# P3.2 - Inventaire des Points de Refus

**Date:** 2026-01-26  
**Scope:** Routes identifiées dans AUDIT_admin_quota_enforcement_paths.md  
**Status:** AUDIT EN COURS

---

## 1. Routes Auditées

| # | Route | File:Line |
|---|-------|-----------|
| 1 | `POST /api/admin/join` | server/routes.ts:3064 |
| 2 | `POST /api/admin/join-with-credentials` | server/routes.ts:3238 |
| 3 | `POST /api/communities/:id/admins` | server/routes.ts:~4700 |
| 4 | `PATCH /api/memberships/:id` | server/routes.ts:5971 |

---

## 2. Inventaire Détaillé

### 2.1 POST /api/admin/join (3064-3234)

| Path | Layer | Condition | Code Actuel | ProductError? | Message UX | CTA | TraceId? | Action |
|------|-------|-----------|-------------|---------------|------------|-----|----------|--------|
| L3070 | API | !joinCode | 400 `MISSING_JOIN_CODE` | ❌ NON | "Code d'invitation requis" | ∅ | ✅ | ALIGN |
| L3078 | API | code.length !== 8 | 400 `INVALID_CODE_LENGTH` | ❌ NON | "Le code doit contenir exactement 8 caractères" | ∅ | ✅ | ALIGN |
| L3087 | API | !firebaseUser?.email | 401 `FIREBASE_REQUIRED` | ❌ NON | "Authentification Firebase requise" | ∅ | ✅ | ALIGN |
| L3107 | API | !community | 404 `INVALID_JOIN_CODE` | ❌ NON | "Code d'invitation invalide ou expiré" | ∅ | ✅ | ALIGN |
| L3117 | API | community.whiteLabel | 403 `FORBIDDEN_CONTRACT` | ❌ NON | "Ce mode de rattachement n'est pas supporté" | ∅ | ✅ | ALIGN |
| L3128 | API | !adminQuotaCheck.allowed | 403 `PLAN_ADMIN_QUOTA_EXCEEDED` | ❌ NON | "Quota d'administrateurs atteint" | ∅ | ✅ | **ALIGN (CTA UPGRADE)** |
| L3155 | API | existingMembership | 409 `ALREADY_MEMBER` | ❌ NON | "Vous êtes déjà membre" | ∅ | ✅ | ALIGN |
| L3227 | API | catch(error) | 500 ∅ | ❌ NON | "Échec du rattachement" | ∅ | ✅ | ALIGN |

### 2.2 POST /api/admin/join-with-credentials (3238-3430)

| Path | Layer | Condition | Code Actuel | ProductError? | Message UX | CTA | TraceId? | Action |
|------|-------|-----------|-------------|---------------|------------|-----|----------|--------|
| L3244 | API | !joinCode/email/password | 400 `MISSING_FIELDS` | ❌ NON | "Code, email et mot de passe requis" | ∅ | ✅ | ALIGN |
| L3253 | API | code.length !== 8 | 400 `INVALID_CODE_LENGTH` | ❌ NON | "Le code doit contenir exactement 8 caractères" | ∅ | ✅ | ALIGN |
| L3276 | API | !community | 404 `INVALID_JOIN_CODE` | ❌ NON | "Code d'invitation invalide ou expiré" | ∅ | ✅ | ALIGN |
| L3286 | API | community.whiteLabel | 403 `FORBIDDEN_CONTRACT` | ❌ NON | "Ce mode de rattachement n'est pas supporté" | ∅ | ✅ | ALIGN |
| L3297 | API | !adminQuotaCheck.allowed | 403 `PLAN_ADMIN_QUOTA_EXCEEDED` | ❌ NON | "Quota d'administrateurs atteint" | ∅ | ✅ | **ALIGN (CTA UPGRADE)** |
| L3317 | API | !user.password | 401 `INVALID_CREDENTIALS` | ❌ NON | "Mot de passe incorrect" | ∅ | ✅ | ALIGN |
| L3326 | API | !bcrypt.compare | 401 `INVALID_CREDENTIALS` | ❌ NON | "Mot de passe incorrect" | ∅ | ✅ | ALIGN |
| L3343 | API | existingMembership | 409 `ALREADY_MEMBER` | ❌ NON | "Vous êtes déjà membre" | ∅ | ✅ | ALIGN |
| L3423 | API | catch(error) | 500 ∅ | ❌ NON | "Échec du rattachement" | ∅ | ✅ | ALIGN |

### 2.3 POST /api/communities/:communityId/admins (~4700-4950)

| Path | Layer | Condition | Code Actuel | ProductError? | Message UX | CTA | TraceId? | Action |
|------|-------|-----------|-------------|---------------|------------|-----|----------|--------|
| L4768 | API | !callerMembership | 403 ∅ | ❌ NON | "Vous n'êtes pas membre de cette communauté" | ∅ | ✅ | ALIGN |
| L4780 | API | !isOwner | 403 `OWNER_REQUIRED` | ❌ NON | "Seul le propriétaire peut créer des administrateurs" | ∅ | ✅ | ALIGN |
| L4792 | API | !adminQuotaCheck.allowed | 403 `PLAN_ADMIN_QUOTA_EXCEEDED` | ❌ NON | "Quota d'administrateurs atteint (x/y)" | ∅ | ✅ | **ALIGN (CTA UPGRADE)** |
| L4813 | API | !email valid | 400 `INVALID_EMAIL` | ❌ NON | "Une adresse email valide est requise" | ∅ | ✅ | ALIGN |
| L4821 | API | !firstName | 400 `FIRST_NAME_REQUIRED` | ❌ NON | "Le prénom est requis" | ∅ | ✅ | ALIGN |
| L4829 | API | !lastName | 400 `LAST_NAME_REQUIRED` | ❌ NON | "Le nom est requis" | ∅ | ✅ | ALIGN |
| L4850 | API | permissions.length === 0 | 400 `PERMISSIONS_REQUIRED` | ❌ NON | "Au moins une permission est requise" | ∅ | ✅ | ALIGN |
| L4865 | API | !VALID_SCOPES.includes | 400 `INVALID_SECTION_SCOPE` | ❌ NON | "Périmètre invalide" | ∅ | ✅ | ALIGN |

### 2.4 PATCH /api/memberships/:id (5971-6100)

| Path | Layer | Condition | Code Actuel | ProductError? | Message UX | CTA | TraceId? | Action |
|------|-------|-----------|-------------|---------------|------------|-----|----------|--------|
| L5974 | API | !koomyUser | 401 ∅ | ❌ NON | "auth_required" | ∅ | ❌ | ALIGN |
| L5984 | API | !currentMembership | 404 ∅ | ❌ NON | "Membership not found" | ∅ | ❌ | ALIGN |
| L5992 | API | !callerMembership | 403 ∅ | ❌ NON | "membership_required" | ∅ | ❌ | ALIGN |
| L5996 | API | !isAdmin | 403 ∅ | ❌ NON | "insufficient_role" | ∅ | ❌ | ALIGN |
| L6002 | API | role change attempted | 400 `ROLE_CHANGE_NOT_ALLOWED` | ❌ NON | "Le changement de rôle doit passer par les endpoints dédiés" | ∅ | ❌ | ALIGN |
| L6027 | API | !communitySection | 400 ∅ | ❌ NON | "Section invalide" | ∅ | ❌ | ALIGN |
| L6049 | API | !plan | 400 ∅ | ❌ NON | "Formule introuvable" | ∅ | ❌ | ALIGN |
| L6055 | API | plan.communityId !== communityId | 400 ∅ | ❌ NON | "Formule invalide" | ∅ | ❌ | ALIGN |
| L6061 | API | !plan.isActive | 400 ∅ | ❌ NON | "Formule inactive" | ∅ | ❌ | ALIGN |

---

## 3. Résumé de Conformité

| Route | Total Refus | ProductError? | Conformes | Non-Conformes |
|-------|-------------|---------------|-----------|---------------|
| POST /api/admin/join | 8 | 0 | 0 | **8** |
| POST /api/admin/join-with-credentials | 9 | 0 | 0 | **9** |
| POST /api/communities/:id/admins | 8 | 0 | 0 | **8** |
| PATCH /api/memberships/:id | 9 | 0 | 0 | **9** |
| **TOTAL** | **34** | **0** | **0** | **34** |

---

## 4. Priorité d'Alignement

### 4.1 Haute Priorité (CTA UPGRADE requis)

| Route | Line | Code | Action |
|-------|------|------|--------|
| /api/admin/join | 3128 | PLAN_ADMIN_QUOTA_EXCEEDED | → makeQuotaExceededError |
| /api/admin/join-with-credentials | 3297 | PLAN_ADMIN_QUOTA_EXCEEDED | → makeQuotaExceededError |
| /api/communities/:id/admins | 4792 | PLAN_ADMIN_QUOTA_EXCEEDED | → makeQuotaExceededError |

### 4.2 Priorité Standard

Tous les autres refus : remplacer par le helper ProductError correspondant.

---

## 5. Mapping Code → Helper

| Code Actuel | HTTP | Helper ProductError |
|-------------|------|---------------------|
| `MISSING_JOIN_CODE` | 400 | makeValidationError |
| `INVALID_CODE_LENGTH` | 400 | makeValidationError |
| `FIREBASE_REQUIRED` | 401 | makeAuthRequiredError |
| `INVALID_JOIN_CODE` | 404 | makeNotFoundError |
| `FORBIDDEN_CONTRACT` | 403 | makeForbiddenError |
| `PLAN_ADMIN_QUOTA_EXCEEDED` | 403 | makeQuotaExceededError |
| `ALREADY_MEMBER` | 409 | makeValidationError (conflict) |
| `OWNER_REQUIRED` | 403 | makeForbiddenError |
| `INVALID_EMAIL` | 400 | makeValidationError |
| `FIRST_NAME_REQUIRED` | 400 | makeValidationError |
| `LAST_NAME_REQUIRED` | 400 | makeValidationError |
| `PERMISSIONS_REQUIRED` | 400 | makeValidationError |
| `INVALID_SECTION_SCOPE` | 400 | makeValidationError |
| `INVALID_CREDENTIALS` | 401 | makeAuthRequiredError |
| `ROLE_CHANGE_NOT_ALLOWED` | 400 | makeValidationError |
| `auth_required` | 401 | makeAuthRequiredError |
| `membership_required` | 403 | makeForbiddenError |
| `insufficient_role` | 403 | makeForbiddenError |
| ∅ (500) | 500 | makeServerError |

---

**Fin de l'Inventaire**
