import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fuelanchor/core/services/biometric_service.dart';

part 'biometric_providers.g.dart';

/// Provider for BiometricService instance
@riverpod
BiometricService biometricService(BiometricServiceRef ref) {
  return BiometricService();
}

/// Provider to check if biometric is available
@riverpod
Future<bool> isBiometricAvailable(IsBiometricAvailableRef ref) async {
  final biometricService = ref.watch(biometricServiceProvider);
  final result = await biometricService.isBiometricAvailable();
  
  return result.fold(
    (failure) => false,
    (available) => available,
  );
}

/// Provider to check if biometric is enabled
@riverpod
Future<bool> isBiometricEnabled(IsBiometricEnabledRef ref) async {
  final biometricService = ref.watch(biometricServiceProvider);
  final result = await biometricService.isBiometricEnabled();
  
  return result.fold(
    (failure) => false,
    (enabled) => enabled,
  );
}

/// Provider to get biometric type name
@riverpod
Future<String> biometricTypeName(BiometricTypeNameRef ref) async {
  final biometricService = ref.watch(biometricServiceProvider);
  final result = await biometricService.getBiometricTypeName();
  
  return result.fold(
    (failure) => 'None',
    (name) => name,
  );
}

/// State notifier for managing biometric authentication state
@riverpod
class BiometricAuthNotifier extends _$BiometricAuthNotifier {
  @override
  Future<bool> build() async {
    // Initialize with current enabled state
    final biometricService = ref.watch(biometricServiceProvider);
    final result = await biometricService.isBiometricEnabled();
    
    return result.fold(
      (failure) => false,
      (enabled) => enabled,
    );
  }

  /// Enable biometric authentication
  Future<void> enableBiometric() async {
    state = const AsyncValue.loading();
    
    final biometricService = ref.read(biometricServiceProvider);
    final result = await biometricService.enableBiometric();
    
    result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
      },
      (_) {
        state = const AsyncValue.data(true);
        // Invalidate related providers
        ref.invalidate(isBiometricEnabledProvider);
      },
    );
  }

  /// Disable biometric authentication
  Future<void> disableBiometric() async {
    state = const AsyncValue.loading();
    
    final biometricService = ref.read(biometricServiceProvider);
    final result = await biometricService.disableBiometric();
    
    result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
      },
      (_) {
        state = const AsyncValue.data(false);
        // Invalidate related providers
        ref.invalidate(isBiometricEnabledProvider);
      },
    );
  }

  /// Authenticate with biometric
  Future<bool> authenticate(String reason) async {
    final biometricService = ref.read(biometricServiceProvider);
    final result = await biometricService.authenticate(
      reason: reason,
      sensitiveTransaction: true,
    );
    
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (success) => success,
    );
  }

  /// Quick unlock authentication
  Future<bool> quickUnlock() async {
    final biometricService = ref.read(biometricServiceProvider);
    final result = await biometricService.quickAuthenticateForUnlock();
    
    return result.fold(
      (failure) => false,
      (success) => success,
    );
  }

  /// Authenticate for transaction
  Future<bool> authenticateForTransaction(String description) async {
    final biometricService = ref.read(biometricServiceProvider);
    final result = await biometricService.authenticateForTransaction(
      transactionDescription: description,
    );
    
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (success) => success,
    );
  }
}
