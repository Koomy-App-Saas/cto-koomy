# KOOMY — AUTH FIREBASE ONLY: PROOFS FINAL

**Date**: 2026-01-24  
**Scope**: Admin/Backoffice/Sitepublic  
**Statut**: ⚠️ TEMPLATES À COMPLÉTER EN SANDBOX

> **NOTE**: Ce document est un template de capture. Les preuves réelles doivent être collectées lors de la validation sur les environnements sandbox.

---

## 1. SANDBOX.KOOMY.APP (Wallet Mobile)

### Statut: ⚠️ À CAPTURER

#### 1.1 Token Source

```
# Template de capture console
[AUTH] Token source: Firebase
[AUTH] Token format: xxx.yyy.zzz (JWT)
[AUTH] Token length: XXX caractères (attendu: 800-1500)
```

#### 1.2 API Auth Me

```bash
# Commande de test
curl -X GET "https://sandbox.koomy.app/api/auth/me" \
  -H "Authorization: Bearer {FIREBASE_JWT}"
```

**Expected**: 
- Status: 200 OK
- Body: `{ id, email, role, ... }`

#### 1.3 Requêtes exemples

| Action | Endpoint | Status attendu | Capturé |
|--------|----------|----------------|---------|
| N/A (wallet = membre) | - | - | - |

> Note: sandbox.koomy.app est l'app membre (Wallet), pas admin. Les CRUD sont côté backoffice.

---

## 2. BACKOFFICE-SANDBOX.KOOMY.APP (Admin)

### Statut: ⚠️ À CAPTURER

#### 2.1 Token Source

```
# Template de capture console
[AUTH] Firebase signIn success
[AUTH] Token verified successfully for uid: {firebase_uid}
[AUTH] Token format: xxx.yyy.zzz (JWT)
[AUTH] Token length: XXX caractères (attendu: 800-1500)
```

#### 2.2 API Auth Me

```bash
# Commande de test
curl -X GET "https://backoffice-sandbox.koomy.app/api/auth/me" \
  -H "Authorization: Bearer {FIREBASE_JWT}"
```

**Expected**: 
- Status: 200 OK
- Body: `{ id, email, firstName, lastName, ... }`

#### 2.3 Requêtes CRUD exemples

| Action | Endpoint | Méthode | Status attendu | Body snippet | TraceId | Capturé |
|--------|----------|---------|----------------|--------------|---------|---------|
| POST section | `/api/communities/:id/sections` | POST | 201 | `{ name: "Test" }` | - | ⚠️ |
| POST event | `/api/communities/:id/events` | POST | 201 | `{ title: "Test", date: "..." }` | - | ⚠️ |
| POST message | `/api/communities/:id/messages` | POST | 201 | `{ content: "..." }` | - | ⚠️ |
| POST admin | `/api/communities/:id/admins` | POST | 201 | `{ email: "..." }` | - | ⚠️ |
| POST offer | `/api/communities/:id/offers` | POST | 201 | `{ title: "..." }` | - | ⚠️ |

#### 2.4 Template de capture réseau

```
# Format attendu pour chaque requête
Request:
  URL: POST /api/communities/{id}/sections
  Headers: 
    Authorization: Bearer eyJhbGc...{tronqué}
    Content-Type: application/json
  Body: { "name": "Test Section" }

Response:
  Status: 201 Created
  Body: { "id": "uuid", "name": "Test Section", ... }
  X-Trace-Id: {si disponible}
```

---

## 3. SITEPUBLIC-SANDBOX.KOOMY.APP (Site public)

### Statut: ⚠️ À CAPTURER

> Note: Le site public est principalement en lecture seule. Les endpoints admin ne sont pas accessibles.

#### 3.1 Routes publiques (pas de token requis)

| Endpoint | Status attendu | Capturé |
|----------|----------------|---------|
| GET `/api/public/community/:slug` | 200 | ⚠️ |
| GET `/api/public/community/:slug/events` | 200 | ⚠️ |
| GET `/api/public/community/:slug/news` | 200 | ⚠️ |

#### 3.2 Routes protégées (doit rejeter sans token)

| Endpoint | Status sans token | Capturé |
|----------|-------------------|---------|
| POST `/api/communities/:id/sections` | 401 | ⚠️ |
| POST `/api/communities/:id/events` | 401 | ⚠️ |

---

## 4. NEGATIVE TESTS (Token Legacy rejeté)

### Statut: ⚠️ À CAPTURER

#### 4.1 Test token legacy sur route admin

```bash
# Commande de test
curl -X GET "https://backoffice-sandbox.koomy.app/api/communities/{id}/sections" \
  -H "Authorization: Bearer fake-legacy-token-33chars"
```

**Expected**:
- Status: 401 Unauthorized
- Body: `{ "error": "Firebase authentication required", "code": "FIREBASE_AUTH_REQUIRED" }`

#### 4.2 Test endpoint legacy désactivé

```bash
curl -X POST "https://backoffice-sandbox.koomy.app/api/admin/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"test"}'
```

**Expected**:
- Status: 410 Gone
- Body: `{ "error": "This endpoint is deprecated...", "code": "ENDPOINT_DISABLED" }`

---

## 5. RÉSUMÉ DES PREUVES

| Application | Token Firebase | Auth Me 200 | CRUD fonctionne | Legacy rejeté | Statut |
|-------------|----------------|-------------|-----------------|---------------|--------|
| sandbox.koomy.app | ⚠️ | ⚠️ | N/A (membre) | ⚠️ | ⚠️ NON PROUVÉ |
| backoffice-sandbox.koomy.app | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ⚠️ NON PROUVÉ |
| sitepublic-sandbox.koomy.app | N/A | N/A | N/A | ⚠️ | ⚠️ NON PROUVÉ |

### Instructions de capture

1. Se connecter sur chaque environnement
2. Ouvrir DevTools > Network
3. Effectuer les actions listées
4. Capturer les headers Authorization (vérifier format JWT)
5. Capturer les réponses API (status + body)
6. Mettre à jour ce document avec les preuves réelles

---

**FIN DU TEMPLATE PROOFS_FINAL**
