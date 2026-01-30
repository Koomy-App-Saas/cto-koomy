# Contrat Erreurs & Messages - P3.1

**ID:** KOOMY-P3.1  
**Date:** 2026-01-26  
**Status:** IMPLEMENTED

---

## 1. Principe Fondamental

**Règle produit:** Tout refus doit être clair + proposer une action.

- Cause explicite (code machine + message humain)
- Solution actionnable (CTA)
- Traçabilité (traceId)

---

## 2. Format JSON Standardisé

### 2.1 Structure ProductError

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
      "feature": "ADMINS",
      "capability": null,
      "currentPlan": "PLUS",
      "limit": 5,
      "current": 5,
      "communityId": "xxx-xxx"
    },
    "traceId": "PE-abc123-xyz789"
  }
}
```

### 2.2 Champs Obligatoires

| Champ | Type | Description |
|-------|------|-------------|
| `ok` | `false` | Toujours `false` pour les erreurs |
| `error.code` | `ProductErrorCode` | Code machine stable |
| `error.reason` | `ProductErrorReason` | Raison technique |
| `error.message` | `string` | Message utilisateur (FR) |
| `error.cta` | `ProductErrorCta` | Action suggérée |
| `error.traceId` | `string` | ID de trace unique |

### 2.3 Champs Optionnels

| Champ | Type | Description |
|-------|------|-------------|
| `error.context` | `object` | Contexte additionnel |
| `error.context.feature` | `string` | Fonctionnalité concernée |
| `error.context.limit` | `number` | Limite du plan |
| `error.context.current` | `number` | Utilisation actuelle |
| `error.context.currentPlan` | `string` | Plan actuel |

---

## 3. Codes d'Erreur (ProductErrorCode)

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `PLAN_GATING_DENIED` | 403 | Fonctionnalité nécessite un plan supérieur |
| `CAPABILITY_REQUIRED` | 403 | Capacité non incluse dans le plan |
| `QUOTA_EXCEEDED` | 403 | Limite de ressources atteinte |
| `PLAN_ADMIN_QUOTA_EXCEEDED` | 403 | Limite d'administrateurs atteinte |
| `AUTH_REQUIRED` | 401 | Authentification requise |
| `FORBIDDEN` | 403 | Accès interdit |
| `NOT_FOUND` | 404 | Ressource non trouvée |
| `VALIDATION_ERROR` | 400 | Données invalides |
| `SERVER_ERROR` | 500 | Erreur interne |
| `DB_SCHEMA_MISMATCH` | 500 | Schéma DB incompatible |
| `BILLING_BLOCKED` | 403 | Paiement requis |
| `ROLE_CHANGE_NOT_ALLOWED` | 400 | Changement de rôle interdit |

---

## 4. Raisons (ProductErrorReason)

| Reason | Description |
|--------|-------------|
| `CAPABILITY_REQUIRED` | Capacité plan requise |
| `LIMIT_EXCEEDED` | Quota dépassé |
| `PLAN_UPGRADE_REQUIRED` | Upgrade de plan nécessaire |
| `SUBSCRIPTION_PAST_DUE` | Paiement en retard |
| `SUBSCRIPTION_CANCELED` | Abonnement annulé |
| `UNAUTHORIZED` | Non authentifié |
| `INSUFFICIENT_PERMISSIONS` | Droits insuffisants |
| `RESOURCE_NOT_FOUND` | Ressource inexistante |
| `INVALID_INPUT` | Entrée invalide |
| `INTERNAL_ERROR` | Erreur serveur |
| `SCHEMA_MISSING` | Colonnes DB manquantes |

---

## 5. Types de CTA

| Type | Description | Comportement UI |
|------|-------------|-----------------|
| `UPGRADE` | Mise à niveau plan | Lien vers `/billing/upgrade` |
| `REQUEST_EXTENSION` | Demande extension | Modal ou `/support?subject=extension` |
| `CONTACT_SUPPORT` | Contact support | Lien vers `/support` |
| `NONE` | Pas d'action | Pas de bouton |

---

## 6. Exemples Concrets

### 6.1 Quota Administrateurs Atteint

```json
{
  "ok": false,
  "error": {
    "code": "PLAN_ADMIN_QUOTA_EXCEEDED",
    "reason": "LIMIT_EXCEEDED",
    "message": "Quota d'administrateurs atteint (2/2). Veuillez mettre à niveau votre plan.",
    "cta": {
      "type": "UPGRADE",
      "targetPlan": "PRO",
      "url": "/billing/upgrade?plan=PRO",
      "label": "Passer à PRO"
    },
    "context": {
      "feature": "ADMINS",
      "limit": 2,
      "current": 2,
      "currentPlan": "PLUS"
    },
    "traceId": "AJ-abc123"
  }
}
```

### 6.2 Fonctionnalité Tags Non Disponible

```json
{
  "ok": false,
  "error": {
    "code": "CAPABILITY_REQUIRED",
    "reason": "CAPABILITY_REQUIRED",
    "message": "Cette fonctionnalité (Tags) nécessite le plan PRO.",
    "cta": {
      "type": "UPGRADE",
      "targetPlan": "PRO",
      "url": "/billing/upgrade?plan=PRO",
      "label": "Passer à PRO"
    },
    "context": {
      "feature": "TAGS",
      "capability": "MANAGE_TAGS",
      "currentPlan": "PLUS"
    },
    "traceId": "PE-xyz789"
  }
}
```

### 6.3 Erreur Serveur

```json
{
  "ok": false,
  "error": {
    "code": "SERVER_ERROR",
    "reason": "INTERNAL_ERROR",
    "message": "Une erreur interne est survenue. Veuillez réessayer.",
    "cta": {
      "type": "CONTACT_SUPPORT",
      "url": "/support",
      "label": "Contacter le support"
    },
    "traceId": "PE-err456"
  }
}
```

---

## 7. Intégration UI

### 7.1 Composant ActionableError

```tsx
<ActionableError
  error={parsedError}
  onRetry={() => refetch()}
  onDismiss={() => setError(null)}
/>
```

### 7.2 Parsing Client

```typescript
import { parseApiError } from "@/lib/api/parseApiError";

try {
  await api.createTag(...);
} catch (error) {
  const parsed = parseApiError(error);
  if (parsed.isProductError) {
    // Afficher ActionableError
  }
}
```

---

## 8. Règles UX

1. **Jamais de spinner infini** - Toute erreur doit être captée
2. **Toujours un message humain** - Pas de codes techniques bruts
3. **Action claire** - Bouton CTA visible si applicable
4. **TraceId accessible** - Petit, copiable, pour le support

---

## 9. Fichiers de Référence

| Fichier | Description |
|---------|-------------|
| `server/lib/errors/productError.ts` | Helper central |
| `client/src/lib/api/parseApiError.ts` | Parser client |
| `client/src/components/errors/ActionableError.tsx` | Composant UI |
| `server/tests/product-error-contract.test.ts` | Tests contrat |

---

**Fin du Contrat**
