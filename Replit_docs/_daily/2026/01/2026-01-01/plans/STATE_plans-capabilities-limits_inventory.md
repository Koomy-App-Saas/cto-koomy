# KOOMY — INVENTAIRE DES PLANS, CAPABILITIES, LIMITES

**Date**: 2026-01-25  
**Version**: 1.0  
**Statut**: Audit factuel basé sur le code

---

## 1. Résumé Exécutif

- **4 plans officiels** : FREE, PLUS, PRO, GRAND_COMPTE (définis dans `shared/plans.ts`)
- **Limites définies** : `maxMembers` et `maxAdmins` par plan
- **FREE = 1 admin** : Déclaré dans `KOOMY_PLANS.FREE.maxAdmins = 1`, mais **NON ENFORCED côté API**
- **Capabilities** : 21 capabilities définies dans `PlanCapabilities` interface
- **Enforcement** : `maxMembers` enforcé via `checkLimit`, `maxAdmins` **NON enforcé**
- **White-Label & Enterprise** : Bypass automatique de toutes les limites
- **Tags** : Gating par plan supprimé (2026-01-25), disponible pour tous les plans
- **Événements payants** : Capability `eventPaid` + quota `eventPaidQuota` enforcés
- **Cotisations (dues)** : Capability `dues` enforcée via `checkCapability`
- **GAP CRITIQUE** : Route `POST /api/communities/:communityId/admins` ne vérifie pas `maxAdmins`

---

## 2. Modèle des Plans

### 2.1 Définition des Plans

**Fichier source** : `shared/plans.ts` (KOOMY_PLANS)

| Code | ID | Nom | maxMembers | maxAdmins | Prix/mois | Prix/an |
|------|-----|------|------------|-----------|-----------|---------|
| FREE | free | Free | 20 | 1 | 0€ | 0€ |
| PLUS | plus | Plus | 300 | null (∞) | 12€ | 120€ |
| PRO | pro | Pro | 1000 | null (∞) | 39€ | 390€ |
| GRAND_COMPTE | enterprise | Grand Compte | null (∞) | null (∞) | Sur devis | Sur devis |

**Note** : Les prix sont stockés en centimes dans le code (1200 = 12€).

### 2.2 Valeurs par Défaut (Fallback)

**Fichier** : `server/lib/planLimits.ts` (DEFAULT_LIMITS)

```typescript
const DEFAULT_LIMITS = {
  free: { maxMembers: 50, maxAdmins: 1 },      // Note: 50 ≠ 20 dans KOOMY_PLANS
  plus: { maxMembers: 500, maxAdmins: 3 },     // Note: 500 ≠ 300, 3 ≠ null
  pro: { maxMembers: 5000, maxAdmins: 10 },    // Note: 5000 ≠ 1000, 10 ≠ null
  enterprise: { maxMembers: null, maxAdmins: null },
  whitelabel: { maxMembers: null, maxAdmins: null },
};
```

**⚠️ INCOHÉRENCE** : `DEFAULT_LIMITS` dans `planLimits.ts` diffère de `KOOMY_PLANS` dans `shared/plans.ts`. Le fallback est utilisé si la DB n'a pas le plan.

### 2.3 Stockage DB

**Table** : `plans` (schéma dans `shared/schema.ts`)

```typescript
export const plans = pgTable("plans", {
  id: varchar("id", { length: 50 }).primaryKey(),
  code: text("code").notNull().unique(),
  name: text("name").notNull(),
  maxMembers: integer("max_members"),    // null = illimité
  maxAdmins: integer("max_admins"),      // null = illimité
  capabilities: jsonb("capabilities").$type<PlanCapabilities>().default({}),
  // ...
});
```

### 2.4 Référence Community → Plan

**Table** : `communities`

```typescript
planId: varchar("plan_id").references(() => plans.id).notNull(),
subscriptionStatus: subscriptionStatusEnum("subscription_status").default("active"),
maxMembersAllowed: integer("max_members_allowed"), // Override possible
```

---

## 3. Inventaire Complet des Features/Gates

### 3.1 LIMITES (Quotas)

| Nom | Limite | Scope | Enforcement | Fichiers | Status/Message |
|-----|--------|-------|-------------|----------|----------------|
| Membres max | `maxMembers` | PLAN_LINKED | API_ENFORCED | `server/routes.ts:2467,5263`, `usageLimitsGuards.ts:100` | 403 `USAGE_LIMIT_EXCEEDED` |
| Admins max | `maxAdmins` | PLAN_LINKED | **NONE** | Défini dans `planLimits.ts:23` mais **non utilisé** | - |
| Événements payants/mois | `eventPaidQuota` | PLAN_LINKED | API_ENFORCED | `server/routes.ts:7332-7339` | 403 "Vous avez utilisé vos X événements payants ce mois-ci" |

### 3.2 CAPABILITIES (Fonctionnalités)

| Capability | FREE | PLUS | PRO | GRAND_COMPTE | Enforcement | Fichiers |
|------------|------|------|-----|--------------|-------------|----------|
| qrCard | ❌ | ✅ | ✅ | ✅ | FRONT_ENFORCED | UI conditionnel |
| dues | ❌ | ✅ | ✅ | ✅ | **API_ENFORCED** | `routes.ts:10735` → `checkCapability("dues")` |
| messaging | ❌ | ✅ | ✅ | ✅ | FRONT_ENFORCED | - |
| events | ✅ | ✅ | ✅ | ✅ | GLOBAL | - |
| analytics | ❌ | ✅ | ✅ | ✅ | FRONT_ENFORCED | - |
| advancedAnalytics | ❌ | ❌ | ✅ | ✅ | FRONT_ENFORCED | - |
| exportData | ❌ | ❌ | ✅ | ✅ | FRONT_ENFORCED | - |
| apiAccess | ❌ | ❌ | ✅ | ✅ | NONE | Pas de gate trouvé |
| multiAdmin | ❌ | ❌ | ✅ | ✅ | **NONE** | Affiché en UI, pas enforcé |
| unlimitedSections | ❌ | ❌ | ✅ | ✅ | NONE | - |
| customization | ❌ | ✅ | ✅ | ✅ | FRONT_ENFORCED | - |
| multiCommunity | ❌ | ❌ | ❌ | ✅ | NONE | - |
| slaGuarantee | ❌ | ❌ | ❌ | ✅ | N/A (contractuel) | - |
| dedicatedManager | ❌ | ❌ | ❌ | ✅ | N/A (contractuel) | - |
| prioritySupport | ❌ | ✅ | ✅ | ✅ | N/A (humain) | - |
| support24x7 | ❌ | ❌ | ❌ | ✅ | N/A (humain) | - |
| customDomain | ❌ | ❌ | ❌ | ✅ | ORPHAN | WL only |
| whiteLabeling | ❌ | ❌ | ❌ | ✅ | ORPHAN | WL only |
| eventRsvp | ❌ | ✅ | ✅ | ✅ | NONE | Disponible par défaut |
| eventPaid | ❌ | ✅ | ✅ | ✅ | **API_ENFORCED** | `routes.ts:7318` |
| eventPaidQuota | 0 | 2 | null | null | **API_ENFORCED** | `routes.ts:7332` |
| eventTargeting | ❌ | ❌ | ✅ | ✅ | FRONT_ENFORCED | - |
| eventCapacity | ❌ | ❌ | ✅ | ✅ | NONE | - |
| eventDeadline | ❌ | ❌ | ✅ | ✅ | NONE | - |
| eventStats | ❌ | ❌ | ✅ | ✅ | FRONT_ENFORCED | - |
| eventWaitlist | ❌ | ❌ | ❌ | ✅ | NONE | Grand Compte only |
| eventApproval | ❌ | ❌ | ❌ | ✅ | NONE | Grand Compte only |

### 3.3 FEATURE_FLAGS (Modules)

| Feature | Type | Scope | Enforcement | Fichiers | Notes |
|---------|------|-------|-------------|----------|-------|
| Tags | FEATURE_FLAG | **GLOBAL** | NONE | Gating supprimé 2026-01-25 | Disponible tous plans |
| Sections | FEATURE_FLAG | GLOBAL | NONE | - | Disponible tous plans |
| Self-enrollment | FEATURE_FLAG | GLOBAL | API_ENFORCED | - | Vérifie member limit |

### 3.4 BRANDING / WHITE-LABEL

| Feature | Type | Scope | Enforcement | Fichiers | Notes |
|---------|------|-------|-------------|----------|-------|
| whiteLabel flag | BRANDING | WL_ONLY | API | `communities.whiteLabel` | Active mode WL |
| whiteLabelTier | BRANDING | WL_ONLY | API | `communities.whiteLabelTier` | standard/premium |
| billingMode | BILLING | WL_ONLY | API | `communities.billingMode` | manual/stripe |
| brandConfig | BRANDING | WL_ONLY | API | `communities.brandConfig` (JSONB) | Thème custom |
| customDomain | BRANDING | WL_ONLY | NONE | Non implémenté | - |

### 3.5 BILLING / SUBSCRIPTION

| Feature | Type | Scope | Enforcement | Fichiers | Notes |
|---------|------|-------|-------------|----------|-------|
| Trial payments block | BILLING | PLAN_LINKED | API_ENFORCED | `usageLimitsGuards.ts:152` | 403 `TRIAL_PAYMENTS_DISABLED` |
| Paid upgrade required | BILLING | PLAN_LINKED | API_ENFORCED | `routes.ts:4996` | 403 `PAID_UPGRADE_REQUIRED` |
| Subscription status | BILLING | GLOBAL | API | `communities.subscriptionStatus` | active/trialing/past_due |

---

## 4. Focus: "Free = 1 admin"

### 4.1 Où c'est défini

**Fichier** : `shared/plans.ts`
```typescript
[PLAN_CODES.FREE]: {
  maxAdmins: 1,  // ✅ Déclaré
  // ...
}
```

**Fichier** : `server/lib/planLimits.ts`
```typescript
const DEFAULT_LIMITS = {
  free: { maxMembers: 50, maxAdmins: 1 },  // ✅ Déclaré
};
```

### 4.2 Où c'est censé être enforcé

**Fichier** : `server/lib/usageLimitsGuards.ts`

```typescript
export async function getAdminCount(communityId: string): Promise<number> {
  // Compte les admins + delegates
}

export async function checkLimit(communityId: string, limitKey: LimitKey): Promise<...> {
  // Supporte "maxAdmins" comme limitKey
}
```

### 4.3 Où c'est réellement enforcé

**Route** : `POST /api/communities/:communityId/admins` (`routes.ts:4586`)

```typescript
app.post("/api/communities/:communityId/admins", 
  requireMembership("communityId"), 
  requireOwner,  // ✅ Vérifie owner
  async (req, res) => {
    // ❌ PAS DE checkLimit("maxAdmins")
    // ❌ PAS DE requireWithinLimit(getCommunityId, "maxAdmins")
    // → Création admin sans vérification de quota
  });
```

### 4.4 Conclusion

| Aspect | Status |
|--------|--------|
| Limite déclarée | ✅ `maxAdmins: 1` dans FREE |
| Fonction de check | ✅ `getAdminCount()` + `checkLimit()` existent |
| Enforcement API | ❌ **NON IMPLÉMENTÉ** |
| Enforcement UI | ❌ **NON IMPLÉMENTÉ** |

**VERDICT** : La limite "Free = 1 admin" est **déclarée mais NON enforcée**. Un owner FREE peut créer plusieurs admins via l'API.

---

## 5. Gaps / Incohérences

### 5.1 Incohérences de Valeurs

| Item | KOOMY_PLANS | DEFAULT_LIMITS | Risque |
|------|-------------|----------------|--------|
| FREE.maxMembers | 20 | 50 | LOW - DB prime |
| PLUS.maxMembers | 300 | 500 | LOW - DB prime |
| PLUS.maxAdmins | null | 3 | MED - Fallback différent |
| PRO.maxMembers | 1000 | 5000 | LOW - DB prime |
| PRO.maxAdmins | null | 10 | MED - Fallback différent |

### 5.2 Capabilities Non Enforcées

| Capability | Déclarée | Enforcée | Risque |
|------------|----------|----------|--------|
| multiAdmin | ✅ | ❌ | HIGH - maxAdmins ignoré |
| apiAccess | ✅ | ❌ | MED - Pas de gate API |
| exportData | ✅ | ❌ | MED - Pas de gate API |
| analytics | ✅ | ❌ | LOW - UI only |
| eventCapacity | ✅ | ❌ | LOW - Fonctionnel sans gate |
| eventDeadline | ✅ | ❌ | LOW - Fonctionnel sans gate |

### 5.3 Orphans (Code Présent mais Non Relié)

| Item | Fichier | Description |
|------|---------|-------------|
| delegate role count | `usageLimitsGuards.ts:57-59` | Delegates comptés dans admin count mais pas de limite séparée |
| customDomain capability | `schema.ts:210` | Déclaré mais jamais vérifié |
| whiteLabeling capability | `schema.ts:211` | Déclaré mais utilise `community.whiteLabel` flag |

---

## 6. Matrice Cible Proposée

### 6.1 Couche 1: Capabilities par Rôle (indépendant du plan)

| Permission | Owner | Admin | Delegate | Member |
|------------|-------|-------|----------|--------|
| Créer admin | ✅ | ❌ | ❌ | ❌ |
| Gérer membres | ✅ | ✅ (si MEMBERS) | ❌ | ❌ |
| Gérer contenu | ✅ | ✅ (si CONTENT) | ❌ | ❌ |
| Gérer finances | ✅ | ✅ (si FINANCE) | ❌ | ❌ |
| Gérer événements | ✅ | ✅ (si EVENTS) | ❌ | ❌ |
| Paramètres | ✅ | ✅ (si SETTINGS) | ❌ | ❌ |
| Voir contenu | ✅ | ✅ | ✅ | ✅ |

### 6.2 Couche 2: Plans = Limites + Modules

| Plan | maxMembers | maxAdmins | Modules Activés | Events Payants |
|------|------------|-----------|-----------------|----------------|
| FREE | 20 | 1 | Base | 0/mois |
| PLUS | 300 | ∞ | + QR + Dues + Messaging + Analytics | 2/mois |
| PRO | 1000 | ∞ | + Multi-admin + Export + API + Sections∞ | ∞ |
| GRAND_COMPTE | ∞ | ∞ | + Multi-communauté + SLA + Dédié | ∞ |

### 6.3 Table Feature → Case Cible

| Feature | Case Actuelle | Case Cible | Plan Min | Risque Breaking | Action |
|---------|---------------|------------|----------|-----------------|--------|
| maxMembers | LIMIT | LIMIT | FREE | LOW | Maintenir |
| maxAdmins | LIMIT | LIMIT | FREE | **HIGH** | **Enforcer API** |
| dues | CAPABILITY | CAPABILITY | PLUS | LOW | Maintenir |
| eventPaid | CAPABILITY | CAPABILITY | PLUS | LOW | Maintenir |
| eventPaidQuota | LIMIT | LIMIT | PLUS | LOW | Maintenir |
| tags | FEATURE_FLAG | GLOBAL | - | **DONE** | ✅ Migré |
| multiAdmin | CAPABILITY | **LIMIT** | PRO | MED | Changer vers maxAdmins |
| exportData | CAPABILITY | CAPABILITY | PRO | MED | Enforcer API |
| apiAccess | CAPABILITY | CAPABILITY | PRO | MED | Enforcer API |
| analytics | CAPABILITY | CAPABILITY | PLUS | LOW | Maintenir UI |
| customDomain | BRANDING | BRANDING | GRAND_COMPTE | LOW | Implémenter |

---

## 7. Liste d'Actions Recommandées

### Priorité 1 - CRITIQUE

| # | Action | Risque | Fichiers |
|---|--------|--------|----------|
| 1 | **Enforcer maxAdmins** sur `POST /api/communities/:communityId/admins` | HIGH | `routes.ts:4589` |
| 2 | Ajouter UI gate pour création admin si limite atteinte | HIGH | `client/src/pages/admin/Team.tsx` |

### Priorité 2 - IMPORTANT

| # | Action | Risque | Fichiers |
|---|--------|--------|----------|
| 3 | Harmoniser `DEFAULT_LIMITS` avec `KOOMY_PLANS` | MED | `planLimits.ts:25-31` |
| 4 | Enforcer `exportData` capability sur routes d'export | MED | `routes.ts` (à identifier) |
| 5 | Enforcer `apiAccess` capability sur routes API externes | MED | À implémenter |

### Priorité 3 - AMÉLIORATION

| # | Action | Risque | Fichiers |
|---|--------|--------|----------|
| 6 | Supprimer capabilities orphelines (`customDomain`, `whiteLabeling`) ou les implémenter | LOW | `schema.ts` |
| 7 | Documenter les capabilities N/A (SLA, support) | LOW | Documentation |
| 8 | Ajouter tests pour tous les gates | LOW | `server/tests/` |

---

## 8. Annexe: Codes d'Erreur Standardisés

| Code | HTTP | Description |
|------|------|-------------|
| `USAGE_LIMIT_EXCEEDED` | 403 | Limite de plan atteinte (membres, admins) |
| `CAPABILITY_NOT_ALLOWED` | 403 | Fonctionnalité non disponible pour ce plan |
| `CAPABILITY_DENIED` | 403 | Permission rôle insuffisante |
| `TRIAL_PAYMENTS_DISABLED` | 403 | Paiements bloqués pendant essai |
| `PAID_UPGRADE_REQUIRED` | 403 | Upgrade payant requis via Stripe |
| `AUTH_TOKEN_EXPIRED` | 401 | Token Firebase expiré |
| `UNAUTHENTICATED` | 401 | Token absent |
| `AUTH_TOKEN_INVALID` | 401 | Token invalide |

---

## 9. Prochaines Étapes de Vérification

Pour valider les findings:

1. **Test API maxAdmins**:
   ```bash
   # Créer community FREE, ajouter 2 admins → devrait passer (bug)
   curl -X POST /api/communities/{id}/admins -d '{"email":"admin2@test.com",...}'
   ```

2. **Test capability exportData**:
   ```bash
   # Community FREE, tenter export → devrait bloquer (non implémenté)
   curl /api/communities/{id}/export
   ```

3. **Comparer DB vs KOOMY_PLANS**:
   ```sql
   SELECT id, code, max_members, max_admins FROM plans;
   ```
