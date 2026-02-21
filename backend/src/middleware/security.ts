import { Request, Response, NextFunction } from 'express';
import crypto from 'crypto';
import { Keypair } from '@stellar/stellar-sdk';
import { AppError } from './errorHandler';
import { config } from '../config/environment';

/**
 * Verify webhook signatures from mobile money providers
 */
export const verifyWebhookSignature = (req: Request, res: Response, next: NextFunction) => {
  try {
    const signature = req.headers['x-webhook-signature'] as string;
    const timestamp = req.headers['x-webhook-timestamp'] as string;

    if (!signature || !timestamp) {
      throw new AppError('Missing webhook signature or timestamp', 401, 'INVALID_WEBHOOK');
    }

    // Verify timestamp is recent (within 5 minutes)
    const requestTime = parseInt(timestamp, 10);
    const currentTime = Math.floor(Date.now() / 1000);
    if (Math.abs(currentTime - requestTime) > 300) {
      throw new AppError('Webhook timestamp too old or invalid', 401, 'EXPIRED_WEBHOOK');
    }

    // Reconstruct the signed payload
    const payload = `${timestamp}.${JSON.stringify(req.body)}`;
    
    // Compute expected signature using webhook secret
    const webhookSecret = config.webhookSecret || process.env.WEBHOOK_SECRET || '';
    const expectedSignature = crypto
      .createHmac('sha256', webhookSecret)
      .update(payload)
      .digest('hex');

    // Compare signatures (constant-time comparison to prevent timing attacks)
    if (!crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expectedSignature))) {
      throw new AppError('Invalid webhook signature', 401, 'INVALID_SIGNATURE');
    }

    next();
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError('Webhook verification failed', 401, 'WEBHOOK_VERIFICATION_FAILED');
  }
};

/**
 * Verify Stellar transaction signatures
 */
export const verifyTransactionSignature = async (
  transaction: string,
  expectedSigner: string
): Promise<boolean> => {
  try {
    // Parse the transaction envelope
    const { Transaction } = await import('@stellar/stellar-sdk');
    const tx = Transaction.fromEnvelope(transaction);
    
    // Check if the expected signer is in the transaction signatures
    const signers = tx.signatures.map(sig => {
      // Extract public key from signature (implementation depends on your use case)
      return sig.hint().toString('hex');
    });

    // Verify the expected signer is present
    return signers.some(signer => signer.includes(expectedSigner.slice(-8)));
  } catch (error) {
    return false;
  }
};

/**
 * Validate request body against expected schema
 */
export const validateRequestBody = (requiredFields: string[]) => {
  return (req: Request, res: Response, next: NextFunction) => {
    const missingFields = requiredFields.filter(field => !(field in req.body));

    if (missingFields.length > 0) {
      throw new AppError(
        `Missing required fields: ${missingFields.join(', ')}`,
        400,
        'MISSING_REQUIRED_FIELDS'
      );
    }

    next();
  };
};

/**
 * Sanitize input to prevent XSS and injection attacks
 */
export const sanitizeInput = (req: Request, res: Response, next: NextFunction) => {
  const sanitize = (obj: any): any => {
    if (typeof obj === 'string') {
      // Remove potential XSS patterns
      return obj
        .replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '')
        .replace(/javascript:/gi, '')
        .replace(/on\w+\s*=/gi, '')
        .trim();
    }
    if (typeof obj === 'object' && obj !== null) {
      for (const key in obj) {
        obj[key] = sanitize(obj[key]);
      }
    }
    return obj;
  };

  req.body = sanitize(req.body);
  req.query = sanitize(req.query);
  req.params = sanitize(req.params);

  next();
};

/**
 * Verify API key for external integrations
 */
export const verifyApiKey = (req: Request, res: Response, next: NextFunction) => {
  const apiKey = req.headers['x-api-key'] as string;

  if (!apiKey) {
    throw new AppError('API key required', 401, 'MISSING_API_KEY');
  }

  // Validate against stored API keys (implement your storage logic)
  const validApiKeys = process.env.VALID_API_KEYS?.split(',') || [];

  if (!validApiKeys.includes(apiKey)) {
    throw new AppError('Invalid API key', 401, 'INVALID_API_KEY');
  }

  next();
};

/**
 * CORS security headers
 */
export const securityHeaders = (req: Request, res: Response, next: NextFunction) => {
  // Prevent clickjacking
  res.setHeader('X-Frame-Options', 'DENY');
  
  // Prevent MIME type sniffing
  res.setHeader('X-Content-Type-Options', 'nosniff');
  
  // Enable XSS protection
  res.setHeader('X-XSS-Protection', '1; mode=block');
  
  // Referrer policy
  res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
  
  // Content Security Policy
  res.setHeader(
    'Content-Security-Policy',
    "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline';"
  );

  next();
};

/**
 * Verify Stellar account ownership
 */
export const verifyStellarAccountOwnership = async (
  publicKey: string,
  signature: string,
  message: string
): Promise<boolean> => {
  try {
    const keypair = Keypair.fromPublicKey(publicKey);
    const messageBuffer = Buffer.from(message);
    const signatureBuffer = Buffer.from(signature, 'base64');

    return keypair.verify(messageBuffer, signatureBuffer);
  } catch (error) {
    return false;
  }
};

/**
 * Request ID middleware for tracing
 */
export const requestId = (req: Request, res: Response, next: NextFunction) => {
  const id = req.headers['x-request-id'] as string || crypto.randomUUID();
  req.headers['x-request-id'] = id;
  res.setHeader('X-Request-ID', id);
  next();
};
