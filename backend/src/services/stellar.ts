/**
 * Stellar Blockchain Service
 * Handles all interactions with Stellar network and Soroban smart contracts
 */

import * as StellarSdk from '@stellar/stellar-sdk';
import { config } from '../config/environment';
import { logger } from '../utils/logger';

// Network configuration
const getNetworkPassphrase = (): string => {
  switch (config.stellarNetwork) {
    case 'mainnet':
      return StellarSdk.Networks.PUBLIC;
    case 'testnet':
      return StellarSdk.Networks.TESTNET;
    default:
      return config.stellarNetworkPassphrase;
  }
};

// Initialize Stellar server
const server = new StellarSdk.Horizon.Server(config.stellarHorizonUrl);
const sorobanServer = new StellarSdk.SorobanRpc.Server(config.stellarSorobanRpcUrl);

export interface TokenTransferParams {
  from: string;
  to: string;
  amount: string;
  memo?: string;
}

export interface MintParams {
  to: string;
  amount: string;
}

export interface VoucherRedemptionParams {
  driverAddress: string;
  stationId: string;
  amount: string;
  latitude: number;
  longitude: number;
}

/**
 * Create a new Stellar keypair for a user
 */
export const createWallet = (): { publicKey: string; secretKey: string } => {
  const keypair = StellarSdk.Keypair.random();
  return {
    publicKey: keypair.publicKey(),
    secretKey: keypair.secret(),
  };
};

/**
 * Fund a testnet account using Friendbot
 */
export const fundTestnetAccount = async (publicKey: string): Promise<boolean> => {
  if (config.stellarNetwork !== 'testnet') {
    throw new Error('Friendbot only available on testnet');
  }

  try {
    const response = await fetch(
      `https://friendbot.stellar.org?addr=${encodeURIComponent(publicKey)}`
    );
    
    if (!response.ok) {
      throw new Error(`Friendbot request failed: ${response.statusText}`);
    }

    logger.info(`Funded testnet account: ${publicKey}`);
    return true;
  } catch (error) {
    logger.error('Failed to fund testnet account:', error);
    throw error;
  }
};

/**
 * Get account details from Stellar network
 */
export const getAccount = async (publicKey: string): Promise<StellarSdk.Horizon.AccountResponse> => {
  try {
    return await server.loadAccount(publicKey);
  } catch (error) {
    logger.error(`Failed to load account ${publicKey}:`, error);
    throw error;
  }
};

/**
 * Get FUEL token balance for an account
 */
export const getFuelBalance = async (publicKey: string): Promise<string> => {
  try {
    const account = await getAccount(publicKey);
    
    // Look for FUEL token balance
    const fuelBalance = account.balances.find(
      (balance) => 
        balance.asset_type !== 'native' && 
        'asset_code' in balance &&
        balance.asset_code === 'FUEL' &&
        balance.asset_issuer === config.fuelTokenIssuer
    );

    return fuelBalance ? fuelBalance.balance : '0';
  } catch (error) {
    logger.error(`Failed to get FUEL balance for ${publicKey}:`, error);
    return '0';
  }
};

/**
 * Establish trustline for FUEL token
 */
export const establishTrustline = async (
  userSecretKey: string
): Promise<StellarSdk.Horizon.HorizonApi.SubmitTransactionResponse> => {
  try {
    const userKeypair = StellarSdk.Keypair.fromSecret(userSecretKey);
    const userAccount = await server.loadAccount(userKeypair.publicKey());

    const fuelAsset = new StellarSdk.Asset('FUEL', config.fuelTokenIssuer);

    const transaction = new StellarSdk.TransactionBuilder(userAccount, {
      fee: StellarSdk.BASE_FEE,
      networkPassphrase: getNetworkPassphrase(),
    })
      .addOperation(
        StellarSdk.Operation.changeTrust({
          asset: fuelAsset,
          limit: '1000000000', // 1 billion FUEL max
        })
      )
      .setTimeout(30)
      .build();

    transaction.sign(userKeypair);

    const result = await server.submitTransaction(transaction);
    logger.info(`Trustline established for ${userKeypair.publicKey()}`);
    return result;
  } catch (error) {
    logger.error('Failed to establish trustline:', error);
    throw error;
  }
};

/**
 * Mint FUEL tokens to an address (admin only)
 */
export const mintFuelTokens = async (
  params: MintParams
): Promise<StellarSdk.Horizon.HorizonApi.SubmitTransactionResponse> => {
  try {
    const distributorKeypair = StellarSdk.Keypair.fromSecret(config.distributorSecretKey);
    const distributorAccount = await server.loadAccount(distributorKeypair.publicKey());

    const fuelAsset = new StellarSdk.Asset('FUEL', config.fuelTokenIssuer);

    const transaction = new StellarSdk.TransactionBuilder(distributorAccount, {
      fee: StellarSdk.BASE_FEE,
      networkPassphrase: getNetworkPassphrase(),
    })
      .addOperation(
        StellarSdk.Operation.payment({
          destination: params.to,
          asset: fuelAsset,
          amount: params.amount,
        })
      )
      .setTimeout(30)
      .build();

    transaction.sign(distributorKeypair);

    const result = await server.submitTransaction(transaction);
    logger.info(`Minted ${params.amount} FUEL to ${params.to}`);
    return result;
  } catch (error) {
    logger.error('Failed to mint FUEL tokens:', error);
    throw error;
  }
};

/**
 * Transfer FUEL tokens between addresses
 */
export const transferFuelTokens = async (
  fromSecretKey: string,
  params: TokenTransferParams
): Promise<StellarSdk.Horizon.HorizonApi.SubmitTransactionResponse> => {
  try {
    const fromKeypair = StellarSdk.Keypair.fromSecret(fromSecretKey);
    const fromAccount = await server.loadAccount(fromKeypair.publicKey());

    const fuelAsset = new StellarSdk.Asset('FUEL', config.fuelTokenIssuer);

    let builder = new StellarSdk.TransactionBuilder(fromAccount, {
      fee: StellarSdk.BASE_FEE,
      networkPassphrase: getNetworkPassphrase(),
    })
      .addOperation(
        StellarSdk.Operation.payment({
          destination: params.to,
          asset: fuelAsset,
          amount: params.amount,
        })
      );

    // Add memo if provided (for audit trail)
    if (params.memo) {
      builder = builder.addMemo(StellarSdk.Memo.text(params.memo));
    }

    const transaction = builder.setTimeout(30).build();
    transaction.sign(fromKeypair);

    const result = await server.submitTransaction(transaction);
    logger.info(`Transferred ${params.amount} FUEL from ${params.from} to ${params.to}`);
    return result;
  } catch (error) {
    logger.error('Failed to transfer FUEL tokens:', error);
    throw error;
  }
};

/**
 * Path payment - convert local currency to FUEL for station
 */
export const pathPayment = async (
  fromSecretKey: string,
  destinationAddress: string,
  sendAsset: StellarSdk.Asset,
  destAsset: StellarSdk.Asset,
  sendMax: string,
  destAmount: string
): Promise<StellarSdk.Horizon.HorizonApi.SubmitTransactionResponse> => {
  try {
    const fromKeypair = StellarSdk.Keypair.fromSecret(fromSecretKey);
    const fromAccount = await server.loadAccount(fromKeypair.publicKey());

    const transaction = new StellarSdk.TransactionBuilder(fromAccount, {
      fee: StellarSdk.BASE_FEE,
      networkPassphrase: getNetworkPassphrase(),
    })
      .addOperation(
        StellarSdk.Operation.pathPaymentStrictReceive({
          sendAsset,
          sendMax,
          destination: destinationAddress,
          destAsset,
          destAmount,
        })
      )
      .setTimeout(30)
      .build();

    transaction.sign(fromKeypair);

    const result = await server.submitTransaction(transaction);
    logger.info(`Path payment executed to ${destinationAddress}`);
    return result;
  } catch (error) {
    logger.error('Failed to execute path payment:', error);
    throw error;
  }
};

/**
 * Create claimable balance for driver wallet
 */
export const createClaimableBalance = async (
  sponsorSecretKey: string,
  claimantAddress: string,
  amount: string,
  conditions: StellarSdk.xdr.ClaimPredicate
): Promise<string> => {
  try {
    const sponsorKeypair = StellarSdk.Keypair.fromSecret(sponsorSecretKey);
    const sponsorAccount = await server.loadAccount(sponsorKeypair.publicKey());

    const fuelAsset = new StellarSdk.Asset('FUEL', config.fuelTokenIssuer);

    const claimant = new StellarSdk.Claimant(claimantAddress, conditions);

    const transaction = new StellarSdk.TransactionBuilder(sponsorAccount, {
      fee: StellarSdk.BASE_FEE,
      networkPassphrase: getNetworkPassphrase(),
    })
      .addOperation(
        StellarSdk.Operation.createClaimableBalance({
          asset: fuelAsset,
          amount,
          claimants: [claimant],
        })
      )
      .setTimeout(30)
      .build();

    transaction.sign(sponsorKeypair);

    const result = await server.submitTransaction(transaction);
    
    // Extract claimable balance ID from result
    const balanceId = (result as any).result_xdr; // Simplified - need to parse XDR properly
    
    logger.info(`Created claimable balance for ${claimantAddress}: ${amount} FUEL`);
    return balanceId;
  } catch (error) {
    logger.error('Failed to create claimable balance:', error);
    throw error;
  }
};

/**
 * Stream transactions for real-time updates
 */
export const streamTransactions = (
  accountId: string,
  onMessage: (transaction: StellarSdk.Horizon.ServerApi.TransactionRecord) => void,
  onError: (error: Error) => void
): () => void => {
  const stream = server
    .transactions()
    .forAccount(accountId)
    .cursor('now')
    .stream({
      onmessage: onMessage,
      onerror: onError,
    });

  return stream;
};

/**
 * Get transaction history for an account
 */
export const getTransactionHistory = async (
  accountId: string,
  limit: number = 20
): Promise<StellarSdk.Horizon.ServerApi.TransactionRecord[]> => {
  try {
    const transactions = await server
      .transactions()
      .forAccount(accountId)
      .limit(limit)
      .order('desc')
      .call();

    return transactions.records;
  } catch (error) {
    logger.error(`Failed to get transaction history for ${accountId}:`, error);
    throw error;
  }
};

/**
 * Invoke Soroban smart contract
 */
export const invokeSorobanContract = async (
  contractId: string,
  method: string,
  args: StellarSdk.xdr.ScVal[],
  signerSecretKey: string
): Promise<any> => {
  try {
    const signerKeypair = StellarSdk.Keypair.fromSecret(signerSecretKey);
    const account = await sorobanServer.getAccount(signerKeypair.publicKey());

    const contract = new StellarSdk.Contract(contractId);
    
    const transaction = new StellarSdk.TransactionBuilder(account, {
      fee: StellarSdk.BASE_FEE,
      networkPassphrase: getNetworkPassphrase(),
    })
      .addOperation(contract.call(method, ...args))
      .setTimeout(30)
      .build();

    // Simulate first
    const simulation = await sorobanServer.simulateTransaction(transaction);
    
    if ('error' in simulation) {
      throw new Error(`Simulation failed: ${simulation.error}`);
    }

    // Prepare and sign
    const preparedTx = StellarSdk.SorobanRpc.assembleTransaction(
      transaction,
      simulation
    ).build();
    
    preparedTx.sign(signerKeypair);

    // Submit
    const response = await sorobanServer.sendTransaction(preparedTx);
    
    // Wait for confirmation
    if (response.status === 'PENDING') {
      let result = await sorobanServer.getTransaction(response.hash);
      while (result.status === 'NOT_FOUND') {
        await new Promise(resolve => setTimeout(resolve, 1000));
        result = await sorobanServer.getTransaction(response.hash);
      }
      return result;
    }

    return response;
  } catch (error) {
    logger.error(`Failed to invoke contract ${contractId}.${method}:`, error);
    throw error;
  }
};

export default {
  createWallet,
  fundTestnetAccount,
  getAccount,
  getFuelBalance,
  establishTrustline,
  mintFuelTokens,
  transferFuelTokens,
  pathPayment,
  createClaimableBalance,
  streamTransactions,
  getTransactionHistory,
  invokeSorobanContract,
};
