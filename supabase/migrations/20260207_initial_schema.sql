-- FuelAnchor Database Schema for Supabase
-- Created: 2026-02-07

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table (extends Supabase auth.users)
CREATE TABLE public.profiles (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    full_name TEXT NOT NULL,
    phone_number TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('rider', 'fleet_driver', 'merchant')),
    stellar_public_key TEXT UNIQUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Rider profiles
CREATE TABLE public.rider_profiles (
    id UUID REFERENCES public.profiles(id) PRIMARY KEY,
    national_id TEXT,
    total_fuel_purchased DECIMAL(10, 2) DEFAULT 0,
    total_transactions INTEGER DEFAULT 0,
    credit_score INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Fleet driver profiles
CREATE TABLE public.fleet_driver_profiles (
    id UUID REFERENCES public.profiles(id) PRIMARY KEY,
    vehicle_id TEXT NOT NULL,
    vehicle_type TEXT,
    fleet_manager_id UUID REFERENCES public.profiles(id),
    odometer_reading BIGINT DEFAULT 0,
    fuel_quota_allocated DECIMAL(10, 2) DEFAULT 0,
    fuel_quota_used DECIMAL(10, 2) DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Merchant/Station profiles
CREATE TABLE public.merchant_profiles (
    id UUID REFERENCES public.profiles(id) PRIMARY KEY,
    station_id TEXT NOT NULL,
    station_name TEXT NOT NULL,
    location_lat DECIMAL(10, 6),
    location_lng DECIMAL(10, 6),
    total_fuel_dispensed DECIMAL(10, 2) DEFAULT 0,
    total_revenue DECIMAL(15, 2) DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Transactions table (synced with blockchain)
CREATE TABLE public.transactions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    blockchain_hash TEXT UNIQUE NOT NULL,
    from_user_id UUID REFERENCES public.profiles(id) NOT NULL,
    to_user_id UUID REFERENCES public.profiles(id) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    fuel_volume DECIMAL(8, 2),
    gps_lat DECIMAL(10, 6),
    gps_lng DECIMAL(10, 6),
    status TEXT DEFAULT 'completed' CHECK (status IN ('pending', 'completed', 'failed')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Fuel quotas (for fleet management)
CREATE TABLE public.fuel_quotas (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    driver_id UUID REFERENCES public.fleet_driver_profiles(id) NOT NULL,
    allocated_by UUID REFERENCES public.profiles(id) NOT NULL,
    quota_amount DECIMAL(10, 2) NOT NULL,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_profiles_stellar_key ON public.profiles(stellar_public_key);
CREATE INDEX idx_profiles_role ON public.profiles(role);
CREATE INDEX idx_transactions_from_user ON public.transactions(from_user_id);
CREATE INDEX idx_transactions_to_user ON public.transactions(to_user_id);
CREATE INDEX idx_transactions_hash ON public.transactions(blockchain_hash);
CREATE INDEX idx_fleet_drivers_vehicle ON public.fleet_driver_profiles(vehicle_id);

-- Row Level Security (RLS) Policies
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rider_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fleet_driver_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.merchant_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fuel_quotas ENABLE ROW LEVEL SECURITY;

-- Profiles: Users can read their own profile
CREATE POLICY "Users can view own profile"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id);

-- Profiles: Users can update their own profile
CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id);

-- Transactions: Users can view transactions they're part of
CREATE POLICY "Users can view own transactions"
    ON public.transactions FOR SELECT
    USING (auth.uid() = from_user_id OR auth.uid() = to_user_id);

-- Transactions: Anyone authenticated can insert (for payment processing)
CREATE POLICY "Authenticated users can create transactions"
    ON public.transactions FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL);

-- Role-specific profiles: Users can view their own role profile
CREATE POLICY "Users can view own rider profile"
    ON public.rider_profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can view own driver profile"
    ON public.fleet_driver_profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can view own merchant profile"
    ON public.merchant_profiles FOR SELECT
    USING (auth.uid() = id);

-- Additional indexes for phone number lookup (used by webhook callbacks)
CREATE UNIQUE INDEX idx_profiles_phone ON public.profiles(phone_number);

-- Functions for automatic timestamp updates
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for updating updated_at
CREATE TRIGGER set_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- RPC: Increment rider stats atomically (called after successful FUEL purchase)
CREATE OR REPLACE FUNCTION public.increment_rider_stats(
    p_rider_id UUID,
    p_fuel_amount DECIMAL,
    p_tx_count INTEGER DEFAULT 1
)
RETURNS VOID AS $$
BEGIN
    UPDATE public.rider_profiles
    SET
        total_fuel_purchased = total_fuel_purchased + p_fuel_amount,
        total_transactions = total_transactions + p_tx_count
    WHERE id = p_rider_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC: Increment merchant stats atomically (called after merchant settlement)
CREATE OR REPLACE FUNCTION public.increment_merchant_stats(
    p_merchant_id UUID,
    p_fuel_dispensed DECIMAL,
    p_revenue DECIMAL
)
RETURNS VOID AS $$
BEGIN
    UPDATE public.merchant_profiles
    SET
        total_fuel_dispensed = total_fuel_dispensed + p_fuel_dispensed,
        total_revenue = total_revenue + p_revenue
    WHERE id = p_merchant_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC: Rider dashboard stats aggregation
CREATE OR REPLACE FUNCTION public.rider_dashboard_stats(p_rider_id UUID)
RETURNS TABLE(
    total_fuel_purchased DECIMAL,
    total_transactions INTEGER,
    credit_score INTEGER,
    pending_transactions BIGINT,
    recent_tx_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        rp.total_fuel_purchased,
        rp.total_transactions,
        rp.credit_score,
        (SELECT COUNT(*) FROM public.transactions t
         WHERE t.from_user_id = p_rider_id AND t.status = 'pending') AS pending_transactions,
        (SELECT COUNT(*) FROM public.transactions t
         WHERE t.from_user_id = p_rider_id
           AND t.created_at >= NOW() - INTERVAL '30 days') AS recent_tx_count
    FROM public.rider_profiles rp
    WHERE rp.id = p_rider_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC: Merchant dashboard stats aggregation
CREATE OR REPLACE FUNCTION public.merchant_dashboard_stats(p_merchant_id UUID)
RETURNS TABLE(
    total_fuel_dispensed DECIMAL,
    total_revenue DECIMAL,
    pending_transactions BIGINT,
    today_revenue DECIMAL,
    today_transactions BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        mp.total_fuel_dispensed,
        mp.total_revenue,
        (SELECT COUNT(*) FROM public.transactions t
         WHERE t.to_user_id = p_merchant_id AND t.status = 'pending') AS pending_transactions,
        (SELECT COALESCE(SUM(t.amount), 0) FROM public.transactions t
         WHERE t.to_user_id = p_merchant_id
           AND t.created_at >= CURRENT_DATE
           AND t.status = 'completed') AS today_revenue,
        (SELECT COUNT(*) FROM public.transactions t
         WHERE t.to_user_id = p_merchant_id
           AND t.created_at >= CURRENT_DATE) AS today_transactions
    FROM public.merchant_profiles mp
    WHERE mp.id = p_merchant_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC: Find nearby merchants using Haversine distance formula
CREATE OR REPLACE FUNCTION public.nearby_merchants(
    p_lat DECIMAL,
    p_lng DECIMAL,
    p_radius_km DECIMAL DEFAULT 10
)
RETURNS TABLE(
    id UUID,
    station_name TEXT,
    station_id TEXT,
    location_lat DECIMAL,
    location_lng DECIMAL,
    distance_km DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        mp.id,
        mp.station_name,
        mp.station_id,
        mp.location_lat,
        mp.location_lng,
        ROUND(
            (6371 * ACOS(
                COS(RADIANS(p_lat)) * COS(RADIANS(mp.location_lat)) *
                COS(RADIANS(mp.location_lng) - RADIANS(p_lng)) +
                SIN(RADIANS(p_lat)) * SIN(RADIANS(mp.location_lat))
            ))::DECIMAL, 2
        ) AS distance_km
    FROM public.merchant_profiles mp
    WHERE mp.location_lat IS NOT NULL
      AND mp.location_lng IS NOT NULL
      AND (6371 * ACOS(
            COS(RADIANS(p_lat)) * COS(RADIANS(mp.location_lat)) *
            COS(RADIANS(mp.location_lng) - RADIANS(p_lng)) +
            SIN(RADIANS(p_lat)) * SIN(RADIANS(mp.location_lat))
          )) <= p_radius_km
    ORDER BY distance_km ASC
    LIMIT 50;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
