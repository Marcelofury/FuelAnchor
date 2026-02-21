// FuelAnchor Backend Entry Point
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import { config } from './config/environment';
import { logger } from './utils/logger';
import { errorHandler, notFoundHandler } from './middleware/errorHandler';
import { apiLimiter, authLimiter, transactionLimiter, creditInquiryLimiter, webhookLimiter } from './middleware/rateLimiter';
import { securityHeaders, sanitizeInput, requestId } from './middleware/security';

// Import routes
import authRoutes from './api/auth';
import fleetRoutes from './api/fleet';
import driverRoutes from './api/driver';
import stationRoutes from './api/station';
import transactionRoutes from './api/transaction';
import creditRoutes from './api/credit';
import stellarRoutes from './api/stellar';
import webhookRoutes from './api/webhooks';
import mobileMoneyRoutes from './api/mobile_money';
import analyticsRoutes from './api/analytics';
import sep31Routes from './api/sep31';
import docsRoutes from './api/docs';

const app = express();

// Security middleware
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", 'data:', 'https:'],
    },
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true,
  },
}));

app.use(cors({
  origin: config.corsOrigins,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Request-ID', 'X-API-Key'],
  exposedHeaders: ['X-Request-ID'],
}));

// Custom security headers
app.use(securityHeaders);

// Request tracking
app.use(requestId);

// Body parsing with size limits
app.use(express.json({ limit: config.maxRequestBodySize }));
app.use(express.urlencoded({ extended: true, limit: config.maxRequestBodySize }));

// Input sanitization
app.use(sanitizeInput);

// Rate limiting - apply general limiter to all API routes
app.use('/api/', apiLimiter);

// Logging
app.use(morgan('combined', {
  stream: { write: (message) => logger.info(message.trim()) },
}));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: '1.0.0',
    service: 'FuelAnchor API',
    environment: config.nodeEnv,
    stellarNetwork: config.stellarNetwork,
  });
});

// API Routes with specific rate limiters
app.use('/api/v1/auth', authLimiter, authRoutes);
app.use('/api/v1/fleet', fleetRoutes);
app.use('/api/v1/drivers', driverRoutes);
app.use('/api/v1/stations', stationRoutes);
app.use('/api/v1/transactions', transactionLimiter, transactionRoutes);
app.use('/api/v1/credit', creditInquiryLimiter, creditRoutes);
app.use('/api/v1/stellar', stellarRoutes);
app.use('/api/v1/webhooks', webhookLimiter, webhookRoutes);
app.use('/api/v1/mobile-money', transactionLimiter, mobileMoneyRoutes);
app.use('/api/v1/analytics', analyticsRoutes);
app.use('/api/v1/sep31', transactionLimiter, sep31Routes);

// API Documentation
app.use('/api/docs', docsRoutes);

// Error handling
app.use(notFoundHandler);
app.use(errorHandler);

// Start server
const PORT = config.port || 3000;

app.listen(PORT, () => {
  logger.info(`🚀 FuelAnchor API server running on port ${PORT}`);
  logger.info(`📍 Environment: ${config.nodeEnv}`);
  logger.info(`🌐 Stellar Network: ${config.stellarNetwork}`);
});

export default app;
