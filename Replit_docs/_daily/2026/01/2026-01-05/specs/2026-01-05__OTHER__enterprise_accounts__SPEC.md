# Enterprise Accounts (Grand Compte)

## Overview

Koomy supports two types of community accounts:

1. **STANDARD** - Self-service communities using public plans (Gratuit, Essentiel, Pro)
2. **GRAND_COMPTE** - Enterprise clients with custom contracts

## Account Type Differences

### STANDARD Accounts
- Use public self-service plans (Gratuit, Essentiel, Pro, etc.)
- Member limits based on plan's `maxMembers`
- Feature access based on plan's capabilities
- Billing via Stripe self-service subscriptions
- Plan visible publicly on pricing page

### GRAND_COMPTE Accounts
- Custom contracts negotiated with Koomy
- Member limits based on `contractMemberLimit` field
- **Full access to ALL features** regardless of assigned plan
- Billing via manual invoicing (billingMode: manual_contract)
- Plan displayed as "Grand Compte" in UI (not public plan name)

## Database Schema

```sql
-- New fields in communities table
account_type: 'STANDARD' | 'GRAND_COMPTE'
distribution_channels: JSONB { whiteLabelApp, koomyWallet }
contract_member_limit: integer
contract_member_alert_threshold: integer (default 90%)
```

## Distribution Channels

For GRAND_COMPTE accounts, `distributionChannels` tracks how members access the community:

- **whiteLabelApp**: Dedicated white-label app (e.g., "UNSA Lidl" app)
- **koomyWallet**: Membership card visible in the Koomy Wallet app

Example configuration:
```json
{
  "whiteLabelApp": true,
  "koomyWallet": false
}
```

## Member Limit Logic

```typescript
// For GRAND_COMPTE: use contractMemberLimit
// For STANDARD: use plan.maxMembers

const max = isGrandCompte && community.contractMemberLimit 
  ? community.contractMemberLimit 
  : plan.maxMembers;
```

## Feature Access Logic

GRAND_COMPTE accounts bypass plan capability checks:

```typescript
// Example: feature capability check
if (community.accountType === "GRAND_COMPTE") {
  return true; // Full access to all features
}
// Then check plan capabilities...
```

## Alert Thresholds

For GRAND_COMPTE accounts, alerts are triggered when:
- **90% threshold** (default): "Approaching contract limit"
- **100% threshold**: "Contract limit reached - contact Koomy to extend"

The threshold is configurable via `contractMemberAlertThreshold`.

## UI Display

In back-office and platform dashboards:
- Show "Grand Compte" instead of plan name
- Show "Contrat personnalisé" for billing info
- Display contract member limit (not plan limit)
- Add visual indicator (purple badge "GC")

## Example: UNSA Lidl Configuration

```sql
UPDATE communities SET
  account_type = 'GRAND_COMPTE',
  white_label = true,
  distribution_channels = '{"whiteLabelApp": true, "koomyWallet": false}',
  contract_member_limit = 2000,
  contract_member_alert_threshold = 90,
  full_access_granted_at = NOW(),
  full_access_reason = 'Contrat Grand Compte White Label'
WHERE name = 'UNSA Lidl';
```

## API Endpoints

### Get Community Quota
```
GET /api/communities/:id/quota
```

Response includes:
```json
{
  "canAdd": true,
  "current": 156,
  "max": 2000,
  "planName": "Grand Compte",
  "hasFullAccess": true,
  "isGrandCompte": true,
  "alertThreshold": 90
}
```

## Migration Checklist

When converting a STANDARD account to GRAND_COMPTE:

1. Set `accountType = 'GRAND_COMPTE'`
2. Set `contractMemberLimit` based on contract
3. Set `fullAccessGrantedAt = NOW()` for full feature access
4. Configure `distributionChannels` if applicable
5. Set `billingMode = 'manual_contract'`
6. Add `internalNotes` with contract details
