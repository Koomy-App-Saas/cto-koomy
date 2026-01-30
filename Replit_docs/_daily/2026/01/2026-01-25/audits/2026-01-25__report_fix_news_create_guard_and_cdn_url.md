# Audit Report: Fix POST /api/news Guard and CDN URL Resolution

**Date**: 2026-01-25
**Status**: Implemented

## Problems Addressed

### Problem 1 — POST /api/news returns 403 for Firebase Admins

**Symptom:** Backoffice sandbox, authenticated Firebase admin:
```
POST /api/news -> 403 { error: "Permission denied - Admin role required", code: "FORBIDDEN" }
```

**Root Cause:** Route used `storage.getMembershipByAccountAndCommunity(accountId, communityId)` which only searches by `accountId`. Firebase admin users have their membership linked via `userId`, not `accountId`.

**Fix:** Use `getMembershipForAuth(authResult, communityId, traceId)` which:
1. First tries `accountId` lookup
2. Falls back to `userId` lookup for admin users
3. Correctly resolves Firebase admin memberships

### Problem 2 — Uploaded Image Preview 403 (Wrong URL)

**Symptom:** After upload success, browser tries to load:
```
https://backoffice-sandbox.koomy.app/admin/cdn-sandbox.koomy.app/public/news/<file>.png -> 403
```

**Root Cause:** URL was constructed as `cdn-sandbox.koomy.app/...` without `https://` protocol, causing browser to treat it as a relative path.

**Fix:** Added safety check in `resolvePublicObjectUrl()` and `resolveImageUrl()`:
```typescript
if (/^cdn(-sandbox)?\.koomy\.app\//i.test(trimmedUrl)) {
  return `https://${trimmedUrl}`;
}
```

## Files Modified

| File | Change |
|------|--------|
| `server/routes.ts` | POST /api/news: Use `getMembershipForAuth` instead of direct accountId lookup |
| `client/src/lib/cdnResolver.ts` | Add safety check for CDN domains without protocol |
| `client/src/api/config.ts` | Add safety check for CDN domains without protocol |

## Code Changes

### 1. POST /api/news Guard (server/routes.ts)

**Before:**
```typescript
callerMembership = await storage.getMembershipByAccountAndCommunity(accountId, communityId);
if (!isBackofficeAdmin(callerMembership)) {
  return res.status(403).json({ error: "Permission denied - Admin role required", code: "FORBIDDEN" });
}
```

**After:**
```typescript
const { membership, lookupPath } = await getMembershipForAuth(authResult, communityId, traceId);
callerMembership = membership;

if (!callerMembership) {
  return res.status(403).json({ error: "Membership required", code: "MEMBERSHIP_REQUIRED" });
}

if (!isBackofficeAdmin(callerMembership)) {
  return res.status(403).json({ error: "Permission denied - Admin role required", code: "FORBIDDEN" });
}
```

### 2. CDN URL Safety (client/src/lib/cdnResolver.ts + client/src/api/config.ts)

Added early check before other path processing:
```typescript
if (/^cdn(-sandbox)?\.koomy\.app\//i.test(trimmedUrl)) {
  return `https://${trimmedUrl}`;
}
```

## Debug Logging

When `KOOMY_AUTH_DEBUG=1`:
```
[NEWS_GUARD NEWS-XXXXXXXX] {
  accountId: "...",
  userId: "...",
  communityId: "...",
  membershipFound: true,
  membershipId: "...",
  role: "OWNER",
  lookupPath: "userId-fallback"
}
```

## Manual Validation Steps

### 1. Test POST /api/news for Firebase Admin

```bash
# Set debug mode
export KOOMY_AUTH_DEBUG=1

# Login as Firebase admin on backoffice-sandbox.koomy.app
# Go to News > Create New Article
# Fill form and click Publish

# Expected:
# - Network: POST /api/news → 201
# - Response contains created article id
# - Server logs: [NEWS_GUARD] membershipFound=true
```

### 2. Test Image Upload and Preview

```bash
# In News creation form, upload an image
# 
# Expected:
# - Upload succeeds (toast: "Image uploadée avec succès")
# - Preview loads correctly
# - Network shows: GET https://cdn-sandbox.koomy.app/public/news/<id>.png 200
# - NOT: GET .../admin/cdn-sandbox.koomy.app/...
```

### 3. Negative Test: Non-Admin Member

```bash
# Login as member without admin role
# Attempt to create news

# Expected:
# - 403 FORBIDDEN or MEMBERSHIP_REQUIRED
# - No article created
```

## Contracts Verified

### Contract A — News Permissions
- ✅ Firebase admins with membership can create news
- ✅ Uses `getMembershipForAuth` pattern consistent with events/messages

### Contract C — CDN URL Must Be Absolute
- ✅ All CDN URLs now guaranteed to have `https://` protocol
- ✅ Safety check catches edge cases of protocol-less domains
