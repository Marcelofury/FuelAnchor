-- FuelAnchor Phase 2 Schema: Fleet Management & Enhanced Stations
-- Run this after the initial schema migration

-- ============================================================
-- Enhance merchant_profiles for full station support
-- ============================================================

ALTER TABLE public.merchant_profiles 
  ADD COLUMN IF NOT EXISTS address TEXT,
  ADD COLUMN IF NOT EXISTS country TEXT DEFAULT 'KE',
  ADD COLUMN IF NOT EXISTS fuel_types JSONB DEFAULT '[]',
  ADD COLUMN IF NOT EXISTS geofence_radius_meters INTEGER DEFAULT 100,
  ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true,
  ADD COLUMN IF NOT EXISTS rating DECIMAL(3, 2) DEFAULT 0.0,
  ADD COLUMN IF NOT EXISTS stellar_secret_key TEXT; -- stored encrypted in production

-- ============================================================
-- Fleets table
-- ============================================================

CREATE TABLE IF NOT EXISTS public.fleets (
    id          UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name        TEXT NOT NULL,
    description TEXT,
    country     TEXT NOT NULL DEFAULT 'KE',
    vehicle_count   INTEGER DEFAULT 0,
    operator_id UUID REFERENCES public.profiles(id),
    stellar_public_key  TEXT,
    total_fuel_budget   DECIMAL(15, 2) DEFAULT 0,
    remaining_fuel_budget DECIMAL(15, 2) DEFAULT 0,
    driver_count INTEGER DEFAULT 0,
    is_active   BOOLEAN DEFAULT true,
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- Fleet members (drivers belonging to a fleet)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.fleet_members (
    id                  UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    fleet_id            UUID REFERENCES public.fleets(id) ON DELETE CASCADE NOT NULL,
    profile_id          UUID REFERENCES public.profiles(id) NOT NULL,
    vehicle_id          TEXT NOT NULL,
    daily_limit         DECIMAL(10, 2) DEFAULT 0,
    transaction_limit   DECIMAL(10, 2) DEFAULT 0,
    weekly_limit        DECIMAL(10, 2) DEFAULT 0,
    daily_spent         DECIMAL(10, 2) DEFAULT 0,
    weekly_spent        DECIMAL(10, 2) DEFAULT 0,
    allowed_stations    TEXT[] DEFAULT '{}',
    total_redemptions   INTEGER DEFAULT 0,
    is_active           BOOLEAN DEFAULT true,
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (fleet_id, profile_id)
);

-- ============================================================
-- Indexes
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_fleets_operator ON public.fleets(operator_id);
CREATE INDEX IF NOT EXISTS idx_fleet_members_fleet ON public.fleet_members(fleet_id);
CREATE INDEX IF NOT EXISTS idx_fleet_members_profile ON public.fleet_members(profile_id);
CREATE INDEX IF NOT EXISTS idx_merchant_profiles_active ON public.merchant_profiles(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_merchant_profiles_country ON public.merchant_profiles(country);

-- ============================================================
-- RLS policies for new tables
-- ============================================================

ALTER TABLE public.fleets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fleet_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Fleet operators can manage their fleets"
    ON public.fleets FOR ALL
    USING (auth.uid() = operator_id);

CREATE POLICY "Fleet members can view their fleet"
    ON public.fleets FOR SELECT
    USING (
        auth.uid() = operator_id OR
        EXISTS (
            SELECT 1 FROM public.fleet_members
            WHERE fleet_id = fleets.id AND profile_id = auth.uid()
        )
    );

CREATE POLICY "Fleet operators can manage members"
    ON public.fleet_members FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.fleets
            WHERE id = fleet_members.fleet_id AND operator_id = auth.uid()
        )
    );

CREATE POLICY "Members can view their own fleet membership"
    ON public.fleet_members FOR SELECT
    USING (auth.uid() = profile_id);

-- ============================================================
-- RPC: Reset daily/weekly spending (call via cron)
-- ============================================================

CREATE OR REPLACE FUNCTION public.reset_daily_fleet_spending()
RETURNS VOID AS $$
BEGIN
    UPDATE public.fleet_members SET daily_spent = 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.reset_weekly_fleet_spending()
RETURNS VOID AS $$
BEGIN
    UPDATE public.fleet_members SET weekly_spent = 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- RPC: Fleet analytics summary
-- ============================================================

CREATE OR REPLACE FUNCTION public.fleet_analytics(p_fleet_id UUID)
RETURNS TABLE(
    total_budget        DECIMAL,
    remaining_budget    DECIMAL,
    driver_count        BIGINT,
    active_drivers      BIGINT,
    total_redemptions   BIGINT,
    avg_per_driver      DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        f.total_fuel_budget,
        f.remaining_fuel_budget,
        COUNT(fm.id),
        COUNT(fm.id) FILTER (WHERE fm.is_active),
        SUM(fm.total_redemptions)::BIGINT,
        CASE WHEN COUNT(fm.id) > 0
            THEN ROUND((f.total_fuel_budget - f.remaining_fuel_budget) / COUNT(fm.id), 2)
            ELSE 0
        END
    FROM public.fleets f
    LEFT JOIN public.fleet_members fm ON fm.fleet_id = f.id
    WHERE f.id = p_fleet_id
    GROUP BY f.id, f.total_fuel_budget, f.remaining_fuel_budget;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- Update updated_at trigger for fleets
-- ============================================================

CREATE TRIGGER set_fleet_updated_at
    BEFORE UPDATE ON public.fleets
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();
