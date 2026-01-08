//! Admin functionality for the FUEL token contract

use soroban_sdk::{Address, Env};

use crate::storage_types::{DataKey, INSTANCE_BUMP_AMOUNT, INSTANCE_LIFETIME_THRESHOLD};

/// Check if there is an admin set for the contract
pub fn has_admin(env: &Env) -> bool {
    let key = DataKey::Admin;
    env.storage().instance().has(&key)
}

/// Read the admin address from storage
pub fn read_admin(env: &Env) -> Address {
    let key = DataKey::Admin;
    env.storage().instance().get(&key).unwrap()
}

/// Write the admin address to storage
pub fn write_admin(env: &Env, id: &Address) {
    let key = DataKey::Admin;
    env.storage().instance().set(&key, id);
}

/// Extend the TTL of the instance storage
pub fn extend_instance_ttl(env: &Env) {
    env.storage()
        .instance()
        .extend_ttl(INSTANCE_LIFETIME_THRESHOLD, INSTANCE_BUMP_AMOUNT);
}

/// Check if the given address is the admin, panic if not
pub fn require_admin(env: &Env, address: &Address) {
    let admin = read_admin(env);
    if admin != *address {
        panic!("Unauthorized: caller is not admin");
    }
    address.require_auth();
}
