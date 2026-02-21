/**
 * Transaction Routes
 */

import { Router, Request, Response } from 'express';
import { query, body, validationResult } from 'express-validator';
import { asyncHandler, AppError } from '../middleware/errorHandler';
import { authenticate, authorize } from '../middleware/auth';
import stellarService from '../services/stellar';
import db from '../services/database';
import tokenMinting from '../services/tokenMinting';
import { logger } from '../utils/logger';

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
 * Initiate a new fuel payment transaction
 */
router.post(
  '/initiate',
  authenticate,
  [
    body('merchantAddress').trim().notEmpty(),
    body('amount').isNumeric(),
    body('latitude').isFloat({ min: -90, max: 90 }),
    body('longitude').isFloat({ min: -180, max: 180 }),
    body('memo').optional().trim(),
  ],
  asyncHandler(async (req: Request, res: Response) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      throw new AppError('Validation failed', 400, 'VALIDATION_ERROR');
    }

    const { merchantAddress, amount, latitude, longitude, memo } = req.body;
    const driverAddress = req.user?.walletAddress;

    if (!driverAddress) {
      throw new AppError('Wallet address not found', 400, 'WALLET_MISSING');
    }

    // Build transaction for client to sign
    const transactionData = {
      contractId: process.env.FUEL_LOCK_CONTRACT_ID,
      function: 'pay_merchant',
      parameters: {
        driver: driverAddress,
        merchant: merchantAddress,
        amount: amount,
        driver_gps: [latitude * 1000000, longitude * 1000000], // Convert to micro-degrees
      },
      memo: memo || `Payment to ${merchantAddress.substring(0, 8)}`,
    };

    res.json({
      success: true,
      data: {
        transaction: transactionData,
        message: 'Transaction prepared. Sign and submit from client.',
      },
    });
  })
);

/**
 * Verify and record a submitted transaction
 */
router.post(
  '/verify',
  authenticate,
  [
    body('transactionHash').trim().notEmpty(),
    body('merchantAddress').trim().notEmpty(),
    body('amount').isNumeric(),
  ],
  asyncHandler(async (req: Request, res: Response) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      throw new AppError('Validation failed', 400, 'VALIDATION_ERROR');
    }

    const { transactionHash, merchantAddress, amount } = req.body;

    // Verify transaction on Stellar network
    try {
      const txDetails = await stellarService.getTransactionDetails(transactionHash);
      
      if (!txDetails.successful) {
        throw new AppError('Transaction failed on blockchain', 400, 'TX_FAILED');
      }

      // Record in database (Supabase) - TODO: Add database integration
      const transactionRecord = {
        hash: transactionHash,
        driverId: req.user?.userId,
        merchantAddress,
        amount: parseFloat(amount),
        status: 'confirmed',
        timestamp: new Date().toISOString(),
      };

      res.json({
        success: true,
        data: {
          transaction: transactionRecord,
          blockchainConfirmed: true,
        },
      });
    } catch (error: any) {
      throw new AppError(
        error.message || 'Transaction verification failed',
        400,
        'VERIFICATION_FAILED'
      );
    }
  })
);

/**
 * Get pending transactions for settlement (merchant view)
 */
router.get(
  '/pending',
  authenticate,
  authorize('station_owner'),
  asyncHandler(async (req: Request, res: Response) => {
    const merchantAddress = req.user?.walletAddress;

    if (!merchantAddress) {
      throw new AppError('Wallet address not found', 400, 'WALLET_MISSING');
    }

    // Query blockchain for recent transactions to this merchant
    const pendingTransactions = await stellarService.getTransactionHistory(
      merchantAddress,
      50
    );

    res.json({
      success: true,
      data: {
        transactions: pendingTransactions.filter(tx => tx.successful),
        count: pendingTransactions.length,
        totalAmount: pendingTransactions.reduce((sum, tx) => sum + parseFloat(String(tx.fee_charged || '0')), 0),
      },
    });
  })
);

/**
 * Query driver quota from fuel-lock contract
 */
router.get(
  '/quota',
  authenticate,
  asyncHandler(async (req: Request, res: Response) => {
    const driverAddress = req.user?.walletAddress;

    if (!driverAddress) {
      throw new AppError('Wallet address not found', 400, 'WALLET_MISSING');
    }

    // Query quota from contract
    const quota = await stellarService.getDriverQuota(driverAddress);

    res.json({
      success: true,
      data: quota,
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

/**
 * Process merchant settlement request
 */
router.post(
  '/settle',
  authenticate,
  authorize('station_owner'),
  [
    body('date').isISO8601(),
    body('totalAmount').isNumeric(),
    body('transactionCount').isInt({ min: 0 }),
  ],
  asyncHandler(async (req: Request, res: Response) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      throw new AppError('Validation failed', 400, 'VALIDATION_ERROR');
    }

    const { date, totalAmount, transactionCount } = req.body;
    const merchantId = req.user?.userId;
    const merchantAddress = req.user?.walletAddress;

    if (!merchantAddress) {
      throw new AppError('Wallet address not found', 400, 'WALLET_MISSING');
    }

    // Get merchant profile
    const merchantProfile = await db.getMerchantProfile(merchantId!);
    if (!merchantProfile) {
      throw new AppError('Merchant profile not found', 404, 'MERCHANT_NOT_FOUND');
    }

    // Get pending transactions for the merchant
    const pendingTransactions = await db.getPendingTransactions(merchantId!);
    const actualTotal = pendingTransactions.reduce((sum, tx) => sum + tx.amount, 0);

    logger.info(`Processing settlement for merchant ${merchantId}: ${pendingTransactions.length} transactions, Total: ${actualTotal} FUEL`);

    // Create settlement record with calculated totals
    const settlement = {
      id: `settlement_${Date.now()}`,
      merchantId,
      merchantAddress,
      date: date || new Date().toISOString(),
      requestedAmount: parseFloat(totalAmount),
      actualAmount: actualTotal,
      transactionsProcessed: pendingTransactions.length,
      status: 'completed',
      createdAt: new Date().toISOString(),
      completedAt: new Date().toISOString(),
    };

    // Update transaction statuses to completed
    try {
      for (const tx of pendingTransactions) {
        await db.updateTransactionStatus(tx.id!, 'completed');
      }

      // Update merchant stats
      await db.updateMerchantStats(merchantId!, actualTotal, actualTotal);

      logger.info(`Settlement completed: ${settlement.id}, Amount: ${actualTotal} FUEL`);
    } catch (error) {
      logger.error('Settlement processing failed:', error);
      throw new AppError('Settlement processing failed', 500, 'SETTLEMENT_FAILED');
    }

    res.json({
      success: true,
      data: settlement,
      message: `Settlement completed successfully. ${pendingTransactions.length} transactions processed.`,
    });
  })
);

export default router;
