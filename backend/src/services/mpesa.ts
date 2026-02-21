import axios from 'axios';
import { config } from '../config/environment';
import { logger } from '../utils/logger';

/**
 * M-Pesa (Safaricom) Integration Service
 * Handles STK Push (Lipa Na M-Pesa Online) for payments
 */

interface MPesaAuthResponse {
  access_token: string;
  expires_in: string;
}

interface STKPushRequest {
  phoneNumber: string;
  amount: number;
  accountReference: string;
  transactionDesc: string;
}

interface STKPushResponse {
  MerchantRequestID: string;
  CheckoutRequestID: string;
  ResponseCode: string;
  ResponseDescription: string;
  CustomerMessage: string;
}

interface STKQueryResponse {
  ResponseCode: string;
  ResponseDescription: string;
  MerchantRequestID: string;
  CheckoutRequestID: string;
  ResultCode: string;
  ResultDesc: string;
}

export class MPesaService {
  private baseUrl: string;
  private accessToken: string | null = null;
  private tokenExpiry: number = 0;

  constructor() {
    this.baseUrl = config.nodeEnv === 'production'
      ? 'https://api.safaricom.co.ke'
      : 'https://sandbox.safaricom.co.ke';
  }

  /**
   * Get OAuth access token from M-Pesa
   */
  private async getAccessToken(): Promise<string> {
    // Check if existing token is still valid
    if (this.accessToken && Date.now() < this.tokenExpiry) {
      return this.accessToken;
    }

    try {
      const auth = Buffer.from(
        `${config.mpesaConsumerKey}:${config.mpesaConsumerSecret}`
      ).toString('base64');

      const response = await axios.get<MPesaAuthResponse>(
        `${this.baseUrl}/oauth/v1/generate?grant_type=client_credentials`,
        {
          headers: {
            Authorization: `Basic ${auth}`,
          },
        }
      );

      this.accessToken = response.data.access_token;
      // Set expiry to 1 hour from now (M-Pesa tokens expire in 1 hour)
      this.tokenExpiry = Date.now() + 3600000;

      logger.info('M-Pesa access token obtained');
      return this.accessToken;
    } catch (error) {
      logger.error('Failed to get M-Pesa access token:', error);
      throw new Error('M-Pesa authentication failed');
    }
  }

  /**
   * Generate timestamp in M-Pesa format (YYYYMMDDHHmmss)
   */
  private generateTimestamp(): string {
    const now = new Date();
    return now.toISOString()
      .replace(/[-:TZ.]/g, '')
      .slice(0, 14);
  }

  /**
   * Generate password for STK Push
   */
  private generatePassword(timestamp: string): string {
    const data = `${config.mpesaShortcode}${config.mpesaPasskey}${timestamp}`;
    return Buffer.from(data).toString('base64');
  }

  /**
   * Initiate STK Push for payment
   */
  async initiateSTKPush(request: STKPushRequest): Promise<STKPushResponse> {
    try {
      const token = await this.getAccessToken();
      const timestamp = this.generateTimestamp();
      const password = this.generatePassword(timestamp);

      // Format phone number (remove + and ensure Kenya format)
      let phoneNumber = request.phoneNumber.replace(/[^0-9]/g, '');
      if (phoneNumber.startsWith('0')) {
        phoneNumber = '254' + phoneNumber.substring(1);
      } else if (!phoneNumber.startsWith('254')) {
        phoneNumber = '254' + phoneNumber;
      }

      const payload = {
        BusinessShortCode: config.mpesaShortcode,
        Password: password,
        Timestamp: timestamp,
        TransactionType: 'CustomerPayBillOnline',
        Amount: Math.round(request.amount),
        PartyA: phoneNumber,
        PartyB: config.mpesaShortcode,
        PhoneNumber: phoneNumber,
        CallBackURL: config.mpesaCallbackUrl,
        AccountReference: request.accountReference,
        TransactionDesc: request.transactionDesc,
      };

      const response = await axios.post<STKPushResponse>(
        `${this.baseUrl}/mpesa/stkpush/v1/processrequest`,
        payload,
        {
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
        }
      );

      logger.info('STK Push initiated', {
        merchantRequestId: response.data.MerchantRequestID,
        checkoutRequestId: response.data.CheckoutRequestID,
      });

      return response.data;
    } catch (error: any) {
      logger.error('STK Push failed:', error.response?.data || error.message);
      throw new Error('Failed to initiate M-Pesa payment');
    }
  }

  /**
   * Query STK Push transaction status
   */
  async querySTKPush(checkoutRequestId: string): Promise<STKQueryResponse> {
    try {
      const token = await this.getAccessToken();
      const timestamp = this.generateTimestamp();
      const password = this.generatePassword(timestamp);

      const payload = {
        BusinessShortCode: config.mpesaShortcode,
        Password: password,
        Timestamp: timestamp,
        CheckoutRequestID: checkoutRequestId,
      };

      const response = await axios.post<STKQueryResponse>(
        `${this.baseUrl}/mpesa/stkpushquery/v1/query`,
        payload,
        {
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
        }
      );

      return response.data;
    } catch (error: any) {
      logger.error('STK Push query failed:', error.response?.data || error.message);
      throw new Error('Failed to query M-Pesa transaction status');
    }
  }

  /**
   * Process M-Pesa callback
   */
  processCallback(callbackData: any): {
    success: boolean;
    transactionId?: string;
    amount?: number;
    phoneNumber?: string;
    resultCode: string;
    resultDesc: string;
  } {
    try {
      const { Body } = callbackData;
      const { stkCallback } = Body;

      const resultCode = stkCallback.ResultCode;
      const resultDesc = stkCallback.ResultDesc;

      if (resultCode === 0) {
        // Success
        const callbackMetadata = stkCallback.CallbackMetadata.Item;
        const amount = callbackMetadata.find((item: any) => item.Name === 'Amount')?.Value;
        const mpesaReceiptNumber = callbackMetadata.find(
          (item: any) => item.Name === 'MpesaReceiptNumber'
        )?.Value;
        const phoneNumber = callbackMetadata.find(
          (item: any) => item.Name === 'PhoneNumber'
        )?.Value;

        logger.info('M-Pesa payment successful', {
          transactionId: mpesaReceiptNumber,
          amount,
          phoneNumber,
        });

        return {
          success: true,
          transactionId: mpesaReceiptNumber,
          amount,
          phoneNumber: phoneNumber?.toString(),
          resultCode: resultCode.toString(),
          resultDesc,
        };
      } else {
        // Failed or cancelled
        logger.warn('M-Pesa payment failed', { resultCode, resultDesc });
        return {
          success: false,
          resultCode: resultCode.toString(),
          resultDesc,
        };
      }
    } catch (error) {
      logger.error('Failed to process M-Pesa callback:', error);
      throw new Error('Invalid M-Pesa callback data');
    }
  }

  /**
   * Initiate B2C (Business to Customer) payment for withdrawals
   */
  async initiateB2CPayment(phoneNumber: string, amount: number, remarks: string): Promise<any> {
    try {
      const token = await this.getAccessToken();
      
      // Format phone number
      let formattedPhone = phoneNumber.replace(/[^0-9]/g, '');
      if (formattedPhone.startsWith('0')) {
        formattedPhone = '254' + formattedPhone.substring(1);
      }

      const payload = {
        InitiatorName: 'FuelAnchor',
        SecurityCredential: config.mpesaSecurityCredential || '', // Encrypted password
        CommandID: 'BusinessPayment',
        Amount: Math.round(amount),
        PartyA: config.mpesaShortcode,
        PartyB: formattedPhone,
        Remarks: remarks,
        QueueTimeOutURL: `${config.mpesaCallbackUrl}/timeout`,
        ResultURL: `${config.mpesaCallbackUrl}/result`,
        Occasion: 'FuelAnchor Withdrawal',
      };

      const response = await axios.post(
        `${this.baseUrl}/mpesa/b2c/v1/paymentrequest`,
        payload,
        {
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
        }
      );

      logger.info('B2C payment initiated', { response: response.data });
      return response.data;
    } catch (error: any) {
      logger.error('B2C payment failed:', error.response?.data || error.message);
      throw new Error('Failed to initiate M-Pesa withdrawal');
    }
  }
}

export const mpesaService = new MPesaService();
