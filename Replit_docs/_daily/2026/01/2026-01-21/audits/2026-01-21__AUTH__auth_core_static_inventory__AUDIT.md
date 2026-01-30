# KOOMY — AUTH CORE AUDIT
## Bilan clinique exhaustif

**Date :** 2026-01-21  
**Périmètre :** Authentification, Rôles, Autorisations, Appartenance utilisateur ↔ organisation

---

## 1. Vue d'ensemble

### 1.1 Localisation du cœur auth

Le système d'authentification de Koomy est distribué entre :

| Composant | Fichier(s) principal(aux) |
|-----------|--------------------------|
| Backend - Routes auth | `server/routes.ts` (lignes 1550-2800, 2890-3200, 6440-6700) |
| Backend - Storage | `server/storage.ts` (interface IStorage + implémentation) |
| Backend - Helpers auth | `server/routes.ts` (lignes 117-500) |
| Backend - SaaS Access | `server/lib/saasAccess.ts` |
| Frontend - Contexte auth | `client/src/contexts/AuthContext.tsx` |
| Frontend - Storage local | `client/src/lib/storage.ts` |
| Frontend - Mode résolution | `client/src/lib/appModeResolver.ts` |
| Schéma données | `shared/schema.ts` |

### 1.2 Flux auth factuel

**Login Admin (Backoffice) :**
```
POST /api/admin/login
  → Recherche dans `users` table par email
  → Si trouvé + password valide → retourne user + memberships via getUserMemberships(userId)
  → Sinon fallback → Recherche dans `accounts` table
  → Si trouvé + passwordHash valide → retourne account + memberships via getAccountMemberships(accountId)
  → Génère sessionToken: `${id}:${timestamp}:${random}`
```

**Login Membre (App mobile) :**
```
POST /api/accounts/login
  → Recherche dans `accounts` table par email
  → Vérifie passwordHash via verifyPassword()
  → Retourne account + memberships via getAccountMemberships(accountId)
  → Token: `${accountId}:${timestamp}:${random}`
```

**Login Plateforme (SaaS Owner) :**
```
POST /api/platform/login
  → Vérifie IP France uniquement (countryCode === 'FR')
  → Recherche dans `users` table + vérifie globalRole
  → Crée session dans `platform_sessions` (2h expiry)
  → Révoque sessions précédentes (single active session)
```

**Accès aux ressources :**
```
Request → requireAuth() extrait auth depuis:
  1. Bearer token (Authorization header) → accountId
  2. req.user / req.account (session) → sessionId (peut être accountId ou userId)
  3. req.body.userId (legacy)
→ Résolution membership via getAccountMemberships() ou getMembership()
→ Vérification rôle via isOwner(), isBackofficeAdmin(), canAccessSection(), can()
```

---

## 2. Modèle de données (vérité terrain)

### 2.1 Table `accounts`

**Rôle :** Comptes utilisateurs de l'application mobile (membres)

| Champ | Type | Description |
|-------|------|-------------|
| `id` | varchar(50) | PK, UUID auto-généré |
| `email` | text | Unique, NOT NULL |
| `passwordHash` | text | NOT NULL |
| `firstName` | text | Nullable |
| `lastName` | text | Nullable |
| `avatar` | text | Nullable |
| `authProvider` | text | Default "email" |
| `providerId` | text | Pour OAuth |
| `createdAt` | timestamp | NOT NULL |
| `updatedAt` | timestamp | NOT NULL |

**Source de vérité pour :** Identité des membres app mobile

### 2.2 Table `users`

**Rôle :** Administrateurs backoffice + administrateurs plateforme

| Champ | Type | Description |
|-------|------|-------------|
| `id` | varchar(50) | PK, UUID auto-généré |
| `firstName` | text | NOT NULL |
| `lastName` | text | NOT NULL |
| `email` | text | Unique, NOT NULL |
| `password` | text | NOT NULL (hash bcrypt) |
| `phone` | text | Nullable |
| `avatar` | text | Nullable |
| `globalRole` | enum | NULL \| platform_super_admin \| platform_support \| platform_commercial |
| `isPlatformOwner` | boolean | true = root admin indestructible |
| `isActive` | boolean | false jusqu'à email vérifié (platform admins) |
| `emailVerifiedAt` | timestamp | |
| `failedLoginAttempts` | integer | Rate limiting |
| `lockedUntil` | timestamp | Verrouillage compte |
| `createdAt` | timestamp | |

**Contraintes implicites :**
- Un user avec `globalRole != NULL` est un admin plateforme
- Un user avec `globalRole = NULL` est un admin communautaire (backoffice)
- `isPlatformOwner = true` protège contre la suppression

### 2.3 Table `user_community_memberships`

**Rôle :** Table de jonction définissant l'appartenance et les rôles

| Champ | Type | Description |
|-------|------|-------------|
| `id` | varchar(50) | PK |
| `userId` | varchar(50) | FK → users (nullable) |
| `accountId` | varchar(50) | FK → accounts (nullable) |
| `communityId` | varchar(50) | FK → communities, NOT NULL |
| `memberId` | text | NOT NULL, ex: "DEMO-001" |
| `role` | text | NOT NULL: "member" \| "admin" \| "delegate" |
| `adminRole` | enum | super_admin \| support_admin \| finance_admin \| content_admin \| admin |
| `isOwner` | boolean | true = propriétaire communauté |
| `sectionScope` | text | "ALL" \| "SELECTED" |
| `sectionIds` | jsonb | string[] si sectionScope = "SELECTED" |
| `permissions` | jsonb | AdminPermission[] : ["MEMBERS", "FINANCE", "CONTENT", "EVENTS", "SETTINGS"] |
| `status` | enum | active \| expired \| suspended |
| `canManageArticles` | boolean | Legacy flag |
| `canManageEvents` | boolean | Legacy flag |
| `canManageCollections` | boolean | Legacy flag |
| `canManageMessages` | boolean | Legacy flag |
| `canManageMembers` | boolean | Legacy flag |
| `canScanPresence` | boolean | Legacy flag |
| ... | | (nombreux autres champs pour cotisations, plans, paiements) |

**Sources de vérité multiples observées :**

1. **Appartenance :**
   - `userId` : pour les admins backoffice (table users)
   - `accountId` : pour les membres app mobile (table accounts)
   - **⚠️ Les deux peuvent être NULL** (cartes créées par admin non réclamées)

2. **Rôle admin :**
   - `role` : valeur textuelle ("admin", "member", "delegate")
   - `adminRole` : enum distinct (super_admin, admin, etc.)
   - `isOwner` : boolean prioritaire

3. **Permissions :**
   - `permissions` jsonb array (nouveau système V2)
   - `canManage*` booleans (legacy, maintenu pour compat)

### 2.4 Table `platform_sessions`

**Rôle :** Sessions pour les admins plateforme (expiration 2h)

| Champ | Type |
|-------|------|
| `id` | varchar(50) PK |
| `userId` | FK → users |
| `token` | text unique |
| `ipAddress` | text |
| `userAgent` | text |
| `expiresAt` | timestamp (2h) |
| `revokedAt` | timestamp |
| `createdAt` | timestamp |

### 2.5 Table `communities`

Champs auth-related :

| Champ | Type | Description |
|-------|------|-------------|
| `ownerId` | FK → users | Propriétaire (nullable) |
| `subscriptionStatus` | enum | pending \| active \| past_due \| canceled |
| `saasClientStatus` | enum | ACTIVE \| IMPAYE_1 \| IMPAYE_2 \| SUSPENDU \| RESILIE |
| `whiteLabel` | boolean | |
| `customDomain` | text | Pour routing white-label |

---

## 3. Backend — Décision d'accès

### 3.1 Fonctions d'extraction auth

**`requireAuth(req, res)`** (ligne 401)
```typescript
function requireAuth(req, res): AuthResult | null
// Retourne: { accountId?, userId?, authType: "account"|"session"|"body" }
```
- Extrait `accountId` depuis Bearer token
- Ou extrait `sessionId` depuis `req.user`/`req.account` → assigne aux deux `accountId` ET `userId`
- Fallback: `req.body.userId` (legacy)

**`requireAuthWithUser(req, res)`** (ligne 439)
```typescript
async function requireAuthWithUser(req, res): Promise<AuthResult | null>
```
- Appelle `requireAuth()`
- Si pas de `userId`, tente résolution via `getAccountMemberships(accountId)` pour trouver un `userId`

### 3.2 Helpers de décision rôle

**`isOwner(membership)`** (ligne 117)
```typescript
function isOwner(membership): boolean
// Vérifie dans l'ordre:
// 1. membership.isOwner === true
// 2. membership.role === "super_admin" || "owner"
// 3. membership.adminRole === "super_admin" || "owner"
```

**`isBackofficeAdmin(membership)`** (ligne 129)
```typescript
function isBackofficeAdmin(membership): boolean
// 1. isOwner(membership) → true
// 2. membership.role === "admin" → true
// 3. membership.adminRole === "admin" → true
```

**`canAccessSection(membership, sectionId)`** (ligne 147)
```typescript
function canAccessSection(membership, sectionId): boolean
// 1. isOwner() → true (accès global)
// 2. !isBackofficeAdmin() → false
// 3. sectionScope === "ALL" → true
// 4. sectionScope === "SELECTED" → vérifie sectionId in sectionIds[]
```

**`can(membership, permission, sectionId?)`** (ligne 200)
```typescript
function can(membership, permission: AdminPermission, sectionId?): boolean
// 1. isOwner() → true (toutes permissions)
// 2. !isBackofficeAdmin() → false
// 3. Vérifie permission in membership.permissions[]
// 4. Si sectionId fourni → canAccessSection()
```

### 3.3 Endpoints critiques

| Endpoint | Méthode auth | Vérification rôle | Qui décide |
|----------|-------------|-------------------|------------|
| `POST /api/admin/login` | Credentials (email/password) | Aucune | bcrypt.compare() |
| `POST /api/accounts/login` | Credentials | Aucune | verifyPassword() |
| `POST /api/platform/login` | Credentials + IP France | globalRole != NULL | Storage + IP check |
| `GET /api/accounts/me` | Bearer token | account existe | Storage lookup |
| `POST /api/communities/:id/admins` | requireAuth | isOwner() | Membership lookup |
| `PUT /api/communities/:id/settings` | requireAuth | isOwner() | Membership lookup |
| `GET /api/platform/*` | Session token | verifyPlatformAdmin() | platform_sessions + user.globalRole |

### 3.4 Middlewares

**`verifyPlatformAdmin(userId)`** (ligne 6444)
```typescript
const verifyPlatformAdmin = async (userId): Promise<{ valid, user?, error? }>
// 1. Vérifie userId exists
// 2. Récupère user depuis storage
// 3. Vérifie user.globalRole != null
```

**`checkSaasAccess`** (server/lib/saasAccess.ts)
- Middleware pour routes communauté
- Bloque accès si `community.saasClientStatus` in ['SUSPENDU', 'RESILIE']
- Sauf endpoints read-only (export data)

---

## 4. Frontend — Hypothèses et couplages

### 4.1 États auth globaux

**`AuthContext`** expose :
```typescript
interface AuthContextType {
  account: AuthAccount | null;          // Pour app mobile
  user: AuthUser | null;                // Pour backoffice
  currentMembership: Membership | null; // Membership actuel
  currentCommunity: Community | null;
  isAuthenticated: boolean;             // !!account || !!user
  isAdmin: boolean;                     // Dérivé de membership
  isPlatformAdmin: boolean;             // user.isPlatformAdmin
  authReady: boolean;                   // Hydratation terminée
  authError: { type, message } | null;
}
```

### 4.2 Logique d'hydratation

**Sync (web) :**
```typescript
hydrateFromStorageSync()
// Lit localStorage: koomy_account, koomy_user, koomy_current_membership, koomy_auth_token
// Si account/user présent MAIS token absent → force logout
```

**Async (native) :**
```typescript
hydrateAndVerifySession()
// Lit Capacitor Preferences
// Appelle /api/accounts/me pour vérifier validité
// Si 401 → clear auth
// Si network error → garde session locale + affiche "Hors ligne"
```

### 4.3 Conditions d'affichage rôle (frontend)

**Observées dans le codebase :**
- `isAdmin` dérivé de `membership.role === 'admin'` ou `isOwner`
- `isPlatformAdmin` stocké directement depuis `user.isPlatformAdmin`
- Navigation conditionnelle basée sur `currentMembership?.isOwner`

### 4.4 Redirections automatiques

**`appModeResolver.ts`** :
- Hostname → AppMode déterministe
- `sitepublic-sandbox.koomy.app` → SITE_PUBLIC
- `sandbox.koomy.app` → WALLET
- `backoffice-sandbox.koomy.app` → BACKOFFICE
- `club-mobile-sandbox.koomy.app` → CLUB_MOBILE
- `saasowner-sandbox.koomy.app` → SAAS_OWNER
- Domaines inconnus `*.koomy.app` → WHITE_LABEL (DB lookup)
- localhost/replit.dev → STANDARD

**⚠️ Logique normalement backend :**
- Le frontend décide du "mode app" basé sur hostname AVANT toute auth
- Cette décision influence quel shell/login afficher

---

## 5. Couplages dangereux

### 5.1 Auth ↔ Onboarding

**Fichier :** `server/routes.ts` - POST /api/admin/register

```
Registration flow:
1. Crée user (storage.createUser)
2. Crée community (storage.createCommunity) avec user.id comme ownerId
3. Crée membership (storage.createMembership) avec isOwner=true
```

**Couplage :** Si étape 2 ou 3 échoue, user orphelin créé.

### 5.2 Auth ↔ Paiement/Stripe

**Fichier :** `server/routes.ts` - POST /api/admin/register

```
Si planId in ['plus', 'pro']:
  → Community créée avec subscriptionStatus: "pending"
  → Stripe Checkout Session créée
  → Redirection vers Stripe
  → Webhook checkout.session.completed active le plan
```

**Couplage :**
- Accès conditionné par `subscriptionStatus` et `saasClientStatus`
- Community peut exister en état "pending" si paiement non complété
- SaaS access middleware bloque communautés SUSPENDU/RESILIE

### 5.3 Auth ↔ White-label

**Fichiers :** 
- `client/src/lib/appModeResolver.ts`
- `server/routes.ts` - GET /api/white-label/config

```
Frontend hostname patterns:
→ Si match SANDBOX/PRODUCTION patterns → isForcedMode=true, NO DB lookup
→ Si *.koomy.app non reconnu → WHITE_LABEL mode → nécessite DB lookup
```

**Couplage :**
- `community.customDomain` permet routing white-label
- `community.whiteLabel` flag active le mode
- `community.brandConfig` stocke la personnalisation

### 5.4 Auth ↔ Routing

**Fichier :** `client/src/lib/appModeResolver.ts`

Le frontend détermine le shell à afficher AVANT authentification :
- SITE_PUBLIC → WebsiteHome
- WALLET → MobileLogin
- BACKOFFICE → AdminLogin
- CLUB_MOBILE → MobileAdminLogin
- SAAS_OWNER → PlatformLogin

**Couplage :** Le hostname dicte le parcours auth, pas l'inverse.

### 5.5 Auth ↔ UI conditionnelle

**Observations :**
- Boutons admin visibles si `isOwner` ou `isBackofficeAdmin`
- Menu paramètres visible si `can(membership, 'SETTINGS')`
- Banner "SANDBOX" affiché si `isSandbox` de `/api/env`

---

## 6. Zones à risque

### 6.1 Incohérences potentielles

**Double source userId/accountId :**
- Membership peut avoir `userId` ET/OU `accountId`
- `userId` utilisé pour admins backoffice (table users)
- `accountId` utilisé pour membres mobile (table accounts)
- Login admin met sessionId dans BOTH `accountId` ET `userId` du AuthResult
- Code downstream doit gérer les deux cas

**Triple source de rôle :**
- `role` (text): "member" | "admin" | "delegate"
- `adminRole` (enum): super_admin | admin | etc.
- `isOwner` (boolean): priorité absolue
- Mapping non garantit cohérent

**Permissions legacy vs V2 :**
- `canManage*` booleans (legacy) 
- `permissions[]` array (V2)
- Pas de garantie de synchronisation

### 6.2 États impossibles mais observables

1. **Membership sans identité :**
   - `userId = NULL` ET `accountId = NULL` (carte non réclamée)
   - Mais `isOwner = true` ou `role = 'admin'`
   - **→ Admin sans compte attaché**

2. **User sans membership :**
   - `users` record existe
   - Aucune entrée dans `user_community_memberships` avec ce `userId`
   - **→ Admin orphelin**

3. **Community sans owner :**
   - Aucune membership avec `isOwner = true` pour cette `communityId`
   - `communities.ownerId` existe mais membership correspondante absente
   - **→ Gouvernance non définie**

### 6.3 Cas non gérés

**Bearer token parsing :**
```typescript
const parts = token.split(':');
// Attend format: accountId:timestamp:random
// Si format différent → comportement indéfini
```

**Password null :**
- Code vérifie `if (user.password)` avant bcrypt
- Mais si user existe avec password = null → fallback silencieux vers accounts table
- Pas d'erreur explicite AUTH_NO_PASSWORD_SET

**Session expiry (non-platform) :**
- Token admin/member format: `${id}:${timestamp}:${random}`
- Pas de vérification d'expiration côté backend (contrairement aux platform_sessions)
- Token valide indéfiniment

### 6.4 Hypothèses non garanties

1. **Frontend suppose que `isOwner` implique tous les droits**
   - Backend vérifie explicitement, mais frontend peut permettre l'accès UI

2. **Hostname routing suppose déploiement correct**
   - Si mauvais hostname → mauvais shell → UX cassée

3. **Storage lookup suppose intégrité référentielle**
   - `membership.communityId` → community doit exister
   - Pas de FK enforced au niveau applicatif

4. **Rate limiting par email uniquement**
   - `failedLoginAttempts` sur user
   - Pas de protection au niveau IP pour admins communautaires

---

## 7. Résumé clinique

### Points solides

1. **Séparation claire accounts/users**
   - Membres mobiles (accounts) vs Admins backoffice (users)
   - Chaque population a son endpoint login dédié

2. **Hiérarchie de rôles définie**
   - `isOwner` > `isBackofficeAdmin` > membre
   - Helpers centralisés (isOwner, can, canAccessSection)

3. **Platform sessions sécurisées**
   - Expiration 2h
   - Single active session
   - IP whitelist France
   - Audit logging complet

4. **SaaS access control**
   - Middleware dédié
   - États de suspension/résiliation clairs
   - Endpoints read-only préservés

### Points fragiles

1. **Double/triple source de vérité pour les rôles**
   - `role`, `adminRole`, `isOwner` peuvent diverger
   - Legacy `canManage*` vs nouveau `permissions[]`

2. **Mapping userId/accountId ambigu**
   - Membership peut référencer l'un, l'autre, ou aucun
   - Login admin assigne les deux au AuthResult

3. **Token admin sans expiration**
   - Contrairement aux platform_sessions
   - Token valide tant que format correct

4. **Création atomicité non garantie**
   - Register crée user, puis community, puis membership
   - Échec partiel = état incohérent

### Zones critiques

1. **Résolution membership pour auth**
   - `getAccountMemberships(accountId)` vs `getUserMemberships(userId)`
   - Fallback entre les deux non systématique
   - Memberships avec `accountId = NULL` invisibles pour certains flows

2. **White-label hostname resolution**
   - Frontend décide du mode AVANT auth
   - Mismatch hostname/DB = comportement indéfini

3. **Paiement → Accès conditionnel**
   - `subscriptionStatus: "pending"` bloque
   - `saasClientStatus: "SUSPENDU"` bloque
   - Webhook Stripe = source de vérité asynchrone

---

*Fin du bilan clinique*

**Aucune recommandation technique**  
**Aucun plan de refonte**  
**Aucun correctif proposé**

---

## Mini-log de conformité

| Action | Détail |
|--------|--------|
| Ancien chemin | `docs/audit/AUTH_CORE_AUDIT.md` |
| Nouveau chemin | `docs/audits/2026-01/AUTH/2026-01-21__AUTH__auth_core_static_inventory__AUDIT.md` |
| Opération | Copie (fichier original conservé) |
| Lien ajouté | `docs/_INDEX.md` section "Audits Actifs → AUTH" |
