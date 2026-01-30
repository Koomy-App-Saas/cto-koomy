# Wallet Hub Access Fix - Instrumentation et Correction

**Date**: 2026-01-24  
**Statut**: Instrumenté + Corrigé

## Symptôme

Sur sandbox wallet (sandbox.koomy.app):
- Boot: `koomy_current_membership` présent, `koomy_user` absent, token absent
- Après login Firebase: `/api/auth/me` → 200 OK avec `user` + `memberships`
- Mais UI bloquée, AuthContext reste:
  - `isAuthenticated: false`
  - `hasUser: false`
  - `hasAccount: false`

## Cause racine identifiée

1. **Mauvaise structure de l'objet account** : `refreshMe()` ne construisait pas correctement l'objet `AuthAccount` avec tous les champs requis

2. **Field mismatch API/Frontend** : L'API retourne `user` mais le code cherchait parfois `account`

3. **State pas mis à jour** : `setAccountState()` était appelé mais l'objet passé n'avait pas la structure correcte

## Instrumentation ajoutée

### AuthContext.tsx - refreshMe()

```typescript
log("[refreshMe:start] snapshot BEFORE:", { hasAccount, hasUser, hasMembership })
log("[refreshMe:tokens]", { hasFirebaseToken, hasLegacyToken })
log("[refreshMe:apiResponse]", { ok, status, hasUser, hasAccount, membershipsCount, responseKeys })
log("[refreshMe:commitState] setting account:", { id, email, membershipsCount })
log("[refreshMe:commitStorage] SET koomy_account")
log("[refreshMe:commitStorage] SET koomy_current_membership:", { id, communityId })
log("[refreshMe:SUCCESS] AFTER commit")
```

### CommunityHub.tsx - Hub Guard

```typescript
console.log("[HubGuard:check]", { hasAccount, hasUser, accountId, userId, accountMemberships, userMemberships })
console.log("[HubGuard:REJECT] No account or user")  // si refus
console.log("[HubGuard:ALLOW] Access granted")       // si OK
```

## Corrections appliquées

### 1. Construction correcte de l'objet AuthAccount

**Avant:**
```typescript
const refreshedAccount: AuthAccount = {
  ...userData,  // ← structure incomplète
  memberships: response.data.memberships || []
};
```

**Après:**
```typescript
const refreshedAccount: AuthAccount = {
  id: userData.id,
  email: userData.email,
  firstName: userData.firstName || null,
  lastName: userData.lastName || null,
  avatar: userData.avatar || null,
  authProvider: userData.authProvider || 'firebase',
  providerId: userData.providerId || null,
  createdAt: userData.createdAt || new Date(),
  updatedAt: userData.updatedAt || new Date(),
  memberships: response.data.memberships || []
};
```

### 2. Sélection intelligente du membership actif

```typescript
// Préfère le membership actif, sinon prend le premier
const activeMembership = refreshedAccount.memberships.find(m => m.status === 'active') 
  || refreshedAccount.memberships[0];
```

## Fichiers modifiés

| Fichier | Modifications |
|---------|--------------|
| `client/src/contexts/AuthContext.tsx` | Instrumentation + construction correcte de AuthAccount |
| `client/src/pages/mobile/CommunityHub.tsx` | Logs de debug pour le guard |

## Tests attendus

### Parcours Google Login
```
[refreshMe:start] snapshot BEFORE: { hasAccount: false, hasUser: false }
[refreshMe:tokens] { hasFirebaseToken: true }
[refreshMe:apiResponse] { ok: true, hasUser: true, membershipsCount: 1 }
[refreshMe:commitState] setting account: { id: "xxx", membershipsCount: 1 }
[refreshMe:commitStorage] SET koomy_account
[refreshMe:commitStorage] SET koomy_current_membership
[refreshMe:SUCCESS]
[HubGuard:check] { hasAccount: true, accountMemberships: 1 }
[HubGuard:ALLOW] Access granted
```

### Parcours Email/Password Login
Même séquence de logs attendue.

### Hard Refresh (F5)
```
// Au boot, hydratation depuis localStorage
[AUTH] Hydrating from storage (sync)...
[STORAGE] GET_SYNC koomy_account { found: true }
[HubGuard:check] { hasAccount: true }
[HubGuard:ALLOW] Access granted
```

## Prochaines étapes (si problème persiste)

1. Vérifier les logs console après login
2. Identifier où le state est reset (race condition possible)
3. Vérifier que le guard ne dépend pas d'un token legacy
