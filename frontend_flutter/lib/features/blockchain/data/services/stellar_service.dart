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
  
  // Deployed contract IDs from Phase 1 (Feb 21, 2026)
  static const String _fuelAssetIssuer = 'GCHWQJ4OVQBBOSWEQUXYXFMWVIINIMN2AXWU6FRKCB7YA6NPFFJOJXKX';
  static const String _sorobanContractId = 'CDRQE4CCMQP5AFZZQ6MFADSAAGXFQZQVUKX6H66AQW5BUDPDSB32ITNB';

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
            
            // Search for FUEL token balance
            Balance? fuelBalance;
            
            for (final balance in account.balances) {
              // Check for FUEL token issued by our admin account
              if (balance.assetType != Asset.TYPE_NATIVE) {
                // For credit_alphanum4 or credit_alphanum12
                final assetCode = balance.assetCode;
                final assetIssuer = balance.assetIssuer;
                
                if (assetCode == _fuelAssetCode && assetIssuer == _fuelAssetIssuer) {
                  fuelBalance = balance;
                  break;
                }
              }
            }
            
            // If FUEL token not found, check if trustline exists
            if (fuelBalance == null) {
              AppLogger.info('FUEL token not found in balances. User may need to establish trustline.');
              return Right(WalletBalance(
                assetCode: _fuelAssetCode,
                balance: '0',
                assetIssuer: _fuelAssetIssuer,
              ));
            }
            
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
            AppLogger.info('Amount: $amount, GPS: $driverGps');
            
            // Get driver's public key
            final driverAddress = keyPair.accountId;
            
            // Load driver's account to get sequence number
            final account = await _sdk.accounts.account(driverAddress);
            
            // Convert GPS coordinates to micro-degrees (multiply by 1,000,000)
            final latMicroDegrees = (driverGps['latitude']! * 1000000).round();
            final lngMicroDegrees = (driverGps['longitude']! * 1000000).round();
            
            // Build contract invocation for pay_merchant function
            // Parameters: driver (Address), merchant (Address), amount (i128), driver_gps ((i128, i128))
            final contractAddress = Address.forContractId(_sorobanContractId);
            
            // Create XDR values for function arguments
            final driverAddressValue = Address.forAccountId(driverAddress);
            final merchantAddressValue = Address.forAccountId(merchantId);
            final amountValue = XdrSCVal.forI128(
              XdrInt128Parts(
                XdrUint64(BigInt.from((int.parse(amount) >> 64) & 0xFFFFFFFFFFFFFFFF).toInt()),
                XdrUint64(BigInt.from(int.parse(amount) & 0xFFFFFFFFFFFFFFFF).toInt()),
              ),
            );
            
            // Create GPS tuple (latitude, longitude) in micro-degrees
            final gpsLatValue = XdrSCVal.forI128(
              XdrInt128Parts(
                XdrUint64(BigInt.from((latMicroDegrees >> 64) & 0xFFFFFFFFFFFFFFFF).toInt()),
                XdrUint64(BigInt.from(latMicroDegrees & 0xFFFFFFFFFFFFFFFF).toInt()),
              ),
            );
            final gpsLngValue = XdrSCVal.forI128(
              XdrInt128Parts(
                XdrUint64(BigInt.from((lngMicroDegrees >> 64) & 0xFFFFFFFFFFFFFFFF).toInt()),
                XdrUint64(BigInt.from(lngMicroDegrees & 0xFFFFFFFFFFFFFFFF).toInt()),
              ),
            );
            final gpsTuple = XdrSCVal.forVec([gpsLatValue, gpsLngValue]);
            
            // Build InvokeContractHostFunction operation
            final invokeOperation = InvokeContractHostFunction(
              contractAddress.toXdr(),
              XdrSCSymbol('pay_merchant'),
              [
                driverAddressValue.toXdr(),
                merchantAddressValue.toXdr(),
                amountValue,
                gpsTuple,
              ],
            );
            
            // Create transaction
            final transaction = TransactionBuilder(account)
                .addOperation(invokeOperation.toOperation())
                .build();
            
            // Sign transaction
            transaction.sign(keyPair, Network.TESTNET);
            
            // Submit to Soroban RPC
            final response = await _sdk.sorobanServer.sendTransaction(transaction);
            
            if (response.status == GetTransactionStatus.SUCCESS) {
              final txHash = response.hash;
              AppLogger.info('Payment successful! Transaction hash: $txHash');
              return Right(txHash);
            } else if (response.status == GetTransactionStatus.ERROR) {
              final errorMsg = response.error ?? 'Unknown transaction error';
              AppLogger.error('Payment failed: $errorMsg');
              return Left(Failure.blockchainError('Payment failed: $errorMsg'));
            } else {
              // Transaction pending
              AppLogger.info('Transaction pending: ${response.hash}');
              return Right(response.hash);
            }
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
