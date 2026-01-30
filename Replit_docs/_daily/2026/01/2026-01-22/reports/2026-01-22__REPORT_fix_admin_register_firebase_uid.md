# Fix: Admin Register Firebase UID Column

**Date:** 2026-01-22  
**Type:** Bug Fix  
**Environment:** Sandbox (Railway)  
**Status:** REQUIRES MANUAL DB SYNC ON RAILWAY

---

## Cause Racine

L'erreur `column "firebase_uid" does not exist` (SQLSTATE 42703) se produit car:

1. La DB sandbox Railway a été purgée/réinitialisée
2. Le schéma Drizzle définit bien `firebaseUid` sur la table `users`
3. Mais après une purge, la DB n'a pas été resynchronisée avec le schéma

**Code fautif:** `storage.getUserByFirebaseUid(firebaseUser.uid)` dans `/api/admin/register` (ligne ~2629)

---

## Schéma Drizzle (déjà correct)

```typescript
// shared/schema.ts - ligne 363
export const users = pgTable("users", {
  // ...
  firebaseUid: text("firebase_uid").unique(), // Firebase Auth UID (immutable primary identity)
  // ...
});
```

La colonne existe dans le schéma mais pas dans la DB sandbox après purge.

---

## Solution: Synchroniser la DB Railway

### Option 1: Via Railway CLI/Shell

```bash
# Depuis le shell Railway du backend
npm run db:push
```

Si la commande demande confirmation pour les contraintes, choisir "No, add the constraint without truncating the table".

### Option 2: SQL Direct (si db:push échoue)

Exécuter sur la DB sandbox Railway:

```sql
-- 1) Ajouter la colonne si elle n'existe pas
ALTER TABLE users ADD COLUMN IF NOT EXISTS firebase_uid TEXT;

-- 2) Créer l'index unique partiel
CREATE UNIQUE INDEX IF NOT EXISTS users_firebase_uid_unique 
ON users (firebase_uid) 
WHERE firebase_uid IS NOT NULL;
```

---

## Fichiers Concernés

| Fichier | Modification |
|---------|--------------|
| `shared/schema.ts:363` | Contient déjà `firebaseUid: text("firebase_uid").unique()` |
| `server/storage.ts:494-496` | Méthode `getUserByFirebaseUid()` qui fait le lookup |
| `server/routes.ts:2629` | Appel dans `/api/admin/register` |

**Aucune modification de code requise** - le schéma est correct.

---

## Flow `/api/admin/register`

```
1. POST /api/admin/register avec Bearer token Firebase
   │
2. verifyFirebaseToken(token) → {uid, email, displayName}
   │
3. Lookup identité:
   │  ├─ getUserByFirebaseUid(uid) ← CRASH ICI si colonne absente
   │  └─ getUserByEmail(email) (fallback)
   │
4. Si user existe: vérifier communauté existante
5. Sinon: créer user + communauté
```

---

## Tests à Effectuer (après sync DB)

### Test 1: Nouvelle inscription admin

```bash
# Flow: Google Sign-In → Register → Create Community
# Via UI: https://sitepublic-sandbox.koomy.app/register
# Attendu: 200/201
```

### Test 2: Réinscription même compte Google

```bash
# Même flow, même compte Google
# Attendu: 409 ou message "email déjà utilisé"
# PAS 500
```

### Test 3: Vérifier communauté créée

```bash
# Connexion backoffice avec le compte créé
# Attendu: Dashboard visible avec la nouvelle communauté
```

---

## Vérification DB

```sql
-- Vérifier que la colonne existe
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'users' AND column_name = 'firebase_uid';

-- Vérifier l'index unique
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename = 'users' AND indexname LIKE '%firebase%';
```

---

## Notes

- Le schéma Drizzle est correct, seule la DB sandbox Railway doit être synchronisée
- Cette situation se produit après une purge DB sans re-sync du schéma
- La solution est un simple `npm run db:push` sur Railway
- Aucune modification de code n'est requise

---

**Auteur:** Replit Agent  
**Action requise:** Exécuter `npm run db:push` sur Railway sandbox
