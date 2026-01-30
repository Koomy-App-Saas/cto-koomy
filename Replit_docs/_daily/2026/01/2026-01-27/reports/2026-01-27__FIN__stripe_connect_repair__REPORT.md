# P-FIN.6 Stripe Connect Club - Rapport d'Implementation

## Resume

Implementation du statut normalise Stripe Connect pour les clubs dans le Back Office avec migration DB, endpoints API, helper de garde, et mise a jour UI.

## Cause Racine (Lien Casse)

Le lien existant fonctionnait mais les endpoints utilisaient une logique de statut non normalisee (connected/chargesEnabled/payoutsEnabled). La nouvelle implementation ajoute un statut semantique `connectStatus` avec 6 valeurs possibles.

## Endpoints Implementes

| Endpoint | Methode | Description |
|----------|---------|-------------|
| `/api/billing/stripe-connect/onboarding-link` | POST | Cree un lien d'onboarding Stripe Connect |
| `/api/billing/stripe-connect/status` | GET | Retourne le statut normalise |
| `/api/connect/status` | GET | Endpoint legacy mis a jour avec connectStatus |
| `/api/connect/account-link` | POST | Endpoint legacy pour recreer un lien |

## Migration DB

### Enum Cree
```sql
CREATE TYPE stripe_connect_status AS ENUM (
  'NOT_CONNECTED',
  'ONBOARDING_REQUIRED', 
  'PENDING_REVIEW',
  'RESTRICTED',
  'ACTIVE',
  'DISCONNECTED'
);
```

### Colonnes Ajoutees sur `communities`
```sql
ALTER TABLE communities 
  ADD COLUMN stripe_connect_status stripe_connect_status DEFAULT 'NOT_CONNECTED',
  ADD COLUMN stripe_connect_charges_enabled boolean DEFAULT false,
  ADD COLUMN stripe_connect_payouts_enabled boolean DEFAULT false,
  ADD COLUMN stripe_connect_details_submitted boolean DEFAULT false,
  ADD COLUMN stripe_connect_last_sync_at timestamp;
```

## Fichiers Modifies

| Fichier | Changement |
|---------|------------|
| `shared/schema.ts` | Ajout enum + colonnes communities |
| `server/stripeConnect.ts` | normalizeConnectStatus, syncConnectStatus, assertStripeConnectActive, getConnectStatusForCommunity |
| `server/routes.ts` | Nouveaux endpoints billing/stripe-connect |
| `client/src/pages/admin/Finances.tsx` | Affichage statut normalise |
| `client/src/pages/admin/ConnectReturn.tsx` | UI pour tous les 6 statuts |

## Guard Helper

```typescript
assertStripeConnectActive(communityId)
// - Utilise cache DB si < 5 minutes
// - Sync Stripe si cache stale
// - Fallback sur cache si Stripe indisponible
// - Throw ConnectRequiredError si status != ACTIVE
```

Logs:
- `[CONNECT] guard_blocked` si bloque
- `[CONNECT] guard_fallback` si Stripe indisponible mais cache ACTIVE

## Flow Onboarding

1. Admin clique "Configurer" dans Finances
2. POST `/api/billing/stripe-connect/onboarding-link`
3. Redirect vers Stripe Express onboarding
4. Retour sur `/payments/connect/success`
5. GET status avec auto-refresh
6. Badge et message adaptes au statut

## Mapping Statuts

| connectStatus | Couleur Badge | Action |
|--------------|---------------|--------|
| NOT_CONNECTED | Gris | Configurer |
| ONBOARDING_REQUIRED | Orange | Continuer configuration |
| PENDING_REVIEW | Jaune | Attendre verification |
| RESTRICTED | Rouge | Corriger informations |
| ACTIVE | Vert | Gerer |
| DISCONNECTED | Gris | Reconfigurer |

## Test Sandbox

Pour tester:
1. Connecter un compte admin au Back Office sandbox
2. Aller dans Finances
3. Cliquer "Configurer" Stripe Connect
4. Completer l'onboarding Stripe test
5. Verifier les logs `[CONNECT] onboarding_link_created` et `[CONNECT] status_sync`

FIN
