-- STEP 0: CREATE BASE TABLES (execute BEFORE step 2)
-- This creates the core tables that must exist before adding columns

-- Plans table (must exist before communities)
CREATE TABLE IF NOT EXISTS plans (
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

-- Users table (must exist before communities for owner_id FK)
CREATE TABLE IF NOT EXISTS users (
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

-- Communities table
CREATE TABLE IF NOT EXISTS communities (
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
  trial_ends_at TIMESTAMP,
  current_period_end TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW() NOT NULL
);

-- Accounts table (for mobile app members)
CREATE TABLE IF NOT EXISTS accounts (
  id VARCHAR(50) PRIMARY KEY DEFAULT gen_random_uuid()::text,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT,
  first_name TEXT,
  last_name TEXT,
  avatar TEXT,
  auth_provider TEXT DEFAULT 'email',
  provider_id TEXT,
  created_at TIMESTAMP DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP DEFAULT NOW() NOT NULL
);

-- Sections table
CREATE TABLE IF NOT EXISTS sections (
  id VARCHAR(50) PRIMARY KEY DEFAULT gen_random_uuid()::text,
  community_id VARCHAR(50) NOT NULL REFERENCES communities(id),
  name TEXT NOT NULL,
  code VARCHAR(50),
  type VARCHAR(50),
  note TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  sort_order INTEGER DEFAULT 0
);

-- User Community Memberships (junction table)
CREATE TABLE IF NOT EXISTS user_community_memberships (
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
  membership_plan_id VARCHAR(50),
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

-- Membership Plans
CREATE TABLE IF NOT EXISTS membership_plans (
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

-- News Articles
CREATE TABLE IF NOT EXISTS news_articles (
  id VARCHAR(50) PRIMARY KEY DEFAULT gen_random_uuid()::text,
  community_id VARCHAR(50) NOT NULL REFERENCES communities(id),
  title TEXT NOT NULL,
  summary TEXT NOT NULL,
  content TEXT NOT NULL,
  category TEXT,
  category_id VARCHAR(50),
  image TEXT,
  scope scope DEFAULT 'national',
  section TEXT,
  author TEXT NOT NULL,
  status news_status DEFAULT 'draft',
  published_at TIMESTAMP DEFAULT NOW() NOT NULL
);

-- Events
CREATE TABLE IF NOT EXISTS events (
  id VARCHAR(50) PRIMARY KEY DEFAULT gen_random_uuid()::text,
  community_id VARCHAR(50) NOT NULL REFERENCES communities(id),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  date TIMESTAMP NOT NULL,
  end_date TIMESTAMP,
  location TEXT NOT NULL,
  type TEXT NOT NULL,
  scope scope DEFAULT 'national',
  section TEXT,
  participants INTEGER DEFAULT 0,
  created_by_admin_id VARCHAR(50) REFERENCES users(id),
  visibility_mode event_visibility_mode DEFAULT 'ALL',
  section_id VARCHAR(50) REFERENCES sections(id),
  tag_ids TEXT[],
  rsvp_mode event_rsvp_mode DEFAULT 'NONE',
  rsvp_deadline_at TIMESTAMP,
  capacity INTEGER,
  is_paid BOOLEAN DEFAULT FALSE,
  price_cents INTEGER,
  currency TEXT DEFAULT 'EUR',
  status event_status DEFAULT 'DRAFT',
  paid_event_counted_at TIMESTAMP,
  image TEXT,
  created_at TIMESTAMP DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP DEFAULT NOW() NOT NULL
);

-- Event Registrations
CREATE TABLE IF NOT EXISTS event_registrations (
  id VARCHAR(50) PRIMARY KEY DEFAULT gen_random_uuid()::text,
  event_id VARCHAR(50) NOT NULL REFERENCES events(id),
  membership_id VARCHAR(50) NOT NULL REFERENCES user_community_memberships(id),
  account_id VARCHAR(50) REFERENCES accounts(id),
  status event_registration_status DEFAULT 'PENDING',
  payment_status event_payment_status DEFAULT 'NONE',
  amount_cents INTEGER,
  currency TEXT DEFAULT 'EUR',
  stripe_checkout_session_id TEXT,
  stripe_payment_intent_id TEXT,
  created_at TIMESTAMP DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP DEFAULT NOW() NOT NULL
);

-- Event Attendance
CREATE TABLE IF NOT EXISTS event_attendance (
  id VARCHAR(50) PRIMARY KEY DEFAULT gen_random_uuid()::text,
  event_id VARCHAR(50) NOT NULL REFERENCES events(id),
  membership_id VARCHAR(50) NOT NULL REFERENCES user_community_memberships(id),
  scanned_by_admin_id VARCHAR(50) REFERENCES users(id),
  scanned_at TIMESTAMP DEFAULT NOW() NOT NULL,
  source attendance_source DEFAULT 'QR_SCAN'
);

-- Support Tickets
CREATE TABLE IF NOT EXISTS support_tickets (
  id VARCHAR(50) PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_id VARCHAR(50) NOT NULL REFERENCES users(id),
  community_id VARCHAR(50) NOT NULL REFERENCES communities(id),
  subject TEXT NOT NULL,
  message TEXT NOT NULL,
  status ticket_status DEFAULT 'open',
  priority ticket_priority DEFAULT 'medium',
  assigned_to VARCHAR(50) REFERENCES users(id),
  assigned_at TIMESTAMP,
  resolved_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW() NOT NULL,
  last_update TIMESTAMP DEFAULT NOW() NOT NULL
);

-- Messages
CREATE TABLE IF NOT EXISTS messages (
  id VARCHAR(50) PRIMARY KEY DEFAULT gen_random_uuid()::text,
  community_id VARCHAR(50) NOT NULL REFERENCES communities(id),
  conversation_id VARCHAR(50) NOT NULL,
  sender_membership_id VARCHAR(50) REFERENCES user_community_memberships(id),
  sender_type TEXT NOT NULL DEFAULT 'member',
  content TEXT NOT NULL,
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW() NOT NULL
);

-- Tags
CREATE TABLE IF NOT EXISTS tags (
  id VARCHAR(50) PRIMARY KEY DEFAULT gen_random_uuid()::text,
  community_id VARCHAR(50) NOT NULL REFERENCES communities(id),
  name TEXT NOT NULL,
  slug TEXT NOT NULL,
  color TEXT,
  type tag_type DEFAULT 'user',
  description TEXT,
  is_active BOOLEAN DEFAULT TRUE NOT NULL,
  created_by VARCHAR(50) REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP DEFAULT NOW() NOT NULL
);

-- Categories
CREATE TABLE IF NOT EXISTS categories (
  id VARCHAR(50) PRIMARY KEY DEFAULT gen_random_uuid()::text,
  community_id VARCHAR(50) NOT NULL REFERENCES communities(id),
  name TEXT NOT NULL,
  slug TEXT NOT NULL,
  sort_order INTEGER DEFAULT 0 NOT NULL,
  is_active BOOLEAN DEFAULT TRUE NOT NULL,
  created_at TIMESTAMP DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP DEFAULT NOW() NOT NULL
);

-- Verify tables created
SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;
