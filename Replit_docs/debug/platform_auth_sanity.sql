-- KOOMY SANDBOX - Platform Auth Sanity Check
-- Date: 2026-01-22
-- Purpose: Verify platform admin user is loginable

-- 1) Check platform admin user status
SELECT 
    id,
    email,
    global_role,
    is_active,
    email_verified_at IS NOT NULL as email_verified,
    password IS NOT NULL as has_password,
    failed_login_attempts,
    locked_until
FROM users
WHERE lower(email) = lower('rites@koomy.app');

-- Expected: global_role='platform_super_admin', is_active=true, email_verified=true, has_password=true

-- 2) If needed: Fix user to be loginable (RUN MANUALLY IF NEEDED)
-- UPDATE users
-- SET is_active = true,
--     email_verified_at = COALESCE(email_verified_at, NOW()),
--     failed_login_attempts = 0,
--     locked_until = NULL
-- WHERE lower(email) = lower('rites@koomy.app');

-- 3) Check active sessions for platform admin
SELECT 
    ps.id,
    ps.user_id,
    u.email,
    ps.expires_at,
    ps.ip_address,
    ps.expires_at > NOW() as is_valid
FROM platform_sessions ps
LEFT JOIN users u ON ps.user_id = u.id
WHERE u.global_role = 'platform_super_admin'
ORDER BY ps.created_at DESC
LIMIT 5;

-- 4) Count all platform admins
SELECT global_role, COUNT(*) as count
FROM users
WHERE global_role = 'platform_super_admin'
GROUP BY global_role;

-- 5) Verify no Firebase dependency (users.password must be NOT NULL for platform login)
SELECT 
    id, 
    email, 
    password IS NOT NULL as can_login_legacy,
    firebase_uid IS NOT NULL as has_firebase
FROM users
WHERE global_role = 'platform_super_admin';
