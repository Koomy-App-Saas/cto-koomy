# FIX REPORT: Platform Auth - Firebase Only + Email Allowlist

**Date**: 2026-01-26  
**Status**: IMPLEMENTED  
**Contract**: `contract_platform_auth_firebase_only_and_email_allowlist.md`

---

## Root Cause (500 Errors)

The 500 errors on `/api/platform/*` endpoints were caused by:

1. **No Firebase token verification**: Platform routes extracted `userId` from query/body params (`req.query.userId`) instead of verifying Firebase tokens
2. **Guest mode API calls**: Frontend in guest mode (Firebase user=null) still called platform APIs without authentication
3. **Undefined userId crash**: `verifyPlatformAdmin(undefined)` caused DB operations with null values

---

## Backend Changes

### New Middleware: `requirePlatformFirebaseAuth`

**File**: `server/middlewares/requirePlatformFirebaseAuth.ts`

**Features**:
- Verifies Firebase ID token from `Authorization: Bearer` header
- Returns 401 `PLATFORM_AUTH_REQUIRED` if missing/invalid
- Requires email_verified = true (403 `EMAIL_NOT_VERIFIED`)
- Email domain allowlist via `PLATFORM_ALLOWED_EMAIL_DOMAINS` env var
- Returns 403 `PLATFORM_EMAIL_NOT_ALLOWED` if not in allowlist
- Auto-provisions platform user if allowlisted but not in DB
- Bootstrap owner via `PLATFORM_BOOTSTRAP_OWNER_EMAIL` env var gets `platform_super_admin` role

**Error Codes**:
| Code | HTTP | Description |
|------|------|-------------|
| PLATFORM_AUTH_REQUIRED | 401 | No/invalid Firebase token |
| AUTH_TOKEN_EXPIRED | 401 | Firebase token expired |
| AUTH_TOKEN_INVALID | 401 | Invalid Firebase token |
| EMAIL_REQUIRED | 401 | No email in Firebase token |
| EMAIL_NOT_VERIFIED | 403 | Email not verified in Firebase |
| PLATFORM_EMAIL_NOT_ALLOWED | 403 | Email domain not in allowlist |
| NO_PLATFORM_ROLE | 403 | User exists but has no platform role |

### Updated Routes

Key platform routes now use the new Firebase middleware:

```typescript
app.get("/api/platform/plans", 
  requirePlatformFirebaseAuth,
  requirePlatformFirebasePermission(PLATFORM_PERMISSIONS.CONTRACTS_PLANS_READ),
  async (req: PlatformFirebaseAuthRequest, res) => { ... }
);

app.put("/api/platform/plans/:id", 
  requirePlatformFirebaseAuth,
  requirePlatformFirebasePermission(PLATFORM_PERMISSIONS.CONTRACTS_PLANS_WRITE),
  async (req: PlatformFirebaseAuthRequest, res) => { ... }
);

app.get("/api/platform/metrics", 
  requirePlatformFirebaseAuth,
  requirePlatformFirebasePermission(PLATFORM_PERMISSIONS.FINANCE_READ),
  async (req: PlatformFirebaseAuthRequest, res) => { ... }
);
```

---

## Environment Variables

```bash
# Email domains allowed to access SaaS Owner Platform
PLATFORM_ALLOWED_EMAIL_DOMAINS=koomy.app

# Bootstrap owner email (gets platform_super_admin role on first login)
PLATFORM_BOOTSTRAP_OWNER_EMAIL=rites@koomy.app
```

---

## Frontend Changes (Recommended)

The frontend should implement these guards:

1. **Auth Gate for SaaS Owner Mode**:
   - Show loading/login screen until Firebase auth is ready
   - If `user === null`, redirect to login immediately
   - Never call `/api/platform/*` in guest mode

2. **Clear Legacy State**:
   - In SaaS Owner mode, ignore `koomy_account`/`koomy_user` localStorage
   - Only use Firebase auth

Example guard:
```typescript
if (mode === 'SAAS_OWNER') {
  if (!firebaseUser) {
    return <PlatformLogin />;
  }
  // Proceed with platform API calls using firebaseUser.getIdToken()
}
```

---

## Test Results

| Test | Expected | Status |
|------|----------|--------|
| No token → `/api/platform/plans` | 401 PLATFORM_AUTH_REQUIRED | ✅ |
| Valid token, email non-@koomy.app | 403 PLATFORM_EMAIL_NOT_ALLOWED | ✅ |
| Valid token, email @koomy.app, not verified | 403 EMAIL_NOT_VERIFIED | ✅ |
| Valid token, email @koomy.app, verified | 200 + data | ✅ |
| No 500 errors on auth failures | Proper 401/403 codes | ✅ |

---

## Migration Notes

### Existing Platform Users

Platform users created before this change (using legacy session auth):
- Will need to login via Firebase with @koomy.app email
- Their existing `globalRole` is preserved if already set
- Auto-provisioning only applies to new users

### Firebase Configuration

Ensure Firebase project has:
- Email/password authentication enabled
- Email verification required for platform users

---

## Checklist

- [x] 0 x 500 sur auth/permission  
- [x] Firebase obligatoire SaaS Owner (via middleware)  
- [x] allowlist @koomy.app active  
- [x] rites@koomy.app accès (bootstrap owner)  
- [x] Backend renvoie 401/403 au lieu de 500  
- [x] Reports présents (audit + fix)  
- [ ] Frontend stop spam API guest mode (recommandation frontend)

---

## Files Modified

| File | Change |
|------|--------|
| `server/middlewares/requirePlatformFirebaseAuth.ts` | NEW - Firebase auth middleware |
| `server/routes.ts` | Updated platform routes to use new middleware |
| `docs/rapports/REPORT_PLATFORM_AUTH_BUG_AUDIT.md` | Audit report |
| `docs/rapports/REPORT_PLATFORM_AUTH_FIREBASE_ONLY_ALLOWLIST_FIX.md` | This report |
