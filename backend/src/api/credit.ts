/**
 * Credit Score Routes
 */

import { Router, Request, Response } from 'express';
import { param, query, validationResult } from 'express-validator';
import { asyncHandler, AppError } from '../middleware/errorHandler';
import { authenticate, authorize } from '../middleware/auth';
import { logger } from '../utils/logger';

const router = Router();

// In-memory credit profiles
const creditProfiles: Map<string, any> = new Map();

/**
 * Get credit score for authenticated user
 */
router.get(
  '/score',
  authenticate,
  asyncHandler(async (req: Request, res: Response) => {
    const profile = creditProfiles.get(req.user?.walletAddress || '');

    if (!profile) {
      // Return new user status
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
        score: profile.score,
        tier: profile.tier,
        totalTransactions: profile.totalTransactions,
        accountAgeDays: profile.accountAgeDays,
        factors: profile.factors,
        lastUpdated: profile.lastUpdated,
        eligibleForCredit: profile.score >= 500,
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
    const profile = creditProfiles.get(req.user?.walletAddress || '');

    if (!profile) {
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

    res.json({
      success: true,
      data: {
        overallScore: profile.score,
        tier: profile.tier,
        factors: {
          age: { 
            score: profile.factors.age, 
            description: 'Account age (20% weight)',
            tip: profile.factors.age < 80 ? 'Continue using FuelAnchor to build history' : 'Excellent account age!'
          },
          frequency: { 
            score: profile.factors.frequency, 
            description: 'Transaction frequency (25% weight)',
            tip: profile.factors.frequency < 80 ? 'Make regular fuel purchases' : 'Great transaction frequency!'
          },
          consistency: { 
            score: profile.factors.consistency, 
            description: 'Usage consistency (25% weight)',
            tip: profile.factors.consistency < 80 ? 'Maintain daily usage streaks' : 'Excellent consistency!'
          },
          volume: { 
            score: profile.factors.volume, 
            description: 'Transaction volume (15% weight)',
            tip: profile.factors.volume < 80 ? 'Higher volume improves score' : 'Strong transaction volume!'
          },
          diversity: { 
            score: profile.factors.diversity, 
            description: 'Station diversity (15% weight)',
            tip: profile.factors.diversity < 80 ? 'Visit multiple stations' : 'Great station diversity!'
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
    const profile = creditProfiles.get(req.user?.walletAddress || '');

    const baseEligibility = {
      isEligible: false,
      reason: 'Insufficient credit history',
      recommendedLimit: 0,
      availableProducts: [],
    };

    if (!profile || profile.score < 500) {
      res.json({
        success: true,
        data: {
          ...baseEligibility,
          requirements: {
            minimumScore: 500,
            currentScore: profile?.score || 0,
            minimumDays: 90,
            currentDays: profile?.accountAgeDays || 0,
          },
        },
      });
      return;
    }

    // Calculate recommended credit limit based on tier
    let recommendedLimit = 0;
    let availableProducts: any[] = [];

    switch (profile.tier) {
      case 'BRONZE':
        recommendedLimit = 10000; // KES 10,000
        availableProducts = [
          { name: 'Fuel Micro-Loan', maxAmount: 5000, interestRate: 5, termDays: 7 },
        ];
        break;
      case 'SILVER':
        recommendedLimit = 50000;
        availableProducts = [
          { name: 'Fuel Micro-Loan', maxAmount: 10000, interestRate: 4, termDays: 14 },
          { name: 'Weekly Fuel Credit', maxAmount: 25000, interestRate: 3.5, termDays: 7 },
        ];
        break;
      case 'GOLD':
        recommendedLimit = 100000;
        availableProducts = [
          { name: 'Fuel Micro-Loan', maxAmount: 25000, interestRate: 3, termDays: 30 },
          { name: 'Weekly Fuel Credit', maxAmount: 50000, interestRate: 2.5, termDays: 7 },
          { name: 'Bulk Fuel Discount', discount: 5, minimumPurchase: 50000 },
        ];
        break;
      case 'PLATINUM':
        recommendedLimit = 500000;
        availableProducts = [
          { name: 'Fuel Micro-Loan', maxAmount: 100000, interestRate: 2, termDays: 30 },
          { name: 'Weekly Fuel Credit', maxAmount: 200000, interestRate: 2, termDays: 7 },
          { name: 'Bulk Fuel Discount', discount: 10, minimumPurchase: 100000 },
          { name: 'Insurance Package', coverage: 'Comprehensive', premium: 'Reduced' },
        ];
        break;
    }

    res.json({
      success: true,
      data: {
        isEligible: true,
        creditScore: profile.score,
        tier: profile.tier,
        recommendedLimit,
        availableProducts,
        benefits: getTierBenefits(profile.tier),
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
  [
    // body('userWallet').notEmpty(),
  ],
  asyncHandler(async (req: Request, res: Response) => {
    const { userWallet } = req.body;
    const profile = creditProfiles.get(userWallet);

    logger.info(`Credit inquiry for ${userWallet} by ${req.user?.userId}`);

    if (!profile) {
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

    res.json({
      success: true,
      data: {
        userWallet,
        hasProfile: true,
        score: profile.score,
        tier: profile.tier,
        accountAgeDays: profile.accountAgeDays,
        totalTransactions: profile.totalTransactions,
        isEligibleForCredit: profile.score >= 500,
        recommendedLimit: calculateRecommendedLimit(profile),
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

    // Simple simulation algorithm
    const ageFactor = Math.min(100, (daysSinceFirstTransaction / 365) * 100);
    const frequencyFactor = Math.min(100, transactions * 2);
    const consistencyFactor = Math.min(100, Math.random() * 50 + 50); // Random for demo
    const volumeFactor = Math.min(100, transactions * 5);
    const diversityFactor = Math.min(100, uniqueStations * 10);

    const weightedScore = (
      ageFactor * 0.20 +
      frequencyFactor * 0.25 +
      consistencyFactor * 0.25 +
      volumeFactor * 0.15 +
      diversityFactor * 0.15
    );

    const score = Math.round(300 + (weightedScore / 100) * 550); // 300-850 range

    let tier = 'UNSCORED';
    if (score >= 750) tier = 'PLATINUM';
    else if (score >= 650) tier = 'GOLD';
    else if (score >= 500) tier = 'SILVER';
    else if (score >= 300) tier = 'BRONZE';

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
        recommendation: score < 500 
          ? 'Continue building your transaction history for 90+ days'
          : `You would qualify for ${tier} tier benefits!`,
      },
    });
  })
);

function getTierBenefits(tier: string): string[] {
  const benefits: { [key: string]: string[] } = {
    BRONZE: [
      'Access to fuel micro-loans',
      'Basic transaction insights',
    ],
    SILVER: [
      'Higher loan limits',
      'Weekly fuel credit',
      'Priority customer support',
    ],
    GOLD: [
      'Premium loan rates',
      'Bulk fuel discounts (5%)',
      'Partner merchant offers',
      'Insurance eligibility',
    ],
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

function calculateRecommendedLimit(profile: any): number {
  const baseLimit = profile.score * 100;
  const volumeMultiplier = Math.min(2, 1 + (profile.totalTransactions / 500));
  return Math.round(baseLimit * volumeMultiplier);
}

export default router;
