# Enterprise Member Quota Restoration - Implementation Report

**Date**: 2026-01-30  
**Domain**: SAAS_OWNER  
**Type**: Feature Restoration  

## Issue Summary

The SaaS Owner Platform was missing the ability to configure member quotas (places utilisateurs/membres) for Grand Compte and Grand Compte + White-Label clients. While the "Quota Administrateurs" section existed, the equivalent "Quota Membres" section was absent from the UI, even though the database columns and backend logic already supported this feature.

## Root Cause

The quota members configuration was not exposed in the SaaS Owner UI despite:
1. Database columns existing (`contract_member_limit`, `max_members_allowed`)
2. Backend resolver function (`resolveCommunityLimits`) already calculating effective member limits
3. API endpoint (`/api/platform/communities/:id/quota-limits`) already returning member count data

The missing piece was:
- Frontend states for member quotas
- UI section for member quota configuration
- API PATCH support for updating member quotas

## Database Schema Verification

### SQL Verification Queries

#### 1. Verify columns exist
```sql
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'communities' 
AND column_name IN (
  'contract_member_limit',
  'max_members_allowed', 
  'contract_member_alert_threshold',
  'white_label_included_members',
  'white_label_max_members_soft_limit'
)
ORDER BY column_name;
```

**Expected Result:**
```
column_name                           | data_type | is_nullable | column_default
--------------------------------------+-----------+-------------+---------------
contract_member_alert_threshold       | integer   | YES         | 90
contract_member_limit                 | integer   | YES         | 
max_members_allowed                   | integer   | YES         | 
white_label_included_members          | integer   | YES         | 
white_label_max_members_soft_limit    | integer   | YES         | 
```

#### 2. Verify sample community data
```sql
SELECT id, name, plan_id, account_type,
       max_members_allowed, contract_member_limit,
       contract_admin_limit, max_admins_default
FROM communities 
WHERE account_type = 'GRAND_COMPTE'
LIMIT 5;
```

#### 3. Test update query (safe - single community)
```sql
-- Example: Set 500 members for a Grand Compte client
UPDATE communities 
SET contract_member_limit = 500
WHERE id = '<community_id>' 
AND account_type = 'GRAND_COMPTE';
```

## Changes Made

### 1. Frontend - State Variables (`SuperDashboard.tsx`)

Added new states for member quotas (lines 399-405):
- `quotaMaxMembersDefault` - form input value
- `quotaMaxMembersOverride` - contractual override value  
- `quotaEffectiveMaxMembers` - calculated effective limit
- `quotaMaxMembersSource` - source of limit (override/default/plan)
- `quotaPlanDefaultMembers` - plan's default limit
- `quotaCurrentMemberCount` - current member usage

### 2. Frontend - Data Loading (`SuperDashboard.tsx`)

Updated `loadQuotaLimits` function to populate member quota states from API response.

### 3. Frontend - Data Saving (`SuperDashboard.tsx`)

Updated `saveQuotaLimits` function to include member quota fields in PATCH payload:
- `maxMembersDefault` → `max_members_allowed` column
- `maxMembersOverride` → `contract_member_limit` column

### 4. Frontend - UI Section (`SuperDashboard.tsx`)

Added "Quota Membres (Grand Compte / Enterprise)" section in the Quotas tab showing:
- Current usage vs effective limit
- Effective member limit
- Source indicator (override/default/plan)
- Plan default limit
- Input for max members (default)
- Input for max members (override contractuel)

### 5. Backend - API PATCH (`server/routes.ts`)

Enhanced `/api/platform/communities/:id/quota-limits` endpoint to:
- Accept `maxMembersDefault` and `maxMembersOverride` in request body
- Validate member quota values (positive integers)
- Update `max_members_allowed` and `contract_member_limit` columns
- Include member quota data in audit logs
- Return member quota data in response

### 6. Backend - API GET (`server/routes.ts`)

Already returned all necessary fields from `resolveCommunityLimits`:
- `effectiveMaxMembers`
- `maxMembersSource`
- `maxMembersAllowed`
- `contractMemberLimit`
- `planMaxMembers`
- `currentMemberCount`

## Files Modified

1. `client/src/pages/platform/SuperDashboard.tsx`
   - Added 6 new state variables for member quotas
   - Updated `loadQuotaLimits` to set member states
   - Updated `saveQuotaLimits` to send member values
   - Updated `openWhiteLabelModal` to reset member states
   - Added UI section for member quota configuration

2. `server/routes.ts`
   - Added `maxMembersDefault` and `maxMembersOverride` to PATCH handler
   - Added validation for member quota values
   - Added member quota fields to `beforeValues` and `afterValues` for audit
   - Updated `updateData` to include member columns

## Source of Truth

The quota resolution follows this priority chain (same as admin quotas):

1. **Override contractuel** (`contract_member_limit`) - Highest priority
2. **Valeur par défaut** (`max_members_allowed`) - Medium priority  
3. **Plan par défaut** (from `plans.max_members`) - Lowest priority

This logic is implemented in `server/lib/planLimits.ts` → `resolveCommunityLimits()`.

## API Endpoints

### GET `/api/platform/communities/:id/quota-limits`

Returns:
```json
{
  "effectiveMaxMembers": 500,
  "maxMembersSource": "override",
  "maxMembersAllowed": null,
  "contractMemberLimit": 500,
  "planMaxMembers": null,
  "currentMemberCount": 127,
  "effectiveMaxAdmins": 10,
  "maxAdminsSource": "override",
  ...
}
```

### PATCH `/api/platform/communities/:id/quota-limits`

Request body:
```json
{
  "maxMembersDefault": 250,
  "maxMembersOverride": 500,
  "maxAdminsDefault": 5,
  "maxAdminsOverride": 10,
  "reason": "Extension contrat Grand Compte XYZ"
}
```

## Manual Tests

1. **Open SaaS Owner Platform** → Navigate to client configuration modal
2. **Go to "Quotas" tab** → Verify both "Quota Administrateurs" and "Quota Membres" sections visible
3. **Check current values** → Verify member count and effective limit displayed
4. **Set override value** → Enter 500 in "Max membres (override contractuel)"
5. **Save** → Click "Sauvegarder les quotas"
6. **Verify persistence** → Reload modal, verify values persist
7. **Verify source** → Source should show "Override contractuel"

## Rollback (if needed)

No database migration required. To rollback:
1. Revert frontend changes (remove member quota states and UI)
2. Revert backend changes (remove member fields from PATCH handler)
3. Existing data in `contract_member_limit` and `max_members_allowed` columns remains unchanged
