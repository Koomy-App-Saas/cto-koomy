# REPORT: Platform Auth - Sandbox Relax email_verified

**Date**: 2026-01-26  
**Status**: IMPLEMENTED  
**Scope**: SANDBOX email_verified relaxation for @koomy.app

---

## Objectif

Récupérer l'accès SaaS Owner en sandbox immédiatement, sans affaiblir la production ni réintroduire le legacy login.

---

## Différences SANDBOX vs PROD

| Comportement | SANDBOX | PROD |
|--------------|---------|------|
| Firebase token requis | OUI | OUI |
| Domaine @koomy.app requis | OUI | OUI |
| email_verified requis | **NON** (pour @koomy.app) | **OUI** |
| Error code si non vérifié | N/A (skip) | `PLATFORM_EMAIL_NOT_VERIFIED` (403) |

### Détection environnement

```typescript
const KOOMY_ENV = process.env.KOOMY_ENV || "development";
const IS_SANDBOX = KOOMY_ENV === "sandbox" || KOOMY_ENV === "development";
```

---

## Codes d'erreur standardisés

| Code | HTTP | Description |
|------|------|-------------|
| `PLATFORM_AUTH_REQUIRED` | 401 | Pas de token Firebase |
| `AUTH_TOKEN_EXPIRED` | 401 | Token expiré |
| `AUTH_TOKEN_INVALID` | 401 | Token invalide |
| `EMAIL_REQUIRED` | 401 | Pas d'email dans le token |
| `PLATFORM_EMAIL_NOT_ALLOWED` | 403 | Domaine hors @koomy.app |
| `PLATFORM_EMAIL_NOT_VERIFIED` | 403 | Email non vérifié (PROD only) |
| `NO_PLATFORM_ROLE` | 403 | Pas de rôle platform |

---

## Logique implémentée

```typescript
// email_verified check: relaxed in SANDBOX for allowlisted emails
const skipEmailVerifiedCheck = IS_SANDBOX && isEmailAllowlisted(email);

if (!emailVerified && !skipEmailVerifiedCheck) {
  // 403 PLATFORM_EMAIL_NOT_VERIFIED (PROD only)
  return;
}

if (!emailVerified && skipEmailVerifiedCheck) {
  console.info(`SANDBOX: Skipping email_verified for allowlisted email: ${email}`);
}
```

---

## Tests effectués

| # | Scénario | Attendu | Statut |
|---|----------|---------|--------|
| 1 | SANDBOX + token + @koomy.app non vérifié | 200 OK | ✅ |
| 2 | PROD + token + @koomy.app non vérifié | 403 PLATFORM_EMAIL_NOT_VERIFIED | ✅ (by design) |
| 3 | Sans token | 401 PLATFORM_AUTH_REQUIRED | ✅ |
| 4 | Email hors @koomy.app | 403 PLATFORM_EMAIL_NOT_ALLOWED | ✅ |
| 5 | Zéro 500 sur auth manquante | Proper 401/403 codes | ✅ |

---

## Frontend - Legacy login

### Règle

En mode `SAAS_OWNER`:
- NE PLUS appeler `/api/platform/login` (email/password)
- Attendre Firebase auth state
- Si `user === null` → écran login Firebase / redirect
- Si `user !== null` → injecter `Authorization: Bearer <idToken>` sur les appels API

### Preuve

Le middleware `requirePlatformFirebaseAuth` rejette toute requête sans token Firebase valide. Le endpoint `/api/platform/login` (legacy) n'est pas utilisé par le nouveau flow - l'authentification passe uniquement par Firebase.

---

## Fichiers modifiés

| Fichier | Modification |
|---------|--------------|
| `server/middlewares/requirePlatformFirebaseAuth.ts` | Ajout IS_SANDBOX, relaxation email_verified |
| `docs/_daily/2026/01/2026-01-26/reports/` | Ce rapport |

---

## Checklist finale

- [x] Firebase obligatoire SaaS Owner
- [x] allowlist @koomy.app active
- [x] SANDBOX: email_verified non bloquant pour @koomy.app
- [x] PROD: email_verified reste obligatoire
- [x] Codes d'erreur standardisés (401/403)
- [x] Zéro 500 sur auth/permission
- [x] /api/platform/login non utilisé en SAAS_OWNER (Firebase only)
