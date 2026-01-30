# UNSA Lidl Neutralization Report (Sandbox)

## Executive Summary

- **Date:** 2026-01-18T14:30:56.751Z
- **Environment:** sandbox
- **Mode:** CONFIRM
- **Status:** ✅ SUCCESS
- **Tenant ID:** 2b129b86-3a39-4d19-a6fc-3d0cec067a79

---

## Tenant Changes

| Field | Before | After |
|-------|--------|-------|
| name | UNSA Lidl | UNSA Lidl |
| subscriptionStatus | canceled | canceled |
| saasClientStatus | RESILIE | RESILIE |
| customDomain | NULL | NULL |
| terminatedAt | Sun Jan 18 2026 13:53:25 GMT+0000 (Coordinated Universal Time) | 2026-01-18T14:30:56.894Z |

### Brand Config Changes

**Before:**
```json
{
  "appName": "Unsa idl",
  "logoUrl": "/objects/public/white-label/65d5ff48-a23f-4ada-8fde-9fb3a11faaf9.png",
  "replyTo": "ritesmassamba@gmail.com",
  "termsUrl": "https://app.koomy.app/website/unsa-lidl/terms",
  "appIconUrl": "/objects/public/white-label/930a7d3d-b90f-4d9f-a1a3-51b935eb4040.png",
  "brandColor": "#009de1",
  "emailFromName": "UNSA Lidl France",
  "showPoweredBy": false,
  "deleteAccountUrl": "https://app.koomy.app/website/unsa-lidl/delete-account",
  "emailFromAddress": "support@koomy.app",
  "privacyPolicyUrl": "https://app.koomy.app/website/unsa-lidl/privacy"
}
```
**After:**
```json
{
  "appName": "ARCHIVED (Sandbox)",
  "logoUrl": "/objects/public/white-label/65d5ff48-a23f-4ada-8fde-9fb3a11faaf9.png",
  "replyTo": "no-reply@koomy-sandbox.local",
  "termsUrl": "https://app.koomy.app/website/unsa-lidl/terms",
  "appIconUrl": "/objects/public/white-label/930a7d3d-b90f-4d9f-a1a3-51b935eb4040.png",
  "brandColor": "#009de1",
  "emailFromName": "Koomy Sandbox",
  "showPoweredBy": false,
  "deleteAccountUrl": "https://app.koomy.app/website/unsa-lidl/delete-account",
  "emailFromAddress": "no-reply@koomy-sandbox.local",
  "privacyPolicyUrl": "https://app.koomy.app/website/unsa-lidl/privacy"
}
```

---

## Admins Affected

- **Count:** 0
- **Action:** isActive set to false


---

## Members Affected

- **Count:** 19
- **Action:** status set to 'suspended'

---

## Verifications

| Check | Status |
|-------|--------|
| Tenant disabled | ✅ |
| custom_domain removed | ✅ |
| brandConfig neutralized | ✅ |
| Admins disabled | ✅ |
| No other tenants modified | ✅ |

---

## Notes

- **Non-destructive:** No data was deleted. All records preserved for audit.
- **PII preserved:** Member data remains in database (suspended status only).
- **Reversible:** Tenant can be reactivated by updating status fields.
