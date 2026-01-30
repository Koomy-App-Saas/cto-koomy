# Rapport : Diff technique Enterprise Bypass Guards

**Date**: 2026-01-23  
**Référence**: Addendum P2.8.1

---

## 1. Fichiers modifiés

| Fichier | Lignes ajoutées | Lignes modifiées | Type |
|---------|-----------------|------------------|------|
| `server/lib/whiteLabelAccessor.ts` | ~45 | 0 | Nouvelles fonctions |
| `server/lib/planLimits.ts` | ~10 | ~20 | Extension interface + select |
| `server/lib/subscriptionGuards.ts` | 0 | ~12 | Remplacement conditions |
| `server/lib/usageLimitsGuards.ts` | 0 | ~9 | Remplacement conditions |

**Total**: 4 fichiers

---

## 2. Résumé par fichier

### 2.1 server/lib/whiteLabelAccessor.ts

**Ajouts**:

```typescript
// Nouvelles fonctions ajoutées

export function isEnterpriseAccountSync(community: { accountType?: string | null }): boolean {
  return community.accountType === "GRAND_COMPTE";
}

export async function isEnterpriseAccount(communityId: string): Promise<boolean> {
  const community = await db.query.communities.findFirst({
    where: eq(communities.id, communityId),
    columns: { accountType: true }
  });
  return community?.accountType === "GRAND_COMPTE";
}

export function shouldBypassGuardsSync(community: { 
  accountType?: string | null; 
  whiteLabel?: boolean | null;
}): boolean {
  if (isEnterpriseAccountSync(community)) return true;
  if (isWhiteLabelBypassEnabledSync(community)) return true;
  return false;
}
```

**Risque**: Aucun (code additif)

### 2.2 server/lib/planLimits.ts

**Modifications**:

```typescript
// Interface EffectivePlan — ajout de 2 champs
export interface EffectivePlan extends PlanLimits {
  // ... existants
  isEnterprise: boolean;    // AJOUTÉ
  accountType: string | null; // AJOUTÉ
}

// getCommunityLimits — ajout au select et retour
.select({
  // ... existants
  accountType: communities.accountType, // AJOUTÉ
})
// ...
const isEnterprise = community.accountType === "GRAND_COMPTE"; // AJOUTÉ
return {
  // ... existants
  isEnterprise,     // AJOUTÉ
  accountType: community.accountType, // AJOUTÉ
};

// getEffectivePlan — même pattern
```

**Risque**: Faible (extension de structure)

### 2.3 server/lib/subscriptionGuards.ts

**Import modifié**:

```typescript
// Avant
import { isWhiteLabelBypassEnabledSync } from "./whiteLabelAccessor";

// Après
import { shouldBypassGuardsSync, isEnterpriseAccountSync } from "./whiteLabelAccessor";
```

**Conditions modifiées**:

```typescript
// Avant (3 endroits)
if (isWhiteLabelBypassEnabledSync(community)) { ... }

// Après
if (shouldBypassGuardsSync(community)) { ... }
```

```typescript
// enforceCommunityPlanLimits — Avant
if (limits.isWhiteLabel) {
  return { ..., reason: "WHITE_LABEL_BYPASS" };
}

// Après
if (limits.isEnterprise || limits.isWhiteLabel) {
  return { ..., reason: limits.isEnterprise ? "ENTERPRISE_BYPASS" : "WHITE_LABEL_BYPASS" };
}
```

**Risque**: Faible (comportement préservé via shouldBypassGuardsSync)

### 2.4 server/lib/usageLimitsGuards.ts

**Conditions modifiées (3 endroits)**:

```typescript
// Avant
if (effectivePlan.isWhiteLabel) { return { allowed: true }; }

// Après
if (effectivePlan.isEnterprise || effectivePlan.isWhiteLabel) { return { allowed: true }; }
```

**Risque**: Faible (extension de condition, non-régression WL)

---

## 3. Rollback minimal

### Si problème avec Enterprise bypass

```bash
# Rollback git
git revert HEAD

# OU rollback manuel
# 1. Supprimer les nouvelles fonctions de whiteLabelAccessor.ts
# 2. Retirer isEnterprise/accountType de planLimits.ts
# 3. Restaurer les conditions originales dans les guards
```

### Impact rollback

- Retour au comportement WL-proxy
- Clients Enterprise non-WL perdent le bypass
- Clients WL existants non impactés

---

## 4. Tests de non-régression

```bash
# Vérifier compilation
npx tsc --noEmit

# Vérifier garde-fou WL
./scripts/check-wl-debt-propagation.sh

# Démarrer application
npm run dev
```

---

**Fin du rapport diff.**
