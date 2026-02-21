/**
 * Credit Score Routes â€“ backed by Soroban on-chain score + Supabase DB
 */

import { Router, Request, Response } from 'express';
import { body, validationResult } from 'express-validator';
import { asyncHandler, AppError } from '../middleware/errorHandler';
import { authenticate, authorize } from '../middleware/auth';
import { creditScoreService, scoreToTier } from '../services/creditScore';
import db from '../services/database';
import { logger } from '../utils/logger';

const router = Router();

/**
 * Get credit score for authenticated user
 */
router.get(
  '/score',
  authenticate,
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!.userId;
    const walletAddress = req.user!.walletAddress;

    let creditData: any;
    try {
      creditData = await creditScoreService.getCreditScore(userId, walletAddress || '');
    } catch (err) {
      logger.warn(`Credit score fetch failed for ${userId}:`, err);
      creditData = null;
    }

    if (!creditData || creditData.score === 0) {
      res.json({
        success: true,
        data: {
          score: 0,
          tier: 'UNSCORED',
          daysUntilScorable: 90,
          message: 'Build your credit history by making consistent fuel purchases',
          factors: null,
        },
      });
      return;
    }

    res.json({
      success: true,
      data: {
        score: creditData.score,
        tier: creditData.tier,
        totalTransactions: creditData.totalTransactions,
        accountAgeDays: creditData.accountAgeDays,
        source: creditData.source,
        lastUpdated: creditData.lastUpdated,
        eligibleForCredit: creditData.score >= 500,
      },
    });
  })
);

/**
 * Get credit score breakdown/factors
 */
router.get(
  '/factors',
  authenticate,
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!.userId;
    const walletAddress = req.user!.walletAddress;

    let creditData: any;
    try {
      creditData = await creditScoreService.getCreditScore(userId, walletAddress || '');
    } catch {
      creditData = null;
    }

    if (!creditData || creditData.score === 0) {
      res.json({
        success: true,
        data: {
          message: 'No credit history yet',
          factors: {
            age: { score: 0, description: 'Account age (20% weight)', tip: 'Continue using FuelAnchor to build history' },
            frequency: { score: 0, description: 'Transaction frequency (25% weight)', tip: 'Make regular fuel purchases' },
            consistency: { score: 0, description: 'Usage consistency (25% weight)', tip: 'Maintain daily usage streaks' },
            volume: { score: 0, description: 'Transaction volume (15% weight)', tip: 'Higher volume improves score' },
            diversity: { score: 0, description: 'Station diversity (15% weight)', tip: 'Visit multiple stations' },
          },
        },
      });
      return;
    }

    const f = creditData.factors || {};
    res.json({
      success: true,
      data: {
        overallScore: creditData.score,
        tier: creditData.tier,
        source: creditData.source,
        factors: {
          age: {
            score: f.age ?? 0,
            description: 'Account age (20% weight)',
            tip: (f.age ?? 0) < 80 ? 'Continue using FuelAnchor to build history' : 'Excellent account age!',
          },
          frequency: {
            score: f.frequency ?? 0,
            description: 'Transaction frequency (25% weight)',
            tip: (f.frequency ?? 0) < 80 ? 'Make regular fuel purchases' : 'Great transaction frequency!',
          },
          consistency: {
            score: f.consistency ?? 0,
            description: 'Usage consistency (25% weight)',
            tip: (f.consistency ?? 0) < 80 ? 'Maintain daily usage streaks' : 'Excellent consistency!',
          },
          volume: {
            score: f.volume ?? 0,
            description: 'Transaction volume (15% weight)',
            tip: (f.volume ?? 0) < 80 ? 'Higher volume improves score' : 'Strong transaction volume!',
          },
          diversity: {
            score: f.diversity ?? 0,
            description: 'Station diversity (15% weight)',
            tip: (f.diversity ?? 0) < 80 ? 'Visit multiple stations' : 'Great station diversity!',
          },
        },
      },
    });
  })
);
/**
 * Get credit eligibility and loan recommendations
 */
router.get(
  '/eligibility',
  authenticate,
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!.userId;
    const walletAddress = req.user!.walletAddress;

    let creditData: any;
    try {
      creditData = await creditScoreService.getCreditScore(userId, walletAddress || '');
    } catch {
      creditData = null;
    }

    const score = creditData?.score ?? 0;
    const tier = scoreToTier(score);

    if (score < 500) {
      res.json({
        success: true,
        data: {
          isEligible: false,
          reason: 'Insufficient credit history',
          recommendedLimit: 0,
          availableProducts: [],
          requirements: {
            minimumScore: 500,
            currentScore: score,
            minimumDays: 90,
            currentDays: creditData?.accountAgeDays || 0,
          },
        },
      });
      return;
    }

    const recommendedLimit = creditScoreService.getRecommendedLimit(score, tier);
    const availableProducts = creditScoreService.getAvailableProducts(tier);

    res.json({
      success: true,
      data: {
        isEligible: true,
        creditScore: score,
        tier,
        recommendedLimit,
        availableProducts,
        benefits: getTierBenefits(tier),
      },
    });
  })
);

/**
 * Credit inquiry endpoint (for authorized lenders/MFIs)
 */
router.post(
  '/inquiry',
  authenticate,
  authorize('admin'),
  [body('userWallet').optional().notEmpty()],
  asyncHandler(async (req: Request, res: Response) => {
    const { userWallet } = req.body;
    logger.info(`Credit inquiry for ${userWallet} by ${req.user?.userId}`);

    // Look up user by wallet address
    let targetProfile: any = null;
    try {
      const profiles = await db.getRiderProfile('');  // placeholder
      void profiles;
    } catch {
      // ignore
    }

    let creditData: any = null;
    if (userWallet) {
      try {
        creditData = await creditScoreService.getCreditScore('', userWallet);
      } catch {
        // no score found
      }
    }

    if (!creditData || creditData.score === 0) {
      res.json({
        success: true,
        data: {
          userWallet,
          hasProfile: false,
          score: 0,
          tier: 'UNSCORED',
          isEligibleForCredit: false,
          inquiryTimestamp: new Date().toISOString(),
        },
      });
      return;
    }

    const tier = scoreToTier(creditData.score);
    res.json({
      success: true,
      data: {
        userWallet,
        hasProfile: true,
        score: creditData.score,
        tier,
        accountAgeDays: creditData.accountAgeDays,
        totalTransactions: creditData.totalTransactions,
        isEligibleForCredit: creditData.score >= 500,
        recommendedLimit: creditScoreService.getRecommendedLimit(creditData.score, tier),
        inquiryTimestamp: new Date().toISOString(),
      },
    });
  })
);

/**
 * Simulate credit score for demo purposes
 */
router.post(
  '/simulate',
  authenticate,
  asyncHandler(async (req: Request, res: Response) => {
    const { transactions, daysSinceFirstTransaction, uniqueStations } = req.body;

    const ageFactor = Math.min(100, (daysSinceFirstTransaction / 365) * 100);
    const frequencyFactor = Math.min(100, transactions * 2);
    const consistencyFactor = Math.min(100, Math.random() * 50 + 50);
    const volumeFactor = Math.min(100, transactions * 5);
    const diversityFactor = Math.min(100, uniqueStations * 10);

    const weightedScore =
      ageFactor * 0.2 +
      frequencyFactor * 0.25 +
      consistencyFactor * 0.25 +
      volumeFactor * 0.15 +
      diversityFactor * 0.15;

    const score = Math.round(300 + (weightedScore / 100) * 550);
    const tier = scoreToTier(score);

    res.json({
      success: true,
      data: {
        simulatedScore: score,
        tier,
        factors: {
          age: Math.round(ageFactor),
          frequency: Math.round(frequencyFactor),
          consistency: Math.round(consistencyFactor),
          volume: Math.round(volumeFactor),
          diversity: Math.round(diversityFactor),
        },
        recommendation:
          score < 500
            ? 'Continue building your transaction history for 90+ days'
            : `You would qualify for ${tier} tier benefits!`,
      },
    });
  })
);

function getTierBenefits(tier: string): string[] {
  const benefits: Record<string, string[]> = {
    BRONZE: ['Access to fuel micro-loans', 'Basic transaction insights'],
    SILVER: ['Higher loan limits', 'Weekly fuel credit', 'Priority customer support'],
    GOLD: ['Premium loan rates', 'Bulk fuel discounts (5%)', 'Partner merchant offers', 'Insurance eligibility'],
    PLATINUM: [
      'Lowest interest rates',
      'Maximum credit limits',
      'Bulk fuel discounts (10%)',
      'Comprehensive insurance',
      'VIP support',
      'Partner premium benefits',
    ],
  };
  return benefits[tier] || [];
}

export default router;
