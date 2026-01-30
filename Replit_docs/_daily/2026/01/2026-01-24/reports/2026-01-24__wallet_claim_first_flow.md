# Wallet Claim-First Flow Implementation

**Date**: 2026-01-24  
**Fichier modifié**: `client/src/pages/_legacy/MobileLogin.tsx`

---

## 1. Problème résolu

L'UI wallet (mode WALLET / sandbox.koomy.app) déclenchait l'authentification Firebase AVANT de demander un code d'invitation, créant une divergence UX vs backend :
- Utilisateur authentifié Firebase mais sans compte KOOMY
- État bloquant avec `/api/auth/me` retournant `user: null`

---

## 2. Solution implémentée : Claim-First Flow

### 2.1 Nouvel écran initial : "Rejoindre une communauté"

Point d'entrée du wallet pour les utilisateurs non-whitelabel :
- Champ obligatoire : **Code d'invitation** (format `ZDQN-97G5`)
- Avertissement explicite sur l'email attendu
- Bouton **Continuer**

### 2.2 Transition vers l'authentification

Au clic sur **Continuer** :
1. Vérification du code via `GET /api/memberships/verify/{code}`
2. Stockage temporaire du `claimCode` dans `sessionStorage`
3. Affichage de l'écran d'authentification Google

### 2.3 Post-authentification Firebase

Après connexion Google réussie :
1. Récupération du `claimCode` depuis `sessionStorage`
2. Appel `POST /api/memberships/register-and-claim`
3. Si erreur 409 (compte existe) : fallback vers `POST /api/memberships/claim`
4. Rafraîchissement via `refreshMe()`
5. Redirection vers `/app/hub`

### 2.4 Garde-fou

Si après authentification `/api/auth/me` retourne `user: null` :
- Écran bloquant avec message d'erreur
- Bouton "Réessayer avec un autre code"
- Redirection obligatoire vers l'écran claim

---

## 3. États du flow (WalletStep)

| État | Description |
|------|-------------|
| `claim_first` | Écran initial avec champ code d'invitation |
| `auth` | Code vérifié, affichage bouton Google |
| `claiming` | Inscription en cours (spinner) |
| `success` | Compte créé, redirection |
| `error` | Erreur avec message et option réessayer |

---

## 4. Fichiers modifiés

| Fichier | Modifications |
|---------|--------------|
| `client/src/pages/_legacy/MobileLogin.tsx` | Ajout du claim-first flow pour mode WALLET |

---

## 5. Modifications clés

### Nouveaux imports
```typescript
import { AlertCircle, CheckCircle2 } from "lucide-react";
```

### Nouveau type
```typescript
type WalletStep = "claim_first" | "auth" | "claiming" | "success" | "error";
```

### Nouveaux états
```typescript
const [walletStep, setWalletStep] = useState<WalletStep>("claim_first");
const [pendingClaimCode, setPendingClaimCode] = useState<string | null>(null);
const [verifiedCommunityName, setVerifiedCommunityName] = useState<string | null>(null);
const [claimError, setClaimError] = useState<string | null>(null);
```

### Nouvelles fonctions
- `handleVerifyClaimCodeAndProceed()` : Vérifie le code et passe à l'étape auth
- `performClaimAfterAuth()` : Appelle register-and-claim après authentification
- `handleResetClaimFlow()` : Réinitialise le flow pour réessayer

### Placeholder réaliste
```typescript
placeholder="ZDQN-97G5"
```

---

## 6. Tests attendus

| Scénario | Résultat attendu |
|----------|------------------|
| Code valide → auth avec BON email | Compte créé, accès wallet |
| Code valide → auth avec MAUVAIS email | Erreur claim, message explicite |
| Code déjà utilisé | Message "invitation déjà utilisée" |
| Code invalide | Message "code invalide" |
| Auth sans claim (état impossible) | Redirigé vers écran claim |

---

## 7. UX améliorée

1. **Message d'avertissement** avant authentification :
   > "Utilisez l'adresse e-mail sur laquelle vous avez reçu l'invitation"

2. **Confirmation visuelle** après vérification code :
   > ✓ Code vérifié - Vous allez rejoindre [Nom communauté]

3. **États de chargement** clairs avec spinners

4. **Messages d'erreur** contextuels

---

## 8. Conformité avec le backend

| Endpoint utilisé | Rôle |
|-----------------|------|
| `GET /api/memberships/verify/{code}` | Vérification code avant auth |
| `POST /api/memberships/register-and-claim` | Création compte + claim |
| `POST /api/memberships/claim` | Claim pour compte existant (fallback) |
| `GET /api/auth/me` | Vérification finale |

---

## Définition de Done

| Critère | Status |
|---------|--------|
| Claim code requis AVANT l'accès wallet | ✅ |
| Utilisateur informé de l'email attendu | ✅ |
| Aucun état "auth sans compte" accessible | ✅ |
| UX alignée avec backend | ✅ |
| Placeholder format réaliste (ZDQN-97G5) | ✅ |

**FIN DU RAPPORT**
