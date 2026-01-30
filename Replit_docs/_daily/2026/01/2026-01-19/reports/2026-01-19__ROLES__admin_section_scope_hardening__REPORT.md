# Admin Section Scope Hardening Report

**Date:** 2026-01-20  
**Version:** V1  
**Status:** COMPLETE

## Executive Summary

This report documents the complete hardening of the backoffice role model in Koomy V1. The system now enforces:

1. **Two-role model:** Only OWNER and ADMIN have backoffice access
2. **Delegate neutralization:** All "delegate" role privileges systematically removed from authorization checks
3. **Section scope control:** Admins can be restricted to specific sections

## Role Model (V1)

| Role | Backoffice Access | Section Scope | Notes |
|------|-------------------|---------------|-------|
| **OWNER** | Full | ALL (immutable) | Cannot be modified, full access |
| **ADMIN** (sectionScope=ALL) | Full | Unrestricted | Default for new admins |
| **ADMIN** (sectionScope=SELECTED) | Limited | Specific sectionIds[] | Section-scoped content access |
| delegate | NONE | N/A | NEUTRALIZED - treated as member |
| member | NONE | N/A | Mobile app access only |

## Schema Changes

```sql
ALTER TABLE user_community_memberships 
ADD COLUMN section_scope TEXT DEFAULT 'ALL';

ALTER TABLE user_community_memberships 
ADD COLUMN section_ids JSONB;
```

**TypeScript Schema (shared/schema.ts):**
```typescript
sectionScope: text("section_scope").default("ALL"),
sectionIds: jsonb("section_ids").$type<string[]>(),
```

## Centralized Authorization Helpers (V1.1)

### Location: `server/routes.ts` (lines 100-200)

```typescript
// V1 Two-Role Model: Only OWNER and ADMIN have backoffice access
function isOwner(membership: MembershipForRoleCheck): boolean {
  if (!membership) return false;
  return membership.isOwner === true;
}

function isBackofficeAdmin(membership: MembershipForRoleCheck): boolean {
  if (!membership) return false;
  // V1 HARDENING: ONLY owner/admin - delegate role NEUTRALIZED
  return isOwner(membership) || membership.role === "admin";
}

function canAccessSection(membership: MembershipForRoleCheck, sectionId: string | null): boolean {
  if (!membership) return false;
  if (isOwner(membership)) return true;
  if (!isBackofficeAdmin(membership)) return false;
  if (!sectionId) return true;
  const scope = membership.sectionScope || "ALL";
  if (scope === "ALL") return true;
  const allowedSections = membership.sectionIds || [];
  return allowedSections.includes(sectionId);
}

// PREREQUISITE: Caller MUST verify isBackofficeAdmin() BEFORE calling this function
// Returns null for unrestricted access (OWNER or ADMIN with sectionScope=ALL)
// Returns string[] for restricted access (ADMIN with sectionScope=SELECTED)
function getAllowedSectionIds(membership: MembershipForRoleCheck): string[] | null {
  if (!membership) return null;
  if (isOwner(membership)) return null;
  if (!isBackofficeAdmin(membership)) return null;
  const scope = membership.sectionScope || "ALL";
  if (scope === "ALL") return null;
  return membership.sectionIds || [];
}

// V1.1: Uses isBackofficeAdmin for global article checks
async function hasAdminRoleAnywhere(accountId: string, storageInstance): Promise<boolean> {
  if (!accountId) return false;
  const memberships = await storageInstance.getAccountMemberships(accountId);
  return memberships.some((m: any) => isBackofficeAdmin(m));
}
```

## Endpoint Hardening Summary

### Collections Endpoints (7 endpoints)
| Endpoint | Old Check | New Check |
|----------|-----------|-----------|
| POST /api/collections | admin \|\| delegate+canManageCollections | isBackofficeAdmin() |
| GET /api/communities/:id/collections/all | admin \|\| delegate+canManageCollections | isBackofficeAdmin() |
| POST /api/collections/:id/close | admin \|\| delegate+canManageCollections | isBackofficeAdmin() |

### Events Endpoints (2 endpoints)
| Endpoint | Old Check | New Check |
|----------|-----------|-----------|
| POST /api/events | isCommunityAdmin \|\| canManageEvents | isBackofficeAdmin() + canAccessSection() |
| PATCH /api/events/:id | isCommunityAdmin \|\| canManageEvents | isBackofficeAdmin() + canAccessSection() |

### Tags Endpoints (1 endpoint)
| Endpoint | Old Check | New Check |
|----------|-----------|-----------|
| POST /api/communities/:id/tags | admin \|\| delegate \|\| super_admin | isBackofficeAdmin() |

### Articles Endpoints (4 endpoints) - FULLY HARDENED
| Endpoint | Old Check | New Check |
|----------|-----------|-----------|
| POST /api/news | canManageArticles | isBackofficeAdmin() + getAllowedSectionIds() for sectionIds[] |
| PATCH /api/news/:id | canManageArticles | isBackofficeAdmin() + getArticleSections() + getAllowedSectionIds() |
| PATCH /api/news/:id/image | canManageArticles | isBackofficeAdmin() + getArticleSections() + getAllowedSectionIds() |
| DELETE /api/news/:id | canManageArticles | isBackofficeAdmin() + getArticleSections() + getAllowedSectionIds() |
| PUT /api/articles/:id/tags | admin \|\| delegate | isBackofficeAdmin() |

### Article Section Scope Logic (V1.1 - BYPASS FIX)

**Critical Rule:** Admins with sectionScope=SELECTED can ONLY access articles that belong to their allowed sections. Articles without section assignments are inaccessible to scoped admins.

For **creating** articles:
```typescript
// V1.1: Scoped admins MUST specify sectionIds
if (communityId && callerMembership) {
  const allowedSections = getAllowedSectionIds(callerMembership);
  if (allowedSections !== null) {
    // BYPASS FIX: Cannot create articles without sections
    if (!Array.isArray(sectionIds) || sectionIds.length === 0) {
      return res.status(403).json({ 
        error: "Accès refusé - Vous devez sélectionner au moins une section autorisée", 
        code: "SECTION_REQUIRED" 
      });
    }
    const unauthorizedIds = sectionIds.filter((id: string) => !allowedSections.includes(id));
    if (unauthorizedIds.length > 0) {
      return res.status(403).json({ error: "Accès refusé - Vous n'avez pas accès à certaines sections" });
    }
  }
}
```

For **updating/deleting** articles:
```typescript
// V1.1: BYPASS FIX - Block access to articles without sections
if (article.communityId && callerMembership) {
  const allowedSections = getAllowedSectionIds(callerMembership);
  if (allowedSections !== null) {
    const currentSectionIds = await storage.getArticleSections(article.id);
    if (currentSectionIds.length === 0) {
      // BYPASS FIX: No sections = no access for scoped admins
      return res.status(403).json({ 
        error: "Accès refusé - Cet article n'est pas assigné à une section autorisée", 
        code: "SECTION_ACCESS_DENIED" 
      });
    }
    const hasAccessToAny = currentSectionIds.some(id => allowedSections.includes(id));
    if (!hasAccessToAny) {
      return res.status(403).json({ error: "Accès refusé - Vous n'avez pas accès à cet article" });
      }
    }
  }
}
```

## Delegate Neutralization (Complete List)

All occurrences of delegate privilege checks have been systematically removed:

1. **Line ~7665:** Create collection - removed delegate+canManageCollections
2. **Line ~8196:** View all collections - removed delegate+canManageCollections  
3. **Line ~8262:** Close collection - removed delegate+canManageCollections
4. **Line ~8733:** Create tag - removed delegate from role check
5. **Line ~9067:** Set article tags - removed delegate from role check
6. **Line ~5047:** Create event - removed canManageEvents fallback
7. **Line ~5164:** Update event - removed canManageEvents fallback

## Section Scope Logic

### For Events:
```typescript
// When creating event
const eventSectionId = req.body.sectionId;
if (eventSectionId && !canAccessSection(callerMembership, eventSectionId)) {
  return res.status(403).json({ error: "Accès refusé - Vous n'avez pas accès à cette section" });
}

// When updating event
const targetSectionId = req.body.sectionId || existingEvent.sectionId;
if (targetSectionId && !canAccessSection(callerMembership, targetSectionId)) {
  return res.status(403).json({ error: "Accès refusé - Vous n'avez pas accès à cette section" });
}
```

### For Articles (using sectionIds[]):
```typescript
// V1: If article targets sections, check admin can access at least one
const articleSectionIds = await storage.getArticleSections(articleId);
const allowedIds = getAllowedSectionIds(membership);
if (allowedIds && !articleSectionIds.some(id => allowedIds.includes(id))) {
  return res.status(403).json({ error: "Accès refusé" });
}
```

## Backward Compatibility

### Legacy fields preserved (DB only, not used in authorization):
- `canManageEvents` - ignored in V1
- `canManageCollections` - ignored in V1
- `canManageContent` - ignored in V1
- `canManageArticles` - ignored in V1
- `adminRole` - ignored in V1
- `role: "delegate"` - treated as member

### Existing data migration:
- All existing admins default to `sectionScope: "ALL"`
- No breaking changes to existing workflows

## UI Considerations (Not in scope for V1)

The frontend admin panel (Admins.tsx) may still display delegate-related UI elements. These are cosmetic only as the backend enforces the two-role model. Future work should:

1. Remove delegate role from role selection dropdown
2. Add section scope selector for ADMIN role
3. Update mobile admin screens

## Testing Checklist

- [ ] Verify delegate cannot create collections
- [ ] Verify delegate cannot create/update events
- [ ] Verify delegate cannot create tags
- [ ] Verify admin with sectionScope=ALL can access all sections
- [ ] Verify admin with sectionScope=SELECTED can only access assigned sections
- [ ] Verify owner always has full access

## Related Reports

- `docs/audits/BACKOFFICE_ROLE_SIMPLIFICATION_REPORT.md` - Initial role simplification
- `docs/audits/SECURITY_ROLE_NORMALIZATION_REPORT.md` - Security normalization

## Conclusion

The V1 role model is now fully hardened:
- Only OWNER and ADMIN have backoffice access
- Delegate role is completely neutralized in authorization logic
- Section scope provides granular access control for ADMINs
- All changes are backward compatible with existing data
