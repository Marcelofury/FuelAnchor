/**
 * Driver Routes
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
 * Get driver profile
 */
router.get(
  '/profile',
  authenticate,
  authorize('driver'),
  asyncHandler(async (req: Request, res: Response) => {
    // Get FUEL balance
    const fuelBalance = await stellarService.getFuelBalance(req.user?.walletAddress || '');

    res.json({
      success: true,
      data: {
        userId: req.user?.userId,
        walletAddress: req.user?.walletAddress,
        fuelBalance,
      },
    });
  })
);

/**
 * Get driver's spending limits from DB
 */
router.get(
  '/limits',
  authenticate,
  authorize('driver'),
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!.userId;

    const [driverProfile, quota] = await Promise.all([
      db.getFleetDriverProfile(userId).catch(() => null),
      db.getActiveQuota(userId).catch(() => null),
    ]);

    const dailyLimit = driverProfile?.daily_limit ?? 5000;
    const weeklyLimit = driverProfile?.weekly_limit ?? dailyLimit * 7;
    const transactionLimit = driverProfile?.transaction_limit ?? 1000;
    const dailySpent = driverProfile?.daily_spent ?? 0;
    const weeklySpent = driverProfile?.weekly_spent ?? 0;

    res.json({
      success: true,
      data: {
        dailyLimit,
        weeklyLimit,
        transactionLimit,
        dailySpent,
        weeklySpent,
        remainingToday: Math.max(0, dailyLimit - dailySpent),
        remainingThisWeek: Math.max(0, weeklyLimit - weeklySpent),
        quotaAllocated: quota?.quota_amount ?? 0,
      },
    });
  })
);

/**
 * Get driver's transaction history
 */
router.get(
  '/transactions',
  authenticate,
  authorize('driver'),
  asyncHandler(async (req: Request, res: Response) => {
    const transactions = await stellarService.getTransactionHistory(
      req.user?.walletAddress || '',
      20
    );

    res.json({
      success: true,
      data: transactions.map(tx => ({
        id: tx.id,
        hash: tx.hash,
        createdAt: tx.created_at,
        successful: tx.successful,
        memo: tx.memo,
      })),
    });
  })
);

/**
 * Get nearby fuel stations from DB
 */
router.get(
  '/stations',
  authenticate,
  authorize('driver'),
  [
    query('lat').isFloat({ min: -90, max: 90 }),
    query('lng').isFloat({ min: -180, max: 180 }),
    query('radius').optional().isInt({ min: 1, max: 100 }),
  ],
  asyncHandler(async (req: Request, res: Response) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      throw new AppError('lat and lng are required', 400, 'VALIDATION_ERROR');
    }

    const userLat = parseFloat(req.query.lat as string);
    const userLng = parseFloat(req.query.lng as string);
    const radiusKm = parseInt(req.query.radius as string) || 10;

    const stations = await db.getNearbyMerchants(userLat, userLng, radiusKm);

    res.json({
      success: true,
      data: stations,
    });
  })
);

export default router;
