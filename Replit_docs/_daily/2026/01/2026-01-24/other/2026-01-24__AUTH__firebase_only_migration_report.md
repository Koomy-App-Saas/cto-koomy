# KOOMY — Firebase-Only Auth Migration Report

**Date**: 2026-01-24
**Statut**: COMPLÉTÉ - PRÊT POUR VALIDATION SANDBOX
**Objectif**: Clôture de la bipolarité authentification (legacy vs Firebase)

---

## 1. Résumé Exécutif

La migration vers une authentification 100% Firebase a été réalisée avec succès. Tous les flux admin/backoffice utilisent désormais exclusivement Firebase Authentication.

### Changements majeurs

| Composant | Avant | Après |
|-----------|-------|-------|
| Admin Login | `/api/admin/login` → sessionToken legacy | Firebase `signInWithEmailAndPassword` |
| Token dispatch | Firebase + legacy fallback | Firebase uniquement |
| Backend auth | `requireAuth()` (hybride) | `requireFirebaseOnly()` |
| Password reset | API endpoint | Firebase `sendPasswordResetEmail` |

---

## 2. Fichiers Modifiés

### Frontend

| Fichier | Modifications |
|---------|---------------|
| `client/src/pages/admin/Login.tsx` | Login via Firebase SDK, suppression `setAuthToken` |
| `client/src/api/httpClient.ts` | Suppression fallback legacy, nettoyage diagnostic |

### Backend

| Fichier | Modifications |
|---------|---------------|
| `server/routes.ts` | Création `requireFirebaseOnly()`, migration 35+ routes, suppression `requireAuth()` |

---

## 3. Routes Migrées

35 occurrences de `requireAuth(req, res)` et `requireAuth(req, res)` ont été remplacées par `requireFirebaseOnly(req, res)`.

### Catégories de routes migrées

#### Groupe A — Lecture (GET)
- `/api/communities/:id/subscription-state`
- `/api/communities/:id/suspended-members-count`
- `/api/communities/:id/sections`
- `/api/communities/:id/events`
- `/api/communities/:id/event-categories`
- `/api/communities/:id/news`
- `/api/communities/:id/tags`
- `/api/communities/:id/branding`

#### Groupe B — Écriture (POST/PUT/PATCH/DELETE)
- `/api/memberships` (POST)
- `/api/memberships/:id/regenerate-code`
- `/api/memberships/:id/resend-claim`
- `/api/communities/:id/sections` (POST/PATCH/DELETE)
- `/api/communities/:id/event-categories` (POST/PATCH/DELETE)
- `/api/communities/:id/events` (POST/PATCH/DELETE)
- `/api/communities/:id/tags` (POST)
- `/api/communities/:id/news` (déjà Firebase)

#### Groupe C — Admin/Settings
- `/api/communities/:communityId/admins` (POST)
- `/api/membership-plans/:id` (PATCH/DELETE)
- `/api/communities/:id/branding` (PATCH)
- Et autres routes admin...

---

## 4. Nouvelle Architecture Auth

### Header unique
```
Authorization: Bearer <Firebase ID Token JWT>
```

### Middleware backend
```typescript
function requireFirebaseOnly(req, res): AuthResult | null {
  if (req.authContext?.koomyUser?.id) {
    return {
      accountId: req.authContext.koomyUser.id,
      authType: "firebase"
    };
  }
  res.status(401).json({ 
    error: "auth_required", 
    code: "FIREBASE_AUTH_REQUIRED"
  });
  return null;
}
```

### Flux Frontend
```
User → signInWithEmailAndPassword(email, password)
     → Firebase Auth → JWT Token
     → /api/auth/me → User data + Memberships
     → Redirect dashboard
```

---

## 5. Éléments Supprimés

### Code supprimé ou désactivé

| Élément | Fichier | Raison |
|---------|---------|--------|
| `requireAuth()` fonction | routes.ts | Remplacée par `requireFirebaseOnly` |
| `getAuthToken` import | httpClient.ts | Plus de legacy token |
| AUTH_DISPATCH instrumentation | httpClient.ts | Diagnostic terminé |
| `setAuthToken` import | Login.tsx | Plus de legacy token |
| Fallback legacy | httpClient.ts | Firebase uniquement |
| `/api/admin/login` endpoint | routes.ts | Désactivé avec HTTP 410 GONE |

### Endpoints conservés (non modifiés)

- `/api/platform/*` — Système session platform (SaaS Owner)
- `/api/owner/*` — Templates email
- `/api/webhooks/stripe` — Signature Stripe
- `/api/internal/cron/*` — CRON_SECRET

---

## 6. Tests Exécutés

### Tests automatisés (LSP)
- ✅ Aucune erreur LSP liée aux modifications auth
- ⚠️ 20 erreurs préexistantes dans routes.ts (non liées à l'auth)

### Tests manuels requis (sandbox)

| Test | Description | Statut |
|------|-------------|--------|
| Admin login email/password | Connexion backoffice | À valider |
| CRUD sections | Créer/modifier/supprimer section | À valider |
| CRUD events | Créer/modifier/supprimer événement | À valider |
| CRUD news | Créer/modifier/supprimer actualité | À valider |
| Refresh page (F5) | Session maintenue | À valider |
| Logout/login | Cycle complet | À valider |

---

## 7. Risques & Limites

### Risques identifiés

| Risque | Mitigation |
|--------|------------|
| Admin sans compte Firebase | Vérifier `provider_id` en base avant usage |
| Token expiré | Firebase SDK gère le refresh automatique |
| Rollback nécessaire | Git revert + Railway rollback |

### Limites

1. **Platform owner routes** restent sur le système de session legacy (non Firebase)
2. **Mobile natif** doit utiliser Firebase SDK pour s'authentifier

---

## 8. Runbook Rollback

### Option A — Git Revert
```bash
git revert HEAD~4..HEAD
git push
```

### Option B — Railway UI
1. Ouvrir Railway Dashboard
2. Aller dans Deployments
3. Cliquer "Rollback" sur le déploiement précédent

### Durée estimée rollback: 5 minutes

---

## 9. Checklist Post-Déploiement (PROD)

- [ ] Admin peut se connecter via Firebase
- [ ] Créer section test → 200 OK
- [ ] Créer event test → 200 OK  
- [ ] Créer news test → 200 OK
- [ ] Logs sans "Legacy token detected"
- [ ] Aucun 401/403 sur actions admin

---

## 10. Prochaines Étapes

1. **Validation sandbox** — Tester manuellement tous les flux admin
2. **Communication admin** — Informer de la migration auth
3. **Déploiement PROD** — Après validation sandbox
4. **Monitoring** — Surveiller les logs 401/403 pendant 48h
5. **Cleanup final** — Supprimer code mort restant

---

**Fin du rapport**
