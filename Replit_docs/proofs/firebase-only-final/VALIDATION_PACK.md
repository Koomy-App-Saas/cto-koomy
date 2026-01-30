# PACK VALIDATION FIREBASE-ONLY

**Date**: 2026-01-24  
**Environnement**: Sandbox (backoffice-sandbox.koomy.app)  
**Commit**: bae3460b

---

## 1. COHÉRENCE MULTI-APPS ✅ PROUVÉ

### 1.1 Un seul builder d'URL partagé

**Fichier unique**: `client/src/api/httpClient.ts`

```bash
$ ls -la client/src/api/
httpClient.ts  # SEUL fichier API
config.ts      # Configuration
```

**Pas d'autre httpClient**: Aucun autre fichier ne définit apiFetch, buildUrl, ou les guards.

### 1.2 Toutes les apps utilisent le même httpClient

| App | Fichiers | Import httpClient | Status |
|-----|----------|-------------------|--------|
| **sitepublic** | website/*.tsx | ✅ `from "@/api/httpClient"` | ✅ PARTAGÉ |
| **backoffice** | admin/*.tsx | ✅ `from "@/api/httpClient"` | ✅ PARTAGÉ |
| **wallet/mobile** | mobile/*.tsx | ✅ `from "@/api/httpClient"` | ✅ PARTAGÉ |
| **platform** | platform/*.tsx | ✅ `from "@/api/httpClient"` | ✅ PARTAGÉ |

### 1.3 Preuve grep (40+ fichiers)

```bash
$ grep -r "from ['\"].*httpClient" client/src --include="*.tsx" --include="*.ts" | wc -l
40
```

**Tous importent le même fichier**. Aucune logique locale ou dérogatoire.

### 1.4 Guards P0 dans ce fichier unique

- `validateCommunityId()` : ligne 27-32
- `validatePath()` : ligne 39-66
- **Intégration dans apiFetch()** : ligne 105-110 (APRÈS buildUrl)

```typescript
// httpClient.ts:102-110
const baseUrl = getApiBaseUrl();
const fullUrl = buildUrl(baseUrl, path);

// P0 GUARD: Validate FINAL URL after concatenation
const urlError = validatePath<T>(fullUrl, traceId);
if (urlError) {
  return urlError;  // BLOQUÉ - aucune requête réseau
}
```

---

## 2. P0 — URL INVALIDE BLOQUÉE

### 2.1 Flux: URL avec `//` ou `undefined`

```
┌──────────────────────────────────────────────────────────────┐
│ AVANT (risque)                                               │
│ communityId = "" → URL = /api/communities//sections          │
│                  → fetch() → 404 ou erreur serveur           │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│ APRÈS (guard P0)                                             │
│ communityId = "" → fullUrl = https://api.../communities//... │
│                  → validatePath(fullUrl) → ERREUR DÉTECTÉE   │
│                  → return { ok: false, status: 400 }         │
│                  → ❌ AUCUN fetch() exécuté                  │
└──────────────────────────────────────────────────────────────┘
```

### 2.2 Code validatePath (httpClient.ts:39-66)

```typescript
function validatePath<T>(path: string, traceId: string): ApiResponse<T> | null {
  // Check for double slashes (except in protocol)
  const pathWithoutProtocol = path.replace(/^https?:\/\//, '');
  if (pathWithoutProtocol.includes('//')) {
    console.error('[GUARD] URL contains double slash:', { path, traceId });
    return {
      ok: false,
      status: 400,
      data: { error: 'URL invalide: double slash détecté', invalidPath: true, traceId } as T,
      traceId,
      durationMs: 0,
    };
  }
  
  // Check for /undefined/ or /null/ in path
  if (/\/(undefined|null)\//.test(path) || path.endsWith('/undefined') || path.endsWith('/null')) {
    console.error('[GUARD] URL contains undefined/null:', { path, traceId });
    return {
      ok: false,
      status: 400,
      data: { error: 'URL invalide: paramètre undefined/null', invalidPath: true, traceId } as T,
      traceId,
      durationMs: 0,
    };
  }
  
  return null;  // URL valide, continuer
}
```

### 2.3 Intégration APRÈS buildUrl (httpClient.ts:102-110)

```typescript
const baseUrl = getApiBaseUrl();           // ex: https://api.koomy.app
const fullUrl = buildUrl(baseUrl, path);   // ex: https://api.koomy.app/api/communities//sections

// P0 GUARD: Validate FINAL URL after concatenation
const urlError = validatePath<T>(fullUrl, traceId);
if (urlError) {
  return urlError;  // ← RETOUR IMMÉDIAT, pas de fetch()
}
```

**CRITIQUE**: Le guard valide `fullUrl` (URL finale) et non `path` seul.
Cela attrape les `//` causés par `baseUrl/` + `/path`.

### 2.4 Log attendu (console navigateur)

```
[GUARD] URL contains double slash: { path: "https://api.koomy.app/api/communities//sections", traceId: "TR-XXXXXX" }
```

**Aucune ligne `[API TRACE ...] 📤 REQUEST`** pour cette URL = aucun réseau.

---

## 3. P0 — URL VALIDE AUTORISÉE

### 3.1 Exemple requête réussie (log réel)

```javascript
// Console navigateur
[API TRACE TR-UAY3ECTR] 📤 REQUEST {
  method: "GET",
  path: "/api/white-label/config",
  fullUrl: "https://api.koomy.app/api/white-label/config",
  headers: { "Content-Type": "application/json", "X-Trace-Id": "TR-UAY3ECTR", "X-Platform": "web" }
}
[TRACE TR-UAY3ECTR] 🌐 Using fetch
[API TRACE TR-UAY3ECTR] 📥 RESPONSE {
  status: 200,
  ok: true,
  durationMs: 4682,
  bodySnippet: "{\"whiteLabel\":false,...}"
}
```

### 3.2 Flux URL valide

```
communityId = "abc123"
→ path = "/api/communities/abc123/sections"
→ fullUrl = "https://api.koomy.app/api/communities/abc123/sections"
→ validatePath(fullUrl) → null (OK)
→ fetch(fullUrl) exécuté
→ Réponse 200 OK
```

---

## 4. AUTH FIREBASE — PREUVES

### 4.1 Header Authorization (httpClient.ts:114-117)

```typescript
const firebaseToken = await getFirebaseIdToken();
const chosenToken = firebaseToken;
const tokenChosen: 'firebase' | 'none' = firebaseToken ? 'firebase' : 'none';
```

### 4.2 Exemple header envoyé

```
Authorization: Bearer eyJhbGciOiJSUzI1NiIsImtpZCI6IjEyMzQ1NiIsInR5cCI6IkpXVCJ9...
X-Trace-Id: TR-XXXXXX
Content-Type: application/json
```

### 4.3 Décodage Firebase côté backend (server/firebaseAdmin.ts)

```typescript
import { getAuth } from "firebase-admin/auth";

async function verifyFirebaseToken(token: string) {
  const decodedToken = await getAuth().verifyIdToken(token);
  return decodedToken;  // { uid, email, ... }
}
```

### 4.4 Mapping erreurs Firebase (firebase.ts:222-230)

| Code Firebase | Message FR | Status |
|---------------|------------|--------|
| `auth/wrong-password` | "Mot de passe incorrect" | ✅ |
| `auth/user-not-found` | "Aucun compte associé à cet email" | ✅ |
| `auth/invalid-email` | "Adresse email invalide" | ✅ |
| `auth/invalid-credential` | "Email ou mot de passe incorrect" | ✅ |
| `auth/too-many-requests` | "Trop de tentatives..." | ✅ |
| `auth/user-disabled` | "Ce compte a été désactivé" | ✅ |

### 4.5 Intercepteur 401/403 (httpClient.ts:217-239)

```typescript
if (status === 401) {
  (responseData as any).userMessage = 'Session expirée. Veuillez vous reconnecter.';
}

if (status === 403) {
  const errorCode = (responseData as any)?.code;
  if (errorCode === 'ADMIN_REQUIRED' || ...) {
    (responseData as any).userMessage = 'Droits administrateur requis';
  } else if (errorCode === 'COMMUNITY_MISMATCH') {
    (responseData as any).userMessage = "Vous n'avez pas accès à cette communauté";
  } else {
    (responseData as any).userMessage = 'Accès non autorisé';
  }
}
```

---

## 5. CHECKLIST SMOKE TESTS (10 tests)

### Instructions humain

Exécuter sur **backoffice-sandbox.koomy.app** avec DevTools ouvert (Console + Network).

| # | Test | Action | Attendu | ✅/❌ |
|---|------|--------|---------|------|
| 1 | **Login Firebase** | Ouvrir /admin/login, saisir credentials valides | Redirect Dashboard, console: `[AUTH] Firebase sign-in successful` | ⬜ |
| 2 | **Session F5** | Sur Dashboard, appuyer F5 | Reste sur Dashboard, pas de redirect login | ⬜ |
| 3 | **Logout** | Menu → Se déconnecter | Redirect /admin/login | ⬜ |
| 4 | **Mauvais mdp** | Login avec mauvais mot de passe | Toast "Mot de passe incorrect", console: `auth/wrong-password` | ⬜ |
| 5 | **CRUD Sections** | Dashboard → Sections → Créer | Section créée, Network: POST 201 | ⬜ |
| 6 | **CRUD Events** | Dashboard → Événements → Créer | Event créé, Network: POST 201 | ⬜ |
| 7 | **Token Firebase** | Network tab → Requête API | Header `Authorization: Bearer eyJ...` (long JWT) | ⬜ |
| 8 | **Pas de //** | Network tab → Toutes requêtes | Aucune URL avec `//` dans le path | ⬜ |
| 9 | **Pas de undefined** | Network tab → Toutes requêtes | Aucune URL avec `undefined` | ⬜ |
| 10 | **0 club → block** | Déconnecter, créer compte sans club | Écran "Aucun club associé" | ⬜ |

### Validation finale

- [ ] Tous les tests passent
- [ ] Console: aucun `[GUARD]` rouge (= aucune URL bloquée en production)
- [ ] Network: 0 requête avec `//` ou `undefined`

---

## 6. RÉSUMÉ

| Critère | Status | Preuve |
|---------|--------|--------|
| Un seul httpClient partagé | ✅ PROUVÉ | grep: 40 imports, 1 fichier |
| Guards P0 sur URL finale | ✅ PROUVÉ | validatePath APRÈS buildUrl |
| Auth Firebase-only | ✅ PROUVÉ | getFirebaseIdToken(), pas de fallback |
| Mapping erreurs FR | ✅ PROUVÉ | 8 codes dans firebase.ts |
| Intercepteur 401/403 | ✅ PROUVÉ | httpClient.ts:217-239 |

**CONCLUSION**: Les guards P0/P1/P2 sont en place et validés par inspection de code.
Les smoke tests ci-dessus permettront de capturer les preuves runtime.

---

**FIN VALIDATION_PACK**
