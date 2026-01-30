# P0 Backend: Freemium Dues Override - Nested Capabilities Fix

**Date:** 2026-01-29
**Type:** REPORT
**Domain:** CAPABILITY
**Status:** COMPLETE

## Problème

```
POST /api/communities/:id/membership-plans => 403
Response: {"code":"UPGRADE_REQUIRED","capability":"dues", ...}
```

La DB avait `capabilities.features.cotisations = true` mais le code vérifiait `capabilities.dues` (structure plate).

## Cause Racine

Structure en DB:
```json
{
  "features": {
    "cotisations": true,
    "tags": false,
    ...
  },
  "admins": { "max": 1 },
  "members": { "max": 20 }
}
```

Structure attendue par le code (DEFAULT_CAPABILITIES):
```typescript
{
  dues: true,
  analytics: false,
  ...
}
```

## Solution Implémentée

### 1. `hasCapability()` - Multi-path Checking

**Fichier:** `server/lib/planLimits.ts`

```typescript
export function hasCapability(capabilities: PlanCapabilities, key: CapabilityKey): boolean {
  // Check flat structure (from DEFAULT_CAPABILITIES constants)
  if (capabilities[key] === true) {
    return true;
  }
  
  // Check nested DB structure: capabilities.features.[key]
  const featuresObj = (capabilities as any)?.features;
  if (featuresObj && typeof featuresObj === 'object') {
    if (featuresObj[key] === true) {
      return true;
    }
    // Legacy alias: "cotisations" -> "dues"
    if (key === "dues" && featuresObj.cotisations === true) {
      return true;
    }
  }
  
  // Legacy alias at flat level: "cotisations" -> "dues"
  if (key === "dues" && (capabilities as any).cotisations === true) {
    return true;
  }
  
  return false;
}
```

**Chemins vérifiés pour `dues`:**
1. `capabilities.dues` (flat, constants)
2. `capabilities.features.dues` (nested DB)
3. `capabilities.features.cotisations` (nested DB, legacy)
4. `capabilities.cotisations` (flat legacy)

### 2. Logging Diagnostic

**Fichier:** `server/lib/usageLimitsGuards.ts`

```typescript
// P0 Diagnostic log: capability denied
console.log("[CAPABILITY_DENIED]", {
  communityId,
  planId: effectivePlan.planId,
  capability,
  capabilitiesSnapshot: JSON.stringify(effectivePlan.capabilities),
  flatValue: (effectivePlan.capabilities as any)?.[capability],
  nestedValue: (effectivePlan.capabilities as any)?.features?.[capability],
  legacyCotisations: capability === "dues" ? {
    flat: (effectivePlan.capabilities as any)?.cotisations,
    nested: (effectivePlan.capabilities as any)?.features?.cotisations
  } : undefined
});
```

### 3. Tests Ajoutés

**Fichier:** `server/tests/usage-limits.test.ts`

| Test | Description |
|------|-------------|
| `features.dues = true` | DB nested structure |
| `features.cotisations = true` | DB nested legacy |
| Real DB structure | Simule la vraie structure production |

## Résultats des Tests

```
📋 hasCapability Alias Tests (dues ↔ cotisations, flat ↔ nested)
  ✅ hasCapability returns true when capabilities.dues = true (flat)
  ✅ hasCapability returns true when capabilities.features.dues = true (nested DB)
  ✅ hasCapability returns true when capabilities.features.cotisations = true (nested legacy)
  ✅ hasCapability returns true when capabilities.cotisations = true (flat legacy alias)
  ✅ hasCapability returns false when dues/cotisations missing at all levels
  ✅ hasCapability prefers dues=true over cotisations check
    → Real DB structure (features.cotisations=true) = has dues: true
  ✅ FREE plan with features.cotisations=true (real DB structure) allows membership-plans
    → FREE plan + dues=true + active status = can onboard: true
  ✅ FREE plan with dues=true in DB allows Stripe Connect onboarding (simulated)
    → FREE plan + cotisations=true (legacy) + active status = can onboard: true
  ✅ FREE plan with legacy cotisations=true in DB allows Stripe Connect onboarding (simulated)

==================================================
Results: 43/43 tests passed
```

## Fichiers Modifiés

| Fichier | Modification |
|---------|--------------|
| `server/lib/planLimits.ts` | `hasCapability()` vérifie flat + nested + legacy |
| `server/lib/usageLimitsGuards.ts` | Log diagnostic `[CAPABILITY_DENIED]` |
| `server/tests/usage-limits.test.ts` | +3 tests pour structure imbriquée |

## Preuve

Test simulant la vraie structure DB:
```
→ Real DB structure (features.cotisations=true) = has dues: true
```

Un plan FREE avec `capabilities.features.cotisations=true` pourra désormais créer des membership-plans payants (HTTP 200/201 attendu).

## Prochaines Étapes (Post-P0)

1. Valider en staging/prod avec création d'un membership-plan payant
2. Surveiller les logs `[CAPABILITY_DENIED]` pour détecter d'autres anomalies
3. Migrer DB vers `features.dues` au lieu de `features.cotisations` pour consistance

**Statut:** P0 COMPLETE ✅
