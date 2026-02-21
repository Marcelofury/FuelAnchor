/**
 * Relworx Payment Gateway Routes
 * Unified MTN & Airtel Uganda mobile money via Relworx API
 *
 * Routes:
 *  POST   /api/v1/relworx/validate-phone              – validate phone before payment
 *  POST   /api/v1/relworx/collect                     – request payment from customer
 *  POST   /api/v1/relworx/disburse                    – send money to recipient
 *  GET    /api/v1/relworx/status/:reference            – check payment status
 *  POST   /api/v1/relworx/callback                    – Relworx webhook (public)
 *  GET    /api/v1/relworx/balance                     – wallet balance (admin)
 *  GET    /api/v1/relworx/history                     – transaction history (admin)
 */
import { Router, Request, Response, NextFunction } from 'express';
import { body, param, query, validationResult } from 'express-validator';
import { v4 as uuidv4 } from 'uuid';
import { authenticate, authorize } from '../middleware/auth';
import { asyncHandler, AppError } from '../middleware/errorHandler';
import { db } from '../services/database';
import relworxService, { formatPhoneNumber, getProvider } from '../services/relworx';
import { logger } from '../utils/logger';

const router = Router();

// ─── Helpers ──────────────────────────────────────────────────────────────────

/** Generate a unique 20-char transaction reference */
const makeRef = (): string => `FUEL-${Date.now()}-${uuidv4().substring(0, 6).toUpperCase()}`;

// ─── Validate phone number ────────────────────────────────────────────────────

/**
 * POST /api/v1/relworx/validate-phone
 * Check if a phone number is a valid Ugandan MTN/Airtel number
 */
router.post(
  '/validate-phone',
  authenticate,
  [body('phone').notEmpty().withMessage('Phone number is required')],
  asyncHandler(async (req: Request, res: Response) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      throw new AppError('Validation failed', 400, 'VALIDATION_ERROR');
    }

    const { phone } = req.body;
    const formatted = formatPhoneNumber(phone);

    if (!formatted) {
      return res.status(400).json({
        success: false,
        message: 'Invalid phone number. Use format: +256771234567 or 0771234567',
      });
    }

    const provider = getProvider(phone);
    if (provider === 'UNKNOWN') {
      return res.status(400).json({
        success: false,
        message: 'Unsupported provider. Only MTN and Airtel Uganda numbers are supported.',
      });
    }

    const validation = await relworxService.validateMobileNumber(formatted);

    res.json({
      success: true,
      data: {
        phone: formatted,
        provider,
        valid: validation.valid,
        customerName: validation.customerName,
        message: validation.message,
      },
    });
  })
);

// ─── Collect payment ──────────────────────────────────────────────────────────

/**
 * POST /api/v1/relworx/collect
 * Pull mobile money from a customer (e.g. top-up FUEL tokens)
 */
router.post(
  '/collect',
  authenticate,
  [
    body('phone').notEmpty().withMessage('Phone number is required'),
    body('amount').isFloat({ min: 100 }).withMessage('Amount must be at least 100 UGX'),
    body('currency').optional().isIn(['UGX', 'KES', 'TZS']).withMessage('Invalid currency'),
    body('description').optional().isString(),
  ],
  asyncHandler(async (req: Request, res: Response) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      throw new AppError('Validation failed', 400, 'VALIDATION_ERROR');
    }

    const { phone, amount, currency = 'UGX', description } = req.body;
    const userId = req.user!.userId;

    // Format & validate phone
    const msisdn = formatPhoneNumber(phone);
    if (!msisdn) {
      throw new AppError('Invalid phone number format', 400, 'INVALID_PHONE');
    }

    const provider = getProvider(phone);
    if (provider === 'UNKNOWN') {
      throw new AppError(
        'Unsupported provider. Only MTN and Airtel Uganda are supported.',
        400,
        'UNSUPPORTED_PROVIDER'
      );
    }

    // Validate number with Relworx
    const validation = await relworxService.validateMobileNumber(msisdn);
    const reference = makeRef();

    // Initiate payment
    const result = await relworxService.requestPayment({
      reference,
      msisdn,
      currency,
      amount: parseFloat(amount),
      description: description || 'FuelAnchor FUEL Token Top-Up',
    });

    // Persist to Supabase
    await db.createRelworxPayment({
      user_id: userId,
      amount: parseFloat(amount),
      currency,
      type: 'collection',
      status: 'pending',
      transaction_ref: reference,
      internal_reference: result.internalReference,
      phone_number: msisdn,
      provider,
      description: description || 'FUEL Token Top-Up',
    });

    logger.info('Relworx collection initiated', { userId, reference, amount, provider });

    res.json({
      success: true,
      message: 'Payment request sent. Please approve the prompt on your phone.',
      data: {
        transactionRef: reference,
        internalReference: result.internalReference,
        status: 'pending',
        customerName: validation.customerName,
        provider,
        amount,
        currency,
      },
    });
  })
);

// ─── Disburse payment ─────────────────────────────────────────────────────────

/**
 * POST /api/v1/relworx/disburse
 * Push money out to a recipient (e.g. merchant settlement, refund)
 * Admin only
 */
router.post(
  '/disburse',
  authenticate,
  authorize('admin', 'station_owner'),
  [
    body('phone').notEmpty().withMessage('Recipient phone is required'),
    body('amount').isFloat({ min: 100 }).withMessage('Amount must be at least 100'),
    body('currency').optional().isIn(['UGX', 'KES', 'TZS']),
    body('description').optional().isString(),
    body('recipientUserId').optional().isUUID(),
  ],
  asyncHandler(async (req: Request, res: Response) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      throw new AppError('Validation failed', 400, 'VALIDATION_ERROR');
    }

    const { phone, amount, currency = 'UGX', description, recipientUserId } = req.body;
    const initiatorId = req.user!.userId;

    const msisdn = formatPhoneNumber(phone);
    if (!msisdn) throw new AppError('Invalid phone number format', 400, 'INVALID_PHONE');

    const provider = getProvider(phone);
    if (provider === 'UNKNOWN') {
      throw new AppError('Unsupported provider', 400, 'UNSUPPORTED_PROVIDER');
    }

    const reference = makeRef();

    const result = await relworxService.sendPayment({
      reference,
      msisdn,
      currency,
      amount: parseFloat(amount),
      description: description || 'FuelAnchor Settlement',
    });

    await db.createRelworxPayment({
      user_id: recipientUserId || initiatorId,
      amount: parseFloat(amount),
      currency,
      type: 'disbursement',
      status: 'pending',
      transaction_ref: reference,
      internal_reference: result.internalReference,
      phone_number: msisdn,
      provider,
      description: description || 'Settlement',
    });

    logger.info('Relworx disbursement initiated', { initiatorId, reference, amount, provider });

    res.json({
      success: true,
      message: 'Disbursement initiated successfully.',
      data: {
        transactionRef: reference,
        internalReference: result.internalReference,
        status: 'pending',
        provider,
        amount,
        currency,
      },
    });
  })
);

// ─── Check status ─────────────────────────────────────────────────────────────

/**
 * GET /api/v1/relworx/status/:reference
 * Poll the status of a payment by its customer transaction reference
 */
router.get(
  '/status/:reference',
  authenticate,
  [param('reference').notEmpty()],
  asyncHandler(async (req: Request, res: Response) => {
    const { reference } = req.params;
    const userId = req.user!.userId;

    // Look up our record first
    const payment = await db.getRelworxPayment(reference, userId);
    if (!payment) {
      throw new AppError('Transaction not found', 404, 'NOT_FOUND');
    }

    // Ask Relworx for live status
    const statusData = await relworxService.checkRequestStatus(
      payment.internal_reference || reference
    );

    // Sync status to DB if it changed
    if (statusData.status === 'success' && payment.status !== 'completed') {
      await db.updateRelworxPaymentStatus(payment.id, 'completed', {
        provider_transaction_id: statusData.providerTransactionId,
        completed_at: statusData.completedAt || new Date().toISOString(),
      });
    } else if (statusData.status === 'failed' && payment.status !== 'failed') {
      await db.updateRelworxPaymentStatus(payment.id, 'failed');
    }

    res.json({
      success: true,
      data: {
        transactionRef: reference,
        status: statusData.status,
        amount: statusData.amount ?? payment.amount,
        currency: statusData.currency ?? payment.currency,
        provider: statusData.provider ?? payment.provider,
        providerTransactionId: statusData.providerTransactionId,
        completedAt: statusData.completedAt,
        message: statusData.message,
      },
    });
  })
);

// ─── Relworx webhook callback ─────────────────────────────────────────────────

/**
 * POST /api/v1/relworx/callback
 * Relworx posts payment outcome here. Always return 200.
 */
router.post(
  '/callback',
  asyncHandler(async (req: Request, res: Response) => {
    const {
      customer_reference,
      internal_reference,
      status,
      amount,
      currency,
      provider_transaction_id,
    } = req.body;

    logger.info('Relworx webhook received', req.body);

    try {
      if (customer_reference) {
        const payment = await db.getRelworxPaymentByRef(customer_reference);
        if (payment) {
          const newStatus =
            status === 'success' ? 'completed' : status === 'failed' ? 'failed' : null;

          if (newStatus && payment.status !== newStatus) {
            await db.updateRelworxPaymentStatus(payment.id, newStatus, {
              provider_transaction_id: provider_transaction_id,
              completed_at: status === 'success' ? new Date().toISOString() : undefined,
            });
            logger.info(`Relworx callback: payment ${customer_reference} → ${newStatus}`);
          }
        }
      }
    } catch (err) {
      logger.error('Relworx callback processing error:', err);
      // Still return 200 so Relworx doesn't retry indefinitely
    }

    res.status(200).json({ success: true });
  })
);

// ─── Admin: Wallet balance ────────────────────────────────────────────────────

/**
 * GET /api/v1/relworx/balance?currency=UGX
 */
router.get(
  '/balance',
  authenticate,
  authorize('admin'),
  [query('currency').optional().isIn(['UGX', 'KES', 'TZS'])],
  asyncHandler(async (req: Request, res: Response) => {
    const currency = (req.query.currency as string) || 'UGX';
    const balance = await relworxService.checkWalletBalance(currency);

    res.json({ success: true, data: balance });
  })
);

// ─── Admin: Transaction history ───────────────────────────────────────────────

/**
 * GET /api/v1/relworx/history
 */
router.get(
  '/history',
  authenticate,
  authorize('admin'),
  asyncHandler(async (_req: Request, res: Response) => {
    const history = await relworxService.getTransactionHistory();

    res.json({
      success: true,
      data: history.transactions,
      count: history.transactions.length,
    });
  })
);

export default router;
