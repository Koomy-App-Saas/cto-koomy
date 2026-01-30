# REPORT: Platform IAM Phase 0 - Inventaire Factuel

**Date**: 2026-01-26
**Auteur**: Replit Agent
**Scope**: SaaS Owner Platform - Identity & Access Management V1

---

## 1. ÉTAT ACTUEL DE L'INFRASTRUCTURE IAM

### 1.1 Table Platform Users

❌ **INEXISTANTE** - Pas de table `platform_users` dédiée.

Les utilisateurs Platform sont stockés dans la table `users` existante avec distinction via le champ `globalRole`:

```typescript
// shared/schema.ts
export const userGlobalRoleEnum = pgEnum("user_global_role", [
  "platform_super_admin",
  "platform_support",
  "platform_commercial"
]);

export const users = pgTable("users", {
  id: varchar("id", { length: 50 }).primaryKey(),
  email: text("email").notNull().unique(),
  globalRole: userGlobalRoleEnum("global_role"), // null = community admin, set = platform admin
  isPlatformOwner: boolean("is_platform_owner").default(false), // root admin
  isActive: boolean("is_active").default(false), // email verification
  failedLoginAttempts: integer("failed_login_attempts").default(0),
  lockedUntil: timestamp("locked_until"),
  // ...
});
```

### 1.2 Rôles Existants

| Rôle | Description | Implémentation |
|------|-------------|----------------|
| `platform_super_admin` | Super administrateur plateforme | Enum DB + vérification backend |
| `platform_support` | Support client | Enum DB (non utilisé dans guards) |
| `platform_commercial` | Commercial | Enum DB (non utilisé dans guards) |
| `isPlatformOwner=true` | Root admin (non supprimable) | Champ booléen |

⚠️ **PROBLÈME IDENTIFIÉ**: Seul `platform_super_admin` est vérifié dans le code. Les rôles `platform_support` et `platform_commercial` existent mais ne sont pas utilisés pour le contrôle d'accès.

### 1.3 Sessions Platform

✅ **EXISTANTE** - Table `platform_sessions` avec cookies distincts:

```typescript
export const platformSessions = pgTable("platform_sessions", {
  id: varchar("id", { length: 50 }).primaryKey(),
  userId: varchar("user_id").references(() => users.id).notNull(),
  token: text("token").notNull().unique(),
  ipAddress: text("ip_address"),
  userAgent: text("user_agent"),
  expiresAt: timestamp("expires_at").notNull(), // 2 heures
  revokedAt: timestamp("revoked_at"),
  createdAt: timestamp("created_at").defaultNow().notNull()
});
```

### 1.4 Authentification Actuelle

**Mécanisme**: Email/Password + Session token (pas Firebase pour Platform)

**Flux de connexion** (`/api/platform/login`):
1. Vérification IP whitelist (France uniquement)
2. Lookup user par email
3. Vérification `globalRole === 'platform_super_admin'`
4. Validation password (bcrypt)
5. Création session token (2h expiry)
6. Audit log

**Endpoints existants**:
- `POST /api/platform/login` - Connexion
- `POST /api/platform/validate-session` - Validation token
- `POST /api/platform/renew-session` - Renouvellement
- `POST /api/platform/logout` - Déconnexion

### 1.5 Middleware/Guards Existants

✅ **Fonction existante** `verifyPlatformAdmin()`:

```typescript
const verifyPlatformAdmin = async (userId: string | undefined): Promise<{ valid: boolean; user?: any; error?: string }> => {
  if (!userId) {
    return { valid: false, error: "userId is required for platform admin operations" };
  }
  const user = await storage.getUser(userId);
  if (!user) {
    return { valid: false, error: "User not found" };
  }
  if (user.globalRole !== 'platform_super_admin') {
    return { valid: false, error: "Accès non autorisé - Réservé aux super administrateurs plateforme" };
  }
  return { valid: true, user };
};
```

⚠️ **LIMITES**:
- Vérifie UNIQUEMENT `platform_super_admin`
- Pas de gestion de permissions atomiques
- `userId` passé en query/body (pas dérivé du token de session)

### 1.6 Routes Platform Existantes

| Route | Method | Authorization | Description |
|-------|--------|---------------|-------------|
| `/api/platform/login` | POST | Public | Connexion |
| `/api/platform/logout` | POST | Token | Déconnexion |
| `/api/platform/validate-session` | POST | Token | Validation session |
| `/api/platform/renew-session` | POST | Token | Renouvellement |
| `/api/platform/audit-logs` | GET | Token + globalRole check | Logs audit |
| `/api/platform/all-communities` | GET | verifyPlatformAdmin | Toutes communautés |
| `/api/platform/plans` | GET/PATCH | verifyPlatformAdmin | Plans & defaults |
| `/api/platform/plans/:id` | PUT | verifyPlatformAdmin | Mise à jour plan |
| `/api/platform/communities/:id/overrides` | GET/PATCH | verifyPlatformAdmin | Overrides contrat |
| `/api/platform/communities/:id/full-access` | POST/DELETE | verifyPlatformAdmin | Full access VIP |
| `/api/platform/communities/:id/quota-limits` | GET/PATCH | verifyPlatformAdmin | Limites quotas |
| `/api/platform/communities/:id/white-label` | PATCH | verifyPlatformAdmin | Config WL |
| `/api/platform/communities/:id/create-owner-admin` | POST | verifyPlatformAdmin | Création admin |
| `/api/platform/communities/:id/details` | GET | verifyPlatformAdmin | Détails communauté |
| `/api/platform/full-access-communities` | GET | verifyPlatformAdmin | Liste full access |
| `/api/platform/metrics` | GET | verifyPlatformAdmin | Métriques |
| `/api/platform/revenue-*` | GET | verifyPlatformAdmin | Données revenus |
| `/api/platform/health/*` | GET | verifyPlatformAdmin | Santé système |
| `/api/platform/analytics/*` | GET | verifyPlatformAdmin | Analytics |
| `/api/platform/audit/contracts` | GET | verifyPlatformAdmin | Audit contrats |
| `/api/platform/contracts/preview` | GET | verifyPlatformAdmin | Preview contrat |

**Total**: ~35+ routes platform, toutes avec même niveau d'accès (super_admin).

### 1.7 Break-Glass

✅ **EXISTANT** - Endpoint Full Access VIP:

```typescript
app.post("/api/platform/communities/:id/full-access", async (req, res) => {
  // Requires: grantedBy, reason, expiresAt
  // Creates: fullAccessGrantedAt, fullAccessExpiresAt, fullAccessReason
});

app.delete("/api/platform/communities/:id/full-access", async (req, res) => {
  // Revokes full access
});
```

**Caractéristiques**:
- ✅ Raison obligatoire
- ✅ Durée limitée (expiresAt)
- ✅ Audit implicite (champs communauté)
- ❌ Pas de log audit dédié
- ❌ Pas de warning usage routinier

### 1.8 Audit Logs

✅ **EXISTANT** - Deux tables:

**1. `platform_audit_logs`** (actions générales):
```typescript
export const platformAuditLogs = pgTable("platform_audit_logs", {
  id, userId, action, targetType, targetId, details,
  ipAddress, userAgent, countryCode, success, errorMessage, createdAt
});
```

**2. `contract_audit_log`** (changements contrats):
```typescript
export const contractAuditLog = pgTable("contract_audit_log", {
  id, actorId, actorType, targetType, targetId,
  key, oldValue, newValue, reason, note, traceId, createdAt
});
```

### 1.9 Frontend (SaaS Owner Platform)

**Pages existantes**:
- `client/src/pages/platform/Login.tsx` - Écran connexion
- `client/src/pages/platform/SuperDashboard.tsx` - Dashboard principal (4562 lignes)

**Structure UI (Tabs)**:
| Tab | Description |
|-----|-------------|
| `overview` | Vue d'ensemble |
| `finances` | Données financières |
| `analytics` | Analytics |
| `clients` | Gestion clients |
| `users` | Utilisateurs |
| `plans` | Plans |
| `support` | Support |
| `emails` | Emails |
| `health` | Santé système |

⚠️ **PROBLÈME**: Aucun filtrage UI par permissions. Tous les tabs visibles pour tout utilisateur connecté.

---

## 2. POINTS DE CONFUSION IDENTIFIÉS

### 2.1 Mélange Platform/Product

| Problème | Impact |
|----------|--------|
| `users.globalRole` mélange platform et community | Confusion conceptuelle |
| Pas de table `platform_users` dédiée | Couplage fort |
| `isPlatformOwner` vs `globalRole` | Redondance/confusion |

### 2.2 Rôles Non-Fonctionnels

Les rôles `platform_support` et `platform_commercial` existent dans l'enum DB mais:
- ❌ Aucun guard ne les vérifie
- ❌ Aucune permission associée
- ❌ Login refuse tout sauf `platform_super_admin`

### 2.3 Authorization Incohérente

- Token session utilisé pour `/api/platform/audit-logs`
- `userId` query param utilisé pour autres routes
- Pas de dérivation systématique userId depuis token

---

## 3. DELTA MINIMAL V1

### 3.1 Ce qui existe et peut être réutilisé

| Élément | Réutilisable | Action |
|---------|--------------|--------|
| `users.globalRole` | ✅ OUI | Étendre enum |
| `platform_sessions` | ✅ OUI | Conserver |
| `verifyPlatformAdmin()` | ⚠️ PARTIEL | Transformer en `requirePlatformPermission()` |
| `platform_audit_logs` | ✅ OUI | Conserver |
| `contract_audit_log` | ✅ OUI | Conserver |
| Full Access VIP | ✅ OUI | Raccorder au nouveau modèle |

### 3.2 Ce qui manque

| Élément | Priorité | Approche V1 |
|---------|----------|-------------|
| Permissions atomiques | 🔴 HAUTE | Mapping code (Option A) |
| Rôles V1 complets | 🔴 HAUTE | Mise à jour enum + mapping |
| Middleware permission-based | 🔴 HAUTE | `requirePlatformPermission(perm)` |
| UI menu gating | 🟡 MOYENNE | Filtrage tabs par permissions |
| Audit raison obligatoire | 🟡 MOYENNE | Validation sur mutations |
| Break-glass audit dédié | 🟢 BASSE | Log dans `platform_audit_logs` |

### 3.3 Plan d'Implémentation V1

**Phase 1 - Modèle**:
1. Étendre `userGlobalRoleEnum` avec les 6 rôles V1
2. Créer mapping `PLATFORM_ROLE_PERMISSIONS` en code (Option A)
3. Définir les 14 permissions atomiques

**Phase 2 - Auth**:
1. Créer `requirePlatformAuth()` middleware (dérive userId du token)
2. Créer `requirePlatformPermission(permission)` middleware
3. Garantir séparation session platform/product

**Phase 3 - Guards**:
1. Appliquer guards sur toutes routes `/api/platform/*`
2. Mapper chaque route à sa permission requise

**Phase 4 - Audit**:
1. Ajouter champ `permission` dans logs
2. Exiger `reason` sur toutes mutations

**Phase 5 - UI**:
1. Filtrer tabs SuperDashboard par permissions
2. Afficher message clair si accès refusé

**Phase 6 - Break-Glass**:
1. Raccorder au nouveau modèle IAM
2. Ajouter audit log dédié

---

## 4. MATRICE RÔLES → PERMISSIONS V1 (CIBLE)

| Permission | OWNER | OPS | SUPPORT | FINANCE | SALES | READONLY |
|------------|-------|-----|---------|---------|-------|----------|
| platform.access | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| platform.users.read | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ |
| platform.users.write | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| platform.contracts.plans.read | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| platform.contracts.plans.write | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| platform.contracts.overrides.write | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| platform.audit.read | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ |
| platform.support.read | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ |
| platform.support.write | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ |
| platform.finance.read | ✅ | ❌ | ❌ | ✅ | ✅ | ❌ |
| platform.finance.write | ✅ | ❌ | ❌ | ✅ | ❌ | ❌ |
| platform.ops.health.read | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| platform.ops.logs.read | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| platform.ops.actions.write | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |

---

## 5. RISQUES ET CONTRAINTES

| Risque | Mitigation |
|--------|------------|
| Breaking change sur login | Garder `platform_super_admin` comme alias OWNER |
| Sessions existantes invalides | Migration graduelle |
| UI complexe à filtrer | Gating simple (hide/show tabs) |
| Performance guards multiples | Cache permissions en mémoire |

---

## 6. CONCLUSION

L'infrastructure existante fournit une base solide (sessions, audit, full-access). Le delta V1 est principalement:

1. **Mapping rôles → permissions** (code, ~100 lignes)
2. **Middleware permission-based** (~50 lignes)
3. **Application guards sur routes** (~35 routes)
4. **UI gating tabs** (~20 lignes)

**Estimation effort**: 2-3 heures pour V1 complet.

**Prêt pour Phase 1**: ✅ OUI
