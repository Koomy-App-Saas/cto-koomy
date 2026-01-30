# Koomy Option A - Paid Upgrade Implementation Report

**Date**: 2026-01-19  
**Status**: COMPLETED ✅  
**Type**: Security Enhancement - Payment Required Before Access

---

## Summary

This implementation ensures that all upgrades to paid plans (PLUS/PRO) require Stripe payment completion **BEFORE** access is granted. This closes the security vulnerability where users could bypass payment and directly modify their planId.

---

## Changes Implemented

### 1. Backend - New Endpoint (server/stripe.ts)
**Function**: `createUpgradeCheckoutSession()`
- Creates Stripe Checkout session for paid plan upgrades
- Metadata includes `payment_reason: "upgrade"` for tracking
- Handles customer creation if not exists
- Returns redirect URL to Stripe Checkout

### 2. Backend - New API Route (server/routes.ts)
**Endpoint**: `POST /api/billing/create-upgrade-checkout-session`
- Validates communityId, targetPlanId (plus/pro), billingPeriod (monthly/yearly)
- Enforces plan order validation (can only upgrade, not downgrade via this endpoint)
- Returns `{ redirectUrl, sessionId }`

### 3. Backend - Security Patch (server/routes.ts)
**Endpoint**: `PATCH /api/communities/:id/plan`
- Now blocks paid upgrades (FREE→PLUS, FREE→PRO, PLUS→PRO)
- Returns HTTP 403 with error code `PAID_UPGRADE_REQUIRED`
- Allows downgrades and same-plan changes (with quota validation)

### 4. Backend - Webhook Enhancement (server/stripe.ts)
**Function**: `handleCheckoutCompleted()`
- Added handling for `payment_reason: "upgrade"`
- Logs upgrade completions distinctly from registrations
- Sends confirmation email on upgrade completion
- Updates community planId and subscriptionStatus after payment

### 5. Frontend - Billing.tsx
**Changes**:
- Added `upgradeCheckoutMutation` for paid upgrades
- Modified `handleConfirmChange()` to route:
  - Paid upgrades → Stripe Checkout (new mutation)
  - Downgrades → Direct PATCH /plan (existing mutation)
- Updated button states to show "Redirection vers le paiement..." during checkout creation

---

## Plan Order Validation

| Plan | Order | 
|------|-------|
| FREE | 0 |
| PLUS | 1 |
| PRO | 2 |
| ENTERPRISE | 3 |

**Rules**:
- `targetOrder > currentOrder` + paid plan = Stripe required
- `targetOrder <= currentOrder` = Direct PATCH allowed (downgrade)

---

## Test Cases

| # | Scenario | Expected | Status |
|---|----------|----------|--------|
| 1 | FREE → PLUS via Billing.tsx | Redirects to Stripe Checkout | ✅ |
| 2 | FREE → PRO via Billing.tsx | Redirects to Stripe Checkout | ✅ |
| 3 | PLUS → PRO via Billing.tsx | Redirects to Stripe Checkout | ✅ |
| 4 | PLUS → FREE via Billing.tsx | Direct PATCH (with quota check) | ✅ |
| 5 | FREE → PLUS via direct PATCH | Returns 403 PAID_UPGRADE_REQUIRED | ✅ |

---

## Security Guarantees

1. **No payment bypass**: PATCH /plan returns 403 for all paid upgrades
2. **Plan activation after payment only**: Webhook updates planId after checkout.session.completed
3. **Idempotent**: Multiple webhook calls for same session don't duplicate updates
4. **Audit trail**: All upgrades logged with payment_reason for tracking

---

## Files Modified

- `server/stripe.ts` - Added createUpgradeCheckoutSession(), enhanced webhook
- `server/routes.ts` - Added new endpoint, secured PATCH /plan
- `client/src/pages/admin/Billing.tsx` - Stripe Checkout integration

---

## Related Documents

- `Docs/Audits/KOOMY_AUDIT_PLAN_VS_CAPACITY.md` - Original audit findings
- `Docs/Audits/KOOMY_OPTION_A_IMPLEMENTATION_REPORT.md` - Registration flow (already implemented)
