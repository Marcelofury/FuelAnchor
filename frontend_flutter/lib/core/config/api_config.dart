/// FuelAnchor API Configuration
/// Centralizes backend API endpoints and base URLs

class ApiConfig {
  // Backend Base URLs
  static const String productionBaseUrl = 'https://fuelanchor.onrender.com';
  static const String developmentBaseUrl = 'http://localhost:3000';
  
  // Get base URL based on environment
  static String get baseUrl {
    const environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'production');
    return environment == 'development' ? developmentBaseUrl : productionBaseUrl;
  }

  // API Version
  static const String apiVersion = 'v1';
  static String get apiBase => '$baseUrl/api/$apiVersion';

  // ─── Authentication Endpoints ────────────────────────────────────────────
  static String get authRegister => '$apiBase/auth/register';
  static String get authLogin => '$apiBase/auth/login';
  static String get authRefresh => '$apiBase/auth/refresh';
  static String get authLogout => '$apiBase/auth/logout';
  static String get authProfile => '$apiBase/auth/profile';

  // ─── Stations Endpoints ──────────────────────────────────────────────────
  static String get stations => '$apiBase/stations';
  static String stationById(String id) => '$apiBase/stations/$id';
  static String get nearbyStations => '$apiBase/stations/nearby';

  // ─── Transactions Endpoints ──────────────────────────────────────────────
  static String get transactions => '$apiBase/transactions';
  static String transactionById(String id) => '$apiBase/transactions/$id';
  static String get settleTransaction => '$apiBase/transactions/settle';

  // ─── Fleet Management Endpoints ──────────────────────────────────────────
  static String get fleets => '$apiBase/fleet';
  static String fleetById(String id) => '$apiBase/fleet/$id';
  static String get drivers => '$apiBase/drivers';
  static String driverById(String id) => '$apiBase/drivers/$id';

  // ─── Credit Scoring Endpoints ────────────────────────────────────────────
  static String get creditScore => '$apiBase/credit/score';
  static String get creditHistory => '$apiBase/credit/history';

  // ─── Relworx Payment Endpoints ───────────────────────────────────────────
  static String get relworxValidatePhone => '$apiBase/relworx/validate-phone';
  static String get relworxCollect => '$apiBase/relworx/collect';
  static String get relworxDisburse => '$apiBase/relworx/disburse';
  static String get relworxStatus => '$apiBase/relworx/status';
  static String get relworxCallback => '$apiBase/relworx/callback';
  static String get relworxBalance => '$apiBase/relworx/balance';
  static String get relworxHistory => '$apiBase/relworx/history';

  // ─── SEP-31 Cross-Border Endpoints ───────────────────────────────────────
  static String get sep31Quote => '$apiBase/sep31/quote';
  static String get sep31Transaction => '$apiBase/sep31/transaction';
  static String sep31TransactionStatus(String id) => '$apiBase/sep31/transaction/$id';

  // ─── Analytics Endpoints ─────────────────────────────────────────────────
  static String get analyticsOverview => '$apiBase/analytics/overview';
  static String get analyticsTransactions => '$apiBase/analytics/transactions';
  static String get analyticsFleet => '$apiBase/analytics/fleet';

  // ─── Stellar Endpoints ───────────────────────────────────────────────────
  static String get stellarFund => '$apiBase/stellar/fund-testnet';
  static String get stellarBalance => '$apiBase/stellar/balance';

  // Request timeout
  static const Duration requestTimeout = Duration(seconds: 30);

  // Headers factory
  static Map<String, String> headers({String? authToken}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    
    return headers;
  }

  // Logging
  static bool get enableApiLogging {
    const environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'production');
    return environment == 'development';
  }

  // Print configuration on init
  static void printConfig() {
    print('🌐 FuelAnchor API Configuration');
    print('📍 Base URL: $baseUrl');
    print('🔗 API Base: $apiBase');
    print('📊 Logging: ${enableApiLogging ? 'Enabled' : 'Disabled'}');
  }
}
