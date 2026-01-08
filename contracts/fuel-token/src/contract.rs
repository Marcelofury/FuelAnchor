//! Main FUEL Token Contract
//! 
//! SEP-41 compliant fungible token for the FuelAnchor fuel voucher system.
//! Enables fleet operators to issue tokenized fuel credits to drivers.

use soroban_sdk::{contract, contractimpl, Address, Env, String};
use soroban_token_sdk::TokenUtils;

use crate::admin::{extend_instance_ttl, has_admin, read_admin, require_admin, write_admin};
use crate::allowance::{read_allowance, spend_allowance, write_allowance};
use crate::balance::{read_balance, receive_balance, spend_balance};
use crate::metadata::{read_decimal, read_name, read_symbol, write_metadata};
use crate::storage_types::TokenMetadata;

/// Event topics for token operations
fn emit_transfer(env: &Env, from: &Address, to: &Address, amount: i128) {
    let topics = (soroban_sdk::Symbol::new(env, "transfer"), from, to);
    env.events().publish(topics, amount);
}

fn emit_approval(env: &Env, from: &Address, spender: &Address, amount: i128, expiration: u32) {
    let topics = (soroban_sdk::Symbol::new(env, "approve"), from, spender);
    env.events().publish(topics, (amount, expiration));
}

fn emit_mint(env: &Env, admin: &Address, to: &Address, amount: i128) {
    let topics = (soroban_sdk::Symbol::new(env, "mint"), admin, to);
    env.events().publish(topics, amount);
}

fn emit_burn(env: &Env, from: &Address, amount: i128) {
    let topics = (soroban_sdk::Symbol::new(env, "burn"), from);
    env.events().publish(topics, amount);
}

fn emit_set_admin(env: &Env, old_admin: &Address, new_admin: &Address) {
    let topics = (soroban_sdk::Symbol::new(env, "set_admin"), old_admin);
    env.events().publish(topics, new_admin);
}

/// Check nonces for replay protection
fn check_nonce(env: &Env, id: &Address) -> i128 {
    let key = crate::storage_types::DataKey::Nonce(id.clone());
    env.storage().persistent().get(&key).unwrap_or(0)
}

/// Validate and update amount
fn check_non_negative_amount(amount: i128) {
    if amount < 0 {
        panic!("Negative amount not allowed");
    }
}

/// The FuelAnchor FUEL Token Contract
#[contract]
pub struct FuelToken;

#[contractimpl]
impl FuelToken {
    /// Initialize the token contract with admin and metadata
    pub fn initialize(env: Env, admin: Address, decimal: u32, name: String, symbol: String) {
        if has_admin(&env) {
            panic!("Already initialized");
        }

        write_admin(&env, &admin);
        write_metadata(
            &env,
            TokenMetadata {
                decimal,
                name,
                symbol,
            },
        );
    }

    // ==================== SEP-41 Token Interface ====================

    /// Get the allowance for a spender from an owner
    pub fn allowance(env: Env, from: Address, spender: Address) -> i128 {
        extend_instance_ttl(&env);
        read_allowance(&env, &from, &spender).amount
    }

    /// Approve a spender to spend tokens on behalf of the caller
    pub fn approve(env: Env, from: Address, spender: Address, amount: i128, expiration_ledger: u32) {
        from.require_auth();
        check_non_negative_amount(amount);
        extend_instance_ttl(&env);
        write_allowance(&env, &from, &spender, amount, expiration_ledger);
        emit_approval(&env, &from, &spender, amount, expiration_ledger);
    }

    /// Get the balance of an address
    pub fn balance(env: Env, id: Address) -> i128 {
        extend_instance_ttl(&env);
        read_balance(&env, &id)
    }

    /// Transfer tokens from the caller to another address
    pub fn transfer(env: Env, from: Address, to: Address, amount: i128) {
        from.require_auth();
        check_non_negative_amount(amount);
        extend_instance_ttl(&env);
        spend_balance(&env, &from, amount);
        receive_balance(&env, &to, amount);
        emit_transfer(&env, &from, &to, amount);
    }

    /// Transfer tokens from one address to another using an allowance
    pub fn transfer_from(env: Env, spender: Address, from: Address, to: Address, amount: i128) {
        spender.require_auth();
        check_non_negative_amount(amount);
        extend_instance_ttl(&env);
        spend_allowance(&env, &from, &spender, amount);
        spend_balance(&env, &from, amount);
        receive_balance(&env, &to, amount);
        emit_transfer(&env, &from, &to, amount);
    }

    /// Burn tokens from an address (requires authorization)
    pub fn burn(env: Env, from: Address, amount: i128) {
        from.require_auth();
        check_non_negative_amount(amount);
        extend_instance_ttl(&env);
        spend_balance(&env, &from, amount);
        emit_burn(&env, &from, amount);
    }

    /// Burn tokens from an address using an allowance
    pub fn burn_from(env: Env, spender: Address, from: Address, amount: i128) {
        spender.require_auth();
        check_non_negative_amount(amount);
        extend_instance_ttl(&env);
        spend_allowance(&env, &from, &spender, amount);
        spend_balance(&env, &from, amount);
        emit_burn(&env, &from, amount);
    }

    /// Get the number of decimals for the token
    pub fn decimals(env: Env) -> u32 {
        read_decimal(&env)
    }

    /// Get the name of the token
    pub fn name(env: Env) -> String {
        read_name(&env)
    }

    /// Get the symbol of the token
    pub fn symbol(env: Env) -> String {
        read_symbol(&env)
    }

    // ==================== Admin Functions ====================

    /// Mint new tokens (admin only)
    pub fn mint(env: Env, to: Address, amount: i128) {
        check_non_negative_amount(amount);
        let admin = read_admin(&env);
        admin.require_auth();
        extend_instance_ttl(&env);
        receive_balance(&env, &to, amount);
        emit_mint(&env, &admin, &to, amount);
    }

    /// Set a new admin (current admin only)
    pub fn set_admin(env: Env, new_admin: Address) {
        extend_instance_ttl(&env);
        let old_admin = read_admin(&env);
        require_admin(&env, &old_admin);
        write_admin(&env, &new_admin);
        emit_set_admin(&env, &old_admin, &new_admin);
    }

    /// Get the current admin address
    pub fn admin(env: Env) -> Address {
        extend_instance_ttl(&env);
        read_admin(&env)
    }

    // ==================== FuelAnchor Specific Functions ====================

    /// Batch mint tokens to multiple addresses (for fleet distribution)
    pub fn batch_mint(env: Env, recipients: soroban_sdk::Vec<Address>, amounts: soroban_sdk::Vec<i128>) {
        let admin = read_admin(&env);
        admin.require_auth();
        extend_instance_ttl(&env);

        if recipients.len() != amounts.len() {
            panic!("Recipients and amounts length mismatch");
        }

        for i in 0..recipients.len() {
            let to = recipients.get(i).unwrap();
            let amount = amounts.get(i).unwrap();
            check_non_negative_amount(amount);
            receive_balance(&env, &to, amount);
            emit_mint(&env, &admin, &to, amount);
        }
    }

    /// Clawback tokens from an address (admin only, for fraud prevention)
    pub fn clawback(env: Env, from: Address, amount: i128) {
        check_non_negative_amount(amount);
        let admin = read_admin(&env);
        admin.require_auth();
        extend_instance_ttl(&env);
        spend_balance(&env, &from, amount);
        
        let topics = (soroban_sdk::Symbol::new(&env, "clawback"), &admin, &from);
        env.events().publish(topics, amount);
    }
}
