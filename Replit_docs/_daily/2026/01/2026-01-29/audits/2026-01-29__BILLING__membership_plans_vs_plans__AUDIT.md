# Audit : membership_plans vs plans - Source de vérité billing

**Date** : 2026-01-29  
**Domaine** : BILLING  
**Type** : AUDIT  
**Statut** : Complété

---

## Contexte

Audit de la Prod v2 / Sandbox v2 de KOOMY pour activer correctement le billing et les limites de plan.  
La table `membership_plans` existe dans le schéma mais est vide/quasi-vide.  
Les limites affichées côté front sont donc ∞ et les fonctionnalités vides.

---

## 1) Table `membership_plans`

### Question : Cette table contient-elle les plans SaaS runtime ?

**Réponse : NON**

La table `membership_plans` a une FK `community_id` vers `communities`. C'est une table **par communauté** pour les **formules d'adhésion des membres** (cotisations), pas les plans SaaS de la plateforme.

### Structure observée

```sql
CREATE TABLE membership_plans (
  id VARCHAR(50) PRIMARY KEY,
  community_id VARCHAR(50) REFERENCES communities(id) NOT NULL,
  name TEXT NOT NULL,
  slug TEXT NOT NULL,
  tagline TEXT,
  amount INTEGER DEFAULT 0,
  currency TEXT DEFAULT 'EUR',
  billing_type membership_billing_type_enum DEFAULT 'annual',
  membership_type membership_plan_type_enum DEFAULT 'FIXED_PERIOD',
  fixed_period_type fixed_period_type_enum,
  rolling_duration_months INTEGER,
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

### Contenu actuel (sandbox)

| id | community_id | name | amount |
|----|--------------|------|--------|
| ef207ae4-... | 2b129b86-... | Gratuit | 0 |

**1 seul enregistrement** : une formule de cotisation pour une communauté spécifique.

### Était-il prévu qu'elle soit seedée automatiquement ?

**Réponse : NON**

Aucune référence à `membership_plans` dans les scripts de seed :
- `server/seed.ts` : n'insère pas dans `membership_plans`
- Aucun script `seed-membership_plans` trouvé

Cette table est créée **dynamiquement par les admins de communauté** pour définir leurs formules de cotisation.

---

## 2) Source de vérité actuelle

### a) Limite de membres

| Source | Fichier | Priorité |
|--------|---------|----------|
| Table `plans` (DB) | `server/lib/planLimits.ts:130-181` | 1ère |
| `DEFAULT_LIMITS` (hardcodé) | `server/lib/planLimits.ts:31-37` | Fallback |

**Fonction** : `getPlanLimits(planId)`

```typescript
// server/lib/planLimits.ts
export async function getPlanLimits(planId: string): Promise<PlanLimits> {
  const normalizedPlanId = planId?.toLowerCase() || 'free';
  const defaults = DEFAULT_LIMITS[normalizedPlanId] || DEFAULT_LIMITS.free;
  
  const [plan] = await db.select(...).from(plans).where(eq(plans.id, planId));
  
  if (plan) {
    return { maxMembers: plan.maxMembers, ... };
  }
  
  // Fallback to defaults
  return { maxMembers: defaults.maxMembers, ... };
}
```

### b) Fonctionnalités incluses

| Source | Fichier | Priorité |
|--------|---------|----------|
| Table `plans.capabilities` (DB) | `server/lib/planLimits.ts:243+` | 1ère |
| `DEFAULT_CAPABILITIES` (hardcodé) | `server/lib/planLimits.ts:39-125` | Fallback |

**Fonction** : `getPlanCapabilities(planId)`

### c) Droit à l'upgrade / billing

| Source | Fichier |
|--------|---------|
| `communities.planId` | FK vers `plans.id` |
| `communities.subscriptionStatus` | enum (trialing, active, past_due, etc.) |
| Routes billing | `server/routes.ts` (endpoints /api/billing/*) |

---

## 3) BUG CRITIQUE : Mismatch des IDs de plans

### Problème identifié

Les clés utilisées dans `DEFAULT_LIMITS` ne correspondent pas aux IDs en base de données :

| Code (DEFAULT_LIMITS) | Base de données (plans.id) | Résultat |
|-----------------------|---------------------------|----------|
| `free` | `free` | ✅ OK |
| `plus` | `growth` | ❌ Mismatch |
| `pro` | `scale` | ❌ Mismatch |
| `enterprise` | `enterprise` | ✅ OK |
| `whitelabel` | `whitelabel` | ✅ OK |

### Conséquence

Quand une communauté a `planId = "growth"` :
1. `getPlanLimits("growth")` cherche dans DB → trouve le plan
2. `DEFAULT_LIMITS["growth"]` → undefined → fallback vers `DEFAULT_LIMITS.free`
3. Si `plan.maxAdmins` est null en DB → utilise `defaults.maxAdmins` = 1 (free) au lieu de 2 (plus)

### Code source du problème

```typescript
// server/lib/planLimits.ts ligne 31-37
export const DEFAULT_LIMITS: Record<string, {...}> = {
  free: { maxMembers: 20, maxAdmins: 1, maxTags: 10 },
  plus: { maxMembers: 100, maxAdmins: 2, maxTags: 50 },  // ❌ Devrait être "growth"
  pro: { maxMembers: 250, maxAdmins: 5, maxTags: 200 },  // ❌ Devrait être "scale"
  enterprise: { maxMembers: null, maxAdmins: 7, maxTags: 700 },
  whitelabel: { maxMembers: null, maxAdmins: 7, maxTags: 700 },
};
```

### État actuel de la table `plans` (sandbox)

```
id         | name              | max_members | max_admins | capabilities
-----------+-------------------+-------------+------------+--------------
free       | Free Starter      | 20          | 1          | {...}
growth     | Communauté Plus   | 100         | 2          | {...}
scale      | Communauté Pro    | 250         | 5          | {...}
enterprise | Grand Compte      | null        | null       | {...}
whitelabel | Koomy White Label | null        | null       | {...}
```

---

## 4) Historique / intention de `membership_plans`

**Réponse : (a) Table en cours d'implémentation, partiellement fonctionnelle**

- Elle est utilisée pour les formules de cotisation par communauté
- Elle n'a **jamais été conçue** pour contenir les plans SaaS
- Elle est liée au module "Gestion des cotisations" :
  - `membershipFees` : frais appliqués aux membres
  - `paymentRequests` : demandes de paiement
  - `payments` : paiements effectués

---

## 5) Modélisation attendue

### Schéma actuel

```
┌─────────────────────────┐
│         plans           │  ← Plans SaaS (free/growth/scale/enterprise/whitelabel)
│  - id (PK)              │
│  - max_members          │
│  - max_admins           │
│  - capabilities (JSONB) │
└───────────┬─────────────┘
            │ FK
            ▼
┌─────────────────────────┐
│      communities        │
│  - id (PK)              │
│  - plan_id → plans.id   │  ← Détermine les limites SaaS
│  - subscription_status  │
└───────────┬─────────────┘
            │ FK
            ▼
┌─────────────────────────┐
│   membership_plans      │  ← Formules de cotisation (par communauté)
│  - id (PK)              │
│  - community_id         │
│  - name                 │
│  - amount (cents)       │
└─────────────────────────┘
```

### Mapping officiel

**Absent dans le code.** Le code utilise `plus/pro` (frontend/config) mais la DB utilise `growth/scale`.

Correction partielle appliquée dans `/api/admin/register` :

```typescript
// server/routes.ts (commit b7130fa)
const PLAN_ID_MAP: Record<string, string> = {
  "free": "free",
  "plus": "growth",
  "pro": "scale"
};
```

---

## 6) Recommandations

### Option A : Harmoniser les IDs (recommandé)

1. **Mettre à jour `DEFAULT_LIMITS` et `DEFAULT_CAPABILITIES`** pour utiliser `growth`/`scale` :

```typescript
export const DEFAULT_LIMITS = {
  free: { maxMembers: 20, maxAdmins: 1, maxTags: 10 },
  growth: { maxMembers: 100, maxAdmins: 2, maxTags: 50 },  // ← Renommer
  scale: { maxMembers: 250, maxAdmins: 5, maxTags: 200 },  // ← Renommer
  enterprise: { maxMembers: null, maxAdmins: 7, maxTags: 700 },
  whitelabel: { maxMembers: null, maxAdmins: 7, maxTags: 700 },
};
```

2. **Créer un mapping centralisé** pour le frontend :

```typescript
// shared/planMapping.ts
export const FRONTEND_TO_DB_PLAN_ID = {
  "free": "free",
  "plus": "growth",
  "pro": "scale",
  "enterprise": "enterprise",
  "whitelabel": "whitelabel"
};
```

### Option B : Renommer les IDs en base (risqué)

Mettre à jour la table `plans` pour utiliser `plus`/`pro` comme IDs.

**Risques** :
- FK violations sur les communautés existantes
- Nécessite migration de données

### Concernant `membership_plans`

**Aucun seed nécessaire.** Cette table est fonctionnellement différente des plans SaaS.

Elle doit rester vide au démarrage car chaque communauté crée ses propres formules de cotisation via l'interface admin.

---

## 7) Décision finale

| Action | Priorité | Statut |
|--------|----------|--------|
| Corriger le mismatch `DEFAULT_LIMITS` (plus→growth, pro→scale) | P0 | À faire |
| Centraliser le mapping frontend→DB | P1 | Partiel (admin/register) |
| Documenter la séparation `plans` vs `membership_plans` | P2 | Ce document |
| Geler le billing v2 | - | **Non nécessaire** |
| Seed de `membership_plans` | - | **Non applicable** |

---

## Fichiers concernés

- `server/lib/planLimits.ts` : DEFAULT_LIMITS, DEFAULT_CAPABILITIES
- `shared/plans.ts` : KOOMY_PLANS (utilise plus/pro)
- `shared/schema.ts` : définition des tables plans et membership_plans
- `server/routes.ts` : mapping partiel dans /api/admin/register
- `server/seed.ts` : seed des plans depuis KOOMY_PLANS
