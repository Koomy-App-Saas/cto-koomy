# Rapport Phase 2 — User Identities Model (Option C)

**Date**: 2026-01-22  
**Contrat**: Identité & Onboarding (2026-01)  
**Statut**: ✅ COMPLÉTÉ

---

## 1. Résumé Exécutif

Phase 2 de l'Option C implémente le modèle d'identité normalisé via la table `user_identities`:
- Enum `identity_provider` créé avec valeurs `FIREBASE` et `LEGACY_KOOMY`
- Table `user_identities` créée avec contraintes d'unicité
- Backfill exécuté: 9 identités legacy migrées
- Module `identityResolver.ts` créé pour résolution unifiée
- Tests contractuels: 14/14 passent (100%)

### Modèle de Données

```
user_identities
├── id (PK)
├── user_id (FK → users.id, CASCADE DELETE)
├── provider (ENUM: FIREBASE | LEGACY_KOOMY)
├── provider_id (text, unique per provider)
├── provider_email (text, normalized)
├── is_primary (boolean)
├── linked_at (timestamp)
├── last_used_at (timestamp)
└── created_at (timestamp)

INDEXES:
- unique_provider_identity_idx ON (provider, provider_id)
- user_provider_idx ON (user_id, provider)
```

---

## 2. Fichiers Créés

| Fichier | Description |
|---------|-------------|
| `server/lib/identityResolver.ts` | Module de résolution d'identité |
| `scripts/backfill-user-identities.ts` | Script de backfill des identités |
| `scripts/test-contract-phase2.ts` | Tests contractuels Phase 2 |

## 3. Fichiers Modifiés

| Fichier | Modification |
|---------|-------------|
| `shared/schema.ts` | Ajout `identityProviderEnum` + table `userIdentities` |

---

## 4. Migrations Exécutées

### 4.1 Création enum `identity_provider`

```sql
CREATE TYPE identity_provider AS ENUM ('FIREBASE', 'LEGACY_KOOMY');
```

### 4.2 Création table `user_identities`

```sql
CREATE TABLE user_identities (
  id VARCHAR(50) PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id VARCHAR(50) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  provider identity_provider NOT NULL,
  provider_id TEXT NOT NULL,
  provider_email TEXT,
  metadata JSONB,
  is_primary BOOLEAN DEFAULT false,
  linked_at TIMESTAMP DEFAULT NOW() NOT NULL,
  last_used_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW() NOT NULL
);

CREATE UNIQUE INDEX unique_provider_identity_idx ON user_identities(provider, provider_id);
CREATE UNIQUE INDEX user_provider_idx ON user_identities(user_id, provider);
```

### 4.3 Backfill des identités

Résultat du backfill:
- Users avec firebase_uid: 0 (DB de dev ne contient que WL)
- Users sans firebase_uid: 9
- Identités LEGACY_KOOMY créées: 9
- Identités FIREBASE créées: 0

---

## 5. API Identity Resolver

### 5.1 Fonctions Implémentées

| Fonction | Signature | Description |
|----------|-----------|-------------|
| `findUserByFirebaseUid` | `(uid: string) → IdentityLookupResult` | Trouve user par Firebase UID |
| `findUserByLegacyEmail` | `(email: string) → IdentityLookupResult` | Trouve user par email legacy |
| `getUserIdentities` | `(userId: string) → ResolvedIdentity[]` | Liste toutes les identités d'un user |
| `linkIdentity` | `(userId, provider, providerId, email?, isPrimary?) → Result` | Lie une identité à un user |
| `touchIdentity` | `(userId, provider) → void` | Met à jour `last_used_at` |
| `resolveIdentityWithFallback` | `(firebaseUid?, email?) → IdentityLookupResult` | Résolution avec fallback legacy |

### 5.2 Types

```typescript
type IdentityProvider = "FIREBASE" | "LEGACY_KOOMY";

interface ResolvedIdentity {
  userId: string;
  provider: IdentityProvider;
  providerId: string;
  providerEmail: string | null;
  isPrimary: boolean;
  linkedAt: Date;
}

interface IdentityLookupResult {
  found: boolean;
  identity?: ResolvedIdentity;
  user?: { id, email, firstName, lastName };
  error?: string;
}
```

---

## 6. Résultats Tests Contractuels

Exécution: `npx tsx scripts/test-contract-phase2.ts`

```
╔═══════════════════════════════════════════════════════════════╗
║           KOOMY — TESTS CONTRACTUELS PHASE 2                  ║
╚═══════════════════════════════════════════════════════════════╝

--- T1: Table user_identities structure ---
✅ T1.1 - Table user_identities exists
✅ T1.2 - All required columns present

--- T2: Enum identity_provider ---
✅ T2.1 - Enum identity_provider exists
✅ T2.2 - Enum has FIREBASE value
✅ T2.3 - Enum has LEGACY_KOOMY value

--- T3: Data integrity ---
✅ T3.1 - user_identities has data
✅ T3.2 - No orphaned identities
✅ T3.3 - No duplicate (provider, provider_id)

--- T4: Identity Resolver ---
✅ T4.1 - findUserByLegacyEmail works
✅ T4.2 - getUserIdentities works
✅ T4.3 - resolveIdentityWithFallback works
✅ T4.4 - Non-existent email returns not found

--- T5: Index verification ---
✅ T5.1 - unique_provider_identity_idx exists
✅ T5.2 - user_provider_idx exists

SUMMARY: 14/14 passed (100%)
```

---

## 7. Points de Compatibilité

### 7.1 Backward Compatibility

Le module `resolveIdentityWithFallback` assure la compatibilité arrière:
1. Cherche d'abord dans `user_identities` (nouveau modèle)
2. Si non trouvé, fallback vers `users.firebase_uid` (legacy)
3. Logs un warning si trouvé via legacy (pour monitoring migration)

### 7.2 Coexistence

Durant la période de transition:
- Nouvelles identités: écrites dans `user_identities` uniquement
- Identités existantes: disponibles via les deux chemins
- `users.firebase_uid` reste en lecture seule (pas de nouveaux writes)

---

## 8. Prochaines Étapes (Phase 2.4 - Cleanup)

1. Modifier le middleware d'auth pour utiliser `identityResolver`
2. Adapter les routes de login/register pour créer dans `user_identities`
3. Deprecate `users.firebase_uid` (add @deprecated JSDoc)
4. Monitoring des accès legacy vs new model
5. À terme: migration complète et suppression de `users.firebase_uid`

---

## 9. Conformité Contrat

| Règle | Statut |
|-------|--------|
| Modèle identité normalisé | ✅ Implémenté |
| Provider FIREBASE supporté | ✅ Enum créé |
| Provider LEGACY_KOOMY supporté | ✅ Enum créé |
| Unicité (provider, provider_id) | ✅ Index unique |
| Un user = plusieurs identités possible | ✅ 1:N relation |
| Résolution unifiée | ✅ identityResolver.ts |
| Backward compatibility | ✅ Fallback users.firebase_uid |

---

**Phase 2 TERMINÉE** — Modèle user_identities opérationnel.
