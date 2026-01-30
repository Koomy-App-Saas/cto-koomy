# Plan d'exécution : Migration Firebase Auth Only

**Date**: 2026-01-24
**Statut**: EN ATTENTE DE VALIDATION
**Objectif**: Clôture définitive de l'authentification legacy

---

## 1. Inventaire des composants impactés

### Backend (server/)

| Fichier | Composant | Impact |
|---------|-----------|--------|
| `routes.ts` | `requireAuth()` function | **45 occurrences** - Remplacer par `requireFirebaseAuth` |
| `routes.ts` | `/api/admin/login` | **SUPPRIMER** - Endpoint legacy |
| `routes.ts` | `/api/admin/forgot-password` | Migrer vers Firebase reset |
| `routes.ts` | Sessions table usage | Supprimer création/vérification sessions |
| `attachAuthContext.ts` | `isFirebaseJWT()` check | Simplifier (plus de branche legacy) |
| `attachAuthContext.ts` | Legacy token log | Supprimer |
| `storage.ts` | `createPlatformSession()` | Obsolète - conserver pour cleanup |
| `storage.ts` | `revokeAllUserSessions()` | Obsolète - conserver pour cleanup |
| `guards.ts` | `requireFirebaseAuth` | **CONSERVER** - devient le seul guard |
| `guards.ts` | `requireMembership` | **CONSERVER** - déjà Firebase-only |

### Frontend (client/src/)

| Fichier | Composant | Impact |
|---------|-----------|--------|
| `pages/admin/Login.tsx` | Form email/password → `/api/admin/login` | **REFONTE** → Firebase `signInWithEmailAndPassword` |
| `pages/admin/Register.tsx` | Registration flow | Vérifier utilise Firebase |
| `contexts/AuthContext.tsx` | `legacyToken` fallback | **SUPPRIMER** fallback |
| `contexts/AuthContext.tsx` | `verifySession()` | **SUPPRIMER** - utilise legacy token |
| `lib/storage.ts` | `setAuthToken()` / `getAuthToken()` | **OBSOLÈTE** - ne plus utiliser |
| `lib/storage.ts` | `koomy_auth_token` key | **OBSOLÈTE** |
| `api/httpClient.ts` | Legacy token dispatch | **SUPPRIMER** branche legacy |
| `components/unified/UnifiedAuthLogin.tsx` | Firebase login | **CONSERVER** - modèle de référence |

### Base de données

| Table | Impact |
|-------|--------|
| `sessions` | **NE PAS SUPPRIMER** - conserver pour historique, plus créée |
| `accounts` | Champ `password` devient obsolète pour nouveaux comptes |

---

## 2. Actions à mener

### À SUPPRIMER

1. **Route `/api/admin/login`** (endpoint legacy complet)
2. **Fonction `requireAuth()`** dans routes.ts (remplacée par guards)
3. **Fonction `requireAuthWithUser()`** dans routes.ts
4. **Branche legacy** dans `httpClient.ts` (dispatch token)
5. **Fallback legacy** dans `AuthContext.tsx`
6. **Fonction `verifySession()`** dans AuthContext
7. **Branche legacy** dans `attachAuthContext.ts`
8. **Instrumentation diagnostic** (AUTH_DISPATCH, AUTH_TRACE)

### À MODIFIER

1. **`pages/admin/Login.tsx`**
   - Remplacer `apiPost('/api/admin/login')` par `signInWithEmailAndPassword(auth, email, password)`
   - Synchroniser avec backend via `/api/auth/firebase-login` existant
   - Pattern: copier logique de `UnifiedAuthLogin.tsx`

2. **45 routes utilisant `requireAuth()`**
   - Remplacer par `requireFirebaseAuth` (middleware) + `requireMembership` si besoin
   - Ou par vérification directe `req.authContext?.koomyUser?.id`

3. **`attachAuthContext.ts`**
   - Supprimer branche `else` (legacy token)
   - Supprimer log "Legacy token detected"
   - Simplifier `isFirebaseJWT()` → toujours traiter comme JWT

4. **`httpClient.ts`**
   - Supprimer `getAuthToken()` (legacy)
   - Garder uniquement `getFirebaseIdToken()`

5. **`AuthContext.tsx`**
   - Supprimer références à `legacyToken`
   - Supprimer `verifySession()`
   - `refreshMe()` utilise uniquement Firebase token

### À CONSERVER

1. **`guards.ts`** - requireFirebaseAuth, requireMembership, requireRole
2. **Firebase auth** - getFirebaseIdToken, signInWithEmailAndPassword
3. **Table `accounts`** - structure inchangée
4. **Table `sessions`** - ne plus alimenter, mais conserver données existantes

---

## 3. Ordre d'exécution recommandé

### Phase 1: Préparer le terrain (backend sécurisé)
**Risque: Faible | Validation: Tests curl**

1. ✅ Créer ce document de plan
2. Créer endpoint `/api/auth/admin-firebase-login` (nouveau, Firebase-based)
3. Tester endpoint avec curl + fake JWT
4. **Checkpoint**: Nouveau endpoint fonctionne

### Phase 2: Migrer le frontend admin login
**Risque: Moyen | Validation: Test UI sandbox**

5. Modifier `pages/admin/Login.tsx` → utiliser Firebase `signInWithEmailAndPassword`
6. Appeler `/api/auth/admin-firebase-login` après login Firebase
7. Supprimer appel à `/api/admin/login`
8. **Checkpoint**: Admin peut se connecter via Firebase sur sandbox

### Phase 3: Nettoyer les guards backend
**Risque: Élevé | Validation: Test routes protégées**

9. Créer helper `getAuthenticatedUser(req)` → retourne `req.authContext?.koomyUser?.id || null`
10. Remplacer les 45 `requireAuth()` progressivement par groupes:
    - Groupe A (10 routes critiques): news, events, sections, memberships
    - Groupe B (15 routes admin): community settings, plans, billing
    - Groupe C (20 routes autres): analytics, exports, etc.
11. Tester chaque groupe avant de passer au suivant
12. **Checkpoint**: Toutes les routes utilisent Firebase auth

### Phase 4: Nettoyer le frontend
**Risque: Moyen | Validation: Test complet UI**

13. Supprimer fallback legacy dans `AuthContext.tsx`
14. Supprimer branche legacy dans `httpClient.ts`
15. Supprimer `verifySession()`
16. **Checkpoint**: Frontend n'utilise plus de token legacy

### Phase 5: Cleanup final
**Risque: Faible | Validation: Grep codebase**

17. Supprimer `requireAuth()` et `requireAuthWithUser()` de routes.ts
18. Supprimer branche legacy dans `attachAuthContext.ts`
19. Supprimer route `/api/admin/login`
20. Supprimer instrumentation diagnostic (AUTH_DISPATCH, AUTH_TRACE)
21. Archiver documentation legacy
22. **Checkpoint**: Aucune référence legacy dans le code actif

---

## 4. Risques identifiés et mitigation

| Risque | Impact | Probabilité | Mitigation |
|--------|--------|-------------|------------|
| Admin production n'a pas de compte Firebase | BLOQUANT | Moyenne | Créer compte Firebase avant migration |
| Routes cassées après migration guards | Élevé | Moyenne | Migration par groupes + tests intermédiaires |
| Token Firebase expiré non rafraîchi | Moyen | Faible | Firebase SDK gère le refresh automatiquement |
| Perte de session après migration | Moyen | Faible | Communication claire avec admin |
| Rollback nécessaire | Moyen | Faible | Checkpoint git avant chaque phase |

### Mitigation critique: Compte Firebase admin

**AVANT Phase 2**, s'assurer que l'admin production:
1. A un compte Firebase créé avec son email
2. A un mot de passe défini (Firebase console ou flow reset)
3. A un `accounts.providerId` = Firebase UID

**Script de vérification à exécuter:**
```sql
SELECT a.id, a.email, a.providerId, a.authProvider, ucm.role
FROM accounts a
JOIN user_community_memberships ucm ON ucm.account_id = a.id
WHERE ucm.role IN ('admin', 'owner', 'super_admin');
```

---

## 5. Plan de test minimal (sandbox)

### Tests Phase 1
```bash
# Test nouvel endpoint admin Firebase login
curl -X POST http://localhost:5000/api/auth/admin-firebase-login \
  -H "Authorization: Bearer <FIREBASE_JWT>" \
  -H "Content-Type: application/json"
# Attendu: 200 + user data
```

### Tests Phase 2
- [ ] Accéder à backoffice-sandbox.koomy.app
- [ ] Se connecter avec email/password (via Firebase)
- [ ] Vérifier redirection vers dashboard
- [ ] Vérifier token Firebase dans DevTools (3 segments)

### Tests Phase 3
- [ ] Créer une section (POST /api/communities/:id/sections)
- [ ] Créer un événement (POST /api/communities/:id/events)
- [ ] Créer une actualité (POST /api/communities/:id/news)
- [ ] Modifier un membre
- [ ] Toutes actions admin courantes

### Tests Phase 4
- [ ] Refresh page → session maintenue
- [ ] Logout → session détruite
- [ ] Login après logout → fonctionne

### Tests Phase 5
```bash
# Vérifier aucune référence legacy
grep -r "requireAuth\(" server/ --include="*.ts" | wc -l
# Attendu: 0

grep -r "legacyToken\|getAuthToken" client/src/ --include="*.ts" --include="*.tsx" | wc -l
# Attendu: 0 (ou seulement storage.ts obsolète)
```

---

## 6. Critères de succès

- [ ] Admin peut se connecter sur backoffice-sandbox via Firebase
- [ ] Toutes les actions admin (CRUD sections, events, news, members) fonctionnent
- [ ] Aucun appel à `/api/admin/login` dans le code
- [ ] Aucun usage de `requireAuth()` dans routes.ts
- [ ] Aucun legacy token dispatché par httpClient
- [ ] Tests manuels passent sur sandbox
- [ ] Logs ne montrent plus "Legacy token detected"

---

## 7. Estimation de temps

| Phase | Durée estimée |
|-------|---------------|
| Phase 1 | 30 min |
| Phase 2 | 1h |
| Phase 3 | 2h (45 routes) |
| Phase 4 | 45 min |
| Phase 5 | 30 min |
| **Total** | **~5h** |

---

## 8. Go/No-Go Checklist

Avant de commencer l'exécution:

- [ ] Plan validé par l'équipe
- [ ] Admin production a un compte Firebase fonctionnel
- [ ] Checkpoint git créé
- [ ] Accès sandbox vérifié
- [ ] Pas de déploiement prod prévu pendant migration

---

**Fin du plan — En attente de validation**
