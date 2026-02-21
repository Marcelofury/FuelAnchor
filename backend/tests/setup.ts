/**
 * Jest test setup file
 * Runs before all tests
 */

// Set test environment variables
process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test-jwt-secret';
process.env.DATABASE_URL = 'postgresql://localhost:5432/fuelanchor_test';
process.env.REDIS_URL = 'redis://localhost:6379/1';
process.env.STELLAR_NETWORK = 'testnet';
process.env.STELLAR_HORIZON_URL = 'https://horizon-testnet.stellar.org';
process.env.WEBHOOK_SECRET = 'test-webhook-secret';
process.env.ENCRYPTION_KEY = 'test-encryption-key-32-characters!';

// Increase timeout for Stellar network calls
jest.setTimeout(30000);

// Mock console methods to reduce noise in tests
global.console = {
  ...console,
  log: jest.fn(),
  debug: jest.fn(),
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
};

// Global test utilities
export const createMockRequest = (overrides = {}) => ({
  body: {},
  params: {},
  query: {},
  headers: {},
  user: null,
  ...overrides,
});

export const createMockResponse = () => {
  const res: any = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  res.send = jest.fn().mockReturnValue(res);
  res.set = jest.fn().mockReturnValue(res);
  return res;
};

export const createMockNext = () => jest.fn();
