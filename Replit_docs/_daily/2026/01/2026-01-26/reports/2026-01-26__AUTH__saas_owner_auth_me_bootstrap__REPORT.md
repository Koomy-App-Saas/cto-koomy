# REPORT: SAAS_OWNER Mode Auth Bootstrap via /api/auth/me

**Date:** 2026-01-26
**Domain:** AUTH
**Type:** Implementation Report

## Summary

Implemented mode-based authentication in `PlatformLogin.tsx` to bypass the broken `/api/platform/firebase-auth` endpoint when in SAAS_OWNER mode, using `/api/auth/me` as the session bootstrap alternative.

## Problem

The `/api/platform/firebase-auth` endpoint has a backend bug (`"v is not a function"`) that occurs during Firebase token verification in SAAS_OWNER mode. This prevented successful login for platform administrators.

## Solution

Added conditional logic in `handleFirebaseAuthSuccess()` to detect the app mode:

```typescript
const { mode } = resolveAppMode();

if (mode === "SAAS_OWNER") {
  // Use /api/auth/me for session bootstrap
  const response = await apiGet('/api/auth/me');
  
  if (response.ok && response.data?.user) {
    // Session established - redirect to dashboard
  } else if (response.status === 401) {
    // Force Firebase logout
    await signOutFirebase();
  }
  return;
}

// Non-SAAS_OWNER modes continue to use /api/platform/firebase-auth
```

## Changes Made

### File: `client/src/pages/platform/Login.tsx`

1. Added imports:
   - `apiGet` from `@/api/httpClient`
   - `signOutFirebase` from `@/lib/firebase`
   - `resolveAppMode` from `@/lib/appModeResolver`

2. Modified `handleFirebaseAuthSuccess()`:
   - Detects mode via `resolveAppMode()`
   - SAAS_OWNER mode: calls `/api/auth/me` instead of `/api/platform/firebase-auth`
   - Handles 401 response by forcing Firebase logout
   - Other modes: unchanged behavior (uses `/api/platform/firebase-auth`)

## Behavior by Mode

| Mode | Auth Endpoint | Behavior |
|------|---------------|----------|
| SAAS_OWNER | `/api/auth/me` | Bootstrap session from existing user data |
| Other | `/api/platform/firebase-auth` | Standard Firebase auth flow |

## Error Handling

- **200 + user present**: Login success, redirect to dashboard
- **401**: Session expired, force Firebase logout, show error toast
- **Other errors**: Display error message via toast

## Testing

- Mode detection logs visible in console: `[Platform Login] Mode detected: SAAS_OWNER`
- Auth flow logs: `[Platform Login] SAAS_OWNER mode - using /api/auth/me bootstrap`
- No calls to `/api/platform/firebase-auth` when in SAAS_OWNER mode

## Related Documents

- `2026-01-26__UI__platform_firebase_only_login__REPORT.md` - Firebase UI update
- `2026-01-26__SEC__platform_email_verification_sendgrid__REPORT.md` - Email verification

## Status

✅ Implemented and tested
