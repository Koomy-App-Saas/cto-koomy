# REPORT: Canonical Register Firebase Auth Creates Community Trial 14d

**Date:** 2026-01-22  
**Status:** Implementation complete

---

## Résumé du changement

Implémentation du chemin canonique pour l'inscription admin via Firebase Auth avec création atomique de la communauté et essai gratuit 14 jours.

### Fonctionnalités implémentées

1. **Authentification Firebase obligatoire**: Token Firebase vérifié côté backend (AUTH_REQUIRED si absent)
2. **Transaction atomique**: user + community + membership créés en une seule transaction DB
3. **Trial 14 jours sans CB**: Plans payants (PLUS/PRO) → `subscriptionStatus=trialing`, `trialEndsAt=now+14j`
4. **Aucun appel Stripe** à l'inscription
5. **Logs CANONICAL_*** pour traçabilité

---

## Logs CANONICAL_*

Les logs structurés suivent le format demandé:

| Log | Moment | Payload |
|-----|--------|---------|
| `CANONICAL_ATTEMPT` | Avant transaction (routes.ts) | `{ planId, communityName, firebaseUid }` |
| `CANONICAL_START` | Début transaction (storage.ts) | `{ planId, communityName }` |
| `CANONICAL_STEP1 user_created` | Après INSERT user | `{ userId }` |
| `CANONICAL_STEP2 community_created` | Après INSERT community | `{ communityId, name }` |
| `CANONICAL_STEP3 owner_linked` | Après INSERT membership | `{ membershipId, userId, communityId }` |
| `CANONICAL_STEP4 subscription_set` | Après set subscription | `{ subscriptionStatus, trialEndsAt }` |
| `CANONICAL_SUCCESS` | Fin transaction OK | `{ userId, communityId, membershipId }` |
| `CANONICAL_FAILED` | Erreur transaction | `{ pgCode, message, constraint }` |

---

## Fichiers modifiés

| Fichier | Changement |
|---------|------------|
| `server/storage.ts` | Logs CANONICAL_* dans `registerAdminWithCommunityAtomic()` |
| `server/routes.ts` | Logs CANONICAL_FAILED, suppression logs ATOMIC_ redondants |

---

## Comportement API

### POST /api/admin/register

**Headers requis:**
- `Authorization: Bearer <firebase_id_token>`

**Body (champs principaux):**
```json
{
  "communityName": "Mon Club",
  "communityType": "association",
  "planId": "pro"  // free | plus | pro
}
```

**Réponses:**

| Status | Code | Condition |
|--------|------|-----------|
| 200/201 | - | Inscription réussie |
| 401 | AUTH_REQUIRED | Token Firebase absent/invalide |
| 400 | MISSING_FIELDS | Champs obligatoires manquants |
| 400 | EMAIL_TAKEN | Email déjà utilisé (mobile account sans Firebase match) |
| 409 | EMAIL_ALREADY_LINKED | Email lié à un autre Firebase UID |
| 409 | ALREADY_REGISTERED | User existe déjà avec un club (1 admin = 1 club) |

---

## Trial 14 jours

**Logique appliquée dans `routes.ts`:**
```typescript
planId: planId,
subscriptionStatus: isPaidPlan ? "trialing" : "active",
trialEndsAt: isPaidPlan ? new Date(Date.now() + 14 * 24 * 60 * 60 * 1000) : null,
```

**Constante implicite:** `TRIAL_DAYS = 14`

**Aucun appel Stripe:** Les champs `stripeCustomerId` et `stripeSubscriptionId` restent `NULL`.

---

## Test scenarios (à exécuter en Sandbox)

### Test 1 — Canonique provider `firebase:google`

1. Fenêtre privée, compte Google jamais utilisé sur sandbox
2. Naviguer vers `sitepublic-sandbox.koomy.app/register?plan=pro`
3. Auth via Firebase (bouton "Continuer avec Google")
4. Saisir `communityName = "Tennis Club Canonical"`
5. Submit

**Attendus:**
- API 200/201
- Logs Railway: `CANONICAL_SUCCESS`
- DB: 1 user, 1 community, 1 membership (OWNER)
- `subscription_status = 'trialing'`
- `trial_ends_at = now + 14 jours`
- Stripe fields = NULL

### Test 2 — Canonique provider `firebase:password`

1. Fenêtre privée, nouvel email jamais utilisé
2. Même URL, auth via email/password Firebase
3. `communityName = "Club Email Canonical"`
4. Submit

**Attendus:** Identiques à Test 1

### Test 3 — Anti-régression: pas de Stripe

- Confirmer aucun endpoint Stripe appelé pendant inscription
- Confirmer aucune redirection checkout
- Confirmer aucun customer/subscription Stripe créé

---

## Preuve "aucun Stripe"

Le handler `/api/admin/register` ne contient aucun appel aux fonctions Stripe:
- Pas de `stripe.customers.create()`
- Pas de `stripe.checkout.sessions.create()`
- Pas de redirection vers Stripe Checkout

La création Stripe se fait uniquement:
- À la fin du trial (upgrade forcé)
- Via `/api/billing/create-upgrade-checkout-session` (upgrade explicite)

---

## Invariants vérifiés

- **I1**: Firebase UID → single DB user (via `firebase_uid` column)
- **I2**: Email normalisé lowercase
- **R1**: Atomic user+community+membership creation
- **S1**: Plans payants → `subscriptionStatus = 'trialing'`
- **S2**: Trial sans CB, sans Stripe à l'inscription
