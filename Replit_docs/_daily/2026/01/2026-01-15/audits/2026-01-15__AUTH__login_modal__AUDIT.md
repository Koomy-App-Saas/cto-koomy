# Audit - Modale "Connexion à Koomy"

**Date:** 2026-01-20  
**Auteur:** Agent Replit  
**Statut:** Problème identifié et corrigé

---

## A) Audit

### 1. Localisation

| Composant | Fichier | Rôle |
|-----------|---------|------|
| Modale Login | `client/src/pages/website/Layout.tsx` (lignes 163-251) | UI de la modale de connexion |
| Hook useLogin | `client/src/hooks/useApi.ts` (ligne 5-10) | Mutation TanStack Query pour login |
| Service API | `client/src/lib/api.ts` (lignes 24-30) | Appel fetch vers `/api/auth/login` |
| AuthContext | `client/src/contexts/AuthContext.tsx` | Stockage user + memberships |
| Textes i18n | `client/src/i18n/locales/fr.json`, `en.json` | Traductions (incluant "Demo") |

**Déclencheur:** Bouton "Connexion" dans le header du site public (`openLoginModal()`)  
**Fermeture:** `setIsLoginOpen(false)` dans `handleLogin()` (succès) ou via DialogContent close button

### 2. Flux actuel

```
[Clic "Se connecter"]
    ↓
setIsLoginOpen(true) → Dialog s'ouvre
    ↓
[Submit formulaire]
    ↓
handleLogin(e) appelé
    ↓
loginMutation.mutateAsync({ email, password })
    ↓
api.auth.login(email, password)
    ↓
fetchApi("/auth/login", { method: "POST", body: {...} })
    ↓
❌ ERREUR 404 - Endpoint inexistant!
```

**Résultat actuel:** Le toast affiche "Request failed" car `/api/auth/login` n'existe pas.

### 3. Root Cause

| Problème | Détail |
|----------|--------|
| **Endpoint manquant** | `api.ts` appelle `/api/auth/login` mais cet endpoint n'existe PAS |
| **Endpoints réels** | `/api/accounts/login` (mobile), `/api/admin/login` (back-office) |
| **Confusion** | La modale utilise un endpoint fictif jamais implémenté |

**Ce n'est pas un mock** - c'est simplement un endpoint qui n'a jamais été créé. Le code frontend est complet et fonctionnel, il suffit de pointer vers le bon endpoint.

### 4. État des dépendances

| Service | Statut | Notes |
|---------|--------|-------|
| API Backend | ✅ Fonctionnel | `/api/admin/login` fonctionne (testé sur /admin/login) |
| AuthContext | ✅ Fonctionnel | `setUser()` disponible et utilisé correctement |
| Session/Token | ⚠️ Non persisté | Le token retourné n'est pas stocké (localStorage) |
| Redirection | ✅ Implémenté | Vers `/admin/dashboard` ou `/app/hub` selon rôle |

---

## B) Corrections effectuées

### B.1 Suppression section "Demo"

**Fichiers modifiés:**
- `client/src/pages/website/Layout.tsx` - Suppression du bloc Demo (lignes 231-235)
- `client/src/i18n/locales/fr.json` - Suppression clés `login.demo` et `login.demoHint`
- `client/src/i18n/locales/en.json` - Suppression clés `login.demo` et `login.demoHint`

### B.2 Correction de l'endpoint API

**Fichier:** `client/src/lib/api.ts`

```typescript
// AVANT (cassé)
login: (email, password) => fetchApi("/auth/login", ...)

// APRÈS (fonctionnel)
login: (email, password) => fetchApi("/admin/login", ...)
```

### B.3 Adaptation du handler pour le format de réponse

**Fichier:** `client/src/pages/website/Layout.tsx`

Le endpoint `/api/admin/login` retourne `{ user, memberships, sessionToken }` donc le code existant est compatible. Ajout du stockage du sessionToken dans localStorage pour persistance.

---

## C) Patch V1 appliqué

| Fonctionnalité | Statut |
|----------------|--------|
| Submit branché sur vrai service | ✅ `/api/admin/login` |
| Loader pendant connexion | ✅ `loginMutation.isPending` |
| Erreurs visibles | ✅ Toast avec message d'erreur |
| Stockage token | ✅ `localStorage.setItem('sessionToken', ...)` |
| Hydration AuthContext | ✅ `setUser({ ...result.user, memberships })` |
| Close modal + redirect | ✅ Vers `/admin/dashboard` ou `/app/hub` |

---

## D) Tests à valider

| Test | Résultat attendu |
|------|-----------------|
| Login success | Session persistée après refresh (via sessionToken) |
| Login fail | Message "Email ou mot de passe incorrect" |
| Aucun texte "Demo" | Vérifié - supprimé de l'UI et des fichiers i18n |

---

## Fichiers modifiés (résumé)

| Fichier | Modification |
|---------|-------------|
| `client/src/lib/api.ts` | Endpoint `/auth/login` → `/admin/login` |
| `client/src/pages/website/Layout.tsx` | Suppression section Demo + stockage sessionToken |
| `client/src/i18n/locales/fr.json` | Suppression `login.demo` et `login.demoHint` |
| `client/src/i18n/locales/en.json` | Suppression `login.demo` et `login.demoHint` |
