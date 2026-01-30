# AUDIT AS-BUILT : GESTION DES ADMINS

**Date** : 25 janvier 2026  
**Statut** : Observation uniquement  
**Périmètre** : Backoffice, API, Guards, Modèle de données, Quotas  

---

## 1. Modèle de Données

### 1.1 Tables Impliquées

| Table | Rôle |
|-------|------|
| `user_community_memberships` | Table principale des adhésions (admin/membre/delegate) |
| `users` | Utilisateurs backoffice (profils admin) |
| `accounts` | Comptes app mobile (membres) |
| `admin_invitations` | Invitations admin en attente |
| `communities` | Communautés avec `ownerId` FK |

### 1.2 Champs Indiquant un Statut Admin

**Table `user_community_memberships`** :

| Champ | Type | Description |
|-------|------|-------------|
| `role` | text | `"member"` \| `"admin"` \| `"delegate"` |
| `adminRole` | enum | `super_admin` \| `support_admin` \| `finance_admin` \| `content_admin` \| `admin` |
| `isOwner` | boolean | `true` = propriétaire de la communauté (non supprimable) |
| `permissions` | text[] | V2 : `["MEMBERS", "FINANCE", "CONTENT", "EVENTS", "SETTINGS"]` |
| `sectionScope` | text | `"ALL"` \| `"SELECTED"` |
| `sectionIds` | text[] | Sections autorisées si `sectionScope = "SELECTED"` |

### 1.3 Hiérarchie des Rôles

```
OWNER (isOwner=true) > ADMIN (role="admin") > MANAGER > DELEGATE > MEMBER
```

| Niveau | Critère |
|--------|---------|
| **OWNER** | `isOwner === true` OU `role === "owner"` OU `adminRole === "super_admin"` |
| **ADMIN** | `role === "admin"` OU `adminRole === "admin"` |
| **DELEGATE** | `role === "delegate"` — **NEUTRALISÉ** (n'accorde pas d'accès backoffice) |
| **MEMBER** | `role === "member"` |

### 1.4 Rôle Legacy "delegate"

Le rôle `delegate` existe dans le schéma mais est **NEUTRALISÉ** dans le code :

```typescript
// server/routes.ts:149
// NOTE: "delegate" role is NEUTRALIZED - does NOT grant admin access
```

- Valeur encore acceptée en création (`VALID_ROLES = ['member', 'admin', 'delegate']`)
- Comptabilisé dans `getAdminCount()` (ligne 58 de usageLimitsGuards.ts)
- N'accorde **aucun accès backoffice** réel

---

## 2. Création & Promotion Admin

### 2.1 Endpoint Principal

**`POST /api/communities/:communityId/admins`** (server/routes.ts:4586)

| Aspect | Valeur |
|--------|--------|
| Guard | `requireMembership("communityId")`, `requireOwner` |
| Auth | Firebase Auth obligatoire |
| Qui peut créer | **OWNER uniquement** |
| Champs requis | `email`, `firstName`, `lastName`, `permissions[]` (min 1) |

### 2.2 Flux de Création

1. Vérification Firebase Auth
2. Vérification membership caller
3. Vérification `isOwner(callerMembership)` → sinon erreur `OWNER_REQUIRED`
4. Validation email/prénom/nom
5. Validation permissions (au moins 1 parmi MEMBERS, FINANCE, CONTENT, EVENTS, SETTINGS)
6. Vérification email non existant dans la communauté
7. Génération `memberId` et `claimCode`
8. Création membership avec `role: 'admin'`, `isOwner: false`

### 2.3 Autres Endpoints de Création Admin

| Endpoint | Usage |
|----------|-------|
| `POST /api/admin/register-community` | Création communauté + 1er admin (devient OWNER) |
| `POST /api/admin/join` | Admin rejoint une communauté existante via invitation |
| `POST /api/admin/join-with-credentials` | Idem pour WhiteLabel (auth legacy) |
| `POST /api/communities/:communityId/delegates` | Création delegate (neutralisé) |

### 2.4 Limite Actuelle

| Type | Statut |
|------|--------|
| **maxAdmins** | Défini dans `planLimits.ts` (Free:1, Plus:3, Pro:10, Enterprise:null) |
| **Enforcement** | **NON APPLIQUÉ** — `checkLimit("maxAdmins")` n'est jamais appelé |

**Constat critique** : La limite `maxAdmins` existe en configuration mais n'est pas vérifiée lors de la création d'admins. Un OWNER peut créer un nombre illimité d'admins quel que soit son plan.

---

## 3. Révocation & Downgrade

### 3.1 Suppression de Membership

**`DELETE /api/memberships/:id`** (server/routes.ts:5136)

```typescript
// server/storage.ts:1028
if (membership?.isOwner) {
  throw new OwnerAdminDeletionError();
}
```

**Protection OWNER** : L'admin propriétaire (`isOwner === true`) ne peut pas être supprimé.

### 3.2 Révocation Full Access (Platform)

**`DELETE /api/platform/communities/:id/full-access`** (server/routes.ts:8132)

Réservé aux platform super admins pour révoquer l'accès VIP.

### 3.3 Downgrade Admin → Member

**Pas d'endpoint dédié** observé. Le changement de rôle se fait via :
- Suppression du membership admin
- Création d'un nouveau membership membre

### 3.4 Transfert de Propriété

**Non implémenté**. Aucun endpoint `transferOwner` ou mécanisme de changement de `isOwner` n'existe.

---

## 4. Guards & Permissions

### 4.1 Middlewares Utilisés

| Guard | Fichier | Description |
|-------|---------|-------------|
| `requireFirebaseAuth` | guards.ts:73 | Vérifie Firebase UID présent |
| `requireMembership(param)` | guards.ts:90 | Vérifie membership dans la communauté |
| `requireAdmin` | guards.ts:175 | Vérifie `isAdminRole(membership)` |
| `requireOwner` | guards.ts | Vérifie `isOwnerRole(membership)` |
| `enforceTenantAuth` | enforceTenantAuth.ts:27 | Vérifie mode auth (Firebase/Legacy) selon tenant |

### 4.2 Fonctions Helper (routes.ts)

```typescript
// isOwner: true si isOwner flag OU role=super_admin/owner
function isOwner(membership): boolean

// isBackofficeAdmin: true si isOwner OU role=admin OU adminRole=admin
function isBackofficeAdmin(membership): boolean

// Alias pour backward compatibility
function isCommunityAdmin(membership): boolean
```

### 4.3 Vérification par accountId / userId

Le système gère les deux identifiants :

```typescript
// server/routes.ts:4609
const idToCheck = authResult.userId || authResult.accountId;
// Essaie d'abord comme userId (admin login), puis comme accountId (mobile app)
```

### 4.4 Cas Firebase Admin

- **Standard communities** : Firebase Auth obligatoire
- **White-Label** : Firebase **INTERDIT** (`blockFirebaseForWhiteLabel`)
- Le middleware `enforceTenantAuth` bloque si le mode auth ne correspond pas au tenant

### 4.5 Risques d'Incohérence Identifiés

1. **Double source de vérité** : `role` et `adminRole` peuvent diverger
2. **Delegate comptabilisé** : `getAdminCount()` compte les delegates alors qu'ils sont neutralisés
3. **Pas de validation croisée** : Un admin peut avoir `role="admin"` sans `adminRole`

---

## 5. Quotas & Plans

### 5.1 Définition maxAdmins

**Fichier** : `server/lib/planLimits.ts`

```typescript
const DEFAULT_LIMITS = {
  free: { maxMembers: 50, maxAdmins: 1, maxTags: 10 },
  plus: { maxMembers: 500, maxAdmins: 3, maxTags: 50 },
  pro: { maxMembers: 5000, maxAdmins: 10, maxTags: 200 },
  enterprise: { maxMembers: null, maxAdmins: null, maxTags: 700 },
  whitelabel: { maxMembers: null, maxAdmins: null, maxTags: 700 },
};
```

### 5.2 Capability multiAdmin

| Plan | `multiAdmin` |
|------|--------------|
| FREE | `false` |
| PLUS | `true` |
| PRO | `true` |
| ENTERPRISE | `true` |

### 5.3 État de l'Enforcement

| Élément | Statut |
|---------|--------|
| `maxAdmins` défini | OUI |
| `getAdminCount()` implémenté | OUI |
| `getCurrentUsage("maxAdmins")` implémenté | OUI |
| `checkLimit("maxAdmins")` appelé sur création | **NON** |
| Erreur 402 retournée si quota dépassé | **NON** |

### 5.4 Impacts Business & Techniques

| Impact | Description |
|--------|-------------|
| **Abus possible** | Un plan FREE peut créer des admins illimités |
| **Incohérence tarifaire** | Le différenciateur PLUS/PRO (nombre d'admins) n'est pas appliqué |
| **Données faussées** | Les métriques de quota peuvent afficher des valeurs incorrectes |
| **Comptage erroné** | Les delegates neutralisés sont comptés comme admins |

---

## 6. Dette & Risques Identifiés

### 6.1 Incohérences

| ID | Description | Sévérité |
|----|-------------|----------|
| ADMIN-01 | `maxAdmins` non appliqué sur création | HAUTE |
| ADMIN-02 | `getAdminCount()` compte les delegates (neutralisés) | MOYENNE |
| ADMIN-03 | Double source de vérité `role` / `adminRole` | FAIBLE |
| ADMIN-04 | Pas de transfert de propriété implémenté | MOYENNE |

### 6.2 Bypass Possibles

| Scénario | Risque |
|----------|--------|
| OWNER crée admins illimités sur plan FREE | Quota contourné |
| Delegate créé via ancien endpoint | Comptabilisé mais neutralisé |
| Admin créé sans permissions effectives | Incohérence fonctionnelle |

### 6.3 Logiques Dupliquées

- `isOwner()` défini dans `routes.ts` ET `guards.ts` (légèrement différent)
- `isBackofficeAdmin()` vs `isAdminRole()` : mêmes logiques, noms différents
- Vérification membership dupliquée dans plusieurs middlewares

### 6.4 Zones Non Couvertes

| Zone | État |
|------|------|
| Transfert de propriété | Non implémenté |
| Downgrade admin → member | Pas d'endpoint dédié |
| Révocation en masse | Non implémenté |
| Historique des rôles | Non tracé |
| Expiration des droits admin | Non implémenté |

---

## 7. Synthèse

### Points Conformes

- Hiérarchie OWNER > ADMIN > MEMBER claire
- Protection du OWNER contre la suppression
- Guards Firebase Auth fonctionnels
- Système de permissions V2 (5 packages) en place

### Points Non Conformes

- **maxAdmins non appliqué** (GAP-001 documenté)
- Delegates comptabilisés mais neutralisés
- Pas de mécanisme de transfert de propriété

### Recommandations (Observation Uniquement)

1. Appliquer `checkLimit("maxAdmins")` sur POST `/api/communities/:id/admins`
2. Exclure delegates de `getAdminCount()` (cohérence avec neutralisation)
3. Implémenter transfert de propriété sécurisé
4. Unifier les helper functions de vérification de rôle

---

**Fin du rapport d'audit**
