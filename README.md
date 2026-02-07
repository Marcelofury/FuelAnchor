# FuelAnchor

A blockchain-based digital fuel voucher system for East Africa, built with Flutter and Stellar/Soroban.

## Overview

FuelAnchor is a comprehensive fuel payment and management platform that leverages the Stellar blockchain and Soroban smart contracts to provide secure, transparent, and efficient fuel distribution for fleet operators, individual riders, and fuel merchants across East Africa.

## Technology Stack

- **Mobile App**: Flutter 3.0+ (Cross-platform iOS/Android)
- **Blockchain**: Stellar Network with Soroban Smart Contracts (Rust)
- **State Management**: Riverpod with code generation
- **Backend**: Node.js/TypeScript (API services)
- **Storage**: Flutter Secure Storage for keypair management

## Project Structure

```
FuelAnchor/
├── frontend_flutter/       # Flutter mobile application
├── contracts/             # Soroban smart contracts (Rust)
│   ├── fuel-lock/        # Main fuel payment contract
│   ├── credit-score/     # Credit scoring contract
│   ├── fuel-token/       # FUEL token contract (SEP-41)
│   ├── geofencing/       # GPS validation contract
│   └── voucher-redemption/ # Voucher redemption logic
├── backend/              # Node.js backend services
└── docs/                 # Documentation
```

## Quick Start

### Prerequisites

- Flutter SDK 3.0 or higher
- Rust and Soroban CLI (for smart contracts)
- Node.js 18+ (for backend services)

### Flutter App Setup

```bash
cd frontend_flutter
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

### Smart Contract Setup

```bash
cd contracts/fuel-lock
soroban contract build
soroban contract deploy --wasm target/wasm32-unknown-unknown/release/fuel_lock.wasm --network testnet
```

For detailed setup instructions, see [SETUP_GUIDE.md](SETUP_GUIDE.md).

## Features

### For Riders
- Scan QR codes to pay for fuel
- View wallet balance and transaction history
- GPS-verified payments
- Secure Stellar keypair management

### For Fleet Drivers
- Track fuel quota allocation
- Update odometer readings
- Monitor fuel usage and efficiency
- Real-time quota balance

### For Merchants (Fuel Stations)
- Generate payment QR codes
- View earnings and transactions
- Accept FUEL token payments
- Real-time settlement

## Architecture

The application follows a feature-first clean architecture pattern with clear separation of concerns:

- **Presentation Layer**: Flutter UI components and screens
- **Domain Layer**: Business logic and entities
- **Data Layer**: Stellar/Soroban integration and repositories

For detailed architecture documentation, see [ARCHITECTURE.md](ARCHITECTURE.md).

## Smart Contracts

FuelAnchor deploys multiple Soroban smart contracts:

1. **FuelLock Contract**: Manages fuel quotas and payment processing
2. **Credit Score Contract**: Builds on-chain credit history
3. **FUEL Token Contract**: SEP-41 compliant token implementation
4. **Geofencing Contract**: GPS validation for payments

Contract documentation available in [contracts/README.md](contracts/fuel-lock/README.md).

## Problem Statement

East African logistics and transportation sectors face critical challenges that hamper economic growth and financial inclusion:

**Fuel Fraud and Theft**: Fleet operators lose 15-25% of their fuel budgets to siphoning, receipt forgery, and unauthorized usage. Traditional fuel voucher systems rely on paper receipts that are easily manipulated, creating significant revenue leakage.

**Financial Exclusion**: Over 1.5 million Boda Boda (motorcycle taxi) riders in Kenya alone lack access to formal credit services. Without verifiable transaction histories or collateral, these micro-entrepreneurs cannot access loans to grow their businesses or manage cash flow during emergencies.

**Cash Dependency**: Approximately 70% of transactions in the informal transport sector are cash-based, creating security risks, inefficiencies, and lack of transparency. Cash transactions prevent the creation of auditable financial records needed for credit assessment.

**Invisible Credit History**: Micro-fleet operators and individual riders have no on-chain or verifiable transaction history, making it impossible for financial institutions to assess creditworthiness and extend appropriate financial products.

## Solution

FuelAnchor creates a blockchain-based digital fuel voucher system that transforms fuel distribution, payment, and credit access across East Africa.

**Tokenized Fuel Vouchers**: FuelAnchor issues SEP-41 compliant FUEL tokens on the Stellar blockchain, where each token represents a prepaid fuel credit. Fleet managers purchase these tokens via mobile money integration, then distribute them to drivers with granular spending controls.

**Geofenced Redemption**: Smart contracts validate both location and spending limits when drivers redeem fuel at participating stations. GPS geofencing ensures fuel can only be purchased within approved corridors or at authorized stations, eliminating fraud and unauthorized usage.

**On-Chain Credit Building**: Every fuel purchase creates an immutable transaction record on the Stellar blockchain. The system analyzes transaction patterns including frequency, consistency, volume, and account age to generate credit scores that enable micro-lending to previously unbankable populations.

**Mobile Money Integration**: Seamless on-ramp and off-ramp through M-Pesa, MTN MoMo, Airtel Money, and other regional mobile money providers. Users can convert local currency to FUEL tokens instantly without needing cryptocurrency knowledge.

**Multi-Platform Access**: Flutter mobile app for iOS and Android smartphones, with support for QR code scanning and GPS verification. Future plans include NFC card tapping for quick transactions and USSD fallback for feature phones, ensuring accessibility across all device types and economic segments.

## Market Target

**Primary Markets**: Kenya, Uganda, Tanzania, Rwanda, Burundi, and South Sudan represent the initial target markets, with expansion planned across the East African Community.

**Fleet Operators**: Transport companies managing 5-500 vehicles, logistics companies with regional distribution networks, and delivery services requiring fuel budget management and fraud prevention.

**Boda Boda Riders**: 1.5+ million motorcycle taxi riders in Kenya alone, representing a massive market of micro-entrepreneurs who need fuel purchasing efficiency and access to credit for vehicle maintenance, insurance, or emergencies.

**Fuel Station Networks**: Independent and chain fuel stations seeking to reduce cash handling, attract digital customers, and participate in the growing digital economy with lower transaction costs than traditional payment processors.

**Micro-Lenders and Financial Institutions**: Banks, MFIs, and fintech companies seeking verifiable credit data to serve the informal transport sector with loans, insurance, and other financial products.

## Business Impact and Revenue Model

**Transaction Fees**: FuelAnchor charges a 1-2% transaction fee on every fuel voucher purchase and redemption, generating revenue from the high-frequency, high-volume fuel transaction flow across the platform.

**SaaS Subscriptions for Fleet Management**: Fleet operators pay monthly subscription fees ($50-500 depending on fleet size) for access to the dashboard, analytics, geofencing controls, and advanced features like automated budget distribution and reconciliation.

**Credit Scoring API**: Financial institutions pay per-query fees to access credit scores and transaction histories, enabling them to make lending decisions based on verified on-chain data. This B2B revenue stream grows as the user base expands.

**Foreign Exchange Spread**: Small spreads on currency conversion when users deposit mobile money or withdraw funds, capitalizing on the anchor's role in facilitating cross-border settlements using Stellar's efficient payment rails.

**Premium Financial Products**: Commission-based revenue from facilitating micro-loans, insurance products, and savings accounts to users with established credit histories, partnering with regulated financial institutions for distribution.

**Market Impact**: By reducing fuel fraud by up to 25%, FuelAnchor saves fleet operators significant capital that can be reinvested in fleet expansion. Providing credit access to 1.5M+ riders unlocks economic opportunity and drives GDP growth in the informal transport sector. The digitization of fuel transactions creates transparent, auditable records that reduce corruption and improve tax collection efficiency.

## How FuelAnchor Uses Stellar

**Smart Contracts on Soroban**: FuelAnchor deploys four core smart contracts on Stellar's Soroban platform written in Rust: the FUEL token contract (SEP-41 compliant), voucher redemption contract with geofencing logic, credit score contract for on-chain reputation, and geofencing contract for GPS validation.

**SEP-24 Mobile Money Bridge**: Implementation of SEP-24 (hosted deposit and withdrawal) enables seamless integration with East African mobile money platforms. Users deposit KES, UGX, or TZS via M-Pesa or MTN MoMo, and the anchor mints equivalent FUEL tokens on Stellar.

**SEP-31 Cross-Border Payments**: For regional fleet operators managing vehicles across multiple countries, SEP-31 (cross-border payments) enables instant, low-cost settlement in local currencies without traditional correspondent banking delays.

**Low Transaction Costs**: Stellar's sub-cent transaction fees ($0.00001 per operation) make micro-transactions economically viable, unlike Ethereum or Bitcoin where gas fees would make small fuel purchases prohibitively expensive.

**3-5 Second Settlement**: Stellar's consensus mechanism provides near-instant finality, allowing drivers to receive tokens and redeem fuel in real-time without waiting for block confirmations that would create friction at fuel stations.

**Built-in DEX**: Stellar's decentralized exchange enables automatic market-making for FUEL tokens against XLM and other assets, providing liquidity and price stability without relying on centralized exchanges.

**Compliance and Regulation**: Stellar's design philosophy emphasizing regulatory compliance, combined with built-in KYC/AML tools through SEP-12, positions FuelAnchor to work within existing financial regulations across East African jurisdictions.

## Why This Is Important

**Financial Inclusion at Scale**: FuelAnchor provides 1.5+ million unbanked or underbanked transport workers with their first access to formal credit, creating pathways out of poverty and enabling economic mobility through verifiable financial history.

**Fraud Prevention**: Eliminating 15-25% revenue leakage from fuel fraud strengthens fleet operator profitability, reduces consumer fuel prices through efficiency gains, and creates a more transparent, trustworthy fuel distribution system.

**Economic Transparency**: Blockchain-based transaction records create auditable trails that reduce corruption, improve tax collection, and provide governments with accurate economic data to inform policy decisions in the critical transport and logistics sectors.

**Regional Integration**: By operating across six East African countries with cross-border payment capabilities, FuelAnchor facilitates regional trade and economic integration, reducing friction in the movement of goods and services across the EAC.

**Technological Leapfrogging**: East Africa, having leapfrogged traditional banking with mobile money adoption, is positioned to leapfrog traditional payment infrastructure with blockchain-based systems. FuelAnchor demonstrates how emerging markets can lead in financial innovation.

**Climate and Efficiency**: Digital fuel distribution reduces paper waste from traditional voucher systems, while transaction data enables fleet optimization insights that can reduce fuel consumption and emissions through better route planning and driver behavior analysis.

**Catalyst for Broader Adoption**: Success in the fuel voucher use case demonstrates blockchain's practical utility beyond speculation, creating a template for tokenizing other essential commodities like electricity, agriculture inputs, or healthcare services in emerging markets.
## Documentation

- [Setup Guide](SETUP_GUIDE.md) - Complete installation and deployment instructions
- [Architecture](ARCHITECTURE.md) - System architecture and data flows
- [Project Summary](PROJECT_SUMMARY.md) - Detailed project overview
- [Commands Reference](COMMANDS.md) - Quick command reference
- [Flutter App Documentation](frontend_flutter/README.md) - Mobile app details
- [Smart Contract Documentation](contracts/fuel-lock/README.md) - Contract API reference

## Development

### Running the Flutter App

```bash
cd frontend_flutter
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

### Building Smart Contracts

```bash
cd contracts/fuel-lock
soroban contract build
cargo test
```

### Backend Services

```bash
cd backend
npm install
npm run dev
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and linters
5. Submit a pull request

## License

See [LICENSE](LICENSE) file for details.

## Contact

For questions, support, or partnership inquiries, please open an issue or contact the development team.