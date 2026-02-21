/**
 * Relworx Payment Gateway Service
 * Unified mobile money for MTN & Airtel Uganda via Relworx API
 */
import axios, { AxiosInstance } from 'axios';
import { config } from '../config/environment';
import { logger } from '../utils/logger';
import { AppError } from '../middleware/errorHandler';

// ─── Types ────────────────────────────────────────────────────────────────────

export interface RelworxValidateResult {
  valid: boolean;
  customerName?: string;
  message: string;
}

export interface RelworxPaymentResult {
  success: boolean;
  message: string;
  internalReference: string;
  customerReference: string;
  status: 'pending';
}

export interface RelworxStatusResult {
  success: boolean;
  status: 'success' | 'pending' | 'failed' | 'unknown';
  requestStatus?: string;
  message?: string;
  customerReference?: string;
  internalReference?: string;
  msisdn?: string;
  amount?: number;
  currency?: string;
  provider?: string;
  charge?: number;
  providerTransactionId?: string;
  completedAt?: string;
}

export interface RelworxBalanceResult {
  success: boolean;
  balance?: number;
  currency?: string;
  message?: string;
}

export interface RelworxTransaction {
  reference: string;
  internal_reference: string;
  msisdn: string;
  amount: number;
  currency: string;
  status: string;
  provider: string;
  created_at: string;
  completed_at?: string;
}

export type MobileProvider = 'MTN_UGANDA' | 'AIRTEL_UGANDA' | 'UNKNOWN';

// ─── Axios client ─────────────────────────────────────────────────────────────

const relworxClient: AxiosInstance = axios.create({
  baseURL: config.relworxApiUrl,
  headers: {
    'Content-Type': 'application/json',
    Accept: 'application/vnd.relworx.v2',
    Authorization: `Bearer ${config.relworxApiKey}`,
  },
  timeout: 30_000,
});

// ─── Helper utilities ─────────────────────────────────────────────────────────

/**
 * Format any Ugandan phone number to international format (+256XXXXXXXXX)
 */
export const formatPhoneNumber = (phone: string): string | null => {
  if (!phone) return null;

  // Strip whitespace, dashes, parentheses
  let cleaned = phone.replace(/[\s\-()]/g, '');

  if (cleaned.startsWith('0')) {
    cleaned = '+256' + cleaned.substring(1);
  } else if (cleaned.startsWith('256') && !cleaned.startsWith('+')) {
    cleaned = '+' + cleaned;
  }

  // Must be +256 followed by 9 digits = 13 chars total
  if (!cleaned.startsWith('+256') || cleaned.length !== 13) {
    return null;
  }

  return cleaned;
};

/**
 * Detect MTN or Airtel Uganda from phone number prefix
 */
export const getProvider = (phone: string): MobileProvider => {
  const formatted = formatPhoneNumber(phone);
  if (!formatted) return 'UNKNOWN';

  const prefix = formatted.substring(4, 6); // digits after +256

  if (['77', '78', '76'].includes(prefix)) return 'MTN_UGANDA';
  if (['70', '75', '74'].includes(prefix)) return 'AIRTEL_UGANDA';

  return 'UNKNOWN';
};

// ─── Service functions ────────────────────────────────────────────────────────

/**
 * Validate phone number with Relworx before charging
 */
export const validateMobileNumber = async (
  msisdn: string
): Promise<RelworxValidateResult> => {
  try {
    const response = await relworxClient.post('/mobile-money/validate', { msisdn });
    if (response.data.success) {
      return {
        valid: true,
        customerName: response.data.customer_name,
        message: response.data.message || 'Valid',
      };
    }
    return { valid: false, message: 'Number validation failed' };
  } catch (error: any) {
    logger.warn('Relworx number validation failed:', error.response?.data || error.message);
    // Fail open – allow payment even if validation service is down
    return { valid: true, message: 'Validation service unavailable' };
  }
};

/**
 * Request payment (Collection) - pull money from customer
 */
export const requestPayment = async (params: {
  reference: string;
  msisdn: string;
  currency?: string;
  amount: number;
  description?: string;
}): Promise<RelworxPaymentResult> => {
  const { reference, msisdn, currency = 'UGX', amount, description } = params;

  if (!reference || reference.length < 8 || reference.length > 36) {
    throw new AppError('Reference must be between 8 and 36 characters', 400, 'INVALID_REFERENCE');
  }
  if (!msisdn || !msisdn.startsWith('+256')) {
    throw new AppError('Phone must be in international format: +256...', 400, 'INVALID_PHONE');
  }
  if (!amount || amount <= 0) {
    throw new AppError('Amount must be greater than 0', 400, 'INVALID_AMOUNT');
  }

  try {
    logger.info(`Relworx: Requesting payment of ${currency} ${amount} from ${msisdn}`);

    const response = await relworxClient.post('/mobile-money/request-payment', {
      account_no: config.relworxAccountNo,
      reference,
      msisdn,
      currency,
      amount: parseFloat(String(amount)),
      description: description || 'FuelAnchor Payment',
    });

    if (response.data.success) {
      logger.info('Relworx payment request initiated', response.data);
      return {
        success: true,
        message: response.data.message,
        internalReference: response.data.internal_reference,
        customerReference: reference,
        status: 'pending',
      };
    }

    throw new AppError(
      response.data.message || 'Payment request failed',
      400,
      'PAYMENT_REQUEST_FAILED'
    );
  } catch (error: any) {
    if (error instanceof AppError) throw error;
    if (error.response?.status === 429) {
      throw new AppError(
        'Too many payment requests for this number. Try again in a few minutes.',
        429,
        'RATE_LIMIT_EXCEEDED'
      );
    }
    logger.error('Relworx payment request error:', error.response?.data || error.message);
    throw new AppError(
      error.response?.data?.message || error.message || 'Payment initiation failed',
      error.response?.status || 500,
      'PAYMENT_ERROR'
    );
  }
};

/**
 * Send payment (Disbursement) - push money to a recipient
 */
export const sendPayment = async (params: {
  reference: string;
  msisdn: string;
  currency?: string;
  amount: number;
  description?: string;
}): Promise<RelworxPaymentResult> => {
  const { reference, msisdn, currency = 'UGX', amount, description } = params;

  try {
    logger.info(`Relworx: Sending payment of ${currency} ${amount} to ${msisdn}`);

    const response = await relworxClient.post('/mobile-money/send-payment', {
      account_no: config.relworxAccountNo,
      reference,
      msisdn,
      currency,
      amount: parseFloat(String(amount)),
      description: description || 'FuelAnchor Payout',
    });

    if (response.data.success) {
      logger.info('Relworx payment send initiated', response.data);
      return {
        success: true,
        message: response.data.message,
        internalReference: response.data.internal_reference,
        customerReference: reference,
        status: 'pending',
      };
    }

    throw new AppError(
      response.data.message || 'Payment send failed',
      400,
      'PAYMENT_SEND_FAILED'
    );
  } catch (error: any) {
    if (error instanceof AppError) throw error;
    logger.error('Relworx payment send error:', error.response?.data || error.message);
    throw new AppError(
      error.response?.data?.message || error.message || 'Payment send failed',
      error.response?.status || 500,
      'PAYMENT_ERROR'
    );
  }
};

/**
 * Check status of a payment by its internal or customer reference
 */
export const checkRequestStatus = async (
  internalReference: string
): Promise<RelworxStatusResult> => {
  try {
    const response = await relworxClient.get('/mobile-money/check-request-status', {
      params: {
        internal_reference: internalReference,
        account_no: config.relworxAccountNo,
      },
    });

    if (response.data.success) {
      const d = response.data;
      return {
        success: true,
        status: d.status,
        requestStatus: d.request_status,
        message: d.message,
        customerReference: d.customer_reference,
        internalReference: d.internal_reference,
        msisdn: d.msisdn,
        amount: d.amount,
        currency: d.currency,
        provider: d.provider,
        charge: d.charge,
        providerTransactionId: d.provider_transaction_id,
        completedAt: d.completed_at,
      };
    }

    return { success: false, status: 'unknown', message: 'Status check failed' };
  } catch (error: any) {
    logger.error('Relworx status check error:', error.response?.data || error.message);
    throw new AppError(
      error.response?.data?.message || 'Status check failed',
      error.response?.status || 500,
      'STATUS_CHECK_FAILED'
    );
  }
};

/**
 * Check Relworx wallet balance
 */
export const checkWalletBalance = async (
  currency = 'UGX'
): Promise<RelworxBalanceResult> => {
  try {
    const response = await relworxClient.get('/mobile-money/check-wallet-balance', {
      params: { account_no: config.relworxAccountNo, currency },
    });

    if (response.data.success) {
      return { success: true, balance: response.data.balance, currency };
    }
    return { success: false, message: 'Balance check failed' };
  } catch (error: any) {
    logger.error('Relworx balance check error:', error.response?.data || error.message);
    throw new AppError(
      error.response?.data?.message || 'Balance check failed',
      error.response?.status || 500,
      'BALANCE_CHECK_FAILED'
    );
  }
};

/**
 * Get transaction history (last 30 days, max 1000)
 */
export const getTransactionHistory = async (): Promise<{
  success: boolean;
  transactions: RelworxTransaction[];
}> => {
  try {
    const response = await relworxClient.get('/payment-requests/transactions', {
      params: { account_no: config.relworxAccountNo },
    });

    if (response.data.success) {
      return { success: true, transactions: response.data.transactions || [] };
    }
    return { success: false, transactions: [] };
  } catch (error: any) {
    logger.error('Relworx transaction history error:', error.response?.data || error.message);
    throw new AppError(
      error.response?.data?.message || 'Failed to fetch transaction history',
      error.response?.status || 500,
      'HISTORY_FETCH_FAILED'
    );
  }
};

// Default export as a service object (consistent with other services)
export const relworxService = {
  validateMobileNumber,
  requestPayment,
  sendPayment,
  checkRequestStatus,
  checkWalletBalance,
  getTransactionHistory,
  formatPhoneNumber,
  getProvider,
};

export default relworxService;
