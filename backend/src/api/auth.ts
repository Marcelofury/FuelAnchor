/**
 * Authentication Routes
 */

import { Router, Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { body, validationResult } from 'express-validator';
import { config } from '../config/environment';
import { asyncHandler, AppError } from '../middleware/errorHandler';
import { authenticate } from '../middleware/auth';
import stellarService from '../services/stellar';
import db from '../services/database';
import { logger } from '../utils/logger';

const router = Router();

/**
 * Register a new user
 */
router.post(
  '/register',
  [
    body('email').isEmail().normalizeEmail(),
    body('password').isLength({ min: 8 }),
    body('name').trim().notEmpty(),
    body('phone').isMobilePhone('any'),
    body('role').isIn(['fleet_operator', 'driver', 'station_owner', 'rider']),
  ],
  asyncHandler(async (req: Request, res: Response) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      throw new AppError('Validation failed', 400, 'VALIDATION_ERROR');
    }

    const { email, password, name, phone, role } = req.body;

    // Check if user exists (by email in DB)
    const existingAuth = await db.getUserByEmail(email);
    if (existingAuth) {
      throw new AppError('User already exists', 409, 'USER_EXISTS');
    }

    // Create Stellar wallet for user
    const wallet = stellarService.createWallet();

    // Fund testnet account if on testnet
    if (config.stellarNetwork === 'testnet') {
      try {
        await stellarService.fundTestnetAccount(wallet.publicKey);
      } catch (error) {
        logger.warn('Failed to fund testnet account, continuing anyway');
      }
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 12);

    // Create user ID
    const userId = `user_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

    try {
      // Create user profile in database
      const userProfile = await db.createUserProfile({
        id: userId,
        full_name: name,
        phone_number: phone,
        role: role as any,
        stellar_public_key: wallet.publicKey,
      });

      // Create role-specific profile
      if (role === 'rider') {
        await db.createRiderProfile({
          id: userId,
          total_fuel_purchased: 0,
          total_transactions: 0,
          credit_score: 0,
        });
      } else if (role === 'fleet_operator' || role === 'driver') {
        await db.createFleetDriverProfile({
          id: userId,
          vehicle_id: req.body.vehicle_id || `VEH${Date.now()}`,
          vehicle_type: req.body.vehicle_type || 'motorcycle',
          odometer_reading: 0,
          fuel_quota_allocated: 0,
          fuel_quota_used: 0,
        });
      } else if (role === 'station_owner') {
        await db.createMerchantProfile({
          id: userId,
          station_id: `STN${Date.now()}`,
          station_name: req.body.station_name || `${name}'s Station`,
          location_lat: req.body.latitude,
          location_lng: req.body.longitude,
          total_fuel_dispensed: 0,
          total_revenue: 0,
        });
      }

      // Persist auth credentials (email + bcrypt hash) to profiles table
      await db.saveUserAuth(userProfile.id, email, hashedPassword);

      // Generate JWT
      const token = jwt.sign(
        { userId: userProfile.id, role: userProfile.role, walletAddress: userProfile.stellar_public_key },
        config.jwtSecret,
        { expiresIn: config.jwtExpiresIn } as jwt.SignOptions
      );

      const refreshToken = jwt.sign(
        { userId: userProfile.id },
        config.jwtSecret,
        { expiresIn: config.jwtRefreshExpiresIn } as jwt.SignOptions
      );

      logger.info(`User registered: ${email} as ${role}`);

      res.status(201).json({
        success: true,
        data: {
          user: {
            id: userProfile.id,
            email,
            name: userProfile.full_name,
            role: userProfile.role,
            walletAddress: userProfile.stellar_public_key,
          },
          token,
          refreshToken,
          walletSecret: wallet.secretKey, // Return once for user to backup securely
        },
      });
    } catch (error: any) {
      logger.error('User registration failed:', error);
      throw new AppError('Failed to create user profile', 500, 'REGISTRATION_FAILED');
    }
  })
);

/**
 * Login user
 */
router.post(
  '/login',
  [
    body('email').isEmail().normalizeEmail(),
    body('password').notEmpty(),
  ],
  asyncHandler(async (req: Request, res: Response) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      throw new AppError('Validation failed', 400, 'VALIDATION_ERROR');
    }

    const { email, password } = req.body;

    // Lookup by email stored in profiles table
    const authRecord = await db.getUserByEmail(email);
    if (!authRecord || !authRecord.password_hash) {
      throw new AppError('Invalid credentials', 401, 'INVALID_CREDENTIALS');
    }

    const isPasswordValid = await bcrypt.compare(password, authRecord.password_hash);
    if (!isPasswordValid) {
      throw new AppError('Invalid credentials', 401, 'INVALID_CREDENTIALS');
    }

    // User profile already loaded from getUserByEmail
    const userProfile = authRecord;
    if (!userProfile) {
      throw new AppError('User profile not found', 404, 'USER_NOT_FOUND');
    }

    // Generate JWT
    const token = jwt.sign(
      { userId: userProfile.id, role: userProfile.role, walletAddress: userProfile.stellar_public_key },
      config.jwtSecret,
      { expiresIn: config.jwtExpiresIn } as jwt.SignOptions
    );

    const refreshToken = jwt.sign(
      { userId: userProfile.id },
      config.jwtSecret,
      { expiresIn: config.jwtRefreshExpiresIn } as jwt.SignOptions
    );

    logger.info(`User logged in: ${email}`);

    res.json({
      success: true,
      data: {
        user: {
          id: userProfile.id,
          email,
          name: userProfile.full_name,
          role: userProfile.role,
          walletAddress: userProfile.stellar_public_key,
        },
        token,
        refreshToken,
      },
    });
  })
);

/**
 * Refresh token
 */
router.post(
  '/refresh',
  [body('refreshToken').notEmpty()],
  asyncHandler(async (req: Request, res: Response) => {
    const { refreshToken } = req.body;

    try {
      const decoded = jwt.verify(refreshToken, config.jwtSecret) as { userId: string };
      
      // Get user from database
      const userProfile = await db.getUserProfile(decoded.userId);
      if (!userProfile) {
        throw new AppError('User not found', 404, 'USER_NOT_FOUND');
      }

      const token = jwt.sign(
        { userId: userProfile.id, role: userProfile.role, walletAddress: userProfile.stellar_public_key },
        config.jwtSecret,
        { expiresIn: config.jwtExpiresIn } as jwt.SignOptions
      );

      res.json({
        success: true,
        data: { token },
      });
    } catch (error) {
      throw new AppError('Invalid refresh token', 401, 'INVALID_REFRESH_TOKEN');
    }
  })
);

/**
 * Get current user profile
 */
router.get(
  '/me',
  authenticate,
  asyncHandler(async (req: Request, res: Response) => {
    const userProfile = await db.getUserProfile(req.user!.userId);
    if (!userProfile) {
      throw new AppError('User not found', 404, 'USER_NOT_FOUND');
    }

    // Get FUEL balance
    const fuelBalance = await stellarService.getFuelBalance(userProfile.stellar_public_key);

    // Get role-specific data
    let roleData: any = {};
    if (userProfile.role === 'rider') {
      roleData = await db.getRiderProfile(userProfile.id);
    } else if (userProfile.role === 'fleet_driver') {
      roleData = await db.getFleetDriverProfile(userProfile.id);
    } else if (userProfile.role === 'merchant') {
      roleData = await db.getMerchantProfile(userProfile.id);
    }

    res.json({
      success: true,
      data: {
        id: userProfile.id,
        name: userProfile.full_name,
        phone: userProfile.phone_number,
        role: userProfile.role,
        walletAddress: userProfile.stellar_public_key,
        fuelBalance,
        createdAt: userProfile.created_at,
        ...roleData,
      },
    });
  })
);

/**
 * Establish FUEL token trustline
 * Note: This requires the user's secret key, which should be stored securely client-side
 */
router.post(
  '/trustline',
  authenticate,
  [body('secretKey').matches(/^S[A-Z2-7]{55}$/)],
  asyncHandler(async (req: Request, res: Response) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      throw new AppError('Invalid secret key format', 400, 'VALIDATION_ERROR');
    }

    const userProfile = await db.getUserProfile(req.user!.userId);
    if (!userProfile) {
      throw new AppError('User not found', 404, 'USER_NOT_FOUND');
    }

    const { secretKey } = req.body;
    
    const result = await stellarService.establishTrustline(secretKey);

    res.json({
      success: true,
      message: 'Trustline established successfully',
      data: {
        hash: result.hash,
      },
    });
  })
);

export default router;
