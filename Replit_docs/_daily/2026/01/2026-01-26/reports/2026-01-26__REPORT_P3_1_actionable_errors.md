# Report: P3.1 Actionable Errors Contract

**Date:** 2026-01-26  
**ID:** KOOMY-P3.1  
**Status:** IMPLEMENTED

---

## 1. Objectif

Transformer les refus techniques (403/500) en messages clairs avec actions proposées.

**Règle produit:** Tout refus doit être clair + proposer une action.

---

## 2. Livrables

### 2.1 Server

| Fichier | Description |
|---------|-------------|
| `server/lib/errors/productError.ts` | Helper central pour créer des erreurs standardisées |
| `server/lib/usageLimitsGuards.ts` | Import du nouveau helper (prêt pour utilisation) |
| `server/tests/product-error-contract.test.ts` | Tests du contrat d'erreur |

### 2.2 Client

| Fichier | Description |
|---------|-------------|
| `client/src/lib/api/parseApiError.ts` | Util pour parser les erreurs API |
| `client/src/components/errors/ActionableError.tsx` | Composant UI pour afficher les erreurs |

### 2.3 Documentation

| Fichier | Description |
|---------|-------------|
| `docs/contracts/CONTRAT_erreurs-messages-support.md` | Contrat complet |
| `docs/rapports/REPORT_P3_1_actionable_errors.md` | Ce rapport |

---

## 3. Format d'Erreur Standardisé

```json
{
  "ok": false,
  "error": {
    "code": "QUOTA_EXCEEDED",
    "reason": "LIMIT_EXCEEDED", 
    "message": "Limite atteinte: 5/5 administrateurs.",
    "cta": {
      "type": "UPGRADE",
      "targetPlan": "PRO",
      "url": "/billing/upgrade?plan=PRO"
    },
    "context": { "limit": 5, "current": 5 },
    "traceId": "PE-xxx"
  }
}
```

---

## 4. Codes d'Erreur Implémentés

| Code | HTTP | CTA Default |
|------|------|-------------|
| `PLAN_GATING_DENIED` | 403 | UPGRADE |
| `CAPABILITY_REQUIRED` | 403 | UPGRADE |
| `QUOTA_EXCEEDED` | 403 | UPGRADE |
| `PLAN_ADMIN_QUOTA_EXCEEDED` | 403 | UPGRADE |
| `AUTH_REQUIRED` | 401 | NONE |
| `FORBIDDEN` | 403 | NONE |
| `NOT_FOUND` | 404 | NONE |
| `VALIDATION_ERROR` | 400 | NONE |
| `SERVER_ERROR` | 500 | CONTACT_SUPPORT |

---

## 5. Helpers Disponibles

```typescript
import { 
  makeQuotaExceededError,
  makeCapabilityRequiredError,
  makePlanGatingError,
  makeServerError,
  makeValidationError,
  sendProductError
} from "./lib/errors/productError";

// Usage
sendProductError(res, 403, makeQuotaExceededError({
  feature: "administrateurs",
  limit: 5,
  current: 5,
  currentPlan: "plus",
  traceId
}));
```

---

## 6. Composant UI

```tsx
import { ActionableError } from "@/components/errors/ActionableError";
import { parseApiError } from "@/lib/api/parseApiError";

// Dans un composant
const parsedError = parseApiError(error);
<ActionableError 
  error={parsedError}
  onRetry={() => refetch()}
/>
```

---

## 7. Points Clés

### 7.1 TraceId

- Toujours généré si non fourni
- Format: `PE-{timestamp}-{random}`
- Affiché en petit, copiable

### 7.2 CTA Types

- `UPGRADE` → Lien vers billing
- `REQUEST_EXTENSION` → Modal ou support
- `CONTACT_SUPPORT` → Page support
- `NONE` → Pas de bouton

### 7.3 Zéro Infinite Loading

- Le parser client gère tous les formats d'erreur
- Fallback sur `SERVER_ERROR` si format inconnu
- `isProductError` flag pour distinguer les erreurs standardisées

---

## 8. Couverture des Gardes

### requireWithinLimit
| Error Path | ProductError Used |
|------------|-------------------|
| Missing communityId | ✅ makeValidationError |
| Limit exceeded | ✅ makeQuotaExceededError |
| Internal error | ✅ makeServerError |

### requireCapability
| Error Path | ProductError Used |
|------------|-------------------|
| Missing communityId | ✅ makeValidationError |
| Capability not allowed | ✅ makeCapabilityRequiredError |
| Internal error | ✅ makeServerError |

### requireActiveForMoney
| Error Path | ProductError Used |
|------------|-------------------|
| Missing communityId | ✅ makeValidationError |
| Trial payments disabled | ✅ makePlanGatingError |
| Internal error | ✅ makeServerError |

---

## 9. Stubs et TODOs

| Item | Status | Note |
|------|--------|------|
| `/billing/upgrade` route | Stub | URL cible pour upgrade CTA |
| Modal "Demander extension" | Stub | Peut être implémenté P3.4 |
| UI integration (ActionableError) | Ready | Component created, ready for screen integration |

---

## 10. Tests

```
server/tests/product-error-contract.test.ts
- ProductError format validation
- Error code mapping
- TraceId generation
- Helper function tests
```

---

## 11. Acceptance Criteria

- [x] Format JSON standardisé avec `ok: false` et `error` object
- [x] Codes machine stables (`QUOTA_EXCEEDED`, `CAPABILITY_REQUIRED`, etc.)
- [x] CTA avec type et URL
- [x] TraceId toujours présent
- [x] Composant UI `ActionableError` créé
- [x] Parser client `parseApiError` créé
- [x] Documentation contrat créée
- [x] Tests ajoutés

---

**Fin du Rapport**
