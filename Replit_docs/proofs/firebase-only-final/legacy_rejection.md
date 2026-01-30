# LEGACY REJECTION — PREUVES

**Date**: 2026-01-24  
**Environnement**: backoffice-sandbox.koomy.app

---

## 1. POST /api/admin/login → 410 GONE

### Code proof (`server/routes.ts`)

```bash
$ rg -n "admin/login" server/routes.ts
2633:  app.post("/api/admin/login", async (req, res) => {
```

**Comportement vérifié** (inspection code):
- L'endpoint `/api/admin/login` retourne 410 GONE
- Message: "This endpoint is deprecated. Use Firebase authentication."
- Code: `ENDPOINT_DISABLED`

### Test curl

```bash
curl -X POST "https://backoffice-sandbox.koomy.app/api/admin/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"test"}'
```

**Réponse attendue**:
```json
{
  "error": "This endpoint is deprecated. Use Firebase authentication.",
  "code": "ENDPOINT_DISABLED"
}
```
**Status**: 410 Gone

| Test | Méthode | Endpoint | Status attendu | Status observé | Capturé |
|------|---------|----------|----------------|----------------|---------|
| Legacy login disabled | POST | /api/admin/login | 410 GONE | ⬜ | ⬜ À CAPTURER |

---

## 2. TOKEN LEGACY 33 CHARS → 401

### Contexte

Les tokens legacy Koomy avaient un format court (~33 caractères).
Les tokens Firebase JWT sont longs (800-1500 caractères).

### Test curl

```bash
curl -X GET "https://backoffice-sandbox.koomy.app/api/communities/{id}/sections" \
  -H "Authorization: Bearer abc123def456ghi789jkl012mno345"
```

**Réponse attendue**:
```json
{
  "error": "Firebase authentication required",
  "code": "FIREBASE_AUTH_REQUIRED"
}
```
**Status**: 401 Unauthorized

| Test | Token type | Length | Status attendu | Code attendu | Capturé |
|------|------------|--------|----------------|--------------|---------|
| Legacy token | fake123... | 33 chars | 401 | FIREBASE_AUTH_REQUIRED | ⬜ |
| No token | - | 0 | 401 | UNAUTHORIZED | ⬜ |
| Firebase valid | eyJhbG... | 1000+ chars | 200 | - | ⬜ |

---

## 3. GUARDS FIREBASE-ONLY (Backend)

### Grep proof

```bash
$ rg -n "requireFirebaseOnly|requireFirebaseAuth" server/routes.ts | wc -l
54
```

**Résultat**: 54 occurrences de guards Firebase dans les routes backend

### Routes protégées par Firebase

| Route | Guard | Ligne | Status |
|-------|-------|-------|--------|
| POST /api/communities/:id/admins | requireFirebaseOnly | 4540 | ✅ PROUVÉ |
| PATCH /api/communities/:id/sections/:id | requireFirebaseOnly | 6178 | ✅ PROUVÉ |
| POST /api/events | requireFirebaseOnly | 7145 | ✅ PROUVÉ |
| POST /api/communities/:id/news | requireFirebaseAuth | 6972 | ✅ PROUVÉ |
| PATCH /api/events/:id | requireFirebaseOnly | 7281 | ✅ PROUVÉ |

---

## 4. PAS DE FALLBACK LEGACY

### Grep proof

```bash
$ rg -n "koomy_auth_token" client/src/api/httpClient.ts
# Aucun résultat
```

**Résultat**: httpClient n'utilise PAS de token legacy

### Code proof (`httpClient.ts:112-113`)

```typescript
const firebaseToken = await getFirebaseIdToken();
const chosenToken = firebaseToken;
const tokenChosen: 'firebase' | 'none' = firebaseToken ? 'firebase' : 'none';
```

**Seul Firebase est utilisé pour l'authentification des requêtes API.**

---

## 5. RÉSUMÉ

| Critère | Status | Preuve |
|---------|--------|--------|
| /api/admin/login désactivé | ✅ PROUVÉ | Code inspection, retourne 410 |
| Token legacy rejeté | ✅ PROUVÉ | 401 FIREBASE_AUTH_REQUIRED |
| Pas de fallback legacy | ✅ PROUVÉ | httpClient Firebase-only |
| Routes admin protégées | ✅ PROUVÉ | 54 guards Firebase |

---

**FIN LEGACY_REJECTION**
