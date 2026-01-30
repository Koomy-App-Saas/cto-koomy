# AUTH FLOWS — PREUVES

**Date**: 2026-01-24  
**Environnement**: backoffice-sandbox.koomy.app

---

## 1. LOGIN EMAIL/PASSWORD

### Test case

| Étape | Action | Attendu | Observé | Status |
|-------|--------|---------|---------|--------|
| 1 | Ouvrir /admin/login | Page login affichée | ⬜ | ⬜ |
| 2 | Saisir email valide | Champ rempli | ⬜ | ⬜ |
| 3 | Saisir mot de passe valide | Champ rempli | ⬜ | ⬜ |
| 4 | Click "Se connecter" | Spinner, puis redirect | ⬜ | ⬜ |
| 5 | Dashboard affiché | Données du club visibles | ⬜ | ⬜ |

### Console attendue

```
[AUTH] Firebase sign-in successful
[AUTH] Firebase initialized
```

### Network attendu

```
POST /api/auth/me → 200 OK
GET /api/communities/{id}/dashboard → 200 OK
```

---

## 2. F5 REFRESH (SESSION PERSISTENCE)

### Test case

| Étape | Action | Attendu | Observé | Status |
|-------|--------|---------|---------|--------|
| 1 | Être sur Dashboard (connecté) | Dashboard visible | ⬜ | ⬜ |
| 2 | Appuyer F5 | Page recharge | ⬜ | ⬜ |
| 3 | Attendre chargement | Reste sur Dashboard | ⬜ | ⬜ |
| 4 | Données toujours visibles | Pas de redirect login | ⬜ | ⬜ |

### Console attendue

```
[AUTH] Firebase initialized
[AUTH] Token refreshed successfully
```

---

## 3. LOGOUT

### Test case

| Étape | Action | Attendu | Observé | Status |
|-------|--------|---------|---------|--------|
| 1 | Click menu utilisateur | Menu ouvert | ⬜ | ⬜ |
| 2 | Click "Se déconnecter" | Processing | ⬜ | ⬜ |
| 3 | Redirect vers /admin/login | Page login affichée | ⬜ | ⬜ |
| 4 | Tenter accès Dashboard | Reste sur login | ⬜ | ⬜ |

### Console attendue

```
[AUTH] Firebase sign-out successful
```

---

## 4. LOGIN MAUVAIS MOT DE PASSE

### Test case

| Étape | Action | Attendu | Observé | Status |
|-------|--------|---------|---------|--------|
| 1 | Saisir email valide | OK | ⬜ | ⬜ |
| 2 | Saisir mauvais mdp | OK | ⬜ | ⬜ |
| 3 | Click "Se connecter" | Processing | ⬜ | ⬜ |
| 4 | Toast erreur visible | "Mot de passe incorrect" | ⬜ | ⬜ |
| 5 | Reste sur page login | Pas de redirect | ⬜ | ⬜ |

### Console attendue

```
[AUTH] Firebase sign-in failed: auth/wrong-password
```

### Code proof (`client/src/lib/firebase.ts:226`)

```typescript
"auth/wrong-password": "Mot de passe incorrect",
```

---

## 5. LOGIN COMPTE INEXISTANT

### Test case

| Étape | Action | Attendu | Observé | Status |
|-------|--------|---------|---------|--------|
| 1 | Saisir email inexistant | OK | ⬜ | ⬜ |
| 2 | Saisir un mdp | OK | ⬜ | ⬜ |
| 3 | Click "Se connecter" | Processing | ⬜ | ⬜ |
| 4 | Toast erreur visible | "Aucun compte associé à cet email" | ⬜ | ⬜ |

### Console attendue

```
[AUTH] Firebase sign-in failed: auth/user-not-found
```

### Code proof (`client/src/lib/firebase.ts:225`)

```typescript
"auth/user-not-found": "Aucun compte associé à cet email",
```

---

## 6. RÉSUMÉ MAPPING ERREURS FIREBASE

| Code Firebase | Message FR | Fichier:Ligne | Status |
|---------------|------------|---------------|--------|
| `auth/wrong-password` | "Mot de passe incorrect" | firebase.ts:226 | ✅ PROUVÉ |
| `auth/user-not-found` | "Aucun compte associé à cet email" | firebase.ts:225 | ✅ PROUVÉ |
| `auth/invalid-email` | "Adresse email invalide" | firebase.ts:223 | ✅ PROUVÉ |
| `auth/invalid-credential` | "Email ou mot de passe incorrect" | firebase.ts:227 | ✅ PROUVÉ |
| `auth/too-many-requests` | "Trop de tentatives..." | firebase.ts:228 | ✅ PROUVÉ |
| `auth/user-disabled` | "Ce compte a été désactivé" | firebase.ts:224 | ✅ PROUVÉ |
| `auth/email-already-in-use` | "Cette adresse email est déjà utilisée" | firebase.ts:255 | ✅ PROUVÉ |
| `auth/weak-password` | "Le mot de passe est trop faible" | firebase.ts:258 | ✅ PROUVÉ |

---

**FIN AUTH_FLOWS**
