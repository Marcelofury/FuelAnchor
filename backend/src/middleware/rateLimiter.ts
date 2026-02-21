import rateLimit from 'express-rate-limit';
import { Request, Response } from 'express';
import Redis from 'ioredis';
import { RedisStore } from 'rate-limit-redis';
import { config } from '../config/environment';
import { logger } from '../utils/logger';

// Initialize Redis client (optional - falls back to memory if unavailable)
let redisClient: Redis | null = null;

const initRedis = (): Redis | null => {
  // Only init Redis if REDIS_URL is explicitly configured (not the default fallback)
  if (!process.env.REDIS_URL) return null;
  try {
    const client = new Redis(config.redisUrl, {
      lazyConnect: true,
      maxRetriesPerRequest: 1,
      retryStrategy: () => null, // Don't retry on connection failure
      enableOfflineQueue: false,
    });

    client.on('connect', () => {
      logger.info('Redis connected for rate limiting');
    });

    client.on('error', (err) => {
      // Suppress common connection refused / closed errors
      const msg = err.message || '';
      if (!msg.includes('ECONNREFUSED') && !msg.includes('Connection is closed') && !msg.includes("Stream isn't writeable")) {
        logger.warn('Redis error:', msg);
      }
    });

    // Attempt connection async - don't block startup
    client.connect().catch(() => { /* ignore */ });

    return client;
  } catch (error) {
    logger.warn('Redis unavailable, using in-memory rate limiting');
    return null;
  }
};

try {
  redisClient = initRedis();
} catch {
  redisClient = null;
}

/**
 * Build rate limiter with optional Redis store
 * Redis store is only used after confirmed connection; falls back to memory store.
 */
const buildLimiter = (options: {
  windowMs: number;
  max: number;
  message: string;
  skipSuccessfulRequests?: boolean;
  skipFailedRequests?: boolean;
}) => {
  // Always start with memory store; Redis store is attached after connection confirmed
  const limiter = rateLimit({
    ...options,
    standardHeaders: true,
    legacyHeaders: false,
    handler: (req: Request, res: Response) => {
      res.status(429).json({
        success: false,
        error: {
          message: options.message,
          code: 'RATE_LIMIT_EXCEEDED',
          retryAfter: Math.ceil(options.windowMs / 1000),
        },
      });
    },
  });

  // Attach Redis store once connected (non-blocking)
  if (redisClient) {
    redisClient.once('ready', () => {
      try {
        (limiter as any).store = new RedisStore({
          sendCommand: (command: string, ...args: string[]) =>
            redisClient!.call(command, ...args) as any,
        });
        logger.info('Rate limiter upgraded to Redis store');
      } catch (err) {
        logger.warn('Failed to attach Redis store to rate limiter, using memory');
      }
    });
  }

  return limiter;
};

// General API rate limiter (100 requests per 15 minutes)
export const apiLimiter = buildLimiter({
  windowMs: 15 * 60 * 1000,
  max: 100,
  message: 'Too many requests from this IP, please try again after 15 minutes.',
});

// Strict rate limiter for authentication endpoints (5 requests per 15 minutes)
export const authLimiter = buildLimiter({
  windowMs: 15 * 60 * 1000,
  max: 5,
  skipSuccessfulRequests: false,
  message: 'Too many authentication attempts from this IP. Please try again after 15 minutes.',
});

// Rate limiter for transaction endpoints (30 requests per minute)
export const transactionLimiter = buildLimiter({
  windowMs: 60 * 1000,
  max: 30,
  message: 'Too many transaction requests. Please wait a moment before trying again.',
});

// Rate limiter for credit inquiries (10 per hour)
export const creditInquiryLimiter = buildLimiter({
  windowMs: 60 * 60 * 1000,
  max: 10,
  message: 'Too many credit inquiry requests. Please try again after 1 hour.',
});

// Rate limiter for webhook endpoints (100 per minute)
export const webhookLimiter = buildLimiter({
  windowMs: 60 * 1000,
  max: 100,
  skipFailedRequests: true,
  message: 'Webhook rate limit exceeded',
});

// Factory for custom Redis-backed rate limiters
export const createRedisRateLimiter = (windowMs: number, max: number, message?: string) => {
  return buildLimiter({
    windowMs,
    max,
    message: message || 'Rate limit exceeded. Please try again later.',
  });
};

// Export Redis client for potential external use
export { redisClient };
