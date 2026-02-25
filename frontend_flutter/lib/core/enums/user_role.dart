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
}
