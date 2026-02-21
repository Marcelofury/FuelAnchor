import express, { Request, Response } from 'express';
import { body, param, query, validationResult } from 'express-validator';
import { sep31Service } from '../services/sep31';
import { authenticate } from '../middleware/auth';
import { logger } from '../utils/logger';

const router = express.Router();

/**
 * GET /api/v1/sep31/info
 * Get SEP-31 service information
 */
router.get('/info', (req: Request, res: Response) => {
  const currencies = sep31Service.getSupportedCurrencies();
  
  res.json({
    receive: {
      enabled: true,
      assets: Object.entries(currencies).map(([code, info]) => ({
        asset: `${code}:${info.issuer}`,
        methods: ['STELLAR'],
        min_amount: 1,
        max_amount: 1000000,
        fee_fixed: 0,
        fee_percent: 1.0,
      })),
    },
    send: {
      enabled: true,
      assets: Object.entries(currencies).map(([code, info]) => ({
        asset: `${code}:${info.issuer}`,
        methods: ['STELLAR'],
      })),
    },
  });
});

/**
 * GET /api/v1/sep31/currencies
 * Get supported currencies
 */
router.get('/currencies', (req: Request, res: Response) => {
  const currencies = sep31Service.getSupportedCurrencies();
  res.json({ currencies });
});

/**
 * GET /api/v1/sep31/price
 * Get exchange rate between two currencies
 */
router.get(
  '/price',
  [
    query('sell_asset').notEmpty().withMessage('Sell asset is required'),
    query('buy_asset').notEmpty().withMessage('Buy asset is required'),
    query('sell_amount')
      .optional()
      .isFloat({ min: 0 })
      .withMessage('Sell amount must be positive'),
  ],
  async (req: Request, res: Response) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    try {
      const { sell_asset, buy_asset, sell_amount } = req.query;

      // Extract currency codes (format: CODE:ISSUER or just CODE)
      const sellCurrency = (sell_asset as string).split(':')[0];
      const buyCurrency = (buy_asset as string).split(':')[0];

      if (!sep31Service.isCurrencyPairSupported(sellCurrency, buyCurrency)) {
        return res.status(400).json({
          error: 'Currency pair not supported',
        });
      }

      const exchangeRate = await sep31Service.getExchangeRate(
        sellCurrency,
        buyCurrency
      );

      const response: any = {
        price: exchangeRate.rate.toString(),
        sell_asset: sell_asset as string,
        buy_asset: buy_asset as string,
        expires_at: exchangeRate.validUntil.toISOString(),
      };

      if (sell_amount) {
        const sellAmountNum = parseFloat(sell_amount as string);
        const fee = sellAmountNum * 0.01;
        const netAmount = sellAmountNum - fee;
        const buyAmount = netAmount * exchangeRate.rate;

        response.sell_amount = sell_amount;
        response.buy_amount = buyAmount.toFixed(2);
        response.fee = {
          total: fee.toFixed(2),
          asset: sell_asset,
        };
      }

      res.json(response);
    } catch (error: any) {
      logger.error('Error fetching price', error);
      res.status(500).json({ error: error.message });
    }
  }
);

/**
 * POST /api/v1/sep31/quotes
 * Create a quote for cross-border payment
 */
router.post(
  '/quotes',
  authenticate,
  [
    body('sell_asset').notEmpty().withMessage('Sell asset is required'),
    body('buy_asset').notEmpty().withMessage('Buy asset is required'),
    body('sell_amount')
      .isFloat({ min: 0 })
      .withMessage('Sell amount must be positive'),
  ],
  async (req: Request, res: Response) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    try {
      const { sell_asset, buy_asset, sell_amount } = req.body;

      const sellCurrency = sell_asset.split(':')[0];
      const buyCurrency = buy_asset.split(':')[0];

      if (!sep31Service.isCurrencyPairSupported(sellCurrency, buyCurrency)) {
        return res.status(400).json({
          error: 'Currency pair not supported',
        });
      }

      const quote = await sep31Service.createQuote(
        sellCurrency,
        buyCurrency,
        sell_amount
      );

      res.status(201).json({
        id: quote.id,
        price: quote.price,
        sell_asset,
        buy_asset,
        sell_amount: quote.sellAmount,
        buy_amount: quote.buyAmount,
        expires_at: quote.expiresAt.toISOString(),
        fee: quote.fee,
      });
    } catch (error: any) {
      logger.error('Error creating quote', error);
      res.status(500).json({ error: error.message });
    }
  }
);

/**
 * GET /api/v1/sep31/quotes/:quoteId
 * Get quote by ID
 */
router.get(
  '/quotes/:quoteId',
  authenticate,
  param('quoteId').isUUID().withMessage('Invalid quote ID'),
  (req: Request, res: Response) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    try {
      const { quoteId } = req.params;
      const quote = sep31Service.getQuote(quoteId);

      if (!quote) {
        return res.status(404).json({ error: 'Quote not found or expired' });
      }

      res.json({
        id: quote.id,
        price: quote.price,
        sell_asset: quote.sellAsset,
        buy_asset: quote.buyAsset,
        sell_amount: quote.sellAmount,
        buy_amount: quote.buyAmount,
        expires_at: quote.expiresAt.toISOString(),
        fee: quote.fee,
      });
    } catch (error: any) {
      logger.error('Error fetching quote', error);
      res.status(500).json({ error: error.message });
    }
  }
);

/**
 * POST /api/v1/sep31/transactions
 * Initiate cross-border transaction
 */
router.post(
  '/transactions',
  authenticate,
  [
    body('quote_id').isUUID().withMessage('Valid quote ID is required'),
    body('sender_id').notEmpty().withMessage('Sender ID is required'),
    body('receiver_id').notEmpty().withMessage('Receiver ID is required'),
    body('sender_account').notEmpty().withMessage('Sender account is required'),
    body('receiver_account').notEmpty().withMessage('Receiver account is required'),
    body('sender_secret_key').optional().isString(),
  ],
  async (req: Request, res: Response) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    try {
      const {
        quote_id,
        sender_id,
        receiver_id,
        sender_account,
        receiver_account,
        sender_secret_key,
      } = req.body;

      const transaction = await sep31Service.initiateTransaction(
        quote_id,
        sender_id,
        receiver_id,
        sender_account,
        receiver_account,
        sender_secret_key
      );

      res.status(201).json({
        id: transaction.id,
        status: transaction.status,
        send_amount: transaction.sendAmount,
        send_currency: transaction.sendCurrency,
        receive_amount: transaction.receiveAmount,
        receive_currency: transaction.receiveCurrency,
        stellar_transaction_id: transaction.stellarTxHash,
        created_at: transaction.createdAt.toISOString(),
        completed_at: transaction.completedAt?.toISOString(),
      });
    } catch (error: any) {
      logger.error('Error initiating transaction', error);
      res.status(500).json({ error: error.message });
    }
  }
);

/**
 * GET /api/v1/sep31/transactions/:transactionId
 * Get transaction status
 */
router.get(
  '/transactions/:transactionId',
  authenticate,
  param('transactionId').isUUID().withMessage('Invalid transaction ID'),
  (req: Request, res: Response) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    try {
      const { transactionId } = req.params;
      const transaction = sep31Service.getTransaction(transactionId);

      if (!transaction) {
        return res.status(404).json({ error: 'Transaction not found' });
      }

      res.json({
        id: transaction.id,
        status: transaction.status,
        send_amount: transaction.sendAmount,
        send_currency: transaction.sendCurrency,
        receive_amount: transaction.receiveAmount,
        receive_currency: transaction.receiveCurrency,
        sender_id: transaction.senderId,
        receiver_id: transaction.receiverId,
        stellar_transaction_id: transaction.stellarTxHash,
        created_at: transaction.createdAt.toISOString(),
        completed_at: transaction.completedAt?.toISOString(),
      });
    } catch (error: any) {
      logger.error('Error fetching transaction', error);
      res.status(500).json({ error: error.message });
    }
  }
);

/**
 * GET /api/v1/sep31/transactions
 * Get user's transactions
 */
router.get(
  '/transactions',
  authenticate,
  query('user_id').notEmpty().withMessage('User ID is required'),
  (req: Request, res: Response) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    try {
      const { user_id } = req.query;
      const transactions = sep31Service.getUserTransactions(user_id as string);

      res.json({
        transactions: transactions.map(tx => ({
          id: tx.id,
          status: tx.status,
          send_amount: tx.sendAmount,
          send_currency: tx.sendCurrency,
          receive_amount: tx.receiveAmount,
          receive_currency: tx.receiveCurrency,
          stellar_transaction_id: tx.stellarTxHash,
          created_at: tx.createdAt.toISOString(),
          completed_at: tx.completedAt?.toISOString(),
        })),
      });
    } catch (error: any) {
      logger.error('Error fetching user transactions', error);
      res.status(500).json({ error: error.message });
    }
  }
);

export default router;
