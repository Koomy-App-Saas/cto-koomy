# Wallet Fix: refreshMe utilise /api/auth/me

**Date**: 2026-01-24  
**Statut**: Corrigé

## Problème identifié

Après inscription email/password + claim, la fonction `refreshMe()` échouait :

```
POST /api/memberships/register-and-claim -> 201 OK
[AUTH] refreshMe called
refreshMe: token found: false
GET /api/accounts/me -> 401
{"error":"Invalid token format","code":"INVALID_TOKEN_FORMAT"}
```

L'utilisateur était redirigé vers l'accueil au lieu du Hub.

### Cause racine

Le wallet est en mode **FIREBASE_ONLY**, mais `refreshMe()` appelait `/api/accounts/me` qui attend un token KOOMY au format `Bearer <jwt>` traditionnel.

Le token Firebase (929 caractères) était envoyé au mauvais endpoint qui attendait un format différent.

## Solution implémentée

### Fichier modifié
`client/src/contexts/AuthContext.tsx`

### Changements

#### Avant (incorrect)
```typescript
const refreshMe = useCallback(async (): Promise<boolean> => {
  const token = isNative ? await getAuthToken() : localStorage.getItem('koomy_auth_token');
  
  const response = await apiGet('/api/accounts/me', headers);
  // ... échouait avec 401 pour les users Firebase
});
```

#### Après (correct)
```typescript
const refreshMe = useCallback(async (): Promise<boolean> => {
  // Try Firebase token first (for wallet/member flows)
  const firebaseToken = await getFirebaseIdToken();
  // Fallback to legacy Koomy token (for admin flows)
  const legacyToken = isNative ? await getAuthToken() : localStorage.getItem('koomy_auth_token');
  
  // Use /api/auth/me which works with Firebase tokens
  const response = await apiGet<{ account: any; memberships: any[] }>('/api/auth/me');
  
  // Hydrate account + set current membership
  if (refreshedAccount.memberships?.length > 0) {
    const firstMembership = refreshedAccount.memberships[0];
    setCurrentMembership(firstMembership);
    // ... save to storage
  }
});
```

### Import ajouté
```typescript
import { clearFirebaseTokenCache, getFirebaseIdToken } from "@/lib/firebase";
```

## Flow corrigé

### Email/Password Registration
1. `POST /api/memberships/register-and-claim` → 201 OK
2. `refreshMe()` appelé
3. `GET /api/auth/me` → 200 OK (token Firebase dans header via httpClient)
4. Account + memberships hydratés
5. Navigation → Hub

### Google Sign-In
1. `POST /api/memberships/claim-with-firebase` → 200 OK
2. `refreshMe()` appelé
3. `GET /api/auth/me` → 200 OK
4. Account + memberships hydratés
5. Navigation → Hub

## Tests attendus

### Parcours email/password
```
verify claimCode OK
register-and-claim -> 201
refreshMe -> /api/auth/me -> 200
koomy_account = { id, email, memberships }
koomy_current_membership = { memberId, communityId }
navigation -> /app/hub
```

### Parcours "J'ai un compte"
```
login -> /api/auth/me -> 200
navigation -> /app/hub
```

## Résumé des améliorations

| Aspect | Avant | Après |
|--------|-------|-------|
| Endpoint | `/api/accounts/me` | `/api/auth/me` |
| Token source | KOOMY token only | Firebase token (via httpClient) |
| Hydratation membership | Non | Oui (première membership auto-sélectionnée) |
| Compatibilité wallet | Non (401) | Oui (200) |
