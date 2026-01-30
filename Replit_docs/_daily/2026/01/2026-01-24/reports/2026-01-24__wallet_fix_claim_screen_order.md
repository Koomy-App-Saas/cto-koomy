# Wallet Fix: Claim Screen Order (Claim Before Signup)

**Date**: 2026-01-24  
**Fichiers modifiés**: 
- `client/src/components/unified/UnifiedAuthChoice.tsx`
- `client/src/components/unified/UnifiedAuthRegister.tsx`
- `client/src/pages/mobile/AuthClaim.tsx` (nouveau)
- `client/src/App.tsx`

---

## 1. Problème initial

Le bouton "C'est ma première fois sur Koomy" redirigeait directement vers l'écran de création de compte (email/Google), AVANT de demander le code d'invitation.

**Comportement incorrect observé:**
1. Accueil wallet
2. Clic sur "C'est ma première fois sur Koomy"
3. ❌ Écran de création de compte (email / mot de passe / Google)
4. Puis seulement écran claim code

---

## 2. Correction apportée

### Nouvel ordre des écrans (CONFORME)

1️⃣ **Accueil wallet** (`/auth`)
   - Bouton : "C'est ma première fois sur Koomy"

⬇️

2️⃣ **Écran Claim Code** (`/auth/claim`) ← **NOUVEL ÉCRAN**
   - Champ obligatoire : Code d'invitation (format ZDQN-97G5)
   - Avertissement : "Utilisez l'email de votre invitation"
   - Bouton : "Vérifier le code"
   - Validation via `GET /api/memberships/verify/{code}`
   - Stockage du code en `sessionStorage`

⬇️

3️⃣ **Écran Création de compte** (`/auth/register`)
   - Email / mot de passe
   - Google Sign-In
   - Affiche le nom de la communauté (si disponible)
   - Accessible UNIQUEMENT après validation du claim code

⬇️

4️⃣ **Appel backend** (automatique après auth)
   - `POST /api/memberships/register-and-claim`
   - Fallback: `POST /api/memberships/claim` (si compte existe)
   - Rafraîchissement `/api/auth/me`

⬇️

5️⃣ **Accès au wallet** (`/app/hub`)

---

## 3. Modifications techniques

### 3.1 Nouveau fichier: `client/src/pages/mobile/AuthClaim.tsx`

Écran dédié pour la saisie du claim code AVANT authentification.

Fonctionnalités:
- Champ de saisie avec formatage auto (XXXX-XXXX)
- Placeholder réaliste: "ZDQN-97G5"
- Validation du code via API
- Stockage temporaire en `sessionStorage`
- États: saisie → vérifié → continuer

### 3.2 Modification: `client/src/components/unified/UnifiedAuthChoice.tsx`

```diff
- onClick={() => setLocation(`${baseRoute}/register`)}
+ onClick={() => setLocation(isAdmin ? `${baseRoute}/register` : `${baseRoute}/claim`)}
```

Le bouton "première fois" redirige maintenant vers `/auth/claim` pour les membres.

### 3.3 Modification: `client/src/components/unified/UnifiedAuthRegister.tsx`

Ajout de la logique de claim après authentification:
- Récupération du claim code depuis `sessionStorage`
- Appel `register-and-claim` après auth Firebase
- Fallback vers `claim` si compte existe
- États: idle → claiming → success/error
- Écrans de chargement et erreur dédiés
- Bouton retour vers `/auth/claim` (pas `/auth`)

### 3.4 Modification: `client/src/App.tsx`

```typescript
import AuthClaim from "@/pages/mobile/AuthClaim";
// ...
<Route path="/auth/claim" component={withMobileContainer(AuthClaim)} />
```

---

## 4. Garde-fous implémentés

| Règle | Implémentation |
|-------|----------------|
| Claim code AVANT auth | Bouton redirige vers `/auth/claim` |
| Pas d'auth sans claim | `/auth/register` vérifie `sessionStorage` |
| Erreur si user:null | État "error" avec message explicite |
| Retour vers claim | Bouton "Réessayer avec un autre code" |

---

## 5. Tests de validation

| Scénario | Résultat attendu |
|----------|------------------|
| Clic "première fois" | → `/auth/claim` (PAS `/auth/register`) |
| Claim code valide | → `/auth/register` avec code stocké |
| Claim code invalide | Message d'erreur, reste sur claim |
| Auth sans claim code | Erreur, redirection vers claim |
| Auth avec bon email + claim | Compte créé, accès wallet |
| Auth avec mauvais email | Erreur claim, message explicite |

---

## 6. Conformité

| Critère | Status |
|---------|--------|
| Claim code TOUJOURS avant auth | ✅ |
| Bouton "première fois" → claim | ✅ |
| Aucun Firebase Auth sans claim | ✅ |
| UX alignée backend | ✅ |
| Placeholder ZDQN-97G5 | ✅ |

---

## Définition de Done

- ✅ Le claim code est TOUJOURS demandé avant l'authentification
- ✅ Le bouton "C'est ma première fois sur Koomy" mène au claim, pas à l'auth
- ✅ Aucun utilisateur ne peut atteindre Firebase Auth sans claim code
- ✅ UX alignée à 100 % avec le backend existant

**FIN DU RAPPORT**
