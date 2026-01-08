//! Tests for the FUEL token contract

#![cfg(test)]

use super::*;
use soroban_sdk::{testutils::Address as _, Address, Env, String};
use crate::contract::{FuelToken, FuelTokenClient};

fn create_token<'a>(env: &Env, admin: &Address) -> FuelTokenClient<'a> {
    let contract_id = env.register_contract(None, FuelToken);
    let client = FuelTokenClient::new(env, &contract_id);
    client.initialize(
        admin,
        &7u32,
        &String::from_str(env, "FuelAnchor Token"),
        &String::from_str(env, "FUEL"),
    );
    client
}

#[test]
fn test_initialize() {
    let env = Env::default();
    env.mock_all_auths();
    
    let admin = Address::generate(&env);
    let token = create_token(&env, &admin);

    assert_eq!(token.decimals(), 7);
    assert_eq!(token.name(), String::from_str(&env, "FuelAnchor Token"));
    assert_eq!(token.symbol(), String::from_str(&env, "FUEL"));
    assert_eq!(token.admin(), admin);
}

#[test]
fn test_mint() {
    let env = Env::default();
    env.mock_all_auths();
    
    let admin = Address::generate(&env);
    let user = Address::generate(&env);
    let token = create_token(&env, &admin);

    token.mint(&user, &1000);
    assert_eq!(token.balance(&user), 1000);
}

#[test]
fn test_transfer() {
    let env = Env::default();
    env.mock_all_auths();
    
    let admin = Address::generate(&env);
    let user1 = Address::generate(&env);
    let user2 = Address::generate(&env);
    let token = create_token(&env, &admin);

    token.mint(&user1, &1000);
    token.transfer(&user1, &user2, &300);

    assert_eq!(token.balance(&user1), 700);
    assert_eq!(token.balance(&user2), 300);
}

#[test]
fn test_approval_and_transfer_from() {
    let env = Env::default();
    env.mock_all_auths();
    
    let admin = Address::generate(&env);
    let owner = Address::generate(&env);
    let spender = Address::generate(&env);
    let recipient = Address::generate(&env);
    let token = create_token(&env, &admin);

    token.mint(&owner, &1000);
    token.approve(&owner, &spender, &500, &1000000);
    
    assert_eq!(token.allowance(&owner, &spender), 500);
    
    token.transfer_from(&spender, &owner, &recipient, &200);
    
    assert_eq!(token.balance(&owner), 800);
    assert_eq!(token.balance(&recipient), 200);
    assert_eq!(token.allowance(&owner, &spender), 300);
}

#[test]
fn test_burn() {
    let env = Env::default();
    env.mock_all_auths();
    
    let admin = Address::generate(&env);
    let user = Address::generate(&env);
    let token = create_token(&env, &admin);

    token.mint(&user, &1000);
    token.burn(&user, &400);

    assert_eq!(token.balance(&user), 600);
}

#[test]
fn test_batch_mint() {
    let env = Env::default();
    env.mock_all_auths();
    
    let admin = Address::generate(&env);
    let user1 = Address::generate(&env);
    let user2 = Address::generate(&env);
    let user3 = Address::generate(&env);
    let token = create_token(&env, &admin);

    let recipients = soroban_sdk::vec![&env, user1.clone(), user2.clone(), user3.clone()];
    let amounts = soroban_sdk::vec![&env, 100i128, 200i128, 300i128];

    token.batch_mint(&recipients, &amounts);

    assert_eq!(token.balance(&user1), 100);
    assert_eq!(token.balance(&user2), 200);
    assert_eq!(token.balance(&user3), 300);
}

#[test]
fn test_clawback() {
    let env = Env::default();
    env.mock_all_auths();
    
    let admin = Address::generate(&env);
    let user = Address::generate(&env);
    let token = create_token(&env, &admin);

    token.mint(&user, &1000);
    token.clawback(&user, &400);

    assert_eq!(token.balance(&user), 600);
}

#[test]
#[should_panic(expected = "Insufficient balance")]
fn test_insufficient_balance() {
    let env = Env::default();
    env.mock_all_auths();
    
    let admin = Address::generate(&env);
    let user1 = Address::generate(&env);
    let user2 = Address::generate(&env);
    let token = create_token(&env, &admin);

    token.mint(&user1, &100);
    token.transfer(&user1, &user2, &200); // Should panic
}
