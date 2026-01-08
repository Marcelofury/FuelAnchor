//! Token metadata for the FUEL token

use soroban_sdk::{Env, String};

use crate::storage_types::TokenMetadata;

pub const DECIMALS: u32 = 7;

/// Token metadata keys in instance storage
#[derive(Clone)]
#[soroban_sdk::contracttype]
pub enum MetadataKey {
    Metadata,
}

/// Initialize token metadata
pub fn write_metadata(env: &Env, metadata: TokenMetadata) {
    env.storage()
        .instance()
        .set(&MetadataKey::Metadata, &metadata);
}

/// Read token metadata
pub fn read_metadata(env: &Env) -> TokenMetadata {
    env.storage()
        .instance()
        .get(&MetadataKey::Metadata)
        .unwrap_or(TokenMetadata {
            decimal: DECIMALS,
            name: String::from_str(env, "FuelAnchor Token"),
            symbol: String::from_str(env, "FUEL"),
        })
}

/// Get token decimals
pub fn read_decimal(env: &Env) -> u32 {
    read_metadata(env).decimal
}

/// Get token name
pub fn read_name(env: &Env) -> String {
    read_metadata(env).name
}

/// Get token symbol
pub fn read_symbol(env: &Env) -> String {
    read_metadata(env).symbol
}
