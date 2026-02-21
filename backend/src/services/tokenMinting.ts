/**
 * Token Minting Service
 * Handles FUEL token minting for mobile money deposits
 */

import * as StellarSdk from '@stellar/stellar-sdk';
import { config } from '../config/environment';
import { logger } from '../utils/logger';
import db from './database';

// Exchange rate: 1 KES = X FUEL tokens
const EXCHANGE_RATES: Record<string, number> = {
  KES: 0.1,    // 1 KES = 0.1 FUEL (10 KES = 1 FUEL)
  UGX: 0.03,   // 1 UGX = 0.03 FUEL (~33 UGX = 1 FUEL)
  TZS: 0.045,  // 1 TZS = 0.045 FUEL (~22 TZS = 1 FUEL)
  RWF: 0.012,  // 1 RWF = 0.012 FUEL (~83 RWF = 1 FUEL)
};

export interface MintRequest {
  userPublicKey: string;
  amount: number;
  currency: string;
  transactionRef: string;
  provider: 'mpesa' | 'mtn' | 'airtel';
}

export interface MintResult {
  success: boolean;
  fuelAmount: number;
  stellarTxHash?: string;
  error?: string;
}

class TokenMintingService {
  private server: StellarSdk.Horizon.Server;
  private issuerKeypair: StellarSdk.Keypair | null = null;

  constructor() {
    this.server = new StellarSdk.Horizon.Server(config.stellarHorizonUrl);
    this.initialize();
  }

  private initialize(): void {
    try {
      if (!config.distributorSecretKey) {
        logger.warn('Distributor secret key not configured - minting will fail');
        return;
      }

      this.issuerKeypair = StellarSdk.Keypair.fromSecret(config.distributorSecretKey);
      logger.info('Token minting service initialized');
    } catch (error) {
      logger.error('Failed to initialize token minting service:', error);
    }
  }

  /**
   * Calculate FUEL tokens for a given fiat amount
   */
  calculateFuelAmount(fiatAmount: number, currency: string): number {
    const rate = EXCHANGE_RATES[currency] || EXCHANGE_RATES.KES;
    return Math.floor(fiatAmount * rate * 100) / 100; // Round to 2 decimals
  }

  /**
   * Mint FUEL tokens and send to user
   */
  async mintAndTransfer(request: MintRequest): Promise<MintResult> {
    try {
      if (!this.issuerKeypair) {
        throw new Error('Token minting service not initialized');
      }

      if (!config.fuelTokenContractId) {
        throw new Error('FUEL token contract ID not configured');
      }

      const fuelAmount = this.calculateFuelAmount(request.amount, request.currency);

      logger.info(`Minting ${fuelAmount} FUEL for ${request.amount} ${request.currency} to ${request.userPublicKey}`);

      // Load issuer account
      const issuerAccount = await this.server.loadAccount(this.issuerKeypair.publicKey());

      // Create FUEL token asset
      const fuelAsset = new StellarSdk.Asset(
        'FUEL',
        config.fuelTokenIssuer || this.issuerKeypair.publicKey()
      );

      // Build payment transaction
      const transaction = new StellarSdk.TransactionBuilder(issuerAccount, {
        fee: StellarSdk.BASE_FEE,
        networkPassphrase: config.stellarNetwork === 'testnet' 
          ? StellarSdk.Networks.TESTNET 
          : StellarSdk.Networks.PUBLIC,
      })
        .addOperation(
          StellarSdk.Operation.payment({
            destination: request.userPublicKey,
            asset: fuelAsset,
            amount: fuelAmount.toString(),
          })
        )
        .addMemo(StellarSdk.Memo.text(`${request.provider}:${request.transactionRef}`))
        .setTimeout(30)
        .build();

      // Sign with issuer keypair
      transaction.sign(this.issuerKeypair);

      // Submit transaction
      const result = await this.server.submitTransaction(transaction);

      logger.info(`Minted ${fuelAmount} FUEL - Tx: ${result.hash}`);

      // Record transaction in database
      try {
        // Get user ID from public key
        const userProfile = await db.getUserByPublicKey(request.userPublicKey);
        if (userProfile) {
          await db.createTransaction({
            blockchain_hash: result.hash,
            from_user_id: this.issuerKeypair.publicKey(), // Issuer/distributor
            to_user_id: userProfile.id,
            amount: fuelAmount,
            status: 'completed',
          });

          // Update rider stats if applicable
          if (userProfile.role === 'rider') {
            await db.updateRiderStats(userProfile.id, fuelAmount);
          }
        }
      } catch (dbError) {
        logger.warn('Failed to record minting transaction in database:', dbError);
        // Don't fail the entire operation if database update fails
      }

      return {
        success: true,
        fuelAmount,
        stellarTxHash: result.hash,
      };
    } catch (error: any) {
      logger.error('Token minting failed:', error);
      return {
        success: false,
        fuelAmount: this.calculateFuelAmount(request.amount, request.currency),
        error: error.message || 'Token minting failed',
      };
    }
  }

  /**
   * Burn FUEL tokens (for withdrawals)
   */
 async burnTokens(userPublicKey: string, fuelAmount: number, userSecretKey: string): Promise<MintResult> {
    try {
      if (!this.issuerKeypair) {
        throw new Error('Token minting service not initialized');
      }

      logger.info(`Burning ${fuelAmount} FUEL from ${userPublicKey}`);

      const userKeypair = StellarSdk.Keypair.fromSecret(userSecretKey);
      const userAccount = await this.server.loadAccount(userPublicKey);

      // Create FUEL token asset
      const fuelAsset = new StellarSdk.Asset(
        'FUEL',
        config.fuelTokenIssuer || this.issuerKeypair.publicKey()
      );

      // Build payment transaction back to issuer (burns tokens)
      const transaction = new StellarSdk.TransactionBuilder(userAccount, {
        fee: StellarSdk.BASE_FEE,
        networkPassphrase: config.stellarNetwork === 'testnet' 
          ? StellarSdk.Networks.TESTNET 
          : StellarSdk.Networks.PUBLIC,
      })
        .addOperation(
          StellarSdk.Operation.payment({
            destination: this.issuerKeypair.publicKey(),
            asset: fuelAsset,
            amount: fuelAmount.toString(),
          })
        )
        .addMemo(StellarSdk.Memo.text('withdrawal'))
        .setTimeout(30)
        .build();

      // Sign with user keypair
      transaction.sign(userKeypair);

      // Submit transaction
      const result = await this.server.submitTransaction(transaction);

      logger.info(`Burned ${fuelAmount} FUEL - Tx: ${result.hash}`);

      // Record transaction in database
      try {
        const userProfile = await db.getUserByPublicKey(userPublicKey);
        if (userProfile) {
          await db.createTransaction({
            blockchain_hash: result.hash,
            from_user_id: userProfile.id,
            to_user_id: this.issuerKeypair.publicKey(), // Issuer
            amount: fuelAmount,
            status: 'completed',
          });
        }
      } catch (dbError) {
        logger.warn('Failed to record burn transaction in database:', dbError);
      }

      return {
        success: true,
        fuelAmount,
        stellarTxHash: result.hash,
      };
    } catch (error: any) {
      logger.error('Token burning failed:', error);
      return {
        success: false,
        fuelAmount,
        error: error.message || 'Token burning failed',
      };
    }
  }

  /**
   * Check if user has sufficient balance for withdrawal
   */
  async checkBalance(userPublicKey: string, requiredAmount: number): Promise<boolean> {
    try {
      const account = await this.server.loadAccount(userPublicKey);
      
      const fuelAsset = new StellarSdk.Asset(
        'FUEL',
        config.fuelTokenIssuer || this.issuerKeypair!.publicKey()
      );

      const balance = account.balances.find(
        (b: any) => b.asset_type !== 'native' && b.asset_code === 'FUEL'
      );

      if (!balance) return false;

      return parseFloat(balance.balance) >= requiredAmount;
    } catch (error) {
      logger.error('Failed to check balance:', error);
      return false;
    }
  }

  /**
   * Get current exchange rate for a currency
   */
  getExchangeRate(currency: string): number {
    return EXCHANGE_RATES[currency] || EXCHANGE_RATES.KES;
  }

  /**
   * Calculate fiat amount for FUEL tokens (inverse conversion)
   */
  calculateFiatAmount(fuelAmount: number, currency: string): number {
    const rate = this.getExchangeRate(currency);
    return Math.ceil(fuelAmount / rate); // Round up to ensure user gets full value
  }
}

// Export singleton instance
export const tokenMinting = new TokenMintingService();
export default tokenMinting;
