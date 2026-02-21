-- FuelAnchor: Add email + password_hash to profiles for custom JWT auth
-- Also adds phone index for webhook phone→userId lookups
-- Date: 2026-02-21

-- Add email column for login lookup (unique, nullable to allow backfill)
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS email TEXT UNIQUE;

-- Add password_hash column (bcrypt hash stored in DB instead of in-memory)
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS password_hash TEXT;

-- Index for fast email lookups during login
CREATE INDEX IF NOT EXISTS idx_profiles_email
  ON public.profiles(email);

-- Index for fast phone number lookups (used by mobile money webhooks)
CREATE INDEX IF NOT EXISTS idx_profiles_phone
  ON public.profiles(phone_number);

-- Allow profiles to store fleet_operator role (existing check constraint may block)
-- Safe NO-OP if constraint already allows it
ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_role_check;

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_role_check
  CHECK (role IN ('rider', 'fleet_driver', 'merchant', 'fleet_operator', 'station_owner', 'admin'));
