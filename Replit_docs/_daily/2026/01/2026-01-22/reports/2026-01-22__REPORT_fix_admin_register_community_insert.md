# Fix: Admin Register Community Insert Atomic

**Date:** 2026-01-22  
**Type:** Bug Fix + Feature Enhancement  
**Environment:** Sandbox (Railway) + Replit  
**Status:** COMPLETED

---

## Cause Racine

Le problème était que `/api/admin/register` créait les entités (user, community, membership) de manière séquentielle et non-atomique:

1. L'user était créé
2. La community était créée (pouvait échouer)
3. Le membership était créé

Si l'étape 2 ou 3 échouait, l'user restait orphelin dans la base de données.

---

## Solution Implémentée

### 1. Transaction Atomique

Création d'une nouvelle méthode `registerAdminWithCommunityAtomic()` dans `server/storage.ts` qui encapsule les 3 opérations dans une transaction Drizzle:

```typescript
async registerAdminWithCommunityAtomic(params: {
  user: InsertUser;
  community: InsertCommunity;
  membership: Omit<InsertMembership, 'userId' | 'communityId'>;
  traceId: string;
}): Promise<{
  user: User;
  community: Community;
  membership: UserCommunityMembership;
}>
```

**Comportement:**
- `TX_START`: Démarre la transaction
- `TX_STEP1`: Crée l'user
- `TX_STEP2`: Crée la community (avec ownerId = user.id)
- `TX_STEP3`: Crée le membership OWNER
- `TX_COMMIT`: Commit si tout réussit
- `ROLLBACK`: Automatique si n'importe quelle étape échoue

### 2. Mapping d'Erreurs Postgres

Les codes SQLSTATE sont maintenant mappés vers des codes API explicites:

| SQLSTATE | Code API | HTTP | Description |
|----------|----------|------|-------------|
| 23505 | EMAIL_TAKEN / SLUG_CONFLICT / COMMUNITY_CONFLICT | 409 | Violation d'unicité |
| 23503 | COMMUNITY_LINK_FAILED | 400 | Violation FK |
| 23502 | COMMUNITY_INVALID_PAYLOAD | 400 | Violation NOT NULL |
| 42703 | SCHEMA_MISMATCH | 500 | Colonne inexistante |
| 23514 | COMMUNITY_VALIDATION_FAILED | 400 | Violation CHECK |
| Autre | REGISTRATION_FAILED | 500 | Erreur générique |

### 3. Garde d'Idempotence

Pour les utilisateurs existants (trouvés par Firebase UID ou email):
- Vérification si l'user possède déjà une communauté (isOwner=true)
- Si oui: retour 409 `ALREADY_REGISTERED` avec message "Un compte = un club"
- Si non: création de la communauté (non-atomique car user existe déjà)

### 4. Logs Améliorés

Nouveaux logs avec traceId:
- `[Admin Register ${traceId}] ATOMIC_START` - Début transaction
- `[Admin Register ${traceId}] TX_STEP1: user_created` - User créé
- `[Admin Register ${traceId}] TX_STEP2: community_created` - Community créée
- `[Admin Register ${traceId}] TX_STEP3: membership_created` - Membership créé
- `[Admin Register ${traceId}] ATOMIC_SUCCESS` - Transaction réussie
- `[Admin Register ${traceId}] ATOMIC_FAILED` - Transaction échouée (avec pgCode, message, constraint, table)

---

## Fichiers Modifiés

| Fichier | Modification |
|---------|--------------|
| `server/storage.ts` | Ajout de `registerAdminWithCommunityAtomic()` (lignes 3710-3780) |
| `server/routes.ts` | Refactoring de `/api/admin/register` pour utiliser la transaction + mapping erreurs |

---

## Résultats Attendus des Tests

### Test 1: Nouvelle inscription admin
```
Flow: Google Sign-In → Register → Create Community
Attendu: 200/201 avec { communityId, traceId }
Logs: ATOMIC_START → TX_STEP1 → TX_STEP2 → TX_STEP3 → ATOMIC_SUCCESS
```

### Test 2: Réinscription même compte
```
Flow: Même compte Google → Register
Attendu: 409 { code: "ALREADY_REGISTERED", error: "Un compte = un club" }
```

### Test 3: Nom de communauté invalide (vide)
```
Attendu: 400 { code: "MISSING_FIELDS", missingFields: ["communityName"] }
```

### Test 4: Conflit de slug (même nom)
```
Attendu: 409 { code: "SLUG_CONFLICT" }
```

---

## Vérification

```sql
-- Vérifier qu'il n'y a pas d'utilisateurs orphelins
SELECT u.id, u.email, u.created_at, 
       COUNT(c.id) as community_count,
       COUNT(m.id) as membership_count
FROM users u
LEFT JOIN communities c ON c.owner_id = u.id
LEFT JOIN user_community_memberships m ON m.user_id = u.id
WHERE u.created_at > NOW() - INTERVAL '1 day'
GROUP BY u.id, u.email, u.created_at
HAVING COUNT(c.id) = 0 OR COUNT(m.id) = 0;
```

---

## Notes Techniques

- La méthode utilise `db.transaction()` de Drizzle qui gère automatiquement le rollback en cas d'erreur
- Les insertions utilisent `as any` pour bypasser les vérifications TypeScript strictes (cohérent avec le pattern existant)
- Le membership inclut tous les champs nécessaires (sectionScope, permissions) pour un OWNER

---

**Auteur:** Replit Agent
