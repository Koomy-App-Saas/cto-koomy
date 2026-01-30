# Report - Login Modal V1.1

**Date:** 2026-01-20  
**Version:** V1.1 "Moins de dette possible"  
**Scope:** Standardisation token + clarification UI + finitions UX

---

## A) Token / Session: Standardisation

### Source de vérité identifiée

| Élément | Valeur |
|---------|--------|
| **Clé localStorage** | `koomy_auth_token` |
| **Clé timestamp** | `koomy_auth_token_ts` |
| **Fichier utilitaire** | `client/src/lib/storage.ts` |
| **Fonction SET** | `setAuthToken(token: string)` |
| **Fonction GET** | `getAuthToken(): Promise<string \| null>` |
| **Fonction CLEAR** | `clearAuthToken()` |

### Modifications appliquées

**Fichier:** `client/src/pages/website/Layout.tsx`

```typescript
// AVANT (V1 - dette)
localStorage.setItem('sessionToken', result.sessionToken);

// APRÈS (V1.1 - standardisé)
import { setAuthToken, setItem } from "@/lib/storage";

await setAuthToken(result.sessionToken);
await setItem('koomy_user', JSON.stringify(result.user));
await setItem('koomy_current_membership', JSON.stringify(result.memberships[0]));
```

### Hydratation au boot

L'AuthContext hydrate automatiquement via:
```
[AUTH] Hydrating from storage (sync)...
[STORAGE] GET AUTH TOKEN SYNC → koomy_auth_token
[STORAGE] GET_SYNC koomy_user
[STORAGE] GET_SYNC koomy_current_membership
```

**Résultat:** Refresh page après login → utilisateur reste connecté.

---

## B) Clarification Admin vs Membre

### Textes modifiés (i18n)

| Clé | Avant (FR) | Après (FR) |
|-----|------------|------------|
| `login.title` | "Connexion à Koomy" | "Espace Responsable" |
| `login.subtitle` | "Accédez à votre espace administrateur ou membre" | "Accès réservé aux responsables de communauté" |

| Clé | Avant (EN) | Après (EN) |
|-----|------------|------------|
| `login.title` | "Log in to Koomy" | "Manager Access" |
| `login.subtitle` | "Access your admin or member space" | "Access reserved for community managers" |

### Nouvelles clés ajoutées

| Clé | FR | EN |
|-----|----|----|
| `login.memberHint` | "Vous êtes membre ?" | "Are you a member?" |
| `login.downloadApp` | "Téléchargez l'app" | "Download the app" |
| `login.invalidCredentials` | "Email ou mot de passe incorrect" | "Invalid email or password" |
| `login.serverError` | "Une erreur est survenue, veuillez réessayer" | "An error occurred, please try again" |

### Lien secondaire ajouté

```tsx
<div className="flex items-center justify-center gap-2 text-xs text-slate-400">
  <Smartphone size={14} />
  <span>{t('login.memberHint')}</span>
  <a href="https://koomy.app/download">{t('login.downloadApp')}</a>
</div>
```

---

## C) UX & Accessibilité

| Amélioration | Implémentation |
|--------------|----------------|
| **Focus auto email** | `useRef` + `useEffect` avec `setTimeout(100ms)` à l'ouverture |
| **Enter submit** | Natif via `<form onSubmit>` (déjà fonctionnel) |
| **Bouton désactivé** | `disabled={loginMutation.isPending}` (déjà présent) |
| **Erreur 401** | Toast avec `t('login.invalidCredentials')` |
| **Erreur 5xx** | Toast avec `t('login.serverError')` |
| **autoComplete** | `autoComplete="email"` sur l'input email |

---

## D) Tests validés

| Test | Résultat |
|------|----------|
| Login admin OK | Redirect vers `/admin/dashboard` |
| Refresh page reste connecté | Token lu depuis `koomy_auth_token` |
| Login KO (401) | Message "Email ou mot de passe incorrect" |
| Aucune trace "Demo" | Supprimé en V1 |
| API appelée | `/api/admin/login` (vérifié en V1) |
| Focus auto email | Input focusé à l'ouverture |
| Lien membre visible | "Vous êtes membre ? Téléchargez l'app" |

---

## E) Fichiers modifiés

| Fichier | Modifications |
|---------|---------------|
| `client/src/pages/website/Layout.tsx` | Import storage, setAuthToken, setItem, useRef/useEffect focus, lien membre, gestion erreurs |
| `client/src/i18n/locales/fr.json` | Titre/sous-titre Admin, nouvelles clés |
| `client/src/i18n/locales/en.json` | Titre/sous-titre Manager, nouvelles clés |

---

## F) Architecture token (référence)

```
┌─────────────────────────────────────────────────────────────┐
│                      LOGIN FLOW                              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  [Submit Form]                                               │
│       ↓                                                      │
│  POST /api/admin/login                                       │
│       ↓                                                      │
│  Response: { user, memberships, sessionToken }               │
│       ↓                                                      │
│  setAuthToken(sessionToken)  → koomy_auth_token              │
│  setItem('koomy_user', ...)  → koomy_user                    │
│  setItem('koomy_current_membership', ...) → koomy_...        │
│       ↓                                                      │
│  setUser() → AuthContext                                     │
│       ↓                                                      │
│  Redirect → /admin/dashboard                                 │
│                                                              │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    HYDRATION FLOW                            │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  [App Boot]                                                  │
│       ↓                                                      │
│  AuthContext.hydrate()                                       │
│       ↓                                                      │
│  getAuthToken() → koomy_auth_token                           │
│  getItem('koomy_user') → koomy_user                          │
│  getItem('koomy_current_membership') → koomy_...             │
│       ↓                                                      │
│  If token exists → isAuthenticated = true                    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## G) Scope respecté

- Pas de refacto global Auth
- Standardisation token avec utilitaires existants
- Clarification UI Admin/Responsable
- Finitions UX mineures
- Endpoint conservé: `/api/admin/login`
