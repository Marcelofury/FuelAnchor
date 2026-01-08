import dotenv from 'dotenv';

dotenv.config();

export const config = {
  // Server
  nodeEnv: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT || '3000', 10),
  corsOrigins: process.env.CORS_ORIGINS?.split(',') || ['http://localhost:3000'],

  // Database
  databaseUrl: process.env.DATABASE_URL || 'postgresql://localhost:5432/fuelanchor',

  // Redis
  redisUrl: process.env.REDIS_URL || 'redis://localhost:6379',

  // JWT
  jwtSecret: process.env.JWT_SECRET || 'your-super-secret-jwt-key-change-in-production',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',
  jwtRefreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '30d',

  // Stellar Configuration
  stellarNetwork: process.env.STELLAR_NETWORK || 'testnet',
  stellarHorizonUrl: process.env.STELLAR_HORIZON_URL || 'https://horizon-testnet.stellar.org',
  stellarSorobanRpcUrl: process.env.STELLAR_SOROBAN_RPC_URL || 'https://soroban-testnet.stellar.org',
  stellarNetworkPassphrase: process.env.STELLAR_NETWORK_PASSPHRASE || 'Test SDF Network ; September 2015',

  // FuelAnchor Stellar Accounts
  fuelTokenIssuer: process.env.FUEL_TOKEN_ISSUER || '',
  fuelTokenDistributor: process.env.FUEL_TOKEN_DISTRIBUTOR || '',
  distributorSecretKey: process.env.DISTRIBUTOR_SECRET_KEY || '',

  // Soroban Contract IDs
  fuelTokenContractId: process.env.FUEL_TOKEN_CONTRACT_ID || '',
  voucherRedemptionContractId: process.env.VOUCHER_REDEMPTION_CONTRACT_ID || '',
  creditScoreContractId: process.env.CREDIT_SCORE_CONTRACT_ID || '',
  geofencingContractId: process.env.GEOFENCING_CONTRACT_ID || '',

  // Mobile Money Integration (M-Pesa, MTN, Airtel)
  mpesaConsumerKey: process.env.MPESA_CONSUMER_KEY || '',
  mpesaConsumerSecret: process.env.MPESA_CONSUMER_SECRET || '',
  mpesaShortcode: process.env.MPESA_SHORTCODE || '',
  mpesaPasskey: process.env.MPESA_PASSKEY || '',
  mpesaCallbackUrl: process.env.MPESA_CALLBACK_URL || '',

  // MTN Mobile Money
  mtnApiKey: process.env.MTN_API_KEY || '',
  mtnApiSecret: process.env.MTN_API_SECRET || '',
  mtnSubscriptionKey: process.env.MTN_SUBSCRIPTION_KEY || '',

  // SMS Gateway (Africa's Talking)
  atApiKey: process.env.AT_API_KEY || '',
  atUsername: process.env.AT_USERNAME || '',
  atShortcode: process.env.AT_SHORTCODE || '',

  // Feature Flags
  enableCreditScoring: process.env.ENABLE_CREDIT_SCORING === 'true',
  enableGeofencing: process.env.ENABLE_GEOFENCING === 'true',
  enableMobileMoney: process.env.ENABLE_MOBILE_MONEY === 'true',
  enableUssd: process.env.ENABLE_USSD === 'true',

  // Rate Limits
  apiRateLimit: parseInt(process.env.API_RATE_LIMIT || '100', 10),
  apiRateWindow: parseInt(process.env.API_RATE_WINDOW || '900000', 10), // 15 minutes

  // Logging
  logLevel: process.env.LOG_LEVEL || 'info',
};

// Validate required environment variables in production
if (config.nodeEnv === 'production') {
  const required = [
    'JWT_SECRET',
    'DATABASE_URL',
    'STELLAR_NETWORK',
    'FUEL_TOKEN_CONTRACT_ID',
  ];

  const missing = required.filter((key) => !process.env[key]);
  if (missing.length > 0) {
    throw new Error(`Missing required environment variables: ${missing.join(', ')}`);
  }
}

export default config;
