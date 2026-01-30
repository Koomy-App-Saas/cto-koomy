# UNSA Lidl Decontamination Report
## Executive Summary

**Date:** 2026-01-18  
**Environment:** Sandbox (development)  
**Status:** COMPLETED  
**Tenant ID:** 2b129b86-3a39-4d19-a6fc-3d0cec067a79

---

## Phase 1: Database Neutralization

### Tenant Status Changes
| Field | Before | After |
|-------|--------|-------|
| subscription_status | active | canceled |
| saas_client_status | ACTIVE | RESILIE |
| custom_domain | unsalidlfrance | NULL |
| terminated_at | NULL | 2026-01-18 |
| internal_notes | NULL | ARCHIVED - tenant neutralized |

### Member/Admin Impact
- **19 members** with real PII: status changed to `suspended`
- **1 admin** (admin@unsalidl.koomy.app): account `isActive` set to `false`
- **Data preserved** in database for potential audit/legal requirements
- **Access blocked** via suspended status and disabled admin account

---

## Phase 2: Code Decontamination

### Files Modified

| File | Changes |
|------|---------|
| `client/src/pages/Landing.tsx` | Removed white-label external link, removed unused imports (Crown, Shield) |
| `client/src/lib/mockData.ts` | c_unsa → c_demo, UNSA member IDs → DEMO pattern, alias renamed |
| `client/src/lib/mockSupportData.ts` | c_unsa → c_demo, UNSA Lidl → Association Demo |
| `client/src/pages/admin/EventDetails.tsx` | UNSA-XXXX → DEMO-XXXX member IDs |
| `client/src/pages/website/Blog.tsx` | UNSA case study → generic federation |
| `client/src/pages/mobile/Card.tsx` | Removed hardcoded UNSA Lidl logo check, fallback "UNSA" → "Association" |
| `client/src/pages/mobile/WhiteLabelLogin.tsx` | LIDL-STRB-2024 placeholder → DEMO-IDF-2024 |
| `client/src/i18n/locales/en.json` | admin@unsa.org → admin@demo.koomy.app |
| `client/src/i18n/locales/fr.json` | admin@unsa.org → admin@demo.koomy.app |
| `client/src/api/config.ts` | Comment example unsalidlfrance → demo-wl |
| `client/src/App.tsx` | Removed legal page routes (/legal/unsa-lidl/*) |
| `server/seed.ts` | UNSA → Demo Association, @unsa.org → @demo.koomy.app |
| `server/routes.ts` | Comment examples updated (unsalidlfrance → mytenant, UNSALIDL → PREFIX) |
| `shared/schema.ts` | Comment examples UNSA → DEMO pattern |

### Files Preserved (Not Modified)

The following files/directories contain UNSA/Lidl references but are intentionally preserved:

| Path | Reason |
|------|--------|
| `tenants/unsa-lidl/` | Tenant configuration archive (not served) |
| `tenants/unsalidlfrance/` | WL config archive (not served) |
| `apps/mobile-shells/tenants/unsa-lidl/` | Mobile build config archive |
| `artifacts/mobile/UNSALidlApp/` | Build artifacts archive |
| `docs/unsa-lidl/` | Historical documentation |
| `scripts/build-unsa-lidl.mjs` | Build script archive |
| `scripts/seed-unsalidl-sections.ts` | Seed script archive |
| `client/src/pages/legal/UnsaLidl*.tsx` | Legal page source files (routes removed) |
| `archive/assets-unused/prompts/` | Historical prompts |
| `SANDBOX_WL_AUDIT_REPORT.md` | Previous audit report |

---

## Verification Checklist

- [x] `custom_domain = NULL` prevents subdomain routing
- [x] `subscription_status = canceled` blocks billing
- [x] `saas_client_status = RESILIE` triggers termination logic
- [x] All members suspended (cannot login via app)
- [x] Admin account disabled (cannot login via backoffice)
- [x] No UNSA/Lidl references in active frontend code
- [x] No UNSA/Lidl references in active API routes
- [x] Legal page routes removed from App.tsx
- [x] Application builds and runs without errors

---

## Security Notes

1. **PII remains in database** - Required for potential legal/audit requirements
2. **Tenant data not deleted** - Soft-archived via status flags
3. **Assets in repo** - Static files in archive directories not served by application
4. **Legal pages** - Source files exist but routes removed, not accessible

---

## Post-Decontamination State

The Koomy sandbox environment no longer exposes any UNSA Lidl branding, member data, or tenant-specific routes to end users. The tenant exists in archived state for record-keeping purposes only.

**Build Status:** PASSING  
**Application Status:** RUNNING  
**LSP Errors:** NONE
