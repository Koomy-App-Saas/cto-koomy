# Android Auth Persistence - Test Report

## Implementation Summary

Version: 1.3.8  
Date: 2026-01-01

### Architecture Changes

1. **Hybrid Storage Service** (`client/src/lib/storage.ts`)
   - Uses Capacitor Preferences API on native platforms (Android/iOS)
   - Uses localStorage on web
   - Automatic platform detection via `Capacitor.isNativePlatform()`
   - Token management with timestamps for debugging
   - Comprehensive diagnostics tracking

2. **Token-Based Authentication**
   - Token format: `{accountId}:{timestamp}`
   - Stored in `koomy_auth_token` key
   - Timestamp stored in `koomy_auth_token_ts` for debugging

3. **Deterministic Auth Flow** (no arbitrary delays)
   - Login: API call → Generate token → Save token → Verify saved → Call /me → Set account
   - Startup: Read token → Call /me → Verify → Set account (or clear if 401)

4. **Error Handling**
   - Network errors: Keep local session, show "offline" message
   - 401 errors: Clear token and logout
   - Server errors: Keep local session, show error

### API Endpoints

| Endpoint | Method | Auth | Purpose |
|----------|--------|------|---------|
| `/api/accounts/me` | GET | Bearer token | Verify session, return account + memberships |
| `/api/health` | GET | None | Connectivity test |
| `/api/accounts/login` | POST | None | Initial login |

### Diagnostics (7-tap logo → Diagnostic Screen)

**Auth Persistence Section shows:**
- Platform (web/android/ios)
- Is Native (Yes/No)
- Storage Type (preferences/localStorage)
- Token Present (Yes/No + length)
- Token Set At (timestamp)
- Account ID (first 8 chars)
- Account Present (Yes/No)
- authReady (true/false)
- isAuthenticated (true/false)
- Last /me Status (200/401/etc)
- Last /me Trace ID
- Last /me Error (if any)
- Last Operation

**Buttons:**
- "Verify /me" - Tests token against server
- "Dump Auth State" - Shows all stored auth data
- "Clear Auth" - Clears all auth storage (for testing)

---

## Test Scenarios

### Test A: Fresh Install Login

**Steps:**
1. Clear app data or fresh install
2. Open app
3. Login with valid credentials
4. Check diagnostics

**Expected:**
- [ ] Token Present = Yes
- [ ] Token Length > 20
- [ ] Account ID = present
- [ ] authReady = true
- [ ] isAuthenticated = true
- [ ] /me → 200
- [ ] Redirect to home screen

**Actual Result:**
```
// TODO: Fill after testing
```

---

### Test B: Kill App + Relaunch (Persistence Test)

**Steps:**
1. Complete Test A (logged in)
2. Force stop app (Android Settings → Apps → Force Stop)
3. Relaunch app
4. Check diagnostics

**Expected:**
- [ ] authReady transitions false → true
- [ ] Token re-read from storage
- [ ] /me → 200 on startup
- [ ] No return to login screen
- [ ] Account data restored

**Actual Result:**
```
// TODO: Fill after testing
```

---

### Test C: Offline / No Connectivity

**Steps:**
1. Login successfully
2. Enable airplane mode
3. Force stop and relaunch app

**Expected:**
- [ ] Token read from storage = success
- [ ] /me call fails with network error
- [ ] App shows "offline" indicator (NOT login screen)
- [ ] Token NOT cleared (network error ≠ 401)
- [ ] isAuthenticated = true (from stored data)

**Actual Result:**
```
// TODO: Fill after testing
```

---

### Test D: Invalid/Expired Token

**Steps:**
1. Login successfully
2. Use Diagnostics → Dump Auth State
3. Note the token
4. Modify token in storage (or wait for expiry)
5. Force stop and relaunch

**Expected:**
- [ ] /me → 401
- [ ] Token cleared
- [ ] Account cleared
- [ ] Redirect to login screen
- [ ] Clear error message with traceId

**Actual Result:**
```
// TODO: Fill after testing
```

---

### Test E: Web App Regression

**Steps:**
1. Open web app
2. Login with valid credentials
3. Refresh page
4. Check localStorage in DevTools

**Expected:**
- [ ] `koomy_auth_token` in localStorage
- [ ] `koomy_account` in localStorage
- [ ] Session persists after refresh
- [ ] /me → 200

**Actual Result:**
```
// TODO: Fill after testing
```

---

## Build Instructions

### Debug APK

```bash
# 1. Sync Capacitor
npx cap sync android

# 2. Build debug APK
cd android && ./gradlew assembleDebug

# APK location: android/app/build/outputs/apk/debug/app-debug.apk
```

### Release AAB (Store Ready)

```bash
# 1. Set up signing (if not done)
# Create secrets/android/app.koomy.unsalidl/keystore.jks

# 2. Build with release script
node packages/mobile-build/index.mjs member --release --android

# AAB location: artifacts/mobile/koomy-member-release.aab
```

### Verify Capacitor Preferences Plugin

```bash
# Check plugin is installed
npm list @capacitor/preferences

# Should show:
# @capacitor/preferences@x.x.x

# Verify in Android
grep -r "Preferences" android/app/src
# Should find references to CapacitorPreferences plugin
```

---

## Client Logs Reference

### Login Flow Logs
```
[Login] ====== LOGIN ATTEMPT START ======
[Login] Calling apiPost /api/accounts/login to: https://...
[Login] ✅ Login API successful, account: { id, email, memberships }
[Login] Generated auth token, length: X
[Login] Step 1: Saving auth token...
[STORAGE] SET AUTH TOKEN ✅ (Preferences)
[Login] Step 2: Verifying token was saved...
[STORAGE] GET AUTH TOKEN ✅ (Preferences)
[Login] ✅ Token verified in storage, length: X
[Login] Step 3: Calling /api/accounts/me to verify server session...
[Login] /me response: { ok: true, status: 200, traceId: TR-XXXX }
[Login] ✅ /me verified! Setting account in context...
[Login] ✅ Navigating to home...
```

### Startup Hydration Logs
```
[AUTH] Native platform detected - hydrating from Preferences async...
[AUTH] Starting async hydration from Preferences...
[STORAGE] GET AUTH TOKEN ✅ (Preferences) { found: true, length: X }
[AUTH] Token found, verifying with /api/accounts/me...
[AUTH] /me response: { ok: true, status: 200, traceId: TR-XXXX }
[AUTH] ✅ Session verified! Setting account from /me response
[AUTH] ✅ Async hydration complete, authReady = true
```

### Server Logs Reference
```
[ME TR-XXXX] Session check request
[ME TR-XXXX] Authorization header present: true
[ME TR-XXXX] Token received, length: X
[ME TR-XXXX] Extracted accountId: abc-123-...
[ME TR-XXXX] ✅ Session valid, account: abc-123-... memberships: 1
```

---

## Diagnostic Screenshots

### After Test B (Persistence Verified)

```
// TODO: Add screenshot after testing showing:
// - Token Present: Yes
// - authReady: true
// - isAuthenticated: true
// - Last /me Status: 200
```

---

## Known Issues & Notes

1. **Capacitor WebView Scoping**: Preferences plugin stores data in app's native SharedPreferences, NOT WebView storage. This ensures persistence across app restarts.

2. **Token Validation**: Current implementation validates token format but doesn't cryptographically verify. For production, consider JWT or signed tokens.

3. **Network vs Auth Errors**: System distinguishes between network failures (keep session) and 401 errors (clear session).

---

## Checklist Before Release

- [ ] All Test A-E pass
- [ ] No 500ms delays in code
- [ ] Diagnostics screen shows all fields
- [ ] /api/accounts/me returns 200 for valid tokens
- [ ] /api/accounts/me returns 401 for invalid tokens
- [ ] Web app regression test passes
- [ ] APK builds successfully
- [ ] AAB builds successfully
- [ ] `npx cap sync android` runs without errors
