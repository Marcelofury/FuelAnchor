import { body, param, query, ValidationChain } from 'express-validator';

/**
 * Comprehensive validation schemas for FuelAnchor API endpoints
 */

// Common validators
export const validators = {
  // User validators
  email: body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Valid email address is required'),

  password: body('password')
    .isLength({ min: 8, max: 128 })
    .withMessage('Password must be between 8 and 128 characters')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/)
    .withMessage('Password must contain uppercase, lowercase, number, and special character'),

  phone: body('phone')
    .matches(/^\+?[1-9]\d{1,14}$/)
    .withMessage('Valid phone number in E.164 format required'),

  stellarPublicKey: (field: string = 'publicKey') =>
    body(field)
      .matches(/^G[A-Z2-7]{55}$/)
      .withMessage('Valid Stellar public key required (starts with G, 56 characters)'),

  stellarSecretKey: (field: string = 'secretKey') =>
    body(field)
      .matches(/^S[A-Z2-7]{55}$/)
      .withMessage('Valid Stellar secret key required (starts with S, 56 characters)'),

  uuid: (field: string) =>
    param(field)
      .isUUID()
      .withMessage(`Valid UUID required for ${field}`),

  positiveNumber: (field: string, location: 'body' | 'query' = 'body') =>
    (location === 'body' ? body(field) : query(field))
      .isFloat({ min: 0 })
      .withMessage(`${field} must be a positive number`),

  coordinates: {
    latitude: (field: string = 'latitude', location: 'body' | 'query' = 'body') =>
      (location === 'body' ? body(field) : query(field))
        .isFloat({ min: -90, max: 90 })
        .withMessage('Valid latitude between -90 and 90 required'),
    longitude: (field: string = 'longitude', location: 'body' | 'query' = 'body') =>
      (location === 'body' ? body(field) : query(field))
        .isFloat({ min: -180, max: 180 })
        .withMessage('Valid longitude between -180 and 180 required'),
  },

  pagination: {
    page: query('page')
      .optional()
      .isInt({ min: 1 })
      .withMessage('Page must be a positive integer'),
    limit: query('limit')
      .optional()
      .isInt({ min: 1, max: 100 })
      .withMessage('Limit must be between 1 and 100'),
  },

  dateRange: {
    startDate: query('start_date')
      .optional()
      .isISO8601()
      .withMessage('Valid ISO 8601 date required for start_date'),
    endDate: query('end_date')
      .optional()
      .isISO8601()
      .withMessage('Valid ISO 8601 date required for end_date'),
  },
};

// Authentication validation schemas
export const authValidators = {
  register: [
    validators.email,
    validators.password,
    body('name')
      .trim()
      .isLength({ min: 2, max: 100 })
      .withMessage('Name must be between 2 and 100 characters'),
    body('role')
      .isIn(['rider', 'driver', 'merchant', 'fleet_operator', 'admin'])
      .withMessage('Invalid role'),
    validators.phone,
  ],

  login: [
    validators.email,
    body('password').notEmpty().withMessage('Password is required'),
  ],

  changePassword: [
    body('currentPassword').notEmpty().withMessage('Current password is required'),
    validators.password,
  ],

  resetPassword: [
    body('token').notEmpty().withMessage('Reset token is required'),
    validators.password,
  ],
};

// Transaction validation schemas
export const transactionValidators = {
  create: [
    body('from_account').notEmpty().withMessage('From account is required'),
    body('to_account').notEmpty().withMessage('To account is required'),
    validators.positiveNumber('amount'),
    body('type')
      .isIn(['payment', 'refund', 'voucher', 'credit_purchase'])
      .withMessage('Invalid transaction type'),
    validators.coordinates.latitude(),
    validators.coordinates.longitude(),
  ],

  getById: [validators.uuid('id')],

  query: [
    validators.pagination.page,
    validators.pagination.limit,
    validators.dateRange.startDate,
    validators.dateRange.endDate,
    query('status')
      .optional()
      .isIn(['pending', 'completed', 'failed', 'cancelled'])
      .withMessage('Invalid status'),
  ],
};

// Wallet validation schemas
export const walletValidators = {
  create: [
    body('user_id').notEmpty().withMessage('User ID is required'),
    validators.stellarPublicKey('public_key'),
    body('wallet_type')
      .optional()
      .isIn(['custodial', 'non_custodial'])
      .withMessage('Invalid wallet type'),
  ],

  transfer: [
    validators.stellarPublicKey('from'),
    validators.stellarPublicKey('to'),
    validators.positiveNumber('amount'),
    body('asset_code')
      .optional()
      .isLength({ min: 1, max: 12 })
      .withMessage('Asset code must be 1-12 characters'),
  ],
};

// Credit scoring validation schemas
export const creditValidators = {
  createScore: [
    body('user_id').notEmpty().withMessage('User ID is required'),
    body('payment_history')
      .isFloat({ min: 0, max: 100 })
      .withMessage('Payment history score must be 0-100'),
    body('transaction_volume')
      .isFloat({ min: 0, max: 100 })
      .withMessage('Transaction volume score must be 0-100'),
    body('account_age')
      .isFloat({ min: 0, max: 100 })
      .withMessage('Account age score must be 0-100'),
  ],

  getScore: [validators.uuid('userId')],

  updateScore: [
    validators.uuid('userId'),
    body('score')
      .isFloat({ min: 0, max: 100 })
      .withMessage('Credit score must be between 0 and 100'),
  ],
};

// Fleet management validation schemas
export const fleetValidators = {
  createFleet: [
    body('name')
      .trim()
      .isLength({ min: 2, max: 100 })
      .withMessage('Fleet name must be between 2 and 100 characters'),
    body('owner_id').notEmpty().withMessage('Owner ID is required'),
    body('registration_number')
      .optional()
      .trim()
      .isLength({ min: 3, max: 50 })
      .withMessage('Registration number must be 3-50 characters'),
  ],

  addDriver: [
    validators.uuid('fleetId'),
    body('driver_id').notEmpty().withMessage('Driver ID is required'),
    body('vehicle_registration')
      .trim()
      .notEmpty()
      .withMessage('Vehicle registration is required'),
    validators.positiveNumber('daily_fuel_limit'),
  ],

  setAllowance: [
    validators.uuid('fleetId'),
    body('driver_id').notEmpty().withMessage('Driver ID is required'),
    validators.positiveNumber('allowance'),
    body('period')
      .isIn(['daily', 'weekly', 'monthly'])
      .withMessage('Period must be daily, weekly, or monthly'),
  ],
};

// Station/Merchant validation schemas
export const stationValidators = {
  register: [
    body('name')
      .trim()
      .isLength({ min: 2, max: 100 })
      .withMessage('Station name must be between 2 and 100 characters'),
    validators.coordinates.latitude(),
    validators.coordinates.longitude(),
    body('owner_id').notEmpty().withMessage('Owner ID is required'),
    body('license_number')
      .optional()
      .trim()
      .isLength({ min: 3, max: 50 })
      .withMessage('License number must be 3-50 characters'),
  ],

  updateLocation: [
    validators.uuid('stationId'),
    validators.coordinates.latitude(),
    validators.coordinates.longitude(),
  ],

  getNearby: [
    validators.coordinates.latitude('lat', 'query'),
    validators.coordinates.longitude('lng', 'query'),
    query('radius')
      .optional()
      .isFloat({ min: 0.1, max: 100 })
      .withMessage('Radius must be between 0.1 and 100 km'),
  ],
};

// Voucher validation schemas
export const voucherValidators = {
  create: [
    body('fleet_id').notEmpty().withMessage('Fleet ID is required'),
    body('driver_id').notEmpty().withMessage('Driver ID is required'),
    validators.positiveNumber('amount'),
    body('valid_until')
      .isISO8601()
      .withMessage('Valid expiration date required'),
    body('restrictions')
      .optional()
      .isObject()
      .withMessage('Restrictions must be an object'),
  ],

  redeem: [
    body('voucher_code')
      .trim()
      .notEmpty()
      .withMessage('Voucher code is required'),
    validators.stellarPublicKey('merchant_account'),
    validators.positiveNumber('amount'),
    validators.coordinates.latitude(),
    validators.coordinates.longitude(),
  ],

  verify: [
    param('code')
      .trim()
      .notEmpty()
      .withMessage('Voucher code is required'),
  ],
};

// Mobile Money validation schemas
export const mobileMoneyValidators = {
  deposit: [
    validators.phone,
    validators.positiveNumber('amount'),
    body('provider')
      .isIn(['mpesa', 'mtn_momo', 'airtel_money'])
      .withMessage('Invalid mobile money provider'),
    body('user_id').notEmpty().withMessage('User ID is required'),
  ],

  withdraw: [
    validators.phone,
    validators.positiveNumber('amount'),
    body('provider')
      .isIn(['mpesa', 'mtn_momo', 'airtel_money'])
      .withMessage('Invalid mobile money provider'),
    body('user_id').notEmpty().withMessage('User ID is required'),
  ],

  checkStatus: [
    param('transactionId')
      .trim()
      .notEmpty()
      .withMessage('Transaction ID is required'),
  ],
};

// Analytics validation schemas
export const analyticsValidators = {
  dashboard: [
    validators.dateRange.startDate,
    validators.dateRange.endDate,
    query('user_id').optional().notEmpty().withMessage('User ID cannot be empty if provided'),
  ],

  merchantAnalytics: [
    validators.uuid('merchantId'),
    validators.dateRange.startDate,
    validators.dateRange.endDate,
  ],

  fleetAnalytics: [
    validators.uuid('fleetId'),
    validators.dateRange.startDate,
    validators.dateRange.endDate,
  ],
};

// SEP-31 validation schemas
export const sep31Validators = {
  createQuote: [
    body('sell_asset').notEmpty().withMessage('Sell asset is required'),
    body('buy_asset').notEmpty().withMessage('Buy asset is required'),
    validators.positiveNumber('sell_amount'),
  ],

  createTransaction: [
    body('quote_id').isUUID().withMessage('Valid quote ID is required'),
    body('sender_id').notEmpty().withMessage('Sender ID is required'),
    body('receiver_id').notEmpty().withMessage('Receiver ID is required'),
    validators.stellarPublicKey('sender_account').optional({ nullable: true }),
    validators.stellarPublicKey('receiver_account').optional({ nullable: true }),
  ],
};
