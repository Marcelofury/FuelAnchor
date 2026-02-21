# FuelAnchor Deployment Scripts

Automated deployment and management scripts for FuelAnchor Soroban smart contracts.

## Prerequisites

- **Stellar CLI** installed: `cargo install --locked stellar-cli`
- **PowerShell** 7+ (cross-platform)
- **Rust toolchain** with wasm32-unknown-unknown target
- **Funded Testnet account** (get XLM from https://laboratory.stellar.org)

## Quick Start

### 1. Deploy All Contracts

Builds and deploys all smart contracts to Stellar Testnet:

```powershell
./scripts/deploy_contracts.ps1
```

This script will:
- ✅ Check for Stellar CLI installation
- ✅ Generate or use existing admin keypair
- ✅ Build all 5 contracts (fuel-token, fuel-lock, voucher-redemption, credit-score, geofencing)
- ✅ Deploy contracts to testnet
- ✅ Save contract IDs to `CONTRACT_IDS.txt`
- ✅ Generate `backend/.env` with contract configurations

**Output**: `CONTRACT_IDS.txt` and `backend/.env`

### 2. Initialize Contracts

Initializes deployed contracts with admin settings:

```powershell
./scripts/initialize_contracts.ps1
```

This script will:
- ✅ Initialize Fuel Token with name, symbol, and decimals
- ✅ Initialize Credit Score contract with admin
- ✅ Initialize Geofencing with max distance (100m)
- ✅ Initialize Voucher Redemption with linked contracts

**Note**: Run this ONCE after initial deployment. Re-running will show "already initialized" warnings.

### 3. Mint Test Tokens

Mint FUEL tokens for testing:

```powershell
./scripts/mint_tokens.ps1 -Amount 1000000 -Recipient GAKSTEST...
```

### 4. Generate Flutter Contract Bindings

Auto-generate Dart bindings for Flutter app from deployed contracts:

```powershell
./scripts/generate_contract_bindings.ps1 -Network testnet
```

This script will:
- ✅ Read contract IDs from `CONTRACT_IDS.txt`
- ✅ Extract contract metadata using Soroban CLI
- ✅ Generate type-safe Dart classes for each contract
- ✅ Create barrel export file for easy imports
- ✅ Output files to `frontend_flutter/lib/features/blockchain/generated/`

**Usage in Flutter**:
```dart
import 'package:fuelanchor/features/blockchain/generated/contracts.dart';

// Use generated contract classes
final fuelToken = FuelTokenContract(
  server: sorobanServer,
  networkPassphrase: Networks.TESTNET,
);
```

**Linux/macOS**:
```bash
chmod +x ./scripts/generate_contract_bindings.sh
./scripts/generate_contract_bindings.sh testnet
```

### 5. Monitor Contracts

```powershell
# Mint 10,000 FUEL to admin account
./scripts/mint_tokens.ps1

# Mint specific amount to a recipient
./scripts/mint_tokens.ps1 -Amount 5000 -Recipient "GCEXAMPLE..."

# Use different admin key
./scripts/mint_tokens.ps1 -AdminKey "my-admin" -Amount 1000
```

Parameters:
- `-AdminKey`: Stellar keypair name (default: "admin")
- `-Amount`: Amount of FUEL tokens to mint (default: 10000)
- `-Recipient`: Recipient address (default: admin address)
- `-Network`: Target network (default: "testnet")

### 4. Monitor Contracts

Monitor deployed contract status:

```powershell
# Single check
./scripts/monitor_contracts.ps1

# Continuous monitoring (refresh every 30 seconds)
./scripts/monitor_contracts.ps1 -Watch

# Custom refresh interval
./scripts/monitor_contracts.ps1 -Watch -RefreshSeconds 10
```

Shows:
- 📊 Token supply and metadata
- 👥 Total registered credit score users
- 🌐 Network status and latest ledger
- 📝 All contract IDs

## Script Details

### `deploy_contracts.ps1`

**What it does:**
1. Verifies Stellar CLI installation
2. Configures Stellar Testnet network
3. Generates admin keypair (if doesn't exist)
4. Builds all contracts in `contracts/` directory
5. Deploys each contract to testnet
6. Saves contract IDs to `CONTRACT_IDS.txt`
7. Generates `backend/.env` file

**Requirements:**
- Funded testnet account for deployment fees
- Internet connection for testnet access

**Output Files:**
- `CONTRACT_IDS.txt` - Contract deployment addresses
- `backend/.env` - Backend environment configuration

### `initialize_contracts.ps1`

**What it does:**
1. Reads contract IDs from `CONTRACT_IDS.txt`
2. Calls `initialize` function on each contract
3. Sets admin addresses and links contracts together
4. Configures default parameters (geofencing distance, etc.)

**Parameters:**
- `-AdminKey`: Keypair name for admin (default: "admin")
- `-Network`: Target network (default: "testnet")

**Note:** Only run ONCE per deployment. Contracts cannot be re-initialized.

### `mint_tokens.ps1`

**What it does:**
1. Invokes `mint` function on Fuel Token contract
2. Mints specified amount to recipient address
3. Verifies balance after minting

**Use Cases:**
- Initial token distribution for testing
- Funding merchant accounts
- Allocating tokens to fleet operators
- Test transaction scenarios

### `monitor_contracts.ps1`

**What it does:**
1. Fetches real-time contract state
2. Displays token supply and metadata
3. Shows credit scoring statistics
4. Checks network connectivity
5. Continuous monitoring mode available

**Parameters:**
- `-Network`: Target network (default: "testnet")
- `-Watch`: Enable continuous monitoring
- `-RefreshSeconds`: Refresh interval for watch mode (default: 30)

**Use Cases:**
- Verify contract deployment
- Monitor token supply
- Track user adoption (credit scores)
- Debugging and development

## Development Workflow

### First-Time Setup

```powershell
# 1. Deploy contracts
./scripts/deploy_contracts.ps1

# 2. Initialize contracts
./scripts/initialize_contracts.ps1

# 3. Mint initial tokens for testing
./scripts/mint_tokens.ps1 -Amount 100000

# 4. Verify deployment
./scripts/monitor_contracts.ps1
```

### After Code Changes

```powershell
# 1. Rebuild contracts (in contracts/ directory)
cd contracts
stellar contract build
cd ..

# 2. Deploy updated contracts
./scripts/deploy_contracts.ps1

# 3. Re-initialize (if contract interface changed)
./scripts/initialize_contracts.ps1

# 4. Update backend .env with new contract IDs
# 5. Update Flutter app with new contract IDs
```

### Testing Scenarios

```powershell
# Create test accounts
stellar keys generate rider1 --network testnet
stellar keys generate merchant1 --network testnet

# Fund test accounts
stellar contract invoke --id $FUEL_TOKEN_ID -- transfer \
  --from $(stellar keys address admin) \
  --to $(stellar keys address rider1) \
  --amount 500000000

# Monitor activity
./scripts/monitor_contracts.ps1 -Watch
```

## Integration with Other Components

### Backend Integration

After running `deploy_contracts.ps1`, the `backend/.env` file is auto-generated with:
- Contract IDs
- Network configuration
- RPC endpoints

Start backend server:
```bash
cd backend
npm install
npm run dev
```

### Flutter App Integration

Update Flutter app with contract IDs from `CONTRACT_IDS.txt`:

Edit `frontend_flutter/lib/features/blockchain/data/services/stellar_service.dart`:

```dart
static const String fuelTokenContractId = 'YOUR_FUEL_TOKEN_ID';
static const String creditScoreContractId = 'YOUR_CREDIT_SCORE_ID';
// ... add other contract IDs
```

Then rebuild:
```bash
cd frontend_flutter
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

## Troubleshooting

### "stellar: command not found"

Install Stellar CLI:
```bash
cargo install --locked stellar-cli
```

### "Insufficient funds" error

Fund your admin account:
1. Get address: `stellar keys address admin`
2. Visit: https://laboratory.stellar.org/#account-creator?network=test
3. Paste address and click "Get test network lumens"

### "Contract already initialized"

This is normal if you run `initialize_contracts.ps1` multiple times. Contracts can only be initialized once.

### "Unable to connect to Horizon"

Check your network connection and verify testnet is operational:
https://status.stellar.org

### Contract deployment fails

Ensure:
- Admin account is funded (check balance on https://stellar.expert)
- Network is testnet (not mainnet)
- Contracts are built successfully (`stellar contract build`)

## Environment Variables

After running scripts, update these in your environment:

### Backend `.env`
```bash
FUEL_TOKEN_CONTRACT_ID=CXXXX...
VOUCHER_REDEMPTION_CONTRACT_ID=CXXXX...
CREDIT_SCORE_CONTRACT_ID=CXXXX...
GEOFENCING_CONTRACT_ID=CXXXX...
FUEL_LOCK_CONTRACT_ID=CXXXX...
STELLAR_ADMIN_SECRET=SXXXX...  # From stellar keys show admin
```

### Flutter App Constants
Update in `stellar_service.dart` or create environment config file.

## Security Notes

- ⚠️ **NEVER** commit admin secret keys to git
- ⚠️ Use testnet for development only
- ⚠️ For production, use secure key management (HSM, KMS)
- ⚠️ Generate new keypairs for mainnet deployment
- ⚠️ Review contract code before mainnet deployment

## Mainnet Deployment

When ready for production:

1. Change network parameter: `-Network mainnet`
2. Use production admin keypair
3. Fund admin account with real XLM
4. Test thoroughly on testnet first
5. Deploy contracts one by one and verify
6. Initialize contracts with production settings
7. Update all frontend/backend configs
8. Monitor contracts continuously

```powershell
# Mainnet deployment (use with caution!)
./scripts/deploy_contracts.ps1 -Network mainnet
./scripts/initialize_contracts.ps1 -Network mainnet
```

## Additional Resources

- [Stellar Documentation](https://developers.stellar.org/)
- [Soroban Documentation](https://soroban.stellar.org/docs)
- [FuelAnchor Architecture](../ARCHITECTURE.md)
- [Deployment Guide](../DEPLOYMENT.md)

## Support

For issues or questions:
- GitHub Issues: https://github.com/Marcelofury/FuelAnchor/issues
- Project Documentation: See `README.md` in project root
