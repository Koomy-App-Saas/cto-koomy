# STRIPE — Stripe Connect Free/Trial Guard + Error Normalization

## Décision Produit (FIGÉE)
Stripe Connect est une fonctionnalité PAYANTE.
Un club ne peut PAS configurer Stripe Connect tant qu'il n'a pas upgradé vers une offre payante.
Cela s'applique même pendant les 14 jours gratuits sans carte (trial sans carte).
Raison: on ne peut pas encaisser de l'argent via Koomy sans être client payant.

## Contexte Bug
Dans le Backoffice sandbox, un compte en plan Free clique "Configurer Stripe Connect":
- `POST /api/billing/stripe-connect/onboarding-link` → 500
- bodySnippet: `{"error":"You can only create new accounts if you'..."}`

Problèmes:
1. UX: en plan Free ou trial, cette action devrait être bloquée par une modal "Fonctionnalité Premium"
2. API: le endpoint renvoyait 500 au lieu d'une erreur business claire (403 upgradeRequired)

## Solution Implémentée

### A) Frontend Guard (Finances.tsx)

```typescript
const handleConnectStripe = () => {
  // Block if plan doesn't have dues capability (Free plan)
  if (currentPlan && !currentPlan.capabilities?.dues) {
    showUpgradeRequired({
      message: "La configuration de Stripe Connect nécessite une offre payante.",
      currentPlan: currentPlan.name || "Free",
      feature: "STRIPE_CONNECT"
    });
    return;
  }
  // Block if still in trial (no payment confirmed)
  if (community?.subscriptionStatus === "trialing") {
    showUpgradeRequired({
      message: "Stripe Connect nécessite un abonnement payant confirmé. Veuillez finaliser votre paiement.",
      currentPlan: currentPlan?.name || "Trial",
      feature: "STRIPE_CONNECT"
    });
    return;
  }
  setIsConnecting(true);
  connectStripeMutation.mutate();
};
```

- Vérifie la capacité `dues` du plan (bloque Free)
- Vérifie le statut d'abonnement `trialing` (bloque trial sans paiement)
- Bloque AVANT l'appel API si non éligible
- Réutilise `useUpgradeRequired` déjà existant

### B) Backend Guard (routes.ts)

```typescript
// Block if plan doesn't have dues capability (Free plan)
if (!effectivePlan.capabilities.dues) {
  return res.status(403).json({
    error: "Stripe Connect nécessite une offre payante.",
    code: "PLAN_NOT_ELIGIBLE",
    upgradeRequired: true,
    currentPlan: effectivePlan.planName,
    feature: "STRIPE_CONNECT",
    traceId
  });
}

// Block if subscription is still in trial (no payment confirmed)
if (effectivePlan.subscriptionStatus === "trialing") {
  return res.status(403).json({
    error: "Stripe Connect nécessite un abonnement payant confirmé. Veuillez finaliser votre abonnement.",
    code: "TRIAL_NOT_ELIGIBLE",
    upgradeRequired: true,
    currentPlan: effectivePlan.planName,
    feature: "STRIPE_CONNECT",
    traceId
  });
}
```

### C) Error Normalization (routes.ts)

```typescript
catch (error: any) {
  if (error.type === 'StripeInvalidRequestError') {
    if (errorMessage.includes('already exists')) {
      return res.status(409).json({ 
        error: "Un compte Stripe Connect existe déjà.",
        code: "STRIPE_CONNECT_ALREADY_EXISTS",
        traceId 
      });
    }
    return res.status(400).json({ 
      error: errorMessage,
      code: "STRIPE_INVALID_REQUEST",
      traceId 
    });
  }
  
  if (error.type === 'StripeAPIError' || error.type === 'StripeConnectionError') {
    return res.status(502).json({ 
      error: "Erreur de communication avec Stripe.",
      code: "STRIPE_API_ERROR",
      traceId 
    });
  }
  
  return res.status(502).json({ 
    error: errorMessage,
    code: "STRIPE_CONNECT_ERROR",
    traceId 
  });
}
```

## Fichiers Modifiés

| Fichier | Changement |
|---------|------------|
| `client/src/pages/admin/Finances.tsx` | Guard plan + trial dans handleConnectStripe + onError handler |
| `client/src/pages/admin/ConnectReturn.tsx` | Import useUpgradeRequired + onError handler pour 403 |
| `server/routes.ts` | Guard plan + trial + normalisation erreurs Stripe (403/400/409/502, jamais 500) |

## Comportement Après Fix

| Scénario | Code HTTP | Body |
|----------|-----------|------|
| Plan Free → clic bouton | N/A (bloqué frontend) | Modal "Fonctionnalité Premium" |
| Plan Payant en trial → clic bouton | N/A (bloqué frontend) | Modal "Abonnement confirmé requis" |
| Plan Free → bypass frontend (curl) | 403 | `{code: "PLAN_NOT_ELIGIBLE", upgradeRequired: true}` |
| Plan trial → bypass frontend (curl) | 403 | `{code: "TRIAL_NOT_ELIGIBLE", upgradeRequired: true}` |
| Plan Payant actif → succès | 200 | `{url: "...", accountId: "..."}` |
| Compte Stripe existant | 409 | `{code: "STRIPE_CONNECT_ALREADY_EXISTS"}` |
| Erreur Stripe API | 502 | `{code: "STRIPE_API_ERROR"}` |

## Requêtes SQL de Vérification

```sql
-- Tables présentes
SELECT table_name FROM information_schema.tables
WHERE table_schema='public' AND table_name IN ('communities','plans');
-- Résultat: communities, plans ✓

-- Plan Free existe
SELECT id, code, name FROM plans WHERE id='free';
-- Résultat: free | STARTER_FREE | Free Starter ✓

-- Vérifier capabilities du plan free (dues = false)
SELECT id, capabilities FROM plans WHERE id='free';
-- Résultat: dues = false ✓

-- Communauté de test
SELECT id, name, plan_id FROM communities WHERE id = '83f058b3-4b77-4cf3-91b4-2e0918f92fc4';
-- Résultat: vide (communauté test non trouvée en sandbox)

-- Table stripe_connect_accounts
SELECT table_name FROM information_schema.tables WHERE table_name='stripe_connect_accounts';
-- Résultat: table non présente (pas nécessaire pour ce fix)
```

## Exemple Réponse API 403 upgradeRequired

### Cas Plan Free
```json
{
  "error": "Stripe Connect nécessite une offre payante.",
  "code": "PLAN_NOT_ELIGIBLE",
  "upgradeRequired": true,
  "currentPlan": "Free Starter",
  "feature": "STRIPE_CONNECT",
  "traceId": "billing-connect-onboarding-1738001234567"
}
```

### Cas Trial
```json
{
  "error": "Stripe Connect nécessite un abonnement payant confirmé. Veuillez finaliser votre abonnement.",
  "code": "TRIAL_NOT_ELIGIBLE",
  "upgradeRequired": true,
  "currentPlan": "Plus",
  "feature": "STRIPE_CONNECT",
  "traceId": "billing-connect-onboarding-1738001234567"
}
```

## Tests Manuels à Effectuer (SANDBOX)

| Test | Étapes | Résultat Attendu |
|------|--------|------------------|
| Plan Free - clic bouton | 1. Backoffice avec compte Free 2. Clic "Configurer Stripe Connect" | Modal premium, aucun POST API |
| Plan Trial - clic bouton | 1. Backoffice avec compte en trial 2. Clic "Configurer Stripe Connect" | Modal "Abonnement confirmé requis", aucun POST API |
| Plan Payant actif - clic bouton | 1. Backoffice avec compte PLUS/PRO actif 2. Clic "Configurer Stripe Connect" | Redirection vers onboarding Stripe |
| API direct plan Free | curl POST /api/billing/stripe-connect/onboarding-link | 403 + PLAN_NOT_ELIGIBLE |
| API direct plan Trial | curl POST /api/billing/stripe-connect/onboarding-link | 403 + TRIAL_NOT_ELIGIBLE |

---

FIN
