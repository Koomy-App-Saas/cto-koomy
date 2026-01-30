# KOOMY Option A: Generic Paid Upgrade Implementation

**Date**: 2026-01-19
**Status**: IMPLEMENTED

## Summary

The paid plan upgrade flow has been made **fully data-driven and generic**. No plan IDs, codes, or prices are hardcoded anywhere in the codebase. The system works with ANY paid plan defined in the database.

## Key Changes

### 1. PATCH /api/communities/:id/plan (server/routes.ts)

**Before**: Hardcoded plan IDs like `["plus", "pro"].includes(newPlanId)`

**After**: Data-driven validation using database:
```typescript
// Load plans from DB
const currentPlan = await storage.getPlan(currentPlanId);
const targetPlan = await storage.getPlan(newPlanId);

// Data-driven blocking logic
const isUpgrade = (targetPlan.sortOrder ?? 0) > (currentPlan?.sortOrder ?? 0);
const isPaidTarget = (targetPlan.priceMonthly && targetPlan.priceMonthly > 0) || 
                     (targetPlan.priceYearly && targetPlan.priceYearly > 0);

if (isUpgrade && isPaidTarget) {
  return res.status(403).json({
    error: "PAID_UPGRADE_REQUIRED",
    message: "Paid plan upgrades require Stripe payment. Use the upgrade checkout flow."
  });
}
```

### 2. POST /api/billing/create-upgrade-checkout-session (server/routes.ts)

**Before**: Only accepted `["plus", "pro"]` as valid `targetPlanId`

**After**: Accepts ANY plan ID, validates using DB data:
- Loads target plan from database
- Checks `sortOrder` for upgrade direction
- Verifies target plan is paid (`priceMonthly > 0` OR `priceYearly > 0`)
- Passes full plan data to Stripe function

### 3. createUpgradeCheckoutSession (server/stripe.ts)

**Before**: Used `getPriceId()` with hardcoded Stripe price IDs

**After**: Uses `price_data` with dynamic plan information:
```typescript
line_items: [{
  price_data: {
    currency: "eur",
    product_data: {
      name: `Koomy ${targetPlan.name}`,
      description: targetPlan.description || undefined,
    },
    unit_amount: priceAmount, // From plan.priceMonthly or plan.priceYearly
    recurring: {
      interval: billingPeriod === "yearly" ? "year" : "month",
    },
  },
  quantity: 1,
}]
```

### 4. Billing.tsx (client/src/pages/admin/Billing.tsx)

**Before**: Checked `selectedPlan.code === "PLUS" || selectedPlan.code === "PRO"`

**After**: Data-driven price check:
```typescript
const isPaidTarget = (selectedPlan.priceMonthly && selectedPlan.priceMonthly > 0) || 
                     (selectedPlan.priceYearly && selectedPlan.priceYearly > 0);

if (isUpgrade && isPaidTarget) {
  // Stripe Checkout with actual plan ID
  upgradeCheckoutMutation.mutate({ targetPlanId: selectedPlan.id, billingPeriod });
}
```

## Security Guarantees

1. **All paid upgrades require Stripe**: No bypass possible via PATCH /plan
2. **EUR-only currency**: Hardcoded in Stripe checkout (V1 requirement)
3. **Price validation**: Only plans with `priceMonthly > 0` or `priceYearly > 0` trigger Stripe
4. **Direction validation**: Only upgrades (higher `sortOrder`) are blocked, downgrades allowed

## How to Add New Plans

To add a new paid plan (e.g., "enterprise", "premium", "scale"):

1. Add plan to `plans` table with:
   - `id`: unique identifier (e.g., "enterprise")
   - `priceMonthly`: monthly price in cents (e.g., 29900 for €299)
   - `priceYearly`: yearly price in cents (e.g., 299000 for €2990)
   - `sortOrder`: higher than existing plans for upgrade hierarchy

2. No code changes required - the system will automatically:
   - Block upgrades to this plan via PATCH /plan (403 PAID_UPGRADE_REQUIRED)
   - Accept it in upgrade checkout endpoint
   - Create Stripe checkout with correct price

## Test Scenarios

| Scenario | Current Plan | Target Plan | Expected Result |
|----------|-------------|-------------|-----------------|
| Free to Paid | free (order=0, price=0) | plus (order=1, price=990) | 403 PAID_UPGRADE_REQUIRED |
| Free to Free | free | free | OK (no change) |
| Paid to Higher Paid | plus (order=1) | pro (order=2, price=1990) | 403 PAID_UPGRADE_REQUIRED |
| Downgrade | pro (order=2) | plus (order=1) | OK (direct PATCH) |
| Downgrade to Free | plus | free | OK (direct PATCH with quota check) |

## Files Modified

- `server/routes.ts`: PATCH /plan, POST /billing/create-upgrade-checkout-session
- `server/stripe.ts`: createUpgradeCheckoutSession interface and implementation
- `client/src/pages/admin/Billing.tsx`: handleConfirmChange function
