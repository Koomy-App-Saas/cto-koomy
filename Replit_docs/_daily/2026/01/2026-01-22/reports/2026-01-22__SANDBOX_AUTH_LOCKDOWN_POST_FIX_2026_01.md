# Rapport: Auth Lockdown Post-Fix Firebase (Sandbox + Prod Safety)

**Date:** 22 janvier 2026  
**Version:** 1.0  
**Scope:** Lockdown des invariants après corrections Firebase auth

---

## 1. Inventory (Step 0)

### 1.1 Recherche `password!`
| Fichier | Ligne | Contexte |
|---------|-------|----------|
| (aucune occurrence dans le code source) | - | - |

### 1.2 Recherche `.password.length`
| Fichier | Ligne | Contexte |
|---------|-------|----------|
| client/src/pages/admin/Register.tsx | 252 | Validation front (Google flow only) |
| client/src/pages/mobile/admin/Register.tsx | 47 | Validation front mobile |

### 1.3 Recherche `hash(password` / `bcrypt`
| Fichier | Ligne | Contexte |
|---------|-------|----------|
| server/routes.ts | 89 | hashPassword util function |
| server/routes.ts | 93 | verifyPassword util function |
| server/routes.ts | 2315 | Admin login bcrypt.compare (guarded) |
| server/routes.ts | 2654 | ~~Admin register password hash~~ (removed) |
| server/routes.ts | 3058 | Mobile admin login (guarded) |
| scripts/seed-*.ts | multiple | Test data seeding |

### 1.4 Recherche `argon`
| Fichier | Ligne | Contexte |
|---------|-------|----------|
| (aucune occurrence) | - | bcrypt utilisé exclusivement |

### 1.5 Recherche `firebaseUid` / `firebase_uid`
| Fichier | Ligne | Contexte |
|---------|-------|----------|
| (aucune occurrence dans le code actif) | - | Pattern `provider_id + auth_provider` utilisé |
| docs/rapports/*.md | multiple | Documentation historique |
| scripts/verify_db_schema.ts | 14-22 | Vérification de l'absence de firebase_uid |

### 1.6 Recherche `sectionScope` / `section_scope`
| Fichier | Ligne | Contexte |
|---------|-------|----------|
| server/routes.ts | 118, 169, 193, 2773, 3509, 3563, 3613, 3635 | Logique de scoping admin |
| server/storage.ts | 812, 867 | Mapping storage |
| shared/schema.ts | 490-491 | Définition Drizzle |
| server/middlewares/attachAuthContext.ts | 47, 153 | Context middleware |

---

## 2. Changements Appliqués

### 2.1 Step 1: Remove implicit password assumptions
**Fichier:** `server/routes.ts`

- Vérification `if (!user.password)` déjà présente ligne 2302 (admin login)
- Fallback vers table `accounts` si password null
- **Aucun changement requis** - le code était déjà sécurisé

### 2.2 Step 2: Make Firebase requirement explicit
**Fichier:** `server/routes.ts` (lignes 2531-2570)

```javascript
// AVANT: Token Firebase optionnel
if (authHeader?.startsWith('Bearer ')) { ... }

// APRÈS: Token Firebase OBLIGATOIRE
if (!authHeader?.startsWith('Bearer ')) {
  console.log(`[Admin Register ${traceId}] AUTH_REQUIRED firebase token missing`);
  return res.status(401).json({ 
    error: "Authentification requise",
    code: "AUTH_REQUIRED",
    traceId 
  });
}
```

- Validation password supprimée (Firebase obligatoire)
- Log explicite `AUTH_REQUIRED firebase token missing/invalid`

### 2.3 Step 3: Identity contract - stable Firebase UID mapping
**Fichiers:** 
- `shared/schema.ts` (ligne 366) - Ajout colonne `firebaseUid`
- `server/storage.ts` (lignes 445-460) - Fonctions `getUserByFirebaseUid`, `updateUserFirebaseUid`
- `server/routes.ts` (lignes 2619-2724) - Logique de lookup/backfill/persist

```javascript
// Identity Contract: Firebase UID -> single DB user
// 1. First lookup by Firebase UID (primary identity)
existingUserByUid = await storage.getUserByFirebaseUid(firebaseUser.uid);

// 2. If not found, lookup by email (for backfill/migration)
if (!existingUserByUid) {
  existingUserByEmail = await storage.getUserByEmail(validatedEmail);
}

// 3. If user found by email, backfill Firebase UID
if (existingUserByEmail) {
  await storage.updateUserFirebaseUid(user.id, firebaseUser.uid);
}

// 4. If not found, create new user with Firebase UID
user = await storage.createUser({
  ...userData,
  firebaseUid: firebaseUser.uid
});
```

- Colonne `firebase_uid` ajoutée au schéma `users` (unique, nullable)
- Lookup primaire par Firebase UID (immutable)
- Fallback par email avec backfill automatique du UID
- Création avec Firebase UID persisté

### 2.4 Step 4: Track membership schema officially
**Fichier créé:** `migrations/2026-01-22_add_section_scope_and_nullable_password.sql`

```sql
ALTER TABLE users ALTER COLUMN password DROP NOT NULL;
ALTER TABLE user_community_memberships ADD COLUMN IF NOT EXISTS section_scope TEXT DEFAULT 'ALL';
ALTER TABLE user_community_memberships ADD COLUMN IF NOT EXISTS section_ids JSONB;
ALTER TABLE user_community_memberships ADD COLUMN IF NOT EXISTS permissions JSONB DEFAULT '[]';
```

**Schéma Drizzle vérifié:** `shared/schema.ts` ligne 490-491
- `sectionScope: text("section_scope").default("ALL")`
- `sectionIds: jsonb("section_ids").$type<string[]>()`

### 2.5 Step 5: Doc lock
**Fichier:** `replit.md` (Platform Security section)

Ajout:
> **Firebase Auth Contract (2026-01-22):** Firebase (Google Sign-In) is the primary identity proof for admin registration. DB stores business user. Firebase users may have `password = NULL`. The `users.password` column is nullable to support Firebase-only accounts. Email is normalized to lowercase for identity matching.

---

## 3. Invariants Implémentés

| # | Invariant | Implémentation |
|---|-----------|----------------|
| 1 | Aucun code n'assume `users.password` non-null | Guard `if (!user.password)` avant bcrypt.compare |
| 2 | `/api/admin/register` Firebase-only | 401 AUTH_REQUIRED si token absent/invalide |
| 3 | Firebase UID = stable link to DB user | Lookup par email lowercase, réutilisation user existant |
| 4 | `section_scope` officiellement tracké | Migration SQL + schéma Drizzle alignés |
| 5 | Doctrine documentée | Note dans replit.md Platform Security |

---

## 4. Regression Checklist

| # | Test | Expected | Status |
|---|------|----------|--------|
| 1 | Google sign-in → `/api/auth/me` | 200 | ⏳ À tester |
| 2 | POST `/api/admin/register` avec token Firebase valide | 200 | ⏳ À tester |
| 3 | POST `/api/admin/register` sans token | 401 AUTH_REQUIRED | ✅ Implémenté |
| 4 | Admin login email/password existant | 200 (si password set) | ⏳ À tester |
| 5 | Membership insert | 200 (section_scope existe) | ✅ Migration appliquée |

---

## 5. Fichiers Modifiés

| Fichier | Type de changement |
|---------|-------------------|
| `server/routes.ts` | Firebase auth obligatoire, email normalization |
| `migrations/2026-01-22_add_section_scope_and_nullable_password.sql` | Nouveau fichier migration |
| `replit.md` | Doc lock (Firebase Auth Contract) |
| `docs/rapports/SANDBOX_AUTH_LOCKDOWN_POST_FIX_2026_01.md` | Ce rapport |

---

## 6. Risques Connus

| Risque | Impact | Mitigation |
|--------|--------|------------|
| Admin login email/password cassé | Moyen | Guard `if (!user.password)` préserve le fallback accounts (ligne 3043) |
| Token Firebase expiré | Faible | Client refresh automatique |
| Email case-sensitivity historique | Faible | Lookup lowercase uniquement sur nouveaux users |
| Firebase UID collision si email change | Faible | Lookup par UID primaire évite les duplications. Backfill pour migration. |

### Note sur les guards bcrypt.compare

Toutes les comparaisons bcrypt sont protégées:
- `server/routes.ts:2302` - Guard `if (!user.password)` → fallback accounts
- `server/routes.ts:3043` - Guard `if (!user || !user.password)` → reject early
- `server/routes.ts:1985` - Utilise `account.passwordHash` qui est NOT NULL dans accounts

---

## 7. Prochaines Étapes Recommandées

1. **Tests E2E:** Exécuter la checklist de régression en sandbox
2. **Cleanup:** Supprimer le code mort de password validation front si non utilisé
3. **Migration prod:** Appliquer la migration SQL en production après validation sandbox

---

*Document généré le 22 janvier 2026*
