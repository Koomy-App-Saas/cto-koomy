# Audit: Web Admin vs Mobile - Source of Truth

**Date**: 2026-01-27
**Version**: 1.0
**Status**: COMPLETED

## Executive Summary

This audit compares the Web Admin (backoffice) and Mobile Admin apps to verify they use the same source of truth for environment, community, plan/quota, and Stripe Connect status.

### Verdict: PARTIAL ALIGNMENT with P1 divergences

| Aspect | Alignment | Severity | Notes |
|--------|-----------|----------|-------|
| Environment (sandbox/prod) | ✅ ALIGNED | - | Both use `getApiBaseUrl()` from config.ts |
| Community current | ✅ ALIGNED | - | Both use AuthContext.currentCommunity |
| Plan display | ⚠️ DIVERGENT | P1 | Different sources (see details) |
| Quota | ⚠️ DIVERGENT | P1 | Web uses quota endpoint, mobile uses plan endpoint |
| Stripe Connect | ⚠️ DIVERGENT | P1 | Different endpoints used |

---

## A. Environment Resolution (ALIGNED)

### Source Files
- `client/src/api/config.ts` - `getApiBaseUrl()`
- `client/src/lib/appModeResolver.ts` - `resolveAppMode()`
- `client/src/lib/envGuard.ts` - `checkEnvironmentMismatch()`

### Behavior (Both Apps)
```
Priority order for API base URL:
1. Sandbox hostname enforcement (isSandbox → api-sandbox.koomy.app)
2. VITE_API_URL / VITE_API_BASE_URL env vars
3. wl.json cached URL
4. Native platform default
5. Known *.koomy.app → api.koomy.app
6. Fallback: api.koomy.app
```

### Boot Logs
Both apps log at boot (via `logBootDiagnostics()`):
- Hostname, isSandbox, Platform, isNative
- Effective API URL, Effective CDN URL
- Sample URL test for image resolution

**Verdict**: ✅ Both apps use identical environment resolution logic.

---

## B. Community Current (ALIGNED)

### Source
- `client/src/contexts/AuthContext.tsx`

### Behavior
Both AdminLayout and MobileAdminLayout:
1. Get `currentCommunity` from AuthContext
2. Fetch community details from `/api/communities/:id`
3. Use `selectCommunity(communityId)` to set current

**Verdict**: ✅ Same AuthContext provides community data.

---

## C. Plan Display (DIVERGENT - P1)

### Web Admin (AdminLayout.tsx)
```typescript
// Source: AuthContext.currentCommunity.planId
const isPaidPlan = currentCommunity.planId !== "free" && currentCommunity.planId != null;
// Display: currentCommunity.planId?.toUpperCase()
```

### Mobile Admin (MobileAdminLayout.tsx)
```typescript
// Source 1: Fetch community from /api/communities/:id
const { data: community } = useQuery<Community>({
  queryKey: [`/api/communities/${communityId}`],
});

// Source 2: Fetch plan details from /api/plans/:planId
const { data: plan } = useQuery<Plan>({
  queryKey: [`/api/plans/${community?.planId}`],
  enabled: !!community?.planId
});

// Display: plan?.name || community?.planId || "Free"
const planName = plan?.name || community?.planId || "Free";
```

### Divergence Analysis
| Aspect | Web Admin | Mobile Admin |
|--------|-----------|--------------|
| Plan source | AuthContext.currentCommunity | Fresh fetch + /api/plans |
| Plan name | planId.toUpperCase() | plan.name or planId |
| Staleness risk | May show cached plan | Always fresh |
| Extra API call | No | Yes (2 calls) |

### Recommendation
Align on backend source `/api/communities/:id/quota` which returns:
- `planCode`
- `limits` (quotas)
- Real-time data

---

## D. Quota Display (DIVERGENT - P1)

### Web Admin (Billing.tsx, Finances.tsx)
```typescript
// Quota endpoint
queryKey: [`/api/communities/${communityId}/quota`]
```

### Mobile Admin
No direct quota endpoint call found. Uses:
```typescript
// Plan info only (no limits)
queryKey: [`/api/plans/${community?.planId}`]
```

### Impact
- Web shows accurate member/admin limits
- Mobile shows plan name but not limits

### Recommendation
Mobile should also use `/api/communities/:id/quota` for limit display.

---

## E. Stripe Connect Status (DIVERGENT - P1)

### Web Admin (Finances.tsx)
```typescript
const { data: connectStatus } = useQuery({
  queryKey: [`/api/billing/stripe-connect/status`, communityId],
  queryFn: async () => {
    const res = await authGet(`/api/billing/stripe-connect/status?communityId=${communityId}`);
    return res.data;
  }
});
```

### Mobile Admin (Finances.tsx)
```typescript
// Different endpoint!
const res = await fetch("/api/payments/connect-community", {
  method: "POST",
  body: JSON.stringify({ communityId })
});
```

### Divergence Analysis
| Aspect | Web Admin | Mobile Admin |
|--------|-----------|--------------|
| Endpoint | GET /api/billing/stripe-connect/status | POST /api/payments/connect-community |
| Method | GET (read) | POST (action) |
| Purpose | Check status | Initiate connection |
| Returns status | Yes (detailed) | URL only |

### Impact
- Mobile cannot display Stripe Connect status before initiating
- Mobile only knows "connected or not" after attempting

### Recommendation
Mobile should call `/api/billing/stripe-connect/status` for status display.

---

## F. Cache Invalidation Analysis

### Current Strategy
| Context | Storage | Invalidation |
|---------|---------|--------------|
| Auth token | localStorage `koomy_token` | On logout |
| Membership | localStorage `koomy_current_membership` | On selectCommunity |
| Community | React Query cache | staleTime default |

### After Checkout Return
- Web (Billing/Return.tsx): Polls `/api/billing/verify-checkout-session`
- On success: `queryClient.invalidateQueries({ queryKey: ['/api/communities/'] })`

### Risk
- If community plan changes, cached AuthContext.currentCommunity may be stale
- MobileAdminLayout fetches fresh (safer)
- Web AdminLayout uses AuthContext (potentially stale)

---

## G. Endpoints Called at Dashboard Boot (Network Trace)

### Web Admin Dashboard (AdminLayout.tsx)
| Order | Method | Path | Status | UI Field |
|-------|--------|------|--------|----------|
| 1 | GET | /api/env | 200 | isSandbox badge |
| 2 | GET | /api/communities/:id/suspended-members-count | 200 | (if past_due) |

**Plan source**: `AuthContext.currentCommunity.planId` (no API call at boot)

### Mobile Admin Dashboard (MobileAdminLayout.tsx)
| Order | Method | Path | Status | UI Field |
|-------|--------|------|--------|----------|
| 1 | GET | /api/communities/:id | 200 | community data |
| 2 | GET | /api/plans/:planId | 200 | planName display |
| 3 | GET | /api/communities/:id/suspended-members-count | 200 | (if past_due) |

**Plan source**: Fresh API call to `/api/communities/:id` + `/api/plans/:planId`

### Mobile Admin Finances (Finances.tsx - Stripe Connect)
| Order | Method | Path | Status | UI Field |
|-------|--------|------|--------|----------|
| 1 | POST | /api/payments/connect-community | 200 | Initiates onboarding |

### Web Admin Finances (Finances.tsx - Stripe Connect)
| Order | Method | Path | Status | UI Field |
|-------|--------|------|--------|----------|
| 1 | GET | /api/billing/stripe-connect/status | 200 | Connect status display |
| 2 | POST | /api/billing/stripe-connect/onboarding-link | 200 | Initiates onboarding |

---

## H. P0/P1 Fixes Required

### P1-001: Align Plan Display Source
**Current**: Web uses AuthContext, Mobile fetches fresh
**Fix**: Both should use `/api/communities/:id/quota` as single source of truth

### P1-002: Add Quota Endpoint to Mobile
**Current**: Mobile doesn't fetch quotas
**Fix**: Mobile should call `/api/communities/:id/quota` and display limits

### P1-003: Align Stripe Connect Status Check
**Current**: Different endpoints
**Fix**: Mobile should use same `GET /api/billing/stripe-connect/status` endpoint

### P1-004: Add Cache Invalidation After Plan Change
**Current**: Risk of stale plan in AuthContext
**Fix**: After checkout success, invalidate community queries AND refresh AuthContext

---

## I. Instrumentation Already Present

Both apps already log at boot:
```
╔══════════════════════════════════════════════════════════════╗
║                    🚀 KOOMY APP BOOT                         ║
║ Hostname, isSandbox, Platform, isNative                      ║
║ Effective API, Effective CDN                                 ║
╚══════════════════════════════════════════════════════════════╝
```

### Instrumentation Added (2026-01-27)
- [x] communityId at boot
- [x] planCode + source endpoint
- [x] traceContext / sessionId for cross-platform comparison (WEB-xxx / MOB-xxx)
- [x] appMode (BACKOFFICE / CLUB_MOBILE)
- [x] isSandbox flag
- [x] effectiveApiBaseUrl
- [x] subscriptionStatus

Example log output:
```
[AdminLayout] 📊 Boot instrumentation: {
  traceContext: "WEB-TR-ABCD1234",
  appMode: "BACKOFFICE",
  communityId: "comm_xxx",
  planCode: "plus",
  planSource: "AuthContext.currentCommunity",
  isSandbox: false,
  effectiveApiBaseUrl: "https://api.koomy.app",
  subscriptionStatus: "active"
}
```

---

## J. Validation Criteria

| Criteria | Status |
|----------|--------|
| Same communityId shows same plan on web/mobile | ⚠️ Partially (different sources) |
| Stripe Connect status identical | ❌ Different endpoints |
| No render loop / layout shift | ✅ OK |
| Environment correctly detected | ✅ OK |

---

## Appendix: File References

| File | Purpose |
|------|---------|
| `client/src/api/config.ts` | API base URL, diagnostics |
| `client/src/lib/appModeResolver.ts` | App mode detection |
| `client/src/lib/envGuard.ts` | Environment validation |
| `client/src/contexts/AuthContext.tsx` | Auth state, currentCommunity |
| `client/src/components/layouts/AdminLayout.tsx` | Web admin layout |
| `client/src/components/MobileAdminLayout.tsx` | Mobile admin layout |
| `client/src/pages/admin/Finances.tsx` | Web Stripe Connect |
| `client/src/pages/mobile/admin/Finances.tsx` | Mobile Stripe Connect |
| `client/src/pages/admin/Billing.tsx` | Web quota display |
