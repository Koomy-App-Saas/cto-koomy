# FIX: 401 auth_required sur POST /api/sections (SITE_PUBLIC)

**Date**: 2026-01-24  
**Statut**: Corrigé

## Problème

Sur `sitepublic-sandbox.koomy.app`, les appels POST /api/sections retournaient 401 `auth_required` alors que l'utilisateur était authentifié via Firebase.

## Cause racine

Le httpClient avait **deux systèmes de token** en conflit :

1. `apiFetch()` (ligne 47) : utilise `getFirebaseIdToken()` → token Firebase (~900 chars)
2. `getAuthHeadersOrFail()` (ligne 242) : utilisait `getAuthToken()` → token LEGACY (33 chars)

Les fonctions `authPost/authGet` passaient le token legacy dans les headers, qui **écrasait** le token Firebase ajouté par `apiFetch()`.

```typescript
// AVANT (BUG)
async function getAuthHeadersOrFail() {
  const token = await getAuthToken(); // ← Token LEGACY (33 chars)
  return { headers: { 'Authorization': `Bearer ${token}` } };
}
```

## Correction appliquée

`getAuthHeadersOrFail()` utilise maintenant le token Firebase en priorité :

```typescript
// APRÈS (FIX)
async function getAuthHeadersOrFail() {
  // PRIORITY: Firebase token first, then legacy token
  const firebaseToken = await getFirebaseIdToken();
  if (firebaseToken) {
    console.log('[API_AUTH] provider=firebase tokenLength=' + firebaseToken.length);
    return { headers: { 'Authorization': `Bearer ${firebaseToken}` }, token: firebaseToken };
  }
  
  // Fallback to legacy token for admin flows
  const legacyToken = await getAuthToken();
  if (legacyToken) {
    console.log('[API_AUTH] provider=legacy tokenLength=' + legacyToken.length);
    return { headers: { 'Authorization': `Bearer ${legacyToken}` }, token: legacyToken };
  }
  
  return null; // No token available
}
```

## Fichiers modifiés

| Fichier | Modifications |
|---------|--------------|
| `client/src/api/httpClient.ts` | `getAuthHeadersOrFail()` priorise Firebase token |

## Logs attendus

### Utilisateur Firebase (SITE_PUBLIC)
```
[API_AUTH] provider=firebase tokenLength=942
POST /api/sections → 201 Created
```

### Utilisateur Legacy (Admin)
```
[API_AUTH] provider=legacy tokenLength=33 reason=no_firebase_token
POST /api/sections → 201 Created
```

## Critères d'acceptation

| Test | Attendu |
|------|---------|
| Créer une section sur sitepublic-sandbox | 201/200 (pas 401) |
| tokenLength dans les logs | ~900+ (Firebase) |
| Admin legacy fonctionne toujours | Token legacy utilisé en fallback |
