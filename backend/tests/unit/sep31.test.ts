import { sep31Service } from '../../src/services/sep31';

describe('SEP-31 Cross-Border Payment Service', () => {
  describe('Exchange Rate Operations', () => {
    it('should get exchange rate between supported currencies', async () => {
      const rate = await sep31Service.getExchangeRate('KES', 'UGX');

      expect(rate).toHaveProperty('sourceCurrency', 'KES');
      expect(rate).toHaveProperty('destinationCurrency', 'UGX');
      expect(rate).toHaveProperty('rate');
      expect(rate).toHaveProperty('validUntil');
      expect(rate.rate).toBeGreaterThan(0);
    });

    it('should throw error for unsupported currency pair', async () => {
      await expect(
        sep31Service.getExchangeRate('KES', 'INVALID')
      ).rejects.toThrow('Exchange rate not available');
    });

    it('should validate currency pair support', () => {
      expect(sep31Service.isCurrencyPairSupported('KES', 'UGX')).toBe(true);
      expect(sep31Service.isCurrencyPairSupported('KES', 'INVALID')).toBe(false);
    });
  });

  describe('Quote Operations', () => {
    it('should create a valid quote', async () => {
      const quote = await sep31Service.createQuote('KES', 'UGX', '1000');

      expect(quote).toHaveProperty('id');
      expect(quote).toHaveProperty('price');
      expect(quote).toHaveProperty('sellAsset', 'KES');
      expect(quote).toHaveProperty('buyAsset', 'UGX');
      expect(quote).toHaveProperty('sellAmount', '1000');
      expect(quote).toHaveProperty('buyAmount');
      expect(quote).toHaveProperty('expiresAt');
      expect(quote).toHaveProperty('fee');
      expect(parseFloat(quote.buyAmount)).toBeGreaterThan(0);
    });

    it('should calculate correct fee (1%)', async () => {
      const quote = await sep31Service.createQuote('KES', 'USD', '1000');

      expect(quote.fee.asset).toBe('KES');
      expect(parseFloat(quote.fee.total)).toBe(10); // 1% of 1000
    });

    it('should retrieve existing quote by ID', async () => {
      const createdQuote = await sep31Service.createQuote('KES', 'UGX', '1000');
      const retrievedQuote = sep31Service.getQuote(createdQuote.id);

      expect(retrievedQuote).not.toBeNull();
      expect(retrievedQuote?.id).toBe(createdQuote.id);
    });

    it('should return null for non-existent quote', () => {
      const quote = sep31Service.getQuote('non-existent-id');
      expect(quote).toBeNull();
    });

    it('should expire quotes after validity period', async () => {
      const quote = await sep31Service.createQuote('KES', 'UGX', '1000');
      
      // Manually set expiration to past
      quote.expiresAt = new Date(Date.now() - 1000);

      const retrievedQuote = sep31Service.getQuote(quote.id);
      expect(retrievedQuote).toBeNull();
    });
  });

  describe('Transaction Operations', () => {
    it('should initiate transaction with valid quote', async () => {
      const quote = await sep31Service.createQuote('KES', 'UGX', '1000');
      
      const transaction = await sep31Service.initiateTransaction(
        quote.id,
        'sender-123',
        'receiver-456',
        'GAKSTEST1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ123456',
        'GAKSTEST7890123456ABCDEFGHIJKLMNOPQRSTUVWXYZ789012'
      );

      expect(transaction).toHaveProperty('id');
      expect(transaction).toHaveProperty('status', 'pending');
      expect(transaction).toHaveProperty('sendAmount', '1000');
      expect(transaction).toHaveProperty('sendCurrency', 'KES');
      expect(transaction).toHaveProperty('receiveCurrency', 'UGX');
      expect(transaction).toHaveProperty('quoteId', quote.id);
    });

    it('should reject transaction with expired quote', async () => {
      await expect(
        sep31Service.initiateTransaction(
          'expired-quote-id',
          'sender-123',
          'receiver-456',
          'GAKSTEST1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ123456',
          'GAKSTEST7890123456ABCDEFGHIJKLMNOPQRSTUVWXYZ789012'
        )
      ).rejects.toThrow('Quote not found or expired');
    });

    it('should retrieve transaction by ID', async () => {
      const quote = await sep31Service.createQuote('KES', 'UGX', '1000');
      const createdTx = await sep31Service.initiateTransaction(
        quote.id,
        'sender-123',
        'receiver-456',
        'GAKSTEST1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ123456',
        'GAKSTEST7890123456ABCDEFGHIJKLMNOPQRSTUVWXYZ789012'
      );

      const retrievedTx = sep31Service.getTransaction(createdTx.id);
      expect(retrievedTx).not.toBeNull();
      expect(retrievedTx?.id).toBe(createdTx.id);
    });

    it('should retrieve user transactions', async () => {
      const quote = await sep31Service.createQuote('KES', 'UGX', '1000');
      await sep31Service.initiateTransaction(
        quote.id,
        'user-123',
        'receiver-456',
        'GAKSTEST1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ123456',
        'GAKSTEST7890123456ABCDEFGHIJKLMNOPQRSTUVWXYZ789012'
      );

      const transactions = sep31Service.getUserTransactions('user-123');
      expect(transactions.length).toBeGreaterThan(0);
      expect(transactions[0].senderId).toBe('user-123');
    });
  });

  describe('Currency Support', () => {
    it('should return all supported currencies', () => {
      const currencies = sep31Service.getSupportedCurrencies();

      expect(currencies).toHaveProperty('KES');
      expect(currencies).toHaveProperty('UGX');
      expect(currencies).toHaveProperty('TZS');
      expect(currencies).toHaveProperty('RWF');
      expect(currencies).toHaveProperty('USD');
      expect(currencies).toHaveProperty('USDC');
    });

    it('should have correct currency metadata', () => {
      const currencies = sep31Service.getSupportedCurrencies();

      expect(currencies.KES).toHaveProperty('code', 'KES');
      expect(currencies.KES).toHaveProperty('issuer');
      expect(currencies.KES).toHaveProperty('name', 'Kenyan Shilling');
    });
  });
});
