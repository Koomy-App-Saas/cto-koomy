# P3.3 - Rapport de Clôture : Global ErrorHandler

**Date:** 2026-01-26  
**Status:** TERMINÉ ✅

---

## 1. Objectif

Implémenter un middleware Express global `errorHandler` qui garantit que **toute erreur API** sort au format **ProductError** sans fuite d'informations sensibles (DB/Stripe/stack) en production.

---

## 2. Fichiers Créés/Modifiés

| Fichier | Action |
|---------|--------|
| `server/middlewares/errorHandler.ts` | CRÉÉ - Middleware global |
| `server/index.ts` | MODIFIÉ - Import + intégration + routes test-only |
| `server/tests/error-handler-contract.test.ts` | CRÉÉ - Tests contractuels |
| `docs/rapports/REPORT_P3_3_global_error_handler.md` | CRÉÉ - Ce rapport |

---

## 3. Mapping des Classes d'Erreurs

| Classe | Détection | ProductError Code | HTTP | Message |
|--------|-----------|-------------------|------|---------|
| **ProductError** | `instanceof ProductErrorException` ou structure ProductError | Préservé | Préservé | Préservé |
| **Stripe** | `err.type.startsWith("Stripe")` | SERVER_ERROR | 500 | "Une erreur est survenue lors du paiement." |
| **DB/Postgres** | `err.code` dans codes PG (23505, 23503, etc.) | SERVER_ERROR | 500 | "Une erreur est survenue." |
| **Zod** | `instanceof ZodError` | VALIDATION_ERROR | 400 | "Données invalides." |
| **Unknown** | Catch-all | SERVER_ERROR | 500 | "Une erreur est survenue." |

---

## 4. Routes Test-Only

Routes disponibles **uniquement en NODE_ENV=test** :

| Route | Erreur simulée |
|-------|----------------|
| `/api/__test__/throw/product` | ProductErrorException |
| `/api/__test__/throw/stripe` | StripeCardError |
| `/api/__test__/throw/db` | PostgreSQL error 23505 |
| `/api/__test__/throw/zod` | ZodError |
| `/api/__test__/throw/unknown` | Generic Error |

⚠️ Ces routes ne sont PAS exposées en production.

---

## 5. Contexte Logging

Chaque erreur est loggée avec:

```javascript
{
  traceId: "PE-xxx",
  code: "SERVER_ERROR",
  class: "stripe|db|zod|product|unknown",
  method: "GET",
  path: "/api/...",
  userId: "xxx" (si disponible),
  communityId: "xxx" (si disponible)
}
```

Les stack traces sont loggées **uniquement** en NODE_ENV !== "production".

---

## 6. Format de Réponse Garanti

Toutes les erreurs retournent:

```json
{
  "ok": false,
  "error": {
    "code": "SERVER_ERROR",
    "reason": "INTERNAL_ERROR",
    "message": "Une erreur est survenue.",
    "cta": {
      "type": "CONTACT_SUPPORT",
      "url": "/support",
      "label": "Contacter le support"
    },
    "context": {
      "provider": "stripe|db|unknown"
    },
    "traceId": "PE-xxx"
  }
}
```

---

## 7. Tests Ajoutés

Fichier: `server/tests/error-handler-contract.test.ts`

| Suite | Tests |
|-------|-------|
| ProductError Format Guarantee | 2 |
| Error Classification: ProductError | 2 |
| Error Classification: Stripe | 4 |
| Error Classification: DB/Postgres | 4 |
| Error Classification: Zod | 3 |
| Error Classification: Unknown | 4 |
| No Information Leakage | 3 |
| HTTP Status Code Mapping | 3 |
| TraceId Correlation | 2 |
| **TOTAL** | **27** |

---

## 8. Non-Régression P3.2

- Les routes P3.2 (POST /api/admin/join, POST /api/admin/join-with-credentials, POST /api/communities/:id/admins, PATCH /api/memberships/:id) n'ont PAS été modifiées
- Les tests P3.2 (`server/tests/refusal-contract.test.ts`) restent verts

---

## 9. Checklist Finale

- [x] Middleware créé (`server/middleware/errorHandler.ts`)
- [x] Middleware branché après toutes les routes
- [x] Routes test-only uniquement en NODE_ENV=test
- [x] Tests P3.3 créés
- [x] Aucune modification métier dans routes existantes
- [x] Pas de fuite d'informations sensibles

---

## 10. Critères de Sortie

- [x] 100% des erreurs capturées sortent en ProductError
- [x] Pas de fuite d'infos sensibles (DB/Stripe/stack)
- [x] Non régression P3.2

---

**Signature:** P3.3 TERMINÉ  
**Date:** 2026-01-26

---

**Fin du Rapport**
