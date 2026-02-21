import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { config } from '../config/environment';
import { logger } from '../utils/logger';

/**
 * Supabase Database Service
 * Handles all database operations for FuelAnchor
 */

// Database types
export interface UserProfile {
  id: string;
  full_name: string;
  phone_number: string;
  email?: string;
  password_hash?: string;
  role: 'rider' | 'fleet_driver' | 'merchant' | 'fleet_operator' | 'station_owner' | 'admin';
  stellar_public_key: string;
  created_at?: string;
  updated_at?: string;
}

export interface RiderProfile {
  id: string;
  national_id?: string;
  total_fuel_purchased: number;
  total_transactions: number;
  credit_score: number;
  created_at?: string;
}

export interface FleetDriverProfile {
  id: string;
  vehicle_id: string;
  vehicle_type?: string;
  fleet_manager_id?: string;
  odometer_reading: number;
  fuel_quota_allocated: number;
  fuel_quota_used: number;
  // Spending limits from fleet_members
  daily_limit?: number;
  weekly_limit?: number;
  transaction_limit?: number;
  daily_spent?: number;
  weekly_spent?: number;
  created_at?: string;
}

export interface MerchantProfile {
  id?: string;
  station_id: string;
  station_name: string;
  address?: string;
  country?: string;
  latitude?: number;
  longitude?: number;
  location_lat?: number;
  location_lng?: number;
  fuel_types?: any[];
  geofence_radius_meters?: number;
  stellar_public_key?: string;
  is_verified?: boolean;
  is_active?: boolean;
  rating?: number;
  total_fuel_dispensed?: number;
  total_revenue?: number;
  total_redemptions?: number;
  total_volume?: number;
  created_at?: string;
  updated_at?: string;
}

export interface Transaction {
  id?: string;
  blockchain_hash?: string;
  from_user_id?: string;
  to_user_id?: string;
  rider_id?: string;
  merchant_id?: string;
  amount: number;
  fuel_volume?: number;
  fuel_liters?: number;
  fuel_type?: string;
  gps_lat?: number;
  gps_lng?: number;
  latitude?: number;
  longitude?: number;
  vehicle_id?: string;
  transaction_type?: string;
  status: 'pending' | 'completed' | 'failed';
  created_at?: string;
  updated_at?: string;
}

export interface FuelQuota {
  id?: string;
  driver_id: string;
  allocated_by: string;
  quota_amount: number;
  period_start: string;
  period_end: string;
  created_at?: string;
}

export interface Fleet {
  id?: string;
  name: string;
  description?: string;
  country: string;
  vehicle_count?: number;
  operator_id: string;
  stellar_public_key?: string;
  total_fuel_budget?: number;
  remaining_fuel_budget?: number;
  driver_count?: number;
  is_active?: boolean;
  created_at?: string;
  updated_at?: string;
}

export interface FleetMember {
  id?: string;
  fleet_id: string;
  profile_id: string;
  vehicle_id: string;
  daily_limit: number;
  transaction_limit: number;
  weekly_limit: number;
  daily_spent?: number;
  weekly_spent?: number;
  allowed_stations?: string[];
  total_redemptions?: number;
  is_active?: boolean;
  created_at?: string;
}

class DatabaseService {
  private supabase: SupabaseClient | null = null;
  private isInitialized = false;

  constructor() {
    this.initialize();
  }

  private initialize(): void {
    try {
      if (!config.supabaseUrl || !config.supabaseAnonKey) {
        logger.warn('Supabase credentials not configured - database operations will fail');
        return;
      }

      this.supabase = createClient(config.supabaseUrl, config.supabaseAnonKey);
      this.isInitialized = true;
      logger.info('Supabase client initialized successfully');
    } catch (error) {
      logger.error('Failed to initialize Supabase client:', error);
    }
  }

  private ensureInitialized(): void {
    if (!this.isInitialized || !this.supabase) {
      throw new Error('Database service not initialized - check Supabase configuration');
    }
  }

  // ==================== USER PROFILES ====================

  async createUserProfile(profile: UserProfile): Promise<UserProfile> {
    this.ensureInitialized();
    const { data, error } = await this.supabase!
      .from('profiles')
      .insert(profile)
      .select()
      .single();

    if (error) {
      logger.error('Failed to create user profile:', error);
      throw new Error(`Database error: ${error.message}`);
    }

    logger.info(`Created user profile: ${profile.id}`);
    return data;
  }

  async getUserProfile(userId: string): Promise<UserProfile | null> {
    this.ensureInitialized();
    const { data, error } = await this.supabase!
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .single();

    if (error) {
      if (error.code === 'PGRST116') return null; // Not found
      logger.error('Failed to get user profile:', error);
      throw new Error(`Database error: ${error.message}`);
    }

    return data;
  }

  async getUserByPublicKey(publicKey: string): Promise<UserProfile | null> {
    this.ensureInitialized();
    const { data, error } = await this.supabase!
      .from('profiles')
      .select('*')
      .eq('stellar_public_key', publicKey)
      .single();

    if (error) {
      if (error.code === 'PGRST116') return null;
      logger.error('Failed to get user by public key:', error);
      throw new Error(`Database error: ${error.message}`);
    }

    return data;
  }

  async getUserByEmail(email: string): Promise<UserProfile | null> {
    this.ensureInitialized();
    const { data, error } = await this.supabase!
      .from('profiles')
      .select('*')
      .eq('email', email)
      .single();

    if (error) {
      if (error.code === 'PGRST116') return null;
      logger.error('Failed to get user by email:', error);
      throw new Error(`Database error: ${error.message}`);
    }

    return data;
  }

  async getUserByPhone(phone: string): Promise<UserProfile | null> {
    this.ensureInitialized();
    // Normalize phone: try exact match first, then strip leading + if present
    const normalized = phone.startsWith('+') ? phone : `+${phone}`;
    const { data, error } = await this.supabase!
      .from('profiles')
      .select('*')
      .or(`phone_number.eq.${phone},phone_number.eq.${normalized}`)
      .limit(1)
      .maybeSingle();

    if (error) {
      logger.error('Failed to get user by phone:', error);
      throw new Error(`Database error: ${error.message}`);
    }

    return data;
  }

  async saveUserAuth(userId: string, email: string, passwordHash: string): Promise<void> {
    this.ensureInitialized();
    const { error } = await this.supabase!
      .from('profiles')
      .update({ email: email.toLowerCase(), password_hash: passwordHash })
      .eq('id', userId);

    if (error) {
      logger.error('Failed to save user auth credentials:', error);
      throw new Error(`Database error: ${error.message}`);
    }
  }

  async updateUserProfile(userId: string, updates: Partial<UserProfile>): Promise<UserProfile> {
    this.ensureInitialized();
    const { data, error } = await this.supabase!
      .from('profiles')
      .update({ ...updates, updated_at: new Date().toISOString() })
      .eq('id', userId)
      .select()
      .single();

    if (error) {
      logger.error('Failed to update user profile:', error);
      throw new Error(`Database error: ${error.message}`);
    }

    return data;
  }

  // ==================== RIDER PROFILES ====================

  async createRiderProfile(profile: RiderProfile): Promise<RiderProfile> {
    this.ensureInitialized();
    const { data, error } = await this.supabase!
      .from('rider_profiles')
      .insert(profile)
      .select()
      .single();

    if (error) {
      logger.error('Failed to create rider profile:', error);
      throw new Error(`Database error: ${error.message}`);
    }

    return data;
  }

  async getRiderProfile(riderId: string): Promise<RiderProfile | null> {
    this.ensureInitialized();
    const { data, error } = await this.supabase!
      .from('rider_profiles')
      .select('*')
      .eq('id', riderId)
      .single();

    if (error) {
      if (error.code === 'PGRST116') return null;
      logger.error('Failed to get rider profile:', error);
      throw new Error(`Database error: ${error.message}`);
    }

    return data;
  }

  async updateRiderStats(riderId: string, fuelPurchased: number): Promise<void> {
    this.ensureInitialized();
    const { error } = await this.supabase!
      .rpc('increment_rider_stats', {
        p_rider_id: riderId,
        p_fuel_amount: fuelPurchased,
      });

    if (error) {
      logger.error('Failed to update rider stats:', error);
      throw new Error(`Database error: ${error.message}`);
    }
  }

  async updateRiderCreditScore(riderId: string, score: number): Promise<void> {
    this.ensureInitialized();
    const { error } = await this.supabase!
      .from('rider_profiles')
      .update({ credit_score: score })
      .eq('id', riderId);

    if (error) {
      logger.error('Failed to update rider credit score:', error);
      throw new Error(`Database error: ${error.message}`);
    }
  }

  // ==================== FLEET DRIVER PROFILES ====================

  async createFleetDriverProfile(profile: FleetDriverProfile): Promise<FleetDriverProfile> {
    this.ensureInitialized();
    const { data, error } = await this.supabase!
      .from('fleet_driver_profiles')
      .insert(profile)
      .select()
      .single();

    if (error) {
      logger.error('Failed to create fleet driver profile:', error);
      throw new Error(`Database error: ${error.message}`);
    }

    return data;
  }

  async getFleetDriverProfile(driverId: string): Promise<FleetDriverProfile | null> {
    this.ensureInitialized();
    const { data, error } = await this.supabase!
      .from('fleet_driver_profiles')
      .select('*')
      .eq('id', driverId)
      .single();

    if (error) {
      if (error.code === 'PGRST116') return null;
      logger.error('Failed to get fleet driver profile:', error);
      throw new Error(`Database error: ${error.message}`);
    }

    return data;
  }

  async updateDriverOdometer(driverId: string, reading: number): Promise<void> {
    this.ensureInitialized();
    const { error } = await this.supabase!
      .from('fleet_driver_profiles')
      .update({ odometer_reading: reading })
      .eq('id', driverId);

    if (error) {
      logger.error('Failed to update odometer:', error);
      throw new Error(`Database error: ${error.message}`);
    }
  }

  async updateDriverQuota(driverId: string, used: number): Promise<void> {
    this.ensureInitialized();
    const { error } = await this.supabase!
      .from('fleet_driver_profiles')
      .update({ fuel_quota_used: used })
      .eq('id', driverId);

    if (error) {
      logger.error('Failed to update driver quota:', error);
      throw new Error(`Database error: ${error.message}`);
    }
  }

  // ==================== MERCHANT PROFILES ====================

  async createMerchantProfile(profile: MerchantProfile): Promise<MerchantProfile> {
    this.ensureInitialized();
    const { data, error } = await this.supabase!
      .from('merchant_profiles')
      .insert(profile)
      .select()
      .single();

    if (error) {
      logger.error('Failed to create merchant profile:', error);
      throw new Error(`Database error: ${error.message}`);
    }

    return data;
  }

  async getMerchantProfile(merchantId: string): Promise<MerchantProfile | null> {
    this.ensureInitialized();
    const { data, error } = await this.supabase!
      .from('merchant_profiles')
      .select('*')
      .eq('id', merchantId)
      .single();

    if (error) {
      if (error.code === 'PGRST116') return null;
      logger.error('Failed to get merchant profile:', error);
      throw new Error(`Database error: ${error.message}`);
    }

    return data;
  }

  async updateMerchantStats(merchantId: string, fuelDispensed: number, revenue: number): Promise<void> {
    this.ensureInitialized();
    const { error } = await this.supabase!
      .rpc('increment_merchant_stats', {
        p_merchant_id: merchantId,
        p_fuel_dispensed: fuelDispensed,
        p_revenue: revenue,
      });

    if (error) {
      logger.error('Failed to update merchant stats:', error);
      throw new Error(`Database error: ${error.message}`);
    }
  }

  async getAllMerchants(country?: string, isVerified?: boolean): Promise<MerchantProfile[]> {
    this.ensureInitialized();
    let query = this.supabase!
      .from('merchant_profiles')
      .select('*')
      .eq('is_active', true);

    if (country) query = query.eq('country', country);
    if (isVerified !== undefined) query = query.eq('is_verified', isVerified);

    const { data, error } = await query.order('station_name');
    if (error) {
      logger.error('Failed to get merchants:', error);
      throw new Error(`Database error: ${error.message}`);
    }
    return data || [];
  }

  async getMerchantByStationId(stationId: string): Promise<MerchantProfile | null> {
    this.ensureInitialized();
    const { data, error } = await this.supabase!
      .from('merchant_profiles')
      .select('*')
      .eq('station_id', stationId)
      .single();

    if (error) {
      if (error.code === 'PGRST116') return null;
      throw new Error(`Database error: ${error.message}`);
    }
    return data;
  }

  async updateMerchantProfile(merchantId: string, updates: Partial<MerchantProfile> & Record<string, any>): Promise<MerchantProfile> {
    this.ensureInitialized();
    const { data, error } = await this.supabase!
      .from('merchant_profiles')
      .update(updates)
      .eq('id', merchantId)
      .select()
      .single();

    if (error) {
      logger.error('Failed to update merchant profile:', error);
      throw new Error(`Database error: ${error.message}`);
    }
    return data;
  }

  async getNearbyMerchants(lat: number, lng: number, radiusKm: number = 10): Promise<MerchantProfile[]> {
    this.ensureInitialized();
    const { data, error } = await this.supabase!
      .rpc('nearby_merchants', {
        user_lat: lat,
        user_lng: lng,
        radius_km: radiusKm,
      });

    if (error) {
      logger.error('Failed to get nearby merchants:', error);
      throw new Error(`Database error: ${error.message}`);
    }

    return data || [];
  }

  // ==================== TRANSACTIONS ====================

  async createTransaction(transaction: Transaction): Promise<Transaction> {
    this.ensureInitialized();
    const { data, error } = await this.supabase!
      .from('transactions')
      .insert(transaction)
      .select()
      .single();

    if (error) {
      logger.error('Failed to create transaction:', error);
      throw new Error(`Database error: ${error.message}`);
    }

    logger.info(`Created transaction: ${data.blockchain_hash}`);
    return data;
  }

  async getTransaction(transactionId: string): Promise<Transaction | null> {
    this.ensureInitialized();
    const { data, error } = await this.supabase!
      .from('transactions')
      .select('*')
      .eq('id', transactionId)
      .single();

    if (error) {
      if (error.code === 'PGRST116') return null;
      logger.error('Failed to get transaction:', error);
      throw new Error(`Database error: ${error.message}`);
    }

    return data;
  }

  async getTransactionByHash(hash: string): Promise<Transaction | null> {
    this.ensureInitialized();
    const { data, error } = await this.supabase!
      .from('transactions')
      .select('*')
      .eq('blockchain_hash', hash)
      .single();

    if (error) {
      if (error.code === 'PGRST116') return null;
      logger.error('Failed to get transaction by hash:', error);
      throw new Error(`Database error: ${error.message}`);
    }

    return data;
  }

  async getUserTransactions(userId: string, limit: number = 50): Promise<Transaction[]> {
    this.ensureInitialized();
    const { data, error } = await this.supabase!
      .from('transactions')
      .select('*')
      .or(`from_user_id.eq.${userId},to_user_id.eq.${userId}`)
      .order('created_at', { ascending: false })
      .limit(limit);

    if (error) {
      logger.error('Failed to get user transactions:', error);
      throw new Error(`Database error: ${error.message}`);
    }

    return data || [];
  }

  async getPendingTransactions(userId: string): Promise<Transaction[]> {
    this.ensureInitialized();
    const { data, error } = await this.supabase!
      .from('transactions')
      .select('*')
      .eq('to_user_id', userId)
      .eq('status', 'pending')
      .order('created_at', { ascending: false });

    if (error) {
      logger.error('Failed to get pending transactions:', error);
      throw new Error(`Database error: ${error.message}`);
    }

    return data || [];
  }

  async updateTransactionStatus(transactionId: string, status: 'pending' | 'completed' | 'failed'): Promise<void> {
    this.ensureInitialized();
    const { error } = await this.supabase!
      .from('transactions')
      .update({ status })
      .eq('id', transactionId);

    if (error) {
      logger.error('Failed to update transaction status:', error);
      throw new Error(`Database error: ${error.message}`);
    }
  }

  // ==================== FUEL QUOTAS ====================

  async createFuelQuota(quota: FuelQuota): Promise<FuelQuota> {
    this.ensureInitialized();
    const { data, error } = await this.supabase!
      .from('fuel_quotas')
      .insert(quota)
      .select()
      .single();

    if (error) {
      logger.error('Failed to create fuel quota:', error);
      throw new Error(`Database error: ${error.message}`);
    }

    return data;
  }

  async getActiveQuota(driverId: string): Promise<FuelQuota | null> {
    this.ensureInitialized();
    const today = new Date().toISOString().split('T')[0];
    
    const { data, error } = await this.supabase!
      .from('fuel_quotas')
      .select('*')
      .eq('driver_id', driverId)
      .lte('period_start', today)
      .gte('period_end', today)
      .order('created_at', { ascending: false })
      .limit(1)
      .single();

    if (error) {
      if (error.code === 'PGRST116') return null;
      logger.error('Failed to get active quota:', error);
      throw new Error(`Database error: ${error.message}`);
    }

    return data;
  }

  async getDriverQuotas(driverId: string): Promise<FuelQuota[]> {
    this.ensureInitialized();
    const { data, error } = await this.supabase!
      .from('fuel_quotas')
      .select('*')
      .eq('driver_id', driverId)
      .order('created_at', { ascending: false });

    if (error) {
      logger.error('Failed to get driver quotas:', error);
      throw new Error(`Database error: ${error.message}`);
    }

    return data || [];
  }

  // ==================== FLEET MANAGEMENT ====================

  async createFleet(fleet: Fleet): Promise<Fleet> {
    this.ensureInitialized();
    const { data, error } = await this.supabase!
      .from('fleets')
      .insert(fleet)
      .select()
      .single();

    if (error) {
      logger.error('Failed to create fleet:', error);
      throw new Error(`Database error: ${error.message}`);
    }
    logger.info(`Created fleet: ${data.id}`);
    return data;
  }

  async getFleet(fleetId: string): Promise<Fleet | null> {
    this.ensureInitialized();
    const { data, error } = await this.supabase!
      .from('fleets')
      .select('*')
      .eq('id', fleetId)
      .single();

    if (error) {
      if (error.code === 'PGRST116') return null;
      throw new Error(`Database error: ${error.message}`);
    }
    return data;
  }

  async getFleetsByOperator(operatorId: string): Promise<Fleet[]> {
    this.ensureInitialized();
    const { data, error } = await this.supabase!
      .from('fleets')
      .select('*')
      .eq('operator_id', operatorId)
      .eq('is_active', true)
      .order('created_at', { ascending: false });

    if (error) {
      logger.error('Failed to get fleets:', error);
      throw new Error(`Database error: ${error.message}`);
    }
    return data || [];
  }

  async updateFleetBudget(fleetId: string, totalBudget: number, remainingBudget: number): Promise<void> {
    this.ensureInitialized();
    const { error } = await this.supabase!
      .from('fleets')
      .update({ total_fuel_budget: totalBudget, remaining_fuel_budget: remainingBudget, updated_at: new Date().toISOString() })
      .eq('id', fleetId);

    if (error) {
      logger.error('Failed to update fleet budget:', error);
      throw new Error(`Database error: ${error.message}`);
    }
  }

  async createFleetMember(member: FleetMember): Promise<FleetMember> {
    this.ensureInitialized();
    const { data, error } = await this.supabase!
      .from('fleet_members')
      .insert(member)
      .select()
      .single();

    if (error) {
      logger.error('Failed to create fleet member:', error);
      throw new Error(`Database error: ${error.message}`);
    }
    return data;
  }

  async getFleetMembers(fleetId: string): Promise<FleetMember[]> {
    this.ensureInitialized();
    const { data, error } = await this.supabase!
      .from('fleet_members')
      .select('*, profiles(full_name, phone_number, stellar_public_key)')
      .eq('fleet_id', fleetId)
      .order('created_at', { ascending: false });

    if (error) {
      logger.error('Failed to get fleet members:', error);
      throw new Error(`Database error: ${error.message}`);
    }
    return data || [];
  }

  async getFleetMember(memberId: string): Promise<FleetMember | null> {
    this.ensureInitialized();
    const { data, error } = await this.supabase!
      .from('fleet_members')
      .select('*, profiles(full_name, phone_number, stellar_public_key)')
      .eq('id', memberId)
      .single();

    if (error) {
      if (error.code === 'PGRST116') return null;
      throw new Error(`Database error: ${error.message}`);
    }
    return data;
  }

  async updateFleetMemberSpending(memberId: string, addDailySpent: number, addWeeklySpent: number): Promise<void> {
    this.ensureInitialized();
    // Use RPC or read-modify-write for atomic increment
    const { error } = await this.supabase!
      .rpc('increment_fleet_member_spending', {
        p_member_id: memberId,
        p_daily_amount: addDailySpent,
        p_weekly_amount: addWeeklySpent,
      });

    if (error) {
      logger.error('Failed to update fleet member spending:', error);
      // Non-fatal — don't throw
    }
  }

  async getAllFleets(): Promise<Fleet[]> {
    this.ensureInitialized();
    const { data, error } = await this.supabase!
      .from('fleets')
      .select('*, profiles(full_name, phone_number)')
      .order('created_at', { ascending: false });

    if (error) {
      logger.error('Failed to get all fleets:', error);
      throw new Error(`Database error: ${error.message}`);
    }
    return data || [];
  }

  async getFleetAnalytics(fleetId: string): Promise<any> {
    this.ensureInitialized();
    const { data, error } = await this.supabase!
      .rpc('fleet_analytics', { p_fleet_id: fleetId });

    if (error) {
      logger.error('Failed to get fleet analytics:', error);
      throw new Error(`Database error: ${error.message}`);
    }
    return data?.[0] || null;
  }

  // ==================== ANALYTICS ====================

  async getDashboardStats(userId: string, role: string): Promise<any> {
    this.ensureInitialized();
    
    if (role === 'merchant') {
      const { data, error } = await this.supabase!
        .rpc('merchant_dashboard_stats', { merchant_id: userId });
      
      if (error) {
        logger.error('Failed to get merchant stats:', error);
        throw new Error(`Database error: ${error.message}`);
      }
      
      return data;
    } else if (role === 'rider') {
      const { data, error } = await this.supabase!
        .rpc('rider_dashboard_stats', { rider_id: userId });
      
      if (error) {
        logger.error('Failed to get rider stats:', error);
        throw new Error(`Database error: ${error.message}`);
      }
      
      return data;
    }
    
    return null;
  }

  async getMerchantAnalytics(merchantId: string): Promise<any> {
    this.ensureInitialized();

    const [profileRes, txRes] = await Promise.all([
      this.supabase!
        .from('merchant_profiles')
        .select('total_fuel_dispensed, total_revenue, total_redemptions, fuel_types')
        .eq('id', merchantId)
        .single(),
      this.supabase!
        .from('transactions')
        .select('amount, fuel_liters, fuel_type, created_at, status')
        .or(`merchant_id.eq.${merchantId},to_user_id.eq.${merchantId}`)
        .eq('status', 'completed')
        .order('created_at', { ascending: false })
        .limit(500),
    ]);

    const profile = profileRes.data;
    const txs: any[] = txRes.data || [];

    const uniqueUsers = new Set(txs.map((t: any) => t.rider_id || t.from_user_id)).size;
    const totalSales = txs.reduce((s: number, t: any) => s + (t.amount || 0), 0);

    // Aggregate transactions per day (last 30 days)
    const byDay: Record<string, number> = {};
    txs.forEach((t: any) => {
      const day = (t.created_at || '').split('T')[0];
      if (day) byDay[day] = (byDay[day] || 0) + (t.amount || 0);
    });
    const revenueByDay = Object.entries(byDay)
      .sort(([a], [b]) => a.localeCompare(b))
      .slice(-30)
      .map(([date, value]) => ({ date, value }));

    return {
      merchantId,
      summary: {
        totalSales: totalSales || profile?.total_revenue || 0,
        transactionCount: txs.length || profile?.total_redemptions || 0,
        uniqueCustomers: uniqueUsers,
        averageTicket: txs.length ? totalSales / txs.length : 0,
        totalFuelDispensed: profile?.total_fuel_dispensed || 0,
      },
      revenueByDay,
    };
  }

  async getFleetDetailedAnalytics(fleetId: string): Promise<any> {
    this.ensureInitialized();

    const [membersRes, fleetRes] = await Promise.all([
      this.supabase!
        .from('fleet_members')
        .select('*, profiles(full_name, phone_number)')
        .eq('fleet_id', fleetId)
        .eq('is_active', true),
      this.supabase!
        .from('fleets')
        .select('*')
        .eq('id', fleetId)
        .single(),
    ]);

    const fleet = fleetRes.data;
    const members: any[] = membersRes.data || [];

    const totalSpend = members.reduce((s: number, m: any) => s + (m.weekly_spent || 0), 0);
    const budgetUsed = fleet
      ? ((fleet.total_fuel_budget || 0) - (fleet.remaining_fuel_budget || 0))
      : totalSpend;

    return {
      fleetId,
      summary: {
        totalDrivers: fleet?.driver_count || members.length,
        activeDrivers: members.length,
        totalFuelBudget: fleet?.total_fuel_budget || 0,
        remainingBudget: fleet?.remaining_fuel_budget || 0,
        budgetUtilization: fleet?.total_fuel_budget
          ? Math.round((budgetUsed / fleet.total_fuel_budget) * 100)
          : 0,
      },
      driverPerformance: members.map((m: any) => ({
        memberId: m.id,
        name: m.profiles?.full_name || 'Unknown',
        vehicleId: m.vehicle_id,
        dailyLimit: m.daily_limit,
        dailySpent: m.daily_spent || 0,
        weeklySpent: m.weekly_spent || 0,
        totalRedemptions: m.total_redemptions || 0,
      })),
    };
  }

  async getRiderAnalytics(riderId: string): Promise<any> {
    this.ensureInitialized();

    const [profileRes, riderRes, txRes] = await Promise.all([
      this.supabase!
        .from('profiles')
        .select('full_name, phone_number, stellar_public_key')
        .eq('id', riderId)
        .single(),
      this.supabase!
        .from('rider_profiles')
        .select('credit_score, total_fuel_purchased, total_transactions')
        .eq('id', riderId)
        .single(),
      this.supabase!
        .from('transactions')
        .select('amount, fuel_liters, fuel_type, merchant_id, created_at, status')
        .or(`rider_id.eq.${riderId},from_user_id.eq.${riderId}`)
        .eq('status', 'completed')
        .order('created_at', { ascending: false })
        .limit(200),
    ]);

    const rider = riderRes.data;
    const txs: any[] = txRes.data || [];

    // Top stations by visit frequency
    const stationCounts: Record<string, { visits: number; amount: number }> = {};
    txs.forEach((t: any) => {
      const mid = t.merchant_id || 'unknown';
      if (!stationCounts[mid]) stationCounts[mid] = { visits: 0, amount: 0 };
      stationCounts[mid].visits += 1;
      stationCounts[mid].amount += t.amount || 0;
    });
    const topStations = Object.entries(stationCounts)
      .sort(([, a], [, b]) => b.visits - a.visits)
      .slice(0, 5)
      .map(([merchantId, stats]) => ({ merchantId, ...stats }));

    // Spending trend (last 90 days by day)
    const byDay: Record<string, number> = {};
    txs.forEach((t: any) => {
      const day = (t.created_at || '').split('T')[0];
      if (day) byDay[day] = (byDay[day] || 0) + (t.amount || 0);
    });
    const spendingTrend = Object.entries(byDay)
      .sort(([a], [b]) => a.localeCompare(b))
      .slice(-90)
      .map(([date, value]) => ({ date, value }));

    const score = rider?.credit_score || 0;
    const tier = score >= 800 ? 'Platinum' : score >= 700 ? 'Gold' : score >= 600 ? 'Silver' : score >= 500 ? 'Bronze' : 'Unscored';

    return {
      riderId,
      summary: {
        totalFuelPurchases: rider?.total_fuel_purchased || 0,
        transactionCount: rider?.total_transactions || txs.length,
        creditScore: score,
        creditTier: tier,
      },
      spendingTrend,
      topStations,
    };
  }

  async getCreditScoreDistribution(): Promise<any> {
    this.ensureInitialized();
    const { data, error } = await this.supabase!
      .from('rider_profiles')
      .select('credit_score');

    if (error) {
      logger.error('Failed to get credit score distribution:', error);
      throw new Error(`Database error: ${error.message}`);
    }

    const scores: number[] = (data || []).map((r: any) => r.credit_score || 0);
    const distribution = {
      unscored: scores.filter(s => s === 0).length,
      bronze:   scores.filter(s => s >= 500 && s < 600).length,
      silver:   scores.filter(s => s >= 600 && s < 700).length,
      gold:     scores.filter(s => s >= 700 && s < 800).length,
      platinum: scores.filter(s => s >= 800).length,
      total:    scores.length,
      averageScore: scores.length
        ? Math.round(scores.reduce((a, b) => a + b, 0) / scores.length)
        : 0,
    };

    return distribution;
  }

  // ==================== RELWORX PAYMENTS ====================

  async createRelworxPayment(data: {
    user_id: string;
    amount: number;
    currency: string;
    type: 'collection' | 'disbursement';
    status: string;
    transaction_ref: string;
    internal_reference?: string;
    phone_number: string;
    provider?: string;
    description?: string;
    metadata?: Record<string, any>;
  }): Promise<any> {
    this.ensureInitialized();
    const { data: record, error } = await this.supabase!
      .from('relworx_payments')
      .insert(data)
      .select()
      .single();

    if (error) {
      logger.error('Failed to create relworx payment:', error);
      throw new Error(`Database error: ${error.message}`);
    }
    return record;
  }

  async getRelworxPayment(transactionRef: string, userId?: string): Promise<any> {
    this.ensureInitialized();
    let query = this.supabase!
      .from('relworx_payments')
      .select('*')
      .eq('transaction_ref', transactionRef);

    if (userId) query = query.eq('user_id', userId);

    const { data, error } = await query.single();
    if (error && error.code !== 'PGRST116') {
      logger.error('Failed to get relworx payment:', error);
      throw new Error(`Database error: ${error.message}`);
    }
    return data || null;
  }

  async getRelworxPaymentByRef(customerRef: string): Promise<any> {
    this.ensureInitialized();
    const { data, error } = await this.supabase!
      .from('relworx_payments')
      .select('*')
      .eq('transaction_ref', customerRef)
      .single();

    if (error && error.code !== 'PGRST116') {
      logger.error('Failed to get relworx payment by ref:', error);
      throw new Error(`Database error: ${error.message}`);
    }
    return data || null;
  }

  async updateRelworxPaymentStatus(
    id: string,
    status: string,
    extra?: { provider_transaction_id?: string; completed_at?: string }
  ): Promise<void> {
    this.ensureInitialized();
    const updates: Record<string, any> = { status };
    if (extra?.provider_transaction_id) updates.provider_transaction_id = extra.provider_transaction_id;
    if (extra?.completed_at) updates.completed_at = extra.completed_at;

    const { error } = await this.supabase!
      .from('relworx_payments')
      .update(updates)
      .eq('id', id);

    if (error) {
      logger.error('Failed to update relworx payment status:', error);
      throw new Error(`Database error: ${error.message}`);
    }
  }

  async getPendingRelworxPayments(): Promise<any[]> {
    this.ensureInitialized();
    const { data, error } = await this.supabase!
      .from('relworx_payments')
      .select('*')
      .eq('status', 'pending')
      .lt('created_at', new Date(Date.now() - 2 * 60 * 1000).toISOString()) // older than 2 min
      .order('created_at', { ascending: true });

    if (error) {
      logger.error('Failed to get pending relworx payments:', error);
      throw new Error(`Database error: ${error.message}`);
    }
    return data || [];
  }

  // ==================== HEALTH CHECK ====================

  async healthCheck(): Promise<boolean> {
    try {
      this.ensureInitialized();
      const { error } = await this.supabase!
        .from('profiles')
        .select('id')
        .limit(1);
      
      return !error;
    } catch (error) {
      logger.error('Database health check failed:', error);
      return false;
    }
  }
}

// Export singleton instance
export const db = new DatabaseService();
export default db;
