import axios from 'axios';
import { v4 as uuidv4 } from 'uuid';
import { config } from '../config/environment';
import { logger } from '../utils/logger';

/**
 * MTN Mobile Money Integration Service
 * Handles Collections (deposits) and Disbursements (withdrawals)
 */

interface MTNTokenResponse {
  access_token: string;
  token_type: string;
  expires_in: number;
}

interface MTNPaymentRequest {
  amount: string;
  currency: string;
  externalId: string;
  payer: {
    partyIdType: string;
    partyId: string;
  };
  payerMessage: string;
  payeeNote: string;
}

interface MTNPaymentResponse {
  status: string;
  reason?: string;
}

interface MTNTransferRequest {
  amount: string;
  currency: string;
  externalId: string;
  payee: {
    partyIdType: string;
    partyId: string;
  };
  payerMessage: string;
  payeeNote: string;
}

export class MTNMoMoService {
  private baseUrl: string;
  private collectionsToken: string | null = null;
  private disbursementsToken: string | null = null;
  private tokenExpiry: number = 0;

  constructor() {
    this.baseUrl = config.nodeEnv === 'production'
      ? 'https://proxy.momoapi.mtn.com'
      : 'https://sandbox.momodeveloper.mtn.com';
  }

  /**
   * Get OAuth access token for Collections (deposits)
   */
  private async getCollectionsToken(): Promise<string> {
    if (this.collectionsToken && Date.now() < this.tokenExpiry) {
      return this.collectionsToken;
    }

    try {
      const response = await axios.post<MTNTokenResponse>(
        `${this.baseUrl}/collection/token/`,
        {},
        {
          headers: {
            Authorization: `Basic ${Buffer.from(
              `${config.mtnCollectionsUserId}:${config.mtnApiKey}`
            ).toString('base64')}`,
            'Ocp-Apim-Subscription-Key': config.mtnSubscriptionKey,
          },
        }
      );

      this.collectionsToken = response.data.access_token;
      this.tokenExpiry = Date.now() + response.data.expires_in * 1000;

      logger.info('MTN Collections token obtained');
      return this.collectionsToken;
    } catch (error) {
      logger.error('Failed to get MTN Collections token:', error);
      throw new Error('MTN authentication failed');
    }
  }

  /**
   * Get OAuth access token for Disbursements (withdrawals)
   */
  private async getDisbursementsToken(): Promise<string> {
    if (this.disbursementsToken && Date.now() < this.tokenExpiry) {
      return this.disbursementsToken;
    }

    try {
      const response = await axios.post<MTNTokenResponse>(
        `${this.baseUrl}/disbursement/token/`,
        {},
        {
          headers: {
            Authorization: `Basic ${Buffer.from(
              `${config.mtnDisbursementsUserId}:${config.mtnApiKey}`
            ).toString('base64')}`,
            'Ocp-Apim-Subscription-Key': config.mtnSubscriptionKey,
          },
        }
      );

      this.disbursementsToken = response.data.access_token;
      this.tokenExpiry = Date.now() + response.data.expires_in * 1000;

      logger.info('MTN Disbursements token obtained');
      return this.disbursementsToken;
    } catch (error) {
      logger.error('Failed to get MTN Disbursements token:', error);
      throw new Error('MTN authentication failed');
    }
  }

  /**
   * Format phone number for MTN (256XXXXXXXXX for Uganda)
   */
  private formatPhoneNumber(phoneNumber: string, countryCode: string = '256'): string {
    let formatted = phoneNumber.replace(/[^0-9]/g, '');
    
    if (formatted.startsWith('0')) {
      formatted = countryCode + formatted.substring(1);
    } else if (!formatted.startsWith(countryCode)) {
      formatted = countryCode + formatted;
    }

    return formatted;
  }

  /**
   * Request payment from customer (Collections - Deposit)
   */
  async requestToPay(
    phoneNumber: string,
    amount: number,
    currency: string = 'UGX',
    reference: string,
    message: string = 'FuelAnchor deposit'
  ): Promise<string> {
    try {
      const token = await this.getCollectionsToken();
      const referenceId = uuidv4();
      const formattedPhone = this.formatPhoneNumber(phoneNumber);

      const payload: MTNPaymentRequest = {
        amount: amount.toString(),
        currency,
        externalId: reference,
        payer: {
          partyIdType: 'MSISDN',
          partyId: formattedPhone,
        },
        payerMessage: message,
        payeeNote: 'FuelAnchor Payment',
      };

      await axios.post(
        `${this.baseUrl}/collection/v1_0/requesttopay`,
        payload,
        {
          headers: {
            Authorization: `Bearer ${token}`,
            'X-Reference-Id': referenceId,
            'X-Target-Environment': config.nodeEnv === 'production' ? 'live' : 'sandbox',
            'Ocp-Apim-Subscription-Key': config.mtnSubscriptionKey,
            'Content-Type': 'application/json',
          },
        }
      );

      logger.info('MTN request to pay initiated', { referenceId, amount });
      return referenceId;
    } catch (error: any) {
      logger.error('MTN request to pay failed:', error.response?.data || error.message);
      throw new Error('Failed to initiate MTN payment');
    }
  }

  /**
   * Check payment status
   */
  async getPaymentStatus(referenceId: string): Promise<MTNPaymentResponse> {
    try {
      const token = await this.getCollectionsToken();

      const response = await axios.get<MTNPaymentResponse>(
        `${this.baseUrl}/collection/v1_0/requesttopay/${referenceId}`,
        {
          headers: {
            Authorization: `Bearer ${token}`,
            'X-Target-Environment': config.nodeEnv === 'production' ? 'live' : 'sandbox',
            'Ocp-Apim-Subscription-Key': config.mtnSubscriptionKey,
          },
        }
      );

      return response.data;
    } catch (error: any) {
      logger.error('Failed to get MTN payment status:', error.response?.data || error.message);
      throw new Error('Failed to query MTN transaction status');
    }
  }

  /**
   * Transfer money to customer (Disbursements - Withdrawal)
   */
  async transfer(
    phoneNumber: string,
    amount: number,
    currency: string = 'UGX',
    reference: string,
    message: string = 'FuelAnchor withdrawal'
  ): Promise<string> {
    try {
      const token = await this.getDisbursementsToken();
      const referenceId = uuidv4();
      const formattedPhone = this.formatPhoneNumber(phoneNumber);

      const payload: MTNTransferRequest = {
        amount: amount.toString(),
        currency,
        externalId: reference,
        payee: {
          partyIdType: 'MSISDN',
          partyId: formattedPhone,
        },
        payerMessage: message,
        payeeNote: 'FuelAnchor Withdrawal',
      };

      await axios.post(
        `${this.baseUrl}/disbursement/v1_0/transfer`,
        payload,
        {
          headers: {
            Authorization: `Bearer ${token}`,
            'X-Reference-Id': referenceId,
            'X-Target-Environment': config.nodeEnv === 'production' ? 'live' : 'sandbox',
            'Ocp-Apim-Subscription-Key': config.mtnSubscriptionKey,
            'Content-Type': 'application/json',
          },
        }
      );

      logger.info('MTN transfer initiated', { referenceId, amount });
      return referenceId;
    } catch (error: any) {
      logger.error('MTN transfer failed:', error.response?.data || error.message);
      throw new Error('Failed to initiate MTN withdrawal');
    }
  }

  /**
   * Check transfer status
   */
  async getTransferStatus(referenceId: string): Promise<MTNPaymentResponse> {
    try {
      const token = await this.getDisbursementsToken();

      const response = await axios.get<MTNPaymentResponse>(
        `${this.baseUrl}/disbursement/v1_0/transfer/${referenceId}`,
        {
          headers: {
            Authorization: `Bearer ${token}`,
            'X-Target-Environment': config.nodeEnv === 'production' ? 'live' : 'sandbox',
            'Ocp-Apim-Subscription-Key': config.mtnSubscriptionKey,
          },
        }
      );

      return response.data;
    } catch (error: any) {
      logger.error('Failed to get MTN transfer status:', error.response?.data || error.message);
      throw new Error('Failed to query MTN transfer status');
    }
  }

  /**
   * Get account balance
   */
  async getAccountBalance(): Promise<{ availableBalance: string; currency: string }> {
    try {
      const token = await this.getCollectionsToken();

      const response = await axios.get(
        `${this.baseUrl}/collection/v1_0/account/balance`,
        {
          headers: {
            Authorization: `Bearer ${token}`,
            'X-Target-Environment': config.nodeEnv === 'production' ? 'live' : 'sandbox',
            'Ocp-Apim-Subscription-Key': config.mtnSubscriptionKey,
          },
        }
      );

      return response.data;
    } catch (error: any) {
      logger.error('Failed to get MTN account balance:', error.response?.data || error.message);
      throw new Error('Failed to get account balance');
    }
  }
}

export const mtnMoMoService = new MTNMoMoService();
