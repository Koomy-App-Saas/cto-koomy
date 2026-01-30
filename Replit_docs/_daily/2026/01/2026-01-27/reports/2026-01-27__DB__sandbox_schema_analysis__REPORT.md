# REPORT: Sandbox DB Schema Analysis - Missing Columns

**Date:** 2026-01-27
**Domain:** DB
**Type:** Analysis Report

## Summary

Analyzed API 500 errors on sandbox environment caused by schema mismatch between Drizzle ORM definitions and actual Neon PostgreSQL database.

## Errors Observed

| Endpoint | HTTP Status | SQLSTATE | Error Detail |
|----------|-------------|----------|--------------|
| `GET /api/plans` | 500 | 42703 | Column "max_tags" does not exist |
| `GET /api/communities` | 500 | 42703 | Schema mismatch (probable) |

## Root Cause

Drizzle ORM schema (`shared/schema.ts`) defines columns that don't exist in the sandbox Neon database. When `db.select().from(table)` executes, it generates `SELECT *` queries referencing all schema-defined columns, causing PostgreSQL error 42703 (undefined column).

## Analysis Method

1. Queried `information_schema.columns` for `plans` and `communities` tables
2. Compared results with column definitions in `shared/schema.ts`
3. Identified columns present in ORM but absent in database

## Missing Columns Identified

### Table: `communities`

| Column | Type | Default | Line in schema.ts |
|--------|------|---------|-------------------|
| `connect_fee_fixed_cents` | INTEGER | 0 | 324 |

**Impact:** Used for Stripe Connect fee calculations. Without this column, any query selecting from communities table fails.

### Table: `plans`

| Column | Type | Default | Line in schema.ts |
|--------|------|---------|-------------------|
| `max_tags` | INTEGER | NULL | 239 |
| `tagline` | TEXT | NULL | 236 |
| `policies` | JSONB | NULL | 244 |
| `updated_at` | TIMESTAMP | NOW() | 250 |
| `updated_by` | VARCHAR(50) | NULL | 251 |

**Note:** Development database (Replit) has these columns. Sandbox Neon may be out of sync.

## Affected Code Paths

```typescript
// server/storage.ts - line 582
async getAllPlans(): Promise<Plan[]> {
  return await db.select().from(plans).orderBy(asc(plans.sortOrder));
  // ↑ Fails if max_tags/tagline/policies columns missing
}

// server/storage.ts - line 586
async getPublicPlans(): Promise<Plan[]> {
  return await db.select().from(plans)
    .where(eq(plans.isPublic, true))
    .orderBy(asc(plans.sortOrder));
  // ↑ Same issue
}
```

## Endpoints Impacted

| Endpoint | Route File | Storage Method |
|----------|------------|----------------|
| `GET /api/plans` | routes.ts:5010 | `storage.getAllPlans()` |
| `GET /api/plans/public` | routes.ts:5024 | `storage.getPublicPlans()` |
| `GET /api/plans/code/:code` | routes.ts:5035 | `storage.getPlanByCode()` |
| `GET /api/plans/:id` | routes.ts:5049 | `storage.getPlan()` |
| Any community query | multiple | Various methods |

## Solution

Generated idempotent SQL patch bundle at:
```
docs/_daily/2026/01/2026-01-27/specs/2026-01-27__DB__sandbox_schema_patch_bundle__SPEC.md
```

### Key Features of Patch Bundle:
- Uses `DO $$ ... IF NOT EXISTS` pattern for idempotency
- Can be executed multiple times safely
- Includes verification queries
- Provides NOTICE output for confirmation

## Validation Steps

After executing patch on Neon sandbox:

1. **Test /api/plans:**
   ```bash
   curl -s https://api-sandbox.koomy.app/api/plans
   # Expected: 200 OK with JSON array of plans
   ```

2. **Test /api/communities:**
   ```bash
   curl -s -H "Authorization: Bearer <token>" \
     https://api-sandbox.koomy.app/api/communities
   # Expected: 200 OK (or 401 if no token, but NOT 500)
   ```

3. **SaaS Owner Platform:**
   - Navigate to Plans management page
   - Verify plans display without errors

## Prevention Recommendations

1. **Sync check before deployment:**
   ```bash
   npm run db:push --dry-run
   ```

2. **Add schema version tracking:**
   - Store schema version in database
   - Compare on startup

3. **CI/CD pipeline gate:**
   - Compare production schema with ORM definition
   - Block deployment if mismatch detected

## Status

- [x] Analysis complete
- [x] Patch bundle generated
- [ ] Executed on sandbox (manual step)
- [ ] Verified with API tests

## Related Documents

- `2026-01-27__DB__sandbox_schema_patch_bundle__SPEC.md` - SQL patch bundle
