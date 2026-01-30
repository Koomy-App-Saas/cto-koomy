# Plans Registry & Capabilities Governance - Phase 0 Inventory

**Date:** 2026-01-26
**Status:** COMPLETED
**Objectif:** Inventaire factuel de l'existant avant implémentation

---

## 1. Sources Actuelles des Plans

### 1.1 KOOMY_PLANS (shared/plans.ts)

Source de vérité marketing/UI pour les plans :

```typescript
export const KOOMY_PLANS: Record<PlanCode, KoomyPlan> = {
  free: { maxMembers: 20, maxAdmins: 1, priceMonthly: 0, ... },
  plus: { maxMembers: 300, maxAdmins: 2, priceMonthly: 1900, ... },
  pro: { maxMembers: 1000, maxAdmins: 5, priceMonthly: 4900, ... },
  enterprise: { maxMembers: null, maxAdmins: null, isCustom: true, ... }
}
```

**Contenu:**
- `id`, `code`, `name`, `tagline`, `description`
- `maxMembers`, `maxAdmins` (quotas)
- `priceMonthly`, `priceYearly` (tarification)
- `features` (liste marketing)
- `exclusions` (fonctionnalités exclues)
- `sortOrder`, `isPublic`, `isPopular`, `isCustom`, `isWhiteLabel`

### 1.2 Plans Table (shared/schema.ts)

Table DB pour les plans :

```typescript
export const plans = pgTable("plans", {
  id: varchar("id", { length: 50 }).primaryKey(),
  code: text("code").notNull().unique(),
  name: text("name").notNull(),
  description: text("description"),
  tagline: text("tagline"),
  maxMembers: integer("max_members"),
  maxAdmins: integer("max_admins"),
  priceMonthly: integer("price_monthly"),
  priceYearly: integer("price_yearly"),
  features: jsonb("features").$type<string[]>().notNull(),
  capabilities: jsonb("capabilities").$type<PlanCapabilities>(),
  isPopular: boolean("is_popular").default(false),
  isPublic: boolean("is_public").default(true),
  isCustom: boolean("is_custom").default(false),
  isWhiteLabel: boolean("is_white_label").default(false),
  sortOrder: integer("sort_order").default(0)
});
```

### 1.3 DEFAULT_LIMITS (server/lib/planLimits.ts)

Fallback côté serveur pour les quotas :

```typescript
export const DEFAULT_LIMITS = {
  free: { maxMembers: 20, maxAdmins: 1, maxTags: 10 },
  plus: { maxMembers: 300, maxAdmins: 2, maxTags: 50 },
  pro: { maxMembers: 1000, maxAdmins: 5, maxTags: 200 },
  enterprise: { maxMembers: null, maxAdmins: 7, maxTags: 700 },
  whitelabel: { maxMembers: null, maxAdmins: 7, maxTags: 700 },
};
```

### 1.4 DEFAULT_CAPABILITIES (server/lib/planLimits.ts)

Fallback côté serveur pour les capabilities :

```typescript
const DEFAULT_CAPABILITIES = {
  free: { qrCard: true, dues: false, messaging: true, events: true, analytics: false, ... },
  plus: { qrCard: true, dues: true, messaging: true, events: true, analytics: true, ... },
  pro: { qrCard: true, dues: true, messaging: true, events: true, analytics: true, advancedAnalytics: true, ... },
  enterprise: { /* all true */ },
  whitelabel: { /* all true */ },
};
```

---

## 2. Quotas et Overrides Communauté

### 2.1 Champs sur la table `communities`

```typescript
// Overrides quotas
maxMembersAllowed: integer("max_members_allowed"),    // Override membres
maxAdminsDefault: integer("max_admins_default"),       // Default admins
contractMemberLimit: integer("contract_member_limit"), // Limite contractuelle membres
contractAdminLimit: integer("contract_admin_limit"),   // Limite contractuelle admins
contractMemberAlertThreshold: integer(...).default(90), // Seuil alerte %

// Policies / Fees
platformFeePercent: integer("platform_fee_percent").default(2),
connectFeeFixedCents: integer("connect_fee_fixed_cents").default(0),
```

### 2.2 Ordre de Résolution Actuel

Implémenté dans `getEffectivePlan()` et `resolveCommunityLimits()` :

```
Pour maxAdmins:
1. community.contractAdminLimit (si présent)
2. community.maxAdminsDefault (si présent)
3. plan.maxAdmins (depuis DB)
4. DEFAULT_LIMITS[planId].maxAdmins (fallback)
5. SAFE_MIN_ADMINS = 1 (ultimate fallback)

Pour maxMembers:
1. community.contractMemberLimit (si présent)
2. community.maxMembersAllowed (si présent)
3. plan.maxMembers (depuis DB/DEFAULT_LIMITS)
```

---

## 3. Audit Log Existant

### 3.1 Table `platform_audit_logs`

```typescript
export const platformAuditLogs = pgTable("platform_audit_logs", {
  id: varchar("id", { length: 50 }).primaryKey(),
  userId: varchar("user_id").references(() => users.id),
  action: auditActionEnum("action").notNull(),
  targetType: text("target_type"),      // "user", "community", "plan"
  targetId: text("target_id"),
  details: jsonb("details"),            // { before, after, ... }
  ipAddress: text("ip_address"),
  userAgent: text("user_agent"),
  countryCode: text("country_code"),
  success: boolean("success").default(true),
  createdAt: timestamp("created_at").defaultNow(),
});
```

### 3.2 Actions Enum Existantes

```typescript
export const auditActionEnum = pgEnum("audit_action", [
  "create_community", "update_community", "delete_community",
  "create_user", "update_user", "delete_user", "suspend_user",
  "login_success", "login_failed", "logout",
  "export_data", "import_data",
  "plan_change", "billing_update",
  "security_settings_change", "api_key_generated"
]);
```

**Note:** L'action `plan_change` existe mais pas de `contract_change` dédié.

---

## 4. Analyse des Risques de Migration

### 4.1 Risques Identifiés

| Risque | Impact | Mitigation |
|--------|--------|------------|
| Dualité KOOMY_PLANS / plans table | Désynchronisation | Utiliser plans table comme source, KOOMY_PLANS pour UI |
| DEFAULT_LIMITS hors DB | Pas éditable via UI | Migrer vers platform_plans ou garder comme fallback |
| Overrides dispersés sur communities | Pas de structure JSON centralisée | Créer table dédiée ou wrapper JSON |
| Audit log générique | Manque détail old/new valeurs | Étendre avec key/old_value/new_value |

### 4.2 Points de Cohérence Existants

- **Boot-time validation** (server/index.ts) : Vérifie KOOMY_PLANS ↔ DEFAULT_LIMITS
- **Tests existants** : `plan-limits-alignment.test.ts`, `plan-limits-safe-resolution.test.ts`
- **Service centralisé** : `getEffectivePlan()`, `resolveCommunityLimits()`

---

## 5. Proposition Delta Minimal

### 5.1 Ce qui existe déjà (NE PAS REFAIRE)

- ✅ Table `plans` avec quotas et capabilities
- ✅ Table `platform_audit_logs`
- ✅ Overrides sur `communities` (contractAdminLimit, etc.)
- ✅ Service de résolution (`planLimits.ts`)
- ✅ DEFAULT_LIMITS et DEFAULT_CAPABILITIES

### 5.2 Ce qu'il faut ajouter

1. **Étendre `plans` table** (ou créer `platform_plans`) pour stocker :
   - `defaults_json` : structure consolidée quotas + capabilities + policies
   
2. **Créer `contract_audit_log`** (ou étendre `platform_audit_logs`) :
   - Champs `key`, `old_value`, `new_value`, `reason`
   - Pour tracer les changements de contrat spécifiquement

3. **Créer service `contractResolver.ts`** :
   - Wrapper unifié pour résolution
   - Validation server-side avec Zod
   - Bornes min/max

4. **API Platform** :
   - `GET/PATCH /api/platform/plans/:id` (defaults)
   - `GET/PATCH /api/platform/communities/:id/overrides`
   - `GET /api/platform/audit/contracts`

5. **UI Gouvernance** :
   - Adapter page Plans existante
   - Ajouter onglet/drawer gouvernance

### 5.3 Décision Structurelle

**Option A - Réutiliser `plans` table :**
- Ajouter colonne `defaults_json` sur `plans`
- Moins de migration

**Option B - Créer `platform_plans` dédié :**
- Séparation claire marketing / gouvernance
- Plus propre mais plus de migration

**Recommandation:** Option A (réutiliser `plans` + étendre) car :
- La table `plans` a déjà quotas, capabilities, features
- Ajouter `defaults_json` permet consolidation sans casser l'existant
- Boot-time validation continue de fonctionner

---

## 6. Fichiers Clés Identifiés

| Fichier | Rôle |
|---------|------|
| `shared/plans.ts` | KOOMY_PLANS définition marketing |
| `shared/schema.ts` | Table `plans`, `communities`, `platform_audit_logs` |
| `server/lib/planLimits.ts` | DEFAULT_LIMITS, résolution quotas |
| `server/lib/effectiveStateService.ts` | Service état effectif |
| `server/routes.ts` | API existantes plans/communities |
| `server/index.ts` | Boot validation KOOMY_PLANS ↔ DEFAULT_LIMITS |

---

## 7. Conclusion

L'architecture existante est solide avec :
- Double source (KOOMY_PLANS + plans table) nécessitant cohérence
- Overrides communauté dispersés mais fonctionnels
- Audit log générique extensible
- Service de résolution centralisé

**Delta minimal identifié :**
1. Étendre `plans` avec `defaults_json`
2. Créer audit log spécialisé contrats
3. Wrapper `contractResolver.ts`
4. API gouvernance
5. UI gouvernance

**Prêt pour Phase 1.**
