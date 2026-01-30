# KOOMY — AUTH MIGRATION FIREBASE-ONLY: IMPACT MAP EXHAUSTIVE

**Date**: 2026-01-24  
**Scope**: Admin/Backoffice  
**Format**: Feature → API calls → Auth guard → Rôles → Risques → Test minimal

> **DISCLAIMER**: Ce mapping est basé sur l'inventaire des routes connues. Les guards indiqués sont les attentes post-migration. Pour une vérification exhaustive, exécuter `rg "requireFirebaseOnly|requireAuthWithUser|requireFirebaseAuth" server/routes.ts` et valider chaque route.

---

## 1. SECTIONS (CRUD)

| Action | Endpoint | Méthode | Guard | Rôles requis | Risque | Test minimal |
|--------|----------|---------|-------|--------------|--------|--------------|
| Lister | `/api/communities/:id/sections` | GET | `requireFirebaseOnly` | admin | 401 si token legacy | GET + vérifier 200 |
| Créer | `/api/communities/:id/sections` | POST | `requireFirebaseOnly` | admin | 401 si token legacy | POST body valide |
| Modifier | `/api/communities/:id/sections/:sectionId` | PATCH | `requireFirebaseOnly` | admin | 401/403 | PATCH + vérifier update |
| Supprimer | `/api/communities/:id/sections/:sectionId` | DELETE | `requireFirebaseOnly` | admin | 401/403 | DELETE + vérifier suppression |

**Erreurs possibles**:
- `401 FIREBASE_AUTH_REQUIRED`: Token non-Firebase envoyé
- `403 FORBIDDEN`: Pas admin de cette communauté

**Correction**: Vérifier que le frontend envoie bien le Firebase JWT

---

## 2. EVENTS (CRUD)

| Action | Endpoint | Méthode | Guard | Rôles requis | Risque | Test minimal |
|--------|----------|---------|-------|--------------|--------|--------------|
| Lister | `/api/communities/:id/events` | GET | `requireFirebaseOnly` | admin | 401 si token legacy | GET + vérifier 200 |
| Créer | `/api/communities/:id/events` | POST | `requireFirebaseOnly` | admin | 401 si token legacy | POST avec title/date |
| Modifier | `/api/communities/:id/events/:eventId` | PATCH | `requireFirebaseOnly` | admin | 401/403 | PATCH + vérifier update |
| Supprimer | `/api/communities/:id/events/:eventId` | DELETE | `requireFirebaseOnly` | admin | 401/403 | DELETE + vérifier suppression |

**Endpoints additionnels**:

| Action | Endpoint | Méthode | Guard |
|--------|----------|---------|-------|
| Catégories | `/api/communities/:id/event-categories` | GET/POST | `requireFirebaseOnly` |
| Catégorie | `/api/communities/:id/event-categories/:id` | PATCH/DELETE | `requireFirebaseOnly` |

---

## 3. NEWS (CRUD)

| Action | Endpoint | Méthode | Guard | Rôles requis | Risque | Test minimal |
|--------|----------|---------|-------|--------------|--------|--------------|
| Lister | `/api/communities/:id/news` | GET | `requireFirebaseOnly` | admin | 401 | GET + vérifier 200 |
| Créer | `/api/communities/:id/news` | POST | `requireFirebaseAuth` (middleware) | admin | 401 | POST avec title/content |
| Modifier | `/api/news/:id` | PATCH | `requireFirebaseAuth` (middleware) | admin | 401/403 | PATCH + vérifier update |
| Supprimer | `/api/news/:id` | DELETE | `requireFirebaseAuth` (middleware) | admin | 401/403 | DELETE + vérifier suppression |

---

## 4. MESSAGES / COMMUNICATIONS

| Action | Endpoint | Méthode | Guard | Rôles requis | Risque | Test minimal |
|--------|----------|---------|-------|--------------|--------|--------------|
| Envoyer message | `/api/communities/:id/messages` | POST | `requireFirebaseOnly` | admin | 401 | POST + vérifier envoi |
| Historique | `/api/communities/:id/messages` | GET | `requireFirebaseOnly` | admin | 401 | GET + vérifier liste |

---

## 5. OFFERS / PROMOTIONS

| Action | Endpoint | Méthode | Guard | Rôles requis | Risque | Test minimal |
|--------|----------|---------|-------|--------------|--------|--------------|
| Lister | `/api/communities/:id/offers` | GET | `requireFirebaseOnly` | admin | 401 | GET |
| Créer | `/api/communities/:id/offers` | POST | `requireFirebaseOnly` | admin | 401 | POST |
| Modifier | `/api/offers/:id` | PATCH | `requireFirebaseOnly` | admin | 401/403 | PATCH |
| Supprimer | `/api/offers/:id` | DELETE | `requireFirebaseOnly` | admin | 401/403 | DELETE |

---

## 6. ENROLLMENT REQUESTS

| Action | Endpoint | Méthode | Guard | Rôles requis | Risque | Test minimal |
|--------|----------|---------|-------|--------------|--------|--------------|
| Lister | `/api/communities/:id/enrollment-requests` | GET | `requireFirebaseOnly` | admin | 401 | GET |
| Approuver | `/api/communities/:id/enrollment-requests/:id/approve` | POST | `requireFirebaseOnly` | admin | 401/403 | POST + vérifier status |
| Rejeter | `/api/communities/:id/enrollment-requests/:id/reject` | POST | `requireFirebaseOnly` | admin | 401/403 | POST + vérifier status |

---

## 7. MEMBERSHIP PLANS

| Action | Endpoint | Méthode | Guard | Rôles requis | Risque | Test minimal |
|--------|----------|---------|-------|--------------|--------|--------------|
| Lister | `/api/communities/:id/membership-plans` | GET | `requireFirebaseOnly` | admin | 401 | GET |
| Créer | `/api/communities/:id/membership-plans` | POST | `requireFirebaseOnly` | admin | 401 | POST |
| Modifier | `/api/membership-plans/:id` | PATCH | `requireFirebaseOnly` | admin | 401/403 | PATCH |
| Supprimer | `/api/membership-plans/:id` | DELETE | `requireFirebaseOnly` | admin | 401/403 | DELETE |

---

## 8. BRANDING / SETTINGS

| Action | Endpoint | Méthode | Guard | Rôles requis | Risque | Test minimal |
|--------|----------|---------|-------|--------------|--------|--------------|
| Lire | `/api/communities/:id/branding` | GET | `requireFirebaseOnly` | admin | 401 | GET |
| Modifier | `/api/communities/:id/branding` | PATCH | `requireFirebaseOnly` | admin | 401/403 | PATCH |
| Self-enrollment settings | `/api/communities/:id/self-enrollment/settings` | GET/PATCH | `requireFirebaseOnly` | admin | 401 | GET/PATCH |
| Generate slug | `/api/communities/:id/self-enrollment/generate-slug` | POST | `requireFirebaseOnly` | admin | 401 | POST |

---

## 9. MEMBERSHIPS (Members management)

| Action | Endpoint | Méthode | Guard | Rôles requis | Risque | Test minimal |
|--------|----------|---------|-------|--------------|--------|--------------|
| Créer membre | `/api/memberships` | POST | `requireFirebaseOnly` | admin | 401 | POST |
| Régénérer code | `/api/memberships/:id/regenerate-code` | POST | `requireFirebaseOnly` | admin | 401 | POST |
| Renvoyer claim | `/api/memberships/:id/resend-claim` | POST | `requireFirebaseOnly` | admin | 401 | POST |
| Marquer payé | `/api/memberships/:id/mark-paid` | POST | `requireFirebaseOnly` | admin | 401 | POST |
| Tags membre | `/api/memberships/:id/tags` | PUT | `requireFirebaseOnly` | admin | 401 | PUT |
| Modifier | `/api/memberships/:id` | PATCH | `requireFirebaseAuth` | admin | 401/403 | PATCH |
| Supprimer | `/api/memberships/:id` | DELETE | `requireFirebaseAuth` | admin | 401/403 | DELETE |

---

## 10. TAGS

| Action | Endpoint | Méthode | Guard | Rôles requis | Risque | Test minimal |
|--------|----------|---------|-------|--------------|--------|--------------|
| Lister | `/api/communities/:id/tags` | GET | `requireFirebaseOnly` | admin | 401 | GET |
| Créer | `/api/communities/:id/tags` | POST | `requireFirebaseOnly` | admin | 401 | POST |
| Modifier | `/api/tags/:id` | PUT | `requireFirebaseOnly` | admin | 401/403 | PUT |
| Désactiver | `/api/tags/:id/deactivate` | POST | `requireFirebaseOnly` | admin | 401/403 | POST |
| Supprimer | `/api/tags/:id` | DELETE | `requireFirebaseOnly` | admin | 401/403 | DELETE |

---

## 11. COLLECTIONS

| Action | Endpoint | Méthode | Guard | Rôles requis | Risque | Test minimal |
|--------|----------|---------|-------|--------------|--------|--------------|
| Lister toutes | `/api/communities/:id/collections/all` | GET | `requireFirebaseOnly` | admin | 401 | GET |

---

## 12. TRANSACTIONS

| Action | Endpoint | Méthode | Guard | Rôles requis | Risque | Test minimal |
|--------|----------|---------|-------|--------------|--------|--------------|
| Lister | `/api/communities/:id/transactions` | GET | `requireFirebaseOnly` | admin | 401 | GET |

---

## 13. ADMIN CREATION

| Action | Endpoint | Méthode | Guard | Rôles requis | Risque | Test minimal |
|--------|----------|---------|-------|--------------|--------|--------------|
| Ajouter admin | `/api/communities/:id/admins` | POST | `requireFirebaseOnly` | admin/owner | 401/403 | POST |

---

## 14. REPAIR / MAINTENANCE

| Action | Endpoint | Méthode | Guard | Rôles requis | Risque | Test minimal |
|--------|----------|---------|-------|--------------|--------|--------------|
| Repair memberships | `/api/admin/communities/:id/repair-memberships` | POST | `requireFirebaseOnly` | admin | 401 | POST |

---

## HORS SCOPE — SaaS Owner / Platform Admin

Ces routes utilisent un système de session séparé (pas Firebase):

| Endpoint pattern | Guard | Raison hors scope |
|------------------|-------|-------------------|
| `/api/platform/*` | Session-based | Platform owner = système différent |
| `/api/saas-owner/*` | Session-based | Platform owner = système différent |

---

## CODES D'ERREUR POST-MIGRATION

| Code | Status | Signification | Action utilisateur |
|------|--------|---------------|-------------------|
| `FIREBASE_AUTH_REQUIRED` | 401 | Token legacy envoyé | Se reconnecter via Firebase |
| `NO_AUTH_TOKEN` | 401 | Pas de token | Se connecter |
| `TOKEN_EXPIRED` | 401 | Token Firebase expiré | Refresh automatique |
| `FORBIDDEN` | 403 | Pas les droits | Vérifier rôle admin |
| `COMMUNITY_MISMATCH` | 403 | Mauvaise communauté | Vérifier communityId |

---

**FIN DU RAPPORT IMPACT_MAP_EXHAUSTIVE**
