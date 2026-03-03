# FuelAnchor

Blockchain-based fuel voucher system for East Africa, built with Flutter and Stellar/Soroban.

## Overview

FuelAnchor provides secure, transparent fuel distribution for fleet operators, riders, and merchants using Stellar blockchain and Soroban smart contracts.

**Key Features:**
- GPS-verified fuel payments
- On-chain credit scoring
- Mobile money integration (M-Pesa, MTN MoMo)
- Real-time transaction settlement
- QR code payments

## Technology Stack

- **Mobile**: Flutter 3.0+ (iOS/Android)
- **Blockchain**: Stellar + Soroban (Rust)
- **State**: Riverpod with code generation
- **Backend**: Node.js/TypeScript
- **Storage**: Flutter Secure Storage

## Quick Start

### Flutter App
```bash
cd frontend_flutter
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

### Smart Contracts
```bash
cd contracts/fuel-lock
soroban contract build
cargo test
```

### Backend
```bash
cd backend
npm install
npm run dev
```

## Core Features

**Riders**: Scan QR codes, view balance, GPS-verified payments  
**Fleet Drivers**: Track quotas, monitor fuel usage, update odometer  
**Merchants**: Generate QR codes, view earnings, real-time settlement

## Smart Contracts

- **fuel-lock**: Payment processing and quotas
- **credit-score**: On-chain credit history
- **fuel-token**: SEP-41 compliant FUEL token
- **geofencing**: GPS validation

## Problem & Solution

**Problem**: Fleet operators lose 15-25% to fuel fraud. 1.5M+ Boda Boda riders lack credit access.

**Solution**: Tokenized fuel vouchers with geofenced redemption, creating verifiable transaction history for credit building.
## Documentation

- [SETUP_GUIDE.md](SETUP_GUIDE.md) - Installation & deployment
- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture
- [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) - Detailed overview
- [SUPABASE_SETUP.md](SUPABASE_SETUP.md) - Database setup

<<<<<<< HEAD
## License

MIT License - See [LICENSE](LICENSE)

---

**Built for East Africa**  Powered by Stellar 

