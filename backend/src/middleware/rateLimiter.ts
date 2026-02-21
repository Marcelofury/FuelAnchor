import rateLimit from 'express-rate-limit';
import { Request, Response } from 'express';

// General API rate limiter (100 requests per 15 minutes)
export const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100,
  message: 'Too many requests from this IP, please try again later.',
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req: Request, res: Response) => {
    res.status(429).json({
      success: false,
      error: {
        message: 'Too many requests from this IP, please try again after 15 minutes.',
        code: 'RATE_LIMIT_EXCEEDED',
        retryAfter: 900, // seconds
      },
    });
  },
});

// Strict rate limiter for authentication endpoints (5 requests per 15 minutes)
export const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5,
  skipSuccessfulRequests: false,
  message: 'Too many authentication attempts, please try again later.',
  handler: (req: Request, res: Response) => {
    res.status(429).json({
      success: false,
      error: {
        message: 'Too many authentication attempts from this IP. Please try again after 15 minutes.',
        code: 'AUTH_RATE_LIMIT_EXCEEDED',
        retryAfter: 900,
      },
    });
  },
});

// Rate limiter for transaction endpoints (30 requests per minute)
export const transactionLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 30,
  message: 'Too many transaction requests, please slow down.',
  handler: (req: Request, res: Response) => {
    res.status(429).json({
      success: false,
      error: {
        message: 'Too many transaction requests. Please wait a moment before trying again.',
        code: 'TRANSACTION_RATE_LIMIT_EXCEEDED',
        retryAfter: 60,
      },
    });
  },
});

// Rate limiter for credit inquiries (10 per hour)
export const creditInquiryLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 10,
  message: 'Too many credit inquiries, please try again later.',
  handler: (req: Request, res: Response) => {
    res.status(429).json({
      success: false,
      error: {
        message: 'Too many credit inquiry requests. Please try again after 1 hour.',
        code: 'CREDIT_INQUIRY_RATE_LIMIT',
        retryAfter: 3600,
      },
    });
  },
});

// Rate limiter for webhook endpoints (100 per minute)
export const webhookLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 100,
  skipFailedRequests: true,
  message: 'Webhook rate limit exceeded',
});

// Create a custom rate limiter with Redis (for production use)
// This would require Redis connection configuration
export const createRedisRateLimiter = (windowMs: number, max: number) => {
  // TODO: Implement Redis-based rate limiter for distributed environments
  // This is a placeholder for future Redis integration
  return apiLimiter;
};
