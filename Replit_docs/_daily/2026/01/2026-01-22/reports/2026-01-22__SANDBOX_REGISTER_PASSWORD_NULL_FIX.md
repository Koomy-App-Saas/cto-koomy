# Fix: Password NULL pour utilisateurs Firebase

**Date:** 2026-01-22  
**Statut:** ✅ TERMINÉ  
**Auteur:** Agent Replit

---

## 1. Résumé Exécutif

Correction de l'erreur 500 sur `/api/admin/register` pour les utilisateurs Firebase (Google Sign-In). La colonne `users.password` a été rendue nullable pour permettre la création d'utilisateurs authentifiés via Firebase sans mot de passe local.

### Résultats Clés
- **Migration DB appliquée**: `ALTER TABLE users ALTER COLUMN password DROP NOT NULL`
- **Schema Drizzle mis à jour**: `password: text("password")` (sans `.notNull()`)
- **3/3 tests** smoke passent
- **Compatibilité préservée**: les utilisateurs email/password fonctionnent toujours

---

## 2. Root Cause

**Erreur:**
```
null value in column "password" of relation "users" violates not-null constraint
```

**Cause:** Lors de la création d'un utilisateur via Google Sign-In (Firebase), le code passait `password: null` mais la colonne DB avait une contrainte `NOT NULL`.

---

## 3. Migration DB Appliquée

```sql
ALTER TABLE users ALTER COLUMN password DROP NOT NULL;
```

**Vérification:**
```sql
SELECT column_name, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'users' AND column_name = 'password';

-- Résultat: is_nullable = 'YES'
```

---

## 4. Fichiers Modifiés

| Fichier | Changement |
|---------|-----------|
| `shared/schema.ts` | `password: text("password").notNull()` → `password: text("password")` |

**Note:** La route `/api/admin/register` gérait déjà correctement le cas `hashedPassword = null` pour les utilisateurs Firebase (ligne 2651). Aucune modification nécessaire.

---

## 5. Tests

### Script de Test

```bash
npx tsx scripts/sandbox_register_smoke_test.ts
```

### Résultats

```
=== Sandbox Register Smoke Tests ===

✅ users.password is nullable in DB
✅ Insert user without password (Firebase pattern)
✅ Insert user with password (email/password pattern)

Total: 3 passed, 0 failed
```

---

## 6. Points de Vigilance

### Reset Password

Les endpoints de réinitialisation de mot de passe doivent vérifier que l'utilisateur a un mot de passe local avant d'autoriser le reset. Pour les utilisateurs Firebase:
- Ils ne peuvent pas utiliser "forgot password" 
- Ils doivent utiliser Google Sign-In pour s'authentifier

### Compatibilité

- **Utilisateurs email/password**: Continuent de fonctionner normalement (password requis à l'inscription)
- **Utilisateurs Firebase**: Créés avec `password: null`, authentifiés via token Firebase

---

## 7. Definition of Done

| Critère | Statut |
|---------|--------|
| `/api/admin/register` ne renvoie plus 500 pour Google Sign-In | ✅ |
| `users.password` nullable en DB | ✅ |
| Schema Drizzle mis à jour | ✅ |
| Flux email/password inchangé | ✅ |
| Tests passent | ✅ |
| Rapport livré | ✅ |

---

## 8. Commandes de Validation

```bash
# Vérifier que password est nullable
npx tsx scripts/sandbox_register_smoke_test.ts

# Vérifier en DB directement
SELECT is_nullable FROM information_schema.columns 
WHERE table_name = 'users' AND column_name = 'password';
-- Doit retourner: 'YES'
```
