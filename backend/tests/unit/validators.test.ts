import { validationResult } from 'express-validator';
import { createMockRequest, createMockResponse, createMockNext } from '../setup';
import {
  authValidators,
  transactionValidators,
  walletValidators,
  creditValidators,
  stationValidators,
  voucherValidators,
  mobileMoneyValidators,
  sep31Validators,
} from '../../src/middleware/validators';

describe('Validation Middleware', () => {
  describe('Auth Validators', () => {
    it('should validate correct registration data', async () => {
      const req = createMockRequest({
        body: {
          email: 'test@example.com',
          password: 'Test@1234',
          name: 'Test User',
          role: 'rider',
          phone: '+254712345678',
        },
      });
      const res = createMockResponse();
      const next = createMockNext();

      for (const validator of authValidators.register) {
        await validator.run(req);
      }

      const errors = validationResult(req);
      expect(errors.isEmpty()).toBe(true);
    });

    it('should reject invalid email', async () => {
      const req = createMockRequest({
        body: {
          email: 'not-an-email',
          password: 'Test@1234',
          name: 'Test User',
          role: 'rider',
          phone: '+254712345678',
        },
      });

      for (const validator of authValidators.register) {
        await validator.run(req);
      }

      const errors = validationResult(req);
      expect(errors.isEmpty()).toBe(false);
      expect(errors.array().some(e => e.msg.includes('email'))).toBe(true);
    });

    it('should reject weak password', async () => {
      const req = createMockRequest({
        body: {
          email: 'test@example.com',
          password: 'weak',
          name: 'Test User',
          role: 'rider',
          phone: '+254712345678',
        },
      });

      for (const validator of authValidators.register) {
        await validator.run(req);
      }

      const errors = validationResult(req);
      expect(errors.isEmpty()).toBe(false);
    });

    it('should reject invalid role', async () => {
      const req = createMockRequest({
        body: {
          email: 'test@example.com',
          password: 'Test@1234',
          name: 'Test User',
          role: 'invalid_role',
          phone: '+254712345678',
        },
      });

      for (const validator of authValidators.register) {
        await validator.run(req);
      }

      const errors = validationResult(req);
      expect(errors.isEmpty()).toBe(false);
    });
  });

  describe('Transaction Validators', () => {
    it('should validate correct transaction data', async () => {
      const req = createMockRequest({
        body: {
          from_account: 'GAKSTEST1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ123456',
          to_account: 'GAKSTEST7890123456ABCDEFGHIJKLMNOPQRSTUVWXYZ789012',
          amount: 100,
          type: 'payment',
          latitude: -1.2921,
          longitude: 36.8219,
        },
      });

      for (const validator of transactionValidators.create) {
        await validator.run(req);
      }

      const errors = validationResult(req);
      expect(errors.isEmpty()).toBe(true);
    });

    it('should reject negative amount', async () => {
      const req = createMockRequest({
        body: {
          from_account: 'GAKSTEST1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ123456',
          to_account: 'GAKSTEST7890123456ABCDEFGHIJKLMNOPQRSTUVWXYZ789012',
          amount: -100,
          type: 'payment',
          latitude: -1.2921,
          longitude: 36.8219,
        },
      });

      for (const validator of transactionValidators.create) {
        await validator.run(req);
      }

      const errors = validationResult(req);
      expect(errors.isEmpty()).toBe(false);
    });

    it('should reject invalid coordinates', async () => {
      const req = createMockRequest({
        body: {
          from_account: 'GAKSTEST1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ123456',
          to_account: 'GAKSTEST7890123456ABCDEFGHIJKLMNOPQRSTUVWXYZ789012',
          amount: 100,
          type: 'payment',
          latitude: 200, // Invalid
          longitude: 300, // Invalid
        },
      });

      for (const validator of transactionValidators.create) {
        await validator.run(req);
      }

      const errors = validationResult(req);
      expect(errors.isEmpty()).toBe(false);
    });
  });

  describe('SEP-31 Validators', () => {
    it('should validate correct quote creation', async () => {
      const req = createMockRequest({
        body: {
          sell_asset: 'KES',
          buy_asset: 'UGX',
          sell_amount: 1000,
        },
      });

      for (const validator of sep31Validators.createQuote) {
        await validator.run(req);
      }

      const errors = validationResult(req);
      expect(errors.isEmpty()).toBe(true);
    });

    it('should reject missing assets', async () => {
      const req = createMockRequest({
        body: {
          sell_amount: 1000,
        },
      });

      for (const validator of sep31Validators.createQuote) {
        await validator.run(req);
      }

      const errors = validationResult(req);
      expect(errors.isEmpty()).toBe(false);
    });
  });

  describe('Mobile Money Validators', () => {
    it('should validate correct deposit request', async () => {
      const req = createMockRequest({
        body: {
          phone: '+254712345678',
          amount: 1000,
          provider: 'mpesa',
          user_id: 'user-123',
        },
      });

      for (const validator of mobileMoneyValidators.deposit) {
        await validator.run(req);
      }

      const errors = validationResult(req);
      expect(errors.isEmpty()).toBe(true);
    });

    it('should reject invalid phone format', async () => {
      const req = createMockRequest({
        body: {
          phone: 'invalid-phone',
          amount: 1000,
          provider: 'mpesa',
          user_id: 'user-123',
        },
      });

      for (const validator of mobileMoneyValidators.deposit) {
        await validator.run(req);
      }

      const errors = validationResult(req);
      expect(errors.isEmpty()).toBe(false);
    });

    it('should reject invalid provider', async () => {
      const req = createMockRequest({
        body: {
          phone: '+254712345678',
          amount: 1000,
          provider: 'invalid_provider',
          user_id: 'user-123',
        },
      });

      for (const validator of mobileMoneyValidators.deposit) {
        await validator.run(req);
      }

      const errors = validationResult(req);
      expect(errors.isEmpty()).toBe(false);
    });
  });

  describe('Station Validators', () => {
    it('should validate correct station registration', async () => {
      const req = createMockRequest({
        body: {
          name: 'Test Station',
          latitude: -1.2921,
          longitude: 36.8219,
          owner_id: 'owner-123',
          license_number: 'LIC123',
        },
      });

      for (const validator of stationValidators.register) {
        await validator.run(req);
      }

      const errors = validationResult(req);
      expect(errors.isEmpty()).toBe(true);
    });

    it('should validate nearby stations query with valid coordinates', async () => {
      const req = createMockRequest({
        query: {
          lat: '-1.2921',
          lng: '36.8219',
          radius: '10',
        },
      });

      for (const validator of stationValidators.getNearby) {
        await validator.run(req);
      }

      const errors = validationResult(req);
      expect(errors.isEmpty()).toBe(true);
    });
  });

  describe('Voucher Validators', () => {
    it('should validate correct voucher creation', async () => {
      const req = createMockRequest({
        body: {
          fleet_id: 'fleet-123',
          driver_id: 'driver-456',
          amount: 500,
          valid_until: new Date(Date.now() + 86400000).toISOString(),
        },
      });

      for (const validator of voucherValidators.create) {
        await validator.run(req);
      }

      const errors = validationResult(req);
      expect(errors.isEmpty()).toBe(true);
    });
  });
});
