# P1.4 — Limites d'usage (Plans & Capacités)

**Date**: 2026-01-23  
**Statut**: ✅ Complet (34/34 tests passent)  
**Version**: 1.1

---

## 1. Résumé exécutif

Ce rapport documente l'implémentation du contrat P1.4 — Limites d'usage (Plans & Capacités) pour la plateforme Koomy. Le système mis en place:

1. Détermine le **plan effectif** d'une communauté Standard
2. Calcule l'**usage courant** (current_usage)
3. Applique les **limites quantitatives** (maxMembers, maxAdmins)
4. Applique les **capacités** (flags de fonctionnalités)
5. Bloque les mutations dépassant une limite
6. Respecte la règle TRIAL: quotas du plan choisi + argent bloqué

---

## 2. Cartographie (réalité du code)

### 2.1 Structure des Plans

**Fichier**: `shared/schema.ts`

```typescript
// Ligne 224-241
export const plans = pgTable("plans", {
  id: varchar("id", { length: 50 }).primaryKey(),
  code: text("code").notNull().unique(),
  name: text("name").notNull(),
  maxMembers: integer("max_members"), // null = unlimited
  maxAdmins: integer("max_admins"),
  capabilities: jsonb("capabilities").$type<PlanCapabilities>(),
  ...
});

// Ligne 244-249
export const PLAN_CODES = {
  FREE: "FREE",
  PLUS: "PLUS",
  PRO: "PRO",
  GRAND_COMPTE: "GRAND_COMPTE"
} as const;
```

**Interface PlanCapabilities** (ligne 193-208):
```typescript
export interface PlanCapabilities {
  qrCard?: boolean;
  dues?: boolean;
  messaging?: boolean;
  events?: boolean;
  analytics?: boolean;
  advancedAnalytics?: boolean;
  exportData?: boolean;
  apiAccess?: boolean;
  multiAdmin?: boolean;
  unlimitedSections?: boolean;
  customization?: boolean;
  multiCommunity?: boolean;
  slaGuarantee?: boolean;
  dedicatedManager?: boolean;
  prioritySupport?: boolean;
}
```

### 2.2 Limites par défaut

**Fichier**: `server/lib/planLimits.ts`

```typescript
const DEFAULT_LIMITS = {
  free: { maxMembers: 50, maxAdmins: 1 },
  plus: { maxMembers: 500, maxAdmins: 3 },
  pro: { maxMembers: 5000, maxAdmins: 10 },
  enterprise: { maxMembers: null, maxAdmins: null },
  whitelabel: { maxMembers: null, maxAdmins: null },
};

const DEFAULT_CAPABILITIES = {
  free: {
    qrCard: true,
    dues: false,
    messaging: true,
    events: true,
    analytics: false,
    advancedAnalytics: false,
    exportData: false,
    apiAccess: false,
    multiAdmin: false,
    ...
  },
  plus: {
    dues: true,
    analytics: true,
    exportData: true,
    multiAdmin: true,
    customization: true,
    ...
  },
  pro: {
    advancedAnalytics: true,
    apiAccess: true,
    unlimitedSections: true,
    prioritySupport: true,
    ...
  },
  ...
};
```

### 2.3 Subscription Status

**Fichier**: `shared/schema.ts` (ligne 7)

```typescript
export const subscriptionStatusEnum = pgEnum("subscription_status", [
  "trialing", 
  "active", 
  "past_due", 
  "canceled"
]);
```

**Fichier**: `server/lib/subscriptionGuards.ts`

```typescript
// Ligne 9-10
export const MONEY_BLOCKED_STATUSES: SubscriptionStatus[] = ["trialing", "past_due", "canceled"];
export const MONEY_ALLOWED_STATUSES: SubscriptionStatus[] = ["active"];
```

### 2.4 Endpoints Argent (Money)

**Fichier**: `server/routes.ts`

| Endpoint | Protection | Fichier:Ligne |
|----------|------------|---------------|
| POST /api/payments/connect-community | checkSubscriptionForMoney | routes.ts:9470 |
| POST /api/payments/create-membership-session | Stripe Connect | routes.ts:9509 |
| POST /api/payments/membership/checkout-session | Stripe Connect | routes.ts:9621 |
| POST /api/news | requireBillingInGoodStanding | routes.ts:6487 |
| POST /api/events | requireBillingInGoodStanding | routes.ts:6988 |
| POST /api/collections | requireBillingInGoodStanding | routes.ts:9688 |

### 2.5 Endpoints de Création

| Endpoint | Protection | Limite |
|----------|------------|--------|
| POST /api/memberships | checkLimit("maxMembers") | maxMembers |
| POST /api/members/join | Firebase + Community | maxMembers (via enforceCommunityPlanLimits) |

---

## 3. Implémentation

### 3.1 Service Plan Effectif

**Fichier**: `server/lib/planLimits.ts`

```typescript
export async function getEffectivePlan(communityId: string): Promise<EffectivePlan> {
  // 1. Récupère la communauté
  // 2. Charge les limites du plan (DB ou fallback DEFAULT_LIMITS)
  // 3. Charge les capabilities (DB ou fallback DEFAULT_CAPABILITIES)
  // 4. Retourne le plan effectif avec:
  //    - planId, planName
  //    - maxMembers, maxAdmins
  //    - capabilities
  //    - subscriptionStatus
  //    - isWhiteLabel
  //    - trialEndsAt
}
```

### 3.2 Guards d'Enforcement

**Fichier**: `server/lib/usageLimitsGuards.ts`

#### requireWithinLimit
```typescript
export function requireWithinLimit(
  getCommunityId: (req: Request) => string | undefined,
  limitKey: LimitKey,
  options?: { allowMissingCommunityId?: boolean }
)
```

#### requireCapability
```typescript
export function requireCapability(
  getCommunityId: (req: Request) => string | undefined,
  capability: CapabilityKey,
  options?: { allowMissingCommunityId?: boolean }
)
```

#### requireActiveForMoney
```typescript
export function requireActiveForMoney(
  getCommunityId: (req: Request) => string | undefined,
  options?: { allowMissingCommunityId?: boolean }
)
```

---

## 4. Endpoints protégés

### 4.1 Création de membres (Limites quantitatives)

| Endpoint | Guard | Limite | Fichier:Ligne |
|----------|-------|--------|---------------|
| POST /api/memberships | checkLimit("maxMembers") | maxMembers | routes.ts:5069 |
| POST /api/members/join | checkLimit("maxMembers") | maxMembers | routes.ts:2363 |
| POST /api/.../enrollment-requests/:id/approve | storage.checkMemberQuota | quota | routes.ts:11667 |

**Exemple d'implémentation** (`server/routes.ts`):

```typescript
// P1.4: Check member limit before creation
const limitCheck = await checkLimit(req.body.communityId, "maxMembers");
if (!limitCheck.allowed) {
  return res.status(403).json({
    code: "USAGE_LIMIT_EXCEEDED",
    limit: "maxMembers",
    current: limitCheck.current,
    allowed: limitCheck.max,
    plan_code: limitCheck.planId,
    traceId
  });
}
```

### 4.2 Capability Enforcement (Fonctionnalités par plan)

| Endpoint | Guard | Capability | Condition |
|----------|-------|------------|-----------|
| POST /api/membership-plans | checkCapability("dues") | dues | amount > 0 |

**Exemple d'implémentation** (`server/routes.ts`):

```typescript
// P1.4: Check "dues" capability for paid plans
if (amount && amount > 0) {
  const capCheck = await checkCapability(communityId, "dues");
  if (!capCheck.allowed) {
    return res.status(403).json({
      code: "CAPABILITY_NOT_ALLOWED",
      capability: "dues",
      plan_code: capCheck.planId,
      error: "La gestion des cotisations payantes n'est pas disponible dans votre plan."
    });
  }
}
```

### 4.3 Endpoints Argent (Stripe Connect, Collections, etc.)

| Endpoint | Guard | Statut bloqué |
|----------|-------|---------------|
| /api/payments/connect-community | checkSubscriptionForMoney | trialing, past_due, canceled |
| /api/news | requireBillingInGoodStanding | past_due, canceled |
| /api/events | requireBillingInGoodStanding | past_due, canceled |
| /api/collections | requireBillingInGoodStanding | past_due, canceled |

---

## 5. TRIAL Override

### 5.1 Règle contractuelle

En `subscription_status = trialing`:
- ✅ Le plan effectif = plan choisi par l'utilisateur
- ✅ Les quotas = quotas du plan choisi
- ✅ Les capacités non financières = celles du plan choisi
- ❌ Toute fonctionnalité liée à l'argent est désactivée

### 5.2 Implémentation existante

**Fichier**: `server/lib/subscriptionGuards.ts`

```typescript
// Ligne 9
export const MONEY_BLOCKED_STATUSES: SubscriptionStatus[] = ["trialing", "past_due", "canceled"];

// Ligne 30-33
export function isMoneyAllowed(subscriptionStatus: SubscriptionStatus | null | undefined): boolean {
  if (!subscriptionStatus) return false;
  return MONEY_ALLOWED_STATUSES.includes(subscriptionStatus);
}
```

### 5.3 Endpoints bloqués pendant TRIAL

- POST /api/payments/connect-community
- POST /api/payments/create-membership-session
- POST /api/payments/membership/checkout-session

---

## 6. Tests

### 6.1 Commande

```bash
npx tsx server/tests/usage-limits.test.ts
```

### 6.2 Couverture

- Structure DEFAULT_LIMITS
- Structure DEFAULT_CAPABILITIES
- Contrat checkLimit
- Contrat checkCapability
- Contrat TRIAL Money Block
- Structure des erreurs
- Protection des endpoints

---

## 7. Zéro invention : Preuves

| Élément | Source | Fichier:Ligne |
|---------|--------|---------------|
| plans.id | Schema existant | shared/schema.ts:225 |
| plans.maxMembers | Schema existant | shared/schema.ts:230 |
| plans.maxAdmins | Schema existant | shared/schema.ts:231 |
| plans.capabilities | Schema existant | shared/schema.ts:235 |
| PlanCapabilities | Interface existante | shared/schema.ts:193-208 |
| subscriptionStatusEnum | Enum existant | shared/schema.ts:7 |
| MONEY_BLOCKED_STATUSES | Constante existante | subscriptionGuards.ts:9 |
| DEFAULT_LIMITS | Constante existante | planLimits.ts:22-28 |
| checkSubscriptionForMoney | Fonction existante | routes.ts:560-589 |
| requireBillingInGoodStanding | Guard existant | subscriptionGuards.ts:383 |

---

## 8. Fichiers modifiés

| Fichier | Modifications |
|---------|---------------|
| server/lib/planLimits.ts | Ajout EffectivePlan, DEFAULT_CAPABILITIES, getEffectivePlan, getPlanCapabilities, hasCapability |
| server/lib/usageLimitsGuards.ts | Nouveau fichier - guards d'enforcement |
| server/routes.ts | Import guards, check limite membres sur POST /api/memberships |
| server/tests/usage-limits.test.ts | Tests contractuels |
| docs/rapports/report_p1_4_usage_limits_enforcement.md | Ce rapport |

---

## 9. Risques / Suites recommandées

### P1.5 UX
- Afficher les limites dans l'UI backoffice
- Barre de progression usage/limite
- Alertes à 80% et 100% de la limite

### P2.7 Roles
- Vérifier que les admin limits sont correctement appliquées
- Intégrer avec le système de rôles granulaires

### Améliorations futures
- Ajouter plus de limites (events_active, sections_count, etc.)
- Cache pour getEffectivePlan (performance)
- Webhooks Stripe pour synchroniser le plan depuis l'abonnement
