/**
 * Stellar API Routes
 */

import { Router, Request, Response } from 'express';
import { body, validationResult } from 'express-validator';
import { asyncHandler, AppError } from '../middleware/errorHandler';
import { authenticate, authorize } from '../middleware/auth';
import stellarService from '../services/stellar';
import { config } from '../config/environment';

const router = Router();

/**
 * Get Stellar network info
 */
router.get(
  '/network',
  asyncHandler(async (req: Request, res: Response) => {
    res.json({
      success: true,
      data: {
        network: config.stellarNetwork,
        horizonUrl: config.stellarHorizonUrl,
        sorobanRpcUrl: config.stellarSorobanRpcUrl,
        fuelTokenIssuer: config.fuelTokenIssuer,
        contracts: {
          fuelToken: config.fuelTokenContractId,
          voucherRedemption: config.voucherRedemptionContractId,
          creditScore: config.creditScoreContractId,
          geofencing: config.geofencingContractId,
        },
      },
    });
  })
);

/**
 * Get account info
 */
router.get(
  '/account/:publicKey',
  authenticate,
  asyncHandler(async (req: Request, res: Response) => {
    const { publicKey } = req.params;

    try {
      const account = await stellarService.getAccount(publicKey);
      const fuelBalance = await stellarService.getFuelBalance(publicKey);

      res.json({
        success: true,
        data: {
          id: account.id,
          sequence: account.sequence,
          balances: account.balances,
          fuelBalance,
          thresholds: account.thresholds,
          signers: account.signers,
        },
      });
    } catch (error) {
      throw new AppError('Account not found', 404, 'ACCOUNT_NOT_FOUND');
    }
  })
);

/**
 * Get FUEL balance
 */
router.get(
  '/balance/:publicKey',
  authenticate,
  asyncHandler(async (req: Request, res: Response) => {
    const balance = await stellarService.getFuelBalance(req.params.publicKey);

    res.json({
      success: true,
      data: {
        publicKey: req.params.publicKey,
        asset: 'FUEL',
        balance,
      },
    });
  })
);

/**
 * Create a new wallet
 */
router.post(
  '/wallet',
  authenticate,
  asyncHandler(async (req: Request, res: Response) => {
    const wallet = stellarService.createWallet();

    // Fund if on testnet
    if (config.stellarNetwork === 'testnet') {
      try {
        await stellarService.fundTestnetAccount(wallet.publicKey);
      } catch (error) {
        // Continue even if funding fails
      }
    }

    res.status(201).json({
      success: true,
      data: {
        publicKey: wallet.publicKey,
        // Only return secret in testnet for demo purposes
        ...(config.stellarNetwork === 'testnet' && { secretKey: wallet.secretKey }),
        message: config.stellarNetwork === 'mainnet' 
          ? 'Secret key stored securely - never share it' 
          : 'Testnet account funded automatically',
      },
    });
  })
);

/**
 * Fund testnet account
 */
router.post(
  '/fund',
  authenticate,
  [body('publicKey').notEmpty()],
  asyncHandler(async (req: Request, res: Response) => {
    if (config.stellarNetwork !== 'testnet') {
      throw new AppError('Funding only available on testnet', 400, 'MAINNET_FUNDING_DISABLED');
    }

    const { publicKey } = req.body;
    await stellarService.fundTestnetAccount(publicKey);

    res.json({
      success: true,
      message: 'Account funded with testnet XLM',
      data: { publicKey },
    });
  })
);

/**
 * Establish FUEL trustline
 */
router.post(
  '/trustline',
  authenticate,
  [body('secretKey').notEmpty()],
  asyncHandler(async (req: Request, res: Response) => {
    const { secretKey } = req.body;

    const result = await stellarService.establishTrustline(secretKey);

    res.json({
      success: true,
      message: 'FUEL trustline established',
      data: {
        hash: result.hash,
      },
    });
  })
);

/**
 * Transfer FUEL tokens
 */
router.post(
  '/transfer',
  authenticate,
  [
    body('fromSecretKey').notEmpty(),
    body('to').notEmpty(),
    body('amount').isFloat({ min: 0.0000001 }),
    body('memo').optional().isString().isLength({ max: 28 }),
  ],
  asyncHandler(async (req: Request, res: Response) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      throw new AppError('Validation failed', 400, 'VALIDATION_ERROR');
    }

    const { fromSecretKey, to, amount, memo } = req.body;

    const result = await stellarService.transferFuelTokens(fromSecretKey, {
      from: '', // Will be derived from secret key
      to,
      amount: amount.toString(),
      memo,
    });

    res.json({
      success: true,
      message: 'Transfer successful',
      data: {
        hash: result.hash,
        ledger: result.ledger,
      },
    });
  })
);

/**
 * Mint FUEL tokens (admin only)
 */
router.post(
  '/mint',
  authenticate,
  authorize('admin'),
  [
    body('to').notEmpty(),
    body('amount').isFloat({ min: 0.0000001 }),
  ],
  asyncHandler(async (req: Request, res: Response) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      throw new AppError('Validation failed', 400, 'VALIDATION_ERROR');
    }

    const { to, amount } = req.body;

    const result = await stellarService.mintFuelTokens({
      to,
      amount: amount.toString(),
    });

    res.json({
      success: true,
      message: 'Tokens minted successfully',
      data: {
        hash: result.hash,
        to,
        amount,
      },
    });
  })
);

/**
 * Get transaction history
 */
router.get(
  '/transactions/:publicKey',
  authenticate,
  asyncHandler(async (req: Request, res: Response) => {
    const { publicKey } = req.params;
    const limit = parseInt(req.query.limit as string) || 20;

    const transactions = await stellarService.getTransactionHistory(publicKey, limit);

    res.json({
      success: true,
      data: {
        publicKey,
        transactions: transactions.map(tx => ({
          id: tx.id,
          hash: tx.hash,
          createdAt: tx.created_at,
          successful: tx.successful,
          memo: tx.memo,
          feeCharged: tx.fee_charged,
        })),
      },
    });
  })
);

export default router;
