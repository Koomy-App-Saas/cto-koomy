# Rapport P0.1 — STRIPE & LIFECYCLE DE SOUSCRIPTION (Enforcement)

**Date**: 23 janvier 2026  
**Version**: 1.0  
**Statut**: ✅ Implémenté

---

## 1. Résumé Exécutif

Ce rapport documente l'implémentation du guard serveur-side `requireBillingInGoodStanding` qui empêche les communautés Standard d'effectuer des opérations premium lorsque leur `subscriptionStatus` est `past_due` ou `canceled`.

### Résultats Clés

| Critère | Statut |
|---------|--------|
| Guard unique créé | ✅ |
| 4+ endpoints protégés | ✅ (4 endpoints) |
| Billing endpoints accessibles | ✅ |
| Aucune régression WL | ✅ |
| Logs de transitions | ✅ |
| Tests contractuels | ✅ |

---

## 2. Cartographie (Réalité du Code)

### 2.1 Localisation des Données

| Élément | Emplacement | Description |
|---------|-------------|-------------|
| `subscriptionStatus` | `communities.subscription_status` | Enum: trialing, active, past_due, canceled |
| `trialEndsAt` | `communities.trial_ends_at` | Timestamp fin de période d'essai |
| `stripeCustomerId` | `communities.stripe_customer_id` | ID client Stripe |
| `stripeSubscriptionId` | `communities.stripe_subscription_id` | ID abonnement Stripe |
| `planId` | `communities.plan_id` | Plan souscrit (free, plus, pro, enterprise) |

### 2.2 Endpoints Billing Existants

| Endpoint | Méthode | Rôle | Fichier:Ligne |
|----------|---------|------|---------------|
| `/api/billing/status` | GET | Vérifie config Stripe | routes.ts:9902 |
| `/api/billing/checkout` | POST | Crée session checkout | routes.ts:9917 |
| `/api/billing/portal` | POST | Crée session portail client | routes.ts:9951 |
| `/api/billing/registration-status` | GET | Statut inscription | routes.ts:9988 |
| `/api/billing/verify-checkout-session` | GET | Vérifie paiement | routes.ts:10027 |
| `/api/billing/create-upgrade-checkout-session` | POST | Upgrade payant | routes.ts:10100 |

### 2.3 Distinction Standard vs WL vs SaaS Owner

| Mode | Détermination | Guard Billing |
|------|---------------|---------------|
| Standard | `community.whiteLabel = false` | ✅ Appliqué |
| White-Label | `community.whiteLabel = true` | ⛔ Bypass |
| SaaS Owner | Route dédiée + hostname | ⛔ Hors scope |

---

## 3. Implémentation (Guard + Branchements)

### 3.1 Guard Créé

**Fichier**: `server/lib/subscriptionGuards.ts`  
**Fonction**: `requireBillingInGoodStanding(getCommunityId, options?)`

#### Comportement

```
Input: communityId (via fonction extracteur)
├── Si WL → bypass (next)
├── Si trialing/active → autorisé (next)
├── Si past_due → 402 + BILLING_PAST_DUE
└── Si canceled → 402 + BILLING_CANCELED
```

#### Réponse d'Erreur (HTTP 402)

```json
{
  "code": "BILLING_PAST_DUE",
  "message": "Votre période d'essai est terminée. Activez votre abonnement pour continuer à utiliser les fonctionnalités premium.",
  "subscription_status": "past_due",
  "traceId": "billing-1706012345678"
}
```

```json
{
  "code": "BILLING_CANCELED",
  "message": "Votre abonnement est annulé. Réactivez votre abonnement pour accéder aux fonctionnalités premium.",
  "subscription_status": "canceled",
  "traceId": "billing-1706012345678"
}
```

### 3.2 Endpoints Protégés (4)

| # | Endpoint | Méthode | Fichier:Ligne | Extracteur communityId |
|---|----------|---------|---------------|------------------------|
| 1 | `/api/events` | POST | routes.ts:6977 | `req.body?.communityId` |
| 2 | `/api/news` | POST | routes.ts:6482 | `req.body?.communityId` (allowMissing=true) |
| 3 | `/api/communities/:communityId/news` | POST | routes.ts:6812 | `req.params.communityId` |
| 4 | `/api/collections` | POST | routes.ts:9680 | `req.body?.communityId` |

### 3.3 Endpoints NON Bloqués (Exception)

Les endpoints billing restent accessibles même en `past_due` / `canceled` :

- `GET /api/billing/status`
- `POST /api/billing/checkout`
- `POST /api/billing/portal`
- Tous les endpoints `/api/billing/*`

---

## 4. Trial Expiration

### 4.1 Mécanisme Existant

**Fichier**: `server/lib/subscriptionGuards.ts`  
**Fonction**: `checkAndUpdateTrialExpiry(communityId)`

Le système vérifie à chaque appel du guard si le trial est expiré et bascule automatiquement vers `past_due`.

#### Logique

```typescript
if (
  community.subscriptionStatus === "trialing" &&
  community.trialEndsAt &&
  new Date() > community.trialEndsAt
) {
  // Transition: trialing → past_due
  await db.update(communities).set({ subscriptionStatus: "past_due" });
}
```

### 4.2 Champs Utilisés

| Champ | Existant | Description |
|-------|----------|-------------|
| `trial_ends_at` | ✅ Oui | Timestamp de fin de trial (14 jours après création) |
| `trial_started_at` | ⛔ Non | Calculé implicitement via `createdAt` |

**Note**: Le champ `trial_ends_at` est défini à la création de communauté payante comme `Date.now() + 14 jours`.

---

## 5. Logs & Observabilité

### 5.1 Fonction de Log

**Fichier**: `server/lib/subscriptionGuards.ts`  
**Fonction**: `logSubscriptionTransition(communityId, fromStatus, toStatus, source, traceId?)`

#### Format du Log

```json
{
  "event": "subscription_status_transition",
  "communityId": "abc123",
  "from_status": "trialing",
  "to_status": "past_due",
  "source": "trial_job",
  "timestamp": "2026-01-23T10:30:00.000Z",
  "traceId": "transition-1706012345678"
}
```

### 5.2 Points d'Émission

| Source | Transition | Fichier:Ligne |
|--------|------------|---------------|
| `trial_job` | trialing → past_due | subscriptionGuards.ts:76 |
| `stripe_webhook` | * → active (checkout) | stripe.ts:739 |
| `stripe_webhook` | * → active (payment) | stripe.ts:897 |

---

## 6. Tests

### 6.1 Tests Unitaires

**Fichier**: `server/tests/billing-enforcement.test.ts`

```bash
# Exécuter avec Vitest
npx vitest run server/tests/billing-enforcement.test.ts
```

### 6.2 Smoke Test

```bash
# Exécuter le smoke test
npx tsx server/tests/billing-enforcement.test.ts --smoke
```

### 6.3 Scénarios Couverts

| # | Scénario | Résultat Attendu |
|---|----------|------------------|
| 1 | `past_due` appelle `/api/events` POST | 402 + BILLING_PAST_DUE |
| 2 | `canceled` appelle `/api/events` POST | 402 + BILLING_CANCELED |
| 3 | `past_due` appelle `/api/billing/checkout` | 200 (pas bloqué) |
| 4 | `trialing` appelle `/api/events` POST | 200 (autorisé) |
| 5 | `active` appelle `/api/events` POST | 200 (autorisé) |
| 6 | WL avec `past_due` appelle endpoint | Bypass (autorisé) |

---

## 7. Différences entre Prompt et Code Réel

| Élément Prompt | Réalité Code | Correction |
|----------------|--------------|------------|
| `trial_started_at` | N'existe pas | Utilisation de `trialEndsAt` uniquement |
| HTTP 402 vs 403 | Guard existant utilisait 403 | Nouveau guard utilise 402 |
| Endpoint activation Stripe Connect | Déjà protégé par `requireActiveSubscriptionForMoney` | Non dupliqué |
| Job cron trial expiration | Vérification à la demande via guard | Confirmé existant |

---

## 8. Risques & Suites Recommandées

### 8.1 Risques Identifiés

| Risque | Probabilité | Impact | Mitigation |
|--------|-------------|--------|------------|
| Race condition sur trial expiry | Faible | Faible | Check idempotent |
| Endpoints non protégés restants | Moyen | Moyen | P1: étendre la couverture |

### 8.2 Suites Recommandées (P1)

1. **Étendre la protection** aux endpoints de mise à jour (PATCH /api/events/:id, etc.)
2. **Limites d'usage** - implémenter les quotas par plan (nombre d'événements, etc.)
3. **Dashboard admin** - afficher le statut billing dans l'interface
4. **Alertes** - notifier les admins avant expiration du trial

---

## 9. Fichiers Modifiés

| Fichier | Type de Modification |
|---------|---------------------|
| `server/lib/subscriptionGuards.ts` | Ajout guard + logs |
| `server/routes.ts` | Import + branchement 4 endpoints |
| `server/stripe.ts` | Import + logs transitions |
| `server/tests/billing-enforcement.test.ts` | Nouveau fichier tests |

---

## 10. Conclusion

L'implémentation P0.1 est complète et opérationnelle. Le guard `requireBillingInGoodStanding` protège 4 endpoints critiques de création de contenu, tout en préservant l'accès aux endpoints de régularisation (billing). Les communautés White-Label sont correctement exemptées.
