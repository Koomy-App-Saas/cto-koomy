# DB Migration Report: CGV & Newsletter Columns

**Date**: 2026-01-27
**Table**: communities
**Environment**: sandbox

## Issue

Schema drift detected: code referenced `cgv_accepted_at`, `cgv_version`, `newsletter_opt_in` columns but they did not exist in the database.

Error observed:
```
column "cgv_accepted_at" does not exist
```

Affected endpoints:
- `/api/billing/stripe-connect/status`
- `/api/communities/:id`
- `/api/communities/:id/quota`
- `/api/communities`

## SQL Migration (Applied)

```sql
-- Idempotent migration for CGV and newsletter consent columns
ALTER TABLE communities ADD COLUMN IF NOT EXISTS cgv_accepted_at TIMESTAMPTZ;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS cgv_version TEXT;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS newsletter_opt_in BOOLEAN DEFAULT false;
```

## Verification SQL

```sql
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'communities' 
AND column_name IN ('cgv_accepted_at', 'cgv_version', 'newsletter_opt_in')
ORDER BY column_name;
```

## Result

| column_name | data_type | is_nullable | column_default |
|-------------|-----------|-------------|----------------|
| cgv_accepted_at | timestamp with time zone | YES | null |
| cgv_version | text | YES | null |
| newsletter_opt_in | boolean | YES | false |

## Rollback SQL

```sql
ALTER TABLE communities DROP COLUMN IF EXISTS cgv_accepted_at;
ALTER TABLE communities DROP COLUMN IF EXISTS cgv_version;
ALTER TABLE communities DROP COLUMN IF EXISTS newsletter_opt_in;
```

## Production Deployment

This same migration must be applied to production before deploying the code that uses these columns.
