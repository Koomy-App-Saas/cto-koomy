# Wallet Auth Hydration and Redirect Fix

**Date**: 2026-01-24  
**Statut**: Corrigé

## Problème identifié

Après login Firebase, `/api/auth/me` retournait 200 avec les données utilisateur, mais AuthContext restait :
```
isAuthenticated: false
hasUser: false
hasAccount: false
hasMembership: true  // ← incohérent
```

L'utilisateur était renvoyé vers l'accueil au lieu du Hub.

### Cause racine

1. **Mauvais champ dans la réponse API** : L'endpoint `/api/auth/me` retourne `{ user: {...} }` mais le code frontend cherchait `{ account: {...} }`

2. **refreshMe() ne trouvait pas les données** : `response.data?.account` était `undefined` car l'API utilise `response.data?.user`

## Solution implémentée

### Fichiers modifiés

| Fichier | Modification |
|---------|--------------|
| `client/src/contexts/AuthContext.tsx` | `refreshMe()` utilise maintenant `response.data?.user` |
| `client/src/components/unified/UnifiedAuthRegister.tsx` | `handleSuccessfulGoogleAuth()` utilise `response.data?.user` |

### Code avant/après

#### AuthContext.tsx - refreshMe()

**Avant:**
```typescript
const accountData = response.data?.account;  // ← undefined car API retourne "user"
```

**Après:**
```typescript
const userData = response.data?.user || response.data?.account;  // ← Compatible avec les deux formats
```

#### UnifiedAuthRegister.tsx - handleSuccessfulGoogleAuth()

**Avant:**
```typescript
const meResponse = await apiGet<{ account: any; memberships: any[] }>("/api/auth/me");
if (meResponse.ok && meResponse.data?.account) {  // ← toujours false
```

**Après:**
```typescript
const meResponse = await apiGet<{ user: any; memberships: any[] }>("/api/auth/me");
const userData = meResponse.data?.user;
if (meResponse.ok && userData) {  // ← correct
```

## Structure de réponse API /api/auth/me

```json
{
  "firebase": {
    "uid": "xxxxx",
    "email": "user@example.com"
  },
  "env": "sandbox",
  "user": {              // ← Attention: "user", pas "account"
    "id": "account-id",
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "avatar": null
  },
  "memberships": [
    {
      "id": "membership-id",
      "communityId": "community-id",
      "role": "member",
      "status": "active"
    }
  ],
  "traceId": "XXXXXXXX"
}
```

## Logs attendus après fix

```
[AUTH] refreshMe called
[AUTH] refreshMe: firebaseToken found: { firebase: true, legacy: false }
[AUTH] refreshMe /api/auth/me response: { ok: true, status: 200, traceId: "TR-XXXX" }
[AUTH] refreshMe: user data received { id: "xxx", email: "xxx", membershipsCount: 1 }
[AUTH] refreshMe success: { accountId: "xxx", memberships: 1 }
[STORAGE] SET koomy_account
[STORAGE] SET koomy_current_membership
[NAV] redirect -> /app/hub
```

## Tests attendus

### Login Google
1. Code invitation → Vérification OK
2. Google Sign-In → OK
3. `POST /api/memberships/claim-with-firebase` → 200
4. `refreshMe()` → `/api/auth/me` → 200
5. AuthContext: `isAuthenticated: true`, `hasAccount: true`
6. Navigation → `/app/hub`

### Login Email/Password
1. Code invitation → Vérification OK
2. Email + Password → OK
3. `POST /api/memberships/register-and-claim` → 201
4. `refreshMe()` → `/api/auth/me` → 200
5. AuthContext: `isAuthenticated: true`, `hasAccount: true`
6. Navigation → `/app/hub`

### Hard Refresh (F5)
1. Page refresh
2. Hydration depuis localStorage
3. AuthContext: données persistées
4. Navigation → reste sur Hub
