# Owner Membership Fix Report

**Date:** 2026-01-20  
**Status:** RESOLVED  
**Priority:** CRITICAL

## Issue Summary

Admin users registering new clubs via `/api/admin/register` were receiving 403 Forbidden errors when attempting to create membership plans, articles, and other admin-only resources.

## Root Cause Analysis

### Problem 1: Missing `isOwner` Flag in Admin Registration

The `/api/admin/register` endpoint was creating memberships without the `isOwner: true` flag:

```typescript
// BEFORE (broken)
const membership = await storage.createMembership({
  userId: user.id,
  communityId: community.id,
  memberId,
  role: "admin",
  displayName: `${firstName} ${lastName}`,
  status: "active",
  contributionStatus: "up_to_date"
});
```

### Problem 2: Authorization Check Relies on `isOwner` Flag

The `isCommunityAdmin()` function (via `isOwner()` check) requires `isOwner: true` OR specific admin roles to grant access:

```typescript
function isOwner(membership: MembershipForRoleCheck): boolean {
  if (!membership) return false;
  if (membership.isOwner === true) return true;
  // fallback checks...
}
```

## Solution Applied

### Code Fix in `/api/admin/register`

```typescript
// AFTER (fixed)
const memberId = `OWNER-${Date.now().toString(36).toUpperCase()}`;
const membership = await storage.createMembership({
  userId: user.id,
  communityId: community.id,
  memberId,
  role: "admin",
  isOwner: true,        // CRITICAL: Marks this as the community owner
  sectionScope: "ALL",  // Full access to all sections
  displayName: `${firstName} ${lastName}`,
  status: "active",
  contributionStatus: "up_to_date"
});
```

### Data Migration Applied

Fixed existing affected community:

```sql
-- Club d'Échecs de Paris (demo@koomy.app)
UPDATE user_community_memberships 
SET 
  role = 'admin',
  is_owner = true,
  section_scope = 'ALL'
WHERE id = '2a603043-debe-415d-86f0-3fc33792f51a'
  AND community_id = '82590b15-9394-4cfe-b99a-8a3b8df1e701';
```

## Verification

### Test Case: Create Membership Plan

```bash
curl -X POST "http://localhost:5000/api/communities/{communityId}/membership-plans" \
  -H "Authorization: Bearer {accountId}:test" \
  -d '{"name":"Test","slug":"test","membershipType":"FIXED_PERIOD","fixedPeriodType":"CALENDAR_YEAR"}'
```

### Expected Log Output

```
[MEMBERSHIP-PLANS AUTH] accountId=xxx userId=undefined authType=account 
  communityId=xxx membership.id=xxx role=admin adminRole=null 
  isOwner=true => allowed=true reason=IS_OWNER
```

### Actual Result: ✅ SUCCESS (HTTP 201)

## Communities Status After Fix

| Community | Owner Membership | isOwner | sectionScope | Status |
|-----------|-----------------|---------|--------------|--------|
| UNSA Lidl | ✅ | true | ALL | OK |
| Club d'Échecs de Paris | ✅ (fixed) | true | ALL | OK |
| Port-Bouët FC | ✅ | true | ALL | OK |

## Prevention Measures

1. **Code Change**: `/api/admin/register` now always creates memberships with `isOwner: true` and `sectionScope: "ALL"`

2. **Member ID Prefix**: Changed from `ADMIN-` to `OWNER-` for clarity

3. **Future registrations**: All new clubs will automatically have proper owner memberships

## Related Files

- `server/routes.ts` (lines 2345-2360): Admin registration endpoint
- `server/routes.ts` (lines 140-142): `isCommunityAdmin()` function
- `shared/schema.ts` (line 488): `isOwner` column definition

## Migration Script

An idempotent migration script was created to fix any communities missing owner memberships:

**Location:** `scripts/migrations/fix-owner-memberships.ts`

**Run command:**
```bash
npx tsx scripts/migrations/fix-owner-memberships.ts
```

**Behavior:**
- Scans all communities to find those without an owner membership
- For each community without an owner, promotes the first admin membership to owner
- Safe to run multiple times (idempotent)
- Logs all actions and skips communities that are already correct

## Database Audit Results

### Query: Membership Status Per Community

```sql
SELECT 
  c.id, c.name,
  m.id as membership_id, m.account_id, m.user_id,
  m.role, m.is_owner, m.section_scope
FROM communities c
LEFT JOIN user_community_memberships m 
  ON m.community_id = c.id AND (m.is_owner = true OR m.role = 'admin')
ORDER BY c.id;
```

### Results After Fix (2026-01-20):

| Community | Owner Membership ID | Account ID | Role | is_owner | section_scope |
|-----------|---------------------|------------|------|----------|---------------|
| UNSA Lidl | 4fb9ea8e-... | 83c58566-... | super_admin | true | ALL |
| Club d'Échecs de Paris | 2a603043-... | 041eae4d-... | admin | true | ALL |
| Port-Bouët FC | bae54493-... | (null) | admin | true | ALL |

### Auth Log Evidence

```
[MEMBERSHIP-PLANS AUTH TEST-FIX-OWNER-2] 
  accountId=041eae4d-63b2-4abb-ad65-2eabf4eb46f6 
  userId=undefined 
  authType=account 
  communityId=82590b15-9394-4cfe-b99a-8a3b8df1e701 
  membership.id=2a603043-debe-415d-86f0-3fc33792f51a 
  role=admin 
  adminRole=null 
  isOwner=true 
  => allowed=true 
  reason=IS_OWNER
```

## Testing Checklist

- [x] Admin registration creates owner membership correctly
- [x] Owner can create membership plans
- [x] Owner has full access to all admin features
- [x] Existing affected communities migrated
- [x] Idempotent migration script created
- [x] 403 diagnostic logging in place

## Conclusion

The fix ensures that all admin users who register a new club are immediately recognized as the OWNER with full administrative privileges, preventing 403 errors on protected endpoints.
