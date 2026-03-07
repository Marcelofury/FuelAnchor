import 'package:local_auth/local_auth.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fuelanchor/core/error/failure.dart';

/// Biometric Authentication Service
/// Handles fingerprint, face ID, and PIN authentication
class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _biometricTypeKey = 'biometric_type';

  /// Check if biometric authentication is available on this device
  Future<Either<Failure, bool>> isBiometricAvailable() async {
    try {
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      
      return Right(canCheckBiometrics && isDeviceSupported);
    } catch (e) {
      return Left(Failure.unknown('Failed to check biometric availability: ${e.toString()}'));
    }
  }

  /// Get list of available biometric types
  Future<Either<Failure, List<BiometricType>>> getAvailableBiometrics() async {
    try {
      final List<BiometricType> availableBiometrics =
          await _localAuth.getAvailableBiometrics();
      
      return Right(availableBiometrics);
    } catch (e) {
      return Left(Failure.unknown('Failed to get available biometrics: ${e.toString()}'));
    }
  }

  /// Authenticate user with biometrics
  Future<Either<Failure, bool>> authenticate({
    required String reason,
    bool useErrorDialogs = true,
    bool stickyAuth = true,
    bool sensitiveTransaction = false,
  }) async {
    try {
      // Check if biometrics are available
      final availabilityResult = await isBiometricAvailable();
      final isAvailable = availabilityResult.fold(
        (failure) => false,
        (available) => available,
      );

      if (!isAvailable) {
        return Left(Failure.unknown('Biometric authentication not available on this device'));
      }

      // Attempt authentication
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          sensitiveTransaction: sensitiveTransaction,
          biometricOnly: false, // Allow fallback to PIN/pattern
        ),
      );

      return Right(didAuthenticate);
    } catch (e) {
      return Left(Failure.unknown('Biometric authentication failed: ${e.toString()}'));
    }
  }

  /// Enable biometric authentication for the app
  Future<Either<Failure, void>> enableBiometric() async {
    try {
      // First verify with biometric
      final authResult = await authenticate(
        reason: 'Verify your identity to enable biometric login',
        sensitiveTransaction: true,
      );

      return authResult.fold(
        (failure) => Left(failure),
        (success) async {
          if (success) {
            await _secureStorage.write(
              key: _biometricEnabledKey,
              value: 'true',
            );

            // Store the type of biometric used
            final biometricsResult = await getAvailableBiometrics();
            biometricsResult.fold(
              (failure) => null,
              (biometrics) async {
                if (biometrics.isNotEmpty) {
                  await _secureStorage.write(
                    key: _biometricTypeKey,
                    value: biometrics.first.toString(),
                  );
                }
              },
            );

            return const Right(null);
          } else {
            return Left(Failure.unauthorized('Biometric verification failed'));
          }
        },
      );
    } catch (e) {
      return Left(Failure.unknown('Failed to enable biometric: ${e.toString()}'));
    }
  }

  /// Disable biometric authentication for the app
  Future<Either<Failure, void>> disableBiometric() async {
    try {
      await _secureStorage.delete(key: _biometricEnabledKey);
      await _secureStorage.delete(key: _biometricTypeKey);
      return const Right(null);
    } catch (e) {
      return Left(Failure.unknown('Failed to disable biometric: ${e.toString()}'));
    }
  }

  /// Check if biometric authentication is enabled
  Future<Either<Failure, bool>> isBiometricEnabled() async {
    try {
      final String? enabled = await _secureStorage.read(key: _biometricEnabledKey);
      return Right(enabled == 'true');
    } catch (e) {
      return Left(Failure.unknown('Failed to check biometric status: ${e.toString()}'));
    }
  }

  /// Get friendly name for biometric type
  Future<Either<Failure, String>> getBiometricTypeName() async {
    try {
      final biometricsResult = await getAvailableBiometrics();
      
      return biometricsResult.fold(
        (failure) => Left(failure),
        (biometrics) {
          if (biometrics.isEmpty) {
            return const Right('None');
          }

          if (biometrics.contains(BiometricType.face)) {
            return const Right('Face ID');
          } else if (biometrics.contains(BiometricType.fingerprint)) {
            return const Right('Fingerprint');
          } else if (biometrics.contains(BiometricType.iris)) {
            return const Right('Iris');
          } else if (biometrics.contains(BiometricType.strong)) {
            return const Right('Strong Biometric');
          } else if (biometrics.contains(BiometricType.weak)) {
            return const Right('PIN/Pattern');
          } else {
            return const Right('Biometric');
          }
        },
      );
    } catch (e) {
      return Left(Failure.unknown('Failed to get biometric type: ${e.toString()}'));
    }
  }

  /// Authenticate user for sensitive operations (payments, settings changes)
  Future<Either<Failure, bool>> authenticateForTransaction({
    required String transactionDescription,
  }) async {
    // Check if biometric is enabled
    final enabledResult = await isBiometricEnabled();
    final isEnabled = enabledResult.fold(
      (failure) => false,
      (enabled) => enabled,
    );

    if (!isEnabled) {
      // If biometric not enabled, just return success
      // (Caller should handle alternative authentication)
      return const Right(true);
    }

    // Perform biometric authentication
    return await authenticate(
      reason: transactionDescription,
      sensitiveTransaction: true,
      stickyAuth: true,
    );
  }

  /// Quick biometric check for app unlock
  Future<Either<Failure, bool>> quickAuthenticateForUnlock() async {
    // Check if biometric is enabled
    final enabledResult = await isBiometricEnabled();
    final isEnabled = enabledResult.fold(
      (failure) => false,
      (enabled) => enabled,
    );

    if (!isEnabled) {
      return const Right(true);
    }

    return await authenticate(
      reason: 'Unlock FuelAnchor',
      useErrorDialogs: false,
      stickyAuth: false,
    );
  }

  /// Stop biometric authentication (cancel ongoing prompt)
  Future<Either<Failure, void>> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
      return const Right(null);
    } catch (e) {
      return Left(Failure.unknown('Failed to stop authentication: ${e.toString()}'));
    }
  }
}
