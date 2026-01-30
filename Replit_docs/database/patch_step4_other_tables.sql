-- STEP 4: Other tables (execute fourth)

-- user_identities
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

-- admin_invitations
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

-- platform_sessions
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

-- platform_verification_tokens
CREATE TABLE IF NOT EXISTS platform_verification_tokens (
  id VARCHAR(50) PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_id VARCHAR(50) NOT NULL REFERENCES users(id),
  token TEXT NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  used_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW() NOT NULL
);

SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;
