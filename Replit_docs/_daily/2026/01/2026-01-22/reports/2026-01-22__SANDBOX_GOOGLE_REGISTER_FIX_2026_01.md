# Rapport: Fix Google Register - USER_CREATION_ERROR + Token Race

**Date:** 22 janvier 2026  
**Version:** 1.0  
**Scope:** Backend instrumentation + Front auth sequencing + Site public sandbox CDN

---

## 1. Symptômes Observés

### 1.1 Erreur 500 USER_CREATION_ERROR
- **Endpoint:** `POST /api/admin/register`
- **Symptôme:** Retourne `500 USER_CREATION_ERROR` même après un `/api/auth/me` en 200
- **Contexte:** Google sign-in popup réussit, mais l'inscription échoue

### 1.2 Token Race (401 intermittent)
- **Endpoint:** `GET /api/auth/me`
- **Symptôme:** Retourne parfois `401 {"error":"invalid_token"}` juste après Google login
- **Cause probable:** Token Firebase pas encore attaché au moment de l'appel API

### 1.3 CDN Mismatch (Site Public Sandbox)
- **Hostname:** `sitepublic-sandbox.koomy.app`
- **Symptôme:** Utilisait `cdn.koomy.app` (prod) au lieu de `cdn-sandbox.koomy.app`
- **Impact:** Non bloquant pour l'auth mais mismatch de configuration

---

## 2. Cause Racine

### 2.1 USER_CREATION_ERROR
La cause exacte dépend du code SQLSTATE loggé. Les possibilités sont:

| SQLSTATE | Cause | Code erreur retourné |
|----------|-------|---------------------|
| 23505 | Unique violation (email déjà pris) | `EMAIL_TAKEN` |
| 23502 | NOT NULL violation (colonne manquante) | `USER_INSERT_FAILED_NULL_CONSTRAINT` |
| 23503 | FK violation (référence invalide) | `USER_INSERT_FAILED` |
| Autre | Erreur DB générique | `USER_INSERT_FAILED` |

### 2.2 Token Race
- Le token Firebase n'est pas immédiatement disponible après `signInWithPopup`
- Les appels API partent avant que le token soit cached
- Solution: `ensureFirebaseToken()` DOIT être appelé et awaité avant toute requête API

### 2.3 CDN Sandbox
- `VITE_CDN_BASE_URL` non défini dans l'environnement de build Cloudflare Pages
- Solution: Fallback environment-aware basé sur hostname pattern matching

---

## 3. Correctifs Appliqués

### 3.1 Backend - Logs Enrichis (A1)

**Fichier:** `server/routes.ts`

Chaque étape de création (user, community, membership) log maintenant:
- `step`: Étape où l'erreur se produit
- `message`: Message d'erreur
- `code`: Code SQLSTATE (23505, 23502, etc.)
- `constraint`: Nom de la contrainte violée
- `table`/`column`: Table et colonne concernées
- `detail`: Détail de l'erreur PostgreSQL
- `stack`: 5 premières lignes de la stack trace

```javascript
console.error(`[Admin Register ${traceId}] ERROR: USER_INSERT_FAILED`, { 
  step: 'create_user',
  message: userError?.message,
  code: userError?.code,
  constraint: userError?.constraint,
  table: userError?.table,
  column: userError?.column,
  detail: userError?.detail,
  stack: userError?.stack?.split('\n').slice(0, 5).join('\n')
});
```

### 3.2 Backend - Codes d'Erreur Précis (A2)

| Ancien code | Nouveau code |
|-------------|--------------|
| `USER_CREATION_ERROR` | `USER_INSERT_FAILED` |
| `USER_CREATION_ERROR` (23502) | `USER_INSERT_FAILED_NULL_CONSTRAINT` |
| `COMMUNITY_CREATION_ERROR` | `COMMUNITY_INSERT_FAILED` |
| `MEMBERSHIP_CREATION_ERROR` | `MEMBERSHIP_INSERT_FAILED` |

### 3.3 Front - Token Diagnostics (C3)

**Fichier:** `client/src/api/httpClient.ts`

Log ajouté (dev only) avant chaque appel API:
```javascript
console.log(`[API ${traceId}] Token check:`, {
  hasToken: !!firebaseToken,
  tokenLength: firebaseToken?.length || 0,
  endpoint: path
});
```

### 3.4 Front - Token Sequencing (C1/C2)

**Déjà implémenté dans:**
- `client/src/pages/admin/Register.tsx` 
- `client/src/pages/admin/Login.tsx`
- `client/src/pages/mobile/Login.tsx`

Pattern correct:
```javascript
// 1. Sign in with Google
const result = await signInWithGoogle();

// 2. ATTENDRE le cache du token
await ensureFirebaseToken(result.user);

// 3. SEULEMENT ENSUITE appeler les APIs
const meResponse = await apiGet("/api/auth/me");
```

### 3.5 CDN Sandbox (D)

**Fichiers:** 
- `client/src/lib/envGuard.ts` - Pattern matching sandbox hostnames
- `client/src/lib/cdnResolver.ts` - Environment-aware fallback

Le pattern `/sandbox/i` matche tous les hostnames contenant "sandbox":
- `sitepublic-sandbox.koomy.app` ✓
- `backoffice-sandbox.koomy.app` ✓
- `sandbox.koomy.app` ✓

Fallback automatique:
- Hostname sandbox → `https://cdn-sandbox.koomy.app`
- Hostname production → `https://cdn.koomy.app`

---

## 4. Checklist de Tests Manuels

### 4.1 Test Google Register (Sandbox)

1. Aller sur `https://sitepublic-sandbox.koomy.app`
2. Cliquer sur "Créer ma communauté"
3. Cliquer sur "Continuer avec Google"
4. Compléter le formulaire
5. Vérifier dans la console:
   - [ ] `[API TR-xxx] Token check: { hasToken: true, tokenLength: xxx, endpoint: /api/auth/me }`
   - [ ] Pas de `401 invalid_token`
   - [ ] Pas de `500 USER_INSERT_FAILED`

### 4.2 Test Token Race

1. Ouvrir les DevTools > Console
2. Faire un Google sign-in
3. Vérifier que chaque appel API a `hasToken: true`
4. Si `hasToken: false` apparaît → Bug non résolu

### 4.3 Test CDN Sandbox

1. Aller sur `https://sitepublic-sandbox.koomy.app`
2. Ouvrir les DevTools > Console
3. Vérifier le log de boot:
   - [ ] `Effective CDN: https://cdn-sandbox.koomy.app`
4. Vérifier les requêtes réseau:
   - [ ] Images/assets chargés depuis `cdn-sandbox.koomy.app`

### 4.4 Test Logs Backend (si erreur)

1. Reproduire l'erreur
2. Vérifier les logs serveur pour:
   - [ ] TraceId présent
   - [ ] SQLSTATE code visible
   - [ ] Constraint name si applicable

---

## 5. Risques / Suivis

### 5.1 Risques Identifiés

| Risque | Impact | Mitigation |
|--------|--------|------------|
| Token cache expiré | API rejetée | Le cache a 50min TTL, refresh auto |
| Popup bloqué | Fallback redirect (plus lent) | UX acceptable |
| Schéma DB sandbox différent | INSERT fail | Migration à aligner |

### 5.2 Suivis Recommandés

1. **Monitoring:** Surveiller les logs `USER_INSERT_FAILED` pour identifier les causes récurrentes
2. **Migration:** Vérifier que `users.password` est nullable en sandbox (pour Google-only users)
3. **Firebase Console:** Ajouter `sitepublic-sandbox.koomy.app` aux domaines autorisés si pas déjà fait

---

## 6. Definition of Done

- [x] `/api/admin/register` log les détails SQLSTATE en cas d'erreur
- [x] Codes d'erreur précis (USER_INSERT_FAILED, COMMUNITY_INSERT_FAILED, etc.)
- [x] Log front token diagnostics (hasToken, tokenLength, endpoint)
- [x] Token sequencing déjà correct (ensureFirebaseToken avant API calls)
- [x] CDN sandbox resolution environment-aware (pattern matching)
- [x] Rapport livré

---

*Document généré le 22 janvier 2026*
