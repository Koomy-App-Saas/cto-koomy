# ÉTAT DES RÔLES ET PRIVILÈGES — Audit Interne

**Date :** 25 janvier 2026  
**Version :** 1.0  
**Périmètre :** Modèle RBAC, guards backend, administration des rôles

---

## 1. SYNTHÈSE EXÉCUTIVE

### Vue d'ensemble
Koomy implémente un système RBAC (Role-Based Access Control) à **deux niveaux** :
- **Niveau Communauté (actif Phase 3)** : Owner (isOwner=true) → Admin (role="admin") → Member (role="member")
- **Niveau Plateforme SaaS** : platform_super_admin → platform_support → platform_commercial

**⚠️ Note importante :** Le champ `role` stocke uniquement 3 valeurs actives : `"member"` | `"admin"` | `"delegate"`. Les rôles `manager`, `super_admin`, `owner` sont définis dans les guards mais réservés/legacy — ils ne sont pas utilisés en Phase 3.

### Constats majeurs

| Aspect | Statut | Détail |
|--------|--------|--------|
| Hiérarchie des rôles | ✅ Simplifié Phase 3 | 3 rôles actifs (admin, member, delegate), Owner via flag isOwner |
| Guards backend | ✅ Fonctionnel | `requireRole()`, `requireOwner()`, `requireAdmin()` |
| Vérification isOwner | ✅ Cohérent | `isOwner=true` OU `role IN (owner, super_admin)` |
| Quota maxAdmins | ⚠️ NON APPLIQUÉ | Middleware `requireWithinLimit("maxAdmins")` manquant sur POST /admins |
| Permissions V2 | ✅ Implémenté | 5 packages (MEMBERS, FINANCE, CONTENT, EVENTS, SETTINGS) |
| Platform Owner protection | ✅ Protégé | `isPlatformOwner=true` bloque suppression/modification |

---

## 2. MODÈLE DE DONNÉES

### 2.1. Énumérations des rôles

```typescript
// shared/schema.ts

// Rôles admin communauté (legacy + Phase 3)
export const adminRoleEnum = pgEnum("admin_role", [
  "super_admin",    // Full access (legacy)
  "support_admin",  // Read + limited write
  "finance_admin",  // Finance access
  "content_admin",  // Content management
  "admin"           // Standard admin
]);

// Rôles globaux plateforme SaaS Owner
export const userGlobalRoleEnum = pgEnum("user_global_role", [
  "platform_super_admin",   // Full SaaS access
  "platform_support",       // Support-level access
  "platform_commercial"     // Commercial operations
]);
```

### 2.2. Table userCommunityMemberships (pivot user↔communauté)

| Colonne | Type | Description |
|---------|------|-------------|
| `role` | text | "member" \| "admin" \| "delegate" (principal) |
| `adminRole` | admin_role | Sous-type si role="admin" |
| `isOwner` | boolean | true = Owner inaliénable de la communauté |
| `sectionScope` | text | "ALL" \| "SELECTED" (scope admin) |
| `sectionIds` | jsonb | IDs sections si sectionScope="SELECTED" |
| `permissions` | jsonb | Array AdminPermission[] (V2: 5 packages) |

### 2.3. Table users (administrateurs back-office)

| Colonne | Type | Description |
|---------|------|-------------|
| `globalRole` | user_global_role | null pour admins communauté, set pour platform admins |
| `isPlatformOwner` | boolean | true = root admin SaaS, non supprimable |
| `isActive` | boolean | false jusqu'à vérification email |

### 2.4. Permissions V2 (5 packages)

```typescript
export type AdminPermission = "MEMBERS" | "FINANCE" | "CONTENT" | "EVENTS" | "SETTINGS";
```

| Permission | Scope |
|------------|-------|
| `MEMBERS` | Gérer adhérents, cotisations, cartes |
| `FINANCE` | Accès données financières, collectes |
| `CONTENT` | Articles, collections, messages |
| `EVENTS` | Créer et gérer événements |
| `SETTINGS` | Configuration communauté |

---

## 3. HIÉRARCHIE DES RÔLES

### 3.1. Rôles actifs vs réservés

**Rôles actifs (Phase 3) :**
| Rôle stocké | Niveau | Description |
|-------------|--------|-------------|
| `isOwner=true` | 100 | Owner communauté (flag, pas une valeur de role) |
| `role="admin"` | 50 | Administrateur standard |
| `role="delegate"` | 20 | Délégué avec permissions limitées |
| `role="member"` | 10 | Membre standard |

**Rôles réservés/legacy (définis mais non utilisés Phase 3) :**
- `owner` (comme valeur de role) — remplacé par flag `isOwner=true`
- `super_admin` — legacy, traité comme owner si rencontré
- `manager` — réservé pour future phase

### 3.2. Niveaux numériques (guards.ts - inclut legacy)

```typescript
// Définition complète (legacy + actif)
const ROLE_HIERARCHY: Record<string, number> = {
  owner: 100,        // Legacy: traité via isOwnerRole()
  super_admin: 90,   // Legacy: traité via isOwnerRole()
  admin: 50,         // ACTIF
  manager: 30,       // Réservé
  delegate: 20,      // ACTIF
  member: 10,        // ACTIF
};
```

### 3.3. Logique de vérification Owner

```typescript
function isOwnerRole(membership: KoomyMembership): boolean {
  // Flag isOwner prend précédence absolue
  if (membership.isOwner === true) return true;
  // Legacy: roles owner/super_admin équivalents
  const role = membership.role?.toLowerCase();
  return role === "owner" || role === "super_admin";
}
```

### 3.3. Logique de vérification Admin

```typescript
function isAdminRole(membership: KoomyMembership): boolean {
  if (isOwnerRole(membership)) return true;
  const role = membership.role?.toLowerCase();
  const adminRole = membership.adminRole?.toLowerCase();
  return role === "admin" || adminRole === "admin";
}
```

---

## 4. GUARDS BACKEND

### 4.1. Middlewares disponibles (server/middlewares/guards.ts)

| Guard | Code erreur | Description |
|-------|-------------|-------------|
| `requireFirebaseAuth` | 401 auth_required | Vérifie token Firebase valide |
| `requireMembership(paramName)` | 403 membership_required | Vérifie appartenance à communauté |
| `requireRole(minRole)` | 403 insufficient_role | Vérifie niveau minimum |
| `requireOwner` | 403 insufficient_role | Vérifie isOwner=true ou role owner/super_admin |
| `requireAdmin` | 403 insufficient_role | Vérifie isAdmin() ou isOwner() |

### 4.2. Utilisation typique

```typescript
// Endpoint protégé Owner uniquement
app.post("/api/communities/:communityId/admins", 
  requireMembership("communityId"), 
  requireOwner,
  async (req, res) => { ... }
);

// Endpoint protégé Admin minimum
app.patch("/api/memberships/:id", 
  requireFirebaseAuth, 
  async (req, res) => {
    const isAdmin = callerMembership.isOwner || callerMembership.role === "admin";
    if (!isAdmin) return res.status(403).json({ error: "insufficient_role" });
    ...
  }
);
```

---

## 5. ADMINISTRATION DES RÔLES

### 5.1. Création Owner (lors création communauté)

```typescript
// server/routes.ts - POST /api/communities
const membership = await storage.createMembership({
  communityId: community.id,
  userId: user.id,
  role: "admin",
  ...
});
await storage.updateMembership(membership.id, { isOwner: true });
```

**Règle :** Le créateur de la communauté devient automatiquement Owner (isOwner=true).

### 5.2. Création Admin (POST /api/communities/:communityId/admins)

**Prérequis :** Appelant doit être Owner de la communauté.

**Processus :**
1. Validation Firebase Auth
2. Vérification membership communauté
3. Vérification `isOwner(callerMembership)` → 403 si non
4. Validation email, prénom, nom requis
5. Validation permissions[] (min 1 package)
6. Création entry users + userCommunityMemberships avec role="admin"
7. Génération claimCode pour réclamation

**⚠️ FAILLE IDENTIFIÉE :**
```typescript
// POST /api/communities/:communityId/admins
// Ligne ~4589 - AUCUN guard requireWithinLimit("maxAdmins")
app.post("/api/communities/:communityId/admins", 
  requireMembership("communityId"), 
  requireOwner,
  // MISSING: requireWithinLimit("maxAdmins")
  async (req, res) => { ... }
);
```

Le plan FREE définit `maxAdmins: 1` mais la route ne vérifie pas cette limite.

### 5.3. Modification rôle (PATCH /api/memberships/:id)

**Prérequis :** Appelant doit être Admin ou Owner de la communauté cible.

```typescript
const isAdmin = callerMembership.isOwner || callerMembership.role === "admin";
if (!isAdmin) return res.status(403).json({ error: "insufficient_role" });
```

### 5.4. Suppression Admin

La suppression passe par `PATCH /api/memberships/:id` avec `role: "member"` pour rétrograder.

**Protection Owner :** Le flag `isOwner=true` n'est jamais supprimable via cette route.

---

## 6. RÔLES PLATEFORME (SaaS Owner)

### 6.1. Vérification platform_super_admin

```typescript
// Helper function (ligne ~8079)
function verifyPlatformAdmin(userId: string) {
  const user = await storage.getUserById(userId);
  if (user.globalRole !== 'platform_super_admin') {
    return { valid: false, error: "Accès refusé - rôle platform_super_admin requis" };
  }
  return { valid: true, user };
}
```

### 6.2. Endpoints protégés platform admin

| Endpoint | Action |
|----------|--------|
| POST /api/platform/communities/:id/grant-full-access | Accorder VIP |
| POST /api/platform/communities/:id/revoke-full-access | Révoquer VIP |
| PATCH /api/platform/communities/:id/whitelabel | Modifier settings WL |
| POST /api/platform/communities/:id/create-owner-admin | Créer owner WL |
| PATCH /api/platform/communities/:id/name | Modifier nom |
| GET /api/platform/communities/:id/details | Détails complets |
| GET /api/admin/audit-logs | Logs d'audit |

### 6.3. Protection Platform Owner

```typescript
// Protection contre suppression/modification du root admin
if (targetUser?.isPlatformOwner) {
  return res.status(403).json({ error: "Cannot modify platform owner" });
}

// Protection contre dégradation super_admin → autre rôle
if (targetUser?.globalRole === 'platform_super_admin' && globalRole !== 'platform_super_admin') {
  return res.status(403).json({ error: "Cannot demote platform super admin" });
}
```

---

## 7. AFFICHAGE FRONTEND

### 7.1. AuthContext (client/src/contexts/AuthContext.tsx)

```typescript
const isAdmin = !!(user && currentMembership && currentMembership.role === "admin");
```

**Note :** Cette vérification est simplifiée et ne couvre pas tous les cas (super_admin, owner, isOwner).

### 7.2. Page Admins (client/src/pages/admin/Admins.tsx)

```typescript
// Filtrage des admins
const admins = members.filter(m => 
  m.isOwner === true || 
  m.role === "admin" || 
  m.role === "super_admin" || 
  m.role === "owner"
);
```

### 7.3. Détection super_admin dans composants

```typescript
// MemberDetails.tsx
const isSuperAdmin = currentMembership?.adminRole === "super_admin" || 
                     currentMembership?.isOwner === true;
```

### 7.4. MobileLayout admin check

```typescript
const isAdmin = currentMembership?.role === "admin" || 
                currentMembership?.adminRole !== null;
```

---

## 8. RISQUES ET RECOMMANDATIONS

### 8.1. CRITIQUE — Quota maxAdmins non appliqué

| Sévérité | Composant | Problème |
|----------|-----------|----------|
| 🔴 HAUTE | POST /api/communities/:communityId/admins | Permet création admins illimités sur plan FREE |

**Correction recommandée :**
```typescript
app.post("/api/communities/:communityId/admins", 
  requireMembership("communityId"), 
  requireOwner,
  requireWithinLimit("maxAdmins"),  // AJOUTER
  async (req, res) => { ... }
);
```

### 8.2. MOYENNE — Vérification isAdmin frontend incomplète

```typescript
// AuthContext.tsx actuel
const isAdmin = !!(user && currentMembership && currentMembership.role === "admin");

// Devrait inclure :
const isAdmin = !!(user && currentMembership && (
  currentMembership.role === "admin" ||
  currentMembership.role === "super_admin" ||
  currentMembership.role === "owner" ||
  currentMembership.isOwner === true
));
```

### 8.3. BASSE — Incohérence role vs adminRole

Le champ `adminRole` (enum) et `role` (text) créent une dualité potentiellement confuse. Le système utilise principalement `role` avec `isOwner` comme flag de priorité.

### 8.4. BASSE — Permissions V2 partiellement utilisées

Les 5 packages de permissions (MEMBERS, FINANCE, CONTENT, EVENTS, SETTINGS) sont stockés mais les guards ne vérifient pas encore ces permissions granulaires.

---

## 9. MATRICE DES PRIVILÈGES

### 9.1. Niveau Communauté (Phase 3 — Rôles actifs uniquement)

| Action | Member | Delegate | Admin | Owner (isOwner) |
|--------|--------|----------|-------|-----------------|
| Voir contenu public | ✅ | ✅ | ✅ | ✅ |
| Voir membres section | ❌ | ✅ (scope) | ✅ | ✅ |
| Créer articles | ❌ | ✅* | ✅ | ✅ |
| Gérer événements | ❌ | ✅* | ✅ | ✅ |
| Scanner présence | ❌ | ✅* | ✅ | ✅ |
| Modifier membres | ❌ | ✅ (scope)* | ✅ | ✅ |
| Voir finances | ❌ | ❌ | ✅ | ✅ |
| Gérer admins | ❌ | ❌ | ❌ | ✅ |
| Modifier plan | ❌ | ❌ | ❌ | ✅ |
| Supprimer communauté | ❌ | ❌ | ❌ | ✅ |

*\* Delegate: Permissions contrôlées par flags `canManageArticles`, `canManageEvents`, `canManageMembers`, `canScanPresence`*

**Note :** Le rôle `Manager` est réservé pour une future phase et n'apparaît pas dans cette matrice.

### 9.2. Niveau Plateforme

| Action | platform_commercial | platform_support | platform_super_admin |
|--------|---------------------|------------------|----------------------|
| Voir liste communautés | ✅ | ✅ | ✅ |
| Voir détails communauté | ❌ | ✅ | ✅ |
| Modifier communauté | ❌ | ❌ | ✅ |
| Accorder Full Access VIP | ❌ | ❌ | ✅ |
| Créer owner White Label | ❌ | ❌ | ✅ |
| Voir audit logs | ❌ | ❌ | ✅ |
| Gérer platform admins | ❌ | ❌ | ✅ |

---

## 10. FICHIERS SOURCES AUDITÉS

| Fichier | Contenu |
|---------|---------|
| `shared/schema.ts` | Définition enums, tables, types |
| `server/middlewares/guards.ts` | Guards requireRole, requireOwner, requireAdmin |
| `server/routes.ts` | Endpoints CRUD avec vérifications rôles |
| `client/src/contexts/AuthContext.tsx` | État authentification et currentMembership |
| `client/src/pages/admin/Admins.tsx` | UI gestion administrateurs |
| `server/middlewares/attachAuthContext.ts` | Construction authContext avec memberships |

---

## 11. CONCLUSION

Le système RBAC Koomy est fonctionnel avec une hiérarchie claire (Owner > Admin > Member) et des protections adéquates pour les opérations sensibles. La principale lacune identifiée est l'absence de vérification du quota `maxAdmins` lors de la création d'administrateurs, permettant théoriquement de dépasser les limites du plan FREE.

Les permissions V2 (5 packages) représentent une évolution vers un contrôle plus granulaire mais ne sont pas encore pleinement exploitées dans les guards backend.

---

*Rapport généré automatiquement — Audit interne Koomy*
