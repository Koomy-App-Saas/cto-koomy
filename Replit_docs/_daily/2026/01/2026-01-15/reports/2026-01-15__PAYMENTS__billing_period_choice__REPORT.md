# Koomy Billing Period Choice Implementation Report

## Date: 2026-01-19

## Summary

Added monthly/yearly billing period toggle to the admin billing page with dynamic price display and integrated period selection in the upgrade dialog.

## Changes Implemented

### 1. Billing Period Toggle (`Billing.tsx`)

- Added `billingPeriod` state with "monthly" | "yearly" options
- Implemented `Tabs` component above plan cards for period selection
- Toggle displays "Mensuel" / "Annuel" options

### 2. Dynamic Price Display

- `formatPrice(price, period)` function updated to show:
  - Monthly: "XX€ /mois"
  - Yearly: "XX€ /an"
- `getYearlySavings(plan)` calculates savings percentage:
  ```typescript
  Math.round(((priceMonthly * 12 - priceYearly) / (priceMonthly * 12)) * 100)
  ```
- Plan cards show appropriate price based on selected period
- Yearly savings badge displayed when applicable

### 3. Upgrade Dialog Enhancement

- Added billing period toggle inside upgrade confirmation dialog
- Real-time price display updates when period changes
- Savings percentage shown for yearly selection
- Button text changed to "Payer et confirmer" for clarity

### 4. Success Page (`Success.tsx`)

- Added `upgrade=true` URL parameter detection
- Uses `isAuthenticated` from AuthContext to determine redirect:
  - Authenticated users (upgrade flow) → `/admin/billing`
  - New registrations → `/admin/login`
- Added `queryClient.invalidateQueries` to refresh community data after payment

### 5. Cancel Page (`Cancel.tsx`)

- Simplified to redirect back to billing page
- Uses `isAuthenticated` to determine return destination:
  - Authenticated users → `/admin/billing`
  - Non-authenticated → `/pricing`
- Removed unused `communityId` parameter handling

## UI/UX Flow

1. User visits `/admin/billing`
2. Toggle between "Mensuel" and "Annuel" above plan cards
3. Prices update dynamically with savings shown for yearly
4. Click "Changer de plan" on desired plan
5. Dialog shows price with period toggle for final confirmation
6. "Payer et confirmer" redirects to Stripe Checkout
7. Success returns to billing page with updated plan
8. Cancel returns to billing to retry

## Data Flow

```
billingPeriod state
    ↓
Plan cards display appropriate priceMonthly or priceYearly
    ↓
Upgrade dialog inherits current billingPeriod
    ↓
upgradeCheckoutMutation sends period to backend
    ↓
Backend creates Stripe price_data with correct amount/interval
    ↓
User completes payment on Stripe
    ↓
Success page redirects to billing with refreshed data
```

## Files Modified

- `client/src/pages/admin/Billing.tsx` - Main billing page with toggle
- `client/src/pages/admin/billing/Success.tsx` - Upgrade-aware redirect
- `client/src/pages/admin/billing/Cancel.tsx` - Simplified cancel flow

## Test Scenarios

1. Toggle updates all plan card prices correctly
2. Yearly toggle shows savings percentage
3. Dialog inherits toggle state from main page
4. Dialog toggle updates displayed price
5. Stripe Checkout receives correct period/amount
6. Success page redirects correctly for upgrade vs registration
7. Cancel page returns to billing for authenticated users
