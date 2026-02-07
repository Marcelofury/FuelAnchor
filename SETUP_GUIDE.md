# FuelAnchor Setup Guide

## Quick Start Guide

This guide will help you set up and run the FuelAnchor Flutter app and deploy the Soroban smart contract.

## Part 1: Flutter App Setup

### Step 1: Install Flutter

If you haven't installed Flutter yet:

1. Download Flutter SDK from [flutter.dev](https://flutter.dev/docs/get-started/install)
2. Extract and add to PATH
3. Run `flutter doctor` to verify installation

### Step 2: Install Dependencies

```bash
cd frontend_flutter
flutter pub get
```

### Step 3: Generate Code

The app uses code generation for Riverpod, Freezed, and JSON serialization:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Note**: This will generate all `.g.dart` and `.freezed.dart` files needed by the app.

### Step 4: Configure Android/iOS

#### For Android:
- Ensure Android Studio is installed
- Accept Android licenses: `flutter doctor --android-licenses`
- Connect a device or start an emulator

#### For iOS (Mac only):
- Install Xcode from App Store
- Install CocoaPods: `sudo gem install cocoapods`
- Run: `cd ios && pod install`

### Step 5: Run the App

```bash
flutter run
```

Select your target device when prompted.

## Part 2: Soroban Smart Contract Setup

### Prerequisites

1. **Install Rust:**
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
   ```

2. **Install Soroban CLI:**
   ```bash
   cargo install --locked soroban-cli
   ```

3. **Add WASM target:**
   ```bash
   rustup target add wasm32-unknown-unknown
   ```

### Build the Smart Contract

```bash
cd contracts/fuel-lock
soroban contract build
```

This creates a `.wasm` file in `target/wasm32-unknown-unknown/release/`

### Deploy to Testnet

1. **Configure Soroban for testnet:**
   ```bash
   soroban network add testnet \
     --rpc-url https://soroban-testnet.stellar.org:443 \
     --network-passphrase "Test SDF Network ; September 2015"
   ```

2. **Generate a keypair:**
   ```bash
   soroban keys generate admin --network testnet
   ```

3. **Fund the account:**
   ```bash
   soroban keys address admin
   # Copy the address and fund it at: https://laboratory.stellar.org/#account-creator?network=test
   ```

4. **Deploy the contract:**
   ```bash
   soroban contract deploy \
     --wasm target/wasm32-unknown-unknown/release/fuel_lock.wasm \
     --source admin \
     --network testnet
   ```

   **Save the contract ID** - you'll need it for the Flutter app!

5. **Initialize the contract:**
   ```bash
   soroban contract invoke \
     --id <CONTRACT_ID> \
     --source admin \
     --network testnet \
     -- initialize \
     --admin <ADMIN_ADDRESS>
   ```

### Testing the Contract

Run unit tests:
```bash
cd contracts/fuel-lock
cargo test
```

## Part 3: Connect Flutter App to Smart Contract

### Update Configuration

Edit `frontend_flutter/lib/features/blockchain/data/services/stellar_service.dart`:

```dart
// Replace these with your actual values:
static const String _fuelAssetIssuer = 'YOUR_FUEL_ASSET_ISSUER_ADDRESS';
static const String _sorobanContractId = 'YOUR_DEPLOYED_CONTRACT_ID';
```

### Create FUEL Asset (Optional)

If you want to create your own FUEL token:

1. Generate issuer account:
   ```bash
   soroban keys generate fuel-issuer --network testnet
   ```

2. Fund the issuer account via Friendbot

3. Issue the FUEL asset using Stellar Laboratory or SDK

### Test the Integration

1. Run the Flutter app
2. Select a role (Rider/Fleet/Merchant)
3. The app will automatically:
   - Generate a Stellar keypair
   - Store it securely
   - Fund the account on testnet
4. Test payments between roles

## Part 4: Development Workflow

### Hot Reload

Flutter supports hot reload for rapid development:
- Press `r` in the terminal to hot reload
- Press `R` for hot restart
- Press `q` to quit

### Code Generation (Watch Mode)

For automatic code generation during development:

```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

This watches for changes and regenerates code automatically.

### Debugging

#### VS Code
1. Install Flutter extension
2. Press F5 to start debugging
3. Set breakpoints in code

#### Android Studio
1. Open the project
2. Click the debug icon
3. Use the debugger panel

## Part 5: Production Deployment

### Flutter App

#### Android (APK)
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

#### Android (App Bundle for Play Store)
```bash
flutter build appbundle --release
```

#### iOS (App Store)
```bash
flutter build ios --release
```
Then use Xcode to archive and upload to App Store Connect.

### Smart Contract (Mainnet)

1. **Configure mainnet:**
   ```bash
   soroban network add mainnet \
     --rpc-url https://soroban-mainnet.stellar.org:443 \
     --network-passphrase "Public Global Stellar Network ; September 2015"
   ```

2. **Deploy to mainnet:**
   ```bash
   soroban contract deploy \
     --wasm target/wasm32-unknown-unknown/release/fuel_lock.wasm \
     --source admin \
     --network mainnet
   ```

3. **Update Flutter app configuration** to use mainnet:
   ```dart
   StellarService(
     secureStorage: secureStorage,
     useTestnet: false, // Switch to mainnet
   )
   ```

## Troubleshooting

### Common Issues

**1. Code generation fails:**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

**2. Stellar SDK errors:**
- Ensure you're using testnet for development
- Check that accounts are funded
- Verify contract ID is correct

**3. QR Scanner not working:**
- Grant camera permissions
- Check AndroidManifest.xml / Info.plist for permissions

**4. Soroban build fails:**
```bash
# Update dependencies
cargo update
# Rebuild
cargo clean
soroban contract build
```

### Get Help

- Flutter: https://docs.flutter.dev/
- Stellar/Soroban: https://soroban.stellar.org/docs
- Riverpod: https://riverpod.dev/

## Next Steps

1. ✅ Run the app and test all three user roles
2. ✅ Deploy smart contract to testnet
3. ✅ Test payment flows end-to-end
4. ✅ Customize UI colors and branding
5. ✅ Add additional features as needed
6. ✅ Prepare for production deployment

---

**Happy coding! 🚀**
