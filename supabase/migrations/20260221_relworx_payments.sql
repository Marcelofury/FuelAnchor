-- Relworx Payment Gateway: payments tracking table
-- Apply this in Supabase Dashboard → SQL Editor

-- Enable UUID extension (already exists in Supabase by default)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ─── Relworx payments table ───────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS relworx_payments (
  id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id                 UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  amount                  DECIMAL(12, 2) NOT NULL,
  currency                VARCHAR(3) NOT NULL DEFAULT 'UGX',
  type                    VARCHAR(20) NOT NULL CHECK (type IN ('collection', 'disbursement')),
  status                  VARCHAR(20) NOT NULL DEFAULT 'pending'
                            CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
  transaction_ref         VARCHAR(60) UNIQUE NOT NULL,       -- our reference (FUEL-...)
  internal_reference      VARCHAR(100),                      -- Relworx internal reference
  provider_transaction_id VARCHAR(100),                      -- provider TXN ID (MTN/Airtel)
  phone_number            VARCHAR(20) NOT NULL,
  provider                VARCHAR(30),                       -- MTN_UGANDA | AIRTEL_UGANDA
  description             TEXT,
  metadata                JSONB,
  completed_at            TIMESTAMPTZ,
  created_at              TIMESTAMPTZ DEFAULT NOW(),
  updated_at              TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for common lookups
CREATE INDEX IF NOT EXISTS idx_relworx_payments_user_id
  ON relworx_payments(user_id);

CREATE INDEX IF NOT EXISTS idx_relworx_payments_transaction_ref
  ON relworx_payments(transaction_ref);

CREATE INDEX IF NOT EXISTS idx_relworx_payments_internal_ref
  ON relworx_payments(internal_reference);

CREATE INDEX IF NOT EXISTS idx_relworx_payments_status
  ON relworx_payments(status);

CREATE INDEX IF NOT EXISTS idx_relworx_payments_created_at
  ON relworx_payments(created_at DESC);

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_relworx_payments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_relworx_payments_updated_at
  BEFORE UPDATE ON relworx_payments
  FOR EACH ROW EXECUTE FUNCTION update_relworx_payments_updated_at();

-- Row Level Security
ALTER TABLE relworx_payments ENABLE ROW LEVEL SECURITY;

-- Users can only see their own payments
CREATE POLICY relworx_payments_user_select
  ON relworx_payments FOR SELECT
  USING (user_id = auth.uid() OR EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
  ));

-- Only backend (service role) inserts/updates
CREATE POLICY relworx_payments_service_all
  ON relworx_payments FOR ALL
  USING (auth.role() = 'service_role');
