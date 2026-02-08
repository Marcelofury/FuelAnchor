import 'package:flutter/foundation.dart';

/// Supabase configuration
/// 
/// To use this app:
/// 1. Create a Supabase project at https://supabase.com
/// 2. Copy your project URL and anon key
/// 3. Replace the values below OR use environment variables
class SupabaseConfig {
  // TODO: Replace with your Supabase project credentials
  // You can get these from: https://app.supabase.com/project/_/settings/api
  
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://fyujsibwnltaofzbacoa.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ5dWpzaWJ3bmx0YW9memJhY29hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA0MjY3MTMsImV4cCI6MjA4NjAwMjcxM30.B9kbol3l5uliCHkT5tSOxFyrudAkeMSW1Wk1ghe-U3g',
  );

  /// Check if Supabase is properly configured
  static bool get isConfigured {
    return supabaseUrl != 'YOUR_SUPABASE_URL_HERE' &&
           supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY_HERE' &&
           supabaseUrl.isNotEmpty &&
           supabaseAnonKey.isNotEmpty;
  }

  /// Validate configuration and show warning in debug mode
  static void validateConfig() {
    if (!isConfigured && kDebugMode) {
      print('⚠️  WARNING: Supabase not configured!');
      print('📝 Please update lib/core/config/supabase_config.dart with your Supabase credentials');
      print('🔗 Get your credentials from: https://app.supabase.com/project/_/settings/api');
    }
  }
}
