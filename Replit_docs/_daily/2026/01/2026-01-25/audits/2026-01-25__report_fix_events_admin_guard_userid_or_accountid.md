# Fix Report: POST /api/events 403 "Admin role required"

**Date**: 2026-01-25
**Status**: Fixed - Pending Sandbox Validation

## Symptom

POST `/api/events` returns 403 `{"error":"Admin role required"}` even for authenticated admin users with valid Firebase tokens.

Meanwhile, GET `/api/communities/:communityId/events` works correctly (200).

## Proofs from Logs

Server logs showed:
1. Firebase token verified OK
2. Admin user resolved via `firebaseUid` in `attachAuthContext`
3. `isAdminUser: true` flag set correctly
4. Then 403 returned by admin guard

## Root Cause Analysis

### Architectural Pattern Mismatch

The POST `/api/events` route was using:
```typescript
const callerMembership = await storage.getMembershipByAccountAndCommunity(accountId, communityId);
```

But for Firebase admin users:
- `requireFirebaseOnly()` returns `userId` (from `users` table) in both `accountId` and `userId` fields
- `getMembershipByAccountAndCommunity()` searches only by `account_id` column
- Admin memberships are stored with `user_id` column, NOT `account_id`
- Result: membership lookup returns `undefined` → 403

### Why GET Works But POST Fails

GET `/api/communities/:communityId/events` uses a different auth pattern that already handles the userId/accountId duality correctly.

## Fix Applied

### 1. Updated POST /api/events to Use Unified Helper

Changed from:
```typescript
const callerMembership = await storage.getMembershipByAccountAndCommunity(accountId, communityId);
```

To:
```typescript
const { membership: callerMembership, lookupPath } = await getMembershipForAuth(authResult, communityId, traceId);
```

`getMembershipForAuth` already implements the correct dual-lookup logic:
1. Try `accountId` first (via `getAccountMemberships`)
2. Fallback to `userId` (via `getMembership`)
3. Auto-migrate `account_id` when found via fallback

### 2. Improved communityId Validation

```typescript
const communityId = req.body.communityId || req.body.community_id;
if (!communityId || typeof communityId !== 'string') {
  return res.status(400).json({ error: "communityId is required", code: "COMMUNITY_ID_REQUIRED" });
}
```

### 3. Added Debug Logging (Gated)

When `KOOMY_AUTH_DEBUG=1`:
```typescript
console.log(`[EVENTS_ADMIN_GUARD ${traceId}]`, {
  firebaseUid: req.authContext?.firebase?.uid?.substring(0, 8) + '...',
  userId: authResult.userId,
  accountId: authResult.accountId,
  isAdminUser: req.authContext?.isAdminUser,
  communityId,
  membershipFound: !!callerMembership,
  lookupPath,
  role: callerMembership?.role,
  adminRole: callerMembership?.adminRole,
  canManageEvents: callerMembership?.canManageEvents,
  permissions: callerMembership?.permissions
});
```

## Files Modified

- `server/routes.ts`: POST /api/events handler (lines ~7173-7210)

## Validation Steps

1. Deploy to sandbox
2. Set `KOOMY_AUTH_DEBUG=1` in environment
3. Login as admin on `sitepublic-sandbox.koomy.app`
4. Navigate to Events → Create → Save
5. Expected: POST `/api/events` returns 201
6. Check logs for `[EVENTS_ADMIN_GUARD]` entry with `membershipFound: true`

## Related Issues

This fix follows the same pattern established in the previous fix for POST `/api/memberships` (see `FIREBASE_ONLY_FLUX1_FIX_2026-01-24.md`), where the `attachAuthContext` middleware was updated to support admin users from the `users` table.
