# KOOMY — AUTH Phase 3 — RBAC & Guards (Backend)

**Date :** 2026-01-21  
**Domain :** AUTH  
**Doc Type :** PROCEDURE  
**Scope :** Backend (Replit Sandbox)  
**Statut :** Finalisé (review PASS)  
**Pré-requis :** Phase 2.5 validée

---

## Objectif

1. Centraliser l'identité via `req.authContext`
2. Mapping stable Firebase → KOOMY user via `firebase_uid`
3. Guards backend testables : `requireFirebaseAuth`, `requireMembership`, `requireRole`
4. Application progressive sur routes sensibles

---

## Composants Implémentés

### 1. Schéma DB — Colonne `firebase_uid`

```sql
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS firebase_uid TEXT UNIQUE;
```

Ajouté dans `shared/schema.ts` :
```typescript
firebaseUid: text("firebase_uid").unique(), // Firebase Auth UID for mapping
```

### 2. Storage — Nouvelles méthodes

| Méthode | Description |
|---------|-------------|
| `getAccountByFirebaseUid(uid)` | Lookup par Firebase UID |
| `updateAccountFirebaseUid(id, uid)` | Backfill firebase_uid |

### 3. Middleware — `attachAuthContext`

Fichier : `server/middlewares/attachAuthContext.ts`

Enrichit `req.authContext` avec :
```typescript
interface AuthContext {
  firebase: { uid, email };
  koomyUser: KoomyUser | null;
  memberships: KoomyMembership[];
}
```

**Comportement :** 
- Ne bloque PAS si token absent (pour routes publiques)
- Lookup par `firebase_uid` en priorité
- Si non trouvé + email disponible : lookup par email + backfill automatique `firebase_uid`
- Enregistré globalement dans `server/index.ts` avant les routes

### 4. Guards — `server/middlewares/guards.ts`

| Guard | Code erreur | Description |
|-------|-------------|-------------|
| `requireFirebaseAuth` | 401 `auth_required` | Token Firebase valide requis |
| `requireMembership(param)` | 403 `membership_required` | Membership dans communauté requis |
| `requireRole(minRole)` | 403 `insufficient_role` | Rôle minimum requis |
| `requireAdmin` | 403 `insufficient_role` | Rôle admin ou owner |
| `requireOwner` | 403 `insufficient_role` | Rôle owner uniquement |

**Hiérarchie des rôles :**
```
OWNER (100) > SUPER_ADMIN (90) > ADMIN (50) > MANAGER (30) > DELEGATE (20) > MEMBER (10)
```

### 5. Endpoint — `/api/auth/me` (Phase 3)

**Comportement mis à jour :**
1. Lookup par `firebase_uid` (primaire)
2. Si non trouvé + email disponible : lookup par email + backfill `firebase_uid`
3. Retour standardisé

---

## Variables d'Environnement

| Variable | Description |
|----------|-------------|
| `FIREBASE_PROJECT_ID` | ID projet Firebase (koomy-sandbox) |
| `KOOMY_ENV` | Environnement (sandbox/production) |

---

## Application Progressive (TODO)

Routes à protéger par priorité :

| Route | Action | Niveau | Risque |
|-------|--------|--------|--------|
| `POST /api/communities/:id/admins` | WRITE | OWNER | Élevé |
| `DELETE /api/memberships/:id` | WRITE | ADMIN | Élevé |
| `PATCH /api/communities/:id` | WRITE | ADMIN | Moyen |
| `POST /api/news` | WRITE | ADMIN | Moyen |
| `GET /api/communities/:id/members` | READ | MEMBER | Faible |

---

## Fichiers Modifiés

| Fichier | Modification |
|---------|-------------|
| `shared/schema.ts` | Ajout `firebaseUid` dans `accounts` |
| `server/storage.ts` | Méthodes `getAccountByFirebaseUid`, `updateAccountFirebaseUid` |
| `server/middlewares/attachAuthContext.ts` | Nouveau middleware + fallback email + backfill |
| `server/middlewares/guards.ts` | Guards RBAC |
| `server/routes.ts` | `/api/auth/me` mis à jour Phase 3 |
| `server/index.ts` | Enregistrement global `attachAuthContext` |

---

## Résultat d'Exécution

- **Schéma DB :** `firebase_uid` ajouté ✓
- **Middleware attachAuthContext :** Livré ✓ (avec fallback email + backfill)
- **Guards :** Livrés ✓
- **Endpoint /api/auth/me :** Mis à jour ✓
- **Enregistrement global :** `server/index.ts` ✓
- **Application routes :** En attente (progressif)

---

## Prochaines Étapes

- Application progressive des guards sur routes sensibles
- Tests E2E avec guards
- Déploiement sandbox → production
