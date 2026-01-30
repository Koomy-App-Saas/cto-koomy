# SANDBOX_AUTH_FIX_REPORT

**Date:** 2026-01-22  
**Ticket:** Correction erreur 500 sur /api/admin/register et /api/auth/me en sandbox

## Cause Racine

Le code backend utilisait une colonne `firebase_uid` qui n'existe pas dans la DB sandbox de production. Le schéma correct utilise:
- `accounts.provider_id` = Firebase UID
- `accounts.auth_provider` = "firebase"

Erreur SQL observée:
```
column "firebase_uid" does not exist (42703)
```

## Fichiers Modifiés

| Fichier | Modification |
|---------|--------------|
| `shared/schema.ts` | Suppression de `firebaseUid` du schéma accounts |
| `server/storage.ts` | Remplacement de `getAccountByFirebaseUid()` par `getAccountByProviderId(providerId, authProvider)` |
| `server/storage.ts` | Remplacement de `updateAccountFirebaseUid()` par `linkAccountToProvider(id, providerId, authProvider)` |
| `server/routes.ts` | Correction de `/api/auth/me` pour utiliser `getAccountByProviderId` |
| `server/routes.ts` | Suppression de `firebaseUid` dans la création user `/api/admin/register` |
| `server/middlewares/attachAuthContext.ts` | Correction du lookup et backfill pour utiliser `providerId` + `authProvider` |

## Avant / Après

### Avant (Erreur 500)
```typescript
// Lookup by firebase_uid column (n'existe pas)
account = await storage.getAccountByFirebaseUid(decoded.uid);

// Query générée (FAIL):
// SELECT * FROM accounts WHERE firebase_uid = ?
```

### Après (Correct)
```typescript
// Lookup by provider_id + auth_provider='firebase'
account = await storage.getAccountByProviderId(decoded.uid, "firebase");

// Query générée (OK):
// SELECT * FROM accounts WHERE provider_id = ? AND auth_provider = 'firebase'
```

## Vérification Non-Régression

Recherche globale `firebase_uid` dans le repo:
```bash
grep -r "firebase_uid\|firebaseUid" --include="*.ts" .
# Résultat: No matches found
```

## Comportement Attendu

| Endpoint | Situation | Réponse |
|----------|-----------|---------|
| `/api/auth/me` | Token valide, account trouvé | 200 + user data |
| `/api/auth/me` | Token valide, account non trouvé | 200 + `user: null` |
| `/api/auth/me` | Token invalide | 401 |
| `/api/auth/me` | Erreur DB inattendue | 500 ACCOUNT_LOOKUP_FAILED |
| `/api/admin/register` | Email déjà utilisé | 409 EMAIL_TAKEN |
| `/api/admin/register` | Création réussie | 201 |

## Tests à Effectuer (Manuel)

1. **Google Sign-In sur backoffice-sandbox.koomy.app**
   - Popup Google → Succès
   - Appelle `/api/auth/me` → 200 ou erreur métier (pas 500)

2. **Création club via /api/admin/register**
   - Doit retourner 200/201 (pas 500)

3. **Vérification logs**
   - Plus aucune erreur 42703 "column firebase_uid does not exist"

## Commit

```
Fix firebase uid lookup: use accounts.provider_id + auth_provider

- Remove firebaseUid column from schema (not present in production sandbox DB)
- Replace getAccountByFirebaseUid() with getAccountByProviderId(uid, 'firebase')
- Replace updateAccountFirebaseUid() with linkAccountToProvider()
- Update /api/auth/me, /api/admin/register, and attachAuthContext middleware
- All auth lookups now use: provider_id + auth_provider='firebase'
```
