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
