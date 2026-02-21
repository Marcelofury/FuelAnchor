# FuelAnchor Contract Deployment Guide

## Phase 1: Smart Contract Deployment to Stellar Testnet

### Prerequisites

Before deploying contracts, ensure you have:

1. **Rust & Cargo installed**
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
   ```

2. **Soroban CLI installed**
   ```bash
   cargo install --locked soroban-cli --version 21.0.0
   ```

3. **WASM target added**
   ```bash
   rustup target add wasm32-unknown-unknown
   ```

4. **Verify installation**
   ```bash
   soroban --version
   # Should show: soroban 21.0.0 or higher
   ```

### Quick Deployment (Automated)

#### Option A: Linux/Mac (Bash)
```bash
cd scripts
chmod +x deploy_contracts.sh
./deploy_contracts.sh
```

#### Option B: Windows (PowerShell)
```powershell
cd scripts
.\deploy_contracts.ps1
```

The script will:
- ✅ Check for Soroban CLI installation
- ✅ Configure Stellar Testnet network
- ✅ Generate admin keypair (if needed)
- ✅ Build all 5 contracts
- ✅ Deploy contracts to testnet
- ✅ Save contract IDs to `.env` and `CONTRACT_IDS.txt`

### Manual Deployment (Step-by-Step)

If you prefer manual control or the script fails:

#### 1. Configure Network
```bash
soroban network add testnet \
  --rpc-url https://soroban-testnet.stellar.org:443 \
  --network-passphrase "Test SDF Network ; September 2015"
```

#### 2. Generate Admin Keypair
```bash
soroban keys generate admin --network testnet
soroban keys address admin
```

**Copy the address** and fund it at: https://laboratory.stellar.org/#account-creator?network=test

#### 3. Build Contracts
```bash
cd contracts

# Fuel Token
cd fuel-token
soroban contract build
cd ..

# Fuel Lock
cd fuel-lock
soroban contract build
cd ..

# Voucher Redemption
cd voucher-redemption
soroban contract build
cd ..

# Credit Score
cd credit-score
soroban contract build
cd ..

# Geofencing
cd geofencing
soroban contract build
cd ..
```

#### 4. Deploy Contracts

**Deploy Fuel Token:**
```bash
cd fuel-token
soroban contract deploy \
  --wasm target/wasm32-unknown-unknown/release/fuel_token.wasm \
  --source admin \
  --network testnet
```
**Save the returned contract ID as `FUEL_TOKEN_CONTRACT_ID`**

**Deploy Fuel Lock:**
```bash
cd ../fuel-lock
soroban contract deploy \
  --wasm target/wasm32-unknown-unknown/release/fuel_lock.wasm \
  --source admin \
  --network testnet
```
**Save as `FUEL_LOCK_CONTRACT_ID`**

**Deploy Voucher Redemption:**
```bash
cd ../voucher-redemption
soroban contract deploy \
  --wasm target/wasm32-unknown-unknown/release/voucher_redemption.wasm \
  --source admin \
  --network testnet
```
**Save as `VOUCHER_REDEMPTION_CONTRACT_ID`**

**Deploy Credit Score:**
```bash
cd ../credit-score
soroban contract deploy \
  --wasm target/wasm32-unknown-unknown/release/credit_score.wasm \
  --source admin \
  --network testnet
```
**Save as `CREDIT_SCORE_CONTRACT_ID`**

**Deploy Geofencing:**
```bash
cd ../geofencing
soroban contract deploy \
  --wasm target/wasm32-unknown-unknown/release/geofencing.wasm \
  --source admin \
  --network testnet
```
**Save as `GEOFENCING_CONTRACT_ID`**

### Post-Deployment Configuration

#### 1. Update Backend Environment

Create or edit `backend/.env`:
```env
# Stellar Network
STELLAR_NETWORK=testnet
STELLAR_HORIZON_URL=https://horizon-testnet.stellar.org
STELLAR_SOROBAN_RPC_URL=https://soroban-testnet.stellar.org:443
STELLAR_NETWORK_PASSPHRASE=Test SDF Network ; September 2015

# Get your admin secret with: soroban keys show admin
STELLAR_ADMIN_SECRET=SXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

# Contract IDs from deployment
FUEL_TOKEN_CONTRACT_ID=CXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
FUEL_LOCK_CONTRACT_ID=CXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
VOUCHER_REDEMPTION_CONTRACT_ID=CXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
CREDIT_SCORE_CONTRACT_ID=CXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
GEOFENCING_CONTRACT_ID=CXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

# Server Config
PORT=3000
NODE_ENV=development
CORS_ORIGINS=http://localhost:3000,http://localhost:8080
```

#### 2. Update Flutter App

Edit `frontend_flutter/lib/features/blockchain/data/services/stellar_service.dart`:

```dart
// Line 17-18: Replace placeholder IDs
static const String _fuelAssetIssuer = 'YOUR_ADMIN_ADDRESS';
static const String _sorobanContractId = 'YOUR_FUEL_LOCK_CONTRACT_ID';
```

Replace:
- `YOUR_ADMIN_ADDRESS` with the address from `soroban keys address admin`
- `YOUR_FUEL_LOCK_CONTRACT_ID` with the deployed fuel-lock contract ID

### Verification

#### 1. Check Contract on Stellar Expert
Visit: `https://stellar.expert/explorer/testnet/contract/YOUR_CONTRACT_ID`

#### 2. Test Contract Invocation
```bash
soroban contract invoke \
  --id YOUR_FUEL_TOKEN_CONTRACT_ID \
  --source admin \
  --network testnet \
  -- \
  name
```

Should return the token name.

#### 3. Test Backend
```bash
cd backend
npm install
npm run dev
```

Visit: http://localhost:3000/health
Should return: `{"status": "healthy"}`

### Troubleshooting

**Error: "Account not found"**
- Solution: Fund your admin account at https://laboratory.stellar.org/#account-creator?network=test

**Error: "Contract already exists"**
- Solution: Each deployment creates a new instance. If you want to reinstall, just deploy again with a new ID.

**Error: "WASM file not found"**
- Solution: Run `soroban contract build` in the contract directory first.

**Error: "Network not configured"**
- Solution: Run the network add command from step 1.

### Next Steps

After successful deployment:
- ✅ Proceed to **Phase 2: Configuration** (See below)
- ✅ Update Flutter app with contract IDs
- ✅ Test end-to-end payment flow

---

## Phase 2: Configuration (Coming Next)

Once contracts are deployed, you'll need to:
1. Configure backend with contract IDs ✅ (Done by script)
2. Update Flutter stellar_service.dart
3. Initialize contracts with admin settings
4. Test contract invocations

## Phase 3: Integration (After Phase 2)

Implement real blockchain calls in:
- Payment processing (scan_screen.dart)
- Transaction history (settlement_screen.dart)
- Voucher generation (fleet_dashboard_screen.dart)
- GPS verification (geofencing contract)

---

**Need Help?** Check the contract README files in `contracts/*/README.md` or the main [SETUP_GUIDE.md](SETUP_GUIDE.md)
