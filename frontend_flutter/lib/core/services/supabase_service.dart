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

  /// Check if a username exists in database
  static Future<bool> usernameExists(String username) async {
    final response = await client
        .from('profiles')
        .select('id')
        .eq('username', username)
        .maybeSingle();
    
    return response != null;
  }

  /// Check if a phone number exists in database
  static Future<bool> phoneExists(String phoneNumber) async {
    final response = await client
        .from('profiles')
        .select('id')
        .eq('phone_number', phoneNumber)
        .maybeSingle();
    
    return response != null;
  }

  /// Simple hash function for password (basic security)
  static String hashPassword(String password) {
    // For production, use a proper bcrypt/argon2 implementation
    // This is a simple hash for demonstration
    return password.hashCode.toString();
  }

  /// Create user with username/password in database
  static Future<String> createUser({
    required String username,
    required String password,
    required String fullName,
    required String phoneNumber,
    required String role,
    required String stellarPublicKey,
  }) async {
    // Check if username already exists
    final existing = await client
        .from('profiles')
        .select('id')
        .eq('username', username)
        .maybeSingle();
    
    if (existing != null) {
      throw Exception('Username already exists');
    }

    // Check if phone already exists
    final existingPhone = await client
        .from('profiles')
        .select('id')
        .eq('phone_number', phoneNumber)
        .maybeSingle();
    
    if (existingPhone != null) {
      throw Exception('Phone number already registered');
    }

    // Hash password
    final hashedPassword = hashPassword(password);

    // Insert user into profiles table
    final response = await client
        .from('profiles')
        .insert({
          'username': username,
          'password_hash': hashedPassword,
          'full_name': fullName,
          'phone_number': phoneNumber,
          'role': role,
          'stellar_public_key': stellarPublicKey,
        })
        .select()
        .single();

    return response['id'] as String;
  }

  /// Authenticate user with username/password
  static Future<Map<String, dynamic>?> authenticateUser({
    required String username,
    required String password,
  }) async {
    final hashedPassword = hashPassword(password);

    final response = await client
        .from('profiles')
        .select()
        .eq('username', username)
        .eq('password_hash', hashedPassword)
        .maybeSingle();

    return response;
  }

  /// Sign out (just clear local storage)
  static Future<void> signOut() async {
    // No Supabase auth session to clear
    // Local storage clearing handled by app
  }

  /// Update user profile
  static Future<void> updateProfile({
    required String userId,
    Map<String, dynamic>? updates,
  }) async {
    if (updates == null || updates.isEmpty) return;
    
    await client
        .from('profiles')
        .update(updates)
        .eq('id', userId);
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
      case 'fleet_manager':
        await client.from('fleet_manager_profiles').insert(data);
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

  /// Get user profile by phone number
  static Future<Map<String, dynamic>?> getProfileByPhone(
    String phoneNumber,
  ) async {
    final response = await client
        .from('profiles')
        .select()
        .eq('phone_number', phoneNumber)
        .maybeSingle();
    
    return response;
  }

  /// Convert username/phone to email format for Supabase auth
  static String usernameToEmail(String username) {
    // If already an email, return as is
    if (username.contains('@')) return username;
    // Otherwise, convert username to email format
    return '$username@fuelanchor.app';
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
