# AUDIT: Platform Auth Bug - 500 Errors

**Date**: 2026-01-26  
**Status**: COMPLETED  
**Type**: Root Cause Analysis

---

## Executive Summary

The SaaS Owner Platform endpoints return 500 errors instead of proper 401/403 when accessed without authentication. The root cause is that platform routes rely on `userId` extracted from query/body parameters rather than verifying Firebase tokens, leading to crashes when the frontend calls APIs in guest mode.

---

## Root Cause Analysis

### Issue 1: No Firebase Token Verification for Platform Routes

**Current Flow:**
```
Frontend (guest mode) → GET /api/platform/plans → req.query.userId = undefined
                      → verifyPlatformAdmin(undefined) 
                      → verifyPlatformAdminLegacy(undefined)
                      → Returns { valid: false, error: "userId is required..." }
                      → Should be 403, but sometimes 500 if DB error occurs first
```

**Problem:**
- Platform routes extract `userId` from `req.query.userId` or `req.body.userId`
- Frontend passes `userId` as query parameter (insecure, easily forged)
- No Firebase token verification happens
- Guest mode frontend sends requests without userId → undefined passed to auth functions

### Issue 2: Frontend Calls API in Guest Mode

**Current Behavior:**
- When Firebase `onAuthStateChanged` returns `null` (guest mode)
- Frontend still attempts to call `/api/platform/*` endpoints
- Legacy auth state may contain stale data causing confusion
- No guard to prevent API calls when `user === null`

### Issue 3: No Email Allowlist Enforcement

**Current State:**
- Any user with `platform_super_admin` role can access
- No domain restriction (should be @koomy.app only)
- No Firebase email verification requirement

---

## Technical Findings

### Files Involved

| File | Issue |
|------|-------|
| `server/routes.ts` | Routes use `verifyPlatformAdmin(userId)` with userId from query params |
| `server/platform/auth.ts` | Legacy session-based auth, not Firebase |
| `server/middlewares/requireFirebaseAuth.ts` | EXISTS but not used for platform routes |
| Frontend | Calls platform APIs without checking auth state first |

### Code Path Analysis

```typescript
// Current problematic pattern (server/routes.ts)
app.put("/api/platform/plans/:id", async (req, res) => {
  const userId = req.query.userId as string || req.body.userId as string;
  const authResult = await verifyPlatformAdmin(userId);  // userId can be undefined!
  if (!authResult.valid) {
    return res.status(403).json({ error: authResult.error });  // Returns 403
  }
  // ...business logic
});
```

The 500 occurs when:
1. `storage.getUser(undefined)` throws instead of returning null
2. Any async error before the auth check completes
3. Unhandled promise rejections in middleware chain

---

## Required Fixes

### Backend

1. **Create `requirePlatformFirebaseAuth` middleware**
   - Verify Firebase ID token from `Authorization: Bearer` header
   - Return 401 `PLATFORM_AUTH_REQUIRED` if missing/invalid
   
2. **Create `requirePlatformEmailAllowlist` middleware**
   - Check email domain against `PLATFORM_ALLOWED_EMAIL_DOMAINS` env var
   - Require email_verified = true
   - Return 403 `PLATFORM_EMAIL_NOT_ALLOWED` if not in allowlist

3. **Apply middleware to all `/api/platform/*` routes**
   - Use express middleware chain instead of inline auth checks

4. **Add global error handler for auth errors**
   - Map auth exceptions to proper HTTP status codes
   - Never return 500 for auth failures

### Frontend

1. **Guard platform API calls**
   - Check `user !== null` before any `/api/platform/*` call
   - Show login screen immediately if no Firebase user

2. **Clear legacy auth state**
   - Remove stale `koomy_account`/`koomy_user` storage when in SaaS Owner mode
   - Force Firebase-only auth flow

---

## Environment Variables Required

```bash
PLATFORM_ALLOWED_EMAIL_DOMAINS=koomy.app
PLATFORM_BOOTSTRAP_OWNER_EMAIL=rites@koomy.app
```

---

## Test Cases

| Test | Expected |
|------|----------|
| No token → `/api/platform/plans` | 401 PLATFORM_AUTH_REQUIRED |
| Valid token, email non-@koomy.app | 403 PLATFORM_EMAIL_NOT_ALLOWED |
| Valid token, email @koomy.app, not verified | 403 EMAIL_NOT_VERIFIED |
| Valid token, email @koomy.app, verified | 200 + data |
| Frontend user=null | No platform API calls made |

---

## Conclusion

The 500 errors are caused by:
1. Platform routes not using Firebase token verification
2. userId passed as query parameter (undefined in guest mode)
3. Frontend calling APIs before auth is established

Solution: Implement Firebase-required middleware with email allowlist for all platform routes.
