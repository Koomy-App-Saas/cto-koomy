# Audit: Firebase-Only Authentication Fix - Flux 1 & POST /api/memberships

**Date**: 2026-01-24
**Status**: Implemented - Pending Sandbox Deployment & Verification

## Critical Fix: POST /api/memberships 401 Error

### Root Cause Analysis

The `attachAuthContext` middleware (global auth enricher) only searched in the `accounts` table for Firebase users. However, admin users are stored in the `users` table with `firebaseUid`. This meant:
- Firebase token was validated successfully
- But `koomyUser` remained `null` because no matching record in `accounts`
- `requireFirebaseOnly()` then returned 401 FIREBASE_AUTH_REQUIRED

### Fix Applied

1. **Added admin user fallback in `attachAuthContext.ts`**:
   - After searching `accounts` table, now also searches `users` table by `firebaseUid`
   - Sets `isAdminUser = true` flag when user found via `users` table
   - Fetches memberships using `userId` (not `accountId`) for admin users

2. **Enhanced `requireFirebaseOnly()` in `routes.ts`**:
   - Now returns `userId` field when `isAdminUser = true`
   - Maintains backward compatibility with `accountId` field

3. **Added `isAdminUser` flag to `AuthContext` interface**:
   - Distinguishes between member accounts and admin users
   - Enables proper routing in downstream guards

## Important Note (Original Issue)

The `firebaseUid` column was already being passed to the Drizzle insert (line 3645 in routes.ts):
```typescript
firebaseUid: firebaseUser.uid
```

The user's previous test showing `firebaseUid = NULL` was on the **deployed sandbox** which did not yet include these changes. The root cause was actually in `/api/auth/me` not finding admin users and the AuthContext legacy guard - both of which are now fixed.

## Summary

Fixed critical bugs in the admin registration flow (Flux 1) and POST /api/memberships that prevented Firebase admin users from being properly authenticated.

## Root Cause Analysis

The admin registration flow had multiple issues:

1. **`/api/auth/me` only searched `accounts` table**: Admin users are stored in `users` table with `firebaseUid`, but the endpoint only looked in `accounts` table (for mobile members). Result: `user: null` returned after registration.

2. **Missing `authProvider` in API response**: The `/api/admin/register` endpoint didn't include `authProvider: 'firebase'` in the response, so the frontend couldn't identify the user as a Firebase user.

3. **AuthContext legacy guard checked wrong field**: The `hydrateFromStorageSync` function only checked `parsedAccount?.authProvider`, but admin users are stored in `storedUser` not `storedAccount`. Result: Firebase admin users were incorrectly force-logged out.

## Changes Made

### 1. server/routes.ts - `/api/auth/me` (lines 12471-12532)

Added lookup for admin users by `firebaseUid` when no member account is found:

```typescript
if (!account) {
  // Check for admin user by firebaseUid
  const adminUser = await storage.getUserByFirebaseUid(decoded.uid);
  if (adminUser) {
    const adminMemberships = await storage.getUserMemberships(adminUser.id);
    return res.json({
      firebase: { uid: decoded.uid, email: decoded.email },
      user: { ...adminUser, authProvider: 'firebase', isAdmin: true },
      memberships: adminMemberships,
      traceId
    });
  }
}
```

### 2. server/routes.ts - `/api/admin/register` response (lines 3962-3983)

Added `authProvider` and `isAdmin` to the response:

```typescript
return res.status(201).json({
  user: {
    id: user.id,
    firstName: user.firstName,
    lastName: user.lastName,
    email: user.email,
    avatar: user.avatar,
    phone: user.phone,
    authProvider: 'firebase', // NEW: Identity Contract marker
    isAdmin: true             // NEW: Admin flag
  },
  memberships: [...]
});
```

### 3. client/src/contexts/AuthContext.tsx - `hydrateFromStorageSync` (lines 79-107)

Extended Firebase user detection to also check `parsedUser`:

```typescript
// Parse user to check auth provider (for admin users)
let parsedUser = null;
if (storedUser) {
  parsedUser = JSON.parse(storedUser);
}

// Check BOTH account and user for authProvider
const isFirebaseUser = 
  parsedAccount?.authProvider === 'firebase' || 
  parsedAccount?.authProvider === 'google' ||
  parsedUser?.authProvider === 'firebase' ||
  parsedUser?.isAdmin === true;
```

### 4. server/storage.ts - Enhanced Logging (lines 3724-3740)

Added instrumented logging to trace `firebaseUid` through the insert:

```typescript
console.log(`[Admin Register ${traceId}] CANONICAL_START`, { 
  inputFirebaseUid: userInput.firebaseUid?.substring(0, 12) || 'NULL'
});

const [user] = await tx.insert(users).values(userInput).returning();
console.log(`[Admin Register ${traceId}] CANONICAL_STEP1 user_created`, { 
  userId: user.id,
  storedFirebaseUid: user.firebaseUid?.substring(0, 12) || 'NULL',
  inputWasProvided: !!userInput.firebaseUid
});
```

## Expected Behavior After Fix

1. **Registration Flow**:
   - User fills registration form
   - Frontend creates Firebase account (via `createUserWithEmailPassword`)
   - Frontend caches token (via `ensureFirebaseToken`)
   - Frontend calls `/api/admin/register` with Firebase token
   - Backend creates user with `firebaseUid` in Neon
   - Backend returns user with `authProvider: 'firebase'`
   - Frontend stores user in localStorage

2. **Subsequent Page Loads**:
   - `hydrateFromStorageSync` reads `koomy_user` from localStorage
   - Detects `userAuthProvider: 'firebase'` or `userIsAdmin: true`
   - Sets `isFirebaseUser = true`
   - Does NOT force logout (legacy guard skipped)

3. **API Calls**:
   - `getFirebaseIdToken()` returns cached token
   - Requests include `Authorization: Bearer <token>`
   - `/api/auth/me` finds user by `firebaseUid`
   - Returns user with memberships

## Verification Checklist

- [ ] Deploy to sandbox environment
- [ ] Create new admin account with fresh email
- [ ] Verify Firebase user created in Firebase Console
- [ ] Verify Neon user has `firebase_uid` populated (not NULL)
- [ ] Verify no "forcing logout" message in browser console
- [ ] Verify dashboard loads successfully
- [ ] Verify page refresh maintains session

## Files Modified

| File | Lines Changed | Description |
|------|---------------|-------------|
| server/routes.ts | +45 lines | Added admin user lookup in `/api/auth/me`, added `authProvider`/`isAdmin` to register response |
| server/storage.ts | +8 lines | Added firebaseUid logging in atomic registration |
| client/src/contexts/AuthContext.tsx | +15 lines | Extended Firebase user detection to include admin users |

## Identity Contract Compliance

This fix aligns with the Identity Contract (2026-01):
- Firebase UID is the immutable primary identity
- Admin users in STANDARD communities use Firebase Auth exclusively
- No legacy token required for Firebase-authenticated users
