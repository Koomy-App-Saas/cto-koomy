# P-FIN.1 — Contrat Machine d'États Abonnement

**Version**: 1.0  
**Date**: 2026-01-26  
**Statut**: ACTIF  

## 1. Vue d'ensemble

Ce contrat définit la machine d'états gérant les abonnements SaaS de KOOMY. Le système utilise **deux machines d'états complémentaires** :

1. **subscriptionStatus** — État synchronisé avec Stripe (source: webhooks)
2. **saasClientStatus** — État métier SaaS avec escalade automatique (source: jobs + webhooks)

## 2. Machine d'États #1 : subscriptionStatus (Stripe)

### 2.1 États

| État | Code DB | Description |
|------|---------|-------------|
| TRIALING | `trialing` | Période d'essai active |
| ACTIVE | `active` | Abonnement payé et actif |
| PAST_DUE | `past_due` | Paiement échoué, grâce en cours |
| CANCELED | `canceled` | Abonnement annulé |

### 2.2 Transitions

```
                    ┌──────────────┐
                    │   TRIALING   │
                    └──────┬───────┘
                           │ payment_succeeded
                           │ trial_expired (→past_due)
                           ▼
┌────────────────┐  payment_succeeded  ┌──────────────┐
│   PAST_DUE     │◄────────────────────│    ACTIVE    │
└───────┬────────┘                     └──────────────┘
        │ payment_failed                      ▲
        │ subscription_deleted (→canceled)    │
        ▼                                     │
┌────────────────┐  payment_succeeded         │
│    CANCELED    │────────────────────────────┘
└────────────────┘
```

### 2.3 Événements Stripe

| Événement Stripe | Transition |
|------------------|------------|
| `checkout.session.completed` | → ACTIVE |
| `customer.subscription.created` | → ACTIVE ou TRIALING |
| `customer.subscription.updated` | Mise à jour période |
| `customer.subscription.deleted` | → CANCELED |
| `invoice.payment_succeeded` | → ACTIVE |
| `invoice.payment_failed` | → PAST_DUE |

## 3. Machine d'États #2 : saasClientStatus (Métier)

### 3.1 États

| État | Code DB | Jour J+ | Description |
|------|---------|---------|-------------|
| ACTIVE | `ACTIVE` | - | Abonnement en règle |
| IMPAYE_1 | `IMPAYE_1` | J+0 à J+15 | Premier impayé, relance |
| IMPAYE_2 | `IMPAYE_2` | J+15 à J+30 | Deuxième relance |
| SUSPENDU | `SUSPENDU` | J+30 à J+60 | Accès restreint |
| RESILIE | `RESILIE` | J+60+ | Accès terminé, purge planifiée |

### 3.2 Transitions

```
┌──────────────┐
│    ACTIVE    │
└──────┬───────┘
       │ payment_failed
       ▼
┌──────────────┐  J+15
│   IMPAYE_1   │───────────► IMPAYE_2
└──────────────┘                │
       ▲                        │ J+30
       │ payment_succeeded      ▼
       │              ┌──────────────┐
       ├──────────────│   SUSPENDU   │
       │              └──────┬───────┘
       │                     │ J+60
       │ payment_succeeded   ▼
       │              ┌──────────────┐
       └──────────────│   RESILIE    │
                      └──────────────┘
                             │
                             ▼ J+90
                        [PURGE DATA]
```

### 3.3 Événements Métier

| Événement | Source | Transition |
|-----------|--------|------------|
| `PAYMENT_SUCCEEDED` | Webhook | → ACTIVE (depuis tout état) |
| `PAYMENT_FAILED` | Webhook | ACTIVE → IMPAYE_1 |
| `GRACE_PERIOD_ELAPSED` | Job | IMPAYE_1 → IMPAYE_2 |
| `SUSPENSION_TRIGGERED` | Job | IMPAYE_2 → SUSPENDU |
| `TERMINATION_TRIGGERED` | Job | SUSPENDU → RESILIE |
| `ADMIN_REACTIVATION` | Admin | → ACTIVE |
| `MANUAL_CANCELLATION` | Admin | → RESILIE |

## 4. Règles d'Accès

### 4.1 Matrice d'Accès par État

| Fonctionnalité | ACTIVE | TRIALING | PAST_DUE | IMPAYE_1/2 | SUSPENDU | RESILIE |
|----------------|--------|----------|----------|------------|----------|---------|
| Lecture données | ✅ | ✅ | ✅ | ✅ | ⚠️ Limité | ❌ |
| Écriture données | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| Paiements (dues) | ✅ | ❌ | ❌ | ⚠️ | ❌ | ❌ |
| Export données | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Nouveau membre | ✅ | ⚠️ Limite | ⚠️ Limite | ⚠️ Limite | ❌ | ❌ |

### 4.2 Guards Backend

```typescript
// server/lib/subscriptionGuards.ts
isMoneyAllowed(status) // true si ACTIVE uniquement

// server/lib/saasAccess.ts
getSaasAccessInfo(community).isBlocked // true si SUSPENDU ou RESILIE
getSaasAccessInfo(community).isWarning // true si IMPAYE_1 ou IMPAYE_2
```

### 4.3 Middleware d'Accès

```typescript
// server/lib/saasAccess.ts - createSaasAccessMiddleware()
// Endpoints read-only export: TOUJOURS autorisés (RGPD compliance)
// Autres endpoints: Bloqués si isBlocked === true (403)
```

### 4.4 Bypass Enterprise/WhiteLabel

Les communautés avec `whiteLabel: true` ou `accountType: GRAND_COMPTE` bypassent les guards de subscription.

**Note sur les limites WhiteLabel**: L'objet `limits` est toujours retourné, mais avec `max: null` (illimité) pour les champs membres/admins.

## 5. Source de Vérité

### 5.1 Hiérarchie

1. **Stripe** = Source des événements de paiement
2. **DB PostgreSQL** = Source de l'état courant
3. **Backend** = Autorité finale sur les décisions d'accès

### 5.2 Champs DB (table `communities`)

| Champ | Type | Description |
|-------|------|-------------|
| `subscription_status` | enum | État Stripe (trialing/active/past_due/canceled) |
| `saas_client_status` | enum | État SaaS (ACTIVE/IMPAYE_1/IMPAYE_2/SUSPENDU/RESILIE) |
| `billing_status` | enum | Alias legacy (trialing/active/past_due/canceled/unpaid) |
| `stripe_customer_id` | text | ID client Stripe |
| `stripe_subscription_id` | text | ID abonnement Stripe |
| `trial_ends_at` | timestamp | Fin de période d'essai |
| `current_period_end` | timestamp | Fin de période de facturation |
| `unpaid_since` | timestamp | Début de l'impayé (pour calcul J+X) |
| `suspended_at` | timestamp | Date de suspension |
| `terminated_at` | timestamp | Date de résiliation |
| `purge_scheduled_at` | timestamp | Date de purge planifiée |

### 5.3 Table d'Audit

```sql
subscription_status_audit (
  id, community_id, previous_status, new_status,
  transition_reason, triggered_by, stripe_event_id, stripe_invoice_id,
  metadata, created_at
)
```

## 6. Codes Erreur (ProductError)

| Code | HTTP | Description |
|------|------|-------------|
| `SUBSCRIPTION_NOT_ACTIVE` | 402 | Abonnement non actif pour opération payante |
| `SUBSCRIPTION_PAST_DUE` | 402 | Paiement en retard |
| `SUBSCRIPTION_SUSPENDED` | 403 | Compte suspendu |
| `SUBSCRIPTION_TERMINATED` | 403 | Compte résilié |
| `TRIAL_EXPIRED` | 402 | Période d'essai expirée |
| `PLAN_LIMIT_EXCEEDED` | 403 | Limite du plan atteinte |

## 7. Fichiers d'Implémentation

| Fichier | Responsabilité |
|---------|----------------|
| `server/stripe.ts` | Handlers webhook Stripe |
| `server/lib/subscriptionGuards.ts` | Guards monétaires (isMoneyAllowed) |
| `server/lib/saasAccess.ts` | Middleware accès SaaS (isBlocked/isWarning) |
| `server/lib/effectiveStateService.ts` | État effectif combiné (getSubscriptionState) |
| `server/lib/planLimits.ts` | Limites par plan |
| `server/services/saasStatusJob.ts` | Job escalade J+15/J+30/J+60 |
| `server/services/saasEmailService.ts` | Notifications email |
| `server/services/purgeService.ts` | Gestion purge données (J+90) |

## 8. Tests

| Fichier | Couverture |
|---------|------------|
| `server/tests/subscription-state.test.ts` | Payload getSubscriptionState (26+ tests) |
| `server/tests/usage-limits.test.ts` | Limites et quotas |
| `server/tests/purge-service.test.ts` | Service de purge |

**Note**: Les tests couvrent principalement le payload exposé par l'API. Les transitions webhook et l'escalade job ne sont pas entièrement testés unitairement - ils sont validés en intégration.

## 9. Changelog

| Date | Version | Changement |
|------|---------|------------|
| 2026-01-26 | 1.0 | Création du contrat (documentation de l'existant) |
