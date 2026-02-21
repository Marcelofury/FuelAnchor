# Phase 2: Flutter-Blockchain Integration

**Completed: February 21, 2026**

## Overview

Phase 2 integrates the Flutter mobile app with the deployed Soroban smart contracts from Phase 1. This phase replaces mock implementations with real blockchain interactions.

## Changes Made

### 1. Updated Contract Configuration

**File:** `frontend_flutter/lib/features/blockchain/data/services/stellar_service.dart`

**Lines 15-18:** Updated with real deployed contract IDs
```dart
// Deployed contract IDs from Phase 1 (Feb 21, 2026)
static const String _fuelAssetIssuer = 'GCHWQJ4OVQBBOSWEQUXYXFMWVIINIMN2AXWU6FRKCB7YA6NPFFJOJXKX';
static const String _sorobanContractId = 'CDRQE4CCMQP5AFZZQ6MFADSAAGXFQZQVUKX6H66AQW5BUDPDSB32ITNB';
```

- `_fuelAssetIssuer`: Admin account address (asset issuer)
- `_sorobanContractId`: Fuel-Lock contract ID for payment processing

### 2. Implemented Soroban Contract Invocation

**File:** `frontend_flutter/lib/features/blockchain/data/services/stellar_service.dart`

**Function:** `payMerchant()` (Lines 120-210)

Replaced mock implementation with real blockchain integration:

**Functionality:**
- Converts GPS coordinates to micro-degrees (multiply by 1,000,000)
- Builds XDR values for contract function parameters
- Invokes `pay_merchant` function on fuel-lock contract
- Signs and submits transaction to Soroban RPC
- Returns transaction hash on success

**Contract Parameters:**
```rust
pub fn pay_merchant(
    env: Env,
    driver: Address,
    merchant: Address,
    amount: i128,
    driver_gps: (i128, i128), // (latitude, longitude) in micro-degrees
) -> Result<(), Error>
```

**Implementation Details:**
- Uses `InvokeContractHostFunction` for contract invocation
- Converts amount to i128 XDR value with proper high/low bit splitting
- Creates GPS tuple with latitude and longitude as i128 micro-degrees
- Handles response status: SUCCESS, ERROR, or PENDING
- Proper error logging and failure handling

### 3. Upgraded Stellar Flutter SDK

**File:** `frontend_flutter/pubspec.yaml`

**Change:** Upgraded from `^1.8.3` to `^3.0.1`

**Reason:** 
- Version 3.0.1 has improved Soroban support
- Better contract invocation APIs
- Resolves API compatibility issues mentioned in original TODO

**Dependencies Updated:**
```
stellar_flutter_sdk: 3.0.1 (was 1.9.4)
dart_jsonwebtoken: 3.3.1 (was 3.1.1)
petitparser: 7.0.2 (was 6.1.0)
pointycastle: 4.0.0 (was 3.9.1)
toml: 0.17.0 (was 0.16.0)
archive: 3.6.1 (newly added)
```

### 4. Updated Backend Configuration

**File:** `backend/.env`

**Line 15:** Added admin secret key
```dotenv
STELLAR_ADMIN_SECRET=SAM6H3VAYJFNK4BTM5HLMJLX35IUPG73GFL3UP7DSZ3PEKJVLVNYTMYG
```

**Warning:** This is a testnet key. NEVER commit real mainnet keys to version control.

## Deployed Contract Registry

All contracts deployed to **Stellar Testnet** on Feb 21, 2026:

| Contract | ID | Purpose |
|----------|-------|---------|
| Fuel Token | `CCEUEJTBNPLTIRQYCSRL6RZX7Y3KK24RRTBP4ZA4K2XWR5LSWNMMRMZF` | FUEL token implementation |
| Fuel Lock | `CDRQE4CCMQP5AFZZQ6MFADSAAGXFQZQVUKX6H66AQW5BUDPDSB32ITNB` | Payment processing & quotas |
| Voucher Redemption | `CBRFBUDWNHU2ROA2XN2A4527UIZFKICVKXKZWORLZ2XIOYQBTRXTWJAG` | Fuel voucher redemption |
| Credit Score | `CA5G6454KS2HTIYADEULYDJLABR4AZVP62AQVI5CAJ67DHFHH45WYOBW` | Credit scoring logic |
| Geofencing | `CA5ZHEPUCRECX2CFPSKJRDXDAPRM3OS2CTTBMFUPXAZ55RO4MXFVSDRN` | Geographic validation |

## Admin Account

**Public Key:** `GCHWQJ4OVQBBOSWEQUXYXFMWVIINIMN2AXWU6FRKCB7YA6NPFFJOJXKX`  
**Funded:** Yes (via Friendbot)  
**Network:** Testnet  
**RPC Endpoint:** https://soroban-testnet.stellar.org:443

## Testing Requirements

### Before Production Testing

1. **Initialize Contracts:**
   ```bash
   # Initialize fuel-lock contract
   stellar contract invoke \
     --id CDRQE4CCMQP5AFZZQ6MFADSAAGXFQZQVUKX6H66AQW5BUDPDSB32ITNB \
     --source admin \
     -- initialize \
     --admin GCHWQJ4OVQBBOSWEQUXYXFMWVIINIMN2AXWU6FRKCB7YA6NPFFJOJXKX
   
   # Initialize other contracts similarly
   ```

2. **Set Up Test Driver:**
   ```bash
   # Create test driver quota
   stellar contract invoke \
     --id CDRQE4CCMQP5AFZZQ6MFADSAAGXFQZQVUKX6H66AQW5BUDPDSB32ITNB \
     --source admin \
     -- set_driver_quota \
     --driver <DRIVER_ADDRESS> \
     --allocated-quota 10000000 \
     --start-date $(date +%s)
   ```

3. **Fund Test Accounts:**
   - Create test driver account in Flutter app
   - Fund via Friendbot (testnet only)
   - Verify balance appears in wallet

### End-to-End Payment Flow Test

1. **Launch Flutter App:**
   ```bash
   cd frontend_flutter
   flutter run
   ```

2. **Create/Login Test Accounts:**
   - Rider account (driver)
   - Merchant account (fuel station)

3. **Test Payment Process:**
   - Rider: Navigate to QR scanner
   - Merchant: Display station QR code with public key
   - Rider: Scan QR code
   - Rider: Enter payment amount
   - Rider: Confirm payment with GPS location
   - Verify transaction hash appears
   - Check transaction on Stellar Expert:
     ```
     https://stellar.expert/explorer/testnet/tx/<TX_HASH>
     ```

4. **Verify Contract State:**
   ```bash
   # Check driver quota was debited
   stellar contract invoke \
     --id CDRQE4CCMQP5AFZZQ6MFADSAAGXFQZQVUKX6H66AQW5BUDPDSB32ITNB \
     --source admin \
     -- get_driver_quota \
     --driver <DRIVER_ADDRESS>
   
   # Check payment history
   stellar contract invoke \
     --id CDRQE4CCMQP5AFZZQ6MFADSAAGXFQZQVUKX6H66AQW5BUDPDSB32ITNB \
     --source admin \
     -- get_payment_history \
     --driver <DRIVER_ADDRESS> \
     --limit 10
   ```

### Expected Behavior

✅ **Success Case:**
- Transaction submitted successfully
- Transaction hash returned (format: 64-character hex string)
- Driver quota decremented
- Payment record stored on-chain
- FUELING event emitted with GPS coordinates

❌ **Error Cases to Test:**
- Insufficient quota → `Error::InsufficientQuota`
- Invalid amount (≤0) → `Error::InvalidAmount`
- Invalid GPS coordinates
- Network connectivity issues
- Authentication failures

## API Compatibility Notes

### stellar_flutter_sdk v3.0.1

The implementation uses the following XDR constructors:

```dart
// Address types
Address.forContractId(contractId)
Address.forAccountId(accountId)

// i128 values
XdrSCVal.forI128(XdrInt128Parts(high, low))

// Vectors (tuples)
XdrSCVal.forVec([...elements])

// Contract invocation
InvokeContractHostFunction(contractAddress, functionName, args)

// Transaction building
TransactionBuilder(account)
  .addOperation(invokeOperation.toOperation())
  .build()

// Signing
transaction.sign(keyPair, network)

// Submission
_sdk.sorobanServer.sendTransaction(transaction)
```

**Breaking Changes from v1.x:**
- XDR value constructors use static methods instead of constructors
- `InvokeContractHostFunction` API changed
- Response types restructured with status enums

## Known Limitations

1. **SDK Version:** Using v3.0.1 which is new - test thoroughly
2. **Error Handling:** Basic error messages - may need more detailed parsing
3. **Transaction Polling:** Currently returns immediately - may need to poll for final status
4. **Gas Estimation:** Not implemented - using default gas limits
5. **Contract Initialization:** Must be done manually via CLI before first use

## Future Improvements

1. **Transaction Status Polling:**
   - Implement polling mechanism for pending transactions
   - Update UI with real-time transaction status
   - Handle transaction timeouts gracefully

2. **Gas Optimization:**
   - Estimate gas before submission
   - Allow users to set gas price
   - Implement gas price recommendations

3. **Enhanced Error Messages:**
   - Parse contract-specific errors
   - Display user-friendly error messages
   - Provide retry mechanisms

4. **Geofencing Integration:**
   - Call geofencing contract before payment
   - Validate driver location against merchant location
   - Block payments outside allowed zones

5. **Multi-Contract Flows:**
   - Integrate voucher-redemption contract
   - Implement credit scoring checks
   - Add batch payment support

## Security Considerations

⚠️ **Testnet Security:**
- Admin secret key stored in `.env` file
- DO NOT use this key pattern on mainnet
- Implement proper key management (HSM, secure enclave) for production

⚠️ **GPS Spoofing:**
- Current implementation trusts client-provided GPS
- Production should implement:
  - Multi-source GPS validation
  - Triangulation verification
  - Server-side location checks

⚠️ **Authentication:**
- Contract requires driver authentication (`driver.require_auth()`)
- Flutter app must sign transactions with driver's private key
- Keep private keys in secure storage only

## Troubleshooting

### Contract Not Initialized
```
Error: Not initialized
Solution: Run initialize() on fuel-lock contract with admin key
```

### Insufficient Quota
```
Error: InsufficientQuota
Solution: Set driver quota or top up existing quota via set_driver_quota
```

### Invalid GPS Format
```
Error: Invalid parameters
Solution: Ensure GPS is {latitude: double, longitude: double}
```

### Transaction Timeout
```
Error: Transaction pending
Solution: Poll for status using transaction hash, or increase timeout
```

### XDR Encoding Errors
```
Error: Failed to build transaction
Solution: Check XDR value constructors match contract types
```

## Next Steps

1. ✅ Deploy contracts (Phase 1 - Complete)
2. ✅ Update Flutter config (Phase 2 - Complete)
3. ✅ Implement contract invocation (Phase 2 - Complete)
4. ⏳ Initialize contracts (Required before testing)
5. ⏳ Test payment flow end-to-end
6. ⏳ Integrate remaining contracts (voucher, credit-score, geofencing)
7. ⏳ Build merchant dashboard features
8. ⏳ Implement settlement and reporting

## References

- **Deployed Contracts:** See `CONTRACT_IDS.txt`
- **Deployment Guide:** See `DEPLOYMENT.md`
- **Contract Source:** `contracts/fuel-lock/src/lib.rs`
- **Flutter Service:** `frontend_flutter/lib/features/blockchain/data/services/stellar_service.dart`
- **Stellar SDK Docs:** https://github.com/Soneso/stellar_flutter_sdk
- **Soroban Docs:** https://soroban.stellar.org/docs

---

**Phase 2 Status:** ✅ Complete  
**Ready for Testing:** Yes (after contract initialization)  
**Next Phase:** Integration testing and merchant features
