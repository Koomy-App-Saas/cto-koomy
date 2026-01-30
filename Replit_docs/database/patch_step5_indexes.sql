-- STEP 5: Indexes (execute last)

CREATE UNIQUE INDEX IF NOT EXISTS users_firebase_uid_key ON users(firebase_uid) WHERE firebase_uid IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS accounts_auth_provider_provider_id_key ON accounts(auth_provider, provider_id) WHERE auth_provider IS NOT NULL AND provider_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS unique_provider_identity_idx ON user_identities(provider, provider_id);
CREATE UNIQUE INDEX IF NOT EXISTS user_provider_idx ON user_identities(user_id, provider);
CREATE UNIQUE INDEX IF NOT EXISTS communities_custom_domain_key ON communities(custom_domain) WHERE custom_domain IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS communities_self_enrollment_slug_key ON communities(self_enrollment_slug) WHERE self_enrollment_slug IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS communities_member_join_code_key ON communities(member_join_code) WHERE member_join_code IS NOT NULL;

SELECT indexname FROM pg_indexes WHERE schemaname = 'public' AND tablename IN ('users', 'accounts', 'communities', 'user_identities');
