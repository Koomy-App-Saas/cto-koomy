-- ============================================================================
-- KOOMY PROD_V2 — SCHEMA PATCH (IDEMPOTENT)
-- ============================================================================
-- Date: 2026-01-28
-- Purpose: Patch pour corriger le schema prod_v2 et permettre le boot Railway
-- Target: Firebase-only compatible
-- ============================================================================
-- SAFE TO RE-RUN: Toutes les commandes sont idempotentes
-- ============================================================================

-- ============================================================================
-- STEP 1: CREATE MISSING ENUMS (IF NOT EXISTS)
-- ============================================================================

DO $$ BEGIN
  CREATE TYPE subscription_status AS ENUM ('trialing', 'active', 'past_due', 'canceled');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE billing_status AS ENUM ('trialing', 'active', 'past_due', 'canceled', 'unpaid');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE member_status AS ENUM ('active', 'expired', 'suspended');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE contribution_status AS ENUM ('up_to_date', 'expired', 'pending', 'late');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE admin_role AS ENUM ('super_admin', 'support_admin', 'finance_admin', 'content_admin', 'admin');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE user_global_role AS ENUM ('platform_super_admin', 'platform_ops', 'platform_support', 'platform_finance', 'platform_commercial', 'platform_readonly');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE billing_period AS ENUM ('one_time', 'monthly', 'yearly');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE billing_mode AS ENUM ('self_service', 'manual_contract');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE white_label_tier AS ENUM ('basic', 'standard', 'premium');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE maintenance_status AS ENUM ('active', 'pending', 'late', 'stopped');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE stripe_connect_status AS ENUM ('NOT_CONNECTED', 'ONBOARDING_REQUIRED', 'PENDING_REVIEW', 'RESTRICTED', 'ACTIVE', 'DISCONNECTED');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE account_type AS ENUM ('STANDARD', 'GRAND_COMPTE');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE saas_client_status AS ENUM ('ACTIVE', 'IMPAYE_1', 'IMPAYE_2', 'SUSPENDU', 'RESILIE');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE purge_status AS ENUM ('scheduled', 'canceled_by_reactivation', 'executed');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE self_enrollment_channel AS ENUM ('OFFLINE', 'ONLINE');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE self_enrollment_mode AS ENUM ('OPEN', 'CLOSED');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE auth_mode AS ENUM ('FIREBASE_ONLY', 'LEGACY_ONLY');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE identity_provider AS ENUM ('FIREBASE', 'LEGACY_KOOMY');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE membership_billing_type AS ENUM ('one_time', 'annual');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE membership_plan_type AS ENUM ('FIXED_PERIOD', 'ROLLING_DURATION');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE fixed_period_type AS ENUM ('CALENDAR_YEAR', 'SEASON');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE membership_payment_status AS ENUM ('free', 'due', 'paid');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE salutation_enum AS ENUM ('M', 'Mme', 'Autre');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Additional enums required by events, news, payments, support
DO $$ BEGIN
  CREATE TYPE ticket_status AS ENUM ('open', 'in_progress', 'resolved', 'closed');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE ticket_priority AS ENUM ('low', 'medium', 'high');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE news_status AS ENUM ('draft', 'published');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE scope AS ENUM ('national', 'local');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE payment_status AS ENUM ('pending', 'completed', 'failed', 'refunded');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE payment_request_status AS ENUM ('pending', 'paid', 'expired', 'cancelled');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE email_type AS ENUM (
    'welcome_community_admin', 'invite_delegate', 'invite_member',
    'reset_password', 'verify_email', 'new_event', 'new_collection',
    'collection_contribution_thanks', 'message_to_admin'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE collection_status AS ENUM ('open', 'closed', 'canceled');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE transaction_type AS ENUM ('subscription', 'membership', 'collection');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE transaction_status AS ENUM ('pending', 'succeeded', 'failed', 'refunded');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE tag_type AS ENUM ('user', 'content', 'hybrid');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Event V2 enums
DO $$ BEGIN
  CREATE TYPE event_visibility_mode AS ENUM ('ALL', 'SECTION', 'TAGS');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE event_rsvp_mode AS ENUM ('NONE', 'OPTIONAL', 'REQUIRED', 'APPROVAL');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE event_status AS ENUM ('DRAFT', 'PUBLISHED', 'CANCELLED');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE event_registration_status AS ENUM ('GOING', 'NOT_GOING', 'WAITLIST', 'PENDING', 'CANCELLED');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE event_payment_status AS ENUM ('NONE', 'PENDING', 'PAID', 'FAILED', 'REFUNDED');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE attendance_source AS ENUM ('QR_SCAN', 'MANUAL');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE saas_transition_reason AS ENUM ('PAYMENT_FAILED', 'PAYMENT_SUCCEEDED', 'DELAY_EXPIRED', 'MANUAL');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE enrollment_request_status AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED', 'EXPIRED', 'CONVERTED');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE audit_action_enum AS ENUM (
    'login', 'logout', 'session_expired', 'session_renewed',
    'create_user', 'update_user', 'delete_user', 'update_role',
    'create_community', 'update_community', 'delete_community',
    'create_plan', 'update_plan', 'delete_plan',
    'grant_full_access', 'revoke_full_access',
    'stripe_connect_enabled', 'stripe_connect_disabled',
    'billing_mode_changed', 'white_label_enabled'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================================
-- STEP 2: ADD MISSING COLUMNS TO communities (CRITICAL FOR BOOT)
-- ============================================================================

-- CRITICAL: These columns are checked by server/index.ts validateDatabaseSchema()
ALTER TABLE communities ADD COLUMN IF NOT EXISTS max_admins_default INTEGER;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS contract_admin_limit INTEGER;

-- Other potentially missing columns (from shared/schema.ts)
ALTER TABLE communities ADD COLUMN IF NOT EXISTS billing_status billing_status DEFAULT 'active';
ALTER TABLE communities ADD COLUMN IF NOT EXISTS white_label BOOLEAN DEFAULT FALSE;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS white_label_tier white_label_tier;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS auth_mode auth_mode DEFAULT 'FIREBASE_ONLY';
ALTER TABLE communities ADD COLUMN IF NOT EXISTS billing_mode billing_mode DEFAULT 'self_service';
ALTER TABLE communities ADD COLUMN IF NOT EXISTS setup_fee_amount_cents INTEGER;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS setup_fee_currency TEXT DEFAULT 'EUR';
ALTER TABLE communities ADD COLUMN IF NOT EXISTS setup_fee_invoice_ref TEXT;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS maintenance_amount_year_cents INTEGER;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS maintenance_currency TEXT DEFAULT 'EUR';
ALTER TABLE communities ADD COLUMN IF NOT EXISTS maintenance_next_billing_date TIMESTAMP;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS maintenance_status maintenance_status;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS internal_notes TEXT;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS brand_config JSONB;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS branding_logo_path TEXT;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS branding_icon_path TEXT;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS branding_splash_path TEXT;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS branding_primary_color TEXT;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS branding_secondary_color TEXT;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS custom_domain TEXT;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS web_app_url TEXT;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS android_store_url TEXT;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS ios_store_url TEXT;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS white_label_included_members INTEGER;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS white_label_max_members_soft_limit INTEGER;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS white_label_additional_fee_per_member_cents INTEGER;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS account_type account_type DEFAULT 'STANDARD';
ALTER TABLE communities ADD COLUMN IF NOT EXISTS distribution_channels JSONB;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS contract_member_limit INTEGER;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS contract_member_alert_threshold INTEGER DEFAULT 90;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS member_id_prefix TEXT;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS member_id_counter INTEGER DEFAULT 0;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS saas_client_status saas_client_status DEFAULT 'ACTIVE';
ALTER TABLE communities ADD COLUMN IF NOT EXISTS saas_status_changed_at TIMESTAMP;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS unpaid_since TIMESTAMP;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS suspended_at TIMESTAMP;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS terminated_at TIMESTAMP;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS purge_scheduled_at TIMESTAMP;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS purge_status purge_status;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS purge_executed_at TIMESTAMP;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS self_enrollment_enabled BOOLEAN DEFAULT FALSE;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS self_enrollment_channel self_enrollment_channel DEFAULT 'OFFLINE';
ALTER TABLE communities ADD COLUMN IF NOT EXISTS self_enrollment_mode self_enrollment_mode DEFAULT 'OPEN';
ALTER TABLE communities ADD COLUMN IF NOT EXISTS self_enrollment_slug TEXT;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS self_enrollment_eligible_plans JSONB;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS self_enrollment_required_fields JSONB;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS self_enrollment_sections_enabled BOOLEAN DEFAULT FALSE;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS member_join_code TEXT;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS cgv_accepted_at TIMESTAMP;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS cgv_version TEXT;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS newsletter_opt_in BOOLEAN DEFAULT FALSE;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS full_access_granted_at TIMESTAMP;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS full_access_expires_at TIMESTAMP;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS full_access_reason TEXT;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS full_access_granted_by VARCHAR(50);
ALTER TABLE communities ADD COLUMN IF NOT EXISTS stripe_connect_account_id TEXT;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS stripe_connect_status stripe_connect_status DEFAULT 'NOT_CONNECTED';
ALTER TABLE communities ADD COLUMN IF NOT EXISTS stripe_connect_charges_enabled BOOLEAN DEFAULT FALSE;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS stripe_connect_payouts_enabled BOOLEAN DEFAULT FALSE;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS stripe_connect_details_submitted BOOLEAN DEFAULT FALSE;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS stripe_connect_last_sync_at TIMESTAMP;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS payments_enabled BOOLEAN DEFAULT FALSE;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS platform_fee_percent INTEGER DEFAULT 2;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS connect_fee_fixed_cents INTEGER DEFAULT 0;

-- ============================================================================
-- STEP 3: ENSURE users TABLE HAS firebase_uid
-- ============================================================================

ALTER TABLE users ADD COLUMN IF NOT EXISTS firebase_uid TEXT;

-- Add unique constraint if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE tablename = 'users' AND indexname = 'users_firebase_uid_key'
  ) THEN
    CREATE UNIQUE INDEX users_firebase_uid_key ON users(firebase_uid) WHERE firebase_uid IS NOT NULL;
  END IF;
END $$;

-- ============================================================================
-- STEP 4: ENSURE accounts TABLE EXISTS WITH CORRECT COLUMNS
-- ============================================================================
-- Note: password_hash is NULLABLE for Firebase-only accounts (auth_provider='firebase')
-- Firebase accounts use provider_id (Firebase UID) instead of password

CREATE TABLE IF NOT EXISTS accounts (
  id VARCHAR(50) PRIMARY KEY DEFAULT gen_random_uuid()::text,
  email TEXT NOT NULL,
  password_hash TEXT,
  first_name TEXT,
  last_name TEXT,
  avatar TEXT,
  auth_provider TEXT DEFAULT 'email',
  provider_id TEXT,
  created_at TIMESTAMP DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP DEFAULT NOW() NOT NULL
);

-- Add missing columns if table exists but columns don't
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS auth_provider TEXT DEFAULT 'email';
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS provider_id TEXT;

-- Make password_hash nullable if it was NOT NULL (for Firebase accounts)
ALTER TABLE accounts ALTER COLUMN password_hash DROP NOT NULL;

-- Add unique constraint on email if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE tablename = 'accounts' AND indexname = 'accounts_email_key'
  ) THEN
    ALTER TABLE accounts ADD CONSTRAINT accounts_email_key UNIQUE (email);
  END IF;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Add unique index on (auth_provider, provider_id) for Firebase auth lookups
-- This ensures one Firebase UID can only link to one account
CREATE UNIQUE INDEX IF NOT EXISTS accounts_auth_provider_provider_id_key 
  ON accounts(auth_provider, provider_id) 
  WHERE auth_provider IS NOT NULL AND provider_id IS NOT NULL;

-- ============================================================================
-- STEP 5: CREATE user_identities TABLE IF NOT EXISTS
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_identities (
  id VARCHAR(50) PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_id VARCHAR(50) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  provider identity_provider NOT NULL,
  provider_id TEXT NOT NULL,
  provider_email TEXT,
  metadata JSONB,
  is_primary BOOLEAN DEFAULT FALSE,
  linked_at TIMESTAMP DEFAULT NOW() NOT NULL,
  last_used_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW() NOT NULL
);

-- Create indexes if not exists
CREATE UNIQUE INDEX IF NOT EXISTS unique_provider_identity_idx ON user_identities(provider, provider_id);
CREATE UNIQUE INDEX IF NOT EXISTS user_provider_idx ON user_identities(user_id, provider);

-- ============================================================================
-- STEP 6: CREATE admin_invitations TABLE IF NOT EXISTS
-- ============================================================================

CREATE TABLE IF NOT EXISTS admin_invitations (
  id VARCHAR(50) PRIMARY KEY DEFAULT gen_random_uuid()::text,
  community_id VARCHAR(50) NOT NULL REFERENCES communities(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  token TEXT NOT NULL,
  invited_by VARCHAR(50) REFERENCES users(id),
  role TEXT DEFAULT 'admin' NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  accepted_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW() NOT NULL
);

-- Add unique constraint on token if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE tablename = 'admin_invitations' AND indexname = 'admin_invitations_token_key'
  ) THEN
    ALTER TABLE admin_invitations ADD CONSTRAINT admin_invitations_token_key UNIQUE (token);
  END IF;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================================
-- STEP 7: CREATE platform_sessions TABLE IF NOT EXISTS
-- ============================================================================

CREATE TABLE IF NOT EXISTS platform_sessions (
  id VARCHAR(50) PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_id VARCHAR(50) NOT NULL REFERENCES users(id),
  token TEXT NOT NULL,
  ip_address TEXT,
  user_agent TEXT,
  expires_at TIMESTAMP NOT NULL,
  revoked_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW() NOT NULL
);

-- Add unique constraint on token if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE tablename = 'platform_sessions' AND indexname = 'platform_sessions_token_key'
  ) THEN
    ALTER TABLE platform_sessions ADD CONSTRAINT platform_sessions_token_key UNIQUE (token);
  END IF;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================================
-- STEP 8: CREATE platform_verification_tokens TABLE IF NOT EXISTS
-- ============================================================================

CREATE TABLE IF NOT EXISTS platform_verification_tokens (
  id VARCHAR(50) PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_id VARCHAR(50) NOT NULL REFERENCES users(id),
  token TEXT NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  used_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW() NOT NULL
);

-- Add unique constraint on token if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE tablename = 'platform_verification_tokens' AND indexname = 'platform_verification_tokens_token_key'
  ) THEN
    ALTER TABLE platform_verification_tokens ADD CONSTRAINT platform_verification_tokens_token_key UNIQUE (token);
  END IF;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================================
-- STEP 9: ADD UNIQUE CONSTRAINTS TO communities (IF NOT EXISTS)
-- ============================================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE tablename = 'communities' AND indexname = 'communities_custom_domain_key'
  ) THEN
    CREATE UNIQUE INDEX communities_custom_domain_key ON communities(custom_domain) WHERE custom_domain IS NOT NULL;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE tablename = 'communities' AND indexname = 'communities_self_enrollment_slug_key'
  ) THEN
    CREATE UNIQUE INDEX communities_self_enrollment_slug_key ON communities(self_enrollment_slug) WHERE self_enrollment_slug IS NOT NULL;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE tablename = 'communities' AND indexname = 'communities_member_join_code_key'
  ) THEN
    CREATE UNIQUE INDEX communities_member_join_code_key ON communities(member_join_code) WHERE member_join_code IS NOT NULL;
  END IF;
END $$;

-- ============================================================================
-- VERIFICATION QUERIES (RUN AFTER PATCH)
-- ============================================================================
/*
-- 1. Check critical columns exist (MUST PASS for server boot)
SELECT column_name 
FROM information_schema.columns 
WHERE table_name = 'communities' 
  AND column_name IN ('max_admins_default', 'contract_admin_limit');
-- Expected: 2 rows

-- 2. Check firebase_uid on users
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'users' AND column_name = 'firebase_uid';
-- Expected: 1 row with TEXT type

-- 3. Check accounts table columns
SELECT column_name, is_nullable
FROM information_schema.columns 
WHERE table_name = 'accounts' 
  AND column_name IN ('provider_id', 'auth_provider', 'password_hash', 'email');
-- Expected: 4 rows, password_hash should be YES (nullable)

-- 4. Check unique index on accounts(auth_provider, provider_id)
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename = 'accounts' 
  AND indexname = 'accounts_auth_provider_provider_id_key';
-- Expected: 1 row with UNIQUE index

-- 5. List all tables
SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;

-- 6. Check all enums exist (should return 40+ enums)
SELECT typname FROM pg_type WHERE typtype = 'e' ORDER BY typname;

-- 7. Check for duplicate (auth_provider, provider_id) - should be 0
SELECT auth_provider, provider_id, COUNT(*) as cnt 
FROM accounts 
WHERE auth_provider IS NOT NULL AND provider_id IS NOT NULL 
GROUP BY auth_provider, provider_id 
HAVING COUNT(*) > 1;
-- Expected: 0 rows
*/

-- ============================================================================
-- END OF PATCH
-- ============================================================================
