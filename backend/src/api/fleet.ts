/**
 * Fleet Management Routes
 */

import { Router, Request, Response } from 'express';
import { body, query, param, validationResult } from 'express-validator';
import { asyncHandler, AppError } from '../middleware/errorHandler';
import { authenticate, authorize } from '../middleware/auth';
import stellarService from '../services/stellar';
import { logger } from '../utils/logger';

const router = Router();

// In-memory storage for fleets
const fleets: Map<string, any> = new Map();
const fleetDrivers: Map<string, any[]> = new Map();

/**
 * Create a new fleet
 */
router.post(
  '/',
  authenticate,
  authorize('fleet_operator', 'admin'),
  [
    body('name').trim().notEmpty(),
    body('description').optional().trim(),
    body('country').isIn(['KE', 'UG', 'TZ', 'RW', 'BI', 'SS']),
    body('vehicleCount').isInt({ min: 1 }),
  ],
  asyncHandler(async (req: Request, res: Response) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      throw new AppError('Validation failed', 400, 'VALIDATION_ERROR');
    }

    const { name, description, country, vehicleCount } = req.body;
    const fleetId = `fleet_${Date.now()}`;

    const fleet = {
      id: fleetId,
      name,
      description,
      country,
      vehicleCount,
      operatorId: req.user?.userId,
      walletAddress: req.user?.walletAddress,
      totalFuelBudget: 0,
      remainingFuelBudget: 0,
      driverCount: 0,
      createdAt: new Date().toISOString(),
      isActive: true,
    };

    fleets.set(fleetId, fleet);
    fleetDrivers.set(fleetId, []);

    logger.info(`Fleet created: ${fleetId} by ${req.user?.userId}`);

    res.status(201).json({
      success: true,
      data: fleet,
    });
  })
);

/**
 * Get all fleets for operator
 */
router.get(
  '/',
  authenticate,
  authorize('fleet_operator', 'admin'),
  asyncHandler(async (req: Request, res: Response) => {
    const operatorFleets: any[] = [];

    for (const [, fleet] of fleets) {
      if (fleet.operatorId === req.user?.userId || req.user?.role === 'admin') {
        operatorFleets.push(fleet);
      }
    }

    res.json({
      success: true,
      data: operatorFleets,
    });
  })
);

/**
 * Get fleet by ID
 */
router.get(
  '/:fleetId',
  authenticate,
  [param('fleetId').notEmpty()],
  asyncHandler(async (req: Request, res: Response) => {
    const fleet = fleets.get(req.params.fleetId);

    if (!fleet) {
      throw new AppError('Fleet not found', 404, 'FLEET_NOT_FOUND');
    }

    // Check authorization
    if (fleet.operatorId !== req.user?.userId && req.user?.role !== 'admin') {
      throw new AppError('Unauthorized', 403, 'FORBIDDEN');
    }

    // Get fleet drivers
    const drivers = fleetDrivers.get(req.params.fleetId) || [];

    res.json({
      success: true,
      data: {
        ...fleet,
        drivers,
      },
    });
  })
);

/**
 * Purchase fuel credits for fleet
 */
router.post(
  '/:fleetId/purchase',
  authenticate,
  authorize('fleet_operator', 'admin'),
  [
    param('fleetId').notEmpty(),
    body('amount').isFloat({ min: 1 }),
    body('paymentMethod').isIn(['mobile_money', 'bank_transfer', 'card']),
    body('paymentReference').notEmpty(),
  ],
  asyncHandler(async (req: Request, res: Response) => {
    const fleet = fleets.get(req.params.fleetId);

    if (!fleet) {
      throw new AppError('Fleet not found', 404, 'FLEET_NOT_FOUND');
    }

    if (fleet.operatorId !== req.user?.userId && req.user?.role !== 'admin') {
      throw new AppError('Unauthorized', 403, 'FORBIDDEN');
    }

    const { amount, paymentMethod, paymentReference } = req.body;

    // Simulate payment verification
    // In production, integrate with M-Pesa, MTN, etc.
    logger.info(`Processing ${paymentMethod} payment: ${paymentReference}`);

    // Mint FUEL tokens to fleet wallet
    const mintResult = await stellarService.mintFuelTokens({
      to: fleet.walletAddress,
      amount: amount.toString(),
    });

    // Update fleet budget
    fleet.totalFuelBudget += amount;
    fleet.remainingFuelBudget += amount;
    fleets.set(req.params.fleetId, fleet);

    logger.info(`Purchased ${amount} FUEL for fleet ${req.params.fleetId}`);

    res.json({
      success: true,
      data: {
        transactionHash: mintResult.hash,
        amount,
        newBalance: fleet.remainingFuelBudget,
      },
    });
  })
);

/**
 * Add driver to fleet
 */
router.post(
  '/:fleetId/drivers',
  authenticate,
  authorize('fleet_operator', 'admin'),
  [
    param('fleetId').notEmpty(),
    body('name').trim().notEmpty(),
    body('phone').isMobilePhone('any'),
    body('vehicleId').notEmpty(),
    body('dailyLimit').isFloat({ min: 0 }),
    body('transactionLimit').isFloat({ min: 0 }),
  ],
  asyncHandler(async (req: Request, res: Response) => {
    const fleet = fleets.get(req.params.fleetId);

    if (!fleet) {
      throw new AppError('Fleet not found', 404, 'FLEET_NOT_FOUND');
    }

    if (fleet.operatorId !== req.user?.userId && req.user?.role !== 'admin') {
      throw new AppError('Unauthorized', 403, 'FORBIDDEN');
    }

    const { name, phone, vehicleId, dailyLimit, transactionLimit, allowedStations } = req.body;

    // Create wallet for driver
    const wallet = stellarService.createWallet();

    const driver = {
      id: `driver_${Date.now()}`,
      fleetId: req.params.fleetId,
      name,
      phone,
      vehicleId,
      walletAddress: wallet.publicKey,
      walletSecret: wallet.secretKey,
      spendingLimits: {
        dailyLimit,
        transactionLimit,
        weeklyLimit: dailyLimit * 7,
        allowedStations: allowedStations || [],
      },
      dailySpent: 0,
      weeklySpent: 0,
      totalRedemptions: 0,
      isActive: true,
      createdAt: new Date().toISOString(),
    };

    const drivers = fleetDrivers.get(req.params.fleetId) || [];
    drivers.push(driver);
    fleetDrivers.set(req.params.fleetId, drivers);

    fleet.driverCount = drivers.length;
    fleets.set(req.params.fleetId, fleet);

    logger.info(`Driver ${driver.id} added to fleet ${req.params.fleetId}`);

    res.status(201).json({
      success: true,
      data: {
        id: driver.id,
        name: driver.name,
        phone: driver.phone,
        vehicleId: driver.vehicleId,
        walletAddress: driver.walletAddress,
        spendingLimits: driver.spendingLimits,
      },
    });
  })
);

/**
 * Distribute fuel tokens to drivers
 */
router.post(
  '/:fleetId/distribute',
  authenticate,
  authorize('fleet_operator', 'admin'),
  [
    param('fleetId').notEmpty(),
    body('distributions').isArray({ min: 1 }),
    body('distributions.*.driverId').notEmpty(),
    body('distributions.*.amount').isFloat({ min: 0.01 }),
  ],
  asyncHandler(async (req: Request, res: Response) => {
    const fleet = fleets.get(req.params.fleetId);

    if (!fleet) {
      throw new AppError('Fleet not found', 404, 'FLEET_NOT_FOUND');
    }

    if (fleet.operatorId !== req.user?.userId && req.user?.role !== 'admin') {
      throw new AppError('Unauthorized', 403, 'FORBIDDEN');
    }

    const { distributions } = req.body;
    const drivers = fleetDrivers.get(req.params.fleetId) || [];

    const results: any[] = [];
    let totalDistributed = 0;

    for (const dist of distributions) {
      const driver = drivers.find(d => d.id === dist.driverId);
      
      if (!driver) {
        results.push({
          driverId: dist.driverId,
          success: false,
          error: 'Driver not found',
        });
        continue;
      }

      if (dist.amount > fleet.remainingFuelBudget) {
        results.push({
          driverId: dist.driverId,
          success: false,
          error: 'Insufficient fleet balance',
        });
        continue;
      }

      try {
        // Note: In a real implementation, you'd use the fleet's secret key
        // This is simplified for the example
        results.push({
          driverId: dist.driverId,
          amount: dist.amount,
          success: true,
          walletAddress: driver.walletAddress,
        });

        totalDistributed += dist.amount;
        fleet.remainingFuelBudget -= dist.amount;
      } catch (error) {
        results.push({
          driverId: dist.driverId,
          success: false,
          error: 'Transfer failed',
        });
      }
    }

    fleets.set(req.params.fleetId, fleet);

    logger.info(`Distributed ${totalDistributed} FUEL to ${results.filter(r => r.success).length} drivers`);

    res.json({
      success: true,
      data: {
        totalDistributed,
        remainingBalance: fleet.remainingFuelBudget,
        results,
      },
    });
  })
);

/**
 * Get fleet analytics
 */
router.get(
  '/:fleetId/analytics',
  authenticate,
  authorize('fleet_operator', 'admin'),
  [
    param('fleetId').notEmpty(),
    query('period').optional().isIn(['day', 'week', 'month', 'year']),
  ],
  asyncHandler(async (req: Request, res: Response) => {
    const fleet = fleets.get(req.params.fleetId);

    if (!fleet) {
      throw new AppError('Fleet not found', 404, 'FLEET_NOT_FOUND');
    }

    if (fleet.operatorId !== req.user?.userId && req.user?.role !== 'admin') {
      throw new AppError('Unauthorized', 403, 'FORBIDDEN');
    }

    const drivers = fleetDrivers.get(req.params.fleetId) || [];

    // Mock analytics - in production, aggregate from actual transaction data
    const analytics = {
      fleetId: fleet.id,
      period: req.query.period || 'week',
      totalBudget: fleet.totalFuelBudget,
      remainingBudget: fleet.remainingFuelBudget,
      utilizationRate: fleet.totalFuelBudget > 0 
        ? ((fleet.totalFuelBudget - fleet.remainingFuelBudget) / fleet.totalFuelBudget * 100).toFixed(2)
        : 0,
      driverCount: drivers.length,
      activeDrivers: drivers.filter(d => d.isActive).length,
      totalRedemptions: drivers.reduce((sum, d) => sum + d.totalRedemptions, 0),
      averagePerDriver: drivers.length > 0
        ? ((fleet.totalFuelBudget - fleet.remainingFuelBudget) / drivers.length).toFixed(2)
        : 0,
      topDrivers: drivers
        .sort((a, b) => b.totalRedemptions - a.totalRedemptions)
        .slice(0, 5)
        .map(d => ({
          id: d.id,
          name: d.name,
          redemptions: d.totalRedemptions,
        })),
      alerts: [],
    };

    res.json({
      success: true,
      data: analytics,
    });
  })
);

export default router;
