# AUDIT POST-CONTRAT — Impact Identité & Onboarding

**Date:** 2026-01-22  
**Contrat de référence:** `docs/architecture/CONTRAT_IDENTITE_ONBOARDING_2026-01.md`  
**Méthode:** Analyse du code source uniquement (fact-based)

---

## 1. Inventaire factuel des surfaces & flux

### 1.1 Site Public (Self-Service)

| Critère | Valeur |
|---------|--------|
| **Routes login/register** | `/api/admin/register` |
| **Auth provider utilisé** | Firebase Auth (obligatoire) |
| **Token attendu** | Firebase ID Token (Bearer) |
| **Vérification** | `verifyFirebaseToken()` dans handler |
| **Fichier** | `server/routes.ts:2516` |
| **Conforme au contrat** | ✅ OUI |

### 1.2 Backoffice Standard (Admin)

| Critère | Valeur |
|---------|--------|
| **Routes login** | `/api/admin/login` |
| **Auth provider utilisé** | Legacy (email/password) avec fallback Firebase |
| **Token attendu** | Session token legacy OU Firebase ID Token |
| **Vérification** | `bcrypt.compare()` dans handler |
| **Fichier** | `server/routes.ts:2271` |
| **Conforme au contrat** | ⚠️ PARTIELLEMENT (login legacy autorise les deux) |

### 1.3 App Membre Standard (Mobile)

| Critère | Valeur |
|---------|--------|
| **Routes login/register** | `/api/accounts/login`, `/api/accounts/register` |
| **Auth provider utilisé** | Legacy (email/password) OU Firebase |
| **Token attendu** | Session token (`accountId:timestamp:random`) OU Firebase ID Token |
| **Vérification** | `verifyPassword()` legacy, `attachAuthContext` middleware pour Firebase |
| **Fichier** | `server/routes.ts:1650`, `server/middlewares/attachAuthContext.ts` |
| **Conforme au contrat** | ⚠️ PARTIELLEMENT (deux modes coexistent) |

### 1.4 App Admin Standard (Mobile Admin)

| Critère | Valeur |
|---------|--------|
| **Routes login** | Partage `/api/admin/login` avec backoffice |
| **Auth provider** | Legacy (email/password) |
| **Conforme au contrat** | ⚠️ PARTIELLEMENT |

### 1.5 Backoffice White-Label

| Critère | Valeur |
|---------|--------|
| **Routes login** | `/api/admin/login` (partagé) |
| **Auth provider utilisé** | Legacy (email/password) |
| **Guard WL explicite** | ❌ ABSENT - pas de vérification `community.whiteLabel` au login |
| **Conforme au contrat** | ⚠️ RISQUE (pas de guard anti-Firebase) |

### 1.6 App White-Label (Membre/Admin)

| Critère | Valeur |
|---------|--------|
| **Routes login** | `/api/accounts/login` (partagé) |
| **Auth provider utilisé** | Legacy (email/password) |
| **Guard WL explicite** | ❌ ABSENT |
| **Conforme au contrat** | ⚠️ RISQUE |

### 1.7 SaaS Owner Platform

| Critère | Valeur |
|---------|--------|
| **Routes login** | `/api/platform/login` |
| **Auth provider utilisé** | Legacy (email/password) UNIQUEMENT |
| **Token attendu** | Platform session token |
| **Vérification** | `bcrypt.compare()`, session dans `platform_sessions` |
| **Guards** | IP whitelist (France), rate limiting, email verification |
| **Fichier** | `server/routes.ts:3188` |
| **Conforme au contrat** | ✅ OUI (aucun Firebase) |

---

## 2. Matrice Endpoints vs Contrat

| Endpoint | Surface(s) | Auth dans le code | Auth contrat | Conforme | Commentaire |
|----------|------------|-------------------|--------------|----------|-------------|
| `POST /api/admin/register` | Site public | Firebase ONLY | Firebase ONLY | ✅ OUI | Conforme |
| `POST /api/admin/login` | Backoffice std + WL | Legacy (bcrypt) | Standard=Firebase, WL=Legacy | ⚠️ NON | Login legacy pour standard viole contrat |
| `POST /api/accounts/login` | Mobile std + WL | Legacy (bcrypt) | Standard=Firebase, WL=Legacy | ⚠️ NON | Mélange implicite |
| `POST /api/accounts/register` | Mobile std | Legacy | Standard=Firebase | ⚠️ NON | Devrait être Firebase |
| `POST /api/platform/login` | SaaS Owner | Legacy | Legacy | ✅ OUI | Conforme |
| `GET /api/white-label/config` | WL detection | N/A (public) | N/A | ✅ OUI | Public, pas d'auth |
| `PATCH /api/platform/communities/:id/white-label` | SaaS Owner | Platform session | Legacy | ✅ OUI | Conforme |
| `POST /api/wl/admin/create` | WL provisioning | INCONNU | Legacy | INCONNU | Non trouvé dans le repo |

---

## 3. Violations du contrat (liste priorisée)

### VIOL-001: Absence de guard Firebase-interdit sur routes WL

| Critère | Valeur |
|---------|--------|
| **Gravité** | CRITIQUE |
| **Contrat** | WL → Firebase STRICTEMENT INTERDIT |
| **Code actuel** | Aucun guard ne vérifie `community.whiteLabel` avant d'autoriser Firebase |
| **Fichiers** | `server/routes.ts` (login handlers), `server/middlewares/attachAuthContext.ts` |
| **Reproduction** | Un compte WL pourrait techniquement se voir assigner un `firebase_uid` via backfill |
| **Risque** | Confusion d'identité, violation contrat B2B, sécurité |

### VIOL-002: Login admin standard autorise Legacy au lieu de Firebase

| Critère | Valeur |
|---------|--------|
| **Gravité** | ÉLEVÉ |
| **Contrat** | Standard → Firebase ONLY |
| **Code actuel** | `/api/admin/login` accepte email/password legacy pour tous |
| **Fichier** | `server/routes.ts:2271` |
| **Reproduction** | Admin standard avec password peut se connecter sans Firebase |
| **Risque** | Incohérence auth, contournement Firebase |

### VIOL-003: Register mobile utilise Legacy au lieu de Firebase

| Critère | Valeur |
|---------|--------|
| **Gravité** | ÉLEVÉ |
| **Contrat** | Standard → Firebase ONLY pour membres |
| **Code actuel** | `/api/accounts/register` crée compte avec email/password |
| **Fichier** | `server/routes.ts:1585` |
| **Reproduction** | Membre standard peut s'inscrire sans Firebase |
| **Risque** | Identité non liée à Firebase, fragmentation |

### VIOL-004: Backfill Firebase UID sur comptes WL potentiel

| Critère | Valeur |
|---------|--------|
| **Gravité** | CRITIQUE |
| **Contrat** | WL → aucun `firebase_uid` |
| **Code actuel** | `attachAuthContext.ts:116-130` backfill `provider_id` par email sans vérifier WL |
| **Fichier** | `server/middlewares/attachAuthContext.ts` |
| **Reproduction** | Un utilisateur WL pourrait avoir son compte backfillé si même email utilisé avec Firebase ailleurs |
| **Risque** | Contamination identité WL, violation contrat B2B |

### VIOL-005: Unicité email globale sans scope tenant

| Critère | Valeur |
|---------|--------|
| **Gravité** | MOYEN |
| **Contrat** | Séparation stricte WL vs Standard |
| **Code actuel** | `accounts.email` et `users.email` sont UNIQUE globalement |
| **Fichier** | `shared/schema.ts:161, 351` |
| **Reproduction** | Un email ne peut exister que dans un univers (standard OU WL) |
| **Risque** | Collision emails entre univers, pas de multi-tenant pur |

---

## 4. Dette & couplages résiduels

### 4.1 Firebase supposé "par défaut"

| Fichier | Problème |
|---------|----------|
| `attachAuthContext.ts` | Tente de résoudre Firebase sur TOUTES les requêtes, y compris WL |
| `requireFirebaseAuth.ts` | Middleware disponible mais non tenant-aware |

### 4.2 Legacy et Firebase partagent des tables

| Table | Colonnes partagées | Problème |
|-------|-------------------|----------|
| `accounts` | `email`, `provider_id`, `auth_provider` | Pas de séparation WL vs Standard |
| `users` | `email`, `firebase_uid` | Pas de flag `is_wl_user` |

### 4.3 Unicité email globale

| Table | Contrainte | Impact |
|-------|------------|--------|
| `accounts` | `email UNIQUE` | Collision cross-tenant |
| `users` | `email UNIQUE` | Collision cross-tenant |

### 4.4 Absence de guard tenant-type

Les handlers suivants ne vérifient PAS `community.whiteLabel` au début:
- `/api/admin/login`
- `/api/accounts/login`
- `/api/accounts/register`
- `attachAuthContext` middleware

---

## 5. État actuel des schémas DB/ORM

### 5.1 Table `accounts` (mobile users)

```
accounts (
  id VARCHAR(50) PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  first_name TEXT,
  last_name TEXT,
  avatar TEXT,
  auth_provider TEXT DEFAULT 'email',  -- "email" | "google" | "firebase"
  provider_id TEXT,                      -- Firebase UID when auth_provider='firebase'
  created_at TIMESTAMP,
  updated_at TIMESTAMP
)
```

### 5.2 Table `users` (admin users)

```
users (
  id VARCHAR(50) PRIMARY KEY,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  password TEXT,                         -- nullable (Firebase users)
  phone TEXT,
  avatar TEXT,
  global_role user_global_role_enum,     -- 'platform_super_admin' | null
  is_platform_owner BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT false,
  email_verified_at TIMESTAMP,
  failed_login_attempts INTEGER DEFAULT 0,
  locked_until TIMESTAMP,
  firebase_uid TEXT UNIQUE,              -- Firebase Auth UID
  created_at TIMESTAMP
)
```

### 5.3 Table `communities`

```
communities (
  ...
  white_label BOOLEAN DEFAULT false,     -- true = WL community
  white_label_tier TEXT,                 -- "basic" | "standard" | "premium"
  white_label_included_members INTEGER,
  white_label_max_members_soft_limit INTEGER,
  ...
)
```

### 5.4 Enum `subscription_status`

```sql
CREATE TYPE subscription_status AS ENUM (
  'trialing',   -- ✅ Présent
  'active',
  'past_due',
  'canceled'
);
```

**Note:** L'enum contient `trialing` - conforme au contrat (pas de `pending`).

### 5.5 Champs trial

| Colonne | Table | Type |
|---------|-------|------|
| `subscription_status` | `communities` | `subscription_status` enum |
| `trial_ends_at` | `communities` | `TIMESTAMP` |

### 5.6 Champ `auth_mode` explicite

**❌ N'EXISTE PAS** - Le mode d'auth est déduit de `community.white_label` flag uniquement.

---

## 6. Plan de correction (3 options)

### Option A — Patch rapide (stabilité immédiate)

**Objectif:** Empêcher les violations critiques VIOL-001 et VIOL-004

**Actions:**
1. Ajouter guard dans `attachAuthContext.ts`:
   ```typescript
   // Si account appartient à communauté WL → SKIP backfill Firebase
   if (account && isWhiteLabelAccount(account)) {
     console.warn("[AUTH] WL account - Firebase backfill BLOCKED");
     return next();
   }
   ```
2. Ajouter early-return dans `/api/admin/login`:
   ```typescript
   const membership = memberships[0];
   const community = await storage.getCommunity(membership.communityId);
   if (community?.whiteLabel && firebaseTokenProvided) {
     return res.status(403).json({ error: "WL_FIREBASE_FORBIDDEN" });
   }
   ```

| Critère | Valeur |
|---------|--------|
| **Effort** | S (1-2 jours) |
| **Risque** | Faible |
| **Impact** | Bloque violations critiques |
| **Débloque** | Conformité contrat B2B |

---

### Option B — Fix propre (réduction dette)

**Objectif:** Séparer clairement les mondes standard vs WL vs owner

**Actions:**
1. Créer helper `getAuthModeForCommunity(communityId)`:
   ```typescript
   async function getAuthModeForCommunity(communityId: string): Promise<'firebase' | 'legacy'> {
     const community = await storage.getCommunity(communityId);
     return community?.whiteLabel ? 'legacy' : 'firebase';
   }
   ```
2. Créer middleware `requireTenantAuth(mode)`:
   - Vérifie le mode attendu vs mode fourni
   - Rejette si mismatch
3. Migrer progressivement les routes vers ce middleware
4. Ajouter index composite `(email, community_id)` pour scope email

| Critère | Valeur |
|---------|--------|
| **Effort** | M (1 semaine) |
| **Risque** | Moyen (changements middleware) |
| **Impact** | Séparation propre des mondes |
| **Débloque** | Évolutivité, maintenabilité |

---

### Option C — Fix scalable (architecture cible)

**Objectif:** Modèle multi-auth tenant-aware durable

**Actions:**
1. Ajouter colonne `auth_mode` sur `communities`:
   ```sql
   ALTER TABLE communities ADD COLUMN auth_mode TEXT DEFAULT 'firebase';
   -- CHECK (auth_mode IN ('firebase', 'legacy'))
   UPDATE communities SET auth_mode = 'legacy' WHERE white_label = true;
   ```
2. Créer `AuthPolicyService`:
   ```typescript
   class AuthPolicyService {
     static getRequiredAuth(tenant: Tenant): AuthMode;
     static validateToken(req: Request, tenant: Tenant): ValidationResult;
     static enforcePolicy(req: Request, tenant: Tenant): void | throws;
   }
   ```
3. Centraliser toutes les routes auth via policy
4. Ajouter tests d'intégration contractuels automatisés
5. Scoper unicité email par `(email, tenant_type)` ou `(email, community_id)`

| Critère | Valeur |
|---------|--------|
| **Effort** | L (2-3 semaines) |
| **Risque** | Élevé (migration, breaking changes) |
| **Impact** | Architecture durable, testable |
| **Débloque** | Multi-tenant pur, audit automatisé |

---

## 7. Tests à ajouter (contrat = tests)

### Checklist tests d'intégration

| Test | Type | Attendu |
|------|------|---------|
| `test_standard_register_firebase_creates_trial` | Integration | 201, `subscription_status=trialing`, `trial_ends_at=+14j` |
| `test_standard_register_no_stripe_call` | Integration | Aucun appel Stripe pendant register |
| `test_wl_login_legacy_only` | Integration | 200 avec email/password |
| `test_wl_login_firebase_rejected` | Integration | 403 `WL_FIREBASE_FORBIDDEN` |
| `test_wl_account_no_firebase_backfill` | Integration | `provider_id` reste NULL |
| `test_saas_owner_legacy_only` | Integration | 200 avec email/password |
| `test_saas_owner_firebase_rejected` | Integration | 403 ou 401 |
| `test_standard_vs_wl_email_collision` | Unit | Comportement défini si même email existe dans les deux univers |
| `test_contract_invariant_wl_no_firebase_uid` | DB | `SELECT * FROM users WHERE firebase_uid IS NOT NULL AND community IS WL` = 0 |

### Tests contractuels automatisés (Option C)

```typescript
describe('Identity Contract', () => {
  it('WL community must reject Firebase auth', async () => {
    const wlCommunity = await createWLCommunity();
    const firebaseToken = await getFirebaseToken();
    const res = await request(app)
      .post('/api/admin/login')
      .set('Authorization', `Bearer ${firebaseToken}`)
      .send({ communityId: wlCommunity.id });
    expect(res.status).toBe(403);
    expect(res.body.code).toBe('FORBIDDEN_CONTRACT');
  });
});
```

---

## 8. Conclusion

| Catégorie | Statut |
|-----------|--------|
| **Register admin standard** | ✅ Conforme (Firebase obligatoire) |
| **SaaS Owner Platform** | ✅ Conforme (Legacy uniquement) |
| **Trial 14j sans Stripe** | ✅ Conforme |
| **Login admin standard** | ⚠️ Non conforme (Legacy autorisé) |
| **Login/Register mobile** | ⚠️ Non conforme (Legacy par défaut) |
| **Guards WL anti-Firebase** | ❌ ABSENT - violation critique |
| **Backfill Firebase sur WL** | ❌ POSSIBLE - violation critique |

**Recommandation:** Implémenter **Option A** immédiatement pour bloquer les violations critiques, puis planifier **Option B** ou **C** selon roadmap.
