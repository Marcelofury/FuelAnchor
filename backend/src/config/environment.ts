import dotenv from 'dotenv';

dotenv.config();

export const config = {
  // Server
  nodeEnv: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT || '3000', 10),
  corsOrigins: process.env.CORS_ORIGINS?.split(',') || ['http://localhost:3000'],

  // Database
  databaseUrl: process.env.DATABASE_URL || 'postgresql://localhost:5432/fuelanchor',

  // Supabase
  supabaseUrl: process.env.SUPABASE_URL || '',
  supabaseAnonKey: process.env.SUPABASE_ANON_KEY || '',
  supabaseServiceKey: process.env.SUPABASE_SERVICE_KEY || '',

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
  stellarIssuer: process.env.STELLAR_ISSUER || '',
  usdcIssuer: process.env.USDC_ISSUER || 'GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5', // Testnet USDC issuer

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
  mpesaSecurityCredential: process.env.MPESA_SECURITY_CREDENTIAL || '',

  // MTN Mobile Money
  mtnApiKey: process.env.MTN_API_KEY || '',
  mtnApiSecret: process.env.MTN_API_SECRET || '',
  mtnSubscriptionKey: process.env.MTN_SUBSCRIPTION_KEY || '',
  mtnCollectionsUserId: process.env.MTN_COLLECTIONS_USER_ID || '',
  mtnDisbursementsUserId: process.env.MTN_DISBURSEMENTS_USER_ID || '',

  // Airtel Money
  airtelClientId: process.env.AIRTEL_CLIENT_ID || '',
  airtelClientSecret: process.env.AIRTEL_CLIENT_SECRET || '',
  airtelEncryptedPin: process.env.AIRTEL_ENCRYPTED_PIN || '',
  airtelCallbackUrl: process.env.AIRTEL_CALLBACK_URL || '',

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

  // Security
  webhookSecret: process.env.WEBHOOK_SECRET || 'change-this-webhook-secret-in-production',
  encryptionKey: process.env.ENCRYPTION_KEY || 'change-this-encryption-key-in-production',
  allowedApiKeys: process.env.ALLOWED_API_KEYS?.split(',') || [],
  maxRequestBodySize: process.env.MAX_REQUEST_BODY_SIZE || '10mb',

  // Session
  sessionSecret: process.env.SESSION_SECRET || 'change-this-session-secret-in-production',
  sessionMaxAge: parseInt(process.env.SESSION_MAX_AGE || '86400000', 10), // 24 hours

  // Logging
  logLevel: process.env.LOG_LEVEL || 'info',
}

// Export a more convenient environment object with aliases
export const environment = {
  ...config,
  horizonUrl: config.stellarHorizonUrl,
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
