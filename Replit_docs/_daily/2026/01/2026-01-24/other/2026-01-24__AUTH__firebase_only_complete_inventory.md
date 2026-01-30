# KOOMY — Inventaire Complet Routes & Plan Migration Firebase Only

**Date**: 2026-01-24
**Statut**: LIVRABLE POUR VALIDATION
**Total routes**: 235

---

## 1. INVENTAIRE DES ROUTES — CLASSIFICATION EXPLICITE

### 1.1 PUBLIC (Aucune auth requise) — 47 routes

| Route | Méthode | Description |
|-------|---------|-------------|
| `/health` | GET | Healthcheck |
| `/api/health` | GET | Healthcheck API |
| `/api/env` | GET | Environment info |
| `/api/version` | GET | Version info |
| `/api/ai-status` | GET | AI status |
| `/api/storage/status` | GET | Storage status |
| `/api/whitelabel/by-host` | GET | WL config lookup |
| `/api/white-label/config` | GET | WL config |
| `/api/accounts/register` | POST | User registration |
| `/api/accounts/login` | POST | Legacy login (membre) |
| `/api/memberships/verify/:claimCode` | GET | Verify claim code |
| `/api/claim/verify` | POST | Verify claim |
| `/api/memberships/claim` | POST | Claim membership |
| `/api/memberships/claim-with-firebase` | POST | Claim via Firebase |
| `/api/memberships/register-and-claim` | POST | Register + claim |
| `/api/admin/login` | POST | **LEGACY ADMIN** ⚠️ |
| `/api/admin/forgot-password` | POST | Password reset |
| `/api/admin/register` | POST | Admin registration |
| `/api/admin/register-community` | POST | Community creation |
| `/api/admin/join-with-credentials` | POST | Join via credentials |
| `/api/communities` | GET | List communities |
| `/api/communities/:id` | GET | Get community |
| `/api/plans` | GET | List plans |
| `/api/plans/public` | GET | Public plans |
| `/api/plans/code/:code` | GET | Plan by code |
| `/api/plans/:id` | GET | Plan by ID |
| `/api/chat` | POST | AI chat |
| `/api/contact` | POST | Contact form |
| `/api/join/:slug` | GET | Self-enrollment page |
| `/api/join/:slug` | POST | Self-enrollment submit |
| `/api/billing/status` | GET | Billing status |
| `/api/billing/registration-status` | GET | Registration status |
| `/api/billing/verify-checkout-session` | GET | Verify checkout |
| `/api/billing/retry-checkout` | GET | Retry checkout |
| `/api/objects/*` | GET | Object storage proxy |
| `/api/debug/*` | GET/POST | Debug endpoints (sandbox) |

### 1.2 SYSTEM / INFRA (Token spécial ou webhook) — 12 routes

| Route | Méthode | Auth | Description |
|-------|---------|------|-------------|
| `/api/webhooks/stripe` | POST | Stripe signature | Webhook Stripe |
| `/api/internal/cron/saas-status` | POST | CRON_SECRET | Cron job |
| `/api/internal/platform/health/collect` | POST | Internal | Health collect |
| `/api/platform/login` | POST | Email/Pass platform | Owner login |
| `/api/platform/validate-session` | POST | Session token | Validate session |
| `/api/platform/renew-session` | POST | Session token | Renew session |
| `/api/platform/logout` | POST | Session token | Logout |
| `/api/_debug/db-identity` | GET | DEBUG_SECRET | DB identity |

### 1.3 FIREBASE AUTH REQUIRED (déjà migrées) — 9 routes

| Route | Méthode | Guards actuels |
|-------|---------|----------------|
| `/api/members/join` | POST | `requireFirebaseAuth` |
| `/api/admin/join` | POST | `requireFirebaseAuth` |
| `/api/communities/:id/news` | POST | `requireFirebaseAuth` |
| `/api/communities/:id/news/:id` | PATCH | `requireFirebaseAuth` |
| `/api/communities/:id/news/:id` | DELETE | `requireFirebaseAuth` |
| `/api/memberships/:id` | DELETE | `requireFirebaseAuth` |
| `/api/memberships/:id` | PATCH | `requireFirebaseAuth` |
| `/api/communities/:id` | PUT | `requireMembership` |
| `/api/communities/:id/admins` | POST | `requireMembership` |

### 1.4 À MIGRER — `requireAuth()` legacy (45 usages) ⚠️

Ces routes utilisent `requireAuth()` qui accepte Firebase OU legacy token.
**Objectif: remplacer par `requireFirebaseAuth` ou vérification directe.**

#### Groupe A — Lecture données (GET) — 12 routes

| Route | Ligne | Description |
|-------|-------|-------------|
| `/api/communities/:id/subscription-state` | 4873 | État abonnement |
| `/api/communities/:id/suspended-members-count` | 4916 | Compteur suspendus |
| `/api/communities/:id/sections` | 6489 | Liste sections |
| `/api/communities/:id/sections/:id` | 6545 | Détail section |
| `/api/communities/:id/events` | 6611 | Liste events |
| `/api/communities/:id/event-categories` | 6493 | Categories events |
| `/api/communities/:id/news` | 6943 | Liste news |
| `/api/communities/:id/tags` | 10970 | Liste tags |
| `/api/communities/:id/membership-plans` | 10590 | Plans membership |
| `/api/communities/:id/collections/all` | 10420 | Collections |
| `/api/communities/:id/transactions` | 10532 | Transactions |
| `/api/communities/:id/branding` | 8124 | Branding config |

#### Groupe B — Écriture contenu (POST/PUT/PATCH/DELETE) — 18 routes

| Route | Ligne | Description |
|-------|-------|-------------|
| `/api/communities/:id/admins` | 4576 | Créer admin |
| `/api/memberships` | 5169 | Créer membership |
| `/api/memberships/:id/regenerate-code` | 5546 | Regenerer code |
| `/api/memberships/:id/resend-claim` | 5606 | Renvoyer claim |
| `/api/communities/:id/sections` | 6159 | Créer section |
| `/api/communities/:id/sections/:id` | 6210 | Modifier section |
| `/api/communities/:id/sections/:id` (DELETE) | 6288 | Supprimer section |
| `/api/communities/:id/event-categories` | 6346 | Créer catégorie |
| `/api/communities/:id/event-categories/:id` | 6400 | Modifier catégorie |
| `/api/communities/:id/event-categories/:id` (DELETE) | 6459 | Supprimer catégorie |
| `/api/communities/:id/events` (POST) | 6611 | Créer event |
| `/api/communities/:id/events/:id` (PATCH) | 6700 | Modifier event |
| `/api/communities/:id/events/:id` (DELETE) | 6750 | Supprimer event |
| `/api/communities/:id/tags` (POST) | 10988 | Créer tag |
| `/api/tags/:id` (PUT) | 11059 | Modifier tag |
| `/api/tags/:id/deactivate` | 11109 | Désactiver tag |
| `/api/tags/:id` (DELETE) | 11143 | Supprimer tag |
| `/api/communities/:id/membership-plans` (POST) | 10607 | Créer plan |

#### Groupe C — Admin/Settings — 15 routes

| Route | Ligne | Description |
|-------|-------|-------------|
| `/api/membership-plans/:id` (PATCH) | 10731 | Modifier plan |
| `/api/membership-plans/:id` (DELETE) | 10808 | Supprimer plan |
| `/api/communities/:id/member-profile-config` (PUT) | 10880 | Config profil |
| `/api/memberships/:id/mark-paid` | 10931 | Marquer payé |
| `/api/memberships/:id/tags` (PUT) | 11193 | Modifier tags |
| `/api/memberships/:id/tags/:id` (POST) | 11228 | Ajouter tag |
| `/api/memberships/:id/tags/:id` (DELETE) | 11258 | Retirer tag |
| `/api/communities/:id/enrollment-requests` | 11791 | Liste inscriptions |
| `/api/communities/:id/enrollment-requests/:id/approve` | 11819 | Approuver |
| `/api/communities/:id/enrollment-requests/:id/reject` | 11949 | Rejeter |
| `/api/communities/:id/self-enrollment/settings` (GET) | 12002 | Settings enrollment |
| `/api/communities/:id/self-enrollment/settings` (PATCH) | 12037 | Modifier enrollment |
| `/api/communities/:id/self-enrollment/generate-slug` | 12127 | Générer slug |
| `/api/admin/communities/:id/repair-memberships` | 12260 | Repair tool |
| `/api/communities/:id/branding` (PATCH) | 8157 | Modifier branding |

### 1.5 PLATFORM OWNER (Session spéciale) — ~40 routes

Ces routes utilisent le système de session platform (SaaS Owner).
**À traiter séparément** — le contrat platform peut rester legacy temporairement.

| Préfixe | Nombre | Description |
|---------|--------|-------------|
| `/api/platform/*` | ~35 | Dashboard owner |
| `/api/owner/*` | ~5 | Templates email |

---

## 2. FLUX AUTH FRONTEND — VÉRITÉ TECHNIQUE

### 2.1 Token dispatché par contexte UI

| Contexte | Hostname | Token Source | Dispatch |
|----------|----------|--------------|----------|
| Site Public | koomy.app | Firebase (Google/Email) | Firebase JWT |
| Wallet Membre | sandbox.koomy.app | Firebase | Firebase JWT |
| Backoffice Admin | backoffice-sandbox.koomy.app | **`/api/admin/login` → sessionToken** | **Legacy** ⚠️ |
| SaaS Owner | saasowner-sandbox.koomy.app | `/api/platform/login` → sessionToken | Platform session |

### 2.2 Construction du header Authorization

**Fichier**: `client/src/api/httpClient.ts` (ligne ~180)

```typescript
// Ordre actuel (avec fallback legacy)
const firebaseToken = await getFirebaseIdToken();  // 1. Firebase
const legacyToken = getAuthToken();                // 2. Legacy fallback

if (firebaseToken) {
  headers['Authorization'] = `Bearer ${firebaseToken}`;
} else if (legacyToken) {
  headers['Authorization'] = `Bearer ${legacyToken}`;  // ← À SUPPRIMER
}
```

### 2.3 Moment où legacy token peut exister

| Scénario | Token créé | Où stocké |
|----------|------------|-----------|
| Admin login email/password | `/api/admin/login` retourne sessionToken | `koomy_auth_token` localStorage |
| Après refresh | Token persisté | localStorage |
| Platform owner login | `/api/platform/login` | Session cookie |

### 2.4 Comportement cible (POST-MIGRATION)

```typescript
// httpClient.ts — APRÈS migration
const firebaseToken = await getFirebaseIdToken();
if (!firebaseToken) {
  // Pas de fallback, user non authentifié
  return;
}
headers['Authorization'] = `Bearer ${firebaseToken}`;

// localStorage "koomy_auth_token" → PURGÉ et jamais réutilisé
```

---

## 3. GUARDS CIBLES — PROPOSITION

### 3.1 Guards existants (à conserver)

| Guard | Fichier | Rôle |
|-------|---------|------|
| `requireFirebaseAuth` | guards.ts | Vérifie `req.authContext.firebase.uid` |
| `requireMembership(param)` | guards.ts | Vérifie membership dans community |
| `requireRole(minRole)` | guards.ts | Vérifie rôle minimum |

### 3.2 Fonction à supprimer

| Fonction | Fichier | Raison |
|----------|---------|--------|
| `requireAuth()` | routes.ts | Hybrid legacy, à remplacer |
| `requireAuthWithUser()` | routes.ts | Dépend de requireAuth |

### 3.3 Mapping routes → guards cibles

| Type de route | Guard cible |
|---------------|-------------|
| Lecture données community | `requireFirebaseAuth` seul |
| Écriture community | `requireFirebaseAuth` + vérification admin inline |
| Admin actions | `requireMembership` + `requireRole('admin')` |
| Public | Aucun guard |
| Webhooks | Signature verification (inchangé) |
| Platform | Session platform (inchangé pour V1) |

### 3.4 Routes NE devant PAS être Firebase-only

| Route | Raison |
|-------|--------|
| `/api/webhooks/stripe` | Signature Stripe |
| `/api/internal/cron/*` | CRON_SECRET |
| `/api/platform/*` | Session platform (traité séparément) |
| `/api/owner/*` | Session platform |

---

## 4. PLAN D'EXÉCUTION RÉVISÉ (PHASES SÉCURISÉES)

### Phase 0 — Préchecks sandbox (30 min)

**Objectif**: Valider que l'environnement est prêt

1. **Vérifier compte Firebase admin**
   ```sql
   SELECT a.id, a.email, a.providerId, a.authProvider, ucm.role
   FROM accounts a
   JOIN user_community_memberships ucm ON ucm.account_id = a.id
   WHERE ucm.role IN ('admin', 'owner');
   ```
   - ✅ Si `authProvider = 'firebase'` et `providerId` présent → OK
   - ⚠️ Sinon → créer compte Firebase pour cet email

2. **Purger tokens legacy côté client (sandbox)**
   - Ouvrir DevTools sur backoffice-sandbox
   - `localStorage.removeItem('koomy_auth_token')`
   - Vérifier qu'aucun legacy token n'est stocké

3. **Créer checkpoint git**
   ```bash
   git tag pre-firebase-migration-$(date +%Y%m%d)
   ```

4. **Validation**: Admin peut se connecter via Firebase sur sandbox

---

### Phase 1 — Migration frontend admin login (1h)

**Objectif**: Admin utilise Firebase pour login

1. **Modifier `pages/admin/Login.tsx`**
   - Remplacer `apiPost('/api/admin/login')` par:
   ```typescript
   import { signInWithEmailAndPassword } from 'firebase/auth';
   const credential = await signInWithEmailAndPassword(auth, email, password);
   // Synchroniser avec backend si nécessaire
   ```

2. **Supprimer stockage legacy**
   - Ne plus appeler `setAuthToken()`
   - Supprimer import de `setAuthToken`

3. **Test validation**:
   - Login admin sur backoffice-sandbox
   - Vérifier token Firebase (3 segments) dans DevTools
   - Vérifier `localStorage.koomy_auth_token` = undefined

---

### Phase 2 — Migration routes par paquets (2h)

**Objectif**: Toutes les routes utilisent Firebase auth

#### Paquet A — Lecture (12 routes) — 30 min

Routes GET qui lisent des données community:
```
/api/communities/:id/subscription-state
/api/communities/:id/suspended-members-count
/api/communities/:id/sections
/api/communities/:id/sections/:id
/api/communities/:id/events
/api/communities/:id/event-categories
/api/communities/:id/news
/api/communities/:id/tags
/api/communities/:id/membership-plans
/api/communities/:id/collections/all
/api/communities/:id/transactions
/api/communities/:id/branding
```

**Action**: Remplacer `requireAuth(req, res)` par:
```typescript
if (!req.authContext?.koomyUser?.id) {
  return res.status(401).json({ error: "auth_required" });
}
const accountId = req.authContext.koomyUser.id;
```

**Test**: Vérifier lecture sections/events/news fonctionne

#### Paquet B — Écriture contenu (18 routes) — 45 min

Routes POST/PUT/PATCH/DELETE pour sections/events/categories/tags:
```
POST /api/communities/:id/sections
PATCH /api/communities/:id/sections/:id
DELETE /api/communities/:id/sections/:id
POST /api/communities/:id/event-categories
... (voir liste complète section 1.4)
```

**Action**: Même pattern que Paquet A

**Test**: Créer section + event + tag sur sandbox

#### Paquet C — Admin/Settings (15 routes) — 45 min

Routes admin et settings:
```
POST /api/memberships
POST /api/memberships/:id/regenerate-code
... (voir liste complète section 1.4)
```

**Action**: Même pattern

**Test**: Créer membership + modifier settings

---

### Phase 3 — Cleanup frontend (45 min)

**Objectif**: Aucun legacy token dans le frontend

1. **`httpClient.ts`**
   - Supprimer `getAuthToken()` fallback
   - Supprimer import `getAuthToken`
   - Supprimer branche `legacyToken`

2. **`AuthContext.tsx`**
   - Supprimer `verifySession()`
   - Supprimer références `legacyToken`
   - `refreshMe()` utilise uniquement Firebase

3. **Purge storage**
   - Au boot, si `koomy_auth_token` existe → supprimer

4. **Test**: Login/logout/refresh fonctionnent

---

### Phase 4 — Cleanup backend (30 min)

1. **Supprimer fonctions obsolètes**
   - `requireAuth()` dans routes.ts
   - `requireAuthWithUser()` dans routes.ts
   - Branche legacy dans `attachAuthContext.ts`

2. **Supprimer route legacy**
   - `/api/admin/login` (ou marquer deprecated avec 410)

3. **Supprimer instrumentation diagnostic**
   - AUTH_DISPATCH dans httpClient.ts
   - AUTH_TRACE dans attachAuthContext.ts
   - authDebug dans guards.ts

4. **Test final**: Grep codebase pour legacy

---

### Phase 5 — PROD SAFE (post-validation sandbox)

#### Runbook déploiement

1. **Pre-check** (J-1)
   - Vérifier compte Firebase admin prod
   - Communiquer avec admin sur changement
   - Créer tag git `pre-prod-firebase-$(date)`

2. **Déploiement**
   - Push sur branche main
   - Railway déploie automatiquement
   - Vérifier logs Railway (pas d'erreur 500)

3. **Validation** (J+0)
   - Admin se connecte via Firebase
   - Créer une section test
   - Vérifier aucun 401/403

4. **Rollback** (si problème)
   ```bash
   # Option A: Revert git
   git revert HEAD~N
   git push
   
   # Option B: Railway rollback
   # Via UI Railway → Deployments → Rollback to previous
   ```

---

## 5. CHECKLIST PROD + ROLLBACK

### Pre-flight checklist

- [ ] Compte Firebase admin prod vérifié (email + providerId)
- [ ] Tests sandbox tous passés
- [ ] Tag git créé
- [ ] Admin informé du changement
- [ ] Créneau déploiement validé (pas de pic usage)

### Post-déploiement checklist

- [ ] Logs Railway sans erreur 500
- [ ] Admin login fonctionne
- [ ] Créer section test → 200
- [ ] Créer event test → 200
- [ ] Créer news test → 200
- [ ] Modifier membership → 200

### Rollback triggers

| Symptôme | Action |
|----------|--------|
| Admin ne peut pas se connecter | Rollback immédiat |
| 401 sur toutes les routes | Rollback immédiat |
| 500 répétées | Rollback + debug |
| Fonctionnalité mineure cassée | Hotfix > Rollback |

### Contacts rollback

- Railway: UI Dashboard → Deployments
- Git: `git revert` + `git push`
- Durée rollback estimée: 5 min

---

## 6. DIAGRAMME AUTH FLOW (TEXTE)

```
┌─────────────────────────────────────────────────────────────────┐
│                     AVANT (Bipolarité)                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  [Membre]                    [Admin]                            │
│     │                           │                               │
│     ▼                           ▼                               │
│  Firebase Auth            /api/admin/login                      │
│     │                           │                               │
│     ▼                           ▼                               │
│  JWT Firebase             sessionToken (33 chars)               │
│     │                           │                               │
│     └──────────┬────────────────┘                               │
│                ▼                                                │
│         httpClient.ts                                           │
│    [Firebase || Legacy fallback]                                │
│                │                                                │
│                ▼                                                │
│         Backend routes                                          │
│    [requireFirebaseAuth || requireAuth]                         │
│                │                                                │
│        ┌───────┴───────┐                                        │
│        ▼               ▼                                        │
│   attachAuthContext  requireAuth()                              │
│   (Firebase only)    (Firebase + Legacy)                        │
│        │               │                                        │
│        ▼               ▼                                        │
│     ✅ 200          ✅ 200 ou ❌ 401                             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                     APRÈS (Firebase Only)                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  [Membre]                    [Admin]                            │
│     │                           │                               │
│     ▼                           ▼                               │
│  Firebase Auth            Firebase Auth                         │
│  (Google/Email)           (Email/Password)                      │
│     │                           │                               │
│     └──────────┬────────────────┘                               │
│                ▼                                                │
│          JWT Firebase                                           │
│                │                                                │
│                ▼                                                │
│         httpClient.ts                                           │
│       [Firebase ONLY]                                           │
│                │                                                │
│                ▼                                                │
│         Backend routes                                          │
│      [requireFirebaseAuth]                                      │
│                │                                                │
│                ▼                                                │
│        attachAuthContext                                        │
│        (Firebase verify)                                        │
│                │                                                │
│                ▼                                                │
│             ✅ 200                                               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 7. CRITÈRES DE SUCCÈS FINAL

- [ ] 0 occurrence de `requireAuth(` dans routes.ts actif
- [ ] 0 occurrence de `legacyToken` dans httpClient.ts
- [ ] 0 occurrence de `koomy_auth_token` dispatché
- [ ] Route `/api/admin/login` supprimée ou désactivée
- [ ] Admin peut se connecter via Firebase email/password
- [ ] Toutes les actions admin (CRUD) fonctionnent
- [ ] Logs ne montrent plus "Legacy token detected"
- [ ] Tests manuels sandbox passent
- [ ] Tests manuels prod passent

---

**Fin du livrable — En attente de validation**
