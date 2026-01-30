# Wallet Auth State Persistence Fix

**Date**: 2026-01-24  
**Statut**: Corrigé

## Symptôme observé

- Boot: `GET AUTH TOKEN SYNC -> found:false`, `koomy_account -> found:false`
- Après login: token Firebase en cache, `/api/auth/me` → 200 OK
- Mais après F5: retour à l'écran de login, état non persisté

## Cause racine identifiée

**Bug critique dans l'hydratation** (AuthContext.tsx ligne 73-78 avant fix):

```typescript
// AVANT (BUG)
if ((storedAccount || storedUser) && !token) {
  // Force logout - supprime koomy_account!
}
```

Le code vérifie si le token LEGACY (`koomy_auth_token`) existe. Mais les utilisateurs Firebase n'utilisent PAS ce token ! Donc même si `koomy_account` est correctement persisté après login Firebase, au prochain boot, le code voit "pas de token legacy" → force le logout → supprime le compte.

## Corrections appliquées

### 1. Hydratation Firebase-aware (AuthContext.tsx)

```typescript
// APRÈS (FIX)
// Parse account pour vérifier l'auth provider
const isFirebaseUser = parsedAccount?.authProvider === 'firebase' || parsedAccount?.authProvider === 'google';

// Ne forcer le logout que pour les utilisateurs legacy (non-Firebase)
if ((storedAccount || storedUser) && !token && !isFirebaseUser) {
  // Force logout only for legacy auth users
}
```

### 2. Nettoyage des résidus orphelins

```typescript
// Nettoyer membership orphelin (sans account/user)
if (storedMembership && !storedAccount && !storedUser) {
  log("[AUTH] Orphan membership detected - cleaning up residual state");
  removeItemSync(MEMBERSHIP_KEY);
}
```

### 3. Hydratation du membership depuis storage

Le membership est maintenant retourné depuis l'hydratation s'il existe, permettant une navigation directe vers le Hub après F5.

### 4. Instrumentation du token (firebase.ts)

Ajout de logs `[AUTH_STORAGE]` pour tracer les opérations:
- `READ key=firebase_token_cache found=... length=...`
- `WRITE key=firebase_token_cache length=...`
- `REMOVE key=firebase_token_cache reason=logout`

## Fichiers modifiés

| Fichier | Modifications |
|---------|--------------|
| `client/src/contexts/AuthContext.tsx` | Hydratation Firebase-aware, nettoyage orphelins |
| `client/src/lib/firebase.ts` | Instrumentation des opérations token |

## Clés de storage

| Clé | Usage | Persistance |
|-----|-------|-------------|
| `koomy_account` | Données compte utilisateur | localStorage |
| `koomy_current_membership` | Membership actif sélectionné | localStorage |
| `koomy_auth_token` | Token legacy (admin) | localStorage |
| `firebase_token_cache` | Token Firebase | Mémoire (Firebase gère la persistance) |

## Tests attendus après fix

### Login Google → Hub
1. `[AUTH_STORAGE] WRITE key=firebase_token_cache length=...`
2. `[refreshMe:commitStorage] SET koomy_account`
3. `[HubGuard:ALLOW]`

### F5 sur Hub
1. `Hydration result: hasAccount:true, isFirebaseUser:true`
2. Pas de `forcing logout`
3. `[HubGuard:ALLOW]`

## Note sur la double exécution

Si vous voyez 2x "Firebase sign-in successful", cela peut être causé par:
- React StrictMode (double render en dev)
- Double listener onAuthStateChanged

Ce n'est pas bloquant tant que le state final est correct.
