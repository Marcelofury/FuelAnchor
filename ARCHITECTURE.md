# FuelAnchor Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         FuelAnchor System                        │
└─────────────────────────────────────────────────────────────────┘

┌──────────────┐         ┌──────────────┐         ┌──────────────┐
│    Rider     │         │ Fleet Driver │         │   Merchant   │
│   (Mobile)   │         │   (Mobile)   │         │   (Mobile)   │
└──────┬───────┘         └──────┬───────┘         └──────┬───────┘
       │                        │                        │
       └────────────────────────┼────────────────────────┘
                                │
                    ┌───────────▼───────────┐
                    │   Flutter Mobile App   │
                    │  (Feature-First Arch)  │
                    └───────────┬───────────┘
                                │
                ┌───────────────┼───────────────┐
                │               │               │
        ┌───────▼──────┐ ┌─────▼─────┐ ┌──────▼──────┐
        │ StellarService│ │  Riverpod │ │   GoRouter  │
        │  (Blockchain) │ │   (State) │ │  (Routing)  │
        └───────┬──────┘ └───────────┘ └─────────────┘
                │
                │
        ┌───────▼──────────────────────┐
        │  Stellar/Soroban Network     │
        │         (Testnet)             │
        └───────┬──────────────────────┘
                │
        ┌───────▼──────────────────────┐
        │   FuelLock Smart Contract    │
        │      (Rust/Soroban)          │
        │  • Quota Management          │
        │  • Payment Processing        │
        │  • GPS Verification          │
        └──────────────────────────────┘
```

## Flutter App Architecture

### Feature-First + Clean Architecture

```
lib/
│
├── core/                           # Cross-cutting concerns
│   ├── constants/
│   │   ├── app_colors.dart        # Navy & Electric Green palette
│   │   └── app_strings.dart       # Localization strings
│   ├── enums/
│   │   └── user_role.dart         # Rider, FleetDriver, Merchant
│   ├── error/
│   │   └── failure.dart           # Sealed error types
│   ├── router/
│   │   └── app_router.dart        # GoRouter configuration
│   └── utils/
│       └── logger.dart            # Centralized logging
│
└── features/                       # Business features
    │
    ├── auth/                       # Authentication Feature
    │   ├── domain/
    │   │   └── entities/
    │   │       └── user_entity.dart
    │   ├── providers/
    │   │   └── providers.dart      # UserRoleNotifier, UserPublicKey
    │   └── presentation/
    │       └── screens/
    │           └── login_screen.dart
    │
    ├── blockchain/                 # Blockchain Feature
    │   └── data/
    │       └── services/
    │           └── stellar_service.dart  ⭐ CORE SERVICE
    │
    ├── payment/                    # Payment Feature
    │   ├── domain/
    │   │   └── entities/
    │   │       └── payment_entity.dart
    │   └── providers/
    │       └── payment_providers.dart  # PaymentNotifier
    │
    ├── wallet/                     # Wallet Feature
    │   ├── domain/
    │   │   └── entities/
    │   │       └── wallet_balance.dart
    │   └── providers/
    │       └── wallet_providers.dart  # WalletBalanceNotifier
    │
    └── dashboard/                  # Dashboard Feature
        └── presentation/
            └── screens/
                ├── rider_dashboard_screen.dart
                ├── fleet_dashboard_screen.dart
                └── merchant_dashboard_screen.dart
```

## Data Flow

### 1. User Login Flow

```
┌─────────────┐
│ User Opens  │
│     App     │
└──────┬──────┘
       │
       ▼
┌─────────────────┐
│  Login Screen   │
│  Select Role    │
└──────┬──────────┘
       │
       ▼
┌────────────────────────┐
│  StellarService:       │
│  Generate or Load      │
│  Keypair               │
└──────┬─────────────────┘
       │
       ▼
┌────────────────────────┐
│  SecureStorage:        │
│  Store Secret Key      │
└──────┬─────────────────┘
       │
       ▼
┌────────────────────────┐
│  UserRoleNotifier:     │
│  Set User Role         │
└──────┬─────────────────┘
       │
       ▼
┌────────────────────────┐
│  Navigate to           │
│  Role-Specific         │
│  Dashboard             │
└────────────────────────┘
```

### 2. Payment Flow (Rider → Merchant)

```
┌──────────────┐
│ Rider Scans  │
│ Merchant QR  │
└──────┬───────┘
       │
       ▼
┌───────────────────┐
│ Extract Merchant  │
│   Public Key      │
└──────┬────────────┘
       │
       ▼
┌───────────────────┐
│  Enter Amount     │
│    (Dialog)       │
└──────┬────────────┘
       │
       ▼
┌───────────────────┐
│  Get GPS          │
│  Coordinates      │
│  (Geolocator)     │
└──────┬────────────┘
       │
       ▼
┌────────────────────────────┐
│  PaymentNotifier:          │
│  executePayment()          │
└──────┬─────────────────────┘
       │
       ▼
┌────────────────────────────┐
│  StellarService:           │
│  payMerchant()             │
│  • Build transaction       │
│  • Sign with keypair       │
│  • Submit to network       │
└──────┬─────────────────────┘
       │
       ▼
┌────────────────────────────┐
│  Soroban Network:          │
│  Invoke FuelLock Contract  │
│  pay_merchant()            │
└──────┬─────────────────────┘
       │
       ▼
┌────────────────────────────┐
│  Contract validates:       │
│  • Driver has quota        │
│  • Amount is valid         │
│  • Update used quota       │
│  • Emit FUELING event      │
└──────┬─────────────────────┘
       │
       ▼
┌────────────────────────────┐
│  Return Transaction Hash   │
│  Show success/error to UI  │
│  Refresh wallet balance    │
└────────────────────────────┘
```

### 3. State Management Flow (Riverpod)

```
┌─────────────────┐
│   Widget Tree   │
└────────┬────────┘
         │ ref.watch()
         ▼
┌──────────────────────┐
│  Riverpod Provider   │
│  (Auto-generated)    │
└────────┬─────────────┘
         │
         ▼
┌──────────────────────┐
│  Notifier Class      │
│  • State management  │
│  • Business logic    │
└────────┬─────────────┘
         │
         ▼
┌──────────────────────┐
│  Data Source         │
│  • StellarService    │
│  • SecureStorage     │
└────────┬─────────────┘
         │
         ▼
┌──────────────────────┐
│  State Update        │
│  (Notify listeners)  │
└────────┬─────────────┘
         │
         ▼
┌──────────────────────┐
│  UI Rebuilds         │
│  (Automatically)     │
└──────────────────────┘
```

## Smart Contract Architecture

### FuelLock Contract Structure

```
┌─────────────────────────────────────────┐
│         FuelLock Smart Contract         │
├─────────────────────────────────────────┤
│                                         │
│  Storage:                               │
│  ├── ADMIN (Address)                    │
│  ├── IS_INIT (bool)                     │
│  ├── Driver Quotas (Map)                │
│  └── Payment Records (Map)              │
│                                         │
├─────────────────────────────────────────┤
│                                         │
│  Functions:                             │
│  ├── initialize(admin)                  │
│  ├── set_driver_quota(...)              │
│  ├── pay_merchant(...)                  │
│  ├── update_odometer(...)               │
│  ├── get_driver_quota(...)              │
│  └── get_payment_history(...)           │
│                                         │
├─────────────────────────────────────────┤
│                                         │
│  Events:                                │
│  └── FUELING (driver, merchant, amount) │
│                                         │
└─────────────────────────────────────────┘
```

### Payment Validation Logic

```
pay_merchant() called
       │
       ▼
┌──────────────────┐
│ Require driver   │
│ authentication   │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Validate amount  │
│ (amount > 0)     │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Get driver quota │
│ from storage     │
└────────┬─────────┘
         │
         ▼
┌──────────────────────┐
│ Calculate remaining  │
│ quota                │
└────────┬─────────────┘
         │
         ▼
┌──────────────────────┐   NO   ┌─────────────────┐
│ Sufficient quota?    │───────►│ Return Error:   │
│                      │        │ InsufficientQuota│
└────────┬─────────────┘        └─────────────────┘
         │ YES
         ▼
┌──────────────────────┐
│ Update used_quota    │
└────────┬─────────────┘
         │
         ▼
┌──────────────────────┐
│ Store payment record │
└────────┬─────────────┘
         │
         ▼
┌──────────────────────┐
│ Emit FUELING event   │
└────────┬─────────────┘
         │
         ▼
┌──────────────────────┐
│ Return success       │
└──────────────────────┘
```

## Dependency Graph

```
┌─────────────────────────────────────────────────┐
│              External Dependencies              │
├─────────────────────────────────────────────────┤
│                                                 │
│  Flutter Framework                              │
│  ├── flutter_riverpod (State)                   │
│  ├── go_router (Navigation)                     │
│  ├── freezed (Immutability)                     │
│  └── dartz (Functional)                         │
│                                                 │
│  Blockchain                                     │
│  └── stellar_flutter_sdk                        │
│                                                 │
│  Device Features                                │
│  ├── geolocator (GPS)                           │
│  ├── mobile_scanner (QR)                        │
│  ├── qr_flutter (QR Gen)                        │
│  └── flutter_secure_storage (Encryption)        │
│                                                 │
│  UI                                             │
│  └── google_fonts                               │
│                                                 │
└─────────────────────────────────────────────────┘
```

## Security Architecture

```
┌────────────────────────────────────────┐
│          Security Layers               │
├────────────────────────────────────────┤
│                                        │
│  1. Device Level                       │
│     ├── Secure Enclave (iOS)           │
│     ├── Keystore (Android)             │
│     └── flutter_secure_storage         │
│                                        │
│  2. Transport Level                    │
│     ├── HTTPS/TLS                      │
│     └── Stellar Network Encryption     │
│                                        │
│  3. Authentication Level               │
│     ├── Stellar Keypair Signatures     │
│     └── Address.require_auth()         │
│                                        │
│  4. Validation Level                   │
│     ├── Contract quota checks          │
│     ├── GPS verification               │
│     └── Amount validation              │
│                                        │
└────────────────────────────────────────┘
```

## Deployment Architecture

```
                    ┌──────────────┐
                    │  Developer   │
                    └──────┬───────┘
                           │
           ┌───────────────┼───────────────┐
           │                               │
    ┌──────▼──────┐              ┌────────▼────────┐
    │   Flutter   │              │  Soroban CLI    │
    │   Build     │              │  Contract Build │
    └──────┬──────┘              └────────┬────────┘
           │                               │
           │                               │
    ┌──────▼──────────┐          ┌────────▼─────────┐
    │  App Stores     │          │ Stellar Testnet  │
    │  • Play Store   │          │ or Mainnet       │
    │  • App Store    │          │                  │
    └──────┬──────────┘          └────────┬─────────┘
           │                               │
           │                               │
    ┌──────▼──────────┐          ┌────────▼─────────┐
    │  User Devices   │◄─────────┤ Smart Contract   │
    │  (iOS/Android)  │  Calls   │   (On-chain)     │
    └─────────────────┘          └──────────────────┘
```

## Technology Stack Summary

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Frontend** | Flutter 3.0+ | Cross-platform mobile UI |
| **State Management** | Riverpod 2.4+ | Reactive state management |
| **Navigation** | GoRouter 13+ | Declarative routing |
| **Blockchain SDK** | stellar_flutter_sdk | Stellar/Soroban integration |
| **Smart Contract** | Rust + Soroban SDK 22 | On-chain business logic |
| **Storage** | flutter_secure_storage | Encrypted keypair storage |
| **Location** | geolocator | GPS verification |
| **QR** | mobile_scanner + qr_flutter | Payment scanning |
| **Fonts** | Google Fonts | Typography |
| **FP Utilities** | Dartz | Either, Option types |

---

**Architecture Principles:**
- ✅ Separation of concerns
- ✅ Single responsibility
- ✅ Dependency inversion
- ✅ Clean architecture layers
- ✅ Feature-first organization
- ✅ Immutable state
- ✅ Functional error handling
