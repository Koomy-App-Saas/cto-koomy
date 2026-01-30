# SPEC: Sandbox DB Schema Patch Bundle

**Date:** 2026-01-27
**Domain:** DB
**Type:** Schema Patch Specification
**Target:** Neon PostgreSQL (sandbox)

## Problem

Several API endpoints return HTTP 500 due to missing database columns:
- `GET /api/plans` → 500, SQLSTATE 42703 (column not found)
- `GET /api/communities` → 500 (schema mismatch)

## Analysis

Comparing `shared/schema.ts` (Drizzle ORM definition) with actual database schema reveals missing columns.

### Table: `communities`

| Column Name | Type | Default | Status |
|-------------|------|---------|--------|
| `connect_fee_fixed_cents` | INTEGER | 0 | **MISSING** |

### Table: `plans`

All columns present in development database. However, sandbox/production may be out of sync.

## SQL Patch Bundle

```sql
-- ============================================================
-- KOOMY SANDBOX DB PATCH BUNDLE
-- Date: 2026-01-27
-- Purpose: Add missing columns to align schema with Drizzle ORM
-- Environment: Neon PostgreSQL (sandbox)
-- IDEMPOTENT: Safe to run multiple times
-- ============================================================

-- ============================================================
-- TABLE: communities
-- ============================================================

-- Column: connect_fee_fixed_cents
-- Purpose: Koomy fixed fee in cents on membership payments
-- Required by: Stripe Connect fee calculations
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'communities' AND column_name = 'connect_fee_fixed_cents'
  ) THEN
    ALTER TABLE communities ADD COLUMN connect_fee_fixed_cents INTEGER DEFAULT 0;
    RAISE NOTICE 'Added column: communities.connect_fee_fixed_cents';
  ELSE
    RAISE NOTICE 'Column already exists: communities.connect_fee_fixed_cents';
  END IF;
END $$;

-- ============================================================
-- TABLE: plans
-- ============================================================

-- Column: max_tags
-- Purpose: Maximum tags/sections allowed per plan
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'plans' AND column_name = 'max_tags'
  ) THEN
    ALTER TABLE plans ADD COLUMN max_tags INTEGER;
    RAISE NOTICE 'Added column: plans.max_tags';
  ELSE
    RAISE NOTICE 'Column already exists: plans.max_tags';
  END IF;
END $$;

-- Column: tagline
-- Purpose: Short tagline for the plan display
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'plans' AND column_name = 'tagline'
  ) THEN
    ALTER TABLE plans ADD COLUMN tagline TEXT;
    RAISE NOTICE 'Added column: plans.tagline';
  ELSE
    RAISE NOTICE 'Column already exists: plans.tagline';
  END IF;
END $$;

-- Column: policies
-- Purpose: Governance policies (fees, thresholds) as JSONB
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'plans' AND column_name = 'policies'
  ) THEN
    ALTER TABLE plans ADD COLUMN policies JSONB;
    RAISE NOTICE 'Added column: plans.policies';
  ELSE
    RAISE NOTICE 'Column already exists: plans.policies';
  END IF;
END $$;

-- Column: updated_at
-- Purpose: Track when plan was last modified
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'plans' AND column_name = 'updated_at'
  ) THEN
    ALTER TABLE plans ADD COLUMN updated_at TIMESTAMP DEFAULT NOW();
    RAISE NOTICE 'Added column: plans.updated_at';
  ELSE
    RAISE NOTICE 'Column already exists: plans.updated_at';
  END IF;
END $$;

-- Column: updated_by
-- Purpose: Track who last modified the plan
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'plans' AND column_name = 'updated_by'
  ) THEN
    ALTER TABLE plans ADD COLUMN updated_by VARCHAR(50);
    RAISE NOTICE 'Added column: plans.updated_by';
  ELSE
    RAISE NOTICE 'Column already exists: plans.updated_by';
  END IF;
END $$;

-- ============================================================
-- VERIFICATION QUERIES
-- ============================================================

-- Verify plans table columns
SELECT 'PLANS TABLE' as table_name, column_name, data_type, column_default
FROM information_schema.columns 
WHERE table_name = 'plans' 
AND column_name IN ('max_tags', 'tagline', 'policies', 'updated_at', 'updated_by')
ORDER BY column_name;

-- Verify communities table columns
SELECT 'COMMUNITIES TABLE' as table_name, column_name, data_type, column_default
FROM information_schema.columns 
WHERE table_name = 'communities' 
AND column_name = 'connect_fee_fixed_cents';

-- ============================================================
-- END OF PATCH BUNDLE
-- ============================================================
```

## Validation After Patch

### Expected Results

1. **GET /api/plans** → 200 OK
   ```bash
   curl -s https://api-sandbox.koomy.app/api/plans | head -c 200
   ```

2. **GET /api/communities** → 200 OK (or proper auth error, not 500)
   ```bash
   curl -s -H "Authorization: Bearer <token>" https://api-sandbox.koomy.app/api/communities | head -c 200
   ```

3. **SaaS Owner Platform** → Plans page displays correctly

## Column Details

| Table | Column | Type | Default | Nullable | Justification |
|-------|--------|------|---------|----------|---------------|
| communities | connect_fee_fixed_cents | INTEGER | 0 | YES | Stripe Connect fixed fee per transaction |
| plans | max_tags | INTEGER | NULL | YES | Tag/section limit per plan tier |
| plans | tagline | TEXT | NULL | YES | UI display tagline |
| plans | policies | JSONB | NULL | YES | Governance policies config |
| plans | updated_at | TIMESTAMP | NOW() | YES | Audit trail |
| plans | updated_by | VARCHAR(50) | NULL | YES | Audit trail |

## Rollback (if needed)

```sql
-- NOT RECOMMENDED - only for emergencies
-- These columns are used by application code

-- ALTER TABLE communities DROP COLUMN IF EXISTS connect_fee_fixed_cents;
-- ALTER TABLE plans DROP COLUMN IF EXISTS max_tags;
-- ALTER TABLE plans DROP COLUMN IF EXISTS tagline;
-- ALTER TABLE plans DROP COLUMN IF EXISTS policies;
-- ALTER TABLE plans DROP COLUMN IF EXISTS updated_at;
-- ALTER TABLE plans DROP COLUMN IF EXISTS updated_by;
```

## Status

- [ ] Reviewed by DBA
- [ ] Executed on sandbox
- [ ] Verified with curl tests
- [ ] Production scheduled (if applicable)
