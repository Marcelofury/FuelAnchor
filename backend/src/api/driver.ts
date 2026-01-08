/**
 * Driver Routes
 */

import { Router, Request, Response } from 'express';
import { body, param, validationResult } from 'express-validator';
import { asyncHandler, AppError } from '../middleware/errorHandler';
import { authenticate, authorize } from '../middleware/auth';
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
 * Get driver's spending limits
 */
router.get(
  '/limits',
  authenticate,
  authorize('driver'),
  asyncHandler(async (req: Request, res: Response) => {
    // Mock data - in production, fetch from database/blockchain
    res.json({
      success: true,
      data: {
        dailyLimit: 5000,
        weeklyLimit: 25000,
        transactionLimit: 1000,
        dailySpent: 1200,
        weeklySpent: 3500,
        remainingToday: 3800,
        remainingThisWeek: 21500,
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
 * Get nearby fuel stations
 */
router.get(
  '/stations',
  authenticate,
  authorize('driver'),
  [
    // Query params for location
  ],
  asyncHandler(async (req: Request, res: Response) => {
    const { lat, lng, radius = 10 } = req.query;

    // Mock stations - in production, query from database with geolocation
    const stations = [
      {
        id: 'station_1',
        name: 'TotalEnergies Westlands',
        address: 'Waiyaki Way, Nairobi',
        lat: -1.2641,
        lng: 36.8025,
        fuelPrice: 180.50,
        distance: 1.2,
        isOpen: true,
      },
      {
        id: 'station_2',
        name: 'Shell Karen',
        address: 'Ngong Road, Nairobi',
        lat: -1.3187,
        lng: 36.7200,
        fuelPrice: 179.90,
        distance: 3.5,
        isOpen: true,
      },
      {
        id: 'station_3',
        name: 'Rubis Thika Road',
        address: 'Thika Superhighway, Nairobi',
        lat: -1.2200,
        lng: 36.8900,
        fuelPrice: 178.00,
        distance: 5.8,
        isOpen: true,
      },
    ];

    res.json({
      success: true,
      data: stations,
    });
  })
);

export default router;
