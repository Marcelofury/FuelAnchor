//! FuelAnchor Credit Scoring Contract
//!
//! On-chain credit scoring for Boda Boda riders and fleet drivers based on:
//! - Consistency of fuel purchases
//! - Transaction frequency
//! - Repayment behavior (if applicable)
//! - Account longevity
//! - Geographic patterns

#![no_std]

use soroban_sdk::{
    contract, contractimpl, contracttype, Address, Env, Symbol, Vec,
};

/// Credit score tiers
#[derive(Clone, Debug, PartialEq)]
#[contracttype]
pub enum CreditTier {
    /// New user, no score yet (0-89 days)
    Unscored,
    /// Basic tier (90-179 days, limited activity)
    Bronze,
    /// Growing tier (good consistency)
    Silver,
    /// Established tier (excellent history)
    Gold,
    /// Premium tier (exceptional track record)
    Platinum,
}

/// User's credit profile
#[derive(Clone, Debug)]
#[contracttype]
pub struct CreditProfile {
    /// User's address
    pub user: Address,
    /// Current credit score (0-850)
    pub score: u32,
    /// Current tier
    pub tier: CreditTier,
    /// Total number of transactions
    pub total_transactions: u64,
    /// Total amount transacted (in smallest unit)
    pub total_amount: i128,
    /// Number of active days (days with at least one transaction)
    pub active_days: u32,
    /// First transaction timestamp
    pub first_transaction_at: u64,
    /// Last transaction timestamp
    pub last_transaction_at: u64,
    /// Consecutive days with transactions (streak)
    pub current_streak: u32,
    /// Longest streak ever
    pub longest_streak: u32,
    /// Average transaction amount
    pub avg_transaction_amount: i128,
    /// Number of unique stations visited
    pub unique_stations: u32,
    /// Last score update timestamp
    pub last_score_update: u64,
}

/// Daily activity record for a user
#[derive(Clone, Debug)]
#[contracttype]
pub struct DailyActivity {
    /// Day identifier (timestamp / 86400)
    pub day: u64,
    /// Number of transactions
    pub transaction_count: u32,
    /// Total amount for the day
    pub total_amount: i128,
    /// Stations visited
    pub stations_visited: u32,
}

/// Score factors and their weights
#[derive(Clone, Debug)]
#[contracttype]
pub struct ScoreFactors {
    /// Account age factor (0-100)
    pub age_factor: u32,
    /// Transaction frequency factor (0-100)
    pub frequency_factor: u32,
    /// Consistency factor based on streaks (0-100)
    pub consistency_factor: u32,
    /// Volume factor based on transaction amounts (0-100)
    pub volume_factor: u32,
    /// Geographic diversity factor (0-100)
    pub diversity_factor: u32,
}

/// Credit score inquiry result (for lenders)
#[derive(Clone, Debug)]
#[contracttype]
pub struct CreditInquiry {
    pub user: Address,
    pub score: u32,
    pub tier: CreditTier,
    pub account_age_days: u32,
    pub total_transactions: u64,
    pub is_eligible_for_credit: bool,
    pub recommended_credit_limit: i128,
    pub inquiry_timestamp: u64,
}

/// Data keys for storage
#[derive(Clone)]
#[contracttype]
pub enum DataKey {
    Admin,
    CreditProfile(Address),
    DailyActivity(Address, u64),
    StationsVisited(Address),
    TotalUsers,
    AverageScore,
    ScoreDistribution(CreditTier),
    AuthorizedInquirer(Address),
    InquiryCount(Address),
}

/// Constants for scoring
const MIN_DAYS_FOR_SCORE: u64 = 90; // 90 days minimum for credit score
const SECONDS_PER_DAY: u64 = 86400;
const MAX_SCORE: u32 = 850;
const MIN_SCORE: u32 = 300;

/// Weight distribution for score calculation (must sum to 100)
const WEIGHT_AGE: u32 = 20;
const WEIGHT_FREQUENCY: u32 = 25;
const WEIGHT_CONSISTENCY: u32 = 25;
const WEIGHT_VOLUME: u32 = 15;
const WEIGHT_DIVERSITY: u32 = 15;

#[contract]
pub struct CreditScore;

#[contractimpl]
impl CreditScore {
    /// Initialize the credit scoring contract
    pub fn initialize(env: Env, admin: Address) {
        if env.storage().instance().has(&DataKey::Admin) {
            panic!("Already initialized");
        }
        
        env.storage().instance().set(&DataKey::Admin, &admin);
        env.storage().instance().set(&DataKey::TotalUsers, &0u64);
        env.storage().instance().set(&DataKey::AverageScore, &0u32);
    }

    /// Record a fuel transaction for credit scoring
    /// This should be called by the voucher redemption contract
    pub fn record_transaction(
        env: Env,
        user: Address,
        amount: i128,
        station_count: u32,
        _timestamp: u64, // Using underscore to indicate intentionally unused
    ) {
        let timestamp = env.ledger().timestamp();
        let day = timestamp / SECONDS_PER_DAY;
        let profile_key = DataKey::CreditProfile(user.clone());

        let mut profile = if env.storage().persistent().has(&profile_key) {
            env.storage().persistent().get(&profile_key).unwrap()
        } else {
            // New user
            let total_users: u64 = env.storage().instance().get(&DataKey::TotalUsers).unwrap_or(0);
            env.storage().instance().set(&DataKey::TotalUsers, &(total_users + 1));

            CreditProfile {
                user: user.clone(),
                score: 0,
                tier: CreditTier::Unscored,
                total_transactions: 0,
                total_amount: 0,
                active_days: 0,
                first_transaction_at: timestamp,
                last_transaction_at: 0,
                current_streak: 0,
                longest_streak: 0,
                avg_transaction_amount: 0,
                unique_stations: 0,
                last_score_update: 0,
            }
        };

        // Update transaction stats
        profile.total_transactions += 1;
        profile.total_amount += amount;
        profile.avg_transaction_amount = profile.total_amount / (profile.total_transactions as i128);

        // Check if this is a new day
        let last_day = profile.last_transaction_at / SECONDS_PER_DAY;
        if day != last_day {
            profile.active_days += 1;
            
            // Update streak
            if day == last_day + 1 {
                profile.current_streak += 1;
            } else if last_day > 0 {
                profile.current_streak = 1;
            } else {
                profile.current_streak = 1;
            }

            if profile.current_streak > profile.longest_streak {
                profile.longest_streak = profile.current_streak;
            }
        }

        // Update unique stations
        profile.unique_stations = station_count.max(profile.unique_stations);
        profile.last_transaction_at = timestamp;

        // Store daily activity
        let daily_key = DataKey::DailyActivity(user.clone(), day);
        let mut daily_activity = if env.storage().persistent().has(&daily_key) {
            env.storage().persistent().get(&daily_key).unwrap()
        } else {
            DailyActivity {
                day,
                transaction_count: 0,
                total_amount: 0,
                stations_visited: 0,
            }
        };

        daily_activity.transaction_count += 1;
        daily_activity.total_amount += amount;
        daily_activity.stations_visited = station_count;
        env.storage().persistent().set(&daily_key, &daily_activity);

        // Calculate and update score
        let score = Self::calculate_score(&env, &profile);
        profile.score = score;
        profile.tier = Self::determine_tier(score, &profile);
        profile.last_score_update = timestamp;

        env.storage().persistent().set(&profile_key, &profile);

        // Emit event
        env.events().publish(
            (Symbol::new(&env, "transaction_recorded"), user),
            (amount, score),
        );
    }

    /// Calculate credit score based on profile data
    fn calculate_score(env: &Env, profile: &CreditProfile) -> u32 {
        let current_time = env.ledger().timestamp();
        let account_age_days = (current_time - profile.first_transaction_at) / SECONDS_PER_DAY;

        // Must have minimum days for a score
        if account_age_days < MIN_DAYS_FOR_SCORE {
            return 0;
        }

        let factors = Self::calculate_factors(profile, account_age_days as u32);

        // Weighted score calculation
        let weighted_score = 
            (factors.age_factor * WEIGHT_AGE +
             factors.frequency_factor * WEIGHT_FREQUENCY +
             factors.consistency_factor * WEIGHT_CONSISTENCY +
             factors.volume_factor * WEIGHT_VOLUME +
             factors.diversity_factor * WEIGHT_DIVERSITY) / 100;

        // Map to score range (300-850)
        let score_range = MAX_SCORE - MIN_SCORE;
        let final_score = MIN_SCORE + (weighted_score * score_range) / 100;

        final_score.min(MAX_SCORE)
    }

    /// Calculate individual scoring factors
    fn calculate_factors(profile: &CreditProfile, account_age_days: u32) -> ScoreFactors {
        // Age factor: More account age = higher score (up to 365 days max benefit)
        let age_factor = ((account_age_days as u64 * 100) / 365).min(100) as u32;

        // Frequency factor: Based on transactions per active day
        let tx_per_day = if profile.active_days > 0 {
            (profile.total_transactions * 100 / profile.active_days as u64).min(100) as u32
        } else {
            0
        };
        let frequency_factor = tx_per_day.min(100);

        // Consistency factor: Based on streak length and active days ratio
        let active_ratio = if account_age_days > 0 {
            (profile.active_days * 100 / account_age_days).min(100)
        } else {
            0
        };
        let streak_bonus = (profile.longest_streak * 2).min(50);
        let consistency_factor = ((active_ratio + streak_bonus) / 2).min(100);

        // Volume factor: Based on average transaction amount (normalized)
        // Assume good average is around 50,000,000 stroops (5 FUEL tokens)
        let volume_target: i128 = 50_000_000;
        let volume_factor = if profile.avg_transaction_amount >= volume_target {
            100
        } else {
            ((profile.avg_transaction_amount * 100) / volume_target).min(100) as u32
        };

        // Diversity factor: Based on unique stations (up to 10 stations = max)
        let diversity_factor = (profile.unique_stations * 10).min(100);

        ScoreFactors {
            age_factor,
            frequency_factor,
            consistency_factor,
            volume_factor,
            diversity_factor,
        }
    }

    /// Determine credit tier based on score and profile
    fn determine_tier(score: u32, profile: &CreditProfile) -> CreditTier {
        if score == 0 {
            CreditTier::Unscored
        } else if score < 500 {
            CreditTier::Bronze
        } else if score < 650 {
            CreditTier::Silver
        } else if score < 750 {
            CreditTier::Gold
        } else {
            CreditTier::Platinum
        }
    }

    /// Get user's credit profile
    pub fn get_profile(env: Env, user: Address) -> CreditProfile {
        env.storage().persistent().get(&DataKey::CreditProfile(user))
            .expect("User has no credit profile")
    }

    /// Get user's current credit score
    pub fn get_score(env: Env, user: Address) -> u32 {
        let profile: CreditProfile = env.storage().persistent()
            .get(&DataKey::CreditProfile(user))
            .expect("User has no credit profile");
        profile.score
    }

    /// Get user's credit tier
    pub fn get_tier(env: Env, user: Address) -> CreditTier {
        let profile: CreditProfile = env.storage().persistent()
            .get(&DataKey::CreditProfile(user))
            .expect("User has no credit profile");
        profile.tier
    }

    /// Authorize a lender/inquirer to access credit scores
    pub fn authorize_inquirer(env: Env, admin: Address, inquirer: Address) {
        admin.require_auth();
        let stored_admin: Address = env.storage().instance().get(&DataKey::Admin).unwrap();
        if admin != stored_admin {
            panic!("Unauthorized");
        }

        env.storage().persistent().set(&DataKey::AuthorizedInquirer(inquirer.clone()), &true);

        env.events().publish(
            (Symbol::new(&env, "inquirer_authorized"), inquirer),
            admin,
        );
    }

    /// Perform a credit inquiry (for authorized lenders)
    pub fn credit_inquiry(env: Env, inquirer: Address, user: Address) -> CreditInquiry {
        inquirer.require_auth();

        // Check if inquirer is authorized
        let is_authorized: bool = env.storage().persistent()
            .get(&DataKey::AuthorizedInquirer(inquirer.clone()))
            .unwrap_or(false);
        
        if !is_authorized {
            panic!("Inquirer not authorized");
        }

        let profile: CreditProfile = env.storage().persistent()
            .get(&DataKey::CreditProfile(user.clone()))
            .expect("User has no credit profile");

        let current_time = env.ledger().timestamp();
        let account_age_days = ((current_time - profile.first_transaction_at) / SECONDS_PER_DAY) as u32;

        // Calculate recommended credit limit based on score and history
        let base_limit: i128 = match profile.tier {
            CreditTier::Unscored => 0,
            CreditTier::Bronze => 10_000_000_000,     // 1,000 FUEL
            CreditTier::Silver => 50_000_000_000,     // 5,000 FUEL
            CreditTier::Gold => 100_000_000_000,      // 10,000 FUEL
            CreditTier::Platinum => 500_000_000_000,  // 50,000 FUEL
        };

        // Adjust based on transaction history
        let history_multiplier = (profile.total_amount / 1_000_000_000).min(200) as i128;
        let recommended_limit = base_limit + (base_limit * history_multiplier / 100);

        // Track inquiry
        let inquiry_count_key = DataKey::InquiryCount(user.clone());
        let inquiry_count: u32 = env.storage().persistent()
            .get(&inquiry_count_key)
            .unwrap_or(0);
        env.storage().persistent().set(&inquiry_count_key, &(inquiry_count + 1));

        let inquiry = CreditInquiry {
            user: user.clone(),
            score: profile.score,
            tier: profile.tier,
            account_age_days,
            total_transactions: profile.total_transactions,
            is_eligible_for_credit: profile.score >= 500,
            recommended_credit_limit: recommended_limit,
            inquiry_timestamp: current_time,
        };

        env.events().publish(
            (Symbol::new(&env, "credit_inquiry"), user, inquirer),
            profile.score,
        );

        inquiry
    }

    /// Get scoring factors breakdown for a user
    pub fn get_score_factors(env: Env, user: Address) -> ScoreFactors {
        let profile: CreditProfile = env.storage().persistent()
            .get(&DataKey::CreditProfile(user))
            .expect("User has no credit profile");

        let current_time = env.ledger().timestamp();
        let account_age_days = ((current_time - profile.first_transaction_at) / SECONDS_PER_DAY) as u32;

        Self::calculate_factors(&profile, account_age_days)
    }

    /// Get total registered users
    pub fn get_total_users(env: Env) -> u64 {
        env.storage().instance().get(&DataKey::TotalUsers).unwrap_or(0)
    }

    /// Check if user is eligible for credit
    pub fn is_eligible_for_credit(env: Env, user: Address) -> bool {
        if let Some(profile) = env.storage().persistent().get::<DataKey, CreditProfile>(&DataKey::CreditProfile(user)) {
            profile.score >= 500
        } else {
            false
        }
    }

    /// Get days until user is eligible for scoring
    pub fn days_until_scorable(env: Env, user: Address) -> u64 {
        if let Some(profile) = env.storage().persistent().get::<DataKey, CreditProfile>(&DataKey::CreditProfile(user)) {
            let current_time = env.ledger().timestamp();
            let account_age_days = (current_time - profile.first_transaction_at) / SECONDS_PER_DAY;
            
            if account_age_days >= MIN_DAYS_FOR_SCORE {
                0
            } else {
                MIN_DAYS_FOR_SCORE - account_age_days
            }
        } else {
            MIN_DAYS_FOR_SCORE
        }
    }
}
