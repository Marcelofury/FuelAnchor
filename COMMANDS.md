# Quick Command Reference

## Flutter Commands

### Initial Setup
```bash
cd frontend_flutter
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Development
```bash
# Run app
flutter run

# Hot reload: Press 'r' in terminal
# Hot restart: Press 'R' in terminal
# Quit: Press 'q'

# Run with specific device
flutter run -d <device-id>

# List devices
flutter devices

# Watch mode for code generation
flutter pub run build_runner watch --delete-conflicting-outputs
```

### Testing & Analysis
```bash
# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
flutter format .

# Check for outdated packages
flutter pub outdated
```

### Building
```bash
# Android APK
flutter build apk --release

# Android App Bundle (Play Store)
flutter build appbundle --release

# iOS (Mac only)
flutter build ios --release
```

### Clean & Reset
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

## Soroban Contract Commands

### Build
```bash
cd contracts/fuel-lock
soroban contract build
```

### Test
```bash
cargo test
cargo test -- --nocapture  # With output
```

### Deploy (Testnet)
```bash
# Configure network
soroban network add testnet \
  --rpc-url https://soroban-testnet.stellar.org:443 \
  --network-passphrase "Test SDF Network ; September 2015"

# Generate keypair
soroban keys generate admin --network testnet

# Get address
soroban keys address admin

# Deploy
soroban contract deploy \
  --wasm target/wasm32-unknown-unknown/release/fuel_lock.wasm \
  --source admin \
  --network testnet

# Initialize (use returned contract ID)
soroban contract invoke \
  --id <CONTRACT_ID> \
  --source admin \
  --network testnet \
  -- initialize \
  --admin $(soroban keys address admin)
```

### Contract Interactions
```bash
# Set driver quota
soroban contract invoke \
  --id <CONTRACT_ID> \
  --source admin \
  --network testnet \
  -- set_driver_quota \
  --admin <ADMIN_ADDR> \
  --driver <DRIVER_ADDR> \
  --quota 100000000

# Check quota
soroban contract invoke \
  --id <CONTRACT_ID> \
  --network testnet \
  -- get_driver_quota \
  --driver <DRIVER_ADDR>

# Make payment
soroban contract invoke \
  --id <CONTRACT_ID> \
  --source driver \
  --network testnet \
  -- pay_merchant \
  --driver <DRIVER_ADDR> \
  --merchant <MERCHANT_ADDR> \
  --amount 5000000 \
  --driver_gps '(40748817, -73985428)'
```

## Useful Flutter Debugging

```bash
# Show widget inspector
flutter run --observatory-port 9999

# Profile mode (performance testing)
flutter run --profile

# Check dependencies
flutter pub deps

# Clean build cache
flutter clean
rm -rf build/
rm -rf .dart_tool/
```

## Git Workflow

```bash
# Commit generated files are in .gitignore
git status
git add .
git commit -m "feat: add flutter app and soroban contract"
git push
```

## VS Code Shortcuts

- `Ctrl+Shift+P` → "Flutter: Run Flutter Doctor"
- `F5` → Debug mode
- `Ctrl+F5` → Run without debugging
- `Ctrl+.` → Quick fix / refactor

## Common Issues & Fixes

### Issue: Code generation fails
```bash
flutter clean
rm -rf .dart_tool/
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Issue: Android build fails
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Issue: iOS build fails (Mac)
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter run
```

### Issue: Stellar SDK errors
- Check you're on testnet
- Verify account is funded
- Confirm contract ID is correct

---

**Tip**: Keep this file handy during development!
