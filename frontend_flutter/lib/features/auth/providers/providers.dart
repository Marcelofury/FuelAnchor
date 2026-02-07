import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../blockchain/data/services/stellar_service.dart';
import '../../../core/enums/user_role.dart';

part 'providers.g.dart';

/// Secure Storage Provider
@riverpod
FlutterSecureStorage secureStorage(SecureStorageRef ref) {
  return const FlutterSecureStorage();
}

/// Stellar Service Provider
@riverpod
StellarService stellarService(StellarServiceRef ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return StellarService(
    secureStorage: secureStorage,
    useTestnet: true, // Set to false for mainnet
  );
}

/// User Role Provider - Tracks the current user's role
@riverpod
class UserRoleNotifier extends _$UserRoleNotifier {
  @override
  UserRole? build() {
    return null; // Initially no role selected
  }

  void setRole(UserRole role) {
    state = role;
  }

  void clearRole() {
    state = null;
  }
}

/// Current User's Public Key Provider
@riverpod
class UserPublicKey extends _$UserPublicKey {
  @override
  Future<String?> build() async {
    final stellarService = ref.watch(stellarServiceProvider);
    final result = await stellarService.getPublicKey();
    
    return result.fold(
      (failure) => null,
      (publicKey) => publicKey,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final stellarService = ref.read(stellarServiceProvider);
      final result = await stellarService.getPublicKey();
      
      return result.fold(
        (failure) => null,
        (publicKey) => publicKey,
      );
    });
  }
}
