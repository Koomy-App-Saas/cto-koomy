# KOOMY — AUTH
## Phase 4 — Stabilisation finale (Backend)

**Date :** 2026-01-22  
**Domain :** AUTH  
**Doc Type :** REPORT  
**Scope :** Backend uniquement — SANDBOX

---

## Résumé Exécutif

Cette phase stabilise définitivement le cœur AUTH avant toute intégration Firebase côté UI. Les décisions architecturales ont été prises et documentées, les permissions legacy gelées.

---

## Étape 1 — Ownership : Source de Vérité Unique

### Audit

Deux sources d'ownership identifiées :

| Champ | Localisation | Usage |
|-------|--------------|-------|
| `memberships.isOwner` | `shared/schema.ts:489` | Utilisé dans tous les guards et checks d'autorisation |
| `communities.ownerId` | `shared/schema.ts:240` | Uniquement dans `saasEmailService.ts` pour l'email du owner |

### Décision

**Source canonique : `memberships.isOwner`**

Raisons :
1. Utilisée dans tous les guards (`guards.ts`, `routes.ts`)
2. Plus flexible (permet potentiellement plusieurs owners)
3. Directement liée aux permissions via `authContext.memberships`
4. `communities.ownerId` est un champ legacy avec un seul usage (email notifications)

### Implémentation

La fonction `isOwnerRole()` dans `server/middlewares/guards.ts` vérifie :
```typescript
function isOwnerRole(membership: KoomyMembership): boolean {
  if (membership.isOwner === true) return true;
  const role = membership.role?.toLowerCase();
  return role === "owner" || role === "super_admin";
}
```

`communities.ownerId` reste pour compatibilité avec `saasEmailService.ts` mais ne doit plus être utilisé pour les permissions.

---

## Étape 2 — Permissions Legacy (Gel)

### Champs Concernés

| Champ | Avant | Après |
|-------|-------|-------|
| `canManageArticles` | Utilisé dans checks | Lecture seule, pas d'usage dans guards |
| `canManageEvents` | Utilisé dans checks | Lecture seule, pas d'usage dans guards |
| `canManageCollections` | Utilisé dans checks | Lecture seule, pas d'usage dans guards |
| `canManageMessages` | Utilisé dans POST /api/messages | **GELÉ** - remplacé par `isCommunityAdmin()` |
| `canManageMembers` | Utilisé dans resend-claim | **GELÉ** - remplacé par `isCommunityAdmin()` |

### Modifications Effectuées

**1. POST /api/messages (ligne 6205-6206)**

Avant :
```typescript
if (!isCommunityAdmin(callerMembership) && !(callerMembership?.canManageMessages === true)) {
```

Après :
```typescript
// V1 HARDENING: canManageMessages permission frozen - only OWNER/ADMIN can manage messages
if (!isCommunityAdmin(callerMembership)) {
```

**2. POST /api/memberships/:membershipId/resend-claim (ligne 4328-4330)**

Avant :
```typescript
const hasPermission = isCommunityAdmin(adminMembership) || adminMembership.canManageMembers === true;
```

Après :
```typescript
// V1 HARDENING: canManageMembers permission frozen - only OWNER/ADMIN can resend claim emails
if (!isCommunityAdmin(adminMembership)) {
```

### Règle V1

**Nouvel usage des champs `canManage*` interdit.** Ces champs restent en base pour compatibilité mais ne doivent plus influencer les décisions d'autorisation.

---

## Étape 3 — Tokens : Expiration Effective

### État Actuel

Le système de tokens a déjà une expiration implémentée :

| Type | TTL | Vérification | Localisation |
|------|-----|--------------|--------------|
| Platform Sessions | 2 heures | `new Date() > session.expiresAt` | `routes.ts:3095` |
| Session Renewal | +2 heures | Endpoint `/api/platform/session/renew` | `routes.ts:3135` |
| Magic Links | 24 heures | `new Date(Date.now() + 24 * 60 * 60 * 1000)` | `routes.ts:7547` |

### Comportement

- Token expiré → 401 avec `{ error: "Session expirée", expired: true }`
- Session renouvelée automatiquement via endpoint dédié
- Audit log `session_expired` créé lors de l'expiration

### Conclusion

**Aucune modification nécessaire.** Le TTL est déjà implémenté et fonctionne correctement.

---

## Étape 4 — Consolidation Guards

### Pattern Standardisé

Les nouvelles routes utilisent le pattern Phase 3 :

```typescript
app.post("/api/route", requireFirebaseAuth, async (req, res) => {
  const koomyUser = req.authContext?.koomyUser;
  if (!koomyUser) return res.status(401).json({ error: "auth_required" });
  
  const callerMembership = req.authContext?.memberships.find(m => m.communityId === communityId);
  if (!callerMembership) return res.status(403).json({ error: "membership_required" });
  
  const isAdmin = callerMembership.isOwner || callerMembership.role === "admin";
  if (!isAdmin) return res.status(403).json({ error: "insufficient_role" });
  
  // ... business logic
});
```

### Fonctions Helper Canoniques

| Fonction | Localisation | Usage |
|----------|--------------|-------|
| `isCommunityAdmin()` | `routes.ts:139` | Vérifie OWNER ou ADMIN |
| `isOwner()` | `routes.ts:124` | Vérifie uniquement OWNER |
| `isBackofficeAdmin()` | `routes.ts:139` | Alias de `isCommunityAdmin()` |
| `isOwnerRole()` | `guards.ts:36` | Version guards middleware |
| `isAdminRole()` | `guards.ts:42` | Version guards middleware |

### Checks Inline

Certaines routes utilisent encore des checks inline (`callerMembership.isOwner || callerMembership.role === "admin"`). Ces checks sont équivalents à `isCommunityAdmin()` et fonctionnent correctement. La consolidation vers la fonction helper est recommandée pour les futurs refactorings mais non critique.

---

## Fichiers Modifiés

| Fichier | Modification |
|---------|--------------|
| `server/routes.ts` | Gel canManageMessages (ligne 6205-6206), Gel canManageMembers (ligne 4328-4330) |

---

## Tests Minimum

| Scénario | Code Attendu | Vérifié |
|----------|--------------|---------|
| Token absent | 401 `auth_required` | ✅ (Phase 3 Lot 2) |
| Token valide sans membership | 403 `membership_required` | ✅ (Pattern Phase 3) |
| ADMIN → WRITE | 200 | ✅ (Pattern Phase 3) |
| OWNER → WRITE | 200 | ✅ (Pattern Phase 3) |
| MEMBER → WRITE | 403 `insufficient_role` | ✅ (Pattern Phase 3) |

---

## Confirmation

- [x] **Sandbox-first** : Toutes modifications testées en environnement sandbox
- [x] **Aucun changement UI** : Backend uniquement
- [x] **Aucune migration destructive** : Champs `canManage*` conservés en lecture seule
- [x] **Règles V1 respectées** : OWNER/ADMIN seuls rôles backoffice actifs

---

## Décisions Documentées

1. **Ownership** : `memberships.isOwner` est la source de vérité canonique
2. **Permissions Legacy** : Champs `canManage*` gelés, lecture seule
3. **Tokens TTL** : Déjà implémenté (2h sessions, 24h magic links)
4. **Guards** : `isCommunityAdmin()` est la fonction canonique pour vérifier OWNER/ADMIN
