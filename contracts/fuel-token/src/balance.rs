//! Balance management for the FUEL token contract

use soroban_sdk::{Address, Env};

use crate::storage_types::{DataKey, BALANCE_BUMP_AMOUNT, BALANCE_LIFETIME_THRESHOLD};

/// Read the balance of an address
pub fn read_balance(env: &Env, addr: &Address) -> i128 {
    let key = DataKey::Balance(addr.clone());
    if let Some(balance) = env.storage().persistent().get::<DataKey, i128>(&key) {
        env.storage()
            .persistent()
            .extend_ttl(&key, BALANCE_LIFETIME_THRESHOLD, BALANCE_BUMP_AMOUNT);
        balance
    } else {
        0
    }
}

/// Write the balance of an address
fn write_balance(env: &Env, addr: &Address, amount: i128) {
    let key = DataKey::Balance(addr.clone());
    env.storage().persistent().set(&key, &amount);
    env.storage()
        .persistent()
        .extend_ttl(&key, BALANCE_LIFETIME_THRESHOLD, BALANCE_BUMP_AMOUNT);
}

/// Increase the balance of an address (for minting or receiving transfers)
pub fn receive_balance(env: &Env, addr: &Address, amount: i128) {
    let balance = read_balance(env, addr);
    write_balance(env, addr, balance + amount);
}

/// Decrease the balance of an address (for burning or sending transfers)
pub fn spend_balance(env: &Env, addr: &Address, amount: i128) {
    let balance = read_balance(env, addr);
    if balance < amount {
        panic!("Insufficient balance");
    }
    write_balance(env, addr, balance - amount);
}

/// Check if an address has sufficient balance
pub fn has_sufficient_balance(env: &Env, addr: &Address, amount: i128) -> bool {
    read_balance(env, addr) >= amount
}
