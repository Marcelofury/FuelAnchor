//! Allowance management for the FUEL token contract

use soroban_sdk::{Address, Env};

use crate::storage_types::{
    AllowanceDataKey, AllowanceValue, DataKey, BALANCE_BUMP_AMOUNT, BALANCE_LIFETIME_THRESHOLD,
};

/// Read the allowance for a spender from an owner
pub fn read_allowance(env: &Env, from: &Address, spender: &Address) -> AllowanceValue {
    let key = DataKey::Allowance(AllowanceDataKey {
        from: from.clone(),
        spender: spender.clone(),
    });
    if let Some(allowance) = env.storage().persistent().get::<DataKey, AllowanceValue>(&key) {
        if allowance.expiration_ledger < env.ledger().sequence() {
            AllowanceValue {
                amount: 0,
                expiration_ledger: allowance.expiration_ledger,
            }
        } else {
            env.storage()
                .persistent()
                .extend_ttl(&key, BALANCE_LIFETIME_THRESHOLD, BALANCE_BUMP_AMOUNT);
            allowance
        }
    } else {
        AllowanceValue {
            amount: 0,
            expiration_ledger: 0,
        }
    }
}

/// Write an allowance for a spender from an owner
pub fn write_allowance(
    env: &Env,
    from: &Address,
    spender: &Address,
    amount: i128,
    expiration_ledger: u32,
) {
    let allowance = AllowanceValue {
        amount,
        expiration_ledger,
    };

    if amount > 0 && expiration_ledger < env.ledger().sequence() {
        panic!("Expiration ledger is in the past");
    }

    let key = DataKey::Allowance(AllowanceDataKey {
        from: from.clone(),
        spender: spender.clone(),
    });
    env.storage().persistent().set(&key, &allowance);

    if amount > 0 {
        let ledgers_to_live = expiration_ledger
            .checked_sub(env.ledger().sequence())
            .unwrap();
        env.storage()
            .persistent()
            .extend_ttl(&key, ledgers_to_live, ledgers_to_live);
    }
}

/// Spend from an allowance, reducing the amount
pub fn spend_allowance(env: &Env, from: &Address, spender: &Address, amount: i128) {
    let allowance = read_allowance(env, from, spender);
    if allowance.amount < amount {
        panic!("Insufficient allowance");
    }
    if amount > 0 {
        write_allowance(
            env,
            from,
            spender,
            allowance.amount - amount,
            allowance.expiration_ledger,
        );
    }
}
