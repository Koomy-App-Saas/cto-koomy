# Fix Report: Disable Membership Auto-Migration for Firebase Admin Users

**Date**: 2026-01-25
**Status**: Fixed

## Symptom

After fixing POST `/api/events` (now returns 201), Railway logs showed FK constraint errors:

```
[MEMBERSHIP-LOOKUP <traceId>] AUTO_MIGRATION_FAILED
violates foreign key constraint "user_community_memberships_account_id_fkey"
```

## Root Cause Analysis

When `getMembershipForAuth` finds a membership via the `userId` fallback (for admin users), it attempts to auto-migrate by setting `membership.accountId = auth.accountId`.

However, for Firebase admin users:
- `authContext.isAdminUser === true`
- `auth.accountId === auth.userId` (compat behavior from `requireFirebaseOnly`)
- This "accountId" is actually the admin's `userId`, NOT a real record in the `accounts` table
- Writing `membership.accountId` violates the FK constraint because the referenced `accounts` row doesn't exist

## Fix Applied

### 1. Added Admin User Detection

```typescript
const isAdminUser = options?.isAdminUser || 
  (auth.accountId && auth.userId && auth.accountId === auth.userId);
const shouldSkipAutoMigration = isAdminUser;
```

### 2. Added Guard Before Auto-Migration

Both auto-migration blocks now check:
```typescript
if (auth.accountId && !membership.accountId && !shouldSkipAutoMigration) {
  // Proceed with auto-migration only for non-admin users
}
```

### 3. Added Debug Logging (Gated by KOOMY_AUTH_DEBUG)

When `KOOMY_AUTH_DEBUG=1` and auto-migration is skipped:
```typescript
console.log(`${logPrefix} AUTO_MIGRATION_DEBUG`, {
  isAdminUser,
  autoMigrationSkipped: true,
  autoMigrationAttempted: false,
  lookupPath: 'USER_ID',
  reason: 'admin_user_skip_fk_constraint'
});
```

### 4. Optional Parameter for Explicit Control

Added optional `options` parameter:
```typescript
interface MembershipLookupOptions {
  isAdminUser?: boolean;
}

async function getMembershipForAuth(
  auth: AuthResult, 
  communityId: string, 
  traceId?: string, 
  options?: MembershipLookupOptions
): Promise<{ membership: any; lookupPath: string }>
```

## Files Modified

- `server/routes.ts` - `getMembershipForAuth` helper function

## Validation Steps

1. Set `KOOMY_AUTH_DEBUG=1` in environment
2. Login as admin (Firebase) on sandbox backoffice
3. Create an event
4. Expected:
   - POST `/api/events` returns 201
   - NO `AUTO_MIGRATION_FAILED` error in logs
   - Debug log shows `autoMigrationSkipped: true`

## Behavior Summary

| User Type | accountId | userId | Auto-Migration |
|-----------|-----------|--------|----------------|
| Member (accounts table) | real accounts.id | undefined or different | ENABLED |
| Admin (users table) | = userId | userId | DISABLED |

This ensures backward compatibility for member accounts while preventing FK violations for admin users.
