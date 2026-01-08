/**
 * Station Management Routes
 */

import { Router, Request, Response } from 'express';
import { body, param, query, validationResult } from 'express-validator';
import { asyncHandler, AppError } from '../middleware/errorHandler';
import { authenticate, authorize } from '../middleware/auth';
import stellarService from '../services/stellar';
import { logger } from '../utils/logger';

const router = Router();

// In-memory storage for stations
const stations: Map<string, any> = new Map();

/**
 * Register a new fuel station
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

    // Create wallet for station (anchor account)
    const wallet = stellarService.createWallet();

    const stationId = `station_${Date.now()}`;
    const station = {
      id: stationId,
      name,
      address,
      country,
      location: {
        latitude,
        longitude,
        geofenceRadius: 100, // 100 meters default
      },
      fuelTypes,
      ownerId: req.user?.userId,
      walletAddress: wallet.publicKey,
      walletSecret: wallet.secretKey,
      isActive: true,
      isVerified: false, // Pending verification
      totalRedemptions: 0,
      totalVolume: 0,
      rating: 0,
      createdAt: new Date().toISOString(),
    };

    stations.set(stationId, station);

    logger.info(`Station registered: ${stationId} by ${req.user?.userId}`);

    res.status(201).json({
      success: true,
      data: {
        id: station.id,
        name: station.name,
        address: station.address,
        location: station.location,
        fuelTypes: station.fuelTypes,
        walletAddress: station.walletAddress,
        isVerified: station.isVerified,
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
    query('lat').optional().isFloat(),
    query('lng').optional().isFloat(),
    query('radius').optional().isInt({ min: 1, max: 100 }),
  ],
  asyncHandler(async (req: Request, res: Response) => {
    const { country, verified, lat, lng, radius } = req.query;

    let result: any[] = [];

    for (const [, station] of stations) {
      let include = true;

      if (country && station.country !== country) {
        include = false;
      }

      if (verified !== undefined && station.isVerified !== (verified === 'true')) {
        include = false;
      }

      if (include) {
        result.push({
          id: station.id,
          name: station.name,
          address: station.address,
          country: station.country,
          location: station.location,
          fuelTypes: station.fuelTypes,
          isVerified: station.isVerified,
          rating: station.rating,
        });
      }
    }

    res.json({
      success: true,
      data: result,
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
    const station = stations.get(req.params.stationId);

    if (!station) {
      throw new AppError('Station not found', 404, 'STATION_NOT_FOUND');
    }

    // Get FUEL/USDC balance
    const balance = await stellarService.getFuelBalance(station.walletAddress);

    res.json({
      success: true,
      data: {
        ...station,
        walletSecret: undefined, // Never expose secret
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
    const station = stations.get(req.params.stationId);

    if (!station) {
      throw new AppError('Station not found', 404, 'STATION_NOT_FOUND');
    }

    if (station.ownerId !== req.user?.userId && req.user?.role !== 'admin') {
      throw new AppError('Unauthorized', 403, 'FORBIDDEN');
    }

    station.fuelTypes = req.body.fuelTypes;
    station.updatedAt = new Date().toISOString();
    stations.set(req.params.stationId, station);

    logger.info(`Prices updated for station ${req.params.stationId}`);

    res.json({
      success: true,
      data: {
        id: station.id,
        fuelTypes: station.fuelTypes,
        updatedAt: station.updatedAt,
      },
    });
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

    const station = stations.get(req.params.stationId);

    if (!station) {
      throw new AppError('Station not found', 404, 'STATION_NOT_FOUND');
    }

    if (!station.isActive) {
      throw new AppError('Station is not active', 400, 'STATION_INACTIVE');
    }

    const { driverWallet, fuelType, amount, liters, latitude, longitude, vehicleId } = req.body;

    // Verify geofence
    const distance = calculateDistance(
      latitude,
      longitude,
      station.location.latitude,
      station.location.longitude
    );

    if (distance > station.location.geofenceRadius) {
      throw new AppError('Location outside station geofence', 400, 'OUT_OF_GEOFENCE');
    }

    // Verify driver has sufficient balance
    const driverBalance = await stellarService.getFuelBalance(driverWallet);
    if (parseFloat(driverBalance) < amount) {
      throw new AppError('Insufficient FUEL balance', 400, 'INSUFFICIENT_BALANCE');
    }

    // Create redemption record
    const redemption = {
      id: `redemption_${Date.now()}`,
      stationId: station.id,
      driverWallet,
      fuelType,
      amount,
      liters,
      pricePerLiter: station.fuelTypes.find((f: any) => f.type === fuelType)?.pricePerLiter,
      location: { latitude, longitude },
      vehicleId,
      timestamp: new Date().toISOString(),
      status: 'completed',
    };

    // Update station stats
    station.totalRedemptions += 1;
    station.totalVolume += liters;
    stations.set(req.params.stationId, station);

    logger.info(`Fuel redeemed at ${station.name}: ${liters}L for ${amount} FUEL`);

    res.json({
      success: true,
      data: redemption,
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
    const station = stations.get(req.params.stationId);

    if (!station) {
      throw new AppError('Station not found', 404, 'STATION_NOT_FOUND');
    }

    if (station.ownerId !== req.user?.userId && req.user?.role !== 'admin') {
      throw new AppError('Unauthorized', 403, 'FORBIDDEN');
    }

    const analytics = {
      stationId: station.id,
      totalRedemptions: station.totalRedemptions,
      totalVolume: station.totalVolume,
      averageTransactionValue: station.totalRedemptions > 0
        ? (station.totalVolume / station.totalRedemptions).toFixed(2)
        : 0,
      rating: station.rating,
      redemptionsByFuelType: {},
      peakHours: [],
      topFleets: [],
    };

    res.json({
      success: true,
      data: analytics,
    });
  })
);

/**
 * Calculate distance between two coordinates (Haversine formula)
 */
function calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371e3; // Earth radius in meters
  const φ1 = (lat1 * Math.PI) / 180;
  const φ2 = (lat2 * Math.PI) / 180;
  const Δφ = ((lat2 - lat1) * Math.PI) / 180;
  const Δλ = ((lon2 - lon1) * Math.PI) / 180;

  const a =
    Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
    Math.cos(φ1) * Math.cos(φ2) * Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c; // Distance in meters
}

export default router;
