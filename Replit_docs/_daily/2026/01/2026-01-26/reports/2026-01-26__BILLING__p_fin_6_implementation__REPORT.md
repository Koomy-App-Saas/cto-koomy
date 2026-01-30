# P-FIN.6 Implementation Report

**Date:** 2026-01-26
**Status:** COMPLETED

## Summary

Implementation of paid memberships with KOOMY commission (percentage + fixed fee) and fix for broken Stripe Connect onboarding.

## Changes Made

### Phase 0 - Audit (DONE)
- Identified missing frontend routes for Stripe Connect OAuth callbacks
- Root cause: `/payments/connect/success` and `/payments/connect/refresh` routes not defined in App.tsx
- Documented in `docs/_daily/2026/01/2026-01-26/audits/2026-01-26__BILLING__p_fin_6_connect_onboarding_bug__AUDIT.md`

### Phase 1 - Stripe Connect Routes (DONE)
**Files modified:**
- `client/src/pages/admin/ConnectReturn.tsx` - New component to handle Connect OAuth callbacks
- `client/src/App.tsx` - Added routes for `/payments/connect/success` and `/payments/connect/refresh`
- `server/routes.ts` - Added `GET /api/connect/status` and `POST /api/connect/account-link` endpoints
- `server/stripeConnect.ts` - Used existing `getStripeConnectUrls()` for redirect URLs

**Behavior:**
1. Admin initiates Connect onboarding from settings
2. Redirected to Stripe for OAuth
3. Returns to `/payments/connect/success` on completion
4. ConnectReturn page shows status and refresh options

### Phase 2 - Commission Configuration (DONE)
**Files modified:**
- `shared/schema.ts` - Added `connectFeeFixedCents` field to communities table

**Schema addition:**
```typescript
connectFeeFixedCents: integer("connect_fee_fixed_cents").default(0)
```

**Commission Model:**
- `platformFeePercent` (existing) - Percentage fee (default 2%)
- `connectFeeFixedCents` (new) - Fixed fee in cents (default 0)
- Total commission: `(amount * percent / 100) + fixed`
- Configurable via existing updateCommunity API

### Phase 3 - Membership Payment Flow (DONE)
**Files modified:**
- `server/routes.ts` - Updated `/api/payments/create-membership-session`

**Commission Calculation:**
```typescript
const feePercent = Math.max(0, community.platformFeePercent ?? 2);
const feeFixedCents = Math.max(0, community.connectFeeFixedCents ?? 0);
const calculatedFee = Math.round(amount * feePercent / 100) + feeFixedCents;
const applicationFeeAmount = Math.min(calculatedFee, amount);
```

**Safeguards:**
- Negative values prevented with `Math.max(0, ...)`
- Fee capped at payment amount with `Math.min(calculatedFee, amount)`

**Metadata:**
```json
{
  "flow": "MEMBERSHIP",
  "type": "membership",
  "communityId": "...",
  "membershipId": "...",
  "userId": "..."
}
```
- `flow: "MEMBERSHIP"` added for traceability per P-FIN.6 contract
- `type: "membership"` preserved for backward compatibility with existing webhooks

### Phase 4 - Webhook Handling (EXISTING)
No changes required - existing handlers already support membership payments:
- `handleCheckoutCompleted` → `handleMembershipPaymentCompleted`
- `handlePaymentIntentSucceeded` → `handleMembershipPayment`

Both record transactions with commission details in the `transactions` table.

## Architecture Decisions

1. **Adaptation over rewrite:** Added `flow` metadata while keeping existing `type` for backward compatibility
2. **Single commission model:** Used existing `platformFeePercent` + new `connectFeeFixedCents` instead of creating separate tables
3. **Validation at payment time:** Commission values validated during checkout creation, not at storage time
4. **No new UI:** Commission can be configured through existing platform admin community update endpoints

## Files Changed Summary

| File | Changes |
|------|---------|
| `client/src/pages/admin/ConnectReturn.tsx` | New - Handle Connect OAuth callbacks |
| `client/src/App.tsx` | Routes for `/payments/connect/*` |
| `server/routes.ts` | Connect status/link endpoints, commission calculation |
| `server/stripeConnect.ts` | Used for redirect URL generation |
| `shared/schema.ts` | Added `connectFeeFixedCents` field |

## Testing Notes

- Server starts without errors
- Routes properly registered
- Commission calculation validated with edge cases (negative, exceeds amount)
- Existing webhook handlers continue to work

## Known Limitations

1. Commission configuration UI not added - uses existing API
2. Commission applies to all Connect memberships uniformly per community
3. Fixed fee in cents only (no sub-cent precision)
