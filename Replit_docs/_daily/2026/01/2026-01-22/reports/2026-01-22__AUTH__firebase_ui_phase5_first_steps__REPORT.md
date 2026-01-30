# KOOMY — AUTH
## Phase 5 — Firebase UI (First Steps) — Sandbox Only

**Date :** 2026-01-22  
**Domain :** AUTH  
**Doc Type :** REPORT  
**Scope :** Frontend (Replit sandbox) + intégration token vers API  
**Environment :** SANDBOX UNIQUEMENT

---

## Résumé Exécutif

Cette phase connecte Firebase Auth côté UI en sandbox. Le login admin utilise maintenant Firebase signInWithEmailAndPassword, et les appels API incluent automatiquement le Bearer token Firebase.

---

## Fichiers Modifiés

| Fichier | Modification |
|---------|--------------|
| `client/src/lib/firebase.ts` | Ajout helpers: signInWithEmailAndPassword, signOutFirebase, sendPasswordResetEmail, getCurrentUser, onAuthStateChange |
| `client/src/api/httpClient.ts` | Ajout Bearer token Firebase automatique dans header Authorization |
| `client/src/pages/admin/Login.tsx` | Login via Firebase + fallback legacy, bouton "Mot de passe oublié" fonctionnel |

---

## A) Variables FRONT

Le code lit les variables d'environnement Vite suivantes :

```typescript
import.meta.env.VITE_FIREBASE_API_KEY
import.meta.env.VITE_FIREBASE_AUTH_DOMAIN
import.meta.env.VITE_FIREBASE_PROJECT_ID
import.meta.env.VITE_FIREBASE_STORAGE_BUCKET
import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID
import.meta.env.VITE_FIREBASE_APP_ID
```

**Note :** Aucun secret n'est loggé. Seul `projectId` est affiché dans les logs d'initialisation (sans apiKey).

---

## B) Client Firebase (firebase.ts)

### Exports ajoutés

| Fonction | Description |
|----------|-------------|
| `signInWithEmailAndPassword(email, password)` | Login Firebase, retourne `{ user, token }` ou `{ error }` |
| `signOutFirebase()` | Déconnexion Firebase |
| `sendPasswordResetEmail(email)` | Envoi email reset, retourne `{ success }` ou `{ success: false, error }` |
| `getCurrentUser()` | Retourne l'utilisateur Firebase courant (sync) |
| `onAuthStateChange(callback)` | Subscribe aux changements d'état auth |
| `getFirebaseIdToken(forceRefresh?)` | Récupère le token ID (existant) |

### Sécurité

- Email, password, token ne sont JAMAIS loggés
- Seuls les codes d'erreur Firebase sont loggés (ex: `auth/wrong-password`)

---

## C) API Client signé (httpClient.ts)

### Modification

```typescript
// Get Firebase ID token for authenticated requests (SECURITY: never log token)
const firebaseToken = await getFirebaseIdToken();

const headers = {
  ...
  // Add Firebase Bearer token if user is authenticated
  ...(firebaseToken ? { 'Authorization': `Bearer ${firebaseToken}` } : {}),
  ...
};
```

### Comportement

- Si utilisateur Firebase connecté → header `Authorization: Bearer <token>` ajouté
- Si pas connecté → pas de header Authorization
- Token JAMAIS loggé

---

## D) UI Login Admin (Login.tsx)

### Flow de connexion

1. Utilisateur entre email/password
2. Appel `signInWithEmailAndPassword()` Firebase
3. Si Firebase OK → appel `/api/auth/me` avec Bearer token
4. Si `/api/auth/me` OK → session Koomy établie
5. Si `/api/auth/me` échoue → fallback vers legacy `/api/admin/login`

### Reset Password

- Bouton "Mot de passe oublié ?" appelle `sendPasswordResetEmail()`
- Feedback utilisateur via toast

---

## E) Test Final (/api/auth/me)

### Endpoint backend (déjà existant)

```
GET /api/auth/me
Authorization: Bearer <FirebaseIdToken>
```

### Action UI Sandbox-Only

Sur la page de login admin (`/admin/login`), un bouton de test "Test /api/auth/me" est visible uniquement en environnement sandbox (hostname contient `sandbox`, `localhost`, ou `replit`).

Ce bouton appelle `/api/auth/me` et affiche le résultat :
- Sans login Firebase → `Status: 401 - FAIL` (expected: missing_token)
- Avec login Firebase → `Status: 200 - OK` (avec user et memberships)

### Réponses attendues

| Scénario | Code | Body |
|----------|------|------|
| Sans token | 401 | `{ error: "missing_token" }` |
| Token invalide | 401 | `{ error: "invalid_token" }` |
| Token valide, pas de compte Koomy | 200 | `{ firebase: {...}, user: null, memberships: [] }` |
| Token valide, compte Koomy existant | 200 | `{ firebase: {...}, user: {...}, memberships: [...] }` |

### Backfill firebase_uid

Si le compte existe par email mais n'a pas de `firebase_uid`, le backend le backfill automatiquement lors du premier login Firebase réussi.

---

## Sécurité

### Règles respectées

- [x] Sandbox uniquement (pas de migration prod)
- [x] Zéro route debug publique
- [x] Zéro log de secrets (email, password, token, Authorization header)
- [x] Aucun changement produit hors AUTH

### Sanitisation des logs

Le header `Authorization` est remplacé par `[REDACTED]` dans les logs de requêtes :

```typescript
// SECURITY: Sanitize headers for logging - never log Authorization token
const sanitizedHeaders = { ...headers };
if (sanitizedHeaders.Authorization) {
  sanitizedHeaders.Authorization = '[REDACTED]';
}
```

### Notes

- Le token Firebase est obtenu via `getFirebaseIdToken()` et n'est jamais loggé
- Les erreurs Firebase sont traduites en messages utilisateur lisibles
- Le fallback legacy assure la continuité de service

---

## Prochaines étapes (Phase 6)

1. Intégration logout dans le menu profil
2. Protection des routes admin côté frontend
3. Synchronisation état Firebase ↔ AuthContext
4. Tests E2E complets
