# Fix: subscription_status Enum "pending" Not Found

**Date:** 2026-01-22  
**Type:** Bug Fix  
**Environment:** Sandbox (Railway)  
**Status:** COMPLETED

---

## Problème

Lors de l'inscription admin avec création de communauté:
```
POST /api/admin/register
pgCode: 22P02
message: invalid input value for enum subscription_status: "pending"
trace: TR-9EKMKEZ7
```

Le code tentait d'insérer `subscriptionStatus: "pending"` mais cette valeur n'existe pas dans l'enum Postgres.

---

## Analyse

### Valeurs de l'enum Drizzle (shared/schema.ts ligne 7)
```typescript
export const subscriptionStatusEnum = pgEnum("subscription_status", 
  ["pending", "active", "past_due", "canceled"]
);
```

### Valeurs réelles dans Postgres (vérifiées par SQL)
```sql
SELECT enumlabel FROM pg_enum 
WHERE enumtypid = (SELECT oid FROM pg_type WHERE typname = 'subscription_status')
ORDER BY enumsortorder;

-- Résultat:
-- active
-- past_due
-- canceled
```

**Écart:** Le schéma Drizzle déclare `pending` mais la base de données n'a jamais été synchronisée avec cette valeur.

---

## Solution Retenue

### Valeur de remplacement: `past_due`

**Justification:**
- Parmi les valeurs existantes (`active`, `past_due`, `canceled`), `past_due` est la plus proche sémantiquement de "en attente de paiement"
- `active` donnerait accès au service avant paiement (risque business)
- `canceled` est trompeur (l'abonnement n'est pas annulé)
- `past_due` signale "paiement attendu" → le webhook Stripe le passera à `active` après paiement

### Logique métier
```typescript
// Avant:
subscriptionStatus: isPaidPlan ? "pending" : "active"

// Après:
subscriptionStatus: isPaidPlan ? "past_due" : "active"
```

- **Plan gratuit (FREE):** `active` immédiatement
- **Plan payant (PLUS, PRO):** `past_due` → l'utilisateur est redirigé vers Stripe Checkout → après paiement, le webhook met `active`

---

## Mapping d'erreur ajouté

```typescript
if (pgCode === '22P02') {
  // Invalid input value for enum
  return res.status(400).json({
    error: "Valeur de champ invalide",
    code: "ENUM_VALUE_INVALID",
    detail: atomicError?.message,
    traceId
  });
}
```

---

## Fichiers Modifiés

| Fichier | Modification |
|---------|--------------|
| `server/routes.ts:2751` | `"pending"` → `"past_due"` (atomic path) |
| `server/routes.ts:2904` | `"pending"` → `"past_due"` (existing user path) |
| `server/routes.ts:2854-2862` | Ajout mapping erreur `22P02` → `ENUM_VALUE_INVALID` |
| `client/src/components/layouts/AdminLayout.tsx:144` | Logique `isPendingPayment` mise à jour pour `past_due && !stripeSubscriptionId` |

---

## Tests Attendus

### Test 1: Nouvelle inscription admin (plan FREE)
```
Flow: Google Sign-In → Register → Create Community (plan FREE)
Attendu: 201/200
subscriptionStatus stocké: "active"
Logs: TX_STEP1 → TX_STEP2 → TX_STEP3 → ATOMIC_SUCCESS
```

### Test 2: Nouvelle inscription admin (plan PLUS/PRO)
```
Flow: Google Sign-In → Register → Create Community (plan PLUS)
Attendu: 201/200 + redirect vers Stripe Checkout
subscriptionStatus stocké: "past_due"
Après paiement Stripe: webhook met "active"
```

### Test 3: Réinscription même compte
```
Flow: Même compte Google → Register
Attendu: 409 { code: "ALREADY_REGISTERED" }
```

### Test 4: Enum invalide (si autre code tente d'insérer valeur invalide)
```
Attendu: 400 { code: "ENUM_VALUE_INVALID" }
```

---

## Vérification Post-Déploiement

```sql
-- Vérifier le subscriptionStatus des nouvelles communautés
SELECT id, name, plan_id, subscription_status, created_at
FROM communities
WHERE created_at > NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC;

-- S'assurer qu'aucune community n'a "pending"
SELECT COUNT(*) FROM communities WHERE subscription_status = 'pending';
-- Attendu: 0
```

---

## Note: Migration Future

Pour ajouter `pending` proprement à l'enum Postgres (opération sûre, sans risque):
```sql
ALTER TYPE subscription_status ADD VALUE 'pending' BEFORE 'active';
```

Mais cela nécessite d'être exécuté sur Railway avec `npm run db:push`.

---

**Auteur:** Replit Agent
