import request from 'supertest';
import app from '../../src/index';

describe('Authentication API', () => {
  describe('POST /api/v1/auth/register', () => {
    it('should register a new user with valid data', async () => {
      const userData = {
        email: 'test@example.com',
        password: 'Test@1234',
        name: 'Test User',
        role: 'rider',
        phone: '+254712345678',
      };

      const response = await request(app)
        .post('/api/v1/auth/register')
        .send(userData)
        .expect('Content-Type', /json/);

      // Note: Actual status code depends on implementation
      // This is a template - adjust based on actual API response
      expect([200, 201]).toContain(response.status);
    });

    it('should reject registration with invalid email', async () => {
      const userData = {
        email: 'invalid-email',
        password: 'Test@1234',
        name: 'Test User',
        role: 'rider',
        phone: '+254712345678',
      };

      const response = await request(app)
        .post('/api/v1/auth/register')
        .send(userData)
        .expect(400);

      expect(response.body).toHaveProperty('error');
      expect(response.body.success).toBe(false);
    });

    it('should reject registration with weak password', async () => {
      const userData = {
        email: 'test2@example.com',
        password: 'weak',
        name: 'Test User',
        role: 'rider',
        phone: '+254712345678',
      };

      const response = await request(app)
        .post('/api/v1/auth/register')
        .send(userData)
        .expect(400);

      expect(response.body).toHaveProperty('error');
      expect(response.body.success).toBe(false);
    });

    it('should reject registration with invalid role', async () => {
      const userData = {
        email: 'test3@example.com',
        password: 'Test@1234',
        name: 'Test User',
        role: 'invalid_role',
        phone: '+254712345678',
      };

      const response = await request(app)
        .post('/api/v1/auth/register')
        .send(userData)
        .expect(400);

      expect(response.body).toHaveProperty('error');
      expect(response.body.success).toBe(false);
    });
  });

  describe('POST /api/v1/auth/login', () => {
    it('should reject login with missing credentials', async () => {
      const response = await request(app)
        .post('/api/v1/auth/login')
        .send({})
        .expect(400);

      expect(response.body).toHaveProperty('error');
      expect(response.body.success).toBe(false);
    });

    it('should reject login with invalid email format', async () => {
      const response = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: 'not-an-email',
          password: 'password',
        });

      expect([400, 429]).toContain(response.status); // May hit rate limit
      expect(response.body).toHaveProperty('error');
      expect(response.body.success).toBe(false);
    });
  });
});
