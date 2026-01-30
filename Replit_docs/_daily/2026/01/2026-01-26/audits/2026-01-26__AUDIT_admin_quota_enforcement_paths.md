# Audit: Admin Quota Enforcement Paths

**Date:** 2026-01-26  
**Scope:** All routes/functions where an admin can be created or promoted  
**Status:** GAPs IDENTIFIED

---

## 1. Admin Creation/Promotion Routes Identified

| Route | File:Line | Purpose | Quota Check? |
|-------|-----------|---------|--------------|
| `POST /api/communities/:communityId/admins` | `server/routes.ts:4688` | Create admin by owner | ✅ YES (line 4757) |
| `POST /api/admin/join` | `server/routes.ts:3064` | Join via code (Firebase) | ❌ NO |
| `POST /api/admin/join-with-credentials` | `server/routes.ts:3221` | Join via code + password | ❌ NO |
| `POST /api/admin/register-community` | `server/routes.ts:3395` | Register new community | N/A (creates owner, not admin) |
| `POST /api/admin/register` | `server/routes.ts:3549` | Register new community | N/A (creates owner, not admin) |
| `POST /api/memberships` | `server/routes.ts:5358` | Create membership | N/A (forces role=member, line 5398) |
| `PATCH /api/memberships/:id` | `server/routes.ts:5937` | Update membership | ⚠️ PARTIAL (role update possible, no quota check) |

---

## 2. Detailed Path Analysis

### 2.1 `POST /api/communities/:communityId/admins` ✅ ENFORCED

**Location:** `server/routes.ts:4688-4772`

**Quota check:**
```typescript
// Line 4755-4772
const adminQuotaCheck = await checkLimit(communityId, "maxAdmins");
if (!adminQuotaCheck.allowed) {
  return res.status(403).json({
    code: "PLAN_ADMIN_QUOTA_EXCEEDED",
    ...
  });
}
```

**Fields used:** Via `checkLimit()` → `getEffectivePlan()`:
- `contractAdminLimit` (priority 1)
- `maxAdminsDefault` (priority 2)
- `plan.maxAdmins` from DB (priority 3)
- `DEFAULT_LIMITS[planId].maxAdmins` (fallback)

---

### 2.2 `POST /api/admin/join` ❌ MISSING QUOTA CHECK

**Location:** `server/routes.ts:3064-3217`

**Current behavior:**
- Validates join code (line 3077)
- Checks if community is STANDARD (not WL) (line 3117)
- Checks if user already member (line 3131)
- Creates admin membership with `role: 'admin'` (line 3168)

**Missing:** No `checkLimit(communityId, "maxAdmins")` call before line 3164.

**Risk:** Unlimited admins can join via join code, bypassing quota.

---

### 2.3 `POST /api/admin/join-with-credentials` ❌ MISSING QUOTA CHECK

**Location:** `server/routes.ts:3221-3391`

**Current behavior:**
- Validates join code (line 3235)
- Validates email/password (line 3227)
- Creates/authenticates user (line 3321)
- Creates admin membership with `role: 'admin'` (line 3341)

**Missing:** No `checkLimit(communityId, "maxAdmins")` call before line 3337.

**Risk:** Unlimited admins can join via credentials, bypassing quota.

---

### 2.4 `PATCH /api/memberships/:id` ⚠️ PARTIAL

**Location:** `server/routes.ts:5937-6084`

**Current behavior:**
- Allows updating various membership fields
- **Does not explicitly block role changes** (updates passed through at line 5946)
- No quota check for role promotion to admin

**Potential bypass:** If `req.body.role = "admin"` is accepted and passed to `storage.updateMembership()`, a member could be promoted to admin without quota check.

**Needs verification:** Check if `storage.updateMembership()` allows role field updates.

---

## 3. Single Source of Truth for Admin Quota

**YES** - Centralized in `server/lib/planLimits.ts`

### Primary function: `getEffectivePlan()` (line 267-323)

**Priority order (lines 295-304):**
```typescript
// RÈGLE DE PRIORITÉ ADMINS (P1):
// 1. contractAdminLimit (override contractuel) si présent
// 2. sinon maxAdminsDefault si présent
// 3. sinon DEFAULT_LIMITS[plan].maxAdmins
if (community.contractAdminLimit !== null && community.contractAdminLimit !== undefined) {
  planLimits.maxAdmins = community.contractAdminLimit;
} else if (community.maxAdminsDefault !== null && community.maxAdminsDefault !== undefined) {
  planLimits.maxAdmins = community.maxAdminsDefault;
}
```

### Enforcement function: `checkLimit()` in `server/lib/usageLimitsGuards.ts` (line 110-141)

**Admin count query:** `getAdminCount()` (line 49-63)
- Counts roles: `admin` OR `delegate`

---

## 4. Fields Used for Admin Quota Resolution

| Field | DB Column | Table | Description |
|-------|-----------|-------|-------------|
| `contractAdminLimit` | `contract_admin_limit` | `communities` | Contractual override (highest priority) |
| `maxAdminsDefault` | `max_admins_default` | `communities` | SaaS-configured default |
| `maxAdmins` | `max_admins` | `plans` | Plan-level limit |
| `DEFAULT_LIMITS` | N/A (code) | `planLimits.ts:31-36` | Hardcoded fallback |

---

## 5. Bypass Summary

| Path | Bypass Type | Severity |
|------|-------------|----------|
| `/api/admin/join` | No quota check | **HIGH** |
| `/api/admin/join-with-credentials` | No quota check | **HIGH** |
| `PATCH /api/memberships/:id` | Role promotion without check | **MEDIUM** (needs storage verification) |

---

## 6. Recommendations

### P0 - Critical Fixes

1. **Add quota check to `/api/admin/join`** (line ~3160):
```typescript
const adminQuotaCheck = await checkLimit(community.id, "maxAdmins");
if (!adminQuotaCheck.allowed) {
  return res.status(403).json({
    error: `Quota d'administrateurs atteint (${adminQuotaCheck.current}/${adminQuotaCheck.max})`,
    code: "PLAN_ADMIN_QUOTA_EXCEEDED",
    traceId
  });
}
```

2. **Add quota check to `/api/admin/join-with-credentials`** (line ~3330):
   Same pattern as above.

3. **Block role promotion in `PATCH /api/memberships/:id`** OR add quota check:
```typescript
if (updates.role && updates.role !== currentMembership.role) {
  if (['admin', 'delegate'].includes(updates.role)) {
    const quotaCheck = await checkLimit(communityId, "maxAdmins");
    if (!quotaCheck.allowed) {
      return res.status(403).json({ code: "PLAN_ADMIN_QUOTA_EXCEEDED", ... });
    }
  }
}
```

---

## 7. Files Referenced

| File | Purpose |
|------|---------|
| `server/routes.ts` | All API routes |
| `server/lib/planLimits.ts` | Quota resolution logic |
| `server/lib/usageLimitsGuards.ts` | Limit checking functions |
| `shared/schema.ts` | Database schema definitions |

---

**End of Audit**
