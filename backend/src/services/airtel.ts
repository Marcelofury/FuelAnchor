/**
 * Airtel Money Integration Service
 * Handles Collections (deposits) and Disbursements (withdrawals)
 * Supports: Kenya (KES), Tanzania (TZS), Uganda (UGX), Rwanda (RWF)
 */

import axios from 'axios';
import { v4 as uuidv4 } from 'uuid';
import { config } from '../config/environment';
import { logger } from '../utils/logger';

interface AirtelTokenResponse {
  access_token: string;
  expire_in: string;
  token_type: string;
}

interface AirtelPaymentRequest {
  reference: string;
  subscriber: {
    country: string;
    currency: string;
    msisdn: string;
  };
  transaction: {
    amount: number;
    country: string;
    currency: string;
    id: string;
  };
}

interface AirtelTransferRequest {
  payee: {
    msisdn: string;
    wallet_type: 'NORMAL';
  };
  reference: string;
  pin: string;
  transaction: {
    amount: number;
    id: string;
    type: 'B2C';
  };
}

interface AirtelPaymentStatus {
  status: 'SUCCESS' | 'FAILED' | 'PENDING' | 'EXPIRED' | 'CANCELLED';
  transaction_id?: string;
  msisdn?: string;
  amount?: number;
}

// Currency to country code mapping
const CURRENCY_COUNTRY: Record<string, string> = {
  KES: 'KE',
  TZS: 'TZ',
  UGX: 'UG',
  RWF: 'RW',
};

export class AirtelMoneyService {
  private baseUrl: string;
  private accessToken: string | null = null;
  private tokenExpiry: number = 0;

  constructor() {
    this.baseUrl = config.nodeEnv === 'production'
      ? 'https://openapi.airtel.africa'
      : 'https://openapiuat.airtel.africa';
  }

  /**
   * Get OAuth access token
   */
  private async getAccessToken(): Promise<string> {
    if (this.accessToken && Date.now() < this.tokenExpiry) {
      return this.accessToken;
    }

    try {
      const response = await axios.post<AirtelTokenResponse>(
        `${this.baseUrl}/auth/oauth2/token`,
        {
          client_id: config.airtelClientId,
          client_secret: config.airtelClientSecret,
          grant_type: 'client_credentials',
        },
        {
          headers: { 'Content-Type': 'application/json' },
        }
      );

      this.accessToken = response.data.access_token;
      this.tokenExpiry = Date.now() + (parseInt(response.data.expire_in) * 1000) - 60000;
      logger.info('Airtel Money token obtained');
      return this.accessToken;
    } catch (error) {
      logger.error('Failed to get Airtel token:', error);
      throw new Error('Airtel authentication failed');
    }
  }

  /**
   * Initiate Collection (deposit) — prompts user to approve on phone
   */
  async requestCollection(
    msisdn: string,
    amount: number,
    currency: 'KES' | 'TZS' | 'UGX' | 'RWF',
    reference: string
  ): Promise<string> {
    const token = await this.getAccessToken();
    const country = CURRENCY_COUNTRY[currency] || 'KE';
    const transactionId = uuidv4();

    const payload: AirtelPaymentRequest = {
      reference,
      subscriber: {
        country,
        currency,
        msisdn: msisdn.replace(/^\+/, ''), // Remove leading +
      },
      transaction: {
        amount,
        country,
        currency,
        id: transactionId,
      },
    };

    try {
      const response = await axios.post(
        `${this.baseUrl}/merchant/v1/payments/`,
        payload,
        {
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
            'X-Country': country,
            'X-Currency': currency,
          },
        }
      );

      logger.info(`Airtel collection initiated: ${transactionId} for ${msisdn}`);
      return transactionId;
    } catch (error: any) {
      logger.error('Airtel collection failed:', error.response?.data || error.message);
      throw new Error('Failed to initiate Airtel Money collection');
    }
  }

  /**
   * Check collection/payment status
   */
  async getTransactionStatus(transactionId: string, country: string = 'KE', currency: string = 'KES'): Promise<AirtelPaymentStatus> {
    const token = await this.getAccessToken();

    try {
      const response = await axios.get(
        `${this.baseUrl}/standard/v1/payments/${transactionId}`,
        {
          headers: {
            Authorization: `Bearer ${token}`,
            'X-Country': country,
            'X-Currency': currency,
          },
        }
      );

      const data = response.data.data?.transaction;
      return {
        status: data?.status || 'PENDING',
        transaction_id: data?.airtel_money_id,
        msisdn: data?.msisdn,
        amount: data?.amount,
      };
    } catch (error: any) {
      logger.error('Airtel status check failed:', error.response?.data || error.message);
      return { status: 'FAILED' };
    }
  }

  /**
   * Initiate Disbursement (withdrawal B2B/B2C)
   */
  async disburseFunds(
    msisdn: string,
    amount: number,
    currency: 'KES' | 'TZS' | 'UGX' | 'RWF',
    reference: string
  ): Promise<string> {
    const token = await this.getAccessToken();
    const country = CURRENCY_COUNTRY[currency] || 'KE';
    const transactionId = uuidv4();

    const payload: AirtelTransferRequest = {
      payee: {
        msisdn: msisdn.replace(/^\+/, ''),
        wallet_type: 'NORMAL',
      },
      reference,
      pin: config.airtelEncryptedPin,
      transaction: {
        amount,
        id: transactionId,
        type: 'B2C',
      },
    };

    try {
      await axios.post(
        `${this.baseUrl}/standard/v1/disbursements/`,
        payload,
        {
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
            'X-Country': country,
            'X-Currency': currency,
          },
        }
      );

      logger.info(`Airtel disbursement initiated: ${transactionId} to ${msisdn}`);
      return transactionId;
    } catch (error: any) {
      logger.error('Airtel disbursement failed:', error.response?.data || error.message);
      throw new Error('Failed to initiate Airtel Money disbursement');
    }
  }

  /**
   * Process incoming webhook callback from Airtel
   */
  processCallback(body: any): {
    success: boolean;
    transactionId?: string;
    msisdn?: string;
    amount?: number;
    currency?: string;
    reference?: string;
  } {
    try {
      const transaction = body.transaction;
      if (!transaction) {
        return { success: false };
      }

      const success = transaction.status_code === 'TS';

      return {
        success,
        transactionId: transaction.id,
        msisdn: transaction.msisdn,
        amount: transaction.amount,
        currency: transaction.currency,
        reference: transaction.message,
      };
    } catch (error) {
      logger.error('Error processing Airtel callback:', error);
      return { success: false };
    }
  }
}

export const airtelService = new AirtelMoneyService();
