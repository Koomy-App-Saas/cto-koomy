# RAPPORT — Alignement Plan Limits

**Date** : 25 janvier 2026  
**Priorité** : P0  
**Statut** : Implémenté et vérifié  

---

## 1. Contexte

Incohérence détectée entre deux sources de vérité pour les quotas membres :

| Source | Fichier | FREE.maxMembers |
|--------|---------|-----------------|
| KOOMY_PLANS | `shared/plans.ts` | 20 |
| DEFAULT_LIMITS | `server/lib/planLimits.ts` | 50 |

**Impact** : Selon le fallback utilisé, le quota FREE varie entre 20 et 50.

---

## 2. Tableau Avant / Après

### DEFAULT_LIMITS (server/lib/planLimits.ts)

| Plan | maxMembers AVANT | maxMembers APRÈS | maxAdmins AVANT | maxAdmins APRÈS | maxTags |
|------|------------------|------------------|-----------------|-----------------|---------|
| FREE | **50** | **20** | 1 | 1 | 10 |
| PLUS | **500** | **300** | 3 | **null** | 50 |
| PRO | **5000** | **1000** | 10 | **null** | 200 |
| ENTERPRISE | null | null | null | null | 700 |
| WHITELABEL | null | null | null | null | 700 |

### Source de vérité finale : KOOMY_PLANS (shared/plans.ts)

| Plan | maxMembers | maxAdmins |
|------|------------|-----------|
| FREE | 20 | 1 |
| PLUS | 300 | null |
| PRO | 1000 | null |
| GRAND_COMPTE | null | null |

---

## 3. Stratégie de Garde-fou

### Mode : **Strict (Bloc au démarrage)**

Le serveur refuse de démarrer si une divergence est détectée.

### Implémentation

**Fichier** : `server/index.ts` (section PLAN LIMITS DRIFT GUARD)

```typescript
const PLAN_LIMIT_MAPPINGS = [
  { planCode: PLAN_CODES.FREE, defaultLimitKey: "free" },
  { planCode: PLAN_CODES.PLUS, defaultLimitKey: "plus" },
  { planCode: PLAN_CODES.PRO, defaultLimitKey: "pro" },
  { planCode: PLAN_CODES.GRAND_COMPTE, defaultLimitKey: "enterprise" },
];

const EXPECTED_DEFAULT_LIMITS = {
  free: { maxMembers: 20, maxAdmins: 1 },
  plus: { maxMembers: 300, maxAdmins: null },
  pro: { maxMembers: 1000, maxAdmins: null },
  enterprise: { maxMembers: null, maxAdmins: null },
};

// Comparaison au boot
for (const { planCode, defaultLimitKey } of PLAN_LIMIT_MAPPINGS) {
  // ... vérification des valeurs
}

if (planDriftErrors.length > 0) {
  console.error("🚫 FATAL: PLAN LIMITS DRIFT DETECTED");
  process.exit(1);
}
```

### Comportement

| Environnement | Comportement si drift |
|---------------|----------------------|
| Sandbox | `process.exit(1)` |
| Production | `process.exit(1)` |
| Development | `process.exit(1)` |

### Message d'erreur

```
═══════════════════════════════════════════════════════════════
🚫 FATAL: PLAN LIMITS DRIFT DETECTED
═══════════════════════════════════════════════════════════════
   DEFAULT_LIMITS (server/lib/planLimits.ts) diverge de
   KOOMY_PLANS (shared/plans.ts).

   Mismatches:
   - free.maxMembers: KOOMY_PLANS=20, DEFAULT_LIMITS=50

   Corrigez la divergence avant de relancer le serveur.
═══════════════════════════════════════════════════════════════
```

---

## 4. Test Automatique

### Fichier

`server/tests/plan-limits-alignment.test.ts`

### Contenu

Test Node.js natif (node:test) vérifiant la cohérence des valeurs.

### Exécution

```bash
npx tsx --test server/tests/plan-limits-alignment.test.ts
```

### Cas testés

| Test | Description |
|------|-------------|
| FREE | maxMembers=20, maxAdmins=1 |
| PLUS | maxMembers=300, maxAdmins=null |
| PRO | maxMembers=1000, maxAdmins=null |
| ENTERPRISE | maxMembers=null, maxAdmins=null |
| maxTags | Valeurs définies pour tous les plans |

---

## 5. Fichiers Modifiés

| Fichier | Modification |
|---------|--------------|
| `server/lib/planLimits.ts` | Alignement DEFAULT_LIMITS + commentaire |
| `server/index.ts` | Ajout garde-fou PLAN LIMITS DRIFT GUARD |
| `server/tests/plan-limits-alignment.test.ts` | Nouveau test |

---

## 6. Validation

### Démarrage serveur

```
[STARTUP] ✓ Plan limits consistency verified (KOOMY_PLANS ↔ DEFAULT_LIMITS)
```

### Test

```
✔ Plan Limits Alignment > FREE plan limits match (X ms)
✔ Plan Limits Alignment > PLUS plan limits match (X ms)
✔ Plan Limits Alignment > PRO plan limits match (X ms)
✔ Plan Limits Alignment > ENTERPRISE plan limits match (X ms)
✔ Plan Limits Alignment > maxTags limits are defined (X ms)
```

---

## 7. Note sur maxTags

Les valeurs `maxTags` sont définies uniquement dans `DEFAULT_LIMITS` car absentes de `KOOMY_PLANS`.

| Plan | maxTags |
|------|---------|
| FREE | 10 |
| PLUS | 50 |
| PRO | 200 |
| ENTERPRISE | 700 |
| WHITELABEL | 700 |

Ces valeurs ne font pas partie du garde-fou car non présentes dans KOOMY_PLANS.

---

**Fin du rapport**
