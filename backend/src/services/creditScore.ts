/**
 * Credit Score Contract Service
 * Reads on-chain credit scores from the Soroban credit-score contract
 * Falls back to database scores when contract is unavailable
 */

import { SorobanRpc, Contract, XdrLargeInt, Address, nativeToScVal, xdr } from '@stellar/stellar-sdk';
import { config } from '../config/environment';
import { logger } from '../utils/logger';
import db from './database';

interface OnChainCreditProfile {
  score: number;
  tier: string;
  totalTransactions: number;
  totalAmount: string;
  activeDays: number;
  currentStreak: number;
  longestStreak: number;
  uniqueStations: number;
  lastUpdated: number;
  factors: {
    ageFactor: number;
    frequencyFactor: number;
    consistencyFactor: number;
    volumeFactor: number;
    diversityFactor: number;
  };
}

const TIER_MAP: Record<number, string> = {
  0: 'UNSCORED',
  1: 'BRONZE',
  2: 'SILVER',
  3: 'GOLD',
  4: 'PLATINUM',
};

class CreditScoreService {
  private rpcUrl: string;
  private contractId: string;

  constructor() {
    this.rpcUrl = config.stellarSorobanRpcUrl;
    this.contractId = config.creditScoreContractId;
  }

  /**
   * Fetch credit profile from on-chain contract
   */
  async getOnChainCreditProfile(stellarPublicKey: string): Promise<OnChainCreditProfile | null> {
    if (!this.contractId) {
      logger.warn('Credit score contract ID not configured - using DB fallback');
      return null;
    }

    try {
      const server = new SorobanRpc.Server(this.rpcUrl);
      const contract = new Contract(this.contractId);

      // Call get_score(user: Address) on the contract
      const userAddress = new Address(stellarPublicKey);

      const tx = contract.call(
        'get_score',
        nativeToScVal(userAddress, { type: 'address' })
      );

      const result = await server.simulateTransaction(
        // We do a minimal simulation to read state
        tx as any
      );

      if (!SorobanRpc.Api.isSimulationSuccess(result)) {
        logger.warn('Credit score contract simulation failed:', result);
        return null;
      }

      // Parse the returned XDR value
      const returnVal = result.result?.retval;
      if (!returnVal) return null;

      return this.parseContractResult(returnVal);
    } catch (error: any) {
      // Expected when contract is not deployed or user has no profile
      if (error.message?.includes('not found') || error.message?.includes('missing')) {
        return null;
      }
      logger.warn('Credit score contract call failed (using DB fallback):', error.message);
      return null;
    }
  }

  /**
   * Parse XDR contract result into structured data
   */
  private parseContractResult(retval: xdr.ScVal): OnChainCreditProfile | null {
    try {
      // The contract returns a CreditProfile struct
      // Attempt to parse as map (struct fields)
      const map = retval.map();
      if (!map) return null;

      const getValue = (key: string): any => {
        const entry = map.find(e => e.key().sym()?.toString() === key);
        return entry?.val();
      };

      const scoreVal = getValue('score');
      const tierVal = getValue('tier');
      const ageFactorVal = getValue('age_factor');

      if (!scoreVal) return null;

      const score = scoreVal.u32() ?? 0;
      const tierIndex = tierVal ? Object.values(tierVal).length : 0;

      return {
        score,
        tier: TIER_MAP[tierIndex] || 'UNSCORED',
        totalTransactions: Number(getValue('total_transactions')?.u64() ?? 0),
        totalAmount: String(getValue('total_amount')?.i128() ?? 0),
        activeDays: getValue('active_days')?.u32() ?? 0,
        currentStreak: getValue('current_streak')?.u32() ?? 0,
        longestStreak: getValue('longest_streak')?.u32() ?? 0,
        uniqueStations: getValue('unique_stations')?.u32() ?? 0,
        lastUpdated: Number(getValue('last_score_update')?.u64() ?? 0),
        factors: {
          ageFactor: ageFactorVal?.u32() ?? 0,
          frequencyFactor: getValue('frequency_factor')?.u32() ?? 0,
          consistencyFactor: getValue('consistency_factor')?.u32() ?? 0,
          volumeFactor: getValue('volume_factor')?.u32() ?? 0,
          diversityFactor: getValue('diversity_factor')?.u32() ?? 0,
        },
      };
    } catch (error) {
      logger.warn('Failed to parse credit score contract result:', error);
      return null;
    }
  }

  /**
   * Get credit score — tries on-chain first, falls back to DB
   */
  async getCreditScore(userId: string, stellarPublicKey: string): Promise<{
    score: number;
    tier: string;
    source: 'blockchain' | 'database';
    factors?: OnChainCreditProfile['factors'];
    totalTransactions?: number;
    activeDays?: number;
    uniqueStations?: number;
    currentStreak?: number;
  }> {
    // Try on-chain first
    const onChain = await this.getOnChainCreditProfile(stellarPublicKey);
    if (onChain) {
      // Keep DB in sync
      try {
        const riderProfile = await db.getRiderProfile(userId);
        if (riderProfile && riderProfile.credit_score !== onChain.score) {
          await db.updateRiderCreditScore(userId, onChain.score);
        }
      } catch (_) { /* best-effort DB sync */ }

      return {
        score: onChain.score,
        tier: onChain.tier,
        source: 'blockchain',
        factors: onChain.factors,
        totalTransactions: onChain.totalTransactions,
        activeDays: onChain.activeDays,
        uniqueStations: onChain.uniqueStations,
        currentStreak: onChain.currentStreak,
      };
    }

    // Fallback to DB
    try {
      const riderProfile = await db.getRiderProfile(userId);
      if (!riderProfile) {
        return { score: 0, tier: 'UNSCORED', source: 'database' };
      }

      const score = riderProfile.credit_score;
      const tier = scoreToTier(score);

      return {
        score,
        tier,
        source: 'database',
        totalTransactions: riderProfile.total_transactions,
      };
    } catch (error) {
      logger.error('Failed to get credit score from DB:', error);
      return { score: 0, tier: 'UNSCORED', source: 'database' };
    }
  }

  /**
   * Calculate recommended credit limit based on score/tier
   */
  getRecommendedLimit(score: number, tier: string): number {
    const limits: Record<string, number> = {
      UNSCORED: 0,
      BRONZE: 10000,
      SILVER: 50000,
      GOLD: 100000,
      PLATINUM: 500000,
    };
    return limits[tier] || 0;
  }

  /**
   * Get available credit products for a tier
   */
  getAvailableProducts(tier: string): any[] {
    const products: Record<string, any[]> = {
      UNSCORED: [],
      BRONZE: [
        { name: 'Fuel Micro-Loan', maxAmount: 5000, interestRate: 5, termDays: 7 },
      ],
      SILVER: [
        { name: 'Fuel Micro-Loan', maxAmount: 10000, interestRate: 4, termDays: 14 },
        { name: 'Weekly Fuel Credit', maxAmount: 25000, interestRate: 3.5, termDays: 7 },
      ],
      GOLD: [
        { name: 'Fuel Micro-Loan', maxAmount: 25000, interestRate: 3, termDays: 30 },
        { name: 'Weekly Fuel Credit', maxAmount: 50000, interestRate: 2.5, termDays: 7 },
        { name: 'Bulk Fuel Discount', discount: 5, minimumPurchase: 50000 },
      ],
      PLATINUM: [
        { name: 'Fuel Micro-Loan', maxAmount: 100000, interestRate: 2, termDays: 30 },
        { name: 'Weekly Fuel Credit', maxAmount: 200000, interestRate: 2, termDays: 7 },
        { name: 'Bulk Fuel Discount', discount: 10, minimumPurchase: 100000 },
        { name: 'Insurance Package', coverage: 'Comprehensive', premium: 'Reduced' },
      ],
    };
    return products[tier] || [];
  }
}

export function scoreToTier(score: number): string {
  if (score >= 750) return 'PLATINUM';
  if (score >= 650) return 'GOLD';
  if (score >= 500) return 'SILVER';
  if (score >= 300) return 'BRONZE';
  return 'UNSCORED';
}

export const creditScoreService = new CreditScoreService();
