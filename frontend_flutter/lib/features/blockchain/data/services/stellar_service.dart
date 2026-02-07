import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import '../../../core/error/failure.dart';
import '../../../core/utils/logger.dart';
import '../../wallet/domain/entities/wallet_balance.dart';

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
      return Left(Failure.storageError('Failed to generate and store keypair'));
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
      return Left(Failure.storageError('Failed to retrieve keypair'));
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
      return Left(Failure.storageError('Failed to get public key'));
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
            final fuelBalance = account.balances.firstWhere(
              (balance) => 
                balance.assetCode == _fuelAssetCode &&
                balance.assetIssuer == _fuelAssetIssuer,
              orElse: () => Balance(
                '0',
                '',
                '',
                0,
                0,
                false,
                null,
                null,
                null,
              ),
            );
            
            return Right(WalletBalance(
              assetCode: _fuelAssetCode,
              balance: fuelBalance.balance,
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
      return Left(Failure.unknown('Unexpected error getting balance'));
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
            
            // Load the account to get the sequence number
            final sourceAccount = await _sdk.accounts.account(keyPair.accountId);
            
            // Build the Soroban contract invocation
            const contractId = _sorobanContractId;
            
            // Create function arguments
            final amountArg = XdrSCVal.forI128(
              XdrInt128Parts(
                BigInt.parse(amount).toInt(),
                0,
              ),
            );
            
            final merchantArg = XdrSCVal.forAddress(
              XdrSCAddress.forAccountId(
                XdrPublicKey.forPublicKeyTypeEd25519(
                  XdrUint256(KeyPair.fromAccountId(merchantId).publicKey),
                ),
              ),
            );
            
            // GPS coordinates as a map
            final gpsArg = XdrSCVal.forMap(
              XdrSCMap([
                XdrSCMapEntry(
                  XdrSCVal.forSymbol(XdrSCSymbol('lat')),
                  XdrSCVal.forI128(XdrInt128Parts((driverGps['latitude']! * 1e6).toInt(), 0)),
                ),
                XdrSCMapEntry(
                  XdrSCVal.forSymbol(XdrSCSymbol('lng')),
                  XdrSCVal.forI128(XdrInt128Parts((driverGps['longitude']! * 1e6).toInt(), 0)),
                ),
              ]),
            );
            
            const functionName = 'pay_merchant';
            final args = [amountArg, merchantArg, gpsArg];
            
            // Invoke the contract
            final invokeContractHostFunction = InvokeContractHostFunction(
              contractId,
              functionName,
              arguments: args,
            );
            
            final builder = InvokeHostFunctionOperationBuilder(invokeContractHostFunction);
            final operation = builder.build();
            
            final transaction = TransactionBuilder(sourceAccount)
                .addOperation(operation)
                .build();
            
            transaction.sign(keyPair, Network.TESTNET);
            
            final response = await _sdk.submitTransaction(transaction);
            
            if (response.success) {
              AppLogger.info('Payment successful: ${response.hash}');
              return Right(response.hash ?? 'Transaction successful');
            } else {
              AppLogger.error('Payment failed', response.extras?.resultCodes);
              return Left(Failure.blockchainError(
                'Transaction failed: ${response.extras?.resultCodes?.transactionResultCode}',
              ));
            }
          } catch (e, stackTrace) {
            AppLogger.error('Error executing payment', e, stackTrace);
            return Left(Failure.blockchainError('Payment execution failed: ${e.toString()}'));
          }
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error in payMerchant', e, stackTrace);
      return Left(Failure.unknown('Unexpected error during payment'));
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
              return Left(Failure.blockchainError('Failed to fund account'));
            }
          } catch (e, stackTrace) {
            AppLogger.error('Error funding account', e, stackTrace);
            return Left(Failure.blockchainError('Failed to fund account'));
          }
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error in fundTestnetAccount', e, stackTrace);
      return Left(Failure.unknown('Unexpected error funding account'));
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
      return Left(Failure.storageError('Failed to clear keypair'));
    }
  }
}
