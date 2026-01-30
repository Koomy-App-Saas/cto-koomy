# P-FIN.1 — Rapport de Clôture Machine d'États Abonnement

**Date**: 2026-01-26  
**Statut**: IMPLÉMENTATION COMPLÈTE  
**Objectif**: Implémenter la machine d'états de gestion des abonnements SaaS  

## Résumé Exécutif

Implémentation d'une **couche d'adaptation P-FIN.1** sur l'infrastructure existante. Le module `server/lib/billing/` fournit un mapping des états existants vers les états contractuels, une machine d'états centralisée, et des fonctions de gating réutilisables. 54 tests unitaires valident le comportement.

## Livrables

### A. Contrat ✅
- **Fichier**: `docs/contracts/contract_p_fin_1_subscription_state_machine.md`
- **Contenu**: Documentation complète des deux machines d'états, transitions, événements, règles d'accès

### B. Modèle DB ✅
- **Enum subscriptionStatus**: `trialing`, `active`, `past_due`, `canceled`
- **Enum saasClientStatus**: `ACTIVE`, `IMPAYE_1`, `IMPAYE_2`, `SUSPENDU`, `RESILIE`
- **Champs communities**: `subscription_status`, `saas_client_status`, `stripe_customer_id`, `stripe_subscription_id`, `trial_ends_at`, `current_period_end`, `unpaid_since`, `suspended_at`, `terminated_at`
- **Table audit**: `subscription_status_audit` avec traçabilité complète

### C. Modules Guards ✅

**Module P-FIN.1 (NOUVEAU)** - `server/lib/billing/`:

| Fichier | Fonctions |
|---------|-----------|
| `subscriptionStateMachine.ts` | `computeNextStatus()`, `canWrite()`, `needsPaymentAction()`, `mapToCanonicalStatus()` |
| `assertCommunityCanWrite.ts` | `assertCommunityCanWrite()`, `checkCommunityCanWrite()`, `requireCanWrite()` middleware |
| `webhookEventMapper.ts` | `mapStripeEventToBillingEvent()`, `processStripeEvent()` |
| `index.ts` | Exports centralisés |

**États P-FIN.1** (mapping depuis DB):
| DB Status | SaaS Status | → P-FIN.1 Status |
|-----------|-------------|------------------|
| trialing | - | TRIAL_ACTIVE |
| trialing (expiré) | - | EXPIRED |
| active | - | ACTIVE |
| past_due | IMPAYE_1/2 | PAST_DUE |
| * | SUSPENDU | SUSPENDED |
| * | RESILIE | CANCELED |
| canceled | - | CANCELED |

**Modules existants** (déjà intégrés dans routes):
- **subscriptionGuards** (`server/lib/subscriptionGuards.ts`): `isMoneyAllowed()`, `checkSubscriptionForMoney()`
- **saasAccess** (`server/lib/saasAccess.ts`): `getSaasAccessInfo().isBlocked/isWarning`
- **Bypass**: WhiteLabel/GRAND_COMPTE contournent les guards

**Intégration progressive**: Le middleware `requireCanWrite()` peut remplacer progressivement `checkSubscriptionForMoney()` dans les routes critiques. L'infrastructure existante est déjà opérationnelle.

### D. Webhook Stripe ✅
- **Fichier**: `server/stripe.ts`
- **Handlers**:
  - `handleCheckoutCompleted` — Activation abonnement
  - `handleSubscriptionCreated/Updated/Deleted` — Sync état Stripe
  - `handlePaymentSucceeded` — Transition vers ACTIVE + reset timestamps
  - `handlePaymentFailed` — Transition vers IMPAYE_1 + unpaidSince
- **Audit trail**: Chaque transition logguée dans `subscription_status_audit`

### E. Endpoints ✅

**Endpoint P-FIN.1 (ENRICHI)** - `GET /api/billing/status`:
- **Fichier**: `server/routes.ts` (ligne 10824)
- **Backward-compatible**: Sans `communityId` = réponse legacy
- **Avec `?communityId=xxx`**: Retourne payload P-FIN.1 complet
- **Payload P-FIN.1**: `subscription_status`, `canWrite`, `needsPaymentAction`, `isInTrial`, `isBlocked`, `traceId`

**Endpoint existant** - `GET /api/communities/:communityId/subscription-state`:
- **Fichier**: `server/routes.ts` (ligne 5100)
- **Auth**: Firebase + membership check (admin/delegate)
- **Payload**: Via `getSubscriptionState()` (effectiveStateService.ts)

### F. Tests ✅

**Tests P-FIN.1 (NOUVEAU)** - `server/tests/p-fin-1-state-machine.test.ts`:
- **54 tests** validant le contrat P-FIN.1
  - State Machine Transitions (13 tests)
  - Access Control: canWrite, needsPaymentAction, isBlocked (18 tests)
  - State Mapping: mapToCanonicalStatus, mapToDBStatus (15 tests)
  - ProductError Generation (5 tests)
  - Billing Status Payload (3 tests)

**Tests existants** - `server/tests/subscription-state.test.ts`:
- 26+ tests sur `getSubscriptionState()` (payload effectif)

## Architecture Vérifiée

```
Stripe Webhooks
      │
      ▼
server/stripe.ts (handlers)
      │
      ├──► storage.updateCommunity() → subscriptionStatus
      │
      └──► storage.transitionSaasStatus() → saasClientStatus + audit
                    │
                    ▼
           subscription_status_audit (traçabilité)

Jobs Batch (scheduled)
      │
      ▼
Escalade automatique: IMPAYE_1 → IMPAYE_2 → SUSPENDU → RESILIE
```

## Fichiers Clés

| Fichier | Lignes | Responsabilité |
|---------|--------|----------------|
| `server/stripe.ts` | 1242 | Webhooks + handlers |
| `server/lib/subscriptionGuards.ts` | ~150 | Guards monétaires |
| `server/lib/saasAccess.ts` | 156 | Middleware accès SaaS |
| `server/lib/effectiveStateService.ts` | ~200 | État effectif combiné |
| `server/lib/planLimits.ts` | ~100 | Limites par plan |
| `server/services/saasStatusJob.ts` | 136 | Job escalade J+15/J+30/J+60 |
| `server/tests/subscription-state.test.ts` | 283 | Tests payload (26+ tests) |
| `shared/schema.ts` | ~3000 | Enums + tables |

## Conclusion

**Implémentation P-FIN.1 complète.** Le nouveau module `server/lib/billing/` fournit :
- Mapping bidirectionnel états DB ↔ états P-FIN.1
- Machine d'états `computeNextStatus()` conforme au contrat
- Fonctions de contrôle d'accès (`canWrite`, `needsPaymentAction`, `isBlocked`)
- Middleware `requireCanWrite()` pour gating centralisé
- Endpoint `/api/billing/status` enrichi (backward-compatible)
- 54 tests unitaires validant le contrat

L'approche d'adaptation préserve l'infrastructure existante tout en exposant une interface standardisée P-FIN.1.

## Checklist Finale

- [x] Contrat respecté à 100%
- [x] États stockés en DB (existant)
- [x] Webhook Stripe met à jour l'état (existant)
- [x] Gating WRITE centralisé (`assertCommunityCanWrite` + `checkSubscriptionForMoney` existant)
- [x] Endpoint billing/status actif (enrichi)
- [x] ProductError finance cohérentes
- [x] Tests verts (54/54)
- [x] Report présent
