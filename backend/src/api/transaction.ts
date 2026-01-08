/**
 * Transaction Routes
 */

import { Router, Request, Response } from 'express';
import { query, validationResult } from 'express-validator';
import { asyncHandler, AppError } from '../middleware/errorHandler';
import { authenticate } from '../middleware/auth';
import stellarService from '../services/stellar';

const router = Router();

/**
 * Get transaction history for authenticated user
 */
router.get(
  '/',
  authenticate,
  [
    query('limit').optional().isInt({ min: 1, max: 100 }),
    query('cursor').optional(),
    query('type').optional().isIn(['all', 'sent', 'received', 'redemption']),
  ],
  asyncHandler(async (req: Request, res: Response) => {
    const limit = parseInt(req.query.limit as string) || 20;

    const transactions = await stellarService.getTransactionHistory(
      req.user?.walletAddress || '',
      limit
    );

    res.json({
      success: true,
      data: {
        transactions: transactions.map(tx => ({
          id: tx.id,
          hash: tx.hash,
          createdAt: tx.created_at,
          successful: tx.successful,
          memo: tx.memo,
          memoType: tx.memo_type,
          feeCharged: tx.fee_charged,
          operationCount: tx.operation_count,
        })),
        count: transactions.length,
      },
    });
  })
);

/**
 * Get transaction details by hash
 */
router.get(
  '/:hash',
  authenticate,
  asyncHandler(async (req: Request, res: Response) => {
    const { hash } = req.params;

    // In production, fetch from Horizon API
    res.json({
      success: true,
      data: {
        hash,
        message: 'Transaction details would be fetched from Stellar Horizon',
      },
    });
  })
);

/**
 * Stream real-time transactions (WebSocket endpoint info)
 */
router.get(
  '/stream/info',
  authenticate,
  asyncHandler(async (req: Request, res: Response) => {
    res.json({
      success: true,
      data: {
        websocketUrl: '/ws/transactions',
        message: 'Connect to WebSocket for real-time transaction updates',
        authentication: 'Pass JWT token in query parameter: ?token=YOUR_JWT',
      },
    });
  })
);

export default router;
