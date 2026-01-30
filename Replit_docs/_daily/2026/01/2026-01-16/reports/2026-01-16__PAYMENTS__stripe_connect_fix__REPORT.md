# Stripe Connect Fix — "userId is required" (400 Error)

**Date:** 2026-01-20  
**Type:** Bug Fix  
**Status:** Resolved

---

## Root Cause

The `POST /api/payments/connect-community` route was expecting `userId` in the request body instead of deriving it from the authenticated user's session/token. This violated security best practices (clients should never send their own userId) and broke the flow since the frontend correctly omitted `userId` from the request.

The route lacked proper authentication middleware (`requireAuth`) and was treating `userId` as a required body parameter rather than extracting it from `req.user` or the JWT token.

---

## Files Modified

| File | Change |
|------|--------|
| `server/routes.ts` (lines 7154-7200) | Replaced `userId` body validation with `requireAuth()` call; used `getMembershipForAuth()` to verify admin role; added logging; response now includes both `url` and `onboardingUrl` for compatibility |

---

## Solution Details

### Before (broken)
```typescript
const { communityId, userId } = req.body;
if (!userId) {
  return res.status(400).json({ error: "userId is required" });
}
const membership = await storage.getMembership(userId, communityId);
```

### After (fixed)
```typescript
const authResult = requireAuth(req, res);
if (!authResult) return; // 401 already sent

const { communityId } = req.body;
const membership = await getMembershipForAuth(authResult, communityId);
```

---

## Response Format

The endpoint now returns:
```json
{
  "url": "https://connect.stripe.com/...",
  "onboardingUrl": "https://connect.stripe.com/...",
  "accountId": "acct_xxxxx"
}
```

The frontend uses `data.url`, so both fields are provided for compatibility.

---

## Manual Test Checklist

### Prerequisites
- [ ] Logged in as admin of a community
- [ ] Community does NOT have Stripe Connect configured yet

### Tests

| Scenario | Steps | Expected Result |
|----------|-------|-----------------|
| Authenticated admin | Click "Configurer" on Finances page | 200 OK, redirects to Stripe Connect onboarding |
| Not authenticated | Call POST /api/payments/connect-community without auth header | 401 Unauthorized |
| Authenticated but not admin | Use account without admin role on community | 403 Forbidden - Admin role required |
| Missing communityId | POST with empty body | 400 "communityId is required" |

### Server Logs to Verify
When clicking "Configurer":
```
[STRIPE CONNECT] Setting up for community: { communityId, authType, membershipId }
[STRIPE CONNECT] Setup complete: { communityId, accountId, hasUrl: true }
```

---

## Security Improvements

1. **No client-supplied userId** - Derived from authenticated session
2. **Proper 401 for unauthenticated** - requireAuth handles this
3. **Role verification** - Only admins can configure Stripe Connect
4. **Audit logging** - All attempts logged with auth context
