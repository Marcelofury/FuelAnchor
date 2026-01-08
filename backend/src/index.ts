// FuelAnchor Backend Entry Point
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import rateLimit from 'express-rate-limit';
import { config } from './config/environment';
import { logger } from './utils/logger';
import { errorHandler, notFoundHandler } from './middleware/errorHandler';

// Import routes
import authRoutes from './api/auth';
import fleetRoutes from './api/fleet';
import driverRoutes from './api/driver';
import stationRoutes from './api/station';
import transactionRoutes from './api/transaction';
import creditRoutes from './api/credit';
import stellarRoutes from './api/stellar';
import webhookRoutes from './api/webhooks';

const app = express();

// Security middleware
app.use(helmet());
app.use(cors({
  origin: config.corsOrigins,
  credentials: true,
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.',
});
app.use('/api/', limiter);

// Body parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

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
  });
});

// API Routes
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/fleet', fleetRoutes);
app.use('/api/v1/drivers', driverRoutes);
app.use('/api/v1/stations', stationRoutes);
app.use('/api/v1/transactions', transactionRoutes);
app.use('/api/v1/credit', creditRoutes);
app.use('/api/v1/stellar', stellarRoutes);
app.use('/api/v1/webhooks', webhookRoutes);

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
