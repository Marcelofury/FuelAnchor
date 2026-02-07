# FuelAnchor Flutter App

A Flutter-based fuel payment application using the Stellar/Soroban blockchain network.

## 🏗️ Architecture

This app follows a **feature-first architecture** with **Clean Architecture** principles:

```
lib/
├── core/                    # Shared utilities and constants
│   ├── constants/          # App-wide constants (colors, strings)
│   ├── enums/              # Common enums
│   ├── error/              # Error handling
│   ├── router/             # App routing configuration
│   └── utils/              # Utility functions
│
├── features/               # Feature modules
│   ├── auth/              # Authentication feature
│   │   ├── domain/        # Entities, use cases
│   │   ├── providers/     # Riverpod providers
│   │   └── presentation/  # UI (screens, widgets)
│   │
│   ├── blockchain/        # Stellar/Soroban integration
│   │   └── data/
│   │       └── services/  # StellarService
│   │
│   ├── dashboard/         # Dashboard screens
│   │   └── presentation/
│   │       └── screens/   # Rider, Fleet, Merchant dashboards
│   │
│   ├── payment/           # Payment processing
│   │   ├── domain/
│   │   └── providers/
│   │
│   └── wallet/            # Wallet management
│       ├── domain/
│       └── providers/
│
└── main.dart              # App entry point
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK (included with Flutter)
- Android Studio / Xcode (for mobile development)
- VS Code with Flutter extension (recommended)

### Installation

1. **Install dependencies:**
   ```bash
   cd frontend_flutter
   flutter pub get
   ```

2. **Generate code (Riverpod, Freezed, etc.):**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

## 🔑 Key Features

### State Management - Riverpod

The app uses **Riverpod** for state management with code generation:

- **UserRoleProvider**: Manages current user role (Rider/Fleet Driver/Merchant)
- **WalletBalanceNotifier**: Tracks FUEL token balance
- **PaymentNotifier**: Handles payment transactions
- **UserPublicKey**: Manages user's Stellar public key

### Stellar/Soroban Integration

The `StellarService` class handles all blockchain operations:

- ✅ Generate and securely store Stellar keypairs
- ✅ Check FUEL asset balances
- ✅ Call Soroban smart contract functions
- ✅ Execute payments with GPS verification

### User Roles

#### 🏍️ Rider
- Scan merchant QR codes
- Pay for fuel using FUEL tokens
- View wallet balance
- Transaction history

#### 🚚 Fleet Driver
- View allocated fuel quota
- Update odometer readings
- Monitor fuel usage
- Quota management

#### 🏪 Merchant (Station)
- Display dynamic QR code for payments
- View earnings
- Transaction history
- Payment notifications

## 🎨 Design System

### Color Palette

- **Navy**: `#0A192F` - Primary background
- **Electric Green**: `#00FF41` - Accent/CTA color
- **Dark Navy**: `#020C1B` - Cards/surfaces
- **Slate**: `#8892B0` - Secondary text

### Theme

The app uses a dark theme with Material 3 design system and Google Fonts (Inter).

## 🔐 Security

- **Secure Storage**: Uses `flutter_secure_storage` for keypair storage
- **GPS Verification**: Payments include driver GPS coordinates
- **Authentication**: All transactions require address authentication
- **Testnet**: Currently configured for Stellar testnet

## 📱 Screens

### Login Screen
- Role selection (Rider, Fleet Driver, Merchant)
- Automatic keypair generation
- Testnet account funding

### Rider Dashboard
- Wallet balance card
- Large "Scan to Pay" button
- QR code scanner
- Payment confirmation dialog
- Transaction list

### Fleet Dashboard
- Fuel quota display with progress bar
- Wallet balance
- Odometer input field
- Trip history

### Merchant Dashboard
- Total earnings display
- Dynamic QR code generator
- Today's transactions
- Transaction details

## 🔧 Configuration

### Update Stellar Network

In `stellar_service.dart`:

```dart
StellarService(
  secureStorage: secureStorage,
  useTestnet: false, // Change to false for mainnet
)
```

### Set Asset Issuer & Contract ID

Update these constants in `stellar_service.dart`:

```dart
static const String _fuelAssetIssuer = 'YOUR_ASSET_ISSUER_ADDRESS';
static const String _sorobanContractId = 'YOUR_CONTRACT_ID';
```

## 🧪 Testing

Run tests:
```bash
flutter test
```

## 📦 Building

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## 🛠️ Code Generation

When you modify files with annotations (@freezed, @riverpod), run:

```bash
flutter pub run build_runner watch
```

This will automatically regenerate `.g.dart` and `.freezed.dart` files.

## 📝 Important Notes

1. **ref.mounted**: All async operations check `if (!mounted) return` to prevent memory leaks
2. **Error Handling**: Uses Either<Failure, T> pattern from `dartz` package
3. **Logging**: Centralized logging through `AppLogger` utility
4. **Navigation**: Uses `go_router` with Riverpod integration

## 🌐 Smart Contract Integration

The app interacts with the `FuelLock` Soroban smart contract for:

- Payment processing
- Quota management
- Odometer tracking
- Transaction verification

See `contracts/fuel-lock/` for smart contract code.

## 🚧 Future Enhancements

- [ ] Transaction history with filtering
- [ ] Push notifications for payments
- [ ] Offline payment queuing
- [ ] Multi-language support
- [ ] Biometric authentication
- [ ] Analytics dashboard
- [ ] Receipt generation

## 📄 License

See LICENSE file in the root directory.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and linters
5. Submit a pull request

---

**Built with ❤️ using Flutter & Stellar/Soroban**
