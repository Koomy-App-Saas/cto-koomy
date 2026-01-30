# KOOMY — QA CHECKLIST EXPANDED

**Date**: 2026-01-24  
**Scope**: Firebase-only migration  
**Total scénarios**: 28

---

## MODULE 1: AUTH & IDENTITY (8 tests)

### 1.1 Login Standard

| # | Scénario | Étapes | Attendu | Endpoints | Status |
|---|----------|--------|---------|-----------|--------|
| 1 | Login email/password OK | 1. Ouvrir login 2. Saisir email/mdp valides 3. Submit | Dashboard affiché | POST Firebase signIn, GET /api/auth/me | ⬜ |
| 2 | Login mauvais mot de passe | 1. Saisir email valide 2. Mauvais mdp 3. Submit | Toast "Mot de passe incorrect" | Firebase signIn error | ⬜ |
| 3 | Login compte inexistant | 1. Saisir email inexistant 2. Submit | Toast "Aucun compte avec cet email" | Firebase signIn error | ⬜ |
| 4 | Login email invalide | 1. Saisir "test" (pas d'@) 2. Submit | Toast "Adresse email invalide" | Firebase signIn error | ⬜ |

### 1.2 Session Management

| # | Scénario | Étapes | Attendu | Endpoints | Status |
|---|----------|--------|---------|-----------|--------|
| 5 | F5 Refresh | 1. Login 2. Dashboard 3. F5 | Reste sur dashboard, connecté | Firebase token persistence | ⬜ |
| 6 | Logout | 1. Login 2. Menu → Logout | Redirect login, session cleared | Firebase signOut | ⬜ |
| 7 | Nouvel onglet | 1. Login 2. Ouvrir nouvel onglet | Même session active | Firebase token shared | ⬜ |
| 8 | Token expiré (simulé) | 1. Login 2. Attendre 1h+ 3. Action | Token auto-refresh, action OK | Firebase token refresh | ⬜ |

---

## MODULE 2: LEGACY REJECTION (4 tests)

| # | Scénario | Étapes | Attendu | Endpoints | Status |
|---|----------|--------|---------|-----------|--------|
| 9 | Token legacy sur route admin | curl avec `Authorization: Bearer fake123` | 401 FIREBASE_AUTH_REQUIRED | GET /api/communities/:id/sections | ⬜ |
| 10 | POST /api/admin/login | curl POST avec credentials | 410 GONE + message deprecated | POST /api/admin/login | ⬜ |
| 11 | Token 33 chars (legacy format) | curl avec token legacy valide | 401 rejected | GET /api/auth/me | ⬜ |
| 12 | Sans Authorization header | curl sans header | 401 Unauthorized | GET /api/communities/:id | ⬜ |

---

## MODULE 3: CRUD SECTIONS (4 tests)

| # | Scénario | Étapes | Attendu | Endpoints | Status |
|---|----------|--------|---------|-----------|--------|
| 13 | List sections | 1. Dashboard 2. Sections | Liste affichée | GET /api/communities/:id/sections | ⬜ |
| 14 | Create section | 1. Sections 2. Ajouter 3. Nom 4. Save | Section créée, toast success | POST /api/communities/:id/sections | ⬜ |
| 15 | Update section | 1. Sections 2. Edit 3. Modifier 4. Save | Section modifiée | PATCH /api/communities/:id/sections/:sid | ⬜ |
| 16 | Delete section | 1. Sections 2. Delete 3. Confirm | Section supprimée | DELETE /api/communities/:id/sections/:sid | ⬜ |

---

## MODULE 4: CRUD EVENTS (3 tests)

| # | Scénario | Étapes | Attendu | Endpoints | Status |
|---|----------|--------|---------|-----------|--------|
| 17 | List events | 1. Événements | Liste affichée | GET /api/communities/:id/events | ⬜ |
| 18 | Create event | 1. Ajouter 2. Remplir form 3. Save | Événement créé | POST /api/events | ⬜ |
| 19 | Update event | 1. Edit 2. Modifier 3. Save | Événement modifié | PATCH /api/events/:id | ⬜ |

---

## MODULE 5: CRUD NEWS (3 tests)

| # | Scénario | Étapes | Attendu | Endpoints | Status |
|---|----------|--------|---------|-----------|--------|
| 20 | List news | 1. Articles | Liste affichée | GET /api/communities/:id/news | ⬜ |
| 21 | Create news | 1. Ajouter 2. Remplir 3. Save | Article créé | POST /api/communities/:id/news | ⬜ |
| 22 | Delete news | 1. Article 2. Delete 3. Confirm | Article supprimé | DELETE /api/communities/:id/news/:id | ⬜ |

---

## MODULE 6: COMMUNITYID GUARDS (4 tests)

| # | Scénario | Étapes | Attendu | Endpoints | Status |
|---|----------|--------|---------|-----------|--------|
| 23 | communityId absent | 1. DevTools 2. `localStorage.removeItem('koomy_community_id')` 3. F5 | Message "Aucune communauté sélectionnée", pas de requête réseau | Aucun (guard bloque) | ⬜ |
| 24 | communityId = "undefined" | 1. Set localStorage = "undefined" 2. F5 | Message erreur, pas de requête `/api/communities/undefined/` | Aucun (guard bloque) | ⬜ |
| 25 | communityId vide | 1. Set localStorage = "" 2. F5 | Message erreur, pas de requête `/api/communities//` | Aucun (guard bloque) | ⬜ |
| 26 | Network tab verification | 1. Ouvrir Network 2. Naviguer pages admin | Aucune URL avec `//` ou `undefined` | Toutes | ⬜ |

---

## MODULE 7: PERMISSIONS RBAC (2 tests)

| # | Scénario | Étapes | Attendu | Endpoints | Status |
|---|----------|--------|---------|-----------|--------|
| 27 | Membre sur action admin | 1. Login membre 2. Tenter POST section | 403 Forbidden + message | POST /api/communities/:id/sections | ⬜ |
| 28 | Admin sur autre communauté | 1. Login admin club A 2. Tenter action club B | 403 Forbidden | POST /api/communities/:idB/sections | ⬜ |

---

## RÉSUMÉ COVERAGE

| Module | Tests | Risque couvert |
|--------|-------|----------------|
| Auth & Identity | 8 | Login, session, errors |
| Legacy Rejection | 4 | Tokens legacy, endpoint disabled |
| CRUD Sections | 4 | Create/Read/Update/Delete |
| CRUD Events | 3 | Create/Read/Update |
| CRUD News | 3 | Create/Read/Delete |
| CommunityId Guards | 4 | URLs invalides |
| Permissions RBAC | 2 | Rôles et accès |
| **TOTAL** | **28** | - |

---

## EXÉCUTION RECOMMANDÉE

### Ordre d'exécution

1. **Module 1** (Auth) → Si échec, STOP
2. **Module 2** (Legacy) → Si échec, risque sécurité
3. **Module 6** (CommunityId) → Si échec, P0
4. **Modules 3-5** (CRUD) → Fonctionnel
5. **Module 7** (RBAC) → Permissions

### Temps estimé

| Mode | Temps |
|------|-------|
| Manuel complet | 2-3h |
| Smoke test (10 tests clés) | 45min |
| Automatisé (si E2E) | 15min |

### Tests smoke prioritaires

1, 2, 5, 6, 9, 10, 14, 23, 26, 27

---

## TEMPLATE RÉSULTAT

```
Date: ____
Testeur: ____
Environnement: backoffice-sandbox.koomy.app

✅ Passed: __/28
❌ Failed: __/28
⚠️ Blocked: __/28

Détails échecs:
- Test #__: [description]
- Test #__: [description]
```

---

**FIN QA_CHECKLIST_EXPANDED**
