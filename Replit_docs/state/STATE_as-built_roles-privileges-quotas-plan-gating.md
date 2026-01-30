# ÉTAT AS-BUILT : Rôles, Privilèges, Quotas et Plan Gating

**Date**: 2026-01-25  
**Version**: 1.0  
**Classification**: État réel du système  
**Statut**: AUDIT COMPLET

---

## Executive Summary

Ce document décrit l'état réel (as-built) du système de gestion des rôles, privilèges, quotas et plan gating de la plateforme Koomy. Il identifie les écarts entre la conception et l'implémentation effective.

### Résumé des Gaps Critiques

| ID | Gap | Sévérité | Fichier |
|----|-----|----------|---------|
| GAP-001 | `maxAdmins` limit NOT enforced on POST /api/communities/:communityId/admins | **P0 CRITIQUE** | server/routes.ts:4589-4684 |
| GAP-002 | Permissions V2 `can()` function defined but NEVER invoked in routes | **P1 MAJEUR** | server/routes.ts:221-246 |
| GAP-003 | Tags management has NO plan/capability gating (premium feature exposed to all) | **P2 MOYEN** | server/routes.ts:11080-11446 |
| GAP-004 | No frontend FeatureGate/PlanGate component exists | **P2 MOYEN** | client/src/* |
| GAP-005 | No ownership transfer function exists (single point of failure) | **P2 MOYEN** | server/storage.ts, server/routes.ts |

---

## A. Hiérarchie des Rôles

### A.1 Rôles Communauté (Tenant-Level)

**Fichier**: `server/middlewares/guards.ts:46-53`

```typescript
const ROLE_HIERARCHY: Record<string, number> = {
  owner: 100,
  super_admin: 90,
  admin: 50,
  manager: 30,
  delegate: 20,
  member: 10,
};
```

| Rôle | Niveau | Caractéristiques | Fichier Référence |
|------|--------|------------------|-------------------|
| **Owner** | 100 | `isOwner=true`, ne peut être supprimé, création d'admins | shared/schema.ts:551 |
| **Super Admin** | 90 | Réservé phases futures (non actif) | guards.ts:15-16 |
| **Admin** | 50 | Accès backoffice, permissions V2, scope sections | shared/schema.ts:523, 555-556 |
| **Manager** | 30 | Réservé phases futures | guards.ts:50 |
| **Delegate** | 20 | Permissions legacy can*, sectionScope | shared/schema.ts:544-554 |
| **Member** | 10 | Accès membre mobile uniquement | guards.ts:52 |

### A.2 Rôles Plateforme (Platform-Level)

**Fichier**: `shared/schema.ts:17`

```typescript
export const userGlobalRoleEnum = pgEnum("user_global_role", [
  "platform_super_admin",  // Koomy team super admin
  "platform_support",      // Koomy support agent
  "platform_commercial"    // Koomy commercial agent
]);
```

| Rôle | Description | Protection | Fichier |
|------|-------------|------------|---------|
| `platform_super_admin` | Accès admin plateforme complet | server/routes.ts:4197, 4463, 8088 |
| `platform_support` | Agent support | Non implémenté |
| `platform_commercial` | Agent commercial | Non implémenté |
| `isPlatformOwner` | Root admin plateforme, ne peut être supprimé | shared/schema.ts:383, storage.ts:9199-9238 |

### A.3 Détermination du Rôle

**Fichiers**: `server/middlewares/guards.ts:60-71`

```typescript
function isOwnerRole(membership: KoomyMembership): boolean {
  if (membership.isOwner === true) return true;
  const role = membership.role?.toLowerCase();
  return role === "owner" || role === "super_admin";
}

function isAdminRole(membership: KoomyMembership): boolean {
  if (isOwnerRole(membership)) return true;
  const role = membership.role?.toLowerCase();
  const adminRole = membership.adminRole?.toLowerCase();
  return role === "admin" || adminRole === "admin";
}
```

---

## B. Guards et Middlewares d'Authentification/Autorisation

### B.1 Middlewares Disponibles

**Fichiers**: `server/middlewares/guards.ts`, `server/lib/usageLimitsGuards.ts`, `server/lib/subscriptionGuards.ts`

| Middleware | Rôle | Fichier:Ligne |
|------------|------|---------------|
| `requireFirebaseAuth` | Vérifie auth Firebase | guards.ts:73-88 |
| `requireMembership("communityId")` | Vérifie appartenance communauté | guards.ts:90-125 |
| `requireRole("admin")` | Vérifie niveau rôle minimum | guards.ts:129-158 |
| `requireOwner` | Vérifie statut Owner | guards.ts:160-173 |
| `requireAdmin` | Vérifie statut Admin | guards.ts:175-188 |
| `requireWithinLimit(fn, "maxMembers")` | Vérifie quota membres | usageLimitsGuards.ts:195-258 |
| `requireCapability(fn, "capability")` | Vérifie capability plan | usageLimitsGuards.ts:260-321 |
| `requireActiveForMoney(fn)` | Bloque payments en trial | usageLimitsGuards.ts:323-383 |
| `requireBillingInGoodStanding(fn)` | Bloque si past_due/canceled | subscriptionGuards.ts:386-450 |

### B.2 Couverture des Endpoints par Guards

| Endpoint Pattern | Guards Appliqués | Statut |
|------------------|------------------|--------|
| `POST /api/members/join` | `requireWithinLimit("maxMembers")` | ✅ Implémenté (routes.ts:2467-2478) |
| `POST /api/news` | `requireBillingInGoodStanding` | ✅ Implémenté (routes.ts:6705-6707) |
| `POST /api/events` | `requireBillingInGoodStanding` | ✅ Implémenté (routes.ts:7226-7228) |
| `POST /api/collections` | `requireBillingInGoodStanding` | ✅ Implémenté (routes.ts:9982-9984) |
| `POST /api/communities/:id/admins` | `requireMembership`, `requireOwner` | ⚠️ INCOMPLET - maxAdmins NOT checked |
| `POST /api/communities/:id/tags` | `isBackofficeAdmin` check | ⚠️ INCOMPLET - no plan gating |

---

## C. Système de Permissions V2

### C.1 Définition des Packages

**Fichier**: `shared/schema.ts:561-563`

```typescript
export type AdminPermission = "MEMBERS" | "FINANCE" | "CONTENT" | "EVENTS" | "SETTINGS";
export const ADMIN_PERMISSIONS: AdminPermission[] = ["MEMBERS", "FINANCE", "CONTENT", "EVENTS", "SETTINGS"];
```

| Package | Périmètre Fonctionnel |
|---------|----------------------|
| `MEMBERS` | Gestion des membres, inscriptions, tags membres |
| `FINANCE` | Cotisations, paiements, exports financiers |
| `CONTENT` | Articles, actualités, publications |
| `EVENTS` | Événements, inscriptions, présences |
| `SETTINGS` | Paramètres communauté, sections, configuration |

### C.2 Fonction can() - RBAC Check

**Fichier**: `server/routes.ts:221-246`

```typescript
function can(
  membership: MembershipForRoleCheck, 
  permission: AdminPermission, 
  sectionId?: string | null
): boolean {
  if (!membership) return false;
  if (isOwner(membership)) return true;  // OWNER bypass
  if (!isBackofficeAdmin(membership)) return false;
  
  const permissions = membership.permissions as AdminPermission[] | undefined;
  if (!permissions || !permissions.includes(permission)) return false;
  
  if (sectionId) return canAccessSection(membership, sectionId);
  return true;
}
```

### C.3 Utilisation Effective dans le Code

**CONSTAT CRITIQUE (GAP-002)**:

Recherche effectuée: `grep -n "can\(.*MEMBERS" server/routes.ts`  
**Résultat: 0 occurrences**

La fonction `can()` est définie (lignes 221-246) mais **n'est JAMAIS invoquée** dans les routes.

Les vérifications RBAC actuelles utilisent:
- `isBackofficeAdmin()` - vérifie simplement si admin (routes.ts:11114)
- `isOwner()` - vérifie ownership (routes.ts:4642)

**Impact**: Les permissions V2 (MEMBERS, FINANCE, CONTENT, EVENTS, SETTINGS) sont stockées mais **non appliquées**.

### C.4 Permissions Legacy (Delegate)

**Fichier**: `shared/schema.ts:544-550`

```typescript
canManageArticles: boolean("can_manage_articles").default(true),
canManageEvents: boolean("can_manage_events").default(true),
canManageCollections: boolean("can_manage_collections").default(true),
canManageMessages: boolean("can_manage_messages").default(true),
canManageMembers: boolean("can_manage_members").default(true),
canScanPresence: boolean("can_scan_presence").default(true),
```

**Statut**: Legacy, neutralisé V1 (commentaire routes.ts:11112)

---

## D. Quotas et Limites

### D.1 Définition des Limites par Plan

**Fichier**: `server/lib/planLimits.ts:25-31`

```typescript
const DEFAULT_LIMITS: Record<string, { maxMembers: number | null; maxAdmins: number | null }> = {
  free: { maxMembers: 50, maxAdmins: 1 },
  plus: { maxMembers: 500, maxAdmins: 3 },
  pro: { maxMembers: 5000, maxAdmins: 10 },
  enterprise: { maxMembers: null, maxAdmins: null },  // Unlimited
  whitelabel: { maxMembers: null, maxAdmins: null },  // Unlimited
};
```

### D.2 Bypass Enterprise/WhiteLabel

**Fichier**: `server/lib/usageLimitsGuards.ts:106-109`

```typescript
if (effectivePlan.isEnterprise || effectivePlan.isWhiteLabel) {
  return { allowed: true };
}
```

**Critères bypass** (planLimits.ts:199, 277):
- `accountType === "GRAND_COMPTE"` → isEnterprise = true
- `whiteLabel === true` → isWhiteLabel = true

### D.3 Couverture des Limites

| Limite | Endpoints Protégés | Endpoints NON Protégés |
|--------|-------------------|----------------------|
| `maxMembers` | POST /api/members/join (routes.ts:2467) | - |
| `maxAdmins` | **AUCUN** | POST /api/communities/:id/admins (routes.ts:4589) |

**CONSTAT CRITIQUE (GAP-001)**:

Le endpoint `POST /api/communities/:communityId/admins` (lignes 4589-4684):
- ✅ Vérifie `requireMembership("communityId")`
- ✅ Vérifie `requireOwner`
- ❌ **NE VÉRIFIE PAS** `requireWithinLimit("maxAdmins")`

Un club FREE peut créer plus de 1 admin. Un club PLUS peut créer plus de 3 admins.

### D.4 Fonctions de Comptage

**Fichier**: `server/lib/usageLimitsGuards.ts:36-63`

```typescript
export async function getMemberCount(communityId: string): Promise<number>
export async function getAdminCount(communityId: string): Promise<number>
```

La fonction `getAdminCount` compte les rôles "admin" ET "delegate".

---

## E. Plan Gating (Capabilities)

### E.1 Définition des Capabilities

**Fichier**: `shared/schema.ts:193-221`

```typescript
export interface PlanCapabilities {
  qrCard?: boolean;           // QR code on member cards
  dues?: boolean;             // Cotisations/membership fees
  messaging?: boolean;        // Messaging between members/admins
  events?: boolean;           // Events with registrations
  analytics?: boolean;        // Basic analytics
  advancedAnalytics?: boolean; // Advanced analytics
  exportData?: boolean;       // Export data feature
  apiAccess?: boolean;        // API access
  multiAdmin?: boolean;       // Multiple admins with roles
  unlimitedSections?: boolean; // Unlimited sections/regions
  customization?: boolean;    // Advanced customization
  // ... + event-specific capabilities
}
```

### E.2 Capabilities par Plan

**Fichier**: `server/lib/planLimits.ts:33-119`

| Capability | FREE | PLUS | PRO | ENTERPRISE |
|------------|------|------|-----|------------|
| qrCard | ✅ | ✅ | ✅ | ✅ |
| dues | ❌ | ✅ | ✅ | ✅ |
| messaging | ✅ | ✅ | ✅ | ✅ |
| events | ✅ | ✅ | ✅ | ✅ |
| analytics | ❌ | ✅ | ✅ | ✅ |
| advancedAnalytics | ❌ | ❌ | ✅ | ✅ |
| exportData | ❌ | ✅ | ✅ | ✅ |
| apiAccess | ❌ | ❌ | ✅ | ✅ |
| multiAdmin | ❌ | ✅ | ✅ | ✅ |
| unlimitedSections | ❌ | ❌ | ✅ | ✅ |
| customization | ❌ | ✅ | ✅ | ✅ |
| prioritySupport | ❌ | ❌ | ✅ | ✅ |

### E.3 Utilisation de requireCapability

**Recherche**: `grep -n "requireCapability" server/routes.ts`

**Résultat**: Import uniquement (ligne 55), aucune utilisation dans les routes.

**CONSTAT (GAP-003)**: Les capabilities sont définies mais `requireCapability` n'est appliqué nulle part.

### E.4 Tags - Feature Non Gatée

**Fichier**: `server/routes.ts:11099-11139`

```typescript
app.post("/api/communities/:communityId/tags", async (req, res) => {
  // V1 HARDENING: Only OWNER/ADMIN can manage tags (delegate neutralized)
  const membership = await storage.getMembership(userId, communityId);
  if (!membership || !isBackofficeAdmin(membership)) {
    return res.status(403).json({ error: "Permission insuffisante", code: "CAPABILITY_DENIED" });
  }
  // NO capability check for tags (premium feature?)
});
```

Tags est probablement une feature premium mais accessible à tous les plans.

---

## F. UX Blocage Frontend

### F.1 Composants Existants

| Composant | Fichier | Fonction |
|-----------|---------|----------|
| `QuotaLimitModal` | client/src/components/QuotaLimitModal.tsx | Affiche limite atteinte + CTA upgrade |
| `SaasStatusBanner` | client/src/components/SaasStatusBanner.tsx | Bannière warning impayé (NON intégré) |
| `SaasBlockedPage` | client/src/components/SaasBlockedPage.tsx | Écran blocage SUSPENDU/RESILIE (NON intégré) |

### F.2 QuotaLimitModal

**Fichier**: `client/src/components/QuotaLimitModal.tsx`

```typescript
interface QuotaLimitModalProps {
  isOpen: boolean;
  onClose: () => void;
  currentPlanCode: PlanCode;
  limitType: "members" | "admins";
  currentCount: number;
  maxLimit: number | null;
}
```

Features:
- Affiche usage actuel vs limite
- Propose upgrade vers plan supérieur
- CTA vers `/admin/billing` ou contact équipe (enterprise)

### F.3 Hook useQuotaCheck

**Fichier**: `client/src/components/QuotaLimitModal.tsx:113-128`

```typescript
export function useQuotaCheck() {
  const checkQuota = async (communityId: string) => {
    const response = await fetch(`/api/communities/${communityId}/quota`);
    return await response.json();
  };
  return { checkQuota };
}
```

### F.4 Feature Gate Component

**CONSTAT (GAP-004)**: 

Recherche: `grep -r "FeatureGate\|PlanGate\|planRequired" client/src/`  
**Résultat: 0 occurrences**

Aucun composant générique `<FeatureGate capability="dues">` n'existe pour:
- Masquer features non disponibles
- Afficher badge "Pro" sur features payantes
- Bloquer accès avec modal upgrade

---

## G. Protection Owner

### G.1 Suppression Impossible

**Fichier**: `server/storage.ts:1023-1030`

```typescript
async deleteMembership(id: string): Promise<void> {
  // Check if membership is an owner - owners cannot be deleted
  const [membership] = await db.select().from(userCommunityMemberships)
    .where(eq(userCommunityMemberships.id, id));
  
  if (membership?.isOwner) {
    throw new OwnerAdminDeletionError();
  }
  // ... delete
}
```

### G.2 Transfert de Propriété

**CONSTAT (GAP-005)**:

Recherche: `grep -rn "transferOwner\|transfer.*owner" server/`  
**Résultat: 0 occurrences**

Aucune fonction de transfert de propriété n'existe.

**Impact**: Si l'owner quitte ou perd accès, la communauté est orpheline.

---

## H. Billing Guards

### H.1 requireBillingInGoodStanding

**Fichier**: `server/lib/subscriptionGuards.ts:386-450`

Bloque si `subscriptionStatus` est:
- `past_due`
- `canceled`
- `trialing` (avec bypass config)

**Endpoints protégés**:
- POST /api/news
- POST /api/events  
- POST /api/collections
- POST /api/communities/:id/news

### H.2 Statuts Billing Acceptés

**Fichier**: `server/lib/subscriptionGuards.ts:332-341`

```typescript
export function isBillingInGoodStanding(status: SubscriptionStatus): boolean {
  return status === "active" || status === "trialing";
}
```

---

## I. Synthèse des Gaps

### I.1 Gaps P0 - Critiques

| ID | Description | Action Requise |
|----|-------------|----------------|
| GAP-001 | maxAdmins NOT enforced | Ajouter `requireWithinLimit(fn, "maxAdmins")` sur POST /api/communities/:id/admins |

### I.2 Gaps P1 - Majeurs

| ID | Description | Action Requise |
|----|-------------|----------------|
| GAP-002 | Permissions V2 `can()` non utilisée | Intégrer checks RBAC permissions V2 dans routes |

### I.3 Gaps P2 - Moyens

| ID | Description | Action Requise |
|----|-------------|----------------|
| GAP-003 | Tags sans plan gating | Définir capability "tags" et appliquer requireCapability |
| GAP-004 | Pas de FeatureGate frontend | Créer composant `<PlanGate capability="X">` |
| GAP-005 | Pas de transfert ownership | Implémenter endpoint POST /api/communities/:id/transfer-ownership |

---

## J. Fichiers Référencés

| Fichier | Contenu |
|---------|---------|
| server/middlewares/guards.ts | Middlewares auth/role guards |
| server/lib/usageLimitsGuards.ts | Guards quotas et capabilities |
| server/lib/planLimits.ts | Définition limites par plan |
| server/lib/subscriptionGuards.ts | Guards billing/subscription |
| server/routes.ts | Définition endpoints API |
| server/storage.ts | Layer données, protection owner |
| shared/schema.ts | Schéma DB, types, permissions |
| client/src/components/QuotaLimitModal.tsx | Modal blocage quota |

---

## K. Rôle Delegate - Analyse Complète

### K.1 État Actuel: NEUTRALISÉ mais CRÉABLE

Le rôle "delegate" est dans un état de **gel fonctionnel** :
- **Créable**: OUI, via API et UI mobile
- **Privilèges actifs**: NON, neutralisé dans le code

### K.2 Points de Création API

| Endpoint | Fichier:Ligne | Statut |
|----------|--------------|--------|
| `POST /api/communities/:communityId/delegates` | server/routes.ts:7724-7771 | ✅ ACTIF |
| `PATCH /api/memberships/:id` avec role="delegate" | server/routes.ts:5214, 5257 | ✅ ACCEPTÉ dans VALID_ROLES |

**Code création delegate** (routes.ts:7751-7764):
```typescript
const delegate = await storage.createMembership({
  communityId,
  memberId,
  displayName,
  email,
  role: role || "delegate",  // Role delegate créé
  status: "active",
  canManageArticles: true,   // Permissions legacy actives
  canManageEvents: true,
  canManageCollections: true,
  canManageMessages: true,
  canManageMembers: false,
  canScanPresence: true
});
```

### K.3 Points de Création UI

**Fichier**: `client/src/pages/mobile/admin/Settings.tsx`

| Élément | Ligne | Description |
|---------|-------|-------------|
| Bouton "Nouveau délégué" | 290 | `data-testid="button-new-delegate"` |
| Input nom | 236 | `data-testid="input-delegate-name"` |
| Input email | 248 | `data-testid="input-delegate-email"` |
| Appel API | 76-82 | POST vers `/api/communities/${communityId}/delegates` |
| Liste delegates | 53 | Filtre `role === "admin" \|\| role === "delegate"` |

### K.4 Neutralisation dans le Code

La neutralisation est documentée par des commentaires explicites:

| Fichier:Ligne | Contexte | Commentaire |
|---------------|----------|-------------|
| routes.ts:121 | Hiérarchie | `"delegate" (no backoffice access)` |
| routes.ts:123 | Documentation | `Legacy roles (delegate, manager...) are NEUTRALIZED` |
| routes.ts:149 | isBackofficeAdmin | `"delegate" role is NEUTRALIZED - does NOT grant admin access` |
| routes.ts:154 | Check | `Only "admin" role grants backoffice access (NOT delegate!)` |
| routes.ts:525 | Articles | `delegate role is NEUTRALIZED - only OWNER/ADMIN can manage articles` |
| routes.ts:7235 | Events | `V1 HARDENING: Only OWNER/ADMIN can create events (delegate neutralized)` |
| routes.ts:10011 | Collections | `V1 HARDENING: Only OWNER/ADMIN can manage collections (delegate neutralized)` |
| routes.ts:11112 | Tags | `V1 HARDENING: Only OWNER/ADMIN can manage tags (delegate neutralized)` |

### K.5 Fonction isBackofficeAdmin - Clé de la Neutralisation

**Fichier**: `server/routes.ts:149-155`

```typescript
function isBackofficeAdmin(membership: MembershipForRoleCheck): boolean {
  if (!membership) return false;
  if (isOwner(membership)) return true;
  // Only "admin" role grants backoffice access (NOT delegate!)
  return membership.role === "admin";  // delegate EXCLUS
}
```

### K.6 Comptage Delegate comme Admin

**Fichier**: `server/lib/usageLimitsGuards.ts:49-63`

```typescript
export async function getAdminCount(communityId: string): Promise<number> {
  const [result] = await db.select({ count: count() })
    .from(userCommunityMemberships)
    .where(and(
      eq(userCommunityMemberships.communityId, communityId),
      or(
        eq(userCommunityMemberships.role, "admin"),
        eq(userCommunityMemberships.role, "delegate")  // Compté dans quotas!
      )
    ));
  return result?.count || 0;
}
```

**Anomalie**: Les delegates comptent vers la limite `maxAdmins` mais n'ont PAS les privilèges admin.

### K.7 Stratégie "Freeze" Delegate (Sans Migration)

**Objectif**: Geler la création de nouveaux delegates sans migration DB ni suppression des existants.

#### Option A: Block API (Recommandé - 1 ligne)

```typescript
// server/routes.ts:7724 - Ajouter au début du handler
app.post("/api/communities/:communityId/delegates", async (req, res) => {
  return res.status(410).json({ 
    error: "Le rôle délégué est désactivé. Utilisez le rôle Admin avec permissions.",
    code: "DELEGATE_ROLE_DEPRECATED"
  });
  // ... reste du code inchangé
});
```

#### Option B: Retirer de VALID_ROLES (Impact PATCH)

```typescript
// server/routes.ts:5214
const VALID_ROLES = new Set(['member', 'admin']);  // Retirer 'delegate'
```

#### Option C: Masquer UI Mobile

```typescript
// client/src/pages/mobile/admin/Settings.tsx
// Remplacer ligne 290 par:
{/* FREEZE: Delegate role deprecated */}
{false && (
  <Button data-testid="button-new-delegate">Nouveau délégué</Button>
)}
```

#### Recommandation Freeze

| Action | Impact | Effort |
|--------|--------|--------|
| Block POST /api/.../delegates | Empêche création API | 1 ligne |
| Retirer "delegate" de VALID_ROLES | Empêche changement rôle vers delegate | 1 mot |
| Masquer bouton UI | Empêche création UI | 1 condition |

**Total**: 3 modifications simples, **0 migration DB**.

Les delegates existants conservent leur membership mais restent neutralisés.

---

## L. SaaS Owner Platform - Analyse Rôles

### L.1 Rôles Plateforme Définis

**Fichier**: `shared/schema.ts:17, 382`

```typescript
export const userGlobalRoleEnum = pgEnum("user_global_role", [
  "platform_super_admin",  // Koomy team - full platform access
  "platform_support",      // Koomy support agent
  "platform_commercial"    // Koomy commercial agent
]);

// Dans users table:
globalRole: userGlobalRoleEnum("global_role")  // null = community admin, set = platform admin
```

### L.2 Modèle Actuel: ROLE-BASED (Non Privileges)

Le système SaaS Owner utilise un modèle **basé sur les rôles**, NON sur les privilèges.

**Pattern vérifié** (routes.ts):
```typescript
if (user.globalRole !== 'platform_super_admin') {
  return res.status(403).json({ error: "Platform admin access required" });
}
```

| Fichier:Ligne | Contexte | Vérification |
|---------------|----------|--------------|
| routes.ts:4197 | Platform login | `globalRole !== 'platform_super_admin'` |
| routes.ts:4463 | Audit logs | `globalRole !== 'platform_super_admin'` |
| routes.ts:8088 | Full access grant | `globalRole !== 'platform_super_admin'` |
| routes.ts:9204 | Role change | `globalRole === 'platform_super_admin'` protection |

### L.3 Différenciation des Rôles - NON Implémentée

**Rôles support/commercial**: Définis mais **NON utilisés**.

Recherche: `grep -n "platform_support\|platform_commercial" server/routes.ts`  
**Résultat**: 0 occurrences dans les routes (seulement dans schéma).

**Constat**: Tous les endpoints `/api/platform/*` vérifient uniquement `platform_super_admin`.

### L.4 Protection Platform Owner

**Fichier**: `server/routes.ts:9199-9238`

```typescript
// Cannot demote platform owner
if (targetUser?.isPlatformOwner) {
  return res.status(403).json({ error: "Cannot modify platform owner" });
}
// Cannot demote last platform_super_admin
if (targetUser?.globalRole === 'platform_super_admin' && globalRole !== 'platform_super_admin') {
  // Vérification qu'il reste d'autres super admins
}
```

### L.5 Endpoints Platform Couverts

**42 endpoints** sous `/api/platform/*` (routes.ts):

| Catégorie | Endpoints | Guard Actuel |
|-----------|-----------|--------------|
| Auth | login, validate-session, renew-session, logout | Session-based |
| Users | GET/POST /users, PATCH /users/:id/role, DELETE | platform_super_admin |
| Communities | all-communities, :id/details, :id/full-access | platform_super_admin |
| Metrics | metrics, revenue-history, revenue-analytics | platform_super_admin |
| Health | health/summary, health/series | platform_super_admin |
| Analytics | top-by-members, at-risk, member-growth, etc. | platform_super_admin |
| Tickets | GET/PATCH tickets, responses | platform_super_admin |
| Payments | analytics, pending, failed | platform_super_admin |

### L.6 Comparaison avec Back-Office (Communauté)

| Aspect | Back-Office (Communauté) | SaaS Owner Platform |
|--------|-------------------------|---------------------|
| **Modèle** | Role + Permissions V2 (MEMBERS, FINANCE...) | Role seul (globalRole) |
| **Granularité** | 5 packages permissions | 0 (tout ou rien) |
| **Section Scope** | sectionScope + sectionIds | N/A |
| **Guard Pattern** | `isBackofficeAdmin()`, `can(permission)` | `globalRole === 'platform_super_admin'` |

### L.7 Harmonisation Possible

Pour aligner SaaS Owner avec le modèle back-office:

#### Étape 1: Définir Permissions Plateforme

```typescript
// shared/schema.ts - Nouveau type
export type PlatformPermission = 
  | "COMMUNITIES"      // Gestion communautés
  | "USERS"            // Gestion users platform
  | "BILLING"          // Métriques financières
  | "SUPPORT"          // Tickets support
  | "ANALYTICS"        // Tableaux de bord
  | "SETTINGS";        // Configuration plateforme

export const PLATFORM_PERMISSIONS: PlatformPermission[] = [
  "COMMUNITIES", "USERS", "BILLING", "SUPPORT", "ANALYTICS", "SETTINGS"
];
```

#### Étape 2: Ajouter Champ JSONB

```typescript
// users table
platformPermissions: jsonb("platform_permissions").$type<PlatformPermission[]>().default([])
```

#### Étape 3: Créer Guard Unifié

```typescript
// server/middlewares/platformGuards.ts
export function canPlatform(
  user: { globalRole: string | null; platformPermissions?: PlatformPermission[] },
  permission: PlatformPermission
): boolean {
  if (!user.globalRole) return false;
  if (user.globalRole === 'platform_super_admin') return true;  // Bypass total
  
  return user.platformPermissions?.includes(permission) ?? false;
}
```

#### Étape 4: Mapping Rôles → Permissions

| Rôle | Permissions par Défaut |
|------|----------------------|
| `platform_super_admin` | Toutes (bypass) |
| `platform_support` | SUPPORT, COMMUNITIES (lecture) |
| `platform_commercial` | ANALYTICS, COMMUNITIES (lecture) |

### L.8 Effort Harmonisation

| Tâche | Effort | Fichiers |
|-------|--------|----------|
| Définir types permissions | 1h | shared/schema.ts |
| Ajouter colonne platformPermissions | 30min | schema + migration |
| Créer canPlatform guard | 2h | nouveau fichier |
| Remplacer guards dans 42 endpoints | 4h | server/routes.ts |
| UI gestion permissions | 4h | SuperDashboard.tsx |

**Total estimé**: ~12h développement

---

## M. Fichiers Additionnels Référencés

| Fichier | Contenu |
|---------|---------|
| client/src/pages/mobile/admin/Settings.tsx | UI création delegate |
| client/src/pages/platform/SuperDashboard.tsx | Dashboard SaaS Owner |
| server/lib/authModeResolver.ts | Résolution mode auth SaaS Owner |

---

## Changelog

| Date | Version | Auteur | Description |
|------|---------|--------|-------------|
| 2026-01-25 | 1.0 | Agent Replit | Création initiale - audit complet |
| 2026-01-25 | 1.1 | Agent Replit | Ajout sections K (Delegate) et L (SaaS Owner Platform) |
