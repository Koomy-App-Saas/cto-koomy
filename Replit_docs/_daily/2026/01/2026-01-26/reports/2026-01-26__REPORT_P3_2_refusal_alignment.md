# P3.2 - Rapport de Clôture : Alignement des Refus

**Date:** 2026-01-26  
**Status:** TERMINÉ ✅

---

## 1. Objectif

Garantir que 100% des refus techniques passent par le contrat ProductError, avec:
- Code stable
- Message utilisateur clair
- CTA cohérent
- TraceId exploitable

---

## 2. Périmètre Audité

Routes auditées (selon AUDIT_admin_quota_enforcement_paths.md):

| Route | Points de Refus | Alignés |
|-------|-----------------|---------|
| POST /api/admin/join | 8 | ✅ 8/8 |
| POST /api/admin/join-with-credentials | 9 | ✅ 9/9 |
| POST /api/communities/:id/admins | 8 | ✅ 8/8 |
| PATCH /api/memberships/:id | 9 | ✅ 9/9 |
| **TOTAL** | **34** | **34/34** |

---

## 3. Corrections Appliquées

### 3.1 Import ProductError dans routes.ts

```typescript
import {
  makeQuotaExceededError,
  makeValidationError,
  makeAuthRequiredError,
  makeForbiddenError,
  makeNotFoundError,
  makeServerError,
  sendProductError
} from "./lib/errors/productError";
```

### 3.2 Mapping Code → Helper

| Ancien Code | Helper ProductError | HTTP |
|-------------|---------------------|------|
| `MISSING_JOIN_CODE` | makeValidationError | 400 |
| `INVALID_CODE_LENGTH` | makeValidationError | 400 |
| `FIREBASE_REQUIRED` | makeAuthRequiredError | 401 |
| `INVALID_JOIN_CODE` | makeNotFoundError | 404 |
| `FORBIDDEN_CONTRACT` | makeForbiddenError | 403 |
| `PLAN_ADMIN_QUOTA_EXCEEDED` | makeQuotaExceededError | 403 |
| `ALREADY_MEMBER` | makeValidationError | 409 |
| `INVALID_CREDENTIALS` | makeAuthRequiredError | 401 |
| `OWNER_REQUIRED` | makeForbiddenError | 403 |
| `INVALID_EMAIL` | makeValidationError | 400 |
| `FIRST_NAME_REQUIRED` | makeValidationError | 400 |
| `LAST_NAME_REQUIRED` | makeValidationError | 400 |
| `PERMISSIONS_REQUIRED` | makeValidationError | 400 |
| `INVALID_SECTION_SCOPE` | makeValidationError | 400 |
| `ROLE_CHANGE_NOT_ALLOWED` | makeValidationError | 400 |
| `auth_required` | makeAuthRequiredError | 401 |
| `membership_required` | makeForbiddenError | 403 |
| `insufficient_role` | makeForbiddenError | 403 |
| 500 catch | makeServerError | 500 |

---

## 4. Format Unifié de Réponse

Tous les refus retournent maintenant:

```json
{
  "ok": false,
  "error": {
    "code": "QUOTA_EXCEEDED",
    "reason": "LIMIT_EXCEEDED",
    "message": "Limite atteinte: 5/5 administrateurs. Passez au plan PRO.",
    "cta": {
      "type": "UPGRADE",
      "targetPlan": "PRO",
      "url": "/billing/upgrade?plan=PRO",
      "label": "Passer à PRO"
    },
    "context": {
      "feature": "administrateurs",
      "limit": 5,
      "current": 5,
      "currentPlan": "PLUS",
      "communityId": "xxx"
    },
    "traceId": "PE-abc123"
  }
}
```

---

## 5. Tests Contractuels

Fichier: `server/tests/refusal-contract.test.ts`

| Test | Vérifie |
|------|---------|
| ProductError Format Validation | ok:false, traceId, CTA |
| Admin Quota Exceeded Refusal | QUOTA_EXCEEDED code, context |
| Unauthorized Action Refusal | AUTH_REQUIRED, FORBIDDEN codes |
| Plan Gating Refusal | PLAN_GATING_DENIED code |
| Suspended State Refusal | BILLING_BLOCKED code |
| HTTP Status Code Mapping | 403/401/400/404/500 |
| Route-specific Refusals | All 34 paths documented |

---

## 6. Chemins Exclus (Hors Périmètre)

Les routes suivantes n'étaient PAS dans le périmètre AUDIT:

- POST /api/admin/register-community (création owner, N/A pour quota admin)
- POST /api/admin/register (création owner, N/A pour quota admin)
- POST /api/memberships (force role=member, N/A pour admin)

Ces routes n'ont pas été modifiées car hors scope P3.2.

---

## 7. Dette Restante

| Item | Status | Note |
|------|--------|------|
| Middleware global errorHandler | Non implémenté | Peut être ajouté P3.3 |
| UI integration ActionableError | Prêt | Composant créé, intégration écrans P3.4 |
| Routes hors périmètre | Non alignées | Peuvent être traitées P3.3 |

---

## 8. Critères de Sortie

- [x] Tous les chemins audités passent par ProductError
- [x] Aucun refus brut restant dans le périmètre
- [x] Rapport signé
- [x] Tests verts

---

## 9. Fichiers Modifiés

| Fichier | Modifications |
|---------|---------------|
| `server/routes.ts` | Import ProductError, 34 refus alignés |
| `server/tests/refusal-contract.test.ts` | Tests contractuels |
| `docs/rapports/REPORT_P3_2_refusal_inventory.md` | Inventaire |
| `docs/rapports/REPORT_P3_2_refusal_alignment.md` | Ce rapport |

---

**Signature:** P3.2 TERMINÉ  
**Date:** 2026-01-26

---

**Fin du Rapport**
