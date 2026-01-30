# Rapport: Correctif Isolation Sandbox/Production Stripe

**Date:** 2026-01-20  
**Version:** 2.0 (mise à jour avec fusible Stripe keys)  
**Problème:** Les sessions Stripe Checkout créées par l'API sandbox utilisaient des URLs de production, causant des 404 et des fuites sandbox→prod.

---

## 1. Variables d'environnement

| Variable | Valeurs acceptées | Fallback | Description |
|----------|-------------------|----------|-------------|
| `APP_ENV` | `sandbox` \| `prod` | Déduit de `KOOMY_ENV` | Contrôle l'environnement Stripe |
| `KOOMY_ENV` | `sandbox` \| `production` \| `development` | `development` | Environnement global de l'application |

### Logique de dérivation APP_ENV

```
Si APP_ENV défini:
  - "sandbox" → sandbox
  - "prod" → production

Sinon, dérivé de KOOMY_ENV:
  - "production" → APP_ENV = "prod"
  - "sandbox" ou "development" → APP_ENV = "sandbox"
  - Non défini → APP_ENV = "sandbox" (défaut sécurisé)
```

---

## 2. URLs générées par environnement

### Sandbox (APP_ENV=sandbox)

| Contexte | Base URL | Route de retour |
|----------|----------|-----------------|
| Backoffice | `https://backoffice-sandbox.koomy.app` | `/billing/return?status=success&session_id={ID}` |
| Mobile | `https://sandbox.koomy.app` | `/payment/success?session_id={ID}` |
| Connect | `https://backoffice-sandbox.koomy.app` | `/payments/connect/success` |

### Production (APP_ENV=prod)

| Contexte | Base URL | Route de retour |
|----------|----------|-----------------|
| Backoffice | `https://backoffice.koomy.app` | `/billing/return?status=success&session_id={ID}` |
| Mobile | `https://app.koomy.app` | `/payment/success?session_id={ID}` |
| Connect | `https://backoffice.koomy.app` | `/payments/connect/success` |

---

## 3. Fonctions mises à jour

### server/stripe.ts

| Fonction | Avant | Après |
|----------|-------|-------|
| `getAppEnvironment()` | - | Nouvelle: retourne `"sandbox"` ou `"prod"` |
| `getStripeCheckoutBaseUrl(context)` | - | Nouvelle: retourne URL base avec guard sécurité |
| `buildBillingReturnUrls(context)` | - | Nouvelle: construit success/cancel URLs |
| `buildMobilePaymentUrls()` | - | Nouvelle: construit URLs mobile |
| `getStripeConnectUrls()` | - | Nouvelle: construit URLs Connect |
| `createKoomySubscriptionSession` | `process.env.CHECKOUT_BASE_URL \|\| hardcoded` | `buildBillingReturnUrls("backoffice")` |
| `createRegistrationCheckoutSession` | `process.env.CHECKOUT_BASE_URL \|\| hardcoded` | `buildBillingReturnUrls("backoffice")` |
| `createUpgradeCheckoutSession` | `process.env.CHECKOUT_BASE_URL \|\| hardcoded` | `buildBillingReturnUrls("backoffice")` |
| `createCheckoutSession` | Acceptait `successUrl`/`cancelUrl` en params | Construit internalement via helper |

### server/stripeConnect.ts

| Fonction | Avant | Après |
|----------|-------|-------|
| `createOnboardingLink` | URLs hardcodées prod | `getStripeConnectUrls()` |

### server/routes.ts

| Route | Avant | Après |
|-------|-------|-------|
| `POST /api/payments/membership/session` | URLs hardcodées | `buildMobilePaymentUrls()` |
| `POST /api/payments/collection/session` | URLs hardcodées | `buildMobilePaymentUrls()` |
| `POST /api/billing/checkout` | Passait `successUrl`/`cancelUrl` | Ne passe plus (construit backend) |

---

## 4. Guard de sécurité

Le helper `getStripeCheckoutBaseUrl()` inclut un guard qui:

1. Vérifie que sandbox ne génère jamais d'URL production
2. Throw une erreur avec message explicite si violation détectée
3. Log en ERROR pour traçabilité

```typescript
if (env === "sandbox") {
  if (baseUrl.includes("backoffice.koomy.app") && !baseUrl.includes("sandbox")) {
    const errorMsg = `[SECURITY ERROR] Sandbox attempted to use production URL: ${baseUrl}`;
    console.error(errorMsg);
    throw new Error(errorMsg);
  }
}
```

---

## 5. Fusible Stripe Keys (v2.0)

Le serveur refuse de démarrer si les clés Stripe ne correspondent pas à l'environnement:

| APP_ENV | Clé autorisée | Clé interdite | Comportement |
|---------|---------------|---------------|--------------|
| `sandbox` | `sk_test_*` | `sk_live_*` | FATAL: refuse de démarrer |
| `prod` | `sk_live_*` | `sk_test_*` | FATAL: refuse de démarrer |

```typescript
// Sandbox: refuse les clés live
if (effectiveAppEnv === "sandbox" && isLiveSecretKey) {
  console.error("🚫 FATAL: STRIPE LIVE KEY DETECTED IN SANDBOX");
  process.exit(1);
}

// Production: refuse les clés test
if (effectiveAppEnv === "prod" && isTestSecretKey) {
  console.error("🚫 FATAL: STRIPE TEST KEY DETECTED IN PRODUCTION");
  process.exit(1);
}
```

**Note:** Les webhook secrets (`whsec_`) n'ont pas de distinction live/test - seule la clé API (`sk_`) détermine l'environnement.

---

## 6. Validation au démarrage

`server/index.ts` valide maintenant:

1. `APP_ENV` doit être `sandbox` ou `prod` si défini
2. **Fusible Stripe keys** - refuse les clés live en sandbox et test en prod
3. Log l'environnement effectif et les URLs Stripe au démarrage
4. Refuse de démarrer si valeur invalide

Exemple de log au démarrage:
```
[STARTUP] ✓ KOOMY_ENV: sandbox
[STARTUP] ✓ APP_ENV: sandbox (Stripe URL environment)
[STARTUP] ✓ Stripe backoffice base URL: https://backoffice-sandbox.koomy.app
[STARTUP] ✓ Stripe mobile base URL: https://sandbox.koomy.app
[STARTUP] ✓ Stripe key type: TEST (matches sandbox environment)
```

---

## 7. Logs de création de session

Chaque création de session Stripe log les URLs utilisées pour traçabilité:

```
[Stripe] createKoomySubscriptionSession URLs: success=https://backoffice-sandbox.koomy.app/billing/return?status=success&session_id={CHECKOUT_SESSION_ID}, cancel=...
[Stripe] Created subscription session cs_xxx, URLs confirmed: success_url=https://backoffice-sandbox.koomy.app/billing/return?status=success&session_id=cs_xxx, cancel_url=...
```

---

## 8. SPA Fallback

La route `/billing/return` est correctement servie via le fallback SPA dans `server/static.ts`:

```typescript
app.use("*", (_req, res) => {
  res.sendFile(path.resolve(distPath, "index.html"));
});
```

Cela garantit qu'aucun 404 server-side ne sera retourné pour cette route ou toute autre route frontend.

---

## 9. Plan de test

### Test Sandbox

1. Définir `APP_ENV=sandbox` ou `KOOMY_ENV=sandbox`
2. Créer une session Stripe (subscription, registration, upgrade)
3. Vérifier dans les logs:
   - `[Stripe] Using backoffice base URL for env=sandbox: https://backoffice-sandbox.koomy.app`
4. Vérifier que `success_url` dans la session Stripe contient `backoffice-sandbox.koomy.app`
5. Compléter le paiement dans Stripe → doit rediriger vers `https://backoffice-sandbox.koomy.app/billing/return`

### Test Production

1. Définir `APP_ENV=prod` ou `KOOMY_ENV=production`
2. Créer une session Stripe
3. Vérifier dans les logs:
   - `[Stripe] Using backoffice base URL for env=prod: https://backoffice.koomy.app`
4. Vérifier que `success_url` dans la session Stripe contient `backoffice.koomy.app` (sans sandbox)

### Test Guard de sécurité

1. Définir `APP_ENV=sandbox`
2. Modifier manuellement le code pour forcer une URL prod
3. Vérifier que:
   - Le serveur throw une erreur
   - Le log contient `[SECURITY ERROR]`

---

## 10. Checklist de déploiement

- [ ] Définir `APP_ENV=sandbox` sur l'environnement sandbox
- [ ] Définir `APP_ENV=prod` sur l'environnement production
- [ ] Vérifier les logs au démarrage pour confirmer les URLs correctes
- [ ] Tester un flux de paiement complet dans chaque environnement
- [ ] Vérifier que les redirections post-paiement fonctionnent

---

## 11. Résumé des fichiers modifiés

| Fichier | Type de modification |
|---------|---------------------|
| `server/stripe.ts` | Ajout helpers + refactoring fonctions |
| `server/stripeConnect.ts` | Import helper + refactoring `createOnboardingLink` |
| `server/routes.ts` | Suppression URLs hardcodées dans 3 routes |
| `server/index.ts` | Validation APP_ENV + logging URLs au démarrage |
| `REPORT_STRIPE_ENV_FIX.md` | Ce rapport (nouveau fichier) |
