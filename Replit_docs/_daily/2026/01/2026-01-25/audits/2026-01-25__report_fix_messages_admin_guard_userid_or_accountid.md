# Fix Report: POST /api/messages 403 for Firebase Admins

**Date**: 2026-01-25
**Status**: Fixed

## Symptom

POST `/api/messages` returns 403 `{"error":"Admin privileges required"}` for authenticated Firebase admins.

GET `/api/communities/:communityId/messages/:conversationId` works correctly (200/304).

## Root Cause Analysis

Same pattern as POST `/api/events`:

The route was using:
```typescript
const callerMembership = await storage.getMembershipByAccountAndCommunity(accountId, communityId);
```

For Firebase admin users:
- `requireFirebaseOnly()` returns `userId` in both `accountId` and `userId` fields
- `getMembershipByAccountAndCommunity()` searches only by `account_id` column
- Admin memberships are stored with `user_id`, NOT `account_id`
- Result: membership lookup returns `undefined` → 403

## Fix Applied

### 1. Updated POST /api/messages to Use Unified Helper

Changed from:
```typescript
const { accountId } = authResult;
if (!accountId) {
  return res.status(401).json({ error: "Account authentication required" });
}
const callerMembership = await storage.getMembershipByAccountAndCommunity(accountId, communityId);
```

To:
```typescript
const { membership: callerMembership, lookupPath } = await getMembershipForAuth(authResult, communityId, traceId);
```

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
console.log(`[MSG_ADMIN_GUARD ${traceId}]`, {
  isAdminUser: req.authContext?.isAdminUser,
  userId: authResult.userId,
  accountId: authResult.accountId,
  communityId,
  conversationId: req.body.conversationId,
  membershipFound: !!callerMembership,
  lookupPath,
  role: callerMembership?.role,
  adminRole: callerMembership?.adminRole,
  permissions: callerMembership?.permissions
});
```

## Files Modified

- `server/routes.ts`: POST /api/messages handler (lines ~7606-7650)

## Code Diff Summary

```diff
- const { accountId } = authResult;
- if (!accountId) {
-   return res.status(401).json({ error: "Account authentication required" });
- }
- const callerMembership = await storage.getMembershipByAccountAndCommunity(accountId, communityId);
+ const { membership: callerMembership, lookupPath } = await getMembershipForAuth(authResult, communityId, traceId);
+ // + debug logging block
```

## Validation Steps

1. Set `KOOMY_AUTH_DEBUG=1` in environment
2. Login as admin (Firebase) on `backoffice-sandbox.koomy.app`
3. Open a conversation
4. Send a message
5. Expected:
   - POST `/api/messages` returns 201 (not 403)
   - Logs show `[MSG_ADMIN_GUARD]` with `membershipFound: true`
   - `lookupPath` shows `USER_ID` for Firebase admins

## Related Fixes

This follows the same pattern as:
- POST `/api/events` (fixed earlier)
- Auto-migration skip for admin users (to prevent FK errors)
