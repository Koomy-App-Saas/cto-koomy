# Audit des Rôles & Privilèges — Backoffice Clients Koomy

**Date:** 2026-01-20  
**Type:** Audit READ-ONLY  
**Scope:** Rôles côté clients Koomy dans une communauté (club/asso)  
**Hors scope:** Staff Koomy / plateforme owner / rôles internes

---

## 1. Résumé Exécutif

Le système de rôles Koomy repose sur 3 rôles principaux (`member`, `admin`, `delegate`) stockés dans la colonne `role` de la table `user_community_memberships`. Un flag `isOwner` distingue le créateur de la communauté. Les `admin` disposent d'un sous-rôle optionnel (`adminRole`). Les `delegate` ont des permissions granulaires (`canManage*`).

**Points clés:**
- La fonction `isCommunityAdmin()` centralise la logique d'admin (isOwner || adminRole in [owner,admin,super_admin] || role in [admin,super_admin,owner])
- Incohérence: certains checks ne passent pas par `isCommunityAdmin()` et vérifient uniquement `role === "admin"`, excluant potentiellement les `isOwner`
- Les permissions `delegate` sont partiellement implémentées (canManageArticles, canManageCollections utilisés; canManageEvents, canManageMessages non utilisés en guards)

---

## 2. Rôles Existants

### 2.1 Source de vérité

| Définition | Fichier | Valeurs |
|------------|---------|---------|
| Colonne `role` | `shared/schema.ts:460` | `"member"` \| `"admin"` \| `"delegate"` |
| Enum `adminRoleEnum` | `shared/schema.ts:10` | `["super_admin", "support_admin", "finance_admin", "content_admin"]` |
| Flag `isOwner` | `shared/schema.ts:488` | `boolean` (true = créateur communauté) |
| Validation backend | `server/routes.ts:3177` | `['member', 'admin', 'delegate']` |

### 2.2 Stockage DB

| Table | Colonne | Type | Description |
|-------|---------|------|-------------|
| `user_community_memberships` | `role` | `text NOT NULL` | Rôle principal |
| `user_community_memberships` | `admin_role` | `admin_role enum` | Sous-rôle si role=admin |
| `user_community_memberships` | `is_owner` | `boolean` | Flag créateur |

### 2.3 Permissions Delegate (colonnes DB)

| Colonne | Default | Utilisé en guard |
|---------|---------|------------------|
| `can_manage_articles` | `true` | ✅ Oui |
| `can_manage_events` | `true` | ❌ Non |
| `can_manage_collections` | `true` | ✅ Oui |
| `can_manage_messages` | `true` | ❌ Non |
| `can_manage_members` | `true` | ✅ Oui |
| `can_scan_presence` | `true` | ❌ Non |

---

## 3. Tableau des Checks Observés

### 3.1 Helper `isCommunityAdmin()` (server/routes.ts:97-106)

```typescript
function isCommunityAdmin(membership): boolean {
  if (membership.isOwner === true) return true;
  if (membership.adminRole && ["owner", "admin", "super_admin"].includes(membership.adminRole)) return true;
  if (membership.role && ["admin", "super_admin", "owner"].includes(membership.role)) return true;
  return false;
}
```

**Rôles acceptés:** isOwner=true OU adminRole∈{owner,admin,super_admin} OU role∈{admin,super_admin,owner}

### 3.2 Checks par Domaine

#### Community Settings / General Admin

| Endpoint/Action | Type Check | Rôles acceptés | Message erreur | Fichier:ligne |
|-----------------|------------|----------------|----------------|---------------|
| GET /communities/:id/settings | isCommunityAdmin() | isOwner, admin, super_admin | "Accès refusé" | routes.ts:4117-4119 |
| PATCH /communities/:id | isCommunityAdmin() | isOwner, admin, super_admin | "Accès refusé" | routes.ts:4195-4197 |
| Self-enrollment settings | isCommunityAdmin() | isOwner, admin, super_admin | "Accès refusé" | routes.ts:4253, 4307, 4366, 4397 |

#### Members Management

| Endpoint/Action | Type Check | Rôles acceptés | Message erreur | Fichier:ligne |
|-----------------|------------|----------------|----------------|---------------|
| POST /members (create) | isCommunityAdmin() OR canManageMembers | admin, isOwner, delegate+permission | "Permission refusée" | routes.ts:3607-3611 |
| PATCH /members/:id | isCommunityAdmin() OR canManageMembers | admin, isOwner, delegate+permission | "Permission refusée" | routes.ts:3607-3611 |

#### Sections

| Endpoint/Action | Type Check | Rôles acceptés | Message erreur | Fichier:ligne |
|-----------------|------------|----------------|----------------|---------------|
| POST/PATCH/DELETE sections | ❓ Non identifié | - | - | - |

*Note: Aucun check explicite trouvé pour la gestion des sections*

#### Events

| Endpoint/Action | Type Check | Rôles acceptés | Message erreur | Fichier:ligne |
|-----------------|------------|----------------|----------------|---------------|
| GET /events | Aucun check de rôle | Tous | - | routes.ts:4895 |
| POST/PATCH events | ❓ Non identifié | - | - | - |

*Note: canManageEvents existe en DB mais non vérifié dans les guards*

#### Content/News (Articles)

| Endpoint/Action | Type Check | Rôles acceptés | Message erreur | Fichier:ligne |
|-----------------|------------|----------------|----------------|---------------|
| POST /articles | canManageArticles() | admin, isOwner, delegate+canManageArticles | "canManageArticles required" | routes.ts:4579-4581 |
| PATCH /articles/:id | canManageArticles() | admin, isOwner, delegate+canManageArticles | "Permission denied" | routes.ts:4660-4667 |
| DELETE /articles/:id | canManageArticles() | admin, isOwner, delegate+canManageArticles | "Permission denied" | routes.ts:4722-4729 |
| Image upload | canManageArticles() | admin, isOwner, delegate+canManageArticles | "Permission denied" | routes.ts:5650, 5682 |

#### Collections (Fundraising)

| Endpoint/Action | Type Check | Rôles acceptés | Message erreur | Fichier:ligne |
|-----------------|------------|----------------|----------------|---------------|
| POST /collections | role === "admin" OR delegate+canManageCollections | admin, delegate+permission | "Admin or delegate with canManageCollections" | routes.ts:7405-7409 |
| PATCH /collections/:id | role === "admin" OR delegate+canManageCollections | admin, delegate+permission | "Admin or delegate with canManageCollections" | routes.ts:7940-7944 |
| DELETE /collections/:id | role === "admin" OR delegate+canManageCollections | admin, delegate+permission | "Admin or delegate with canManageCollections" | routes.ts:8008-8012 |
| Activate/Deactivate | role === "admin" | admin uniquement | "Admin role required" | routes.ts:8058-8060 |

#### Payments/Stripe Connect

| Endpoint/Action | Type Check | Rôles acceptés | Message erreur | Fichier:ligne |
|-----------------|------------|----------------|----------------|---------------|
| POST /payments/connect-community | getMembershipForAuth + role === "admin" | admin uniquement | "Forbidden - Admin role required" | routes.ts:7165-7174 |

#### Messaging

| Endpoint/Action | Type Check | Rôles acceptés | Message erreur | Fichier:ligne |
|-----------------|------------|----------------|----------------|---------------|
| - | ❓ Non identifié | - | - | - |

*Note: canManageMessages existe en DB mais non vérifié dans les guards*

#### Membership Plans

| Endpoint/Action | Type Check | Rôles acceptés | Message erreur | Fichier:ligne |
|-----------------|------------|----------------|----------------|---------------|
| GET/POST/PATCH plans | isCommunityAdmin() | isOwner, admin, super_admin | "Forbidden - Admin role required" | routes.ts:8150-8162 |

#### Admin Management

| Endpoint/Action | Type Check | Rôles acceptés | Message erreur | Fichier:ligne |
|-----------------|------------|----------------|----------------|---------------|
| POST /admins (invite) | role === "admin" | admin uniquement | "Admin role required" | routes.ts:8695-8696 |
| GET /admins | role === "admin" | admin uniquement | "Admin role required" | routes.ts:8726-8727 |
| DELETE /admins/:id | role === "admin" | admin uniquement | "Admin role required" | routes.ts:8756-8757 |

#### Tags Management

| Endpoint/Action | Type Check | Rôles acceptés | Message erreur | Fichier:ligne |
|-----------------|------------|----------------|----------------|---------------|
| POST/PATCH/DELETE tags | role === "admin" OR role === "delegate" | admin, delegate | "Admin or delegate role required" | routes.ts:8818-8819 |

#### Enrollment Requests

| Endpoint/Action | Type Check | Rôles acceptés | Message erreur | Fichier:ligne |
|-----------------|------------|----------------|----------------|---------------|
| GET/Approve/Reject requests | admin OR delegate OR isOwner | admin, delegate, isOwner | "Admin, owner, or delegate role required" | routes.ts:8480-8485 |

---

## 4. Matrice Rôle → Privilèges Observés

| Domaine | member | delegate | delegate+perm | admin | isOwner |
|---------|--------|----------|---------------|-------|---------|
| Community Settings | ❌ | ❌ | ❌ | ✅ | ✅ |
| Members Management | ❌ | ❌ | ✅ (canManageMembers) | ✅ | ✅ |
| Sections | ? | ? | ? | ? | ? |
| Events (read) | ✅ | ✅ | ✅ | ✅ | ✅ |
| Events (write) | ? | ? | ? | ? | ? |
| Articles | ❌ | ❌ | ✅ (canManageArticles) | ✅ | ✅ |
| Collections | ❌ | ❌ | ✅ (canManageCollections) | ✅ | ❓* |
| Stripe Connect | ❌ | ❌ | ❌ | ✅ | ❓** |
| Membership Plans | ❌ | ❌ | ❌ | ✅ | ✅ |
| Admin Management | ❌ | ❌ | ❌ | ✅ | ❓** |
| Tags | ❌ | ✅ | ✅ | ✅ | ❓** |
| Enrollment Requests | ❌ | ✅ | ✅ | ✅ | ✅ |
| Messaging | ? | ? | ? | ? | ? |

**Légende:**
- ✅ = Autorisé
- ❌ = Refusé
- ? = Pas de check identifié
- ❓* = isOwner non vérifié (check strict `role === "admin"`)
- ❓** = isOwner potentiellement exclu car check `role === "admin"` uniquement

---

## 5. Incohérences & Risques

### 5.1 Incohérence critique: isOwner exclu de certaines actions admin

| Endpoint | Problème | Risque |
|----------|----------|--------|
| POST /payments/connect-community | Check `role === "admin"` strict | isOwner avec role="admin" OK, mais isOwner seul sans role="admin" = 403 |
| POST /admins (invite) | Check `role === "admin"` strict | Idem |
| GET/DELETE /admins | Check `role === "admin"` strict | Idem |
| Collections activate/deactivate | Check `role === "admin"` strict | Idem |

**Root cause:** Ces routes ne passent pas par `isCommunityAdmin()` qui gère le flag `isOwner`.

### 5.2 Permissions delegate non utilisées

| Permission | Définie en DB | Utilisée en guard |
|------------|---------------|-------------------|
| canManageEvents | ✅ | ❌ |
| canManageMessages | ✅ | ❌ |
| canScanPresence | ✅ | ❌ |

**Risque:** Dette technique - les permissions existent mais ne protègent rien.

### 5.3 Checks dispersés (non centralisés)

Multiples patterns de vérification:
- `isCommunityAdmin(membership)` - centralisé ✅
- `membership.role === "admin"` - décentralisé ⚠️
- `membership.role === "admin" || membership.role === "delegate"` - décentralisé ⚠️
- `membership.isOwner || membership.role === "admin"` - mix ⚠️

### 5.4 Valeurs de rôle fantômes

Le code vérifie parfois `role === "super_admin"` ou `role === "owner"` alors que ces valeurs ne sont PAS dans le set validé `['member', 'admin', 'delegate']`.

| Valeur | Définie en validation | Utilisée en check |
|--------|----------------------|-------------------|
| `super_admin` | ❌ | ✅ (routes.ts:104, 2130, 2143) |
| `owner` | ❌ | ✅ (routes.ts:104) |

**Risque:** Code mort ou legacy non nettoyé.

---

## 6. Recommandations Minimales (5 max)

1. **Uniformiser les checks admin** — Remplacer tous les `role === "admin"` par `isCommunityAdmin(membership)` pour inclure systématiquement `isOwner`.

2. **Nettoyer les valeurs fantômes** — Supprimer les checks pour `super_admin` et `owner` dans `role` (ils n'existent pas dans le set validé).

3. **Implémenter les guards manquants** — Ajouter des checks pour `canManageEvents`, `canManageMessages`, `canScanPresence` ou supprimer ces colonnes.

4. **Documenter le modèle cible** — Créer un document de référence définissant clairement quels rôles ont accès à quoi.

5. **Centraliser les guards** — Créer des helpers dédiés par domaine (`canManageCollections()`, `canManageEvents()`) similaires à `canManageArticles()`.

---

## Annexe: Fichiers Clés

| Fichier | Contenu |
|---------|---------|
| `shared/schema.ts` | Définition des enums et colonnes de rôles |
| `server/routes.ts` | Tous les guards et checks de permissions |
| `server/storage.ts` | Opérations CRUD (isOwner handling) |

---

*Fin de l'audit — Aucun code modifié*
