import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../blockchain/data/services/stellar_service.dart';
import '../../../core/enums/user_role.dart';
import '../domain/entities/user_profile.dart';

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

/// User Profile Provider - Manages complete user profile data
@riverpod
class UserProfileNotifier extends _$UserProfileNotifier {
  static const String _storageKey = 'user_profile';

  @override
  Future<UserProfile?> build() async {
    return await _loadProfile();
  }

  Future<UserProfile?> _loadProfile() async {
    final storage = ref.read(secureStorageProvider);
    
    try {
      final profileJson = await storage.read(key: _storageKey);
      if (profileJson != null) {
        final profileData = jsonDecode(profileJson) as Map<String, dynamic>;
        return UserProfile.fromJson(profileData);
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
    
    return null;
  }

  Future<void> saveProfile(UserProfile profile) async {
    final storage = ref.read(secureStorageProvider);
    
    try {
      final profileJson = jsonEncode(profile.toJson());
      await storage.write(key: _storageKey, value: profileJson);
      state = AsyncValue.data(profile);
    } catch (e) {
      print('Error saving user profile: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateProfile({
    String? name,
    String? phone,
    String? vehicleId,
    String? fleetName,
    String? stationId,
    String? stationName,
    String? nationalId,
    double? fuelQuota,
    double? lastOdometerReading,
  }) async {
    final currentProfile = state.value;
    if (currentProfile == null) return;

    final updatedProfile = currentProfile.copyWith(
      name: name ?? currentProfile.name,
      phone: phone ?? currentProfile.phone,
      vehicleId: vehicleId ?? currentProfile.vehicleId,
      fleetName: fleetName ?? currentProfile.fleetName,
      stationId: stationId ?? currentProfile.stationId,
      stationName: stationName ?? currentProfile.stationName,
      nationalId: nationalId ?? currentProfile.nationalId,
      fuelQuota: fuelQuota ?? currentProfile.fuelQuota,
      lastOdometerReading: lastOdometerReading ?? currentProfile.lastOdometerReading,
    );

    await saveProfile(updatedProfile);
  }

  Future<void> clearProfile() async {
    final storage = ref.read(secureStorageProvider);
    await storage.delete(key: _storageKey);
    state = const AsyncValue.data(null);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadProfile());
  }
}
