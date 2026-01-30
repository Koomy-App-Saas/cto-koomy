# BUGFIX Wallet Hub Auth - 2026-01-24

**Statut**: Corrigé et déployé

## Cause racine

Le front recevait `/api/auth/me` OK (200 avec user+memberships) mais **ne commitait pas l'hydratation applicative** :
1. Pas de listener `onAuthStateChanged` pour détecter la restauration de session Firebase
2. L'hydratation sync au boot ne fonctionnait pas car elle cherchait un token legacy inexistant pour les utilisateurs Firebase
3. Le state restait en mode "guest" malgré une session Firebase valide

## Corrections implémentées

### A) Auth Boot Flow - onAuthStateChanged (AuthContext.tsx)

Ajout d'un listener `onAuthStateChanged` qui :
1. Détecte quand Firebase restaure une session utilisateur
2. Si `account` n'est pas encore hydraté, appelle `/api/auth/me`
3. Commit le state : `setAccountState()`, `setCurrentMembership()`
4. Persiste dans storage : `koomy_account`, `koomy_current_membership`

```typescript
useEffect(() => {
  const auth = getFirebaseAuth();
  const unsubscribe = onAuthStateChanged(auth, async (firebaseUser) => {
    log("[AUTH_BOOT] onAuthStateChanged user=" + firebaseUser?.uid);
    
    if (firebaseUser && !account?.id) {
      // Appeler /api/auth/me et hydrater le state
      const response = await apiGet('/api/auth/me');
      setAccountState(hydratedAccount);
      setCurrentMembership(activeMembership);
      setItemSync(ACCOUNT_KEY, JSON.stringify(hydratedAccount));
    }
  });
  return () => unsubscribe();
}, [account, user]);
```

### B) Hydratation Firebase-aware (AuthContext.tsx)

Modification de `hydrateFromStorageSync()` pour :
- Détecter si l'utilisateur est Firebase (`authProvider === 'firebase' || 'google'`)
- Ne PAS forcer le logout si le token legacy est absent pour les utilisateurs Firebase
- Nettoyer les résidus orphelins (membership sans account/user)

### C) Hub Guard (CommunityHub.tsx)

Le guard accepte maintenant `account || user` sans exiger de token legacy :
```typescript
const currentUser = account || user;
if (!currentUser) {
  // Redirect to /auth
}
// HubGuard:ALLOW si account existe
```

## Fichiers modifiés

| Fichier | Modifications |
|---------|--------------|
| `client/src/contexts/AuthContext.tsx` | Ajout listener onAuthStateChanged, hydratation Firebase-aware |
| `client/src/lib/firebase.ts` | Instrumentation des opérations token |
| `client/src/pages/mobile/CommunityHub.tsx` | Logs de debug pour le guard |

## Logs attendus (instrumentation)

### Login Google → Hub
```
[AUTH_STORAGE] ensureFirebaseToken: fetching fresh token
[AUTH_STORAGE] WRITE key=firebase_token_cache length=...
[AUTH_BOOT] onAuthStateChanged user=<uid>
[AUTH_BOOT] /api/auth/me status=200 userPresent=true membershipsCount=1
[AUTH_COMMIT] setIsAuthenticated=true
[AUTH_STORAGE] WRITE koomy_account id=...
[AUTH_STORAGE] WRITE koomy_current_membership communityId=...
[HubGuard:check] hasAccount=true
[HubGuard:ALLOW]
```

### F5 → Reste connecté
```
Hydrating from storage (sync)...
GET_SYNC koomy_account { found: true }
Hydration result: isFirebaseUser=true
[AUTH_BOOT] onAuthStateChanged user=<uid>
[AUTH_BOOT] Firebase user exists and account already hydrated - skipping
[HubGuard:ALLOW]
```

## Critères d'acceptation

| Test | Attendu |
|------|---------|
| Login Google → Hub | ✓ Arrive au Hub |
| F5 → Reste connecté → Hub | ✓ Reste au Hub |
| Login Email/Password → Hub | ✓ Arrive au Hub |
| F5 → Reste connecté → Hub | ✓ Reste au Hub |

## Notes techniques

- Le token Firebase est en mémoire (`cachedFirebaseToken`) car Firebase gère sa propre persistance via IndexedDB/cookies
- `koomy_account` est la source de vérité pour savoir si l'utilisateur est authentifié côté app
- Le listener `onAuthStateChanged` se déclenche automatiquement quand Firebase restaure une session au boot
