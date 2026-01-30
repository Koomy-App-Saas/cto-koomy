# P-FIN.6 — Post-migration Verification Report

## A) Database Changes Summary

| Change Type | Applied | Details |
|-------------|---------|---------|
| Tables created | NO | - |
| Columns added | YES | `stripe_connect_status`, `stripe_connect_charges_enabled`, `stripe_connect_payouts_enabled`, `stripe_connect_details_submitted`, `stripe_connect_last_sync_at` on `communities` |
| Enums created | YES | `stripe_connect_status` (6 values) |
| Index/constraints | NO | - |
| Backward compatible | YES | Toutes les colonnes ont des defaults, nullable ok |

---

## B) SQL Migration (Exact)

```sql
-- 1. Créer l'enum stripe_connect_status
CREATE TYPE stripe_connect_status AS ENUM (
  'NOT_CONNECTED',
  'ONBOARDING_REQUIRED',
  'PENDING_REVIEW',
  'RESTRICTED',
  'ACTIVE',
  'DISCONNECTED'
);

-- 2. Ajouter les colonnes sur la table communities
ALTER TABLE communities 
  ADD COLUMN IF NOT EXISTS stripe_connect_status stripe_connect_status DEFAULT 'NOT_CONNECTED',
  ADD COLUMN IF NOT EXISTS stripe_connect_charges_enabled boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS stripe_connect_payouts_enabled boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS stripe_connect_details_submitted boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS stripe_connect_last_sync_at timestamp;

-- 3. Initialiser le statut pour les communautés existantes avec Stripe Connect actif
UPDATE communities 
SET stripe_connect_status = 'ACTIVE',
    stripe_connect_charges_enabled = true,
    stripe_connect_payouts_enabled = true,
    stripe_connect_details_submitted = true
WHERE stripe_connect_account_id IS NOT NULL 
  AND payments_enabled = true;

UPDATE communities 
SET stripe_connect_status = 'ONBOARDING_REQUIRED'
WHERE stripe_connect_account_id IS NOT NULL 
  AND (payments_enabled = false OR payments_enabled IS NULL)
  AND stripe_connect_status = 'NOT_CONNECTED';
```

---

## C) SQL Verification (Existence)

### Enum existence
```sql
SELECT typname
FROM pg_type
WHERE typname = 'stripe_connect_status';
```

### Enum values
```sql
SELECT e.enumlabel
FROM pg_type t
JOIN pg_enum e ON t.oid = e.enumtypid
WHERE t.typname = 'stripe_connect_status'
ORDER BY e.enumsortorder;
```

### Columns existence
```sql
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'communities'
  AND column_name IN (
    'stripe_connect_status',
    'stripe_connect_charges_enabled',
    'stripe_connect_payouts_enabled',
    'stripe_connect_details_submitted',
    'stripe_connect_last_sync_at'
  )
ORDER BY column_name;
```

**Expected Result:** 5 rows returned

---

## D) SQL Minimal Runtime Test

```sql
-- Test 1: Lecture des nouvelles colonnes
SELECT 
  id,
  name,
  stripe_connect_status,
  stripe_connect_charges_enabled,
  stripe_connect_payouts_enabled
FROM communities 
LIMIT 3;

-- Test 2: Filtrage par statut
SELECT COUNT(*) 
FROM communities 
WHERE stripe_connect_status = 'NOT_CONNECTED';

-- Test 3: Update simulation (sans commit)
BEGIN;
UPDATE communities 
SET stripe_connect_status = 'ACTIVE',
    stripe_connect_last_sync_at = NOW()
WHERE id = (SELECT id FROM communities LIMIT 1);
ROLLBACK;
```

---

## E) Rollback SQL

```sql
-- ATTENTION: Perte de données si exécuté après usage en production

-- 1. Supprimer les colonnes
ALTER TABLE communities 
  DROP COLUMN IF EXISTS stripe_connect_status,
  DROP COLUMN IF EXISTS stripe_connect_charges_enabled,
  DROP COLUMN IF EXISTS stripe_connect_payouts_enabled,
  DROP COLUMN IF EXISTS stripe_connect_details_submitted,
  DROP COLUMN IF EXISTS stripe_connect_last_sync_at;

-- 2. Supprimer l'enum
DROP TYPE IF EXISTS stripe_connect_status;
```

---

## Status

| Check | Result |
|-------|--------|
| Migration SQL provided | ✅ |
| Verification SQL provided | ✅ |
| Runtime test SQL provided | ✅ |
| Rollback SQL provided | ✅ |
| **Ready for manual execution** | ✅ |
