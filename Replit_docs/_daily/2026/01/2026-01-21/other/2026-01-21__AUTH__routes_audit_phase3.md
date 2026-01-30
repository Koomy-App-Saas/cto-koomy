# KOOMY — AUTH Phase 3 — Audit des Routes API

**Date :** 2026-01-21  
**Domain :** AUTH  
**Doc Type :** AUDIT  
**Scope :** Backend (Sandbox)  
**Statut :** Finalisé

---

## Légende

| Niveau | Description |
|--------|-------------|
| PUBLIC | Aucune authentification requise |
| AUTH | Token Firebase valide requis |
| MEMBER | Membership dans la communauté cible requis |
| ADMIN | Rôle admin ou owner dans la communauté requis |
| OWNER | Owner de la communauté uniquement |
| PLATFORM | Admin plateforme (hors scope Phase 3) |

| Risque | Description |
|--------|-------------|
| Faible | Lecture de données, pas d'impact sur la sécurité |
| Moyen | Modification de données utilisateur propres |
| Élevé | Modification de rôles, admins, données sensibles |
| Critique | Paiements, suppression, escalade de privilèges |

---

## Routes Critiques (Lot 1 - Phase 3)

### Gestion Admins / Rôles

| Route | Méthode | Type | Niveau Requis | Risque | Action Phase 3 |
|-------|---------|------|---------------|--------|----------------|
| `/api/communities/:communityId/admins` | POST | WRITE | OWNER | Critique | ✓ Protéger |
| `/api/memberships/:id` | DELETE | WRITE | ADMIN | Critique | ✓ Protéger |
| `/api/memberships/:id` | PATCH | WRITE | ADMIN | Élevé | ✓ Protéger |
| `/api/memberships/:id/regenerate-code` | POST | WRITE | ADMIN | Moyen | ✓ Protéger |

### Gestion Communauté

| Route | Méthode | Type | Niveau Requis | Risque | Action Phase 3 |
|-------|---------|------|---------------|--------|----------------|
| `/api/communities` | POST | WRITE | AUTH | Élevé | ✓ Protéger |
| `/api/communities/:id` | PUT | WRITE | ADMIN | Élevé | ✓ Protéger |

### Sections / Catégories

| Route | Méthode | Type | Niveau Requis | Risque | Action Phase 3 |
|-------|---------|------|---------------|--------|----------------|
| `/api/sections` | POST | WRITE | ADMIN | Moyen | ✓ Protéger |
| `/api/communities/:communityId/sections/:sectionId` | PATCH | WRITE | ADMIN | Moyen | ✓ Protéger |
| `/api/communities/:communityId/sections/:sectionId` | DELETE | WRITE | ADMIN | Moyen | ✓ Protéger |
| `/api/communities/:communityId/categories` | POST | WRITE | ADMIN | Moyen | ✓ Protéger |
| `/api/communities/:communityId/categories/:categoryId` | PATCH | WRITE | ADMIN | Moyen | ✓ Protéger |
| `/api/communities/:communityId/categories/:categoryId` | DELETE | WRITE | ADMIN | Moyen | ✓ Protéger |

---

## Routes Hors Scope Phase 3

### Paiements / Billing (NE PAS TOUCHER)

| Route | Méthode | Type | Niveau Requis | Risque | Raison exclusion |
|-------|---------|------|---------------|--------|------------------|
| `/api/payments/*` | ALL | WRITE | Varié | Critique | Webhooks Stripe |
| `/api/billing/*` | ALL | WRITE | Varié | Critique | Subscriptions |
| `/api/collections/*` | ALL | WRITE | Varié | Critique | Collectes |

### Platform Admin (Authentification séparée)

| Route | Méthode | Type | Niveau Requis | Risque | Raison exclusion |
|-------|---------|------|---------------|--------|------------------|
| `/api/platform/*` | ALL | Varié | PLATFORM | Critique | Auth séparée |

### Routes Publiques

| Route | Méthode | Type | Niveau Requis | Risque |
|-------|---------|------|---------------|--------|
| `/api/health` | GET | READ | PUBLIC | Faible |
| `/api/env` | GET | READ | PUBLIC | Faible |
| `/api/version` | GET | READ | PUBLIC | Faible |
| `/api/plans/public` | GET | READ | PUBLIC | Faible |
| `/api/white-label/config` | GET | READ | PUBLIC | Faible |
| `/api/whitelabel/by-host` | GET | READ | PUBLIC | Faible |
| `/api/accounts/register` | POST | WRITE | PUBLIC | Moyen |
| `/api/accounts/login` | POST | WRITE | PUBLIC | Moyen |
| `/api/admin/login` | POST | WRITE | PUBLIC | Moyen |
| `/api/admin/register` | POST | WRITE | PUBLIC | Moyen |
| `/api/memberships/claim` | POST | WRITE | PUBLIC | Moyen |
| `/api/memberships/register-and-claim` | POST | WRITE | PUBLIC | Moyen |

### Routes Lecture (Lower Priority)

| Route | Méthode | Type | Niveau Requis | Risque |
|-------|---------|------|---------------|--------|
| `/api/communities/:communityId/members` | GET | READ | MEMBER | Faible |
| `/api/communities/:communityId/news` | GET | READ | MEMBER | Faible |
| `/api/communities/:communityId/events` | GET | READ | MEMBER | Faible |
| `/api/communities/:communityId/sections` | GET | READ | MEMBER | Faible |
| `/api/communities/:communityId/dashboard` | GET | READ | ADMIN | Faible |

---

## Résumé Lot 1

**Routes à protéger :** 12  
**Niveau OWNER :** 1  
**Niveau ADMIN :** 11  
**Exclues (paiements) :** ~20  
**Exclues (platform) :** ~30

---

## Hiérarchie des Rôles (Phase 3 Simplifiée)

```
OWNER (isOwner=true) > ADMIN (role="admin") > MANAGER (role="manager") > MEMBER (role="member")
```

**Note :** Les rôles `SUPER_ADMIN`, `DELEGATE`, et les sous-types `adminRole` restent définis dans le schéma mais ne sont PAS utilisés dans les guards Phase 3.
