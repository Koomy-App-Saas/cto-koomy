# SAAS Owner Access: Bootstrap Script & Break-Glass Removal

**Date:** 2026-01-22  
**Status:** COMPLETED  
**Type:** Security Enhancement

---

## Overview

Migration from HTTP-based emergency admin access (break-glass endpoint) to secure shell script execution for platform admin bootstrap in sandbox environments.

## Changes Summary

### 1. Removed HTTP Endpoints

| Endpoint | Purpose | Status |
|----------|---------|--------|
| `POST /api/platform/break-glass/bootstrap-admin` | Emergency admin creation | **REMOVED** |
| `POST /api/sandbox/bootstrap-platform-admin` | Sandbox admin promotion | **REMOVED** |

### 2. Removed Frontend

| File | Purpose | Status |
|------|---------|--------|
| `client/src/pages/platform/SandboxBootstrap.tsx` | UI for sandbox bootstrap | **DELETED** |
| `/sandbox/bootstrap` route in App.tsx | Route registration | **REMOVED** |

### 3. New Script-Based Approach

**File:** `scripts/bootstrap_platform_admin.ts`

**Execution:**
```bash
# From Railway shell or direct server access
npx tsx scripts/bootstrap_platform_admin.ts
```

**Required Environment Variables:**
```env
KOOMY_ENV=sandbox                    # MANDATORY: Must be 'sandbox'
PLATFORM_BOOTSTRAP_ENABLED=true      # Explicit enable flag
PLATFORM_BOOTSTRAP_EMAIL=user@koomy.app  # Target email (@koomy.app only)
PLATFORM_BOOTSTRAP_PASSWORD=...       # OR PLATFORM_BOOTSTRAP_MAGICLINK=1
```

### 4. Security Guards (5-Layer Protection)

1. **Environment Guard:** KOOMY_ENV must be **exactly** `sandbox` (strict, no NODE_ENV fallback)
2. **Enable Flag:** PLATFORM_BOOTSTRAP_ENABLED must be `true`
3. **Email Domain:** Only `@koomy.app` emails allowed
4. **Password Validation:** Minimum 8 characters (or magic link mode)
5. **One-Shot Database Flag:** `platform_settings.platform_bootstrap_done` prevents re-execution

**Note:** Guard 1 is intentionally strict - the script refuses to run in development or any non-sandbox environment.

### 5. Audit Trail

- TraceId format: `BOOT-XXXX-YYYY` (timestamp + random)
- Logged to `platform_audit_logs` table
- Console output with structured logging
- Auto-creates `platform_settings` table if missing

## Security Improvements

| Aspect | HTTP Endpoint | Script Approach |
|--------|--------------|-----------------|
| Access requirement | Network + token | Shell access required |
| Attack surface | Public internet | Local/SSH only |
| Credential exposure | Headers visible | Env vars only |
| Audit visibility | HTTP logs | Console + DB logs |
| Re-execution risk | Token-based | DB flag blocks |

## Files Modified

- `server/routes.ts`: Removed ~200 lines of break-glass endpoints
- `client/src/App.tsx`: Removed SandboxBootstrap import and route
- `scripts/bootstrap_platform_admin.ts`: New secure script (created earlier)

## Files Deleted

- `client/src/pages/platform/SandboxBootstrap.tsx`

## Testing

Script requires Railway/shell access to test. In development:
```bash
KOOMY_ENV=sandbox \
PLATFORM_BOOTSTRAP_ENABLED=true \
PLATFORM_BOOTSTRAP_EMAIL=admin@koomy.app \
PLATFORM_BOOTSTRAP_MAGICLINK=1 \
npx tsx scripts/bootstrap_platform_admin.ts
```

## Rollback

If needed, restore from git commit before this change. The HTTP endpoints were intentionally removed as a security improvement.

---

**Author:** Replit Agent  
**Reviewed:** 2026-01-22 (Architect: Strict sandbox-only guard enforced)
