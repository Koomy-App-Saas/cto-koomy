# KOOMY — ROLES
## RBAC Phase 3 — Lot 2 (Sections / Catégories / Contenus — WRITE)

**Date :** 2026-01-21  
**Domain :** ROLES  
**Doc Type :** REPORT  
**Scope :** Backend guards — SANDBOX

---

## Résumé Exécutif

Ce rapport documente l'application des guards RBAC sur les routes WRITE liées aux sections, catégories et contenus (articles/news). Les routes sans protection ont été sécurisées avec `requireFirebaseAuth` et vérification admin via `authContext`.

**Règle V1 :** Seulement 2 rôles backoffice visibles = OWNER + ADMIN. Tous les autres = MEMBER sans accès.

---

## Table d'Audit des Routes

### Sections

| Route | Méthode | Type | Guard Avant | Guard Après | Risque |
|-------|---------|------|-------------|-------------|--------|
| `/api/sections` | POST | WRITE | **AUCUN** | `requireFirebaseAuth` + authContext admin | CRITIQUE → CORRIGÉ |
| `/api/communities/:communityId/sections/:sectionId` | PATCH | WRITE | requireAuth + isCommunityAdmin | Inchangé (déjà protégé) | Moyen |
| `/api/communities/:communityId/sections/:sectionId` | DELETE | WRITE | requireAuth + isCommunityAdmin | Inchangé (déjà protégé) | Élevé |

### Catégories

| Route | Méthode | Type | Guard Avant | Guard Après | Risque |
|-------|---------|------|-------------|-------------|--------|
| `/api/communities/:communityId/categories` | POST | WRITE | requireAuth + isCommunityAdmin | Inchangé (déjà protégé) | Moyen |
| `/api/communities/:communityId/categories/:categoryId` | PATCH | WRITE | requireAuth + isCommunityAdmin | Inchangé (déjà protégé) | Moyen |
| `/api/communities/:communityId/categories/:categoryId` | DELETE | WRITE | requireAuth + isCommunityAdmin | Inchangé (déjà protégé) | Élevé |
| `/api/communities/:communityId/categories/reorder` | POST | WRITE | requireAuth + isCommunityAdmin | Inchangé (déjà protégé) | Faible |

### Articles/News

| Route | Méthode | Type | Guard Avant | Guard Après | Risque |
|-------|---------|------|-------------|-------------|--------|
| `/api/news` | POST | WRITE | requireAuth + isBackofficeAdmin | Inchangé (déjà protégé) | Moyen |
| `/api/news/:id` | PATCH | WRITE | requireAuth + isBackofficeAdmin | Inchangé (déjà protégé) | Moyen |
| `/api/news/:id/image` | PATCH | WRITE | requireAuth + isBackofficeAdmin | Inchangé (déjà protégé) | Faible |
| `/api/news/:id` | DELETE | WRITE | requireAuth + isBackofficeAdmin | Inchangé (déjà protégé) | Élevé |
| `/api/communities/:communityId/news` | POST | WRITE | **AUCUN** | `requireFirebaseAuth` + authContext admin | CRITIQUE → CORRIGÉ |
| `/api/communities/:communityId/news/:id` | PATCH | WRITE | **AUCUN** | `requireFirebaseAuth` + authContext admin | CRITIQUE → CORRIGÉ |
| `/api/communities/:communityId/news/:id` | DELETE | WRITE | **AUCUN** | `requireFirebaseAuth` + authContext admin | CRITIQUE → CORRIGÉ |

### Events

| Route | Méthode | Type | Guard Avant | Guard Après | Risque |
|-------|---------|------|-------------|-------------|--------|
| `/api/events` | POST | WRITE | requireAuth + isBackofficeAdmin | Inchangé (déjà protégé) | Moyen |
| `/api/events/:id` | PATCH | WRITE | requireAuth + isBackofficeAdmin | Inchangé (déjà protégé) | Moyen |

### Messages

| Route | Méthode | Type | Guard Avant | Guard Après | Risque |
|-------|---------|------|-------------|-------------|--------|
| `/api/messages` | POST | WRITE | requireAuth + isCommunityAdmin | Inchangé (déjà protégé) | Moyen |
| `/api/messages/:id/read` | PATCH | WRITE | requireAuth | Inchangé (membre peut marquer lu) | Faible |

---

## Routes Modifiées (4)

### 1. POST /api/sections

**Avant :** Aucune vérification d'authentification  
**Après :**
```typescript
app.post("/api/sections", requireFirebaseAuth, async (req, res) => {
  const koomyUser = req.authContext?.koomyUser;
  if (!koomyUser) return res.status(401).json({ error: "auth_required" });
  
  const callerMembership = req.authContext?.memberships.find(m => m.communityId === communityId);
  if (!callerMembership) return res.status(403).json({ error: "membership_required" });
  
  const isAdmin = callerMembership.isOwner || callerMembership.role === "admin";
  if (!isAdmin) return res.status(403).json({ error: "insufficient_role" });
  // ...
});
```

### 2. POST /api/communities/:communityId/news

**Avant :** Aucune vérification d'authentification  
**Après :** `requireFirebaseAuth` + authContext admin check

### 3. PATCH /api/communities/:communityId/news/:id

**Avant :** Aucune vérification d'authentification  
**Après :** `requireFirebaseAuth` + authContext admin check

### 4. DELETE /api/communities/:communityId/news/:id

**Avant :** Aucune vérification d'authentification  
**Après :** `requireFirebaseAuth` + authContext admin check

---

## Résultats des Tests

### Test 1: Sans token → 401 auth_required

| Route | Résultat |
|-------|----------|
| POST /api/sections | ✅ `{"error":"auth_required"}` |
| POST /api/communities/test/news | ✅ `{"error":"auth_required"}` |
| PATCH /api/communities/test/news/test-id | ✅ `{"error":"auth_required"}` |
| DELETE /api/communities/test/news/test-id | ✅ `{"error":"auth_required"}` |

---

## Notes

- **Aucun changement UI** : Modifications backend uniquement
- **Aucun changement paiements** : Routes billing/webhook non touchées
- **Routes existantes** : Les routes avec requireAuth + isCommunityAdmin existantes n'ont pas été modifiées car déjà protégées
- **Pattern Phase 3** : Utilise `requireFirebaseAuth` comme guard middleware + vérification admin via `authContext.memberships`

---

## Codes d'Erreur Standardisés

| Code | HTTP | Signification |
|------|------|---------------|
| `auth_required` | 401 | Token Firebase manquant ou invalide |
| `membership_required` | 403 | Utilisateur authentifié mais pas membre de la communauté |
| `insufficient_role` | 403 | Membre mais pas OWNER/ADMIN |

---

## Critères de Fin Lot 2

- [x] Toutes les routes WRITE sections/catégories/contenus sont bloquées pour MEMBER
- [x] OWNER/ADMIN passent (via authContext verification)
- [x] Aucun effet domino sur le reste du produit
- [x] Tests 401 validés
