enum UserRole {
  rider,
  fleetDriver,
  fleetManager,
  merchant;

  String get displayName {
    switch (this) {
      case UserRole.rider:
        return 'Rider';
      case UserRole.fleetDriver:
        return 'Fleet Driver';
      case UserRole.fleetManager:
        return 'Fleet Manager';
      case UserRole.merchant:
        return 'Merchant';
    }
  }

  /// Convert enum to database format (snake_case)
  String get dbName {
    switch (this) {
      case UserRole.rider:
        return 'rider';
      case UserRole.fleetDriver:
        return 'fleet_driver';
      case UserRole.fleetManager:
        return 'fleet_manager';
      case UserRole.merchant:
        return 'merchant';
    }
  }

  /// Parse from database format (snake_case)
  static UserRole fromDbName(String dbName) {
    switch (dbName) {
      case 'rider':
        return UserRole.rider;
      case 'fleet_driver':
      case 'fleetDriver':
        return UserRole.fleetDriver;
      case 'fleet_manager':
      case 'fleetManager':
        return UserRole.fleetManager;
      case 'merchant':
        return UserRole.merchant;
      default:
        return UserRole.rider;
    }
  }
}
