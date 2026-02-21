/**
 * Credit Score API Tests
 */

import request from 'supertest';
import app from '../../src/index';

// Helper: mock JWT token for tests (unauthenticated path)
const makeAuthHeader = (token = 'mock-token') => ({ Authorization: `Bearer ${token}` });

describe('Credit Score API', () => {
  describe('GET /api/v1/credit/score', () => {
    it('should return 401 without authentication', async () => {
      const resp = await request(app)
        .get('/api/v1/credit/score')
        .expect(401);

      expect(resp.body.success).toBe(false);
    });

    it('should require bearer token', async () => {
      const resp = await request(app)
        .get('/api/v1/credit/score')
        .set('Authorization', 'Bearer invalid-token')
        .expect(401);

      expect(resp.body.success).toBe(false);
    });
  });

  describe('GET /api/v1/credit/factors', () => {
    it('should return 401 without authentication', async () => {
      const resp = await request(app)
        .get('/api/v1/credit/factors')
        .expect(401);

      expect(resp.body.success).toBe(false);
    });
  });

  describe('GET /api/v1/credit/eligibility', () => {
    it('should return 401 without authentication', async () => {
      const resp = await request(app)
        .get('/api/v1/credit/eligibility')
        .expect(401);

      expect(resp.body.success).toBe(false);
    });
  });

  describe('POST /api/v1/credit/simulate', () => {
    it('should return 401 without authentication', async () => {
      const resp = await request(app)
        .post('/api/v1/credit/simulate')
        .send({ transactions: 50, daysSinceFirstTransaction: 180, uniqueStations: 5 })
        .expect(401);

      expect(resp.body.success).toBe(false);
    });

    it('routes are mounted correctly', async () => {
      // Confirms the credit router is wired up at /api/v1/credit
      const resp = await request(app)
        .post('/api/v1/credit/simulate');

      // 401 = authenticated endpoint exists; 404 = not mounted
      expect(resp.status).not.toBe(404);
    });
  });
});

describe('Station API', () => {
  describe('GET /api/v1/stations/nearby', () => {
    it('should return 401 without authentication', async () => {
      const resp = await request(app)
        .get('/api/v1/stations/nearby')
        .query({ lat: '-1.2921', lng: '36.8219' })
        .expect(401);

      expect(resp.body.success).toBe(false);
    });
  });

  describe('GET /api/v1/stations', () => {
    it('should return 401 without authentication', async () => {
      const resp = await request(app)
        .get('/api/v1/stations')
        .expect(401);

      expect(resp.body.success).toBe(false);
    });
  });

  describe('POST /api/v1/stations', () => {
    it('should return 401 without authentication', async () => {
      const resp = await request(app)
        .post('/api/v1/stations')
        .send({
          name: 'Test Station',
          address: '123 Test St',
          country: 'KE',
          latitude: -1.2921,
          longitude: 36.8219,
          fuelTypes: [{ type: 'petrol', pricePerLiter: 185.0 }],
        })
        .expect(401);

      expect(resp.body.success).toBe(false);
    });
  });
});

describe('Fleet API', () => {
  describe('GET /api/v1/fleet', () => {
    it('should return 401 without authentication', async () => {
      const resp = await request(app)
        .get('/api/v1/fleet')
        .expect(401);

      expect(resp.body.success).toBe(false);
    });
  });

  describe('POST /api/v1/fleet', () => {
    it('should return 401 without authentication', async () => {
      const resp = await request(app)
        .post('/api/v1/fleet')
        .send({
          name: 'Test Fleet',
          country: 'KE',
          vehicleCount: 5,
        })
        .expect(401);

      expect(resp.body.success).toBe(false);
    });
  });
});

describe('Mobile Money API', () => {
  describe('POST /api/v1/mobile-money/deposit/airtel', () => {
    it('should return 401 without authentication', async () => {
      const resp = await request(app)
        .post('/api/v1/mobile-money/deposit/airtel')
        .send({ phoneNumber: '+254712345678', amount: 100 })
        .expect(401);

      expect(resp.body.success).toBe(false);
    });

    it('route is mounted (not 404)', async () => {
      const resp = await request(app)
        .post('/api/v1/mobile-money/deposit/airtel');

      expect(resp.status).not.toBe(404);
    });
  });

  describe('POST /api/v1/mobile-money/deposit/mtn', () => {
    it('route is mounted (not 404)', async () => {
      const resp = await request(app)
        .post('/api/v1/mobile-money/deposit/mtn');

      expect(resp.status).not.toBe(404);
    });
  });

  describe('POST /api/v1/mobile-money/withdraw/airtel', () => {
    it('route is mounted (not 404)', async () => {
      const resp = await request(app)
        .post('/api/v1/mobile-money/withdraw/airtel');

      expect(resp.status).not.toBe(404);
    });
  });
});

describe('Analytics API', () => {
  describe('GET /api/v1/analytics/dashboard', () => {
    it('should return 401 without authentication', async () => {
      const resp = await request(app)
        .get('/api/v1/analytics/dashboard')
        .expect(401);

      expect(resp.body.success).toBe(false);
    });
  });
});
