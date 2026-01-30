-- =====================================================
-- KOOMY P1: Admin Quota Columns - Fallback SQL
-- =====================================================
-- Version: 1.0.0
-- Date: 2026-01-26
-- Purpose: Emergency fallback to add required columns if migrations fail
-- Usage: Run manually against production DB if boot-time guard blocks startup
-- 
-- IMPORTANT: Prefer `npm run db:push` for normal migrations.
-- Use this SQL only as emergency fallback when CI/CD migrations fail.
-- =====================================================

-- =====================================================
-- COMMUNITIES TABLE: Admin quota overrides
-- =====================================================

-- max_admins_default: SaaS-configurable default override (nullable)
-- Used when SaaS owner wants to set a custom admin limit for a community
ALTER TABLE public.communities
  ADD COLUMN IF NOT EXISTS max_admins_default INTEGER;

-- contract_admin_limit: Contractual override (highest priority)
-- Used for Enterprise/WL customers with specific contract terms
ALTER TABLE public.communities
  ADD COLUMN IF NOT EXISTS contract_admin_limit INTEGER;

-- contract_member_limit: Contractual member limit override
ALTER TABLE public.communities
  ADD COLUMN IF NOT EXISTS contract_member_limit INTEGER;

-- =====================================================
-- PLANS TABLE: Default admin quotas per plan
-- =====================================================

-- max_admins: Default admin limit for this plan
-- (Already exists in schema, but ensure column exists)
ALTER TABLE public.plans
  ADD COLUMN IF NOT EXISTS max_admins INTEGER;

-- =====================================================
-- VERIFICATION QUERY
-- =====================================================
-- Run this to verify columns exist after applying migrations:
--
-- SELECT column_name, data_type, is_nullable
-- FROM information_schema.columns
-- WHERE table_schema = 'public'
--   AND table_name IN ('communities', 'plans')
--   AND column_name IN ('max_admins_default', 'contract_admin_limit', 'contract_member_limit', 'max_admins')
-- ORDER BY table_name, column_name;

-- =====================================================
-- EXPECTED RESULT (4 rows):
-- =====================================================
-- column_name           | data_type | is_nullable
-- ----------------------+-----------+-------------
-- contract_admin_limit  | integer   | YES
-- contract_member_limit | integer   | YES
-- max_admins_default    | integer   | YES
-- max_admins            | integer   | YES
