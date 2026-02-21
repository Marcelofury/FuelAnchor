# FuelAnchor Backend Tests

Comprehensive test suite for the FuelAnchor backend API.

## Test Structure

```
tests/
├── setup.ts              # Global test configuration
├── unit/                 # Unit tests for individual modules
│   ├── sep31.test.ts     # SEP-31 service tests
│   └── validators.test.ts # Validation middleware tests
└── integration/          # Integration tests for API endpoints
    └── auth.test.ts      # Authentication API tests
```

## Running Tests

```bash
# Install test dependencies
npm install --save-dev @types/jest @types/supertest jest supertest ts-jest

# Run all tests
npm test

# Run tests in watch mode
npm run test:watch

# Run only unit tests
npm run test:unit

# Run only integration tests
npm run test:integration

# Run with coverage report
npm test -- --coverage
```

## Test Coverage

The test suite covers:

- ✅ **Authentication**: Registration, login, password validation
- ✅ **SEP-31 Cross-Border Payments**: Exchange rates, quotes, transactions
- ✅ **Validators**: All input validation schemas
- ✅ **API Endpoints**: Integration tests for REST APIs

## Writing New Tests

### Unit Test Example

```typescript
import { myService } from '../../src/services/myService';

describe('My Service', () => {
  it('should perform expected operation', async () => {
    const result = await myService.doSomething('input');
    expect(result).toBe('expected output');
  });
});
```

### Integration Test Example

```typescript
import request from 'supertest';
import app from '../../src/index';

describe('My API', () => {
  it('should return 200 OK', async () => {
    const response = await request(app)
      .get('/api/v1/endpoint')
      .expect(200);
    
    expect(response.body).toHaveProperty('data');
  });
});
```

## Test Environment

Tests run with:
- **NODE_ENV**: `test`
- **Database**: `fuelanchor_test` (uses separate test database)
- **Redis**: Database 1 (separate from dev/production)
- **Stellar Network**: Testnet
- **JWT Secret**: Test-specific secret

## Mocking

The test setup provides utilities for mocking:
- `createMockRequest()` - Mock Express request
- `createMockResponse()` - Mock Express response
- `createMockNext()` - Mock Express next function

## CI/CD Integration

Tests are automatically run in GitHub Actions pipeline on:
- Pull requests
- Pushes to main branch
- Manual workflow dispatch

## Coverage Reports

Coverage reports are generated in `coverage/` directory:
- HTML report: `coverage/lcov-report/index.html`
- LCOV data: `coverage/lcov.info`

Minimum coverage thresholds:
- **Statements**: 70%
- **Branches**: 65%
- **Functions**: 70%
- **Lines**: 70%

## Troubleshooting

### Tests timing out
Increase Jest timeout in `jest.config.json` or individual test files:
```typescript
jest.setTimeout(60000); // 60 seconds
```

### Database connection errors
Ensure PostgreSQL test database exists:
```bash
createdb fuelanchor_test
```

### Stellar network errors
Some tests require network access to Stellar testnet. Run with `--detectOpenHandles` to debug:
```bash
npm test -- --detectOpenHandles
```
