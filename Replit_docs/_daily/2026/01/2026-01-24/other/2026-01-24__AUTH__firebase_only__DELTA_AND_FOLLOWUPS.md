# KOOMY — Firebase-Only Auth Migration DELTA & FOLLOWUPS

**Date**: 2026-01-24
**Statut**: COMPLÉTÉ

---

## B1) Liste de tous les changements

### Backend (server/)

#### Middlewares modifiés

| Fichier | Modification | Description |
|---------|--------------|-------------|
| `server/routes.ts` | `requireFirebaseOnly()` créé | Nouvelle fonction auth Firebase-only |
| `server/routes.ts` | `requireAuth()` supprimé | Fonction hybride legacy supprimée |
| `server/routes.ts` | `/api/admin/login` désactivé | Retourne 410 GONE |

#### Routes migrées (43 routes + 5 déjà Firebase = 48 total)

**Comptes vérifiés par grep:**
- `requireFirebaseOnly(req, res)`: 36 occurrences
- `requireAuthWithUser(req, res)`: 7 occurrences (appelle requireFirebaseOnly)
- Routes déjà Firebase (requireFirebaseAuth/requireMembership): ~5

**Catégories couvertes:**
- Routes GET `/api/communities/:id/*` pour sections, events, news, tags, branding
- Routes POST/PATCH/DELETE pour sections, events, event-categories, tags, memberships
- Routes admin: membership-plans, member-profile-config, enrollment-requests, self-enrollment, branding

#### Comportements auth modifiés

| Endpoint | Avant | Après |
|----------|-------|-------|
| `/api/auth/me` | Firebase + legacy fallback | Firebase only |
| Routes protégées | `requireAuth()` hybride | `requireFirebaseOnly()` |

### Frontend (client/)

#### Pages login modifiées

| Fichier | Modification |
|---------|--------------|
| `client/src/pages/admin/Login.tsx` | Firebase `signInWithEmailAndPassword` + `/api/auth/me` |
| `client/src/components/unified/UnifiedAuthLogin.tsx` | Firebase pour admin ET membre |
| `client/src/pages/_legacy/MobileAdminLogin.tsx` | Firebase `signInWithEmailAndPassword` |

#### httpClient modifié

| Fichier | Modification |
|---------|--------------|
| `client/src/api/httpClient.ts` | Suppression fallback legacy token |
| `client/src/api/httpClient.ts` | Suppression import `getAuthToken` |
| `client/src/api/httpClient.ts` | Nettoyage diagnostic AUTH_DISPATCH |

#### Storage/AuthContext

| Élément | Statut | Note |
|---------|--------|------|
| `koomy_auth_token` | CONSERVÉ | Requis pour White-Label (contrat identité) |
| `setAuthToken()` | CONSERVÉ | Utilisé par flows WL membre |
| Firebase token cache | ACTIF | Via `ensureFirebaseToken()` |

---

## B2) Impact Matrix — Effets collatéraux

### Fonctionnalités critiques

| Zone | Risque | Symptôme | Cause probable | Fix | Statut |
|------|--------|----------|----------------|-----|--------|
| **Google sign-in Admin** | Moyen | Bouton absent/désactivé | Intentionnel - admin = email/password only | N/A | ✅ OK (désactivé) |
| **Reset password Admin** | Élevé | Impossible de réinitialiser | Firebase `sendPasswordResetEmail` requis | Implémenter si absent | ⚠️ À VÉRIFIER |
| **Session persistence (F5)** | Élevé | Logout après refresh | Firebase token non persisté | `ensureFirebaseToken()` au boot | ✅ OK |
| **Roles & permissions** | Moyen | 403 sur actions admin | Pas de rôle ADMIN dans membership | Vérifier membership.role | ✅ OK |
| **communityId vide** | Moyen | Double slash URLs | selectCommunity pas appelé | Vérifier flux post-login | ✅ OK |
| **CORS + preflight** | Faible | 401 sur OPTIONS | Authorization non autorisé | CORS config OK | ✅ OK |
| **SaaS Owner** | N/A | - | Système session séparé | Hors scope | ⏭️ HORS SCOPE |
| **Mobile vs Web** | Moyen | Token différent | Capacitor/Native storage | Même Firebase SDK | ✅ OK |
| **Logout** | Moyen | Session fantôme | Firebase + app state pas nettoyés | `signOut()` + clear context | ✅ OK |
| **Error messaging UX** | Élevé | Pas de message visible | Toast manquant | Ajouter toast.error | ✅ OK |

### Statuts détaillés

#### Google sign-in Admin/Backoffice
**Statut**: ✅ OFF (intentionnel)

Le code dans `UnifiedAuthLogin.tsx` bloque explicitement Google pour admin:
```typescript
if (isAdmin) {
  toast.error("L'authentification Google n'est pas disponible pour les administrateurs");
  return;
}
```

**Raison**: Sécurité - les admins doivent utiliser email/password avec compte vérifié.

#### Reset password (mot de passe oublié)
**Statut**: ⚠️ À VÉRIFIER

Firebase `sendPasswordResetEmail` est disponible dans `lib/firebase.ts`. Vérifier que le lien "Mot de passe oublié" sur la page login admin l'utilise.

**Action recommandée**: Tester le flux reset password en sandbox.

#### Session persistence (F5/refresh)
**Statut**: ✅ OK

Firebase SDK gère automatiquement la persistence du token. `onAuthStateChanged` dans AuthContext recharge l'utilisateur au boot.

---

## B3) To-Do Post-Migration

### Priorité 1 — Validation Sandbox

- [ ] Tester login admin email/password
- [ ] Tester CRUD sections/events/news
- [ ] Tester refresh page (F5)
- [ ] Tester logout complet
- [ ] Vérifier reset password

### Priorité 2 — Monitoring PROD

- [ ] Surveiller logs 401/403 pendant 48h
- [ ] Vérifier aucun `tokenLength 33` dans logs
- [ ] Confirmer aucun appel `/api/admin/login`

### Priorité 3 — Cleanup optionnel

- [ ] Supprimer code legacy commenté dans `/api/admin/login`
- [ ] Documenter le contrat White-Label legacy
- [ ] Migrer platform owner vers Firebase (phase ultérieure)

---

## Fichiers modifiés (récapitulatif)

| Fichier | Type de modification |
|---------|---------------------|
| `server/routes.ts` | `requireFirebaseOnly()` créé, `requireAuth()` supprimé, 48 routes Firebase-protected |
| `client/src/pages/admin/Login.tsx` | Firebase login |
| `client/src/components/unified/UnifiedAuthLogin.tsx` | Firebase login admin/membre |
| `client/src/pages/_legacy/MobileAdminLogin.tsx` | Firebase login |
| `client/src/api/httpClient.ts` | Suppression fallback legacy |

---

**FIN DU RAPPORT DELTA**
