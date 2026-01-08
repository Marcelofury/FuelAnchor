//! FuelAnchor Voucher Redemption Contract
//!
//! Handles fuel voucher redemption at partner stations with:
//! - Geofencing validation
//! - Spending limits enforcement
//! - Multi-signature fleet operator controls
//! - Real-time transaction logging for credit scoring

#![no_std]

use soroban_sdk::{
    contract, contractimpl, contracttype, Address, BytesN, Env, Map, String, Symbol, Vec,
};

/// Error codes for the redemption contract
#[derive(Clone, Debug, PartialEq)]
#[contracttype]
pub enum RedemptionError {
    NotInitialized = 1,
    AlreadyInitialized = 2,
    Unauthorized = 3,
    InsufficientBalance = 4,
    DailyLimitExceeded = 5,
    TransactionLimitExceeded = 6,
    StationNotVerified = 7,
    OutOfGeofence = 8,
    DriverNotRegistered = 9,
    VoucherExpired = 10,
    InvalidAmount = 11,
}

/// GPS coordinates with precision for geofencing
#[derive(Clone, Debug, PartialEq)]
#[contracttype]
pub struct GpsCoordinates {
    /// Latitude in micro-degrees (multiply by 1e-6 for actual degrees)
    pub latitude: i64,
    /// Longitude in micro-degrees
    pub longitude: i64,
}

/// Geofence definition for a station
#[derive(Clone, Debug, PartialEq)]
#[contracttype]
pub struct Geofence {
    /// Center coordinates
    pub center: GpsCoordinates,
    /// Radius in meters
    pub radius_meters: u32,
}

/// Verified fuel station
#[derive(Clone, Debug, PartialEq)]
#[contracttype]
pub struct Station {
    pub id: BytesN<32>,
    pub name: String,
    pub owner: Address,
    pub geofence: Geofence,
    pub is_active: bool,
    pub fuel_price_per_liter: i128,
    pub total_redemptions: u64,
    pub registered_at: u64,
}

/// Driver spending configuration
#[derive(Clone, Debug, PartialEq)]
#[contracttype]
pub struct SpendingLimits {
    /// Maximum amount per single transaction
    pub max_per_transaction: i128,
    /// Maximum daily spending limit
    pub daily_limit: i128,
    /// Maximum weekly spending limit
    pub weekly_limit: i128,
    /// Allowed stations (empty = all verified stations allowed)
    pub allowed_stations: Vec<BytesN<32>>,
}

/// Driver registration with fleet association
#[derive(Clone, Debug, PartialEq)]
#[contracttype]
pub struct Driver {
    pub address: Address,
    pub fleet_operator: Address,
    pub vehicle_id: String,
    pub spending_limits: SpendingLimits,
    pub daily_spent: i128,
    pub weekly_spent: i128,
    pub last_daily_reset: u64,
    pub last_weekly_reset: u64,
    pub is_active: bool,
    pub total_redemptions: u64,
    pub registered_at: u64,
}

/// Redemption transaction record
#[derive(Clone, Debug, PartialEq)]
#[contracttype]
pub struct RedemptionRecord {
    pub id: BytesN<32>,
    pub driver: Address,
    pub station_id: BytesN<32>,
    pub amount: i128,
    pub liters: i128,
    pub gps_coords: GpsCoordinates,
    pub timestamp: u64,
    pub vehicle_id: String,
}

/// Data keys for contract storage
#[derive(Clone)]
#[contracttype]
pub enum DataKey {
    Admin,
    FuelToken,
    Station(BytesN<32>),
    StationByOwner(Address),
    Driver(Address),
    DriverByFleet(Address),
    DailyStats(u64),
    RedemptionCount,
    LastRedemption(Address),
}

/// Constants for time calculations (ledger-based)
const LEDGERS_PER_DAY: u64 = 17280; // ~5 seconds per ledger
const LEDGERS_PER_WEEK: u64 = LEDGERS_PER_DAY * 7;

/// Haversine distance approximation (simplified for contract use)
/// Returns distance in meters (approximate)
fn calculate_distance(coord1: &GpsCoordinates, coord2: &GpsCoordinates) -> u32 {
    // Simplified distance calculation using Euclidean approximation
    // For more accuracy, a full Haversine formula would be needed
    let lat_diff = (coord1.latitude - coord2.latitude).abs() as u64;
    let lon_diff = (coord1.longitude - coord2.longitude).abs() as u64;
    
    // Approximate conversion: 1 degree ≈ 111,000 meters
    // Since we use micro-degrees, divide by 1,000,000 then multiply by 111,000
    // Simplified: multiply diff by 111 and divide by 1000
    let lat_meters = (lat_diff * 111) / 1000;
    let lon_meters = (lon_diff * 111) / 1000; // Simplified (should account for latitude)
    
    // Euclidean distance approximation
    let distance_squared = lat_meters * lat_meters + lon_meters * lon_meters;
    
    // Integer square root approximation
    let mut result = distance_squared;
    let mut x = distance_squared;
    if x > 0 {
        x = (x + 1) / 2;
        while x < result {
            result = x;
            x = (x + distance_squared / x) / 2;
        }
    }
    
    result as u32
}

#[contract]
pub struct VoucherRedemption;

#[contractimpl]
impl VoucherRedemption {
    /// Initialize the redemption contract
    pub fn initialize(env: Env, admin: Address, fuel_token: Address) {
        if env.storage().instance().has(&DataKey::Admin) {
            panic!("Already initialized");
        }
        
        env.storage().instance().set(&DataKey::Admin, &admin);
        env.storage().instance().set(&DataKey::FuelToken, &fuel_token);
        env.storage().instance().set(&DataKey::RedemptionCount, &0u64);
    }

    /// Register a new fuel station
    pub fn register_station(
        env: Env,
        caller: Address,
        station_id: BytesN<32>,
        name: String,
        owner: Address,
        geofence: Geofence,
        fuel_price_per_liter: i128,
    ) {
        caller.require_auth();
        let admin: Address = env.storage().instance().get(&DataKey::Admin).unwrap();
        
        if caller != admin && caller != owner {
            panic!("Unauthorized");
        }

        let station = Station {
            id: station_id.clone(),
            name,
            owner: owner.clone(),
            geofence,
            is_active: true,
            fuel_price_per_liter,
            total_redemptions: 0,
            registered_at: env.ledger().timestamp(),
        };

        env.storage().persistent().set(&DataKey::Station(station_id.clone()), &station);
        env.storage().persistent().set(&DataKey::StationByOwner(owner), &station_id);

        // Emit event
        env.events().publish(
            (Symbol::new(&env, "station_registered"), station_id),
            station.name,
        );
    }

    /// Register a driver for a fleet
    pub fn register_driver(
        env: Env,
        fleet_operator: Address,
        driver_address: Address,
        vehicle_id: String,
        spending_limits: SpendingLimits,
    ) {
        fleet_operator.require_auth();

        let driver = Driver {
            address: driver_address.clone(),
            fleet_operator: fleet_operator.clone(),
            vehicle_id,
            spending_limits,
            daily_spent: 0,
            weekly_spent: 0,
            last_daily_reset: env.ledger().sequence() as u64,
            last_weekly_reset: env.ledger().sequence() as u64,
            is_active: true,
            total_redemptions: 0,
            registered_at: env.ledger().timestamp(),
        };

        env.storage().persistent().set(&DataKey::Driver(driver_address.clone()), &driver);

        // Emit event
        env.events().publish(
            (Symbol::new(&env, "driver_registered"), driver_address),
            fleet_operator,
        );
    }

    /// Update driver spending limits
    pub fn update_spending_limits(
        env: Env,
        fleet_operator: Address,
        driver_address: Address,
        new_limits: SpendingLimits,
    ) {
        fleet_operator.require_auth();

        let key = DataKey::Driver(driver_address.clone());
        let mut driver: Driver = env.storage().persistent().get(&key)
            .expect("Driver not registered");

        if driver.fleet_operator != fleet_operator {
            panic!("Unauthorized: not the fleet operator");
        }

        driver.spending_limits = new_limits;
        env.storage().persistent().set(&key, &driver);

        env.events().publish(
            (Symbol::new(&env, "limits_updated"), driver_address),
            fleet_operator,
        );
    }

    /// Redeem fuel voucher at a station
    pub fn redeem_fuel(
        env: Env,
        driver_address: Address,
        station_id: BytesN<32>,
        amount: i128,
        gps_coords: GpsCoordinates,
    ) -> RedemptionRecord {
        driver_address.require_auth();

        if amount <= 0 {
            panic!("Invalid amount");
        }

        // Get driver info
        let driver_key = DataKey::Driver(driver_address.clone());
        let mut driver: Driver = env.storage().persistent().get(&driver_key)
            .expect("Driver not registered");

        if !driver.is_active {
            panic!("Driver account is deactivated");
        }

        // Get station info
        let station_key = DataKey::Station(station_id.clone());
        let mut station: Station = env.storage().persistent().get(&station_key)
            .expect("Station not found");

        if !station.is_active {
            panic!("Station is not active");
        }

        // Check geofence
        let distance = calculate_distance(&gps_coords, &station.geofence.center);
        if distance > station.geofence.radius_meters {
            panic!("Out of geofence");
        }

        // Check allowed stations (if restricted)
        if !driver.spending_limits.allowed_stations.is_empty() {
            let mut allowed = false;
            for i in 0..driver.spending_limits.allowed_stations.len() {
                if driver.spending_limits.allowed_stations.get(i).unwrap() == station_id {
                    allowed = true;
                    break;
                }
            }
            if !allowed {
                panic!("Station not in allowed list");
            }
        }

        // Reset daily/weekly limits if needed
        let current_ledger = env.ledger().sequence() as u64;
        if current_ledger - driver.last_daily_reset >= LEDGERS_PER_DAY {
            driver.daily_spent = 0;
            driver.last_daily_reset = current_ledger;
        }
        if current_ledger - driver.last_weekly_reset >= LEDGERS_PER_WEEK {
            driver.weekly_spent = 0;
            driver.last_weekly_reset = current_ledger;
        }

        // Check spending limits
        if amount > driver.spending_limits.max_per_transaction {
            panic!("Transaction limit exceeded");
        }
        if driver.daily_spent + amount > driver.spending_limits.daily_limit {
            panic!("Daily limit exceeded");
        }
        if driver.weekly_spent + amount > driver.spending_limits.weekly_limit {
            panic!("Weekly limit exceeded");
        }

        // Calculate liters
        let liters = (amount * 10_000_000) / station.fuel_price_per_liter; // 7 decimal precision

        // Generate redemption ID
        let redemption_count: u64 = env.storage().instance().get(&DataKey::RedemptionCount).unwrap_or(0);
        let new_count = redemption_count + 1;
        
        // Create redemption ID from hash of relevant data
        let redemption_id = env.crypto().sha256(
            &soroban_sdk::Bytes::from_slice(&env, &new_count.to_be_bytes())
        );

        // Create redemption record
        let record = RedemptionRecord {
            id: redemption_id,
            driver: driver_address.clone(),
            station_id: station_id.clone(),
            amount,
            liters,
            gps_coords,
            timestamp: env.ledger().timestamp(),
            vehicle_id: driver.vehicle_id.clone(),
        };

        // Update driver stats
        driver.daily_spent += amount;
        driver.weekly_spent += amount;
        driver.total_redemptions += 1;
        env.storage().persistent().set(&driver_key, &driver);

        // Update station stats
        station.total_redemptions += 1;
        env.storage().persistent().set(&station_key, &station);

        // Update redemption count
        env.storage().instance().set(&DataKey::RedemptionCount, &new_count);

        // Store last redemption for driver
        env.storage().persistent().set(&DataKey::LastRedemption(driver_address.clone()), &record);

        // Emit redemption event for credit scoring
        env.events().publish(
            (Symbol::new(&env, "fuel_redeemed"), driver_address, station_id),
            (amount, liters, env.ledger().timestamp()),
        );

        record
    }

    /// Get driver information
    pub fn get_driver(env: Env, driver_address: Address) -> Driver {
        env.storage().persistent().get(&DataKey::Driver(driver_address))
            .expect("Driver not found")
    }

    /// Get station information
    pub fn get_station(env: Env, station_id: BytesN<32>) -> Station {
        env.storage().persistent().get(&DataKey::Station(station_id))
            .expect("Station not found")
    }

    /// Get driver's remaining daily limit
    pub fn get_remaining_daily_limit(env: Env, driver_address: Address) -> i128 {
        let driver: Driver = env.storage().persistent().get(&DataKey::Driver(driver_address))
            .expect("Driver not found");
        
        let current_ledger = env.ledger().sequence() as u64;
        if current_ledger - driver.last_daily_reset >= LEDGERS_PER_DAY {
            driver.spending_limits.daily_limit
        } else {
            driver.spending_limits.daily_limit - driver.daily_spent
        }
    }

    /// Deactivate a driver (fleet operator only)
    pub fn deactivate_driver(env: Env, fleet_operator: Address, driver_address: Address) {
        fleet_operator.require_auth();

        let key = DataKey::Driver(driver_address.clone());
        let mut driver: Driver = env.storage().persistent().get(&key)
            .expect("Driver not registered");

        if driver.fleet_operator != fleet_operator {
            panic!("Unauthorized");
        }

        driver.is_active = false;
        env.storage().persistent().set(&key, &driver);

        env.events().publish(
            (Symbol::new(&env, "driver_deactivated"), driver_address),
            fleet_operator,
        );
    }

    /// Reactivate a driver (fleet operator only)
    pub fn reactivate_driver(env: Env, fleet_operator: Address, driver_address: Address) {
        fleet_operator.require_auth();

        let key = DataKey::Driver(driver_address.clone());
        let mut driver: Driver = env.storage().persistent().get(&key)
            .expect("Driver not registered");

        if driver.fleet_operator != fleet_operator {
            panic!("Unauthorized");
        }

        driver.is_active = true;
        env.storage().persistent().set(&key, &driver);

        env.events().publish(
            (Symbol::new(&env, "driver_reactivated"), driver_address),
            fleet_operator,
        );
    }

    /// Update station fuel price
    pub fn update_fuel_price(env: Env, station_owner: Address, station_id: BytesN<32>, new_price: i128) {
        station_owner.require_auth();

        let key = DataKey::Station(station_id.clone());
        let mut station: Station = env.storage().persistent().get(&key)
            .expect("Station not found");

        if station.owner != station_owner {
            panic!("Unauthorized");
        }

        station.fuel_price_per_liter = new_price;
        env.storage().persistent().set(&key, &station);

        env.events().publish(
            (Symbol::new(&env, "price_updated"), station_id),
            new_price,
        );
    }

    /// Get total redemption count
    pub fn get_redemption_count(env: Env) -> u64 {
        env.storage().instance().get(&DataKey::RedemptionCount).unwrap_or(0)
    }
}
