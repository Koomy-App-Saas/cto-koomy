# White-Label Community Creation Fix Report

**Date**: 2026-01-30  
**Domain**: SAAS_OWNER  
**Type**: Bug Fix  

## Issue Summary

The "Nouveau Client" (New Client) button in the SaaS Owner Platform appeared to create a community successfully (showing a "Client Créé" toast notification), but no community was actually created in the database.

## Root Cause

The `handleCreateClient()` function in `SuperDashboard.tsx` was an **empty stub** that:
1. Only displayed a success toast message
2. Closed the dialog modal
3. Reset the form field
4. **Made NO API call whatsoever**

```typescript
// BEFORE (broken)
const handleCreateClient = () => {
  toast({ title: "Client Créé", description: `L'organisation "${newClientName}" a été ajoutée avec succès.` });
  setIsCreateClientOpen(false);
  setNewClientName("");
};
```

## Changes Made

### 1. Backend - New API Endpoint

**File**: `server/routes.ts`

Created `POST /api/platform/communities` endpoint that:
- Verifies platform super admin authorization
- Validates required fields (name, planId)
- Creates a new community with appropriate defaults:
  - `billingMode: 'manual_contract'`
  - `subscriptionStatus: 'active'`
  - `whiteLabel: false` (can be enabled later via WL settings modal)
- Returns success response with created community data
- Returns explicit error on failure

### 2. Frontend - State Variables

**File**: `client/src/pages/platform/SuperDashboard.tsx`

Added new state variables:
- `newClientPlanId` - tracks selected plan in form
- `isCreatingClient` - loading state during API call

### 3. Frontend - handleCreateClient Implementation

Replaced the stub with a proper async function that:
- Validates form inputs before submission
- Calls `POST /api/platform/communities` API endpoint
- Handles success: shows toast, closes modal, resets form, invalidates query cache
- Handles errors: shows error toast with message from backend
- Shows loading state on button during submission

### 4. Frontend - Form Binding

- Connected the plan Select component to `newClientPlanId` state
- Added loading indicator to submit button
- Button disabled during creation

### 5. Query Invalidation Fix

Fixed the query key from `["platform-communities"]` to `["platform-all-communities", user?.id]` to match the actual query used for fetching communities.

## Files Modified

1. `server/routes.ts` - Added POST /api/platform/communities endpoint
2. `client/src/pages/platform/SuperDashboard.tsx` - Fixed handleCreateClient, added states

## Verification

After fix:
- Creating a client from SaaS Owner Platform will create a real community in the database
- Error scenarios will display appropriate error messages
- Success will refresh the communities list automatically
- Community appears immediately in the "Clients Actifs" table

## Next Steps (Optional Enhancements)

1. Consider adding WL-specific defaults when creating WL communities
2. Add email notification to admin when community is created
3. Option to create owner admin during community creation
