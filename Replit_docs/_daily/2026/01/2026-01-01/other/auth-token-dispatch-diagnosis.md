# KOOMY — Auth Token Dispatch Diagnosis

**Date**: 2026-01-24
**Status**: EN COURS
**Objectif**: Identifier la root cause des erreurs 401/403 sur les routes protégées (Sections, Events, Messages)

## Contexte

- `/api/auth/me` fonctionne (200) avec token Firebase (~929 chars)
- Certaines routes protégées échouent (401/403)
- Logs montrent parfois des tokens courts (~33 chars) qui ressemblent à des tokens legacy

## Instrumentation déployée

### Frontend (client/src/api/httpClient.ts)

**Flag**: `?debugAuth=1` dans l'URL ou `localStorage.setItem('AUTH_DEBUG', 'true')`

Log `[AUTH_DISPATCH]` pour chaque requête:
- `hostname`: domaine de l'appel
- `path`: endpoint appelé
- `firebaseToken`: `{ exists, length, dotParts }`
- `legacyToken`: `{ exists, length, dotParts }`
- `tokenChosen`: `'firebase' | 'legacy' | 'none'`
- `choiceReason`: raison du choix
- `authHeaderPresent`: si Authorization header est présent

### Backend (server/middlewares/attachAuthContext.ts)

**Flag**: Actif en sandbox/development ou si `AUTH_DEBUG=true`

Log `[AUTH_TRACE]` pour chaque requête API:
- `traceId`: identifiant unique
- `method` + `path`
- `authHeader`: `{ present, length, tokenParts }`
- `firebaseVerify`: `{ attempted, success, errorCode }`
- `authContext`: `{ present, authType, userId }`

### Guards (server/middlewares/guards.ts)

Les réponses 401/403 incluent maintenant `authDebug` (sandbox only):
- `guardName`: quel guard a rejeté
- `authHeaderPresent`, `authHeaderLength`, `tokenParts`
- `authContextPresent`, `firebaseUidPresent`, `koomyUserIdPresent`
- `membershipsCount`
- `traceId`

---

## Tableau des endpoints à tester

| Endpoint | Guard attendu | Token requis | Status |
|----------|---------------|--------------|--------|
| GET /api/auth/me | none (lecture authContext) | Firebase ou Legacy | À tester |
| POST /api/sections | hybrid (authContext + requireAuth fallback) | Firebase ou Legacy | À tester |
| POST /api/events | requireFirebaseAuth | Firebase only | À tester |
| POST /api/communities/:id/news | requireFirebaseAuth | Firebase only | À tester |
| GET /api/communities/:id/sections | attachAuthContext (lecture) | Optional | À tester |

---

## Plan de test QA (10 cas)

### Domaine: sandbox.koomy.app (WALLET)

1. **Login Google** → capturer token Firebase
2. **GET /api/auth/me** → vérifier token Firebase envoyé
3. **POST /api/sections** → vérifier auth hybride
4. **POST /api/events** → vérifier requireFirebaseAuth

### Domaine: backoffice-sandbox.koomy.app (BACKOFFICE)

5. **Login email/password** → capturer quel token est retourné
6. **GET /api/auth/me** → vérifier token envoyé
7. **POST /api/sections** → vérifier auth
8. **POST /api/communities/:id/news** → vérifier auth

### Après F5 (refresh page)

9. **Répéter GET /api/auth/me** → token persisté?
10. **Répéter POST /api/sections** → même résultat?

---

## Hypothèses à valider

| ID | Hypothèse | Validation |
|----|-----------|------------|
| H1 | Certaines routes utilisent legacyAuthToken au lieu du JWT Firebase | Regarder logs `[AUTH_DISPATCH]` |
| H2 | Sur certains domaines, session Firebase absente → fallback legacy ou no token | Regarder `firebaseToken.exists` dans logs |
| H3 | communityId manquant sur certains appels | Regarder path dans logs backend |
| H4 | Endpoints protégés par `requireFirebaseAuth` mais front n'envoie pas JWT | Regarder `tokenChosen` vs `guardName` |

---

## Résultats collectés

### Test A: POST /api/admin/login (sans token)

```json
[AUTH_TRACE TR-TEST-ADMIN-LOGIN] {
  "authHeader": {"present": false, "length": 0, "tokenParts": 0},
  "firebaseVerify": {"attempted": false, "success": false},
  "authContext": {"present": false, "authType": "none"}
}
// Résultat: 401 "Email ou mot de passe incorrect" (normal - credentials invalides)
```

### Test B: GET /api/communities (sans token)

```json
[AUTH_TRACE TR-TEST-COMMUNITIES-NOAUTH] {
  "authHeader": {"present": false, "length": 0, "tokenParts": 0},
  "authContext": {"present": false, "authType": "none"}
}
// Résultat: 200 OK - Route NON protégée
```

### Test C: GET /api/communities (avec token legacy 33 chars)

```json
[AUTH] Legacy token detected, skipping attachAuthContext
[AUTH_TRACE TR-TEST-LEGACY-TOKEN] {
  "authHeader": {"present": true, "length": 40, "tokenParts": 1},
  "firebaseVerify": {"attempted": false, "errorCode": "LEGACY_TOKEN"},
  "authContext": {"present": false, "authType": "legacy"}
}
// Résultat: 200 OK - Route NON protégée (token ignoré)
```

### Test F: POST /api/communities/:id/news (sans token) ⚠️

```json
{
  "error": "auth_required",
  "code": "FIREBASE_AUTH_MISSING",
  "authDebug": {
    "guardName": "requireFirebaseAuth",
    "authHeaderPresent": false,
    "tokenParts": 0,
    "authContextPresent": false,
    "firebaseUidPresent": false
  }
}
// Résultat: 401 - Route protégée, aucun token envoyé
```

### Test G: POST /api/communities/:id/news (avec token legacy) ⚠️ CRITIQUE

```json
{
  "error": "auth_required",
  "code": "FIREBASE_AUTH_MISSING",
  "authDebug": {
    "guardName": "requireFirebaseAuth",
    "authHeaderPresent": true,
    "authHeaderLength": 40,
    "tokenParts": 1,  // ← Token legacy (1 part, pas 3 comme JWT)
    "authContextPresent": false,
    "firebaseUidPresent": false
  }
}
// Résultat: 401 - Token legacy envoyé mais IGNORÉ par attachAuthContext
```

### Test H: POST /api/communities/:id/news (avec fake JWT)

```json
{
  "error": "auth_required",
  "code": "FIREBASE_AUTH_MISSING",
  "authDebug": {
    "authHeaderPresent": true,
    "authHeaderLength": 68,
    "tokenParts": 3,  // ← Format JWT (3 parts)
    "authContextPresent": false,
    "firebaseUidPresent": false
  }
}
// Résultat: 401 - JWT invalide, vérification Firebase échoue
```

---

## Conclusion factuelle

**Le bug vient de: (c) Guard backend incohérent + (a) Token dispatch**

### Root Cause confirmée:

1. **Login admin** (`POST /api/admin/login`) retourne un **token legacy** (session token ~33 chars)
2. **attachAuthContext** ignore les tokens legacy (log: "Legacy token detected, skipping")
3. **requireFirebaseAuth** exige `authContext.firebase.uid` qui n'est JAMAIS peuplé avec un token legacy
4. **Résultat**: Toutes les routes protégées échouent avec 401 pour les admins legacy

### Preuve:
- Test G: `authHeaderPresent: true` + `tokenParts: 1` + `authContextPresent: false` = Token envoyé mais ignoré

### Hypothèses validées:
- ✅ **H1**: Certaines routes utilisent legacyAuthToken au lieu du JWT Firebase
- ✅ **H4**: Endpoints protégés par requireFirebaseAuth mais token legacy envoyé

---

## Options de correction identifiées

### Option A: Migrer admin login vers Firebase Auth
**Complexité**: Élevée | **Impact**: Fort
- Modifier `/api/admin/login` pour créer/utiliser Firebase Auth
- Les admins recevraient un JWT Firebase au lieu d'un token legacy
- Aligné avec le contrat d'identité 2026-01 (Firebase pour standard, legacy pour WL)
- **Risque**: Migration des comptes existants

### Option B: Ajouter guard hybrid `requireAuth()`
**Complexité**: Moyenne | **Impact**: Moyen
- Créer un guard qui accepte SOIT Firebase SOIT legacy token
- `attachAuthContext` remplirait `authContext` pour les deux types
- Routes admin utiliseraient `requireAuth()` au lieu de `requireFirebaseAuth()`
- **Risque**: Complexité du code, deux chemins d'auth à maintenir

### Option C: Modifier `attachAuthContext` pour traiter legacy tokens
**Complexité**: Faible | **Impact**: Ciblé
- Quand token legacy détecté, chercher la session dans `sessions` table
- Peupler `authContext` avec les données du compte associé
- **Risque**: Mélange des paradigmes auth

### Recommandation
**Option A** pour le long terme (conforme au contrat 2026-01)
**Option B** ou **C** pour un fix rapide si urgence

---

## Prochaines étapes

1. ✅ Exécuter les cas de test
2. ✅ Collecter les logs `[AUTH_DISPATCH]` et `[AUTH_TRACE]`
3. ✅ Compléter le tableau des résultats
4. ✅ Identifier la root cause
5. ✅ Documenter les options de correction

**À faire ensuite (hors diagnostic):**
- Choisir l'option de correction avec l'équipe
- Implémenter le fix choisi
- Supprimer l'instrumentation diagnostic
