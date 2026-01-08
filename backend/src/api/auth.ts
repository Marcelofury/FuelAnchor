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
import { logger } from '../utils/logger';

const router = Router();

// In-memory storage (replace with database in production)
const users: Map<string, any> = new Map();

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

    // Check if user exists
    if (users.has(email)) {
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

    // Create user
    const userId = `user_${Date.now()}`;
    const user = {
      id: userId,
      email,
      password: hashedPassword,
      name,
      phone,
      role,
      walletAddress: wallet.publicKey,
      walletSecret: wallet.secretKey, // In production, encrypt this!
      createdAt: new Date().toISOString(),
      isActive: true,
    };

    users.set(email, user);

    // Generate JWT
    const token = jwt.sign(
      { userId: user.id, role: user.role, walletAddress: user.walletAddress },
      config.jwtSecret,
      { expiresIn: config.jwtExpiresIn }
    );

    const refreshToken = jwt.sign(
      { userId: user.id },
      config.jwtSecret,
      { expiresIn: config.jwtRefreshExpiresIn }
    );

    logger.info(`User registered: ${email} as ${role}`);

    res.status(201).json({
      success: true,
      data: {
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.role,
          walletAddress: user.walletAddress,
        },
        token,
        refreshToken,
      },
    });
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

    const user = users.get(email);
    if (!user) {
      throw new AppError('Invalid credentials', 401, 'INVALID_CREDENTIALS');
    }

    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      throw new AppError('Invalid credentials', 401, 'INVALID_CREDENTIALS');
    }

    if (!user.isActive) {
      throw new AppError('Account is deactivated', 403, 'ACCOUNT_DEACTIVATED');
    }

    // Generate JWT
    const token = jwt.sign(
      { userId: user.id, role: user.role, walletAddress: user.walletAddress },
      config.jwtSecret,
      { expiresIn: config.jwtExpiresIn }
    );

    const refreshToken = jwt.sign(
      { userId: user.id },
      config.jwtSecret,
      { expiresIn: config.jwtRefreshExpiresIn }
    );

    logger.info(`User logged in: ${email}`);

    res.json({
      success: true,
      data: {
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.role,
          walletAddress: user.walletAddress,
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
      
      // Find user by ID
      let user: any = null;
      for (const [, u] of users) {
        if (u.id === decoded.userId) {
          user = u;
          break;
        }
      }

      if (!user) {
        throw new AppError('User not found', 404, 'USER_NOT_FOUND');
      }

      const token = jwt.sign(
        { userId: user.id, role: user.role, walletAddress: user.walletAddress },
        config.jwtSecret,
        { expiresIn: config.jwtExpiresIn }
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
    let user: any = null;
    for (const [, u] of users) {
      if (u.id === req.user?.userId) {
        user = u;
        break;
      }
    }

    if (!user) {
      throw new AppError('User not found', 404, 'USER_NOT_FOUND');
    }

    // Get FUEL balance
    const fuelBalance = await stellarService.getFuelBalance(user.walletAddress);

    res.json({
      success: true,
      data: {
        id: user.id,
        email: user.email,
        name: user.name,
        phone: user.phone,
        role: user.role,
        walletAddress: user.walletAddress,
        fuelBalance,
        createdAt: user.createdAt,
      },
    });
  })
);

/**
 * Establish FUEL token trustline
 */
router.post(
  '/trustline',
  authenticate,
  asyncHandler(async (req: Request, res: Response) => {
    let user: any = null;
    for (const [, u] of users) {
      if (u.id === req.user?.userId) {
        user = u;
        break;
      }
    }

    if (!user) {
      throw new AppError('User not found', 404, 'USER_NOT_FOUND');
    }

    const result = await stellarService.establishTrustline(user.walletSecret);

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
