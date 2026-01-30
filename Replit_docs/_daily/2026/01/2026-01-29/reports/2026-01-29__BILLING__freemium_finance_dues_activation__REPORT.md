# Rapport : Activation Finance Freemium (dues) pour Plan FREE

**Date** : 2026-01-29  
**Domaine** : BILLING / Finance  
**Objectif** : Permettre aux communautés FREE d'accéder à Stripe Connect (stratégie freemium finance)

---

## Contexte

Décision business : Les fonctionnalités finance (cotisations/dues) doivent être disponibles sur le plan FREE pour encourager l'adoption et la conversion vers les plans payants.

**Avant** : Plan FREE bloqué pour Stripe Connect (erreur "offre payante requise")  
**Après** : Plan FREE avec `dues=true` peut accéder à Stripe Connect

---

## Modifications Code

### 1. `server/lib/planLimits.ts`

**Ligne 46** : Mise à jour `DEFAULT_CAPABILITIES.free.dues`

```typescript
// AVANT
dues: false,

// APRÈS
dues: true, // P0 2026-01-29: Freemium finance strategy - FREE can use Stripe Connect
```

### 2. `server/routes.ts` - Guard Stripe Connect (lignes 11460-11507)

Refactorisation pour être purement basé sur les capabilities :

```typescript
// Vérification capability dues (fonctionne pour tous les plans)
if (!hasCapability(effectivePlan.capabilities, "dues")) {
  // Bloqué - capability manquante
}

// Vérification subscription status (bloque trialing)
if (effectivePlan.subscriptionStatus === "trialing") {
  // Bloqué - subscription non confirmée
}
```

**Supprimé** : Logique spécifique au `planId` (ex: `if (planId !== "free")`)

### 3. `server/routes.ts` - `checkSubscriptionForMoney()` (lignes 845-900)

Ajout vérification capability-based :

```typescript
// P0 2026-01-29: Capability-based access for money features
const { getEffectivePlan, hasCapability } = await import("./lib/planLimits");
const effectivePlan = await getEffectivePlan(communityId);

if (!hasCapability(effectivePlan.capabilities, "dues")) {
  // Bloqué - capability manquante
}
```

**Supprimé** : Bypass basé sur `planId === "free"`

---

## Modifications Base de Données

### Sandbox (Replit)

```sql
UPDATE plans 
SET capabilities = jsonb_set(capabilities, '{features,cotisations}', 'true')
WHERE id = 'free';
```

### Production (Neon)

Tous les plans mis à jour avec `features.dues: true` :

```sql
-- Plan FREE
UPDATE plans SET capabilities = '{
  "admins": {"max": 1}, 
  "members": {"max": 20}, 
  "support": "standard", 
  "features": {
    "tags": false, "qrCard": false, "dues": true,
    "analytics": "none", "messaging": false, "dataExport": false, 
    "integrations": false, "targetedContent": false, 
    "eventRegistration": false, "sectionsUnlimited": false
  }
}'::jsonb WHERE id = 'free';

-- Plan GROWTH
UPDATE plans SET capabilities = '{
  "admins": {"max": 3}, 
  "members": {"max": 100}, 
  "support": "priority", 
  "features": {
    "tags": false, "qrCard": true, "dues": true,
    "analytics": "basic", "messaging": true, "dataExport": false, 
    "integrations": false, "targetedContent": false, 
    "eventRegistration": true, "sectionsUnlimited": false
  }
}'::jsonb WHERE id = 'growth';

-- Plan SCALE
UPDATE plans SET capabilities = '{
  "admins": {"max": 10}, 
  "members": {"max": 250}, 
  "support": "priority", 
  "features": {
    "tags": true, "qrCard": true, "dues": true,
    "analytics": "advanced", "messaging": true, "dataExport": true, 
    "integrations": true, "targetedContent": true, 
    "eventRegistration": true, "sectionsUnlimited": true
  }
}'::jsonb WHERE id = 'scale';

-- Plan ENTERPRISE
UPDATE plans SET capabilities = '{
  "admins": {"max": 999}, 
  "members": {"max": null}, 
  "support": "dedicated", 
  "features": {
    "tags": true, "qrCard": true, "dues": true,
    "analytics": "advanced", "messaging": true, "dataExport": true, 
    "integrations": true, "targetedContent": true, 
    "eventRegistration": true, "sectionsUnlimited": true
  }
}'::jsonb WHERE id = 'enterprise';

-- Plan WHITELABEL
UPDATE plans SET capabilities = '{
  "admins": {"max": 999}, 
  "members": {"max": null}, 
  "support": "dedicated", 
  "features": {
    "tags": true, "qrCard": true, "dues": true,
    "analytics": "advanced", "messaging": true, "dataExport": true, 
    "integrations": true, "targetedContent": true, 
    "eventRegistration": true, "sectionsUnlimited": true
  }
}'::jsonb WHERE id = 'whitelabel';
```

---

## Vérification Production

```sql
SELECT id, name, capabilities->'features'->'dues' as dues FROM plans;
```

**Résultat attendu** :

| id | name | dues |
|---|---|---|
| free | Free Starter | true |
| growth | Communauté Plus | true |
| scale | Communauté Pro | true |
| enterprise | Grand Compte | true |
| whitelabel | Koomy White Label | true |

---

## Logique d'Accès Stripe Connect

### Flow pour communauté FREE avec `dues=true` :

1. **Guard capability** : `hasCapability("dues")` → PASS (dues=true)
2. **Guard trialing** : `subscriptionStatus !== "trialing"` → PASS (FREE a "active" par design)
3. **`checkSubscriptionForMoney()`** : `dues=true` AND `status="active"` → PASS

### Fonction `hasCapability()` (alias support) :

```typescript
export function hasCapability(capabilities, key) {
  if (capabilities[key] === true) return true;
  // Support legacy "cotisations" key as alias for "dues"
  if (key === "dues" && capabilities.cotisations === true) return true;
  return false;
}
```

---

## Commits

- `4d89240` : Enable financial features for free plans and update access controls
- `01a2424` : Update open graph image for community platform

---

## Notes Techniques

1. **Clé `dues` vs `cotisations`** : Production utilise `dues`, sandbox utilise `cotisations` (legacy). Le code supporte les deux via alias dans `hasCapability()`.

2. **Subscription Status** : Les plans FREE ont `subscriptionStatus="active"` par design (pas de paiement requis).

3. **Pas de bypass planId** : La logique est purement capability-based, aucun traitement spécial basé sur le `planId`.

---

## Validation

- [x] Code refactorisé (capability-based)
- [x] Sandbox DB mise à jour
- [x] Production DB mise à jour (5 plans avec dues=true)
- [x] Architect review PASS
