# KOOMY — AUTH Phase 5.2 — Google Sign-In (Web)
## Rapport Final

**Date :** 2026-01-22  
**Domain :** AUTH  
**Doc Type :** REPORT  
**Scope :** Frontend uniquement + réutilisation httpClient Bearer token  
**Status :** COMPLETED

---

## Objectif

Ajouter dans l'UI admin (login + signup) un bouton "Continuer avec Google" via Firebase Auth, puis vérifier que `/api/auth/me` renvoie 200 avec le Bearer token Firebase.

---

## Fichiers modifiés

| Fichier | Modifications |
|---------|---------------|
| `client/src/lib/firebase.ts` | Ajout GoogleAuthProvider, signInWithGoogle(), handleGoogleRedirectResult() |
| `client/src/pages/admin/Login.tsx` | Import fonctions Google, useEffect redirect, bouton "Continuer avec Google" |
| `client/src/pages/admin/Register.tsx` | Import fonctions Google, useEffect redirect, bouton "Continuer avec Google" |

---

## Implémentation

### A) Firebase Provider Google

Dans `client/src/lib/firebase.ts` :

```typescript
import { 
  signInWithPopup,
  signInWithRedirect,
  getRedirectResult,
  GoogleAuthProvider,
  ...
} from "firebase/auth";

export async function signInWithGoogle(): Promise<{ user: User; token: string } | { error: string }> {
  const auth = getFirebaseAuth();
  if (!auth) {
    return { error: "Firebase not initialized" };
  }
  
  const provider = new GoogleAuthProvider();
  provider.addScope('email');
  provider.addScope('profile');
  
  try {
    const credential = await signInWithPopup(auth, provider);
    const token = await firebaseGetIdToken(credential.user, true);
    console.info("[AUTH] Google sign-in (popup) successful");
    return { user: credential.user, token };
  } catch (error: any) {
    // Fallback to redirect if popup blocked
    if (error?.code === 'auth/popup-blocked' || error?.code === 'auth/popup-closed-by-user') {
      await signInWithRedirect(auth, provider);
      return { error: "redirect_initiated" };
    }
    // Handle other errors...
  }
}

export async function handleGoogleRedirectResult(): Promise<{ user: User; token: string } | null> {
  // Handle return from redirect flow
}
```

### B) UI Login

Sur `/admin/login` :
- Bouton "Continuer avec Google" après le formulaire email/password
- Séparateur visuel "ou"
- Gestion du redirect au retour via useEffect

### C) UI Register

Sur `/admin/register` (étape 1) :
- Bouton "Continuer avec Google" après le bouton "Continuer"
- Séparateur visuel "ou"
- Si compte existant → dashboard
- Si nouveau compte → passage à l'étape 2 (création communauté)

---

## Flux d'authentification

### Login avec Google

```
1. Utilisateur clique "Continuer avec Google"
2. signInWithGoogle() → popup Google
   - Si popup bloquée → signInWithRedirect()
3. Firebase renvoie un token
4. httpClient ajoute automatiquement Bearer token
5. GET /api/auth/me
   - Si user existant → dashboard
   - Si pas de membership → redirect vers register
```

### Register avec Google

```
1. Utilisateur clique "Continuer avec Google"
2. signInWithGoogle() → popup Google
3. GET /api/auth/me
   - Si user avec membership → dashboard
   - Si user sans membership → étape 2 (créer communauté)
   - Si nouveau user → étape 2 (créer communauté)
```

---

## Mode utilisé

- **Par défaut :** `signInWithPopup()` (popup)
- **Fallback :** `signInWithRedirect()` si popup bloquée
- **Retour redirect :** géré par `handleGoogleRedirectResult()` dans useEffect

---

## Sécurité

### Règles respectées

- [x] Sandbox first (pas de prod)
- [x] Zéro log de secrets (token, email)
- [x] Zéro endpoint debug public
- [x] Réutilisation httpClient (Bearer auto)
- [x] UX minimale (pas de redesign)

### Notes

- Les tokens Firebase ne sont jamais loggés
- Les erreurs Firebase sont traduites en messages utilisateur
- Le fallback redirect assure le fonctionnement sur navigateurs restrictifs

---

## data-testid ajoutés

| Page | Element | data-testid |
|------|---------|-------------|
| Login | Bouton Google | `button-google-signin` |
| Register | Bouton Google | `button-google-signup` |

---

## Tests requis

| Test | Résultat attendu |
|------|------------------|
| Google login OK (popup) | `/api/auth/me` = 200 (firebase.uid présent) |
| Popup bloquée → redirect | `/api/auth/me` = 200 après retour |
| Sans login | `/api/auth/me` = 401 missing_token |

---

## Prochaines étapes

- Phase 6 : RBAC guards sur routes WRITE
- Phase 7 : Firebase Auth mobile (iOS/Android)
