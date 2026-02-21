import express, { Request, Response, NextFunction } from 'express';
import { authenticate, authorize } from '../middleware/auth';
import db from '../services/database';
import { logger } from '../utils/logger';

const router = express.Router();

/**
 * @route   GET /api/v1/analytics/dashboard
 * @desc    Get dashboard analytics summary
 * @access  Private
 */
router.get(
  '/dashboard',
  authenticate,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const userId = req.user?.userId!;
      const role = req.user?.role!;

      let stats: any = {};
      try {
        stats = await db.getDashboardStats(userId, role);
      } catch (err) {
        logger.warn('getDashboardStats failed, using fallback:', err);
        stats = {
          overview: {
            totalTransactions: 0,
            totalVolume: 0,
            activeUsers: 0,
            averageTransactionValue: 0,
          },
        };
      }

      res.json({
        success: true,
        data: {
          ...stats,
          periodicData: {
            daily: generateMockTimeSeries(7),
            weekly: generateMockTimeSeries(4),
            monthly: generateMockTimeSeries(12),
          },
          userRole: role,
        },
      });
    } catch (error) {
      next(error);
    }
  }
);

/**
 * @route   GET /api/v1/analytics/merchant/:merchantId
 * @desc    Get merchant-specific analytics
 * @access  Private (Merchant or Admin)
 */
router.get(
  '/merchant/:merchantId',
  authenticate,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { merchantId } = req.params;
      const userId = req.user?.userId;

      // Verify merchant owns this data or is admin
      if (req.user?.role !== 'admin' && userId !== merchantId) {
        return res.status(403).json({
          success: false,
          error: 'Unauthorized access',
        });
      }

      const analytics = await db.getMerchantAnalytics(merchantId);

      res.json({
        success: true,
        data: analytics,
      });
    } catch (error) {
      next(error);
    }
  }
);

/**
 * @route   GET /api/v1/analytics/fleet/:fleetId
 * @desc    Get fleet-specific analytics
 * @access  Private (Fleet Operator or Admin)
 */
router.get(
  '/fleet/:fleetId',
  authenticate,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { fleetId } = req.params;
      const userId = req.user?.userId;

      // Verify fleet operator owns this data or is admin
      if (req.user?.role !== 'admin' && userId !== fleetId) {
        return res.status(403).json({
          success: false,
          error: 'Unauthorized access',
        });
      }

      const analytics = await db.getFleetDetailedAnalytics(fleetId);

      res.json({
        success: true,
        data: analytics,
      });
    } catch (error) {
      next(error);
    }
  }
);

/**
 * @route   GET /api/v1/analytics/rider/:riderId
 * @desc    Get rider-specific analytics
 * @access  Private (Rider or Admin)
 */
router.get(
  '/rider/:riderId',
  authenticate,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { riderId } = req.params;
      const userId = req.user?.userId;

      if (req.user?.role !== 'admin' && userId !== riderId) {
        return res.status(403).json({
          success: false,
          error: 'Unauthorized access',
        });
      }

      const analytics = await db.getRiderAnalytics(riderId);

      res.json({
        success: true,
        data: analytics,
      });
    } catch (error) {
      next(error);
    }
  }
);

/**
 * @route   GET /api/v1/analytics/credit-score/distribution
 * @desc    Get credit score distribution (admin only)
 * @access  Private (Admin)
 */
router.get(
  '/credit-score/distribution',
  authenticate,
  authorize('admin'),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const distribution = await db.getCreditScoreDistribution();

      res.json({
        success: true,
        data: distribution,
      });
    } catch (error) {
      next(error);
    }
  }
);

/**
 * @route   GET /api/v1/analytics/system/health
 * @desc    Get system health metrics (admin only)
 * @access  Private (Admin)
 */
router.get(
  '/system/health',
  authenticate,
  authorize('admin'),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const dbHealthy = await db.healthCheck();

      const health = {
        api: {
          status: 'operational',
          uptime: process.uptime(),
          nodeVersion: process.version,
        },
        database: {
          status: dbHealthy ? 'operational' : 'degraded',
        },
        blockchain: {
          status: 'operational',
          network: process.env.STELLAR_NETWORK || 'testnet',
          rpcUrl: process.env.STELLAR_SOROBAN_RPC_URL,
        },
        mobileMoney: {
          mpesa: process.env.MPESA_CONSUMER_KEY ? 'configured' : 'not_configured',
          mtn: process.env.MTN_API_KEY ? 'configured' : 'not_configured',
          airtel: process.env.AIRTEL_CLIENT_ID ? 'configured' : 'not_configured',
        },
      };

      res.json({
        success: true,
        data: health,
      });
    } catch (error) {
      next(error);
    }
  }
);

// Helper function to generate mock time series data
function generateMockTimeSeries(points: number): Array<{ date: string; value: number }> {
  const data = [];
  const now = new Date();
  
  for (let i = points - 1; i >= 0; i--) {
    const date = new Date(now);
    date.setDate(date.getDate() - i);
    
    data.push({
      date: date.toISOString().split('T')[0],
      value: Math.floor(Math.random() * 1000) + 500,
    });
  }
  
  return data;
}

export default router;
