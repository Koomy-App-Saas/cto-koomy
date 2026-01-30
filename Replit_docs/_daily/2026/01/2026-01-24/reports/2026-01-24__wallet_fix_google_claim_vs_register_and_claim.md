# Wallet Fix: Google Claim vs Register-and-Claim

**Date**: 2026-01-24  
**Statut**: Corrigé

## Problème identifié

Après Google Sign-In, l'application appelait incorrectement `/api/memberships/register-and-claim` qui retournait une erreur 400 avec le message "Email et mot de passe sont requis".

### Logs fournis
```
POST /api/memberships/register-and-claim 400
{"error":"Email et mot de passe sont requis"}
request bodyKeys = Array(1) // uniquement claimCode
```

## Cause racine

La fonction `performClaimAfterAuth()` utilisait un seul endpoint pour tous les types d'authentification :
- **Google Sign-In** : Le token Firebase est passé via header, pas besoin d'email/password
- **Email/Password** : L'endpoint `register-and-claim` nécessite `{ claimCode, email, password }`

## Solution implémentée

### Fichier modifié
`client/src/components/unified/UnifiedAuthRegister.tsx`

### Logique de branchement

#### Ancienne logique (incorrecte)
```tsx
performClaimAfterAuth(claimCode)
  → POST /api/memberships/register-and-claim { claimCode } // ERREUR pour Google
```

#### Nouvelle logique (correcte)

**Pour Google Sign-In:**
```tsx
handleSuccessfulGoogleAuth()
  → performClaimForGoogle(claimCode)
    → POST /api/memberships/claim { claimCode }
    → Token Firebase passé via header Authorization
```

**Pour Email/Password:**
```tsx
handleSuccessfulEmailAuth(email, password)
  → performClaimForEmailPassword(claimCode, email, password)
    → POST /api/memberships/register-and-claim { claimCode, email, password }
```

### Fonctions créées

| Fonction | Endpoint | Payload |
|----------|----------|---------|
| `performClaimForGoogle` | `/api/memberships/claim` | `{ claimCode }` |
| `performClaimForEmailPassword` | `/api/memberships/register-and-claim` | `{ claimCode, email, password }` |
| `handleSuccessfulGoogleAuth` | Appelle `performClaimForGoogle` | - |
| `handleSuccessfulEmailAuth` | Appelle `performClaimForEmailPassword` | email, password |

### Points d'appel mis à jour

1. **useEffect (Google redirect result)** : `handleSuccessfulGoogleAuth()`
2. **handleGoogleSignIn (popup)** : `handleSuccessfulGoogleAuth()`
3. **handleEmailRegister** : `handleSuccessfulEmailAuth(email, password)`

## Tests attendus

### Parcours Google Sign-In
1. `/auth/claim` → Entrer code d'invitation (ex: ZDQN-97G5)
2. Clic "Continuer avec Google"
3. Authentification Firebase Google
4. `POST /api/memberships/claim { claimCode }` → 200 OK
5. `GET /api/auth/me` → Compte avec membership
6. Redirection `/app/hub`

### Parcours Email/Password
1. `/auth/claim` → Entrer code d'invitation
2. Formulaire email + password
3. Création compte Firebase email/password
4. `POST /api/memberships/register-and-claim { claimCode, email, password }` → 200 OK
5. `GET /api/auth/me` → Compte avec membership
6. Redirection `/app/hub`

## Résumé des modifications

- **Suppression** : `performClaimAfterAuth()` et `handleSuccessfulMemberAuth()`
- **Ajout** : 
  - `performClaimForGoogle()`
  - `performClaimForEmailPassword()`
  - `handleSuccessfulGoogleAuth()`
  - `handleSuccessfulEmailAuth()`
- **Correction** : Branchement explicite par méthode d'authentification
