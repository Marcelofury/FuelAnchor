import axios from 'axios';
import { v4 as uuidv4 } from 'uuid';
import * as StellarSdk from '@stellar/stellar-sdk';
import { environment } from '../config/environment';
import { logger } from '../utils/logger';

/**
 * SEP-31 Cross-Border Payment Service
 * Handles multi-currency payments between Kenya, Uganda, Tanzania, and Rwanda
 */

interface ExchangeRate {
  sourceCurrency: string;
  destinationCurrency: string;
  rate: number;
  validUntil: Date;
}

interface Quote {
  id: string;
  price: string;
  sellAsset: string;
  buyAsset: string;
  sellAmount: string;
  buyAmount: string;
  expiresAt: Date;
  fee: {
    total: string;
    asset: string;
  };
}

interface CrossBorderTransaction {
  id: string;
  status: 'pending' | 'processing' | 'completed' | 'failed';
  sendAmount: string;
  sendCurrency: string;
  receiveAmount: string;
  receiveCurrency: string;
  senderId: string;
  receiverId: string;
  senderAccount: string;
  receiverAccount: string;
  quoteId: string;
  stellarTxHash?: string;
  createdAt: Date;
  completedAt?: Date;
}

// Supported currencies with their Stellar asset codes
const SUPPORTED_CURRENCIES = {
  KES: { code: 'KES', issuer: environment.stellarIssuer, name: 'Kenyan Shilling' },
  UGX: { code: 'UGX', issuer: environment.stellarIssuer, name: 'Ugandan Shilling' },
  TZS: { code: 'TZS', issuer: environment.stellarIssuer, name: 'Tanzanian Shilling' },
  RWF: { code: 'RWF', issuer: environment.stellarIssuer, name: 'Rwandan Franc' },
  USD: { code: 'USD', issuer: environment.stellarIssuer, name: 'US Dollar' },
  USDC: { code: 'USDC', issuer: environment.usdcIssuer, name: 'USD Coin' },
};

// Mock exchange rates (in production, fetch from forex API)
const EXCHANGE_RATES: Record<string, Record<string, number>> = {
  KES: { UGX: 32.5, TZS: 21.7, RWF: 9.2, USD: 0.0078, USDC: 0.0078 },
  UGX: { KES: 0.031, TZS: 0.67, RWF: 0.28, USD: 0.00024, USDC: 0.00024 },
  TZS: { KES: 0.046, UGX: 1.49, RWF: 0.42, USD: 0.00036, USDC: 0.00036 },
  RWF: { KES: 0.109, UGX: 3.57, TZS: 2.38, USD: 0.00085, USDC: 0.00085 },
  USD: { KES: 128.5, UGX: 4166.7, TZS: 2777.8, RWF: 1176.5, USDC: 1 },
  USDC: { KES: 128.5, UGX: 4166.7, TZS: 2777.8, RWF: 1176.5, USD: 1 },
};

class SEP31Service {
  private server: StellarSdk.Horizon.Server;
  private quotes: Map<string, Quote> = new Map();
  private transactions: Map<string, CrossBorderTransaction> = new Map();

  constructor() {
    this.server = new StellarSdk.Horizon.Server(environment.horizonUrl);
  }

  /**
   * Get current exchange rate between two currencies
   */
  async getExchangeRate(
    sourceCurrency: string,
    destinationCurrency: string
  ): Promise<ExchangeRate> {
    if (!EXCHANGE_RATES[sourceCurrency]?.[destinationCurrency]) {
      throw new Error(`Exchange rate not available for ${sourceCurrency} to ${destinationCurrency}`);
    }

    const rate = EXCHANGE_RATES[sourceCurrency][destinationCurrency];
    
    return {
      sourceCurrency,
      destinationCurrency,
      rate,
      validUntil: new Date(Date.now() + 5 * 60 * 1000), // Valid for 5 minutes
    };
  }

  /**
   * Create a quote for cross-border payment
   */
  async createQuote(
    sellAsset: string,
    buyAsset: string,
    sellAmount: string
  ): Promise<Quote> {
    const exchangeRate = await this.getExchangeRate(sellAsset, buyAsset);
    
    const sellAmountNum = parseFloat(sellAmount);
    const fee = sellAmountNum * 0.01; // 1% fee
    const netAmount = sellAmountNum - fee;
    const buyAmount = (netAmount * exchangeRate.rate).toFixed(2);

    const quote: Quote = {
      id: uuidv4(),
      price: exchangeRate.rate.toString(),
      sellAsset,
      buyAsset,
      sellAmount: sellAmount,
      buyAmount: buyAmount,
      expiresAt: exchangeRate.validUntil,
      fee: {
        total: fee.toFixed(2),
        asset: sellAsset,
      },
    };

    this.quotes.set(quote.id, quote);
    
    logger.info('SEP-31 quote created', { quoteId: quote.id, sellAsset, buyAsset });
    
    return quote;
  }

  /**
   * Get an existing quote by ID
   */
  getQuote(quoteId: string): Quote | null {
    const quote = this.quotes.get(quoteId);
    
    if (!quote) {
      return null;
    }

    // Check if quote expired
    if (new Date() > quote.expiresAt) {
      this.quotes.delete(quoteId);
      return null;
    }

    return quote;
  }

  /**
   * Initiate cross-border transaction
   */
  async initiateTransaction(
    quoteId: string,
    senderId: string,
    receiverId: string,
    senderAccount: string,
    receiverAccount: string,
    senderSecretKey?: string
  ): Promise<CrossBorderTransaction> {
    const quote = this.getQuote(quoteId);
    
    if (!quote) {
      throw new Error('Quote not found or expired');
    }

    const transaction: CrossBorderTransaction = {
      id: uuidv4(),
      status: 'pending',
      sendAmount: quote.sellAmount,
      sendCurrency: quote.sellAsset,
      receiveAmount: quote.buyAmount,
      receiveCurrency: quote.buyAsset,
      senderId,
      receiverId,
      senderAccount,
      receiverAccount,
      quoteId,
      createdAt: new Date(),
    };

    this.transactions.set(transaction.id, transaction);

    logger.info('Cross-border transaction initiated', { 
      txId: transaction.id,
      sendCurrency: quote.sellAsset,
      receiveCurrency: quote.buyAsset 
    });

    // If sender secret key provided, execute immediately
    if (senderSecretKey) {
      await this.executeTransaction(transaction.id, senderSecretKey);
    }

    return transaction;
  }

  /**
   * Execute the actual Stellar transaction
   */
  async executeTransaction(
    transactionId: string,
    senderSecretKey: string
  ): Promise<CrossBorderTransaction> {
    const transaction = this.transactions.get(transactionId);
    
    if (!transaction) {
      throw new Error('Transaction not found');
    }

    if (transaction.status === 'completed') {
      throw new Error('Transaction already completed');
    }

    try {
      transaction.status = 'processing';
      this.transactions.set(transactionId, transaction);

      const sourceKeypair = StellarSdk.Keypair.fromSecret(senderSecretKey);
      const sourceAccount = await this.server.loadAccount(sourceKeypair.publicKey());

      // Build payment transaction with path payment strict send
      const sendAsset = new StellarSdk.Asset(
        transaction.sendCurrency,
        SUPPORTED_CURRENCIES[transaction.sendCurrency as keyof typeof SUPPORTED_CURRENCIES].issuer
      );
      
      const destAsset = new StellarSdk.Asset(
        transaction.receiveCurrency,
        SUPPORTED_CURRENCIES[transaction.receiveCurrency as keyof typeof SUPPORTED_CURRENCIES].issuer
      );

      const txBuilder = new StellarSdk.TransactionBuilder(sourceAccount, {
        fee: StellarSdk.BASE_FEE,
        networkPassphrase: StellarSdk.Networks.TESTNET,
      });

      // Add path payment operation
      txBuilder.addOperation(
        StellarSdk.Operation.pathPaymentStrictSend({
          sendAsset,
          sendAmount: transaction.sendAmount,
          destination: transaction.receiverAccount,
          destAsset,
          destMin: (parseFloat(transaction.receiveAmount) * 0.98).toFixed(7), // 2% slippage
        })
      );

      const builtTx = txBuilder.setTimeout(180).build();
      builtTx.sign(sourceKeypair);

      const result = await this.server.submitTransaction(builtTx);

      transaction.status = 'completed';
      transaction.stellarTxHash = result.hash;
      transaction.completedAt = new Date();
      this.transactions.set(transactionId, transaction);

      logger.info('Cross-border transaction completed', { 
        txId: transactionId,
        stellarTxHash: result.hash 
      });

      return transaction;
    } catch (error) {
      transaction.status = 'failed';
      this.transactions.set(transactionId, transaction);
      
      logger.error('Cross-border transaction failed', { txId: transactionId, error });
      throw error;
    }
  }

  /**
   * Get transaction by ID
   */
  getTransaction(transactionId: string): CrossBorderTransaction | null {
    return this.transactions.get(transactionId) || null;
  }

  /**
   * Get all transactions for a user
   */
  getUserTransactions(userId: string): CrossBorderTransaction[] {
    return Array.from(this.transactions.values()).filter(
      tx => tx.senderId === userId || tx.receiverId === userId
    );
  }

  /**
   * Get supported currency pairs
   */
  getSupportedCurrencies() {
    return SUPPORTED_CURRENCIES;
  }

  /**
   * Validate if currency pair is supported
   */
  isCurrencyPairSupported(sourceCurrency: string, destCurrency: string): boolean {
    return !!(
      SUPPORTED_CURRENCIES[sourceCurrency as keyof typeof SUPPORTED_CURRENCIES] &&
      SUPPORTED_CURRENCIES[destCurrency as keyof typeof SUPPORTED_CURRENCIES] &&
      EXCHANGE_RATES[sourceCurrency]?.[destCurrency]
    );
  }
}

export const sep31Service = new SEP31Service();
