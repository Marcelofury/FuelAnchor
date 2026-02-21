/**
 * Webhook Routes for Mobile Money Integration
 */

import { Router, Request, Response } from 'express';
import { body, validationResult } from 'express-validator';
import { asyncHandler, AppError } from '../middleware/errorHandler';
import { logger } from '../utils/logger';
import stellarService from '../services/stellar';
import tokenMinting from '../services/tokenMinting';
import { airtelService } from '../services/airtel';
import db from '../services/database';
import crypto from 'crypto';

const router = Router();

/**
 * M-Pesa STK Push Callback
 */
router.post(
  '/mpesa/callback',
  asyncHandler(async (req: Request, res: Response) => {
    const { Body } = req.body;

    logger.info('M-Pesa callback received:', JSON.stringify(Body));

    if (!Body?.stkCallback) {
      throw new AppError('Invalid callback format', 400, 'INVALID_CALLBACK');
    }

    const { ResultCode, ResultDesc, CallbackMetadata, CheckoutRequestID } = Body.stkCallback;

    if (ResultCode === 0) {
      // Successful payment
      const metadata = CallbackMetadata?.Item || [];
      const amount = metadata.find((item: any) => item.Name === 'Amount')?.Value;
      const mpesaReceiptNumber = metadata.find((item: any) => item.Name === 'MpesaReceiptNumber')?.Value;
      const phoneNumber = metadata.find((item: any) => item.Name === 'PhoneNumber')?.Value;

      logger.info(`M-Pesa payment successful: ${mpesaReceiptNumber} - KES ${amount} from ${phoneNumber}`);

      // Credit user's wallet with FUEL tokens
      try {
        // Look up user by phone number
        const userProfile = await db.getUserProfile(''); // Get by phone logic needed
        
        if (userProfile) {
          const mintResult = await tokenMinting.mintAndTransfer({
            userPublicKey: userProfile.stellar_public_key,
            amount: parseFloat(amount),
            currency: 'KES',
            transactionRef: mpesaReceiptNumber,
            provider: 'mpesa',
          });

          if (mintResult.success) {
            logger.info(`Credited ${mintResult.fuelAmount} FUEL to ${userProfile.full_name}`);
          } else {
            logger.error(`Failed to mint FUEL: ${mintResult.error}`);
          }
        } else {
          logger.warn(`User not found for phone: ${phoneNumber}`);
        }
      } catch (error) {
        logger.error('Error crediting wallet:', error);
      }

      res.json({
        ResultCode: 0,
        ResultDesc: 'Payment processed successfully',
      });
    } else {
      logger.warn(`M-Pesa payment failed: ${ResultDesc}`);
      res.json({
        ResultCode: ResultCode,
        ResultDesc: ResultDesc,
      });
    }
  })
);

/**
 * M-Pesa B2C Result Callback (for disbursements)
 */
router.post(
  '/mpesa/b2c/result',
  asyncHandler(async (req: Request, res: Response) => {
    const { Result } = req.body;

    logger.info('M-Pesa B2C result received:', JSON.stringify(Result));

    if (Result?.ResultCode === 0) {
      // Successful disbursement
      logger.info(`B2C disbursement successful: ${Result.TransactionID}`);
    } else {
      logger.warn(`B2C disbursement failed: ${Result?.ResultDesc}`);
    }

    res.json({ ResultCode: 0 });
  })
);

/**
 * MTN Mobile Money Callback
 */
router.post(
  '/mtn/callback',
  asyncHandler(async (req: Request, res: Response) => {
    const { 
      financialTransactionId,
      externalId,
      amount,
      currency,
      payer,
      payerMessage,
      status 
    } = req.body;

    logger.info(`MTN MoMo callback: ${financialTransactionId} - ${status}`);

    if (status === 'SUCCESSFUL') {
      logger.info(`MTN payment successful: ${amount} ${currency} from ${payer?.partyId}`);

      // Credit user's wallet with FUEL tokens
      try {
        const userProfile = await db.getUserProfile(''); // Get by phone logic needed
        
        if (userProfile) {
          const mintResult = await tokenMinting.mintAndTransfer({
            userPublicKey: userProfile.stellar_public_key,
            amount: parseFloat(amount),
            currency: currency || 'UGX',
            transactionRef: financialTransactionId,
            provider: 'mtn',
          });

          if (mintResult.success) {
            logger.info(`Credited ${mintResult.fuelAmount} FUEL via MTN MoMo`);
          } else {
            logger.error(`Failed to mint FUEL: ${mintResult.error}`);
          }
        }
      } catch (error) {
        logger.error('Error crediting wallet:', error);
      }
    } else if (status === 'FAILED') {
      logger.warn(`MTN payment failed: ${externalId}`);
    }

    res.status(200).send();
  })
);

/**
 * Airtel Money Callback
 */
router.post(
  '/airtel/callback',
  asyncHandler(async (req: Request, res: Response) => {
    logger.info('Airtel Money callback received:', JSON.stringify(req.body));

    const result = airtelService.processCallback(req.body);

    if (result.success && result.transactionId && result.amount !== undefined) {
      logger.info(`Airtel payment successful: ${result.transactionId} - ${result.amount} ${result.currency}`);

      // Credit user's wallet with FUEL tokens
      try {
        const userProfile = await db.getUserProfile(''); // TODO: phone → userId lookup
        if (userProfile) {
          const mintResult = await tokenMinting.mintAndTransfer({
            userPublicKey: userProfile.stellar_public_key,
            amount: result.amount,
            currency: result.currency || 'KES',
            transactionRef: result.transactionId,
            provider: 'airtel',
          });
          if (mintResult.success) {
            logger.info(`Credited ${mintResult.fuelAmount} FUEL via Airtel Money`);
          } else {
            logger.error(`Failed to mint FUEL: ${mintResult.error}`);
          }
        }
      } catch (error) {
        logger.error('Error crediting wallet after Airtel callback:', error);
      }
    } else {
      logger.warn(`Airtel payment not successful`);
    }

    res.json({ status: 'received' });
  })
);

/**
 * NFC Card Tap Event
 */
router.post(
  '/nfc/tap',
  [
    body('cardId').notEmpty(),
    body('stationId').notEmpty(),
    body('terminalId').notEmpty(),
    body('timestamp').notEmpty(),
    body('signature').notEmpty(),
  ],
  asyncHandler(async (req: Request, res: Response) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      throw new AppError('Validation failed', 400, 'VALIDATION_ERROR');
    }

    const { cardId, stationId, terminalId, timestamp, signature, amount, latitude, longitude } = req.body;

    // Verify signature
    // In production, verify HMAC signature from terminal
    logger.info(`NFC tap event: Card ${cardId} at station ${stationId}`);

    // TODO:
    // 1. Look up driver by NFC card ID
    // 2. Verify geofence
    // 3. Check spending limits
    // 4. Process redemption
    // 5. Record transaction for credit scoring

    res.json({
      success: true,
      data: {
        approved: true,
        maxAmount: 5000, // Maximum they can redeem
        driverName: 'John Doe',
        vehicleId: 'KAB 123X',
        message: 'Ready for fuel dispensing',
      },
    });
  })
);

/**
 * Stellar Anchor SEP-24 Webhook
 */
router.post(
  '/stellar/anchor',
  asyncHandler(async (req: Request, res: Response) => {
    const { transaction_id, status, amount, asset_code, from, to } = req.body;

    logger.info(`Stellar anchor webhook: ${transaction_id} - ${status}`);

    if (status === 'completed') {
      logger.info(`Anchor transaction completed: ${amount} ${asset_code}`);
      
      // Update internal records
      try {
        const userProfile = await db.getUserByPublicKey(to);
        if (userProfile) {
          await db.createTransaction({
            blockchain_hash: transaction_id,
            from_user_id: from || 'anchor',
            to_user_id: userProfile.id,
            amount: parseFloat(amount),
            status: 'completed',
          });
          logger.info(`Recorded anchor transaction in database`);
        }
      } catch (error) {
        logger.error('Error recording anchor transaction:', error);
      }
    }

    res.json({ received: true });
  })
);

/**
 * USSD Session Callback (Africa's Talking)
 */
router.post(
  '/ussd',
  asyncHandler(async (req: Request, res: Response) => {
    const { sessionId, phoneNumber, networkCode, serviceCode, text } = req.body;

    logger.info(`USSD session: ${sessionId} from ${phoneNumber}`);

    // Parse USSD input
    const inputs = text.split('*');
    const level = inputs.length;

    let response = '';

    if (text === '') {
      // Main menu
      response = `CON Welcome to FuelAnchor
1. Check Balance
2. Buy Fuel Credits
3. Transaction History
4. Credit Score
5. Nearby Stations`;
    } else if (inputs[0] === '1') {
      // Check balance
      response = `END Your FUEL Balance: 5,000.00
Available at 150+ stations`;
    } else if (inputs[0] === '2') {
      if (level === 1) {
        response = `CON Enter amount in KES:`;
      } else if (level === 2) {
        const amount = inputs[1];
        response = `CON Buy KES ${amount} of FUEL credits?
1. Confirm
2. Cancel`;
      } else if (level === 3 && inputs[2] === '1') {
        response = `END Payment request sent to M-Pesa.
Enter your PIN to complete.`;
      } else {
        response = `END Transaction cancelled.`;
      }
    } else if (inputs[0] === '3') {
      response = `END Recent Transactions:
- Shell Karen: 500 FUEL
- Total Westlands: 300 FUEL
- Rubis Thika: 200 FUEL`;
    } else if (inputs[0] === '4') {
      response = `END Credit Score: 720 (GOLD)
Eligible for loans up to KES 100,000`;
    } else if (inputs[0] === '5') {
      response = `END Nearby Stations:
1. Shell Karen - 1.2km
2. Total Ngong - 2.5km
3. Rubis Junction - 3.1km`;
    } else {
      response = `END Invalid option. Dial again.`;
    }

    res.set('Content-Type', 'text/plain');
    res.send(response);
  })
);

export default router;
