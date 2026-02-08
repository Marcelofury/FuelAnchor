import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Supabase service wrapper
class SupabaseService {
  static SupabaseClient? _client;

  /// Initialize Supabase
  static Future<void> initialize() async {
    if (!SupabaseConfig.isConfigured) {
      SupabaseConfig.validateConfig();
      // Continue with local-only mode if not configured
      return;
    }

    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );

    _client = Supabase.instance.client;
  }

  /// Get Supabase client instance
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call SupabaseService.initialize() first.');
    }
    return _client!;
  }

  /// Check if user is authenticated
  static bool get isAuthenticated {
    if (!SupabaseConfig.isConfigured) return false;
    return _client?.auth.currentUser != null;
  }

  /// Get current user
  static User? get currentUser {
    if (!SupabaseConfig.isConfigured) return null;
    return _client?.auth.currentUser;
  }

  /// Sign up new user
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? metadata,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: metadata,
    );
  }

  /// Sign in user
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out
  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Create user profile
  static Future<void> createProfile({
    required String userId,
    required String fullName,
    required String phoneNumber,
    required String role,
    required String stellarPublicKey,
  }) async {
    await client.from('profiles').insert({
      'id': userId,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'role': role,
      'stellar_public_key': stellarPublicKey,
    });
  }

  /// Create role-specific profile
  static Future<void> createRoleProfile({
    required String userId,
    required String role,
    Map<String, dynamic>? additionalData,
  }) async {
    final Map<String, dynamic> data = {
      'id': userId,
      ...?additionalData,
    };

    switch (role) {
      case 'rider':
        await client.from('rider_profiles').insert(data);
        break;
      case 'fleet_driver':
        await client.from('fleet_driver_profiles').insert(data);
        break;
      case 'merchant':
        await client.from('merchant_profiles').insert(data);
        break;
    }
  }

  /// Get user profile
  static Future<Map<String, dynamic>?> getProfile(String userId) async {
    final response = await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    
    return response;
  }

  /// Get user profile by Stellar public key
  static Future<Map<String, dynamic>?> getProfileByStellarKey(
    String stellarPublicKey,
  ) async {
    final response = await client
        .from('profiles')
        .select()
        .eq('stellar_public_key', stellarPublicKey)
        .maybeSingle();
    
    return response;
  }

  /// Record transaction
  static Future<void> recordTransaction({
    required String blockchainHash,
    required String fromUserId,
    required String toUserId,
    required double amount,
    double? fuelVolume,
    double? gpsLat,
    double? gpsLng,
  }) async {
    await client.from('transactions').insert({
      'blockchain_hash': blockchainHash,
      'from_user_id': fromUserId,
      'to_user_id': toUserId,
      'amount': amount,
      'fuel_volume': fuelVolume,
      'gps_lat': gpsLat,
      'gps_lng': gpsLng,
      'status': 'completed',
    });
  }

  /// Get user transactions
  static Future<List<Map<String, dynamic>>> getTransactions(
    String userId,
  ) async {
    final response = await client
        .from('transactions')
        .select()
        .or('from_user_id.eq.$userId,to_user_id.eq.$userId')
        .order('created_at', ascending: false)
        .limit(50);
    
    return List<Map<String, dynamic>>.from(response);
  }
}
