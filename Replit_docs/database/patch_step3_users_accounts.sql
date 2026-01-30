-- STEP 3: Users and Accounts (execute third)

-- Users firebase_uid
ALTER TABLE users ADD COLUMN IF NOT EXISTS firebase_uid TEXT;

-- Accounts table
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

ALTER TABLE accounts ADD COLUMN IF NOT EXISTS auth_provider TEXT DEFAULT 'email';
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS provider_id TEXT;
ALTER TABLE accounts ALTER COLUMN password_hash DROP NOT NULL;

SELECT column_name FROM information_schema.columns WHERE table_name = 'accounts';
