-- ============================================================================
-- KOOMY PRODUCTION V2 — SCHEMA REBUILD (MINIMAL)
-- ============================================================================
-- Date: 2026-01-28
-- Purpose: Clean PostgreSQL schema for prod_v2 (Neon) - MINIMAL BOOT
-- Target: Boot API + Firebase Auth + SaaS Owner + Community Creation + Plans
-- ============================================================================
-- STRICTEMENT AUCUNE DONNÉE / AUCUN INSERT / PAS DE SEED
-- ============================================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- SECTION 1: ENUMS (Only those required by included tables)
-- ============================================================================

-- Subscription & Billing
CREATE TYPE subscription_status AS ENUM ('trialing', 'active', 'past_due', 'canceled');
CREATE TYPE billing_status AS ENUM ('trialing', 'active', 'past_due', 'canceled', 'unpaid');
CREATE TYPE billing_period AS ENUM ('one_time', 'monthly', 'yearly');
CREATE TYPE billing_mode AS ENUM ('self_service', 'manual_contract');

-- Member Status
CREATE TYPE member_status AS ENUM ('active', 'expired', 'suspended');
CREATE TYPE contribution_status AS ENUM ('up_to_date', 'expired', 'pending', 'late');
CREATE TYPE membership_payment_status AS ENUM ('free', 'due', 'paid');

-- Admin & Platform Roles
CREATE TYPE admin_role AS ENUM ('super_admin', 'support_admin', 'finance_admin', 'content_admin', 'admin');
CREATE TYPE user_global_role AS ENUM (
  'platform_super_admin',
  'platform_ops',
  'platform_support',
  'platform_finance',
  'platform_commercial',
  'platform_readonly'
);

-- Identity & Auth
CREATE TYPE auth_mode AS ENUM ('FIREBASE_ONLY', 'LEGACY_ONLY');
CREATE TYPE identity_provider AS ENUM ('FIREBASE', 'LEGACY_KOOMY');

-- White Label
CREATE TYPE white_label_tier AS ENUM ('basic', 'standard', 'premium');
CREATE TYPE maintenance_status AS ENUM ('active', 'pending', 'late', 'stopped');

-- Stripe Connect
CREATE TYPE stripe_connect_status AS ENUM (
  'NOT_CONNECTED',
  'ONBOARDING_REQUIRED',
  'PENDING_REVIEW',
  'RESTRICTED',
  'ACTIVE',
  'DISCONNECTED'
);

-- Account Type
CREATE TYPE account_type AS ENUM ('STANDARD', 'GRAND_COMPTE');

-- SaaS Client Status
CREATE TYPE saas_client_status AS ENUM ('ACTIVE', 'IMPAYE_1', 'IMPAYE_2', 'SUSPENDU', 'RESILIE');
CREATE TYPE purge_status AS ENUM ('scheduled', 'canceled_by_reactivation', 'executed');

-- Self-Enrollment
CREATE TYPE self_enrollment_channel AS ENUM ('OFFLINE', 'ONLINE');
CREATE TYPE self_enrollment_mode AS ENUM ('OPEN', 'CLOSED');

-- Salutation
CREATE TYPE salutation_enum AS ENUM ('M', 'Mme', 'Autre');

-- Membership Plans
CREATE TYPE membership_billing_type AS ENUM ('one_time', 'annual');
CREATE TYPE membership_plan_type AS ENUM ('FIXED_PERIOD', 'ROLLING_DURATION');
CREATE TYPE fixed_period_type AS ENUM ('CALENDAR_YEAR', 'SEASON');

-- ============================================================================
-- SECTION 2: CORE TABLES (STRICTLY REQUIRED FOR BOOT)
-- ============================================================================

-- 1. Plans (SaaS subscription plans) - CRITICAL
CREATE TABLE plans (
  id VARCHAR(50) PRIMARY KEY,
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  description TEXT,
  tagline TEXT,
  max_members INTEGER,
  max_admins INTEGER,
  max_tags INTEGER,
  price_monthly INTEGER,
  price_yearly INTEGER,
  features JSONB NOT NULL DEFAULT '[]',
  capabilities JSONB DEFAULT '{}',
  policies JSONB,
  is_popular BOOLEAN DEFAULT FALSE,
  is_public BOOLEAN DEFAULT TRUE,
  is_custom BOOLEAN DEFAULT FALSE,
  is_white_label BOOLEAN DEFAULT FALSE,
  sort_order INTEGER DEFAULT 0,
  updated_at TIMESTAMP DEFAULT NOW(),
  updated_by VARCHAR(50)
);

-- 2. Users (Back-office admins and platform admins) - CRITICAL
CREATE TABLE users (
  id VARCHAR(50) PRIMARY KEY DEFAULT gen_random_uuid()::text,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  password TEXT,
  phone TEXT,
  avatar TEXT,
  global_role user_global_role,
  is_platform_owner BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT FALSE,
  email_verified_at TIMESTAMP,
  failed_login_attempts INTEGER DEFAULT 0,
  locked_until TIMESTAMP,
  firebase_uid TEXT UNIQUE,
  created_at TIMESTAMP DEFAULT NOW() NOT NULL
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_firebase_uid ON users(firebase_uid);
CREATE INDEX idx_users_global_role ON users(global_role);

-- 3. User Identities (Identity Contract Phase 2 - multi-provider) - CRITICAL
CREATE TABLE user_identities (
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

CREATE UNIQUE INDEX unique_provider_identity_idx ON user_identities(provider, provider_id);
CREATE UNIQUE INDEX user_provider_idx ON user_identities(user_id, provider);

-- 4. Communities (Tenants) - CRITICAL
CREATE TABLE communities (
  id VARCHAR(50) PRIMARY KEY DEFAULT gen_random_uuid()::text,
  owner_id VARCHAR(50) REFERENCES users(id),
  name TEXT NOT NULL,
  community_type TEXT NOT NULL DEFAULT 'association',
  community_type_other TEXT,
  category TEXT,
  logo TEXT,
  primary_color TEXT DEFAULT '207 100% 63%',
  secondary_color TEXT DEFAULT '350 80% 55%',
  description TEXT,
  address TEXT,
  city TEXT,
  postal_code TEXT,
  country TEXT DEFAULT 'France',
  contact_email TEXT,
  contact_phone TEXT,
  siret TEXT,
  iban TEXT,
  bic TEXT,
  website TEXT,
  facebook TEXT,
  twitter TEXT,
  instagram TEXT,
  linkedin TEXT,
  membership_start_date TIMESTAMP,
  membership_end_date TIMESTAMP,
  welcome_message TEXT,
  membership_fee_enabled BOOLEAN DEFAULT FALSE,
  membership_fee_amount INTEGER,
  currency TEXT DEFAULT 'EUR',
  billing_period billing_period DEFAULT 'yearly',
  stripe_price_id TEXT,
  stripe_product_id TEXT,
  stripe_customer_id TEXT,
  stripe_subscription_id TEXT,
  member_count INTEGER DEFAULT 0,
  plan_id VARCHAR(50) NOT NULL REFERENCES plans(id),
  subscription_status subscription_status DEFAULT 'active',
  billing_status billing_status DEFAULT 'active',
  trial_ends_at TIMESTAMP,
  current_period_end TIMESTAMP,
  full_access_granted_at TIMESTAMP,
  full_access_expires_at TIMESTAMP,
  full_access_reason TEXT,
  full_access_granted_by VARCHAR(50),
  stripe_connect_account_id TEXT,
  stripe_connect_status stripe_connect_status DEFAULT 'NOT_CONNECTED',
  stripe_connect_charges_enabled BOOLEAN DEFAULT FALSE,
  stripe_connect_payouts_enabled BOOLEAN DEFAULT FALSE,
  stripe_connect_details_submitted BOOLEAN DEFAULT FALSE,
  stripe_connect_last_sync_at TIMESTAMP,
  payments_enabled BOOLEAN DEFAULT FALSE,
  platform_fee_percent INTEGER DEFAULT 2,
  connect_fee_fixed_cents INTEGER DEFAULT 0,
  max_members_allowed INTEGER,
  max_admins_default INTEGER,
  white_label BOOLEAN DEFAULT FALSE,
  white_label_tier white_label_tier,
  auth_mode auth_mode DEFAULT 'FIREBASE_ONLY',
  billing_mode billing_mode DEFAULT 'self_service',
  setup_fee_amount_cents INTEGER,
  setup_fee_currency TEXT DEFAULT 'EUR',
  setup_fee_invoice_ref TEXT,
  maintenance_amount_year_cents INTEGER,
  maintenance_currency TEXT DEFAULT 'EUR',
  maintenance_next_billing_date TIMESTAMP,
  maintenance_status maintenance_status,
  internal_notes TEXT,
  brand_config JSONB,
  branding_logo_path TEXT,
  branding_icon_path TEXT,
  branding_splash_path TEXT,
  branding_primary_color TEXT,
  branding_secondary_color TEXT,
  custom_domain TEXT UNIQUE,
  web_app_url TEXT,
  android_store_url TEXT,
  ios_store_url TEXT,
  white_label_included_members INTEGER,
  white_label_max_members_soft_limit INTEGER,
  white_label_additional_fee_per_member_cents INTEGER,
  account_type account_type DEFAULT 'STANDARD',
  distribution_channels JSONB,
  contract_member_limit INTEGER,
  contract_admin_limit INTEGER,
  contract_member_alert_threshold INTEGER DEFAULT 90,
  member_id_prefix TEXT,
  member_id_counter INTEGER DEFAULT 0,
  saas_client_status saas_client_status DEFAULT 'ACTIVE',
  saas_status_changed_at TIMESTAMP,
  unpaid_since TIMESTAMP,
  suspended_at TIMESTAMP,
  terminated_at TIMESTAMP,
  purge_scheduled_at TIMESTAMP,
  purge_status purge_status,
  purge_executed_at TIMESTAMP,
  self_enrollment_enabled BOOLEAN DEFAULT FALSE,
  self_enrollment_channel self_enrollment_channel DEFAULT 'OFFLINE',
  self_enrollment_mode self_enrollment_mode DEFAULT 'OPEN',
  self_enrollment_slug TEXT UNIQUE,
  self_enrollment_eligible_plans JSONB,
  self_enrollment_required_fields JSONB,
  self_enrollment_sections_enabled BOOLEAN DEFAULT FALSE,
  member_join_code TEXT UNIQUE,
  cgv_accepted_at TIMESTAMP,
  cgv_version TEXT,
  newsletter_opt_in BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW() NOT NULL
);

CREATE INDEX idx_communities_owner_id ON communities(owner_id);
CREATE INDEX idx_communities_plan_id ON communities(plan_id);
CREATE INDEX idx_communities_saas_status ON communities(saas_client_status);
CREATE INDEX idx_communities_custom_domain ON communities(custom_domain);

-- 5. Accounts (Mobile app users / members) - CRITICAL
CREATE TABLE accounts (
  id VARCHAR(50) PRIMARY KEY DEFAULT gen_random_uuid()::text,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  first_name TEXT,
  last_name TEXT,
  avatar TEXT,
  auth_provider TEXT DEFAULT 'email',
  provider_id TEXT,
  created_at TIMESTAMP DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP DEFAULT NOW() NOT NULL
);

CREATE INDEX idx_accounts_email ON accounts(email);
CREATE INDEX idx_accounts_provider_id ON accounts(provider_id);

-- 6. Sections (Regional/local divisions) - REQUIRED for multi-section communities
CREATE TABLE sections (
  id VARCHAR(50) PRIMARY KEY DEFAULT gen_random_uuid()::text,
  community_id VARCHAR(50) NOT NULL REFERENCES communities(id),
  name TEXT NOT NULL,
  code VARCHAR(50),
  type VARCHAR(50),
  note TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  sort_order INTEGER DEFAULT 0
);

CREATE INDEX idx_sections_community_id ON sections(community_id);

-- 7. Membership Plans (per community) - REQUIRED for paid memberships
CREATE TABLE membership_plans (
  id VARCHAR(50) PRIMARY KEY DEFAULT gen_random_uuid()::text,
  community_id VARCHAR(50) NOT NULL REFERENCES communities(id),
  name TEXT NOT NULL,
  slug TEXT NOT NULL,
  tagline TEXT,
  amount INTEGER NOT NULL DEFAULT 0,
  currency TEXT DEFAULT 'EUR',
  billing_type membership_billing_type DEFAULT 'annual',
  membership_type membership_plan_type DEFAULT 'FIXED_PERIOD',
  fixed_period_type fixed_period_type,
  rolling_duration_months INTEGER,
  description TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP DEFAULT NOW() NOT NULL
);

CREATE INDEX idx_membership_plans_community_id ON membership_plans(community_id);

-- 8. User Community Memberships (Junction with role info) - CRITICAL
CREATE TABLE user_community_memberships (
  id VARCHAR(50) PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_id VARCHAR(50) REFERENCES users(id),
  account_id VARCHAR(50) REFERENCES accounts(id),
  community_id VARCHAR(50) NOT NULL REFERENCES communities(id),
  member_id TEXT NOT NULL,
  claim_code TEXT,
  display_name TEXT,
  salutation salutation_enum,
  first_name TEXT,
  last_name TEXT,
  profile_data JSONB,
  email TEXT,
  phone TEXT,
  role TEXT NOT NULL,
  admin_role admin_role,
  status member_status DEFAULT 'active',
  section TEXT,
  join_date TIMESTAMP DEFAULT NOW() NOT NULL,
  contribution_status contribution_status DEFAULT 'pending',
  next_due_date TIMESTAMP,
  claimed_at TIMESTAMP,
  membership_plan_id VARCHAR(50) REFERENCES membership_plans(id),
  membership_price_custom INTEGER,
  membership_currency TEXT DEFAULT 'EUR',
  membership_payment_status membership_payment_status DEFAULT 'free',
  membership_amount_due INTEGER DEFAULT 0,
  membership_paid_at TIMESTAMP,
  membership_valid_until TIMESTAMP,
  membership_amount_paid INTEGER,
  membership_payment_provider TEXT,
  membership_payment_reference TEXT,
  membership_start_date TIMESTAMP,
  membership_season_label TEXT,
  can_manage_articles BOOLEAN DEFAULT TRUE,
  can_manage_events BOOLEAN DEFAULT TRUE,
  can_manage_collections BOOLEAN DEFAULT TRUE,
  can_manage_messages BOOLEAN DEFAULT TRUE,
  can_manage_members BOOLEAN DEFAULT TRUE,
  can_scan_presence BOOLEAN DEFAULT TRUE,
  is_owner BOOLEAN DEFAULT FALSE,
  section_scope TEXT DEFAULT 'ALL',
  section_ids JSONB,
  permissions JSONB DEFAULT '[]',
  suspended_by_quota_limit BOOLEAN DEFAULT FALSE
);

CREATE INDEX idx_memberships_user_id ON user_community_memberships(user_id);
CREATE INDEX idx_memberships_account_id ON user_community_memberships(account_id);
CREATE INDEX idx_memberships_community_id ON user_community_memberships(community_id);
CREATE INDEX idx_memberships_role ON user_community_memberships(role);
CREATE INDEX idx_memberships_member_id ON user_community_memberships(member_id);
CREATE INDEX idx_memberships_claim_code ON user_community_memberships(claim_code);

-- ============================================================================
-- SECTION 3: AUTHENTICATION & SECURITY TABLES
-- ============================================================================

-- 9. Platform Verification Tokens (email verification) - CRITICAL
CREATE TABLE platform_verification_tokens (
  id VARCHAR(50) PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_id VARCHAR(50) NOT NULL REFERENCES users(id),
  token TEXT NOT NULL UNIQUE,
  expires_at TIMESTAMP NOT NULL,
  used_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW() NOT NULL
);

CREATE INDEX idx_platform_verification_tokens_user ON platform_verification_tokens(user_id);
CREATE INDEX idx_platform_verification_tokens_token ON platform_verification_tokens(token);

-- 10. Platform Sessions (2-hour expiration) - CRITICAL
CREATE TABLE platform_sessions (
  id VARCHAR(50) PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_id VARCHAR(50) NOT NULL REFERENCES users(id),
  token TEXT NOT NULL UNIQUE,
  ip_address TEXT,
  user_agent TEXT,
  expires_at TIMESTAMP NOT NULL,
  revoked_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW() NOT NULL
);

CREATE INDEX idx_platform_sessions_user ON platform_sessions(user_id);
CREATE INDEX idx_platform_sessions_token ON platform_sessions(token);
CREATE INDEX idx_platform_sessions_expires ON platform_sessions(expires_at);

-- 11. Admin Invitations (auth-first-then-join flow) - CRITICAL
CREATE TABLE admin_invitations (
  id VARCHAR(50) PRIMARY KEY DEFAULT gen_random_uuid()::text,
  community_id VARCHAR(50) NOT NULL REFERENCES communities(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  token TEXT NOT NULL UNIQUE,
  invited_by VARCHAR(50) REFERENCES users(id),
  role TEXT DEFAULT 'admin' NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  accepted_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW() NOT NULL
);

CREATE INDEX idx_admin_invitations_community ON admin_invitations(community_id);
CREATE INDEX idx_admin_invitations_email ON admin_invitations(email);
CREATE INDEX idx_admin_invitations_token ON admin_invitations(token);

-- 12. Community Member Profile Config - USEFUL
CREATE TABLE community_member_profile_config (
  id VARCHAR(50) PRIMARY KEY DEFAULT gen_random_uuid()::text,
  community_id VARCHAR(50) NOT NULL REFERENCES communities(id) UNIQUE,
  enabled_fields JSONB,
  required_fields JSONB,
  visibility JSONB,
  created_at TIMESTAMP DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP DEFAULT NOW() NOT NULL
);

-- ============================================================================
-- DOCUMENTATION
-- ============================================================================
/*
================================================================================
TABLES INCLUSES (12 tables - MINIMAL BOOT)
================================================================================

CORE IDENTITY & AUTH (6 tables):
1. plans                          → SaaS plan definitions
2. users                          → Back-office admins, platform admins  
3. user_identities                → Firebase/Legacy identity links
4. accounts                       → Mobile app member accounts
5. platform_verification_tokens   → Email verification
6. platform_sessions              → Session management (2h expiry)

CORE BUSINESS (6 tables):
7. communities                    → Tenant/community data
8. user_community_memberships     → Member/admin junction table
9. sections                       → Sections/regions per community
10. membership_plans              → Membership plan definitions
11. admin_invitations             → Admin invitation flow
12. community_member_profile_config → Profile field configuration

================================================================================
TABLES EXCLUES (volontairement)
================================================================================

CONTENT & FEATURES (Phase 2 - ajoutables après boot):
- news_articles          → Articles/news content
- categories             → Article categories
- events                 → Events system
- event_registrations    → Event RSVP
- event_attendance       → Event presence
- messages               → Member-admin messaging
- tags                   → Member/content segmentation
- member_tags            → Member-tag pivot
- article_tags           → Article-tag pivot
- article_sections       → Article-section pivot

PAYMENTS (Phase 2 - après Stripe Connect):
- collections            → Fundraising campaigns
- transactions           → Unified payment tracking
- payments               → Legacy payments
- payment_requests       → Payment requests
- membership_fees        → DEPRECATED

AUDIT & LOGS (Phase 2 - après stabilisation):
- platform_audit_logs         → Platform admin action audit
- contract_audit_log          → Contract change audit
- subscription_status_audit   → SaaS status transitions
- subscription_emails_sent    → Anti-duplicate email tracking
- email_logs                  → Email delivery tracking

ANALYTICS (Phase 2):
- platform_metrics_daily      → Health monitoring
- community_monthly_usage     → Usage quotas

SUPPORT (Phase 2):
- support_tickets             → Support system
- ticket_responses            → Ticket replies
- faqs                        → FAQ system

COMMERCIAL (Phase 2):
- commercial_contacts         → Website leads
- email_templates             → Email templates

SELF-ENROLLMENT (Phase 2):
- enrollment_requests         → Join link system

================================================================================
HYPOTHÈSES PRISES
================================================================================

1. Firebase Auth est le provider principal pour communautés standard
   (authMode = FIREBASE_ONLY)

2. Legacy auth (password in users.password) uniquement pour:
   - White-Label communities (authMode = LEGACY_ONLY)
   - SaaS Owner Platform admin

3. Plans seront seedés après création du schéma:
   - FREE (20 membres, 1 admin)
   - PLUS (100 membres, 3 admins)
   - PRO (250 membres, 10 admins)
   - GRAND_COMPTE (unlimited)

4. SaaS Owner créé manuellement:
   - global_role = 'platform_super_admin'
   - is_platform_owner = TRUE
   - is_active = TRUE

5. Stripe Connect configuré après boot pour paiements

6. Tables de contenu (articles, events, messages) ajoutées en Phase 2
   une fois le boot validé

================================================================================
POST-INSTALLATION (voir scripts séparés)
================================================================================

1. Créer la base de données prod_v2 sur Neon
2. Exécuter ce script SQL (schéma uniquement)
3. Exécuter le script de seed plans (fichier séparé: plans-seed.sql)
4. Créer le SaaS Owner via script dédié (fichier séparé: owner-seed.sql)
5. Configurer DATABASE_URL dans les variables d'environnement
6. Redémarrer l'API

Note: Les scripts de seed sont dans des fichiers séparés conformément
à la règle "AUCUN INSERT dans ce fichier".

================================================================================
AJOUT DES TABLES PHASE 2
================================================================================

Après validation du boot, exécuter les scripts d'extension:
- prod_v2_phase2_content.sql   (articles, events, messages)
- prod_v2_phase2_payments.sql  (collections, transactions)
- prod_v2_phase2_audit.sql     (audit logs)
- prod_v2_phase2_analytics.sql (metrics)

================================================================================
*/
