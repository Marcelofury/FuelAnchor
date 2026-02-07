#![no_std]

use soroban_sdk::{
    contract, contracterror, contractimpl, contracttype,
    log, symbol_short, vec, Address, Env, Symbol, Vec,
};

/// Error codes for the FuelLock contract
#[contracterror]
#[derive(Copy, Clone, Debug, Eq, PartialEq, PartialOrd, Ord)]
#[repr(u32)]
pub enum Error {
    NotInitialized = 1,
    AlreadyInitialized = 2,
    Unauthorized = 3,
    InsufficientQuota = 4,
    InvalidAmount = 5,
}

/// Storage keys
const ADMIN: Symbol = symbol_short!("ADMIN");
const IS_INIT: Symbol = symbol_short!("IS_INIT");

/// Payment record structure
#[contracttype]
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct Payment {
    pub driver: Address,
    pub merchant: Address,
    pub amount: i128,
    pub timestamp: u64,
}

/// Driver quota information
#[contracttype]
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct DriverQuota {
    pub allocated_quota: i128,
    pub used_quota: i128,
    pub last_odometer_reading: u64,
}

#[contract]
pub struct FuelLockContract;

#[contractimpl]
impl FuelLockContract {
    /// Initialize the contract with an admin (Fleet Manager)
    pub fn initialize(env: Env, admin: Address) -> Result<(), Error> {
        if env.storage().instance().has(&IS_INIT) {
            return Err(Error::AlreadyInitialized);
        }

        // Set the admin
        env.storage().instance().set(&ADMIN, &admin);
        env.storage().instance().set(&IS_INIT, &true);

        log!(
            &env,
            "FuelLock initialized with admin: {}",
            admin
        );

        Ok(())
    }

    /// Set or update a driver's fuel quota
    /// Only admin can call this function
    pub fn set_driver_quota(
        env: Env,
        admin: Address,
        driver: Address,
        quota: i128,
    ) -> Result<(), Error> {
        // Verify admin
        admin.require_auth();
        let stored_admin: Address = env
            .storage()
            .instance()
            .get(&ADMIN)
            .ok_or(Error::NotInitialized)?;

        if admin != stored_admin {
            return Err(Error::Unauthorized);
        }

        // Get existing quota or create new
        let driver_key = (symbol_short!("QUOTA"), driver.clone());
        let mut driver_quota = env
            .storage()
            .persistent()
            .get::<(Symbol, Address), DriverQuota>(&driver_key)
            .unwrap_or(DriverQuota {
                allocated_quota: 0,
                used_quota: 0,
                last_odometer_reading: 0,
            });

        driver_quota.allocated_quota = quota;
        env.storage().persistent().set(&driver_key, &driver_quota);

        log!(
            &env,
            "Quota set for driver: {}, amount: {}",
            driver,
            quota
        );

        Ok(())
    }

    /// Process a fuel payment from driver to merchant
    pub fn pay_merchant(
        env: Env,
        driver: Address,
        merchant: Address,
        amount: i128,
        driver_gps: (i128, i128), // (latitude, longitude) in micro-degrees
    ) -> Result<(), Error> {
        // Require driver authentication
        driver.require_auth();

        // Validate amount
        if amount <= 0 {
            return Err(Error::InvalidAmount);
        }

        // Get driver's quota
        let driver_key = (symbol_short!("QUOTA"), driver.clone());
        let mut driver_quota = env
            .storage()
            .persistent()
            .get::<(Symbol, Address), DriverQuota>(&driver_key)
            .ok_or(Error::InsufficientQuota)?;

        // Check if driver has sufficient quota
        let remaining_quota = driver_quota.allocated_quota - driver_quota.used_quota;
        if remaining_quota < amount {
            return Err(Error::InsufficientQuota);
        }

        // Update used quota
        driver_quota.used_quota += amount;
        env.storage().persistent().set(&driver_key, &driver_quota);

        // Create payment record
        let payment = Payment {
            driver: driver.clone(),
            merchant: merchant.clone(),
            amount,
            timestamp: env.ledger().timestamp(),
        };

        // Store payment record
        let payment_key = (
            symbol_short!("PAYMENT"),
            env.ledger().sequence(),
        );
        env.storage().persistent().set(&payment_key, &payment);

        // Emit fueling event
        env.events().publish(
            (symbol_short!("FUELING"), driver.clone()),
            (merchant.clone(), amount, driver_gps),
        );

        log!(
            &env,
            "Payment processed: driver={}, merchant={}, amount={}",
            driver,
            merchant,
            amount
        );

        Ok(())
    }

    /// Update driver's odometer reading
    /// This can be used to calculate fuel efficiency and validate fuel quota
    pub fn update_odometer(
        env: Env,
        driver: Address,
        odometer_reading: u64,
    ) -> Result<(), Error> {
        driver.require_auth();

        let driver_key = (symbol_short!("QUOTA"), driver.clone());
        let mut driver_quota = env
            .storage()
            .persistent()
            .get::<(Symbol, Address), DriverQuota>(&driver_key)
            .ok_or(Error::NotInitialized)?;

        driver_quota.last_odometer_reading = odometer_reading;
        env.storage().persistent().set(&driver_key, &driver_quota);

        log!(
            &env,
            "Odometer updated for driver: {}, reading: {}",
            driver,
            odometer_reading
        );

        Ok(())
    }

    /// Get driver's quota information
    pub fn get_driver_quota(env: Env, driver: Address) -> Result<DriverQuota, Error> {
        let driver_key = (symbol_short!("QUOTA"), driver);
        env.storage()
            .persistent()
            .get::<(Symbol, Address), DriverQuota>(&driver_key)
            .ok_or(Error::NotInitialized)
    }

    /// Get payment history for a driver
    pub fn get_payment_history(
        env: Env,
        driver: Address,
        limit: u32,
    ) -> Vec<Payment> {
        let mut payments = vec![&env];
        let current_sequence = env.ledger().sequence();
        let start_sequence = current_sequence.saturating_sub(limit as u32);

        for seq in start_sequence..current_sequence {
            let payment_key = (symbol_short!("PAYMENT"), seq);
            if let Some(payment) = env
                .storage()
                .persistent()
                .get::<(Symbol, u32), Payment>(&payment_key)
            {
                if payment.driver == driver {
                    payments.push_back(payment);
                }
            }
        }

        payments
    }
}

#[cfg(test)]
mod test {
    use super::*;
    use soroban_sdk::{testutils::Address as _, Address, Env};

    #[test]
    fn test_initialize() {
        let env = Env::default();
        let contract_id = env.register_contract(None, FuelLockContract);
        let client = FuelLockContractClient::new(&env, &contract_id);

        let admin = Address::generate(&env);

        client.initialize(&admin);

        // Try to initialize again - should fail
        let result = client.try_initialize(&admin);
        assert_eq!(result, Err(Ok(Error::AlreadyInitialized)));
    }

    #[test]
    fn test_set_driver_quota() {
        let env = Env::default();
        let contract_id = env.register_contract(None, FuelLockContract);
        let client = FuelLockContractClient::new(&env, &contract_id);

        let admin = Address::generate(&env);
        let driver = Address::generate(&env);

        client.initialize(&admin);
        client.set_driver_quota(&admin, &driver, &1000);

        let quota = client.get_driver_quota(&driver);
        assert_eq!(quota.allocated_quota, 1000);
        assert_eq!(quota.used_quota, 0);
    }

    #[test]
    fn test_payment() {
        let env = Env::default();
        env.mock_all_auths();

        let contract_id = env.register_contract(None, FuelLockContract);
        let client = FuelLockContractClient::new(&env, &contract_id);

        let admin = Address::generate(&env);
        let driver = Address::generate(&env);
        let merchant = Address::generate(&env);

        // Initialize and set quota
        client.initialize(&admin);
        client.set_driver_quota(&admin, &driver, &1000);

        // Make payment
        let gps_coords = (40_748_817, -73_985_428); // NYC coordinates in micro-degrees
        client.pay_merchant(&driver, &merchant, &50, &gps_coords);

        // Check quota was deducted
        let quota = client.get_driver_quota(&driver);
        assert_eq!(quota.used_quota, 50);
        assert_eq!(quota.allocated_quota, 1000);

        // Try payment with insufficient quota
        let result = client.try_pay_merchant(&driver, &merchant, &1000, &gps_coords);
        assert_eq!(result, Err(Ok(Error::InsufficientQuota)));
    }

    #[test]
    fn test_odometer_update() {
        let env = Env::default();
        env.mock_all_auths();

        let contract_id = env.register_contract(None, FuelLockContract);
        let client = FuelLockContractClient::new(&env, &contract_id);

        let admin = Address::generate(&env);
        let driver = Address::generate(&env);

        client.initialize(&admin);
        client.set_driver_quota(&admin, &driver, &1000);
        client.update_odometer(&driver, &50000);

        let quota = client.get_driver_quota(&driver);
        assert_eq!(quota.last_odometer_reading, 50000);
    }
}
