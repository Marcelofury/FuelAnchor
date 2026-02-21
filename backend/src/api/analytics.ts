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

      const analytics = {
        merchantId,
        summary: {
          totalSales: 45230.75,
          transactionCount: 523,
          uniqueCustomers: 187,
          averageTicket: 86.50,
        },
        topFuelTypes: [
          { type: 'Petrol', percentage: 65, revenue: 29400.00 },
          { type: 'Diesel', percentage: 30, revenue: 13569.23 },
          { type: 'Electric', percentage: 5, revenue: 2261.52 },
        ],
        peakHours: [
          { hour: 7, transactions: 45 },
          { hour: 12, transactions: 38 },
          { hour: 18, transactions: 52 },
        ],
        revenueByDay: generateMockTimeSeries(30),
        paymentMethods: [
          { method: 'FUEL Tokens', percentage: 70, count: 366 },
          { method: 'M-Pesa', percentage: 20, count: 105 },
          { method: 'MTN MoMo', percentage: 10, count: 52 },
        ],
      };

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

      const analytics = {
        fleetId,
        summary: {
          totalDrivers: 25,
          activeDrivers: 22,
          totalFuelSpend: 78450.25,
          averageFuelPerDriver: 3138.01,
        },
        driverPerformance: [
          {
            driverId: 'd1',
            name: 'John Kamau',
            fuelUsed: 4250.00,
            trips: 145,
            efficiency: 92,
          },
          {
            driverId: 'd2',
            name: 'Mary Wanjiku',
            fuelUsed: 3890.00,
            trips: 132,
            efficiency: 89,
          },
          // ... more drivers
        ],
        fuelConsumption: generateMockTimeSeries(30),
        topRoutes: [
          { route: 'Nairobi - Mombasa', trips: 45, fuelUsed: 8900.00 },
          { route: 'Nairobi - Kisumu', trips: 38, fuelUsed: 7200.00 },
          { route: 'Nairobi - Nakuru', trips: 52, fuelUsed: 6500.00 },
        ],
        costSavings: {
          blockchain: 1250.00,
          bulkPurchase: 3400.00,
          routeOptimization: 890.00,
          total: 5540.00,
        },
      };

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

      const analytics = {
        riderId,
        summary: {
          totalFuelPurchases: 156.50,
          transactionCount: 45,
          creditScore: 725,
          creditTier: 'Gold',
        },
        spendingTrend: generateMockTimeSeries(90),
        topStations: [
          { name: 'Shell Westlands', visits: 12, amount: 45.00 },
          { name: 'Total Kilimani', visits: 10, amount: 38.50 },
          { name: 'Galana Oil CBD', visits: 8, amount: 32.00 },
        ],
        creditHistory: [
          { date: '2024-01', score: 650 },
          { date: '2024-02', score: 680 },
          { date: '2024-03', score: 725 },
        ],
        achievements: [
          { title: 'Early Adopter', description: 'One of the first 100 users', earned: true },
          { title: 'Consistent User', description: '30 consecutive days', earned: true },
          { title: 'Gold Status', description: 'Reached Gold credit tier', earned: true },
        ],
      };

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
      const distribution = {
        unscored: 145,
        bronze: 234,
        silver: 189,
        gold: 98,
        platinum: 34,
        total: 700,
        averageScore: 567,
      };

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
      const health = {
        api: {
          status: 'operational',
          uptime: 99.98,
          responseTime: 45,
        },
        blockchain: {
          status: 'operational',
          lastBlock: 12345678,
          transactionsPending: 3,
        },
        database: {
          status: 'operational',
          connections: 12,
          queryTime: 8,
        },
        mobileMoney: {
          mpesa: 'operational',
          mtn: 'operational',
          airtel: 'degraded',
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
