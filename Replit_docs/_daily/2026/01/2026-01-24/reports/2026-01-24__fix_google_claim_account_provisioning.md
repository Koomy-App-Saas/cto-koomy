# Fix: Google Claim Account Provisioning

**Date**: 2026-01-24  
**Statut**: Corrigé

## Problème identifié

Après Google Sign-In, l'appel à `/api/memberships/claim` échouait avec l'erreur :
```
{"error":"Claim code and account ID are required"}
```

### Cause racine
1. `/api/memberships/claim` exige `{ claimCode, accountId }` dans le body
2. Après Google Sign-In, `/api/auth/me` retourne `user: null` car aucun compte Koomy n'existe
3. L'UI n'avait aucun `accountId` à envoyer → cercle bloquant

## Solution implémentée (Option B)

### Nouvel endpoint backend

**`POST /api/memberships/claim-with-firebase`**

| Champ | Requis | Description |
|-------|--------|-------------|
| claimCode | Oui | Code d'invitation (XXXX-XXXX) |
| Token Firebase | Oui | Via header Authorization |

**Logique:**
1. Vérifie le token Firebase et extrait `uid` + `email`
2. Cherche un compte Koomy existant via `getAccountByProviderId(uid, 'firebase')`
3. Si pas trouvé, vérifie si l'email existe (compte créé via email/password)
   - Si oui: lie le compte existant au Firebase provider
   - Si non: crée un nouveau compte avec `authProvider: 'firebase'`
4. Effectue le claim avec l'`accountId` obtenu/créé
5. Retourne membership + community + account

### Fichiers modifiés

| Fichier | Modification |
|---------|--------------|
| `server/routes.ts` | Ajout endpoint `POST /api/memberships/claim-with-firebase` |
| `client/src/components/unified/UnifiedAuthRegister.tsx` | `performClaimForGoogle()` appelle maintenant `/api/memberships/claim-with-firebase` |

### Code backend ajouté

```typescript
app.post("/api/memberships/claim-with-firebase", async (req, res) => {
  const { claimCode } = req.body;
  const firebaseUser = (req as any).firebaseUser;
  
  // 1. Vérifier claim code
  const membership = await storage.getMembershipByClaimCode(normalizedCode);
  
  // 2. Get or create compte Koomy
  let account = await storage.getAccountByProviderId(firebaseUser.uid, 'firebase');
  if (!account) {
    account = await storage.getAccountByEmail(firebaseUser.email);
    if (account) {
      await storage.linkAccountToProvider(account.id, firebaseUser.uid, 'firebase');
    } else {
      account = await storage.createAccount({
        email: firebaseUser.email,
        passwordHash: '',
        authProvider: 'firebase',
        providerId: firebaseUser.uid
      });
    }
  }
  
  // 3. Claim
  const claimedMembership = await storage.claimMembership(normalizedCode, account.id);
});
```

### Code frontend modifié

```typescript
const performClaimForGoogle = async (claimCodeToUse: string): Promise<boolean> => {
  // Ancien: POST /api/memberships/claim (échouait car pas d'accountId)
  // Nouveau: POST /api/memberships/claim-with-firebase (auto-provisionne le compte)
  const claimResponse = await apiPost('/api/memberships/claim-with-firebase', {
    claimCode: claimCodeToUse
  });
  // ...
};
```

## Tests attendus

### Parcours Google Sign-In (nouvel utilisateur Koomy)
1. `/auth/claim` → Entrer code (ex: ZDQN-97G5) → Vérification OK
2. Clic "Continuer avec Google"
3. Authentification Firebase réussie
4. `POST /api/memberships/claim-with-firebase { claimCode }` → 200 OK
   - Compte Koomy créé automatiquement
   - Membership lié au compte
5. `GET /api/auth/me` → `account != null`, `memberships` non vide
6. Redirection `/app/hub`

### Parcours Google Sign-In (utilisateur Koomy existant)
- Même flow, mais le compte existant est réutilisé (pas de duplication)
- Si le compte était créé via email/password, il est lié au Firebase provider

### Parcours Email/Password (inchangé)
- Continue d'utiliser `/api/memberships/register-and-claim`
- Pas de régression

## Caractéristiques de sécurité

- Token Firebase obligatoire (vérifié via middleware)
- Claim code obligatoire et validé
- Comportement idempotent (pas de duplication de compte)
- Email normalisé en minuscules
- Log d'audit: `[Claim-Firebase] Account X claimed membership Y via Firebase uid Z`
