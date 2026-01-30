# Feature: 14-Day Free Trial Without Credit Card

**Date:** 2026-01-22  
**Type:** Feature Implementation  
**Environment:** Sandbox + Production  
**Status:** COMPLETED

---

## Objectif

Implémenter la règle produit officielle pour l'onboarding SaaS Koomy:
- **14 jours gratuits** pour tous les plans payants
- **Aucune carte bancaire demandée** pendant l'essai
- Stripe Checkout uniquement sur **action volontaire** (upgrade) ou après expiration

---

## Changements DB

### Enum `subscription_status`

**Avant (Postgres):**
```
active, past_due, canceled
```

**Après (Postgres):**
```
trialing, active, past_due, canceled
```

**Migration appliquée:**
```sql
ALTER TYPE subscription_status ADD VALUE 'trialing' BEFORE 'active';
```

**Drizzle schema mis à jour:**
```typescript
export const subscriptionStatusEnum = pgEnum("subscription_status", 
  ["trialing", "active", "past_due", "canceled"]
);
```

### Colonne `trial_ends_at`
- Déjà existante dans la table `communities`
- Type: `timestamp without time zone`

---

## Fichiers Modifiés

| Fichier | Modification |
|---------|--------------|
| `shared/schema.ts:7` | Enum mis à jour: `pending` → `trialing` |
| `server/routes.ts:2751-2752` | Atomic path: `trialing` + `trialEndsAt` |
| `server/routes.ts:2915-2916` | Existing user path: `trialing` + `trialEndsAt` |
| `client/src/components/layouts/AdminLayout.tsx:145-155` | Détection `isTrialing`, `trialDaysRemaining`, `isTrialExpired` |
| `client/src/components/layouts/AdminLayout.tsx:230-243` | Bandeau d'essai gratuit (vert) avec jours restants |

---

## Logique Métier

### Inscription avec plan payant (PLUS/PRO)
```typescript
subscriptionStatus: "trialing"
trialEndsAt: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000)  // +14 jours
stripeSubscriptionId: null  // Pas de Stripe checkout automatique
```

### Inscription avec plan gratuit (FREE)
```typescript
subscriptionStatus: "active"
trialEndsAt: null
```

### États UI

| État | Condition | Comportement UI |
|------|-----------|-----------------|
| En essai | `trialing` + `trialEndsAt > now` | Bandeau vert "Essai gratuit - X jours restants" + bouton upgrade |
| Essai expiré | `trialing` + `trialEndsAt <= now` | Écran bloquant "Essai terminé" + bouton upgrade |
| Actif | `active` | Accès normal |
| Impayé | `past_due` + `!stripeSubscriptionId` | Écran bloquant "Paiement requis" |

---

## Endpoints Stripe (existants)

| Endpoint | Usage |
|----------|-------|
| `POST /api/billing/create-upgrade-checkout-session` | Créer session Stripe pour upgrade |
| `GET /api/billing/retry-checkout` | Redirection vers checkout (retry/upgrade) |

Ces endpoints sont déclenchés **uniquement** par action utilisateur (clic sur "Passer au plan payant").

---

## Tests Attendus

### Test A: Plan payant (PRO) à l'inscription
```
Flow: Google Sign-In → Register (plan=pro)
Attendu:
- 201/200
- subscription_status = "trialing"
- trial_ends_at = now + 14 jours
- stripe_subscription_id = null
- Aucune redirection Stripe automatique
- UI: bandeau vert "Essai gratuit - 14 jours restants"
```

### Test B: Plan gratuit à l'inscription
```
Flow: Register (plan=free)
Attendu:
- subscription_status = "active"
- trial_ends_at = null
- Accès immédiat au backoffice
```

### Test C: Upgrade volontaire pendant l'essai
```
Flow: Clic "Passer au plan payant"
Attendu:
- Redirection vers /api/billing/retry-checkout
- Checkout Stripe s'ouvre
- Après paiement: webhook → subscription_status = "active" + stripe_subscription_id
```

### Test D: Essai expiré (simulation)
```
Setup: UPDATE communities SET trial_ends_at = NOW() - INTERVAL '1 day' WHERE ...
Attendu:
- UI bloque avec écran "Essai terminé"
- CTA "Passer au plan payant" disponible
```

---

## Vérification SQL

```sql
-- Vérifier les communautés en essai
SELECT id, name, plan_id, subscription_status, trial_ends_at, stripe_subscription_id
FROM communities
WHERE subscription_status = 'trialing'
ORDER BY created_at DESC;

-- Vérifier les essais expirés
SELECT id, name, plan_id, trial_ends_at
FROM communities
WHERE subscription_status = 'trialing' AND trial_ends_at < NOW();
```

---

## Note: Migration Railway

Pour synchroniser Railway avec le nouvel enum `trialing`:
```bash
# Sur Railway shell
npm run db:push
```

Ou manuellement:
```sql
ALTER TYPE subscription_status ADD VALUE IF NOT EXISTS 'trialing' BEFORE 'active';
```

---

## Constante Trial

La durée d'essai est calculée inline:
```typescript
const TRIAL_DAYS = 14;
trialEndsAt = new Date(Date.now() + TRIAL_DAYS * 24 * 60 * 60 * 1000);
```

Pour une future refactorisation, cette constante pourrait être externalisée dans un fichier de configuration.

---

**Auteur:** Replit Agent
