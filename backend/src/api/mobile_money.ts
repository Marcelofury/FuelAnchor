import express, { Request, Response, NextFunction } from 'express';
import { authenticate } from '../middleware/auth';
import { mpesaService } from '../services/mpesa';
import { mtnMoMoService } from '../services/mtn_momo';
import { logger } from '../utils/logger';
import { body, validationResult } from 'express-validator';
import { db } from '../services/database';
import { tokenMinting } from '../services/tokenMinting';

const router = express.Router();

/**
 * @route   POST /api/v1/mobile-money/deposit/mpesa
 * @desc    Initiate M-Pesa deposit (STK Push)
 * @access  Private
 */
router.post(
  '/deposit/mpesa',
  authenticate,
  [
    body('phoneNumber').isMobilePhone('any').withMessage('Invalid phone number'),
    body('amount').isFloat({ min: 1 }).withMessage('Amount must be greater than 0'),
  ],
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ success: false, errors: errors.array() });
      }

      const { phoneNumber, amount } = req.body;
      const userId = req.user?.userId;

      logger.info('Initiating M-Pesa deposit', { userId, phoneNumber, amount });

      const result = await mpesaService.initiateSTKPush({
        phoneNumber,
        amount,
        accountReference: `FUEL-${userId}`,
        transactionDesc: 'FuelAnchor Deposit',
      });

      res.json({
        success: true,
        data: {
          merchantRequestId: result.MerchantRequestID,
          checkoutRequestId: result.CheckoutRequestID,
          responseCode: result.ResponseCode,
          responseDescription: result.ResponseDescription,
          customerMessage: result.CustomerMessage,
        },
      });
    } catch (error) {
      next(error);
    }
  }
);

/**
 * @route   GET /api/v1/mobile-money/deposit/mpesa/status/:checkoutRequestId
 * @desc    Check M-Pesa deposit status
 * @access  Private
 */
router.get(
  '/deposit/mpesa/status/:checkoutRequestId',
  authenticate,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { checkoutRequestId } = req.params;

      const status = await mpesaService.querySTKPush(checkoutRequestId);

      res.json({
        success: true,
        data: status,
      });
    } catch (error) {
      next(error);
    }
  }
);

/**
 * @route   POST /api/v1/mobile-money/callback/mpesa
 * @desc    M-Pesa callback endpoint (called by Safaricom)
 * @access  Public (but should verify signature)
 */
router.post(
  '/callback/mpesa',
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      logger.info('M-Pesa callback received', { body: req.body });

      const result = mpesaService.processCallback(req.body);

      if (result.success) {
        // Credit user's FUEL token balance on Stellar
        try {
          if (result.phoneNumber && result.amount) {
            // Look up user - TODO: Add phone number lookup in database
            logger.info(`Processing credit for ${result.phoneNumber}: KES ${result.amount}`);
            
            // For now, log the pending credit
            // In production, maintain a mapping table: phone_number -> user_id
          }
        } catch (error) {
          logger.error('Error crediting wallet:', error);
        }
        logger.info('M-Pesa payment successful', result);
      } else {
        logger.warn('M-Pesa payment failed', result);
      }

      // Always return success to M-Pesa
      res.json({
        ResultCode: 0,
        ResultDesc: 'Accepted',
      });
    } catch (error) {
      logger.error('M-Pesa callback processing failed:', error);
      // Still return success to avoid retries
      res.json({
        ResultCode: 0,
        ResultDesc: 'Accepted',
      });
    }
  }
);

/**
 * @route   POST /api/v1/mobile-money/withdraw/mpesa
 * @desc    Initiate M-Pesa withdrawal (B2C)
 * @access  Private
 */
router.post(
  '/withdraw/mpesa',
  authenticate,
  [
    body('phoneNumber').isMobilePhone('any').withMessage('Invalid phone number'),
    body('amount').isFloat({ min: 1 }).withMessage('Amount must be greater than 0'),
  ],
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ success: false, errors: errors.array() });
      }

      const { phoneNumber, amount } = req.body;
      const userId = req.user?.userId;

      // Get user profile
      const userProfile = await db.getUserProfile(userId!);
      if (!userProfile) {
        return res.status(404).json({
          success: false,
          error: { message: 'User profile not found' },
        });
      }

      // Calculate FUEL amount
      const fuelAmount = tokenMinting.calculateFiatAmount(amount, 'KES');

      // Verify user has sufficient FUEL token balance
      const hasSufficientBalance = await tokenMinting.checkBalance(
        userProfile.stellar_public_key,
        fuelAmount
      );

      if (!hasSufficientBalance) {
        return res.status(400).json({
          success: false,
          error: { message: `Insufficient FUEL balance. Required: ${fuelAmount} FUEL` },
        });
      }

      logger.info('Initiating M-Pesa withdrawal', { userId, phoneNumber, amount });

      const result = await mpesaService.initiateB2CPayment(
        phoneNumber,
        amount,
        `FuelAnchor withdrawal for ${userId}`
      );

      res.json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }
);

/**
 * @route   POST /api/v1/mobile-money/deposit/mtn
 * @desc    Initiate MTN MoMo deposit
 * @access  Private
 */
router.post(
  '/deposit/mtn',
  authenticate,
  [
    body('phoneNumber').isMobilePhone('any').withMessage('Invalid phone number'),
    body('amount').isFloat({ min: 1 }).withMessage('Amount must be greater than 0'),
    body('currency').optional().isIn(['UGX', 'RWF', 'ZMW']).withMessage('Invalid currency'),
  ],
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ success: false, errors: errors.array() });
      }

      const { phoneNumber, amount, currency = 'UGX' } = req.body;
      const userId = req.user?.userId;

      logger.info('Initiating MTN MoMo deposit', { userId, phoneNumber, amount });

      const referenceId = await mtnMoMoService.requestToPay(
        phoneNumber,
        amount,
        currency,
        `FUEL-${userId}`,
        'FuelAnchor Deposit'
      );

      res.json({
        success: true,
        data: {
          referenceId,
          message: 'Payment request sent. Please approve on your phone.',
        },
      });
    } catch (error) {
      next(error);
    }
  }
);

/**
 * @route   GET /api/v1/mobile-money/deposit/mtn/status/:referenceId
 * @desc    Check MTN MoMo deposit status
 * @access  Private
 */
router.get(
  '/deposit/mtn/status/:referenceId',
  authenticate,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { referenceId } = req.params;

      const status = await mtnMoMoService.getPaymentStatus(referenceId);

      res.json({
        success: true,
        data: status,
      });
    } catch (error) {
      next(error);
    }
  }
);

/**
 * @route   POST /api/v1/mobile-money/withdraw/mtn
 * @desc    Initiate MTN MoMo withdrawal
 * @access  Private
 */
router.post(
  '/withdraw/mtn',
  authenticate,
  [
    body('phoneNumber').isMobilePhone('any').withMessage('Invalid phone number'),
    body('amount').isFloat({ min: 1 }).withMessage('Amount must be greater than 0'),
    body('currency').optional().isIn(['UGX', 'RWF', 'ZMW']).withMessage('Invalid currency'),
  ],
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ success: false, errors: errors.array() });
      }

      const { phoneNumber, amount, currency = 'UGX' } = req.body;
      const userId = req.user?.userId;

      // Get user profile
      const userProfile = await db.getUserProfile(userId!);
      if (!userProfile) {
        return res.status(404).json({
          success: false,
          error: { message: 'User profile not found' },
        });
      }

      // Calculate FUEL amount to burn (fiat → FUEL)
      const fuelAmount = tokenMinting.calculateFuelAmount(amount, currency as 'UGX' | 'RWF');

      // Verify user has sufficient FUEL token balance
      const hasSufficientBalance = await tokenMinting.checkBalance(
        userProfile.stellar_public_key,
        fuelAmount
      );

      if (!hasSufficientBalance) {
        return res.status(400).json({
          success: false,
          error: { message: `Insufficient FUEL balance. Required: ${fuelAmount} FUEL` },
        });
      }

      logger.info('Initiating MTN MoMo withdrawal', { userId, phoneNumber, amount });

      const referenceId = await mtnMoMoService.transfer(
        phoneNumber,
        amount,
        currency,
        `FUEL-${userId}`,
        'FuelAnchor Withdrawal'
      );

      res.json({
        success: true,
        data: {
          referenceId,
          message: 'Withdrawal initiated. Funds will be sent to your phone.',
        },
      });
    } catch (error) {
      next(error);
    }
  }
);

/**
 * @route   GET /api/v1/mobile-money/balance
 * @desc    Get mobile money account balance (admin only)
 * @access  Private
 */
router.get(
  '/balance',
  authenticate,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      // Only allow admin to check balance
      if (req.user?.role !== 'admin') {
        return res.status(403).json({
          success: false,
          error: 'Unauthorized',
        });
      }

      const mtnBalance = await mtnMoMoService.getAccountBalance();

      res.json({
        success: true,
        data: {
          mtn: mtnBalance,
        },
      });
    } catch (error) {
      next(error);
    }
  }
);

export default router;
