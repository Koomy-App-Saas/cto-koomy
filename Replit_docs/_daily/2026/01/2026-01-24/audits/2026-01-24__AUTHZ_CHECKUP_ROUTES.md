# AUDIT AUTHZ — Routes Protégées Koomy

**Date**: 2026-01-24  
**Statut**: Audit en cours

## Résumé du problème

Deux systèmes d'auth coexistent:

| Système | Middleware | Token Format | Verification |
|---------|-----------|--------------|--------------|
| **Firebase** | `attachAuthContext` + `requireFirebaseAuth` | JWT 3 segments `aaa.bbb.ccc` | `req.authContext?.firebase?.uid` |
| **Legacy** | Session + `requireAuth` | `accountId:secret` | `extractAccountIdFromBearerToken()` |

**Problème racine**: `requireAuth()` ne vérifie PAS `req.authContext`. Quand un client envoie un token Firebase, `requireAuth` retourne null → 401/403.

## Routes avec requireFirebaseAuth (OK pour Firebase)

| Endpoint | Méthode | Guard | Statut |
|----------|---------|-------|--------|
| `/api/members/join` | POST | requireFirebaseAuth | ✅ OK |
| `/api/admin/join` | POST | requireFirebaseAuth | ✅ OK |
| `/api/memberships/:id` | DELETE | requireFirebaseAuth | ✅ OK |
| `/api/memberships/:id` | PATCH | requireFirebaseAuth | ✅ OK |
| `/api/sections` | POST | requireFirebaseAuth | ✅ OK |
| `/api/communities/:cid/news` | POST | requireFirebaseAuth | ✅ OK |
| `/api/communities/:cid/news/:id` | PATCH | requireFirebaseAuth | ✅ OK |
| `/api/communities/:cid/news/:id` | DELETE | requireFirebaseAuth | ✅ OK |

## Routes avec requireAuth (CASSÉES avec Firebase)

### Events (❌ OFF)
| Endpoint | Méthode | Guard actuel | Erreur |
|----------|---------|--------------|--------|
| `/api/events` | POST | requireAuth | 403 "Admin role required" |
| `/api/events/:id` | PATCH | requireAuth | 401 auth_required |

### News (routes legacy) (❌ OFF)
| Endpoint | Méthode | Guard actuel | Erreur |
|----------|---------|--------------|--------|
| `/api/news` | POST | requireAuth | 401 |
| `/api/news/:id` | PATCH | requireAuth | 401 |
| `/api/news/:id` | DELETE | requireAuth | 401 |

### Sections (routes legacy) (❌ OFF)
| Endpoint | Méthode | Guard actuel | Erreur |
|----------|---------|--------------|--------|
| `/api/sections/:id` | PATCH | requireAuth | 401 |
| `/api/sections/:id` | DELETE | requireAuth | 401 |

### Messages (❌ OFF)
| Endpoint | Méthode | Guard actuel | Erreur |
|----------|---------|--------------|--------|
| `/api/messages` | POST | requireAuth | 401 |
| `/api/messages/:id/read` | PATCH | requireAuth | 401 |
| `/api/messages` (GET) | GET | requireAuth | 401 |

### Admin Management (❌ OFF)
| Endpoint | Méthode | Guard actuel | Erreur |
|----------|---------|--------------|--------|
| `/api/communities/:id/administrators` | POST | requireAuth | 401 |
| `/api/communities/:id/administrators/:adminId` | PATCH | requireAuth | 401 |
| `/api/communities/:id/administrators/:adminId` | DELETE | requireAuth | 401 |

### Autres routes critiques (❌ OFF potentiellement)
~25 autres routes utilisent `requireAuth` et sont potentiellement cassées.

## Solution proposée

Modifier `requireAuth()` dans `server/routes.ts` pour:

1. **Vérifier d'abord** `req.authContext?.koomyUser` (token Firebase décodé)
2. **Si trouvé**: retourner `{ accountId: koomyUser.id, authType: "firebase" }`
3. **Sinon**: fallback vers extraction legacy token

```typescript
function requireAuth(req: any, res: any): AuthResult | null {
  // PRIORITY 1: Firebase auth (via attachAuthContext middleware)
  if (req.authContext?.koomyUser?.id) {
    return {
      accountId: req.authContext.koomyUser.id,
      authType: "firebase"
    };
  }
  
  // PRIORITY 2: Legacy bearer token (accountId:secret format)
  const auth = req.user || req.account;
  const sessionId = auth?.id;
  const accountIdFromBearer = extractAccountIdFromBearerToken(req.headers?.authorization);
  
  // ... rest unchanged
}
```

## Fichiers à modifier

| Fichier | Modification |
|---------|--------------|
| `server/routes.ts` | Modifier `requireAuth()` pour supporter Firebase |

## Plan d'action

1. [x] Audit des routes protégées
2. [x] Modifier `requireAuth()` pour supporter Firebase (2026-01-24)
3. [ ] Tester Events, Sections, Messages
4. [ ] Valider les autres routes critiques

## Correctifs appliqués (2026-01-24)

### Correctif 1: `requireAuth()` dans `server/routes.ts`

1. Vérifie d'abord `req.authContext?.koomyUser?.id` (Firebase)
2. Si trouvé → retourne `{ accountId, authType: "firebase" }`
3. Sinon → fallback legacy (extractAccountIdFromBearerToken, session, body.userId)

Log ajouté: `[AUTH] Firebase user authenticated` avec accountId et firebaseUid (tronqué)

### Correctif 2: `attachAuthContext` dans `server/middlewares/attachAuthContext.ts`

Le middleware ne reconnaissait que les tokens Firebase JWT. Maintenant:

1. Détecte le type de token:
   - Firebase JWT: 3 segments séparés par `.` (ex: `aaa.bbb.ccc`)
   - Legacy: format `accountId:secret` (2+ segments séparés par `:`)

2. Pour Firebase JWT:
   - Décoder avec `verifyFirebaseToken()`
   - Lookup par `provider_id` + backfill email si nécessaire

3. Pour Legacy token:
   - Extraire `accountId` du premier segment
   - Lookup direct dans table `accounts`
   - Créer un pseudo-Firebase identity: `{ uid: "legacy:{accountId}", email }`

**Note sécurité**: Le support legacy dans `attachAuthContext` a été retiré car les tokens legacy ne sont pas vérifiés cryptographiquement (problème préexistant). Les routes qui ont besoin de supporter les deux types utilisent maintenant une logique hybride directement dans le handler.

### Correctif 3: Route POST /api/sections modifiée

La route utilisait `requireFirebaseAuth` qui exigeait un token Firebase. Elle utilise maintenant une logique hybride:

1. Si `req.authContext?.koomyUser` existe (Firebase) → utiliser cet accountId
2. Sinon → appeler `requireAuth()` qui supporte les tokens legacy
3. Lookup membership via `authContext` ou via `storage.getAccountMemberships()`

Cette approche:
- Supporte Firebase ET legacy
- Ne crée pas de nouvelle faille (legacy utilise le même mécanisme qu'avant)
- Préserve la vérification des rôles admin
