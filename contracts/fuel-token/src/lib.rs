//! FuelAnchor FUEL Token Contract
//! 
//! SEP-41 compliant fungible token for fuel vouchers on the Stellar network.
//! This token represents pre-paid fuel credits that can be redeemed at partner stations.

#![no_std]

mod admin;
mod allowance;
mod balance;
mod contract;
mod metadata;
mod storage_types;
mod test;

pub use contract::FuelTokenClient;
