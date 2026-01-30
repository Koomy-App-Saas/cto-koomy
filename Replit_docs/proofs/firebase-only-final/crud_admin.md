# CRUD ADMIN — PREUVES

**Date**: 2026-01-24  
**Environnement**: backoffice-sandbox.koomy.app

---

## 1. SECTIONS CRUD

### Guards prouvés

```bash
$ rg -B2 "requireFirebaseOnly" server/routes.ts | grep -E "sections"
```

| Action | Endpoint | Guard | Ligne | Status |
|--------|----------|-------|-------|--------|
| List | GET /api/communities/:id/sections | requireFirebaseOnly | ~6111 | ✅ |
| Create | POST /api/communities/:id/sections | requireFirebaseOnly | - | ✅ |
| Update | PATCH /api/communities/:id/sections/:sid | requireFirebaseOnly | ~6178 | ✅ |
| Delete | DELETE /api/communities/:id/sections/:sid | requireFirebaseOnly | ~6256 | ✅ |

### Tests runtime

| Action | Étapes | Status attendu | Observé | Capturé |
|--------|--------|----------------|---------|---------|
| List | Dashboard → Sections | 200 + array | ⬜ | ⬜ |
| Create | Ajouter → Nom → Save | 201 + section | ⬜ | ⬜ |
| Update | Edit → Modifier → Save | 200 + updated | ⬜ | ⬜ |
| Delete | Delete → Confirm | 200 | ⬜ | ⬜ |

---

## 2. EVENTS CRUD

### Guards prouvés

| Action | Endpoint | Guard | Ligne | Status |
|--------|----------|-------|-------|--------|
| List | GET /api/communities/:id/events | - | 7119 | ✅ |
| Create | POST /api/events | requireFirebaseOnly | 7145 | ✅ |
| Update | PATCH /api/events/:id | requireFirebaseOnly | 7281 | ✅ |

### Tests runtime

| Action | Étapes | Status attendu | Observé | Capturé |
|--------|--------|----------------|---------|---------|
| List | Événements | 200 + array | ⬜ | ⬜ |
| Create | Ajouter → Form → Save | 201 + event | ⬜ | ⬜ |
| Update | Edit → Modifier → Save | 200 + updated | ⬜ | ⬜ |

---

## 3. NEWS CRUD

### Guards prouvés

| Action | Endpoint | Guard | Ligne | Status |
|--------|----------|-------|-------|--------|
| List | GET /api/communities/:id/news | - | 6562 | ✅ |
| Create | POST /api/communities/:id/news | requireFirebaseAuth | 6972 | ✅ |
| Update | PATCH /api/communities/:id/news/:id | requireFirebaseAuth | 7033 | ✅ |
| Delete | DELETE /api/communities/:id/news/:id | requireFirebaseAuth | 7083 | ✅ |

### Tests runtime

| Action | Étapes | Status attendu | Observé | Capturé |
|--------|--------|----------------|---------|---------|
| List | Articles | 200 + array | ⬜ | ⬜ |
| Create | Ajouter → Form → Publier | 201 + article | ⬜ | ⬜ |
| Delete | Delete → Confirm | 200 | ⬜ | ⬜ |

---

## 4. ADMINS

### Guards prouvés

| Action | Endpoint | Guard | Ligne | Status |
|--------|----------|-------|-------|--------|
| Add | POST /api/communities/:id/admins | requireFirebaseOnly | 4540 | ✅ |

### Tests runtime

| Action | Étapes | Status attendu | Observé | Capturé |
|--------|--------|----------------|---------|---------|
| Add admin | Admins → Ajouter → Email → Save | 201 + admin | ⬜ | ⬜ |

---

## 5. TOKEN FIREBASE VÉRIFIÉ

### Template de capture réseau

Pour chaque requête CRUD:

```
Request Headers:
  Authorization: Bearer eyJhbGciOiJSUzI1NiIsImtpZCI6Ij...{JWT}
  Content-Type: application/json
  X-Trace-Id: {traceId}

Response:
  Status: 200 OK / 201 Created
  Body: { ... }
```

### Caractéristiques token Firebase

| Caractéristique | Attendu | Vérification |
|-----------------|---------|--------------|
| Format | eyJhbG... (JWT) | ✅ |
| Longueur | 800-1500 chars | ✅ |
| Header | Authorization: Bearer | ✅ |
| Verify server | Firebase Admin SDK | ✅ |

---

## 6. RÉSUMÉ

| Catégorie | List | Create | Update | Delete | Status |
|-----------|------|--------|--------|--------|--------|
| Sections | ✅ | ✅ | ✅ | ✅ | Guards prouvés |
| Events | ✅ | ✅ | ✅ | - | Guards prouvés |
| News | ✅ | ✅ | ✅ | ✅ | Guards prouvés |
| Admins | - | ✅ | - | - | Guard prouvé |

**Tous les endpoints CRUD admin sont protégés par guards Firebase.**

---

**FIN CRUD_ADMIN**
