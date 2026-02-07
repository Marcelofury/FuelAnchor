# FuelAnchor - Soroban Smart Contract

## Overview

The `FuelLock` smart contract manages fuel payments, quotas, and driver verification on the Stellar/Soroban network.

## Features

- ✅ Admin-managed driver fuel quotas
- ✅ Secure payment processing with GPS verification
- ✅ Odometer tracking for fuel efficiency
- ✅ Payment history and event logging
- ✅ Quota validation and enforcement

## Contract Functions

### Administrative Functions

#### `initialize(admin: Address)`
Initialize the contract with an admin (Fleet Manager).
- **Parameters**: Admin address
- **Returns**: `Result<(), Error>`
- **Authorization**: None (first call only)

#### `set_driver_quota(admin: Address, driver: Address, quota: i128)`
Set or update a driver's fuel quota.
- **Parameters**: 
  - `admin`: Admin address
  - `driver`: Driver address
  - `quota`: Allocated fuel quota in smallest unit
- **Returns**: `Result<(), Error>`
- **Authorization**: Admin only

### Driver Functions

#### `pay_merchant(driver: Address, merchant: Address, amount: i128, driver_gps: (i128, i128))`
Process a fuel payment from driver to merchant.
- **Parameters**:
  - `driver`: Driver address
  - `merchant`: Merchant/station address
  - `amount`: Payment amount
  - `driver_gps`: GPS coordinates (latitude, longitude) in micro-degrees
- **Returns**: `Result<(), Error>`
- **Authorization**: Driver
- **Emits**: `FUELING` event

#### `update_odometer(driver: Address, odometer_reading: u64)`
Update driver's odometer reading.
- **Parameters**:
  - `driver`: Driver address
  - `odometer_reading`: Current odometer value
- **Returns**: `Result<(), Error>`
- **Authorization**: Driver

### Query Functions

#### `get_driver_quota(driver: Address)`
Get driver's quota information.
- **Parameters**: Driver address
- **Returns**: `Result<DriverQuota, Error>`

#### `get_payment_history(driver: Address, limit: u32)`
Get payment history for a driver.
- **Parameters**:
  - `driver`: Driver address
  - `limit`: Number of transactions to retrieve
- **Returns**: `Vec<Payment>`

## Data Structures

### Payment
```rust
struct Payment {
    driver: Address,
    merchant: Address,
    amount: i128,
    timestamp: u64,
}
```

### DriverQuota
```rust
struct DriverQuota {
    allocated_quota: i128,
    used_quota: i128,
    last_odometer_reading: u64,
}
```

## Error Codes

- `NotInitialized = 1`: Contract not initialized
- `AlreadyInitialized = 2`: Contract already initialized
- `Unauthorized = 3`: Caller not authorized
- `InsufficientQuota = 4`: Driver's quota insufficient
- `InvalidAmount = 5`: Invalid payment amount

## Events

### FUELING Event
Emitted when a payment is processed.
- **Topics**: `("FUELING", driver_address)`
- **Data**: `(merchant_address, amount, gps_coordinates)`

## Building

```bash
soroban contract build
```

## Testing

```bash
cargo test
```

## Deployment

### Testnet
```bash
soroban contract deploy \
  --wasm target/wasm32-unknown-unknown/release/fuel_lock.wasm \
  --source admin \
  --network testnet
```

### Initialize After Deployment
```bash
soroban contract invoke \
  --id <CONTRACT_ID> \
  --source admin \
  --network testnet \
  -- initialize \
  --admin <ADMIN_ADDRESS>
```

## Example Usage

### Set Driver Quota
```bash
soroban contract invoke \
  --id <CONTRACT_ID> \
  --source admin \
  --network testnet \
  -- set_driver_quota \
  --admin <ADMIN_ADDRESS> \
  --driver <DRIVER_ADDRESS> \
  --quota 100000000
```

### Process Payment
```bash
soroban contract invoke \
  --id <CONTRACT_ID> \
  --source driver \
  --network testnet \
  -- pay_merchant \
  --driver <DRIVER_ADDRESS> \
  --merchant <MERCHANT_ADDRESS> \
  --amount 5000000 \
  --driver_gps '(40748817, -73985428)'
```

### Check Quota
```bash
soroban contract invoke \
  --id <CONTRACT_ID> \
  --network testnet \
  -- get_driver_quota \
  --driver <DRIVER_ADDRESS>
```

## Security Considerations

1. **Authorization**: All sensitive operations require address authentication
2. **Quota Validation**: Automatic validation of remaining quota before payments
3. **GPS Verification**: All payments include GPS coordinates for audit trails
4. **Event Logging**: All transactions emit events for transparency

## License

See LICENSE file in root directory.
