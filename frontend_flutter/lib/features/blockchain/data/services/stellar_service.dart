import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/logger.dart';
import '../../../wallet/domain/entities/wallet_balance.dart';

class StellarService {
  final FlutterSecureStorage _secureStorage;
  final StellarSDK _sdk;
  
  static const String _keyPairSecretKey = 'stellar_secret_key';
  static const String _keyPairPublicKey = 'stellar_public_key';
  static const String _fuelAssetCode = 'FUEL';
  
  // TODO: Replace with your actual asset issuer and contract ID
  static const String _fuelAssetIssuer = 'GXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX';
  static const String _sorobanContractId = 'CXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX';

  StellarService({
    required FlutterSecureStorage secureStorage,
    bool useTestnet = true,
  })  : _secureStorage = secureStorage,
        _sdk = useTestnet ? StellarSDK.TESTNET : StellarSDK.PUBLIC;

  /// Generate a new Stellar keypair and securely store it
  Future<Either<Failure, KeyPair>> generateAndStoreKeypair() async {
    try {
      AppLogger.info('Generating new Stellar keypair');
      
      final keyPair = KeyPair.random();
      
      await _secureStorage.write(
        key: _keyPairSecretKey,
        value: keyPair.secretSeed,
      );
      await _secureStorage.write(
        key: _keyPairPublicKey,
        value: keyPair.accountId,
      );
      
      AppLogger.info('Keypair generated and stored securely');
      return Right(keyPair);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to generate keypair', e, stackTrace);
      return const Left(Failure.storageError('Failed to generate and store keypair'));
    }
  }

  /// Retrieve the stored keypair
  Future<Either<Failure, KeyPair>> getStoredKeypair() async {
    try {
      final secretSeed = await _secureStorage.read(key: _keyPairSecretKey);
      
      if (secretSeed == null) {
        return const Left(Failure.notFound('No keypair found in storage'));
      }
      
      final keyPair = KeyPair.fromSecretSeed(secretSeed);
      return Right(keyPair);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to retrieve keypair', e, stackTrace);
      return const Left(Failure.storageError('Failed to retrieve keypair'));
    }
  }

  /// Get the public key from storage
  Future<Either<Failure, String>> getPublicKey() async {
    try {
      final publicKey = await _secureStorage.read(key: _keyPairPublicKey);
      
      if (publicKey == null) {
        return const Left(Failure.notFound('No public key found'));
      }
      
      return Right(publicKey);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get public key', e, stackTrace);
      return const Left(Failure.storageError('Failed to get public key'));
    }
  }

  /// Check balance for the custom FUEL asset
  Future<Either<Failure, WalletBalance>> getFuelBalance() async {
    try {
      final keyPairResult = await getStoredKeypair();
      
      return keyPairResult.fold(
        (failure) => Left(failure),
        (keyPair) async {
          try {
            final accountId = keyPair.accountId;
            final account = await _sdk.accounts.account(accountId);
            
            // Find the FUEL asset balance
            // For now, return XLM balance (native asset) or default
            // TODO: Update to search for custom FUEL asset after issuing it
            final nativeBalance = account.balances.firstWhere(
              (balance) => balance.assetType == Asset.TYPE_NATIVE,
              orElse: () => account.balances.first,
            );
            
            return Right(WalletBalance(
              assetCode: _fuelAssetCode,
              balance: nativeBalance.balance,
              assetIssuer: _fuelAssetIssuer,
            ));
          } catch (e, stackTrace) {
            AppLogger.error('Failed to fetch balance', e, stackTrace);
            return Left(Failure.blockchainError('Failed to fetch balance: ${e.toString()}'));
          }
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error in getFuelBalance', e, stackTrace);
      return const Left(Failure.unknown('Unexpected error getting balance'));
    }
  }

  /// Call Soroban smart contract function: pay_merchant
  Future<Either<Failure, String>> payMerchant({
    required String amount,
    required String merchantId,
    required Map<String, double> driverGps,
  }) async {
    try {
      final keyPairResult = await getStoredKeypair();
      
      return keyPairResult.fold(
        (failure) => Left(failure),
        (keyPair) async {
          try {
            AppLogger.info('Initiating payment to merchant: $merchantId');
            
            // TODO: Implement Soroban smart contract invocation for pay_merchant
            // The Stellar SDK API has changed significantly in v1.9.4
            // This needs to be updated to use the new Soroban APIs:
            // - Use proper contract invocation builders
            // - Update XDR value constructors
            // - Handle contract deployment and initialization
            
            // For now, returning a mock transaction hash to allow app to compile and run
            // This should be replaced with actual contract invocation once the 
            // smart contracts are deployed and the SDK API is properly configured
            
            await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
            
            final mockHash = 'mock_tx_${DateTime.now().millisecondsSinceEpoch}';
            AppLogger.info('Mock payment transaction: $mockHash');
            AppLogger.info('Amount: $amount, Merchant: $merchantId, GPS: $driverGps');
            
            return Right(mockHash);
          } catch (e, stackTrace) {
            AppLogger.error('Error executing payment', e, stackTrace);
            return Left(Failure.blockchainError('Payment execution failed: ${e.toString()}'));
          }
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error in payMerchant', e, stackTrace);
      return const Left(Failure.unknown('Unexpected error during payment'));
    }
  }

  /// Fund account on testnet (for development)
  Future<Either<Failure, bool>> fundTestnetAccount() async {
    try {
      final publicKeyResult = await getPublicKey();
      
      return publicKeyResult.fold(
        (failure) => Left(failure),
        (publicKey) async {
          try {
            AppLogger.info('Funding testnet account: $publicKey');
            final funded = await FriendBot.fundTestAccount(publicKey);
            
            if (funded) {
              AppLogger.info('Account funded successfully');
              return const Right(true);
            } else {
              return const Left(Failure.blockchainError('Failed to fund account'));
            }
          } catch (e, stackTrace) {
            AppLogger.error('Error funding account', e, stackTrace);
            return const Left(Failure.blockchainError('Failed to fund account'));
          }
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error in fundTestnetAccount', e, stackTrace);
      return const Left(Failure.unknown('Unexpected error funding account'));
    }
  }

  /// Clear stored keypair (logout)
  Future<Either<Failure, void>> clearKeypair() async {
    try {
      await _secureStorage.delete(key: _keyPairSecretKey);
      await _secureStorage.delete(key: _keyPairPublicKey);
      AppLogger.info('Keypair cleared from storage');
      return const Right(null);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to clear keypair', e, stackTrace);
      return const Left(Failure.storageError('Failed to clear keypair'));
    }
  }
}
