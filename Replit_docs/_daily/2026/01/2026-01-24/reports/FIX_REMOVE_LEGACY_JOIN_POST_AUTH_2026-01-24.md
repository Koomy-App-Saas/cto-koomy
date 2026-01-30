# FIX: Suppression de la relique "Join Code" Post-Auth

**Date**: 2026-01-24  
**Statut**: Corrigé

## Problème

Après authentification Firebase (Google ou Email), l'utilisateur était redirigé vers l'écran "Rejoindre une communauté" même s'il avait déjà des memberships. C'est une relique de l'ancien flow.

## Cause racine

1. **Mauvais mapping API** : `handleSuccessfulMemberAuth()` cherchait `meResponse.data.account` mais l'API retourne `meResponse.data.user`
2. **Pas de guard sur JoinCommunityStandard** : L'écran Join ne vérifiait pas si l'utilisateur avait des memberships

## Corrections appliquées

### 1. UnifiedAuthLogin.tsx - handleSuccessfulMemberAuth()

**Avant:**
```typescript
const meResponse = await apiGet<{ account: any; memberships: any[] }>("/api/auth/me");
if (meResponse.ok && meResponse.data?.account) { // ← Bug: API retourne "user", pas "account"
```

**Après:**
```typescript
const meResponse = await apiGet<{ user: any; account?: any; memberships: any[] }>("/api/auth/me");
const userData = meResponse.data?.user || meResponse.data?.account;
const memberships = meResponse.data?.memberships || [];

console.log("[POST_AUTH] membershipsCount=" + memberships.length);

if (memberships.length > 0) {
  console.log("[ROUTE_DECISION] -> HUB reason=memberships_present");
  setLocation("/app/hub");
} else {
  console.log("[ROUTE_DECISION] -> JOIN reason=no_memberships");
  setLocation("/app/join");
}
```

### 2. JoinCommunityStandard.tsx - Guard ajouté

```typescript
// GUARD: If user has memberships, redirect to Hub immediately
useEffect(() => {
  if (authReady && account && account.memberships && account.memberships.length > 0) {
    console.log("[LEGACY_JOIN_REDIRECT] detected=true - user has memberships, redirecting to Hub");
    console.log("[ROUTE_DECISION] -> HUB reason=memberships_present (from JoinCommunityStandard guard)");
    setLocation("/app/hub");
    return;
  }
}, [authReady, account, setLocation]);
```

## Fichiers modifiés

| Fichier | Modifications |
|---------|--------------|
| `client/src/components/unified/UnifiedAuthLogin.tsx` | Correction du mapping API user/account, logs de routage |
| `client/src/pages/mobile/JoinCommunityStandard.tsx` | Guard pour rediriger vers Hub si memberships > 0 |

## Logs de preuve attendus

### Compte avec memberships
```
[POST_AUTH] membershipsCount=1
[ROUTE_DECISION] -> HUB reason=memberships_present
```

### Compte sans memberships
```
[POST_AUTH] membershipsCount=0
[ROUTE_DECISION] -> JOIN reason=no_memberships
```

### Accès direct à /app/join avec memberships
```
[LEGACY_JOIN_REDIRECT] detected=true - user has memberships, redirecting to Hub
[ROUTE_DECISION] -> HUB reason=memberships_present (from JoinCommunityStandard guard)
```

## Critères d'acceptation

| Test | Résultat attendu |
|------|------------------|
| Login Google (memberships > 0) | → HUB direct |
| Login Email (memberships > 0) | → HUB direct |
| F5 (memberships > 0) | → HUB direct |
| Écran "Rejoindre" n'apparaît jamais | ✓ |
| Login (memberships == 0) | → écran Join/Claim |

## Règle contractuelle post-auth

- `user` existe ET `memberships.length > 0` → **REDIRECT HUB DIRECT**
- `user` existe ET `memberships.length == 0` → afficher parcours Join/Claim
