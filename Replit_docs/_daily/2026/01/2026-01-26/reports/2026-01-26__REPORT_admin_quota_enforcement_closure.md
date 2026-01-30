# Report: Admin Quota Enforcement Closure (P0 Fix)

**Date:** 2026-01-26  
**ID:** P0-ADMIN-QUOTA-ENFORCEMENT  
**Status:** IMPLEMENTED

---

## 1. Fixed Bypass Paths

| Route | Fix Applied | Line Numbers |
|-------|-------------|--------------|
| `POST /api/admin/join` | Added `checkLimit(communityId, "maxAdmins")` before membership creation | routes.ts:3129-3144 |
| `POST /api/admin/join-with-credentials` | Added `checkLimit(communityId, "maxAdmins")` before membership creation | routes.ts:3298-3313 |
| `PATCH /api/memberships/:id` | Block role changes entirely (Option C1) | routes.ts:6003-6019 |

---

## 2. Option Chosen for PATCH Membership

**Selected: Option C1 (Forbid role changes entirely)**

### Rationale:
- Safest approach with minimal risk of regression
- Product already has dedicated endpoint: `POST /api/communities/:communityId/admins`
- Role changes should require explicit owner/platform action
- Prevents any future bypass through this generic endpoint

### Implementation:
```typescript
if (updates.role !== undefined && updates.role !== currentMembership.role) {
  return res.status(400).json({
    error: "Le changement de rôle doit passer par les endpoints dédiés",
    code: "ROLE_CHANGE_NOT_ALLOWED"
  });
}
delete updates.role;
delete updates.adminRole;
```

---

## 3. Verification Commands (curl examples)

### 3.1 Test admin join quota enforcement

```bash
# Setup: Ensure community has maxAdmins=1 and already has 1 admin

# Attempt to join (should fail with 403)
curl -X POST http://localhost:5000/api/admin/join \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <firebase_token>" \
  -d '{"joinCode": "TESTCODE"}' \
  -w "\n%{http_code}\n"

# Expected response:
# {
#   "error": "Quota d'administrateurs atteint",
#   "code": "PLAN_ADMIN_QUOTA_EXCEEDED",
#   "current": 1,
#   "max": 1,
#   "traceId": "AJ-xxx"
# }
# 403
```

### 3.2 Test join-with-credentials quota enforcement

```bash
curl -X POST http://localhost:5000/api/admin/join-with-credentials \
  -H "Content-Type: application/json" \
  -d '{"joinCode": "TESTCODE", "email": "test@example.com", "password": "password123"}' \
  -w "\n%{http_code}\n"

# Expected: 403 with PLAN_ADMIN_QUOTA_EXCEEDED
```

### 3.3 Test role change blocking

```bash
curl -X PATCH http://localhost:5000/api/memberships/<membership-id> \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <firebase_token>" \
  -d '{"role": "admin"}' \
  -w "\n%{http_code}\n"

# Expected response:
# {
#   "error": "Le changement de rôle doit passer par les endpoints dédiés",
#   "code": "ROLE_CHANGE_NOT_ALLOWED"
# }
# 400
```

### 3.4 Verify existing admin creation still works

```bash
curl -X POST http://localhost:5000/api/communities/<community-id>/admins \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <owner_token>" \
  -d '{
    "email": "newadmin@example.com",
    "firstName": "New",
    "lastName": "Admin"
  }' \
  -w "\n%{http_code}\n"

# Expected: 201 if quota not exceeded, 403 with PLAN_ADMIN_QUOTA_EXCEEDED if exceeded
```

---

## 4. Observability

All blocked requests log with structured format:

```
[Admin Join ${traceId}] BLOCKED: admin quota exceeded {
  communityId: "...",
  current: N,
  max: M
}

[Admin JoinWithCreds ${traceId}] BLOCKED: admin quota exceeded {
  communityId: "...",
  current: N,
  max: M
}

[MEMBER UPDATE] BLOCKED: Role change attempted via PATCH {
  membershipId: "...",
  communityId: "...",
  currentRole: "member",
  attemptedRole: "admin"
}
```

---

## 5. Schema Naming Verification

Confirmed in codebase:
- Code reads from `plans` table (not `koomy_plans`)
- `/api/health/db` endpoint checks:
  - `public.communities`: `max_admins_default`, `contract_admin_limit`, `contract_member_limit`
  - `public.plans`: `max_admins`

No references to `koomy_plans` table found in runtime code.

---

## 6. Files Modified

| File | Changes |
|------|---------|
| `server/routes.ts` | Added quota checks to join routes, blocked role changes in PATCH |
| `server/tests/admin-quota-enforcement.test.ts` | New regression test file |
| `docs/rapports/REPORT_admin_quota_enforcement_closure.md` | This report |

---

## 7. Acceptance Checklist

- [x] Creating admin via join code cannot exceed quota (403 with PLAN_ADMIN_QUOTA_EXCEEDED)
- [x] join-with-credentials same behavior
- [x] Membership patch cannot be used to bypass quota (ROLE_CHANGE_NOT_ALLOWED)
- [x] Existing admin creation endpoint (`POST /api/communities/:id/admins`) remains working
- [x] No client changes required

---

## 8. Single Source of Truth

Quota resolution remains centralized:

```
checkLimit(communityId, "maxAdmins")
  └→ getEffectivePlan(communityId)
       └→ Priority: contract_admin_limit > max_admins_default > plans.max_admins > DEFAULT_LIMITS
```

**End of Report**
