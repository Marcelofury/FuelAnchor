# FuelAnchor - Digital Energy Layer for Tokenized Fuel Vouchers

<div align="center">
  <img src="docs/logo.png" alt="FuelAnchor Logo" width="200" />
  
  **Tokenized Fuel Vouchers for East African Logistics**
  
  [![Stellar](https://img.shields.io/badge/Stellar-Soroban-7C3AED?style=flat&logo=stellar)](https://stellar.org)
  [![React Native](https://img.shields.io/badge/React%20Native-Expo-61DAFB?style=flat&logo=react)](https://expo.dev)
  [![TypeScript](https://img.shields.io/badge/TypeScript-5.0-3178C6?style=flat&logo=typescript)](https://typescriptlang.org)
  [![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
</div>

---

## 🌍 Problem Statement

East African logistics faces critical challenges:

- **Fuel Fraud**: 15-25% of fleet fuel budgets lost to siphoning and receipts forgery
- **Financial Exclusion**: 1.5M+ Boda Boda riders in Kenya alone lack access to credit
- **Cash Dependency**: 70% of transactions in the informal transport sector are cash-based
- **Credit Invisibility**: No on-chain credit history for micro-fleet operators

## 💡 Solution

FuelAnchor creates a **Digital Energy Layer** using Stellar blockchain to:

1. **Tokenize Fuel Vouchers**: SEP-41 compliant FUEL tokens represent prepaid fuel credits
2. **Geofenced Redemption**: Smart contracts validate location + spending limits at stations
3. **Build Credit Scores**: On-chain transaction history enables micro-lending
4. **Mobile Money Integration**: Seamless on/off ramp via M-Pesa, MTN MoMo, Airtel Money

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    FUELANCHOR ECOSYSTEM                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────┐    ┌──────────────┐    ┌─────────────────┐ │
│  │   Fleet     │    │    Driver    │    │   Station       │ │
│  │  Managers   │    │   (Rider)    │    │   Operator      │ │
│  └──────┬──────┘    └──────┬───────┘    └────────┬────────┘ │
│         │                  │                      │          │
│         ▼                  ▼                      ▼          │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │              MOBILE APP (React Native/Expo)              │ │
│  │   • NFC Card Tap  • QR Scan  • USSD Fallback            │ │
│  └─────────────────────────────────────────────────────────┘ │
│                            │                                 │
│                            ▼                                 │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │               ANCHOR SERVER (Node.js/Express)            │ │
│  │   • SEP-24 (Mobile Money)  • SEP-31 (Cross-border)      │ │
│  │   • Fleet API  • Credit Scoring  • Webhooks             │ │
│  └─────────────────────────────────────────────────────────┘ │
│                            │                                 │
│                            ▼                                 │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │             STELLAR / SOROBAN BLOCKCHAIN                 │ │
│  │                                                          │ │
│  │   ┌─────────────┐  ┌───────────────┐  ┌──────────────┐  │ │
│  │   │ FUEL Token  │  │   Voucher     │  │   Credit     │  │ │
│  │   │  (SEP-41)   │  │  Redemption   │  │   Score      │  │ │
│  │   └─────────────┘  └───────────────┘  └──────────────┘  │ │
│  │                                                          │ │
│  │   ┌─────────────┐                                       │ │
│  │   │ Geofencing  │                                       │ │
│  │   │  Corridors  │                                       │ │
│  │   └─────────────┘                                       │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 📁 Project Structure

```
FuelAnchor/
├── contracts/                    # Soroban Smart Contracts (Rust)
│   ├── fuel-token/               # SEP-41 compliant FUEL token
│   │   ├── src/
│   │   │   ├── lib.rs            # Module exports
│   │   │   ├── contract.rs       # Token implementation
│   │   │   ├── admin.rs          # Admin functions
│   │   │   ├── balance.rs        # Balance management
│   │   │   ├── allowance.rs      # Approval system
│   │   │   ├── metadata.rs       # Token metadata
│   │   │   ├── storage_types.rs  # Data structures
│   │   │   └── test.rs           # Unit tests
│   │   └── Cargo.toml
│   ├── voucher-redemption/       # Geofenced redemption logic
│   ├── credit-score/             # On-chain credit scoring
│   └── geofencing/               # GPS zone validation
│
├── backend/                      # Node.js/Express Server
│   ├── src/
│   │   ├── index.ts              # Server entry point
│   │   ├── config/
│   │   │   └── environment.ts    # Environment configuration
│   │   ├── api/
│   │   │   ├── auth.ts           # Authentication routes
│   │   │   ├── fleet.ts          # Fleet management
│   │   │   ├── driver.ts         # Driver endpoints
│   │   │   ├── station.ts        # Station operations
│   │   │   ├── transaction.ts    # Transaction history
│   │   │   ├── credit.ts         # Credit score API
│   │   │   ├── stellar.ts        # Blockchain interactions
│   │   │   └── webhooks.ts       # Mobile money callbacks
│   │   ├── middleware/
│   │   │   ├── auth.ts           # JWT authentication
│   │   │   └── errorHandler.ts   # Error handling
│   │   ├── services/
│   │   │   └── stellar.ts        # Stellar SDK integration
│   │   └── utils/
│   │       └── logger.ts         # Winston logging
│   └── package.json
│
├── frontend/                     # React Native Mobile App
│   ├── src/
│   │   ├── navigation/
│   │   │   └── RootNavigator.tsx
│   │   ├── screens/
│   │   │   ├── HomeScreen.tsx
│   │   │   ├── WalletScreen.tsx
│   │   │   ├── StationsScreen.tsx
│   │   │   ├── CreditScreen.tsx
│   │   │   ├── ScanScreen.tsx
│   │   │   ├── TransferScreen.tsx
│   │   │   ├── ProfileScreen.tsx
│   │   │   └── auth/
│   │   │       ├── LoginScreen.tsx
│   │   │       └── RegisterScreen.tsx
│   │   ├── hooks/
│   │   │   ├── useAuth.tsx
│   │   │   └── useTheme.tsx
│   │   └── services/
│   │       └── api.ts
│   ├── App.tsx
│   ├── app.json
│   └── package.json
│
├── docs/                         # Documentation
├── .env.example                  # Environment template
├── Cargo.toml                    # Rust workspace config
└── README.md
```

---

## 🚀 Quick Start

### Prerequisites

- Node.js 18+
- Rust 1.70+ with `wasm32-unknown-unknown` target
- Stellar CLI (for Soroban)
- Expo CLI

### 1. Clone Repository

```bash
git clone https://github.com/Marcelofury/FuelAnchor.git
cd FuelAnchor
```

### 2. Setup Smart Contracts

```bash
# Install Rust dependencies
cargo build

# Build Soroban contracts
cd contracts/fuel-token && cargo build --target wasm32-unknown-unknown --release
cd ../voucher-redemption && cargo build --target wasm32-unknown-unknown --release
cd ../credit-score && cargo build --target wasm32-unknown-unknown --release
cd ../geofencing && cargo build --target wasm32-unknown-unknown --release

# Deploy to Stellar Testnet
stellar contract deploy --wasm target/wasm32-unknown-unknown/release/fuel_token.wasm --network testnet
```

### 3. Setup Backend

```bash
cd backend

# Install dependencies
npm install

# Configure environment
cp ../.env.example .env
# Edit .env with your values

# Run migrations
npx prisma migrate dev

# Start server
npm run dev
```

### 4. Setup Mobile App

```bash
cd frontend

# Install dependencies
npm install

# Start Expo development server
npx expo start

# Scan QR code with Expo Go app (iOS/Android)
```

---

## 🔑 Key Features

### For Fleet Managers
- Bulk purchase FUEL tokens via mobile money
- Distribute fuel budgets to drivers with spending limits
- Real-time transaction monitoring dashboard
- Geofence vehicles to approved corridors

### For Drivers (Boda Boda Riders)
- Tap NFC card or scan QR at stations
- Build on-chain credit history
- Access micro-loans based on fuel purchase patterns
- USSD fallback for feature phones

### For Station Operators
- Accept digital fuel payments instantly
- Automatic reconciliation with anchor
- Fraud prevention with geofencing
- Lower transaction fees vs. cash

---

## 📱 Supported Platforms

| Platform | Support |
|----------|---------|
| iOS | ✅ Native via Expo |
| Android | ✅ Native via Expo |
| Feature Phones | ✅ USSD (*384*FUEL#) |
| NFC Cards | ✅ Contactless payments |
| Web Dashboard | 🚧 Coming Soon |

---

## 🌐 Target Markets

| Country | Mobile Money | Currency |
|---------|-------------|----------|
| 🇰🇪 Kenya | M-Pesa | KES |
| 🇺🇬 Uganda | MTN MoMo, Airtel | UGX |
| 🇹🇿 Tanzania | M-Pesa, Tigo Pesa | TZS |
| 🇷🇼 Rwanda | MTN MoMo | RWF |
| 🇧🇮 Burundi | Lumicash | BIF |
| 🇸🇸 South Sudan | M-Pesa | SSP |

---

## 📊 Credit Scoring Model

FuelAnchor builds on-chain credit profiles using 5 factors:

| Factor | Weight | Description |
|--------|--------|-------------|
| Account Age | 20% | Time since first transaction |
| Frequency | 25% | How often fuel is purchased |
| Consistency | 25% | Regular patterns vs. irregular |
| Volume | 15% | Total fuel purchased |
| Diversity | 15% | Number of different stations used |

**Score Tiers:**
- 🥉 Bronze: 300-499 (Basic discounts)
- 🥈 Silver: 500-649 (Emergency fuel credit)
- 🥇 Gold: 650-749 (Micro-loans up to $100)
- 💎 Platinum: 750-850 (Full credit products)

---

## 🛡️ Security Features

- **Multi-sig Admin**: Critical contract operations require multiple signatures
- **Spending Limits**: Daily, weekly, and per-transaction caps
- **Geofencing**: GPS validation prevents out-of-zone redemption
- **Clawback**: Fleet managers can recover tokens from lost NFC cards
- **PIN Protection**: 6-digit PIN for high-value transactions

---

## 🗺️ Roadmap

### Phase 1: MVP (Q1 2025)
- [x] Soroban smart contracts
- [x] Mobile app core features
- [x] M-Pesa integration (Kenya)
- [ ] Testnet pilot with 10 fleets

### Phase 2: Scale (Q2 2025)
- [ ] MTN/Airtel integration
- [ ] Credit scoring launch
- [ ] 100+ station onboarding
- [ ] USSD implementation

### Phase 3: Expand (Q3-Q4 2025)
- [ ] Cross-border payments (SEP-31)
- [ ] Insurance products
- [ ] Uganda & Tanzania launch
- [ ] B2B fuel trading platform

---

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](docs/CONTRIBUTING.md) for guidelines.

```bash
# Create feature branch
git checkout -b feature/amazing-feature

# Commit changes
git commit -m 'Add amazing feature'

# Push to branch
git push origin feature/amazing-feature

# Open Pull Request
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 📧 Contact

- **Website**: [fuelanchor.io](https://fuelanchor.io)
- **Email**: hello@fuelanchor.io
- **Twitter**: [@FuelAnchor](https://twitter.com/FuelAnchor)
- **Discord**: [FuelAnchor Community](https://discord.gg/fuelanchor)

---

<div align="center">
  <p>Built with ❤️ for East African logistics</p>
  <p>Powered by <a href="https://stellar.org">Stellar</a></p>
</div>
