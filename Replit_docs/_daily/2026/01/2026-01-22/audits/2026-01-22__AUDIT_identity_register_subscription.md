# AUDIT COMPLET — Identity, Register & Subscription

**Date:** 2026-01-22  
**Auteur:** CTO (assistant)  
**Projet:** KOOMY  
**Environnement analysé:** Sandbox + Production (code review)  
**Version:** v1.0.0

---

## 1. Objectif du document

Ce document est une **remise à plat structurante** après une série d'implémentations. Il reconstitue la vérité actuelle du système et établit des invariants explicites servant de référence obligatoire.

**Périmètre:**
- Authentification (Firebase + Legacy)
- Onboarding admin (register)
- Création de communautés
- Souscription SaaS et billing

---

## 2. Architecture du Système

### 2.1 Surfaces applicatives

| Surface | Auth Mode | Description |
|---------|-----------|-------------|
| Site public | Aucun | Pages marketing, onboarding |
| Backoffice admin | Firebase (Google Sign-In) | Gestion communauté |
| App membre | Firebase (Google Sign-In) | App mobile membres |
| App admin communauté | Firebase (Google Sign-In) | App mobile admin club |
| SaaS Owner | Legacy (email/password) | Plateforme d'administration |

### 2.2 Tables d'identité

#### Table `users` (Admins backoffice + Platform admins)
```
users {
  id: varchar(50) PK
  firstName: text NOT NULL
  lastName: text NOT NULL
  email: text NOT NULL UNIQUE
  password: text NULLABLE          # NULL pour Firebase-only
  phone: text
  avatar: text
  globalRole: enum                 # null=community admin, platform_super_admin=platform
  isPlatformOwner: boolean         # true = root admin non supprimable
  isActive: boolean                # false jusqu'à vérification email (platform)
  emailVerifiedAt: timestamp
  failedLoginAttempts: integer
  lockedUntil: timestamp
  firebaseUid: text UNIQUE         # Lien Firebase Auth
  createdAt: timestamp
}
```

#### Table `accounts` (Utilisateurs mobile/membres)
```
accounts {
  id: varchar(50) PK
  email: text NOT NULL UNIQUE
  passwordHash: text NOT NULL      # Requis même pour Firebase
  firstName: text
  lastName: text
  avatar: text
  authProvider: text               # "email" | "google" | "firebase"
  providerId: text                 # Firebase UID si auth_provider='firebase'
  createdAt: timestamp
  updatedAt: timestamp
}
```

### 2.3 Séparation des responsabilités

| Table | Usage | Auth Provider |
|-------|-------|---------------|
| `users` | Admins backoffice + Platform admins | Firebase (backoffice) / Legacy (platform) |
| `accounts` | Membres mobile | Firebase ou email/password |

**Règle clé:** Un même Firebase UID peut avoir une entrée dans `users` ET `accounts` (admin + membre du même club).

---

## 3. Système d'Authentification

### 3.1 Firebase Auth (Backoffice + Mobile)

**Fichiers clés:**
- `server/lib/firebaseAdmin.ts` — Initialisation Firebase Admin SDK
- `server/middlewares/requireFirebaseAuth.ts` — Middleware auth obligatoire
- `server/middlewares/attachAuthContext.ts` — Liaison Firebase → Koomy DB

**Flow d'authentification:**
```
1. Client → Google Sign-In → Firebase ID Token
2. Client → API avec Bearer Token
3. Middleware verifyFirebaseToken(token)
4. Lookup: accounts.providerId = firebase.uid OU users.firebaseUid = firebase.uid
5. Si trouvé → Attacher authContext
6. Si non trouvé → Créer via /api/admin/register
```

**Backfill automatique (sandbox uniquement):**
- Si `accounts.email` correspond mais `providerId` est NULL
- Backfill `providerId` et `authProvider='firebase'`
- Contrôlé par `KOOMY_AUTH_BACKFILL_EMAIL=true`

### 3.2 Legacy Auth (SaaS Owner/Platform)

**Endpoint:** `POST /api/platform/login`

**Sécurité renforcée:**
- IP Whitelist: France uniquement (`countryCode === 'FR'`)
- Rate limiting: lockout après N échecs
- Session: 2 heures, single active session
- Email verification obligatoire
- Audit log: toutes actions tracées dans `platform_audit_logs`

**Rôles platform:**
- `platform_super_admin` — Accès complet
- `isPlatformOwner=true` — Root admin non supprimable

---

## 4. Flow d'Inscription Admin (/api/admin/register)

### 4.1 Prérequis

- Firebase Token **OBLIGATOIRE** (pas d'inscription legacy)
- Validation email via Firebase (déjà vérifié par Google)

### 4.2 Logique de lookup (Identity Resolution)

```
1. Lookup par Firebase UID (users.firebaseUid)
   → Si trouvé: user = existant
   
2. Lookup par email (users.email)
   → Si trouvé + firebase_uid NULL: backfill UID
   → Si trouvé + firebase_uid différent: REJECT EMAIL_ALREADY_LINKED
   
3. Lookup dans accounts (mobile)
   → Si providerId match: OK, créer user admin
   → Si providerId différent: REJECT EMAIL_ALREADY_LINKED
   → Si email-only (pas Firebase): REJECT EMAIL_TAKEN
   
4. Nouveau user: création atomique user + community + membership
```

### 4.3 États possibles

| État | Condition | Action |
|------|-----------|--------|
| Nouveau user | Aucun match UID/email | Créer user + community |
| User sans community | User existe, 0 membership owner | Créer community (RESUME) |
| User avec community | User existe, 1+ membership owner | REJECT 409 ALREADY_REGISTERED |
| UID conflit | Email lié à autre UID | REJECT 409 EMAIL_ALREADY_LINKED |
| Email mobile | Email dans accounts sans Firebase | REJECT 400 EMAIL_TAKEN |

### 4.4 Création atomique

```typescript
storage.registerAdminWithCommunityAtomic({
  user: { firstName, lastName, email, firebaseUid, ... },
  community: { name, planId, subscriptionStatus, trialEndsAt, ... },
  membership: { isOwner: true, role: "admin", ... }
});
```

**Transaction Drizzle:** Si une étape échoue, tout est rollback.

### 4.5 Logs de diagnostic

| Log Pattern | Signification |
|-------------|---------------|
| `REGISTER_STATE` | État user/account/community avant décision |
| `RESUME_CREATE_COMMUNITY_START` | User existe sans community |
| `RESUME_CREATE_COMMUNITY_OK` | Community créée pour user existant |
| `ATOMIC_START / ATOMIC_SUCCESS` | Transaction atomique |
| `ALREADY_REGISTERED` | User a déjà une community |

---

## 5. Système de Subscription / Billing

### 5.1 Statuts de souscription

```sql
subscription_status ENUM:
  - 'trialing'   # Essai gratuit 14 jours
  - 'active'     # Abonnement actif
  - 'past_due'   # Paiement en retard
  - 'canceled'   # Abonnement annulé
```

### 5.2 Essai gratuit 14 jours

**Règle produit:** Plans payants (PLUS/PRO) bénéficient de 14 jours gratuits sans CB.

**Implémentation:**
```typescript
if (isPaidPlan) {
  subscriptionStatus = 'trialing';
  trialEndsAt = new Date(Date.now() + 14 * 24 * 60 * 60 * 1000);
} else {
  subscriptionStatus = 'active';
  trialEndsAt = null;
}
```

**Stripe:** Non appelé à l'inscription. Uniquement sur action volontaire (upgrade/paiement).

### 5.3 Cycle de vie SaaS Client

```
saas_client_status ENUM:
  - 'ACTIVE'     # J0 - Client à jour
  - 'IMPAYE_1'   # J+0 à J+15 - 1er impayé
  - 'IMPAYE_2'   # J+15 à J+30 - 2ème impayé
  - 'SUSPENDU'   # J+30 à J+60 - Accès suspendu
  - 'RESILIE'    # J+60+ - Compte résilié
```

**Transitions automatiques:** Gérées par `server/services/saasStatusJob.ts`

### 5.4 Stripe Integration

**Fichiers clés:**
- `server/stripe.ts` — Logique métier Stripe
- `server/stripeClient.ts` — Client Stripe SDK

**Fonctions principales:**
- `createKoomySubscriptionSession()` — Nouvelle souscription
- `createUpgradeCheckoutSession()` — Upgrade de plan
- `createRegistrationCheckoutSession()` — Inscription plan payant (post-trial)

**Webhooks gérés:**
- `checkout.session.completed`
- `customer.subscription.created/updated/deleted`
- `invoice.payment_succeeded/failed`

### 5.5 URLs Stripe par environnement

| Environnement | Backoffice URL | Mobile URL |
|---------------|----------------|------------|
| Sandbox | `https://backoffice-sandbox.koomy.app` | `https://sandbox.koomy.app` |
| Production | `https://backoffice.koomy.app` | `https://app.koomy.app` |

**Guard de sécurité:** Le code refuse d'utiliser URLs prod en sandbox.

---

## 6. Invariants Explicites (Source de Vérité)

### 6.1 Identité

| # | Invariant | Statut |
|---|-----------|--------|
| I1 | Firebase ne doit jamais être rollbacké | ✅ Contractuel |
| I2 | Firebase UID → single DB user (mapping 1:1) | ✅ Implémenté |
| I3 | Un Firebase user peut exister sans community (temporairement) | ✅ Géré |
| I4 | La DB Koomy est seule source de vérité métier | ✅ Contractuel |
| I5 | `users.password` peut être NULL (Firebase-only) | ✅ Schema |
| I6 | Email normalisé en lowercase | ✅ Implémenté |

### 6.2 Register

| # | Invariant | Statut |
|---|-----------|--------|
| R1 | `/api/admin/register` doit être idempotent | ✅ Implémenté |
| R2 | User sans community → reprendre création | ✅ RESUME flow |
| R3 | User avec community OWNER → refus 409 | ✅ ALREADY_REGISTERED |
| R4 | Firebase Token obligatoire (pas de legacy register) | ✅ Lockdown |
| R5 | 1 admin = 1 club (mono-club rule) | ✅ Enforced |

### 6.3 Email / Linking

| # | Invariant | Statut |
|---|-----------|--------|
| E1 | Email existant + firebase_uid NULL → backfill automatique | ✅ Implémenté |
| E2 | Email lié à autre firebase_uid → bloquer | ✅ EMAIL_ALREADY_LINKED |
| E3 | Même Firebase user → peut avoir user + account | ✅ Implémenté |

### 6.4 Subscription

| # | Invariant | Statut |
|---|-----------|--------|
| S1 | Essai gratuit = 14 jours | ✅ Implémenté |
| S2 | Pendant essai: subscriptionStatus = 'trialing' | ✅ Implémenté |
| S3 | Aucune CB demandée pendant essai | ✅ Implémenté |
| S4 | Stripe uniquement sur action volontaire (upgrade) | ✅ Implémenté |
| S5 | Plans: free < plus < pro < enterprise | ✅ Ordre défini |

### 6.5 Platform (SaaS Owner)

| # | Invariant | Statut |
|---|-----------|--------|
| P1 | Platform login = Legacy ONLY (zero Firebase) | ✅ Implémenté |
| P2 | IP Whitelist: France uniquement | ✅ Implémenté |
| P3 | Session: 2 heures, single active | ✅ Implémenté |
| P4 | Audit log: toutes actions tracées | ✅ Implémenté |
| P5 | Email verification obligatoire | ✅ Implémenté |

---

## 7. Problèmes Identifiés

### 7.1 Bugs corrigés (cette session)

| Bug | Description | Fix |
|-----|-------------|-----|
| EMAIL_TAKEN false positive | Account mobile avec même Firebase UID rejeté | Vérification providerId |
| Resume flow cassé | User sans community bloqué | RESUME_CREATE_COMMUNITY |
| Log renommage | EXISTING_USER_NEW_COMMUNITY → RESUME_CREATE_COMMUNITY_OK | Cohérence |

### 7.2 Dette technique identifiée

| Dette | Impact | Priorité |
|-------|--------|----------|
| Pas de statut `trial_expired` | UI gère via trialEndsAt | Faible |
| Enum Drizzle ≠ enum Postgres | Migration manuelle requise | Moyenne |
| Tests E2E register manquants | Régression possible | Haute |

### 7.3 Points d'attention

| Point | Description |
|-------|-------------|
| Backfill sandbox-only | Production ne backfill pas automatiquement |
| Firebase config manquante | Logs warn si `FIREBASE_PROJECT_ID` non set |
| Password NULL | Users Firebase-only n'ont pas de password |

---

## 8. Vérifications SQL

### 8.1 Users sans community owner

```sql
SELECT u.id, u.email, u.firebase_uid, 
       COUNT(m.id) FILTER (WHERE m.is_owner = true) as owned_communities
FROM users u
LEFT JOIN user_community_memberships m ON m.user_id = u.id
GROUP BY u.id, u.email, u.firebase_uid
HAVING COUNT(m.id) FILTER (WHERE m.is_owner = true) = 0;
```

### 8.2 Accounts Firebase

```sql
SELECT id, email, auth_provider, provider_id 
FROM accounts 
WHERE auth_provider = 'firebase';
```

### 8.3 Communities en trial

```sql
SELECT id, name, plan_id, subscription_status, trial_ends_at,
       CASE WHEN trial_ends_at < NOW() THEN 'EXPIRED' ELSE 'ACTIVE' END as trial_state
FROM communities 
WHERE subscription_status = 'trialing';
```

### 8.4 Platform admins

```sql
SELECT id, email, global_role, is_platform_owner, is_active, email_verified_at
FROM users 
WHERE global_role = 'platform_super_admin';
```

---

## 9. Fichiers de Référence

| Fichier | Responsabilité |
|---------|----------------|
| `shared/schema.ts` | Schéma DB, enums, types |
| `server/routes.ts` | Tous les endpoints API |
| `server/storage.ts` | Interface storage + Drizzle queries |
| `server/stripe.ts` | Logique Stripe |
| `server/lib/firebaseAdmin.ts` | Firebase Admin SDK |
| `server/middlewares/attachAuthContext.ts` | Liaison Firebase → Koomy |
| `server/services/saasStatusJob.ts` | Transitions automatiques SaaS |

---

## 10. Recommandations

### 10.1 Court terme (cette semaine)

1. **Tester les 4 scénarios register** en sandbox:
   - Nouveau user
   - User existant sans community (RESUME)
   - User avec community (409)
   - Email lié à autre UID (409)

2. **Vérifier migration enum** `subscription_status` en prod

### 10.2 Moyen terme (ce mois)

1. **Ajouter tests E2E** pour register flow
2. **Documenter recovery procedure** pour platform admin lockout
3. **Créer script emergency access** pour SaaS Owner

### 10.3 Long terme

1. **Considérer statut `trial_expired`** explicite
2. **Audit régulier** de ce document (mensuel)

---

## 11. Conclusion

Cet audit établit la **source de vérité** pour les systèmes d'identité, d'inscription et de billing de KOOMY.

**État global:** Le système est fonctionnel avec des invariants explicites. Les corrections récentes ont résolu les bugs d'idempotence de l'inscription.

**Prochaine révision:** 2026-02-22

---

**Auteur:** Replit Agent  
**Validé par:** CTO  
**Version:** 1.0.0
