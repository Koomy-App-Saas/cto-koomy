# AUTH — Fix INVALID_TOKEN_FORMAT 401 on Boot

## Contexte

Sur SANDBOX (sitepublic-sandbox.koomy.app), au boot on observait :
- `GET /api/accounts/me` → 401 Unauthorized
- Body: `{"error":"Invalid token format","code":"INVALID_TOKEN_FORMAT"}`
- Le client concluait "Web session invalid on startup - clearing" et purgeait le storage
- Ensuite Firebase `onAuthStateChanged` fournit un user, `/api/auth/me` répond 200 et la session revient

## Cause racine

Le token Firebase JWT (format `eyJ...`) était stocké dans `koomy_auth_token` localStorage.
Au boot, le code appelait `/api/accounts/me` avec ce token.
Le serveur attend un token legacy format `accountId:secret` (split sur `:` avec 2+ parties).
Un JWT Firebase n'a pas de `:` → `INVALID_TOKEN_FORMAT`.

## Solution implémentée (v2 - après review architect)

### Ajout de helpers de détection (AuthContext.tsx)

```typescript
function isFirebaseJwtToken(token: string): boolean {
  if (!token) return false;
  if (token.startsWith('eyJ')) return true;  // JWT header base64
  if (!token.includes(':')) return true;      // No legacy separator
  return false;
}

function isLegacyKoomyToken(token: string): boolean {
  if (!token) return false;
  const parts = token.split(':');
  return parts.length >= 2 && !token.startsWith('eyJ');
}
```

### Modification de `hydrateAndVerifySession()`

**V2: Ne pas set isAuthenticated=true immédiatement pour les Firebase JWTs**

```typescript
if (isFirebaseJwtToken(token)) {
  log("Firebase JWT detected in storage - skipping /api/accounts/me");
  // NE PAS hydrate l'account immédiatement - onAuthStateChanged le fera
  updateDiagnostics({ authReady: true, isAuthenticated: false });
  setAuthReady(true);
  return;
}

log("Legacy token found, verifying with /api/accounts/me...");
// ... legacy flow unchanged
```

### Modification de `verifySessionOnStartup()`

```typescript
if (isFirebaseJwtToken(token)) {
  log("Firebase JWT detected on startup - skipping /api/accounts/me");
  return;  // Firebase auth handles verification via onAuthStateChanged
}

// Legacy flow only for accountId:secret tokens
```

### Modification de `verifySession()` (v2)

```typescript
const verifySession = async () => {
  const token = localStorage.getItem('koomy_auth_token');
  
  if (isFirebaseJwtToken(token)) {
    log("Firebase JWT detected - using /api/auth/me for verification");
    const response = await apiGet('/api/auth/me');
    // ... handle response
    return { valid: response.ok };
  }
  
  // Legacy token - use /api/accounts/me
  const response = await apiGet('/api/accounts/me', {
    'Authorization': `Bearer ${token}`
  });
  // ... handle response
};
```

## Fichiers modifiés

| Fichier | Changement |
|---------|------------|
| `client/src/contexts/AuthContext.tsx` | Helpers + skip `/api/accounts/me` pour Firebase + utilise `/api/auth/me` dans verifySession |

## Flux auth après fix

### Flux Firebase (SITE_PUBLIC, backoffice, owner)
1. Boot: `hydrateFromStorageSync()` lit token
2. Si token = Firebase JWT:
   - `hydrateAndVerifySession()` → skip `/api/accounts/me`, set authReady=true, isAuthenticated=false
   - `onAuthStateChanged` → Firebase user détecté → appelle `/api/auth/me` → hydrate account/user
   - isAuthenticated devient true APRÈS confirmation Firebase
3. `verifySession()` → utilise `/api/auth/me` (pas `/api/accounts/me`)

### Flux Legacy (mobile native avec token accountId:secret)
1. Boot: token = legacy format
2. `hydrateAndVerifySession()` → appelle `/api/accounts/me` → vérifie token
3. `verifySession()` → utilise `/api/accounts/me` avec Bearer token

## Tests à effectuer

| Test | Étapes | Résultat attendu |
|------|--------|------------------|
| Boot utilisateur Firebase | 1. Login Firebase 2. Refresh page | Pas de 401 INVALID_TOKEN_FORMAT |
| Boot utilisateur legacy | 1. Login legacy 2. Refresh page | `/api/accounts/me` vérifie |
| Appel verifySession() Firebase | 1. Login Firebase 2. Appeler verifySession | `/api/auth/me` utilisé (pas `/api/accounts/me`) |

## Logs console attendus

```
[AUTH] Firebase JWT detected in storage - skipping /api/accounts/me
[AUTH] onAuthStateChanged user=<firebase-user>
[AUTH] Firebase user exists but no account - calling /api/auth/me
[AUTH] /api/auth/me status=200 userPresent=true
```

---

FIN
