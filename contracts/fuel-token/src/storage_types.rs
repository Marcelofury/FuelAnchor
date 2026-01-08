//! Storage type definitions for the FUEL token contract

use soroban_sdk::{contracttype, Address};

/// Data keys for persistent storage
#[derive(Clone)]
#[contracttype]
pub enum DataKey {
    /// Token allowance: (owner, spender) -> amount
    Allowance(AllowanceDataKey),
    /// Token balance for an address
    Balance(Address),
    /// Nonce for replay protection
    Nonce(Address),
    /// Admin state
    State(Address),
    /// Contract admin address
    Admin,
}

/// Allowance storage key
#[derive(Clone)]
#[contracttype]
pub struct AllowanceDataKey {
    pub from: Address,
    pub spender: Address,
}

/// Allowance value with expiration
#[derive(Clone)]
#[contracttype]
pub struct AllowanceValue {
    pub amount: i128,
    pub expiration_ledger: u32,
}

/// Token metadata structure
#[derive(Clone)]
#[contracttype]
pub struct TokenMetadata {
    pub decimal: u32,
    pub name: soroban_sdk::String,
    pub symbol: soroban_sdk::String,
}

/// Fleet operator spending rules
#[derive(Clone)]
#[contracttype]
pub struct SpendingRule {
    /// Maximum amount per transaction
    pub max_per_tx: i128,
    /// Maximum amount per day
    pub daily_limit: i128,
    /// Allowed station addresses (empty = all allowed)
    pub allowed_stations: soroban_sdk::Vec<Address>,
    /// Expiration timestamp
    pub expires_at: u64,
}

/// Driver wallet configuration
#[derive(Clone)]
#[contracttype]
pub struct DriverWallet {
    pub driver: Address,
    pub fleet_operator: Address,
    pub spending_rule: SpendingRule,
    pub daily_spent: i128,
    pub last_reset_day: u64,
}

pub const DAY_LEDGERS: u32 = 17280; // ~1 day in ledgers (5 sec/ledger)
pub const INSTANCE_BUMP_AMOUNT: u32 = 7 * DAY_LEDGERS;
pub const INSTANCE_LIFETIME_THRESHOLD: u32 = INSTANCE_BUMP_AMOUNT - DAY_LEDGERS;

pub const BALANCE_BUMP_AMOUNT: u32 = 30 * DAY_LEDGERS;
pub const BALANCE_LIFETIME_THRESHOLD: u32 = BALANCE_BUMP_AMOUNT - DAY_LEDGERS;
