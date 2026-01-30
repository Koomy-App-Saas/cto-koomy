# SANDBOX - SaaS Owner Authentication Audit (Read-Only)

**Date:** 2026-01-22  
**Type:** Audit (READ-ONLY)  
**Environment:** Sandbox  
**Status:** COMPLETED

---

## Executive Summary

This audit examines the SaaS Owner authentication chain in the Koomy sandbox environment. The analysis confirms that:

1. **API Resolution is correct**: `saasowner-sandbox.koomy.app` enforces `https://api-sandbox.koomy.app` (no production fallback)
2. **2 platform admins exist in DB**: `rites@koomy.app` (active) and `platform@koomy.app` (inactive)
3. **Guard mechanism**: `users.global_role = 'platform_super_admin'` is the sole authorization criterion
4. **Recovery options**: Script-based bootstrap already exists at `scripts/bootstrap_platform_admin.ts`

---

## A) API Resolution Verification

### Frontend API Base URL Logic

**File:** `client/src/api/config.ts`

```typescript
// Priority 0: Strict sandbox hostname enforcement (BEFORE env vars)
if (isSandbox) {
  resolvedUrl = 'https://api-sandbox.koomy.app';
  source = `SANDBOX ENFORCED (hostname: ${hostname})`;
}
```

**Sandbox Detection (lines 325-333):**
```typescript
export function isSandboxHostname(hostname: string): boolean {
  const lowerHost = hostname.toLowerCase();
  return (
    lowerHost.endsWith('-sandbox.koomy.app') ||
    lowerHost === 'sandbox.koomy.app' ||
    lowerHost.startsWith('demo-') && lowerHost.endsWith('.koomy.app')
  );
}
```

### Hostname → API Mapping

| Hostname | API Target | Mode |
|----------|-----------|------|
| `saasowner-sandbox.koomy.app` | `https://api-sandbox.koomy.app` | SAAS_OWNER (sandbox) |
| `lorpesikoomyadmin.koomy.app` | `https://api.koomy.app` | SAAS_OWNER (production) |
| `*.koomy.app` (other) | `https://api.koomy.app` | Fallback production |

### Boot Log Output (Expected)

The `logBootDiagnostics()` function in `client/src/api/config.ts` (lines 77-122) outputs:

```
╔══════════════════════════════════════════════════════════════╗
║                    🚀 KOOMY APP BOOT                         ║
╠══════════════════════════════════════════════════════════════╣
║ Hostname:          saasowner-sandbox.koomy.app               ║
║ isSandbox:         true                                      ║
║ Platform:          web                                       ║
║ isNative:          false                                     ║
╠══════════════════════════════════════════════════════════════╣
║ Effective API:     https://api-sandbox.koomy.app             ║
║ Effective CDN:     https://cdn-sandbox.koomy.app             ║
╚══════════════════════════════════════════════════════════════╝
```

**Verdict:** ✅ Sandbox hostname → Sandbox API (no production leak possible)

---

## B) Auth Endpoints Cartography

### SaaS Owner Authentication Routes

| Endpoint | Method | Purpose | Input | Output | DB Tables |
|----------|--------|---------|-------|--------|-----------|
| `/api/platform/login` | POST | Email/password login | `{email, password}` | `{user, sessionToken, expiresAt}` | `users`, `platform_sessions` |
| `/api/platform/validate-session` | POST | Check session validity | `{sessionToken}` | `{valid, user}` | `platform_sessions`, `users` |
| `/api/platform/renew-session` | POST | Extend session | `{sessionToken}` | `{expiresAt}` | `platform_sessions` |
| `/api/platform/logout` | POST | Invalidate session | `{sessionToken}` | `{success}` | `platform_sessions` |
| `/api/platform/audit-logs` | GET | Fetch audit trail | Query params | `{logs, total}` | `platform_audit_logs` |

### Login Flow Details (lines 3045-3200)

```
1. Input validation (email + password required)
2. IP whitelist check (France only for production)
3. User lookup by email
4. Account lock check (rate limiting)
5. Role check: globalRole === 'platform_super_admin'
6. Password verification (bcrypt.compare)
7. Email verification check
8. Session creation (2-hour expiry, single active session)
9. Audit log entry
```

**Key Security Features:**
- ✅ Rate limiting (5 attempts → 15 min lockout)
- ✅ Single active session enforcement
- ✅ 2-hour session expiry
- ✅ France-only IP restriction
- ✅ Audit trail logging

---

## C) Middleware / Guards

### Authorization Guard

**File:** `server/routes.ts` (line 3094)

```typescript
if (user.globalRole !== 'platform_super_admin') {
  await logAuditAction('access_denied', req, {
    userId: user.id,
    details: { email, role: user.globalRole },
    success: false,
    errorMessage: 'Accès non autorisé - Réservé aux administrateurs plateforme'
  });
  return res.status(403).json({ error: "Accès non autorisé - Réservé aux administrateurs plateforme" });
}
```

### Session Validation Pattern

**File:** `server/routes.ts` (lines 3350-3362)

```typescript
const session = await storage.getPlatformSessionByToken(token);
if (!session || new Date() > session.expiresAt) {
  return res.status(401).json({ error: "Session expirée", expired: true });
}

const user = await storage.getUser(session.userId);
if (!user || user.globalRole !== 'platform_super_admin') {
  return res.status(403).json({ error: "Accès refusé" });
}
```

### Authorization Criteria

| Criterion | Required Value | Column/Source |
|-----------|---------------|---------------|
| `global_role` | `'platform_super_admin'` | `users.global_role` (enum) |
| `is_active` | `true` | `users.is_active` |
| `email_verified_at` | NOT NULL | `users.email_verified_at` |
| Session valid | `expires_at > NOW()` | `platform_sessions.expires_at` |

**Note:** Firebase claims are NOT used for platform admin authorization. Only DB `global_role` matters.

---

## D) Database Audit (Read-Only)

### User Statistics

```sql
SELECT COUNT(*) as user_count FROM users;
-- Result: 9 users

SELECT global_role, COUNT(*) as count FROM users GROUP BY global_role;
-- Result:
-- NULL: 7
-- platform_super_admin: 2
```

### Platform Admins

```sql
SELECT id, email, global_role, is_active, 
       email_verified_at IS NOT NULL as email_verified,
       firebase_uid IS NOT NULL as has_firebase,
       password IS NOT NULL as has_password
FROM users WHERE global_role = 'platform_super_admin';
```

| Email | Active | Email Verified | Has Firebase | Has Password |
|-------|--------|----------------|--------------|--------------|
| `platform@koomy.app` | ❌ | ❌ | ❌ | ✅ |
| `rites@koomy.app` | ✅ | ✅ | ❌ | ✅ |

### Recent Sessions

```sql
SELECT ps.id, u.email, ps.expires_at, ps.ip_address 
FROM platform_sessions ps 
LEFT JOIN users u ON ps.user_id = u.id 
ORDER BY ps.created_at DESC LIMIT 5;
```

| Email | Expires At | IP |
|-------|------------|-----|
| rites@koomy.app | 2026-01-09 13:08:49 | 91.169.131.185 |
| rites@koomy.app | 2026-01-09 12:38:24 | 91.169.131.185 |

**Note:** All recent sessions belong to `rites@koomy.app` and are expired (13+ days old).

### Users Table Schema

```sql
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'users' 
  AND column_name IN ('id', 'email', 'global_role', 'is_active', 'email_verified_at', 'firebase_uid', 'password');
```

| Column | Type | Nullable |
|--------|------|----------|
| `id` | varchar | NO |
| `email` | text | NO |
| `password` | text | YES |
| `global_role` | USER-DEFINED (enum) | YES |
| `is_active` | boolean | YES |
| `email_verified_at` | timestamp | YES |
| `firebase_uid` | text | YES |

---

## E) Diagnosis & Recovery Options

### Root Cause

The `rites@koomy.app` account exists and is properly configured:
- ✅ `global_role = 'platform_super_admin'`
- ✅ `is_active = true`
- ✅ `email_verified_at` is set
- ✅ Has password

**If login fails**, possible causes:
1. Wrong password
2. IP not from France (403)
3. Account locked after 5 failed attempts
4. Session token not stored/sent properly

### Recovery Options (NOT IMPLEMENTED IN THIS AUDIT)

#### Option A: Use Existing Account

The `rites@koomy.app` account is already a valid platform admin. Simply:
1. Reset password if forgotten (via Neon console or script)
2. Clear any account lock: `UPDATE users SET failed_login_attempts = 0, locked_until = NULL WHERE email = 'rites@koomy.app';`

#### Option B: Bootstrap Script (Already Exists)

**File:** `scripts/bootstrap_platform_admin.ts`

```bash
KOOMY_ENV=sandbox \
PLATFORM_BOOTSTRAP_ENABLED=true \
PLATFORM_BOOTSTRAP_EMAIL=admin@koomy.app \
PLATFORM_BOOTSTRAP_PASSWORD=SecurePass123! \
npx tsx scripts/bootstrap_platform_admin.ts
```

**Security guards:**
1. Requires `KOOMY_ENV=sandbox` (strict)
2. Requires `PLATFORM_BOOTSTRAP_ENABLED=true`
3. Email must be `@koomy.app` domain
4. One-shot: `platform_settings.platform_bootstrap_done` flag

#### Option C: Direct SQL (Neon Console)

```sql
-- Activate existing platform admin
UPDATE users SET 
  is_active = true, 
  email_verified_at = COALESCE(email_verified_at, NOW()),
  failed_login_attempts = 0,
  locked_until = NULL
WHERE email = 'rites@koomy.app';

-- OR create new admin (requires password hash)
INSERT INTO users (id, email, password, global_role, is_active, email_verified_at, created_at)
VALUES (
  gen_random_uuid()::text,
  'newadmin@koomy.app',
  '$2a$10$...', -- bcrypt hash
  'platform_super_admin',
  true,
  NOW(),
  NOW()
);
```

---

## Auth Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         SaaS Owner Login Flow                          │
└─────────────────────────────────────────────────────────────────────────┘

┌──────────────────┐     POST /api/platform/login     ┌──────────────────┐
│   Frontend       │ ─────────────────────────────────▶│   Backend        │
│  (PlatformLogin) │     {email, password}            │  (routes.ts)     │
└──────────────────┘                                   └──────────────────┘
                                                              │
                                                              ▼
                                                    ┌──────────────────┐
                                                    │ 1. IP Check (FR) │
                                                    └────────┬─────────┘
                                                              │
                                                              ▼
                                                    ┌──────────────────┐
                                                    │ 2. User Lookup   │
                                                    │ storage.getUser  │
                                                    │   ByEmail()      │
                                                    └────────┬─────────┘
                                                              │
                                                              ▼
                                                    ┌──────────────────┐
                                                    │ 3. Lock Check    │
                                                    │ locked_until?    │
                                                    └────────┬─────────┘
                                                              │
                                                              ▼
                                                    ┌──────────────────┐
                                                    │ 4. Role Check    │
                                                    │ global_role ===  │
                                                    │ platform_super   │
                                                    │ _admin?          │
                                                    └────────┬─────────┘
                                                              │
                                                              ▼
                                                    ┌──────────────────┐
                                                    │ 5. Password      │
                                                    │ bcrypt.compare() │
                                                    └────────┬─────────┘
                                                              │
                                                              ▼
                                                    ┌──────────────────┐
                                                    │ 6. Email Verify  │
                                                    │ email_verified_at│
                                                    │ IS NOT NULL?     │
                                                    └────────┬─────────┘
                                                              │
                                                              ▼
                                                    ┌──────────────────┐
                                                    │ 7. Revoke Old    │
                                                    │ Sessions         │
                                                    └────────┬─────────┘
                                                              │
                                                              ▼
                                                    ┌──────────────────┐
                                                    │ 8. Create New    │
                                                    │ Session (2h)     │
                                                    │ platform_sessions│
                                                    └────────┬─────────┘
                                                              │
                                                              ▼
┌──────────────────┐     {user, sessionToken}        ┌──────────────────┐
│   Frontend       │ ◀─────────────────────────────── │   Backend        │
│  Store token in  │                                  │  Return JSON     │
│  localStorage    │                                  │                  │
└──────────────────┘                                  └──────────────────┘
```

---

## Validation Checklist

- [x] API resolution verified: sandbox hostname → sandbox API
- [x] Auth endpoints documented with inputs/outputs
- [x] Middleware guard identified: `global_role === 'platform_super_admin'`
- [x] DB audit completed (SELECT only)
- [x] Existing admin accounts identified
- [x] Recovery options listed (NOT implemented)
- [x] No code modifications made
- [x] No DB mutations performed

---

**Report generated by:** Replit Agent  
**Audit scope:** Read-only analysis  
**Next steps:** User to decide which recovery option to pursue
