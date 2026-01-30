# KOOMY — AUTH Phase 2 Backend Setup (Keyless Mode)

**Date :** 2026-01-21  
**Domain :** AUTH  
**Doc Type :** PROCEDURE  
**Scope :** Backend (Replit/Railway)  
**Statut :** Validé  
**Contrainte :** Org Policy `iam.disableServiceAccountKeyCreation` → clés JSON interdites

---

## Objectif

Mise en place de la chaîne d'authentification sécurisée :
**Firebase (Front) → Token → Vérification (Backend) → Identité KOOMY**

---

## Composants Implémentés

### 1. Frontend — `client/src/lib/firebase.ts`

Fonctions exportées :
- `getFirebaseAuth()` : Retourne l'instance Auth Firebase (lazy init)
- `getFirebaseApp()` : Retourne l'instance App Firebase (lazy init)
- `getFirebaseIdToken(forceRefresh?: boolean)` : Récupère le token ID Firebase

```typescript
import { getFirebaseIdToken } from "@/lib/firebase";

const token = await getFirebaseIdToken();
if (token) {
  // Appeler /api/auth/me avec Authorization: Bearer <token>
}
```

### 2. Backend — `server/lib/firebaseAdmin.ts` (KEYLESS)

Fonctions exportées :
- `getFirebaseAdmin()` : Retourne l'instance Admin Firebase (lazy init, keyless)
- `verifyFirebaseToken(idToken)` : Vérifie le token et retourne `{ uid, email }`

**Mode Keyless :** Initialisation sans `credential.cert()`, utilise uniquement `projectId`.

**Configuration requise :**
- Variable `FIREBASE_PROJECT_ID` (ex: `koomy-sandbox`)

### 3. Endpoint — `GET /api/auth/me`

**Headers requis :**
```
Authorization: Bearer <firebase_id_token>
```

**Réponses :**

| Cas | Code | Payload |
|-----|------|---------|
| Token manquant | 401 | `{ error: "missing_token" }` |
| Token invalide | 401 | `{ error: "invalid_token" }` |
| Pas de compte KOOMY | 200 | `{ user: null, firebase: { uid, email }, memberships: [] }` |
| Compte trouvé | 200 | `{ user: {...}, firebase: {...}, memberships: [...] }` |

**Payload succès :**
```json
{
  "firebase": {
    "uid": "firebase_uid",
    "email": "user@example.com"
  },
  "env": "sandbox",
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "avatar": "/path/to/avatar.jpg"
  },
  "memberships": [
    {
      "id": "membership_uuid",
      "communityId": "community_uuid",
      "role": "member",
      "status": "active"
    }
  ]
}
```

---

## Tests de Validation

| Test | Résultat |
|------|----------|
| Sans token | 401 `missing_token` ✓ |
| Token invalide | 401 `invalid_token` ✓ |
| Token valide (si configuré) | 200 + payload ✓ |

---

## Variables d'Environnement Requises

| Variable | Environnement | Description |
|----------|--------------|-------------|
| `FIREBASE_PROJECT_ID` | Railway (Sandbox/Prod) | ID du projet Firebase (ex: `koomy-sandbox`) |
| `KOOMY_ENV` | Railway | Environnement (`sandbox` ou `production`) |

**Mode Keyless :** Aucun secret JSON requis (contrainte Org Policy).

---

## Phase 2.5 — Test Harness E2E (Temporaire)

### Page de Test : `/__auth_test`

Page sandbox-only pour valider le flux complet :
1. Connexion Firebase (email/password)
2. Récupération token ID
3. Appel `/api/auth/me` avec token
4. Affichage résultat (UID masqué - 6 premiers caractères)

**Fichiers :**
- `client/src/pages/debug/AuthTest.tsx`
- Route dans `client/src/App.tsx`

**Sécurité :**
- Token JAMAIS loggé
- UID masqué dans l'affichage
- Accès sandbox uniquement

### Procédure de Retrait

Après validation du flux E2E :

```bash
# 1. Supprimer la page
rm client/src/pages/debug/AuthTest.tsx

# 2. Retirer l'import et la route de App.tsx
# Rechercher et supprimer :
# - import AuthTest from "@/pages/debug/AuthTest";
# - <Route path="/__auth_test" component={AuthTest} />
```

---

## Prochaines Étapes (Phase 3+)

- Phase 3 : RBAC propre (guards backend, scopes clairs)
- Phase 4 : Activation UI login contrôlée
- Phase 5 : Nettoyage legacy auth (décommission)

---

## Fichiers Modifiés

| Fichier | Modification |
|---------|-------------|
| `client/src/lib/firebase.ts` | Ajout `getFirebaseIdToken()` |
| `server/lib/firebaseAdmin.ts` | Module keyless (Admin SDK init sans cert) |
| `server/middlewares/requireFirebaseAuth.ts` | Nouveau middleware auth |
| `server/routes.ts` | Ajout endpoint `/api/auth/me` |
| `package.json` | Ajout `firebase-admin@^12.x` |
| `client/src/pages/debug/AuthTest.tsx` | Page test E2E (temporaire) |
| `client/src/App.tsx` | Route `/__auth_test` (temporaire) |
