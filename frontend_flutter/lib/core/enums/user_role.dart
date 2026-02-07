enum UserRole {
  rider,
  fleetDriver,
  merchant;

  String get displayName {
    switch (this) {
      case UserRole.rider:
        return 'Rider';
      case UserRole.fleetDriver:
        return 'Fleet Driver';
      case UserRole.merchant:
        return 'Merchant';
    }
  }
}
