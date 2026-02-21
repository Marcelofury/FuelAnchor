/**
 * Fleet Management Routes – backed by Supabase DB
 */

import { Router, Request, Response } from 'express';
import { body, query, param, validationResult } from 'express-validator';
import { asyncHandler, AppError } from '../middleware/errorHandler';
import { authenticate, authorize } from '../middleware/auth';
import db from '../services/database';
import stellarService from '../services/stellar';
import { logger } from '../utils/logger';

const router = Router();

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

    // Create a Stellar wallet for the fleet
    const wallet = stellarService.createWallet();

    const fleet = await db.createFleet({
      name,
      description,
      country,
      vehicle_count: vehicleCount,
      operator_id: req.user!.userId,
      stellar_public_key: wallet.publicKey,
      total_fuel_budget: 0,
      remaining_fuel_budget: 0,
      driver_count: 0,
      is_active: true,
    });

    logger.info(`Fleet created: ${fleet.id} by ${req.user!.userId}`);

    res.status(201).json({ success: true, data: fleet });
  })
);

/**
 * Get all fleets for the authenticated operator
 */
router.get(
  '/',
  authenticate,
  authorize('fleet_operator', 'admin'),
  asyncHandler(async (req: Request, res: Response) => {
    const fleets = req.user!.role === 'admin'
      ? await db.getFleetsByOperator('')   // TODO: add admin getAll method
      : await db.getFleetsByOperator(req.user!.userId);

    res.json({ success: true, data: fleets });
  })
);

/**
 * Get fleet by ID with members
 */
router.get(
  '/:fleetId',
  authenticate,
  [param('fleetId').notEmpty()],
  asyncHandler(async (req: Request, res: Response) => {
    const fleet = await db.getFleet(req.params.fleetId);
    if (!fleet) throw new AppError('Fleet not found', 404, 'FLEET_NOT_FOUND');

    if (fleet.operator_id !== req.user!.userId && req.user!.role !== 'admin') {
      throw new AppError('Unauthorized', 403, 'FORBIDDEN');
    }

    const members = await db.getFleetMembers(req.params.fleetId);

    res.json({ success: true, data: { ...fleet, members } });
  })
);

/**
 * Purchase fuel credits for fleet (mint FUEL tokens)
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
    const fleet = await db.getFleet(req.params.fleetId);
    if (!fleet) throw new AppError('Fleet not found', 404, 'FLEET_NOT_FOUND');

    if (fleet.operator_id !== req.user!.userId && req.user!.role !== 'admin') {
      throw new AppError('Unauthorized', 403, 'FORBIDDEN');
    }

    const { amount, paymentMethod, paymentReference } = req.body;
    logger.info(`Processing ${paymentMethod} payment: ${paymentReference}`);

    // Mint FUEL tokens to fleet wallet
    const mintResult = await stellarService.mintFuelTokens({
      to: fleet.stellar_public_key!,
      amount: amount.toString(),
    });

    const newTotal = (fleet.total_fuel_budget || 0) + amount;
    const newRemaining = (fleet.remaining_fuel_budget || 0) + amount;
    await db.updateFleetBudget(fleet.id!, newTotal, newRemaining);

    logger.info(`Purchased ${amount} FUEL for fleet ${fleet.id}`);

    res.json({
      success: true,
      data: {
        transactionHash: mintResult.hash,
        amount,
        newBalance: newRemaining,
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
    body('driverId').notEmpty().withMessage('driverId (profile ID) is required'),
    body('vehicleId').notEmpty(),
    body('dailyLimit').isFloat({ min: 0 }),
    body('transactionLimit').isFloat({ min: 0 }),
    body('weeklyLimit').optional().isFloat({ min: 0 }),
  ],
  asyncHandler(async (req: Request, res: Response) => {
    const fleet = await db.getFleet(req.params.fleetId);
    if (!fleet) throw new AppError('Fleet not found', 404, 'FLEET_NOT_FOUND');

    if (fleet.operator_id !== req.user!.userId && req.user!.role !== 'admin') {
      throw new AppError('Unauthorized', 403, 'FORBIDDEN');
    }

    const { driverId, vehicleId, dailyLimit, transactionLimit, weeklyLimit, allowedStations } = req.body;

    const member = await db.createFleetMember({
      fleet_id: req.params.fleetId,
      profile_id: driverId,
      vehicle_id: vehicleId,
      daily_limit: dailyLimit,
      transaction_limit: transactionLimit,
      weekly_limit: weeklyLimit ?? dailyLimit * 7,
      daily_spent: 0,
      weekly_spent: 0,
      allowed_stations: allowedStations || [],
      total_redemptions: 0,
      is_active: true,
    });

    logger.info(`Driver ${driverId} added to fleet ${req.params.fleetId}`);

    res.status(201).json({ success: true, data: member });
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
    body('distributions.*.memberId').notEmpty(),
    body('distributions.*.amount').isFloat({ min: 0.01 }),
  ],
  asyncHandler(async (req: Request, res: Response) => {
    const fleet = await db.getFleet(req.params.fleetId);
    if (!fleet) throw new AppError('Fleet not found', 404, 'FLEET_NOT_FOUND');

    if (fleet.operator_id !== req.user!.userId && req.user!.role !== 'admin') {
      throw new AppError('Unauthorized', 403, 'FORBIDDEN');
    }

    const { distributions } = req.body;
    const results: any[] = [];
    let totalDistributed = 0;

    for (const dist of distributions) {
      const member = await db.getFleetMember(dist.memberId);

      if (!member) {
        results.push({ memberId: dist.memberId, success: false, error: 'Member not found' });
        continue;
      }

      if (dist.amount > (fleet.remaining_fuel_budget || 0)) {
        results.push({ memberId: dist.memberId, success: false, error: 'Insufficient fleet balance' });
        continue;
      }

      try {
        await db.updateFleetMemberSpending(dist.memberId, dist.amount, dist.amount);
        const newRemaining = (fleet.remaining_fuel_budget || 0) - dist.amount;
        await db.updateFleetBudget(fleet.id!, fleet.total_fuel_budget || 0, newRemaining);
        fleet.remaining_fuel_budget = newRemaining;

        results.push({ memberId: dist.memberId, amount: dist.amount, success: true });
        totalDistributed += dist.amount;
      } catch {
        results.push({ memberId: dist.memberId, success: false, error: 'Transfer failed' });
      }
    }

    logger.info(`Distributed ${totalDistributed} FUEL to ${results.filter(r => r.success).length} members`);

    res.json({
      success: true,
      data: { totalDistributed, remainingBalance: fleet.remaining_fuel_budget, results },
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
    const fleet = await db.getFleet(req.params.fleetId);
    if (!fleet) throw new AppError('Fleet not found', 404, 'FLEET_NOT_FOUND');

    if (fleet.operator_id !== req.user!.userId && req.user!.role !== 'admin') {
      throw new AppError('Unauthorized', 403, 'FORBIDDEN');
    }

    let analytics: any;
    try {
      analytics = await db.getFleetAnalytics(req.params.fleetId);
    } catch {
      analytics = null;
    }

    const members = await db.getFleetMembers(req.params.fleetId);
    const utilized = (fleet.total_fuel_budget || 0) - (fleet.remaining_fuel_budget || 0);

    res.json({
      success: true,
      data: {
        fleetId: fleet.id,
        period: req.query.period || 'week',
        totalBudget: fleet.total_fuel_budget,
        remainingBudget: fleet.remaining_fuel_budget,
        utilizationRate:
          (fleet.total_fuel_budget || 0) > 0
            ? ((utilized / fleet.total_fuel_budget!) * 100).toFixed(2)
            : '0.00',
        memberCount: members.length,
        activeMembers: members.filter(m => m.is_active).length,
        ...(analytics || {}),
      },
    });
  })
);

export default router;