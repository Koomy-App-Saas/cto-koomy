# BILLING — Fix CORS verify-checkout-session + Stabiliser membership-plans

## Contexte

Après un paiement Stripe (upgrade KOOMY) dans le Backoffice SANDBOX, l'utilisateur revient sur:
`/billing/return?status=success&session_id=cs_test_...`

Le front appelait:
`POST https://api-sandbox.koomy.app/api/billing/verify-checkout-session`

Mais le navigateur bloquait:
`CORS policy: Request header field session_id is not allowed by Access-Control-Allow-Headers in preflight response.`

Ensuite, la création d'une offre d'adhésion payante échouait:
`POST /api/communities/:communityId/membership-plans -> 500`

## Problème identifié

Le frontend utilisait `apiGet("/api/billing/verify-checkout-session", { session_id: sessionId })`.

Le second paramètre de `apiGet` est **headers**, pas des query params. Donc `session_id` était envoyé comme header custom, provoquant une erreur CORS car ce header n'était pas dans la liste autorisée.

## Solution A — verify-checkout-session (CORS fix)

### Avant
```typescript
const response = await apiGet("/api/billing/verify-checkout-session", { session_id: sessionId });
```

### Après
```typescript
const response = await apiGet(`/api/billing/verify-checkout-session?session_id=${encodeURIComponent(sessionId)}`);
```

Le `session_id` est maintenant passé en query param, plus de header custom = plus de CORS.

## Solution B — membership-plans (pas de 500)

### Ajouts
1. **403 UPGRADE_REQUIRED** : Si plan KOOMY n'a pas la capability `dues`
2. **409 STRIPE_CONNECT_REQUIRED** : Si Stripe Connect n'est pas ACTIVE pour les tarifs payants
3. **422 VALIDATION_ERROR** : Pour toute erreur de validation/DB (catch bloc amélioré)
4. **409 DUPLICATE_ENTRY** : Si slug/nom déjà existant

### Code ajouté
```typescript
// Check Stripe Connect is configured for paid plans
const community = await storage.getCommunity(communityId);
if (community && !community.whiteLabel) {
  const connectStatus = community.stripeConnectStatus || "NOT_CONNECTED";
  if (connectStatus !== "ACTIVE") {
    return res.status(409).json({
      code: "STRIPE_CONNECT_REQUIRED",
      connectStatus,
      error: "Veuillez configurer Stripe Connect avant de créer des tarifs payants."
    });
  }
}
```

### Catch bloc normalisé
```typescript
catch (error: any) {
  // Handle known error codes
  if (error.code === "UNIQUE_VIOLATION" || error.message?.includes("unique")) {
    return res.status(409).json({ code: "DUPLICATE_ENTRY", ... });
  }
  if (error.code === "FOREIGN_KEY_VIOLATION") {
    return res.status(422).json({ code: "INVALID_REFERENCE", ... });
  }
  // Generic
  return res.status(422).json({ code: "VALIDATION_ERROR", ... });
}
```

## Fichiers modifiés

| Fichier | Changement |
|---------|------------|
| `client/src/pages/admin/billing/Return.tsx` | session_id en query param au lieu de header |
| `server/routes.ts` | Ajout check Stripe Connect + normalisation erreurs 403/409/422 |

## Comportement après fix

| Scénario | Code HTTP | Code |
|----------|-----------|------|
| verify-checkout-session OK | 200 | - |
| verify-checkout-session invalid session | 400 | - |
| membership-plans plan Free | 403 | UPGRADE_REQUIRED |
| membership-plans sans Stripe Connect | 409 | STRIPE_CONNECT_REQUIRED |
| membership-plans slug dupliqué | 409 | DUPLICATE_ENTRY |
| membership-plans erreur validation | 422 | VALIDATION_ERROR |
| membership-plans success | 201 | - |

## Requêtes SQL de vérification

```sql
-- Tables présentes
SELECT table_name FROM information_schema.tables 
WHERE table_schema='public' 
AND table_name IN ('communities','membership_plans','subscriptions');
-- Résultat: communities, membership_plans ✓

-- Colonnes pertinentes
SELECT column_name, data_type FROM information_schema.columns 
WHERE table_name = 'communities' 
AND column_name IN ('stripe_connect_status', 'subscription_status', 'plan_id');
-- Résultat: 
-- stripe_connect_status | USER-DEFINED
-- subscription_status | USER-DEFINED
-- plan_id | character varying ✓
```

## Tests manuels

| Test | Étapes | Résultat attendu |
|------|--------|------------------|
| Checkout return | 1. Compléter paiement Stripe 2. Retour sur /billing/return | Plus de CORS, status vérifié |
| Plan payant sans Connect | 1. Plan PLUS 2. Créer tarif payant | 409 STRIPE_CONNECT_REQUIRED |
| Plan Free + tarif payant | 1. Plan Free 2. Créer tarif payant | 403 UPGRADE_REQUIRED |
| Plan + Connect OK | 1. Plan PLUS 2. Connect ACTIVE 3. Créer tarif | 201 Created |

---

FIN
