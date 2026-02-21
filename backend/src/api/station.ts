/**
 * Station Management Routes – backed by Supabase merchant_profiles
 */

import { Router, Request, Response } from 'express';
import { body, param, query, validationResult } from 'express-validator';
import { asyncHandler, AppError } from '../middleware/errorHandler';
import { authenticate, authorize } from '../middleware/auth';
import db from '../services/database';
import stellarService from '../services/stellar';
import { logger } from '../utils/logger';

const router = Router();

/**
 * Register/update the authenticated merchant as a fuel station
 */
router.post(
  '/',
  authenticate,
  authorize('station_owner', 'admin'),
  [
    body('name').trim().notEmpty(),
    body('address').trim().notEmpty(),
    body('country').isIn(['KE', 'UG', 'TZ', 'RW', 'BI', 'SS']),
    body('latitude').isFloat({ min: -90, max: 90 }),
    body('longitude').isFloat({ min: -180, max: 180 }),
    body('fuelTypes').isArray({ min: 1 }),
    body('fuelTypes.*.type').isIn(['petrol', 'diesel', 'premium']),
    body('fuelTypes.*.pricePerLiter').isFloat({ min: 0 }),
  ],
  asyncHandler(async (req: Request, res: Response) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      throw new AppError('Validation failed', 400, 'VALIDATION_ERROR');
    }

    const { name, address, country, latitude, longitude, fuelTypes } = req.body;

    // Get or create merchant profile for this user
    let merchantProfile = await db.getMerchantProfile(req.user!.userId);

    if (!merchantProfile) {
      throw new AppError('Merchant profile not found. Please complete registration first.', 404, 'PROFILE_NOT_FOUND');
    }

    // Create stellar wallet for station if not yet created
    const wallet = merchantProfile.stellar_public_key
      ? { publicKey: merchantProfile.stellar_public_key }
      : stellarService.createWallet();

    const updated = await db.updateMerchantProfile(merchantProfile.id!, {
      station_name: name,
      address,
      country,
      latitude,
      longitude,
      fuel_types: fuelTypes,
      stellar_public_key: wallet.publicKey,
      geofence_radius_meters: 100,
      is_active: true,
      is_verified: false,
    });

    logger.info(`Station registered/updated: ${merchantProfile.id} by ${req.user!.userId}`);

    res.status(201).json({
      success: true,
      data: {
        id: updated.id,
        name: updated.station_name,
        address: (updated as any).address,
        country: (updated as any).country,
        location: {
          latitude: (updated as any).latitude,
          longitude: (updated as any).longitude,
          geofenceRadius: (updated as any).geofence_radius_meters || 100,
        },
        fuelTypes: (updated as any).fuel_types,
        walletAddress: updated.stellar_public_key,
        isVerified: (updated as any).is_verified,
      },
    });
  })
);

/**
 * Get all stations (with optional filtering)
 */
router.get(
  '/',
  authenticate,
  [
    query('country').optional().isIn(['KE', 'UG', 'TZ', 'RW', 'BI', 'SS']),
    query('verified').optional().isBoolean(),
  ],
  asyncHandler(async (req: Request, res: Response) => {
    const country = req.query.country as string | undefined;
    const verified = req.query.verified !== undefined ? req.query.verified === 'true' : undefined;

    const merchants = await db.getAllMerchants(country, verified);

    res.json({
      success: true,
      data: merchants.map(m => ({
        id: m.id,
        name: m.station_name,
        address: (m as any).address,
        country: (m as any).country,
        location: {
          latitude: (m as any).latitude,
          longitude: (m as any).longitude,
          geofenceRadius: (m as any).geofence_radius_meters || 100,
        },
        fuelTypes: (m as any).fuel_types,
        isVerified: (m as any).is_verified,
        rating: (m as any).rating,
      })),
    });
  })
);

/**
 * Get nearby fuel stations based on GPS location
 */
router.get(
  '/nearby',
  authenticate,
  [
    query('lat').isFloat({ min: -90, max: 90 }),
    query('lng').isFloat({ min: -180, max: 180 }),
    query('radius').optional().isInt({ min: 1, max: 100 }).default(10),
  ],
  asyncHandler(async (req: Request, res: Response) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      throw new AppError('Validation failed', 400, 'VALIDATION_ERROR');
    }

    const userLat = parseFloat(req.query.lat as string);
    const userLng = parseFloat(req.query.lng as string);
    const radiusKm = parseInt(req.query.radius as string) || 10;

    const nearbyMerchants = await db.getNearbyMerchants(userLat, userLng, radiusKm);

    res.json({
      success: true,
      data: {
        stations: nearbyMerchants,
        count: nearbyMerchants.length,
        searchRadius: radiusKm,
        userLocation: { latitude: userLat, longitude: userLng },
      },
    });
  })
);

/**
 * Get station by ID
 */
router.get(
  '/:stationId',
  authenticate,
  [param('stationId').notEmpty()],
  asyncHandler(async (req: Request, res: Response) => {
    const merchant = await db.getMerchantProfile(req.params.stationId);

    if (!merchant) {
      throw new AppError('Station not found', 404, 'STATION_NOT_FOUND');
    }

    let balance = '0';
    if (merchant.stellar_public_key) {
      try {
        balance = await stellarService.getFuelBalance(merchant.stellar_public_key);
      } catch {
        // ignore
      }
    }

    res.json({
      success: true,
      data: {
        id: merchant.id,
        name: merchant.station_name,
        address: (merchant as any).address,
        country: (merchant as any).country,
        location: {
          latitude: (merchant as any).latitude,
          longitude: (merchant as any).longitude,
          geofenceRadius: (merchant as any).geofence_radius_meters || 100,
        },
        fuelTypes: (merchant as any).fuel_types,
        walletAddress: merchant.stellar_public_key,
        isVerified: (merchant as any).is_verified,
        totalRedemptions: merchant.total_redemptions,
        totalVolume: merchant.total_volume,
        rating: (merchant as any).rating,
        balance,
      },
    });
  })
);

/**
 * Update fuel prices
 */
router.patch(
  '/:stationId/prices',
  authenticate,
  authorize('station_owner', 'admin'),
  [
    param('stationId').notEmpty(),
    body('fuelTypes').isArray({ min: 1 }),
    body('fuelTypes.*.type').isIn(['petrol', 'diesel', 'premium']),
    body('fuelTypes.*.pricePerLiter').isFloat({ min: 0 }),
  ],
  asyncHandler(async (req: Request, res: Response) => {
    const merchant = await db.getMerchantProfile(req.params.stationId);

    if (!merchant) throw new AppError('Station not found', 404, 'STATION_NOT_FOUND');

    if (merchant.id !== req.user!.userId && req.user!.role !== 'admin') {
      throw new AppError('Unauthorized', 403, 'FORBIDDEN');
    }

    const updated = await db.updateMerchantProfile(merchant.id!, {
      fuel_types: req.body.fuelTypes,
    });

    logger.info(`Prices updated for station ${merchant.id}`);

    res.json({ success: true, data: { id: updated.id, fuelTypes: (updated as any).fuel_types } });
  })
);

/**
 * Process fuel redemption (NFC tap or QR scan)
 */
router.post(
  '/:stationId/redeem',
  authenticate,
  [
    param('stationId').notEmpty(),
    body('driverWallet').notEmpty(),
    body('fuelType').isIn(['petrol', 'diesel', 'premium']),
    body('amount').isFloat({ min: 0.01 }),
    body('liters').isFloat({ min: 0.01 }),
    body('latitude').isFloat({ min: -90, max: 90 }),
    body('longitude').isFloat({ min: -180, max: 180 }),
  ],
  asyncHandler(async (req: Request, res: Response) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      throw new AppError('Validation failed', 400, 'VALIDATION_ERROR');
    }

    const merchant = await db.getMerchantProfile(req.params.stationId);
    if (!merchant) throw new AppError('Station not found', 404, 'STATION_NOT_FOUND');
    if (!(merchant as any).is_active) throw new AppError('Station is not active', 400, 'STATION_INACTIVE');

    const { driverWallet, fuelType, amount, liters, latitude, longitude, vehicleId } = req.body;

    // Verify geofence
    const geofenceRadius = (merchant as any).geofence_radius_meters || 100;
    const distance = calculateDistance(
      latitude,
      longitude,
      (merchant as any).latitude,
      (merchant as any).longitude
    );

    if (distance > geofenceRadius) {
      throw new AppError('Location outside station geofence', 400, 'OUT_OF_GEOFENCE');
    }

    // Verify driver has sufficient balance
    let driverBalance = '0';
    try {
      driverBalance = await stellarService.getFuelBalance(driverWallet);
    } catch {
      throw new AppError('Could not verify driver balance', 500, 'BALANCE_CHECK_FAILED');
    }

    if (parseFloat(driverBalance) < amount) {
      throw new AppError('Insufficient FUEL balance', 400, 'INSUFFICIENT_BALANCE');
    }

    // Record transaction in DB
    const txRecord = await db.createTransaction({
      rider_id: req.user!.userId,
      merchant_id: merchant.id!,
      amount,
      fuel_liters: liters,
      fuel_type: fuelType,
      latitude,
      longitude,
      vehicle_id: vehicleId,
      status: 'completed',
      transaction_type: 'fuel_purchase',
    });

    // Update merchant stats
    try {
      await db.updateMerchantStats(merchant.id!, liters, amount);
    } catch {
      // non-fatal
    }

    logger.info(`Fuel redeemed at ${merchant.station_name}: ${liters}L for ${amount} FUEL`);

    res.json({
      success: true,
      data: {
        id: txRecord.id,
        stationId: merchant.id,
        driverWallet,
        fuelType,
        amount,
        liters,
        timestamp: txRecord.created_at,
        status: 'completed',
      },
    });
  })
);

/**
 * Get station analytics
 */
router.get(
  '/:stationId/analytics',
  authenticate,
  authorize('station_owner', 'admin'),
  [param('stationId').notEmpty()],
  asyncHandler(async (req: Request, res: Response) => {
    const merchant = await db.getMerchantProfile(req.params.stationId);

    if (!merchant) throw new AppError('Station not found', 404, 'STATION_NOT_FOUND');

    if (merchant.id !== req.user!.userId && req.user!.role !== 'admin') {
      throw new AppError('Unauthorized', 403, 'FORBIDDEN');
    }

    res.json({
      success: true,
      data: {
        stationId: merchant.id,
        totalRedemptions: merchant.total_redemptions ?? 0,
        totalVolume: merchant.total_volume ?? 0,
        averageTransactionValue:
          (merchant.total_redemptions ?? 0) > 0
            ? ((merchant.total_volume ?? 0) / merchant.total_redemptions!).toFixed(2)
            : '0.00',
        rating: (merchant as any).rating || 0,
      },
    });
  })
);

/**
 * Haversine distance in meters
 */
function calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371e3;
  const phi1 = (lat1 * Math.PI) / 180;
  const phi2 = (lat2 * Math.PI) / 180;
  const dPhi = ((lat2 - lat1) * Math.PI) / 180;
  const dLambda = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dPhi / 2) ** 2 +
    Math.cos(phi1) * Math.cos(phi2) * Math.sin(dLambda / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

export default router;