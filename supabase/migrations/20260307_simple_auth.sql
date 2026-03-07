-- Migration: Simple Username/Password Authentication
-- Date: 2026-03-07
-- Purpose: Enable username/password authentication stored directly in database

-- Step 1: Drop all existing data (CAREFUL - only for development)
-- TRUNCATE TABLE public.transactions CASCADE;
-- TRUNCATE TABLE public.fuel_quotas CASCADE;
-- TRUNCATE TABLE public.rider_profiles CASCADE;
-- TRUNCATE TABLE public.fleet_driver_profiles CASCADE;
-- TRUNCATE TABLE public.merchant_profiles CASCADE;
-- TRUNCATE TABLE public.profiles CASCADE;

-- Step 2: Drop existing foreign key constraint to auth.users
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_id_fkey;

-- Step 3: Make id column independent (remove PRIMARY KEY temporarily if needed)
ALTER TABLE public.profiles ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.profiles ALTER COLUMN id SET DEFAULT uuid_generate_v4();

-- Step 4: Add username and password_hash columns
ALTER TABLE public.profiles 
    ADD COLUMN IF NOT EXISTS username TEXT,
    ADD COLUMN IF NOT EXISTS password_hash TEXT;

-- Step 5: Make username and password_hash NOT NULL (after adding columns)
-- First, update any existing rows with dummy values (if any exist)
UPDATE public.profiles SET username = 'user_' || id::text WHERE username IS NULL;
UPDATE public.profiles SET password_hash = 'legacy_' || id::text WHERE password_hash IS NULL;

-- Now make them NOT NULL
ALTER TABLE public.profiles ALTER COLUMN username SET NOT NULL;
ALTER TABLE public.profiles ALTER COLUMN password_hash SET NOT NULL;

-- Step 6: Add unique constraint on username
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_username_key;
ALTER TABLE public.profiles ADD CONSTRAINT profiles_username_key UNIQUE (username);

-- Step 7: Update role check constraint to include fleet_manager
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_role_check;
ALTER TABLE public.profiles 
    ADD CONSTRAINT profiles_role_check 
    CHECK (role IN ('rider', 'fleet_driver', 'fleetDriver', 'fleet_manager', 'fleetManager', 'merchant'));

-- Create index on username for faster lookups
CREATE INDEX IF NOT EXISTS idx_profiles_username ON public.profiles(username);
CREATE INDEX IF NOT EXISTS idx_profiles_phone ON public.profiles(phone_number);

-- Update RLS policies to work without auth.uid()
-- Drop old policies
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;

-- Create new policies for public read (more permissive for now)
CREATE POLICY "Enable read access for all users" 
    ON public.profiles FOR SELECT 
    USING (true);

CREATE POLICY "Enable insert for new users" 
    ON public.profiles FOR INSERT 
    WITH CHECK (true);

CREATE POLICY "Enable update for all users" 
    ON public.profiles FOR UPDATE 
    USING (true);

-- Add fleet_manager_profiles table if not exists
CREATE TABLE IF NOT EXISTS public.fleet_manager_profiles (
    id UUID REFERENCES public.profiles(id) PRIMARY KEY,
    fleet_name TEXT NOT NULL,
    total_vehicles INTEGER DEFAULT 0,
    total_drivers INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS on fleet_manager_profiles
ALTER TABLE public.fleet_manager_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable all access to fleet_manager_profiles" 
    ON public.fleet_manager_profiles 
    USING (true);

-- Update other tables RLS to be more permissive
DROP POLICY IF EXISTS "Users can view own rider profile" ON public.rider_profiles;
DROP POLICY IF EXISTS "Users can view own fleet driver profile" ON public.fleet_driver_profiles;
DROP POLICY IF EXISTS "Users can view own merchant profile" ON public.merchant_profiles;

CREATE POLICY "Enable all access to rider_profiles" 
    ON public.rider_profiles 
    USING (true);

CREATE POLICY "Enable all access to fleet_driver_profiles" 
    ON public.fleet_driver_profiles 
    USING (true);

CREATE POLICY "Enable all access to merchant_profiles" 
    ON public.merchant_profiles 
    USING (true);

CREATE POLICY "Enable all access to transactions" 
    ON public.transactions 
    USING (true);

CREATE POLICY "Enable all access to fuel_quotas" 
    ON public.fuel_quotas 
    USING (true);

-- Add comments
COMMENT ON COLUMN public.profiles.username IS 'Unique username for authentication';
COMMENT ON COLUMN public.profiles.password_hash IS 'Hashed password for authentication';
COMMENT ON TABLE public.fleet_manager_profiles IS 'Fleet manager specific profile data';
