# P0 Backend: hasCapability Alias Hardening Report

**Date:** 2026-01-29
**Type:** REPORT
**Domain:** CAPABILITY
**Status:** COMPLETE

## Contexte

La DB production utilise `dues` comme clé canonique pour la capacité Finance.
Le code legacy utilisait parfois `cotisations`.

**Risque:** Si le code vérifie uniquement `cotisations`, alors `dues=true` en DB est ignoré.

## Analyse

### Fonction Centrale: `hasCapability()`

**Fichier:** `server/lib/planLimits.ts` (lignes 417-425)

```typescript
export function hasCapability(capabilities: PlanCapabilities, key: CapabilityKey): boolean {
  if (capabilities[key] === true) {
    return true;
  }
  if (key === "dues" && (capabilities as any).cotisations === true) {
    return true;
  }
  return false;
}
```

**Comportement:**
1. Vérifie d'abord `capabilities[key]` (canonique: `dues`)
2. Si `key === "dues"` et pas trouvé, vérifie `cotisations` (legacy alias)
3. Retourne `true` si l'un ou l'autre est `true`

### Utilisation dans les Guards

| Guard | Fichier | Ligne | Utilise hasCapability |
|-------|---------|-------|----------------------|
| Money Features | server/routes.ts | 867 | ✅ `hasCapability(effectivePlan.capabilities, "dues")` |
| Stripe Connect | server/routes.ts | 11464 | ✅ `hasCapability(effectivePlan.capabilities, "dues")` |
| Capability Guard | server/lib/usageLimitsGuards.ts | 155 | ✅ `hasCapability(effectivePlan.capabilities, capability)` |

### Aucune Vérification Directe Dangereuse

Recherche `capabilities.xxx === true` :
- `eventPaidQuota !== null` : vérification de quota, pas de capability boolean ✅
- Tests unitaires : accès lecture seule ✅

## Tests Ajoutés

**Fichier:** `server/tests/usage-limits.test.ts`

```typescript
test("hasCapability returns true when capabilities.dues = true", () => {
  const caps = { dues: true, analytics: false, exportData: false, advancedAnalytics: false, eventPaidQuota: null };
  return hasCapability(caps, "dues") === true;
});

test("hasCapability returns true when capabilities.cotisations = true (legacy alias)", () => {
  const legacyCaps = { cotisations: true, ... } as any;
  return hasCapability(legacyCaps, "dues") === true;
});

test("hasCapability returns false when both dues and cotisations are missing/false", () => {
  const caps = { dues: false, ... };
  return hasCapability(caps, "dues") === false;
});

test("hasCapability prefers dues=true over cotisations check", () => {
  const caps = { dues: true, cotisations: false, ... } as any;
  return hasCapability(caps, "dues") === true;
});

test("FREE plan with dues=true in DB allows Stripe Connect onboarding (simulated)", () => {
  // dues=true + subscriptionStatus="active" = can onboard
  return canOnboard === true;
});

test("FREE plan with legacy cotisations=true in DB allows Stripe Connect onboarding (simulated)", () => {
  // cotisations=true (legacy) + subscriptionStatus="active" = can onboard
  return canOnboard === true;
});
```

## Résultat des Tests

```
📋 hasCapability Alias Tests (dues ↔ cotisations)
  ✅ hasCapability returns true when capabilities.dues = true
  ✅ hasCapability returns true when capabilities.cotisations = true (legacy alias)
  ✅ hasCapability returns false when both dues and cotisations are missing/false
  ✅ hasCapability prefers dues=true over cotisations check
    → FREE plan + dues=true + active status = can onboard: true
  ✅ FREE plan with dues=true in DB allows Stripe Connect onboarding (simulated)
    → FREE plan + cotisations=true (legacy) + active status = can onboard: true
  ✅ FREE plan with legacy cotisations=true in DB allows Stripe Connect onboarding (simulated)

==================================================
Results: 40/40 tests passed
```

## Fichiers Modifiés

| Fichier | Modification |
|---------|--------------|
| `server/tests/usage-limits.test.ts` | +6 tests pour alias dues/cotisations |

## Fichiers Audités (aucune modification requise)

| Fichier | Statut |
|---------|--------|
| `server/lib/planLimits.ts` | ✅ hasCapability déjà implémenté correctement |
| `server/routes.ts` | ✅ Guards utilisent hasCapability |
| `server/lib/usageLimitsGuards.ts` | ✅ checkCapability utilise hasCapability |

## Preuves

### FREE plan avec dues=true autorisé
```
→ FREE plan + dues=true + active status = can onboard: true
```

### FREE plan avec cotisations=true (legacy) autorisé
```
→ FREE plan + cotisations=true (legacy) + active status = can onboard: true
```

## Conclusion

L'alias `cotisations` → `dues` est correctement implémenté dans `hasCapability()`.
Tous les guards Finance/Stripe Connect utilisent cette fonction centrale.
Aucun code ne contourne cette vérification.

**Statut:** P0 COMPLETE ✅
