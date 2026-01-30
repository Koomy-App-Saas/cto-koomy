# Matrice Endpoints → Scopes — Backoffice Clients Koomy

**Date:** 2026-01-20  
**Type:** Audit READ-ONLY  
**Scope:** Endpoints back-office clients Koomy  
**Hors scope:** Endpoints plateforme owner, endpoints mobiles membres

---

## Scopes Définis

| Scope | Description |
|-------|-------------|
| **GESTION_MEMBRES** | Création, modification, suppression de membres, tags membres, invitations |
| **FINANCE** | Cotisations, collectes, paiements Stripe, transactions, factures |
| **EDITION** | Articles/News, branding, images, FAQs |
| **EVENT** | Événements, inscriptions, présences |
| **MESSAGING** | Conversations, messages, notifications |
| **SETTINGS** | Paramètres communauté, sections, catégories, plans d'adhésion, self-enrollment |

---

## Légende Règles d'Accès

| Code | Signification |
|------|---------------|
| `OWNER` | Uniquement isOwner=true |
| `ADMIN` | role="admin" uniquement (EXCLUT isOwner potentiellement) |
| `ADMIN+OWNER` | role="admin" OU isOwner=true (via isCommunityAdmin) |
| `ADMIN+DELEGATE` | role="admin" OU role="delegate" |
| `ADMIN+PERM` | Admin OU delegate avec permission spécifique |
| `ALL` | Aucun check de rôle (accessible à tous les membres) |
| `NONE` | Pas de check d'authentification (public ou legacy) |
| ⚠️ | Incohérence détectée |

---

## 1. GESTION_MEMBRES

| Méthode | Endpoint | Règle Actuelle | Règle Cible | Incohérence |
|---------|----------|----------------|-------------|-------------|
| GET | `/api/communities/:id/memberships` | ALL | ADMIN+OWNER | - |
| GET | `/api/communities/:id/members` | ALL | ADMIN+OWNER | - |
| POST | `/api/memberships` | ADMIN+OWNER OU canManageMembers | ADMIN+PERM(canManageMembers) | ✅ OK |
| PATCH | `/api/memberships/:id` | ADMIN+OWNER OU canManageMembers | ADMIN+PERM(canManageMembers) | ✅ OK |
| DELETE | `/api/memberships/:id` | NONE | ADMIN+OWNER | ⚠️ Pas de check |
| POST | `/api/memberships/:id/regenerate-code` | NONE | ADMIN+OWNER | ⚠️ Pas de check |
| POST | `/api/memberships/:id/resend-claim-code` | ADMIN+OWNER OU canManageMembers | ADMIN+PERM(canManageMembers) | ✅ OK |
| POST | `/api/communities/:id/delegates` | NONE | ADMIN+OWNER | ⚠️ Pas de check |
| GET | `/api/communities/:id/tags` | ALL | ADMIN+OWNER | - |
| POST | `/api/communities/:id/tags` | ADMIN+DELEGATE+OWNER | ADMIN+OWNER | ✅ OK |
| PUT | `/api/tags/:id` | ADMIN+DELEGATE | ADMIN+OWNER | ⚠️ isOwner non vérifié |
| POST | `/api/tags/:id/deactivate` | ADMIN+DELEGATE | ADMIN+OWNER | ⚠️ isOwner non vérifié |
| DELETE | `/api/tags/:id` | ADMIN+DELEGATE | ADMIN+OWNER | ⚠️ isOwner non vérifié |
| PUT | `/api/memberships/:membershipId/tags` | ADMIN | ADMIN+OWNER | ⚠️ isOwner exclu |
| POST | `/api/memberships/:membershipId/tags/:tagId` | ADMIN | ADMIN+OWNER | ⚠️ isOwner exclu |
| DELETE | `/api/memberships/:membershipId/tags/:tagId` | ADMIN | ADMIN+OWNER | ⚠️ isOwner exclu |
| GET | `/api/communities/:id/enrollment-requests` | ADMIN+OWNER | ADMIN+OWNER | ✅ OK |
| POST | `/api/communities/:id/enrollment-requests/:id/approve` | ADMIN+OWNER | ADMIN+OWNER | ✅ OK |
| POST | `/api/communities/:id/enrollment-requests/:id/reject` | ADMIN+OWNER | ADMIN+OWNER | ✅ OK |

---

## 2. FINANCE

| Méthode | Endpoint | Règle Actuelle | Règle Cible | Incohérence |
|---------|----------|----------------|-------------|-------------|
| POST | `/api/payments/connect-community` | requireAuth + role==="admin" | ADMIN+OWNER | ⚠️ isOwner exclu (check strict role==="admin")
| GET | `/api/communities/:id/fees` | ALL | ADMIN+OWNER | - |
| POST | `/api/communities/:id/fees` | NONE | ADMIN+OWNER | ⚠️ Pas de check |
| DELETE | `/api/communities/:id/fees/:id` | NONE | ADMIN+OWNER | ⚠️ Pas de check |
| GET | `/api/communities/:id/payment-requests` | ALL | ADMIN+OWNER | - |
| GET | `/api/communities/:id/payments` | ALL | ADMIN+OWNER | - |
| POST | `/api/payments` | NONE | ADMIN+OWNER | ⚠️ Pas de check |
| POST | `/api/payments/:id/process` | NONE | ADMIN+OWNER | ⚠️ Pas de check |
| POST | `/api/collections` | role==="admin" OR delegate+canManageCollections | ADMIN+OWNER+PERM(canManageCollections) | ⚠️ isOwner exclu (check strict) |
| GET | `/api/collections/:communityId` | ALL | ALL (public) | ✅ OK |
| GET | `/api/communities/:id/collections/all` | ALL | ADMIN+OWNER | - |
| PATCH | `/api/collections/:id` | role==="admin" OR delegate+canManageCollections | ADMIN+OWNER+PERM(canManageCollections) | ⚠️ isOwner exclu (check strict) |
| DELETE | `/api/collections/:id` | role==="admin" OR delegate+canManageCollections | ADMIN+OWNER+PERM(canManageCollections) | ⚠️ isOwner exclu (check strict) |
| POST | `/api/collections/:id/close` | role==="admin" | ADMIN+OWNER | ⚠️ isOwner exclu (check strict) |
| GET | `/api/communities/:id/transactions` | role==="admin" | ADMIN+OWNER | ⚠️ isOwner exclu (check strict) |
| POST | `/api/memberships/:id/mark-paid` | ADMIN+OWNER OU delegate OU isOwner | ADMIN+PERM(canManageMembers) | ✅ OK |

---

## 3. EDITION

| Méthode | Endpoint | Règle Actuelle | Règle Cible | Incohérence |
|---------|----------|----------------|-------------|-------------|
| GET | `/api/communities/:id/news` | ALL | ALL | ✅ OK |
| POST | `/api/communities/:id/news` | canManageArticles | ADMIN+PERM(canManageArticles) | ✅ OK |
| PATCH | `/api/communities/:id/news/:id` | canManageArticles | ADMIN+PERM(canManageArticles) | ✅ OK |
| DELETE | `/api/communities/:id/news/:id` | canManageArticles | ADMIN+PERM(canManageArticles) | ✅ OK |
| GET | `/api/communities/:id/branding` | ALL | ALL | ✅ OK |
| PATCH | `/api/communities/:id/branding` | canManageArticles | ADMIN+OWNER | ⚠️ Devrait être SETTINGS? |
| GET | `/api/communities/:id/faqs` | ALL | ALL | ✅ OK |
| GET | `/api/articles/:id/tags` | ALL | ALL | ✅ OK |
| GET | `/api/articles/:id/sections` | ALL | ALL | ✅ OK |
| PUT | `/api/articles/:id/tags` | ADMIN+DELEGATE | ADMIN+PERM(canManageArticles) | ⚠️ isOwner non vérifié |
| GET | `/api/communities/:id/articles/by-tags` | ALL | ALL | ✅ OK |
| GET | `/api/communities/:id/articles/tags` | ALL | ALL | ✅ OK |

---

## 4. EVENT

| Méthode | Endpoint | Règle Actuelle | Règle Cible | Incohérence |
|---------|----------|----------------|-------------|-------------|
| GET | `/api/communities/:id/events` | ALL | ALL | ✅ OK |
| GET | `/api/events/:id` | ALL | ALL | ✅ OK |
| POST | `/api/events` | NONE (zod validation only) | ADMIN+PERM(canManageEvents) | ⚠️ Pas de check auth (vérifié) |
| PATCH | `/api/events/:id` | NONE (zod validation only) | ADMIN+PERM(canManageEvents) | ⚠️ Pas de check auth (vérifié) |
| GET | `/api/communities/:id/tickets` | ALL | ADMIN+OWNER | - |

---

## 5. MESSAGING (canManageMessages)

| Méthode | Endpoint | Règle Actuelle | Règle Cible | Incohérence |
|---------|----------|----------------|-------------|-------------|
| GET | `/api/communities/:id/conversations` | ALL | ADMIN+PERM(canManageMessages) | - |
| GET | `/api/communities/:id/members/:id/conversations` | ALL | ADMIN+PERM(canManageMessages) | - |
| GET | `/api/communities/:id/messages/:conversationId` | ALL | ADMIN+PERM(canManageMessages) | - |
| POST | `/api/messages` | NONE (zod validation only) | ADMIN+PERM(canManageMessages) | ⚠️ Pas de check |
| PATCH | `/api/messages/:id/read` | NONE | ADMIN+OWNER | ⚠️ Pas de check |

*Note: canManageMessages existe en DB mais n'est vérifié dans aucun guard.*

---

## 6. SETTINGS

| Méthode | Endpoint | Règle Actuelle | Règle Cible | Incohérence |
|---------|----------|----------------|-------------|-------------|
| GET | `/api/communities/:id` | ALL | ALL | ✅ OK |
| PUT | `/api/communities/:id` | ADMIN+OWNER | ADMIN+OWNER | ✅ OK |
| GET | `/api/communities/:id/quota` | ALL | ADMIN+OWNER | - |
| PATCH | `/api/communities/:id/plan` | ADMIN+OWNER | OWNER | - |
| GET | `/api/communities/:id/sections` | ALL | ALL | ✅ OK |
| POST | `/api/sections` | ADMIN+OWNER | ADMIN+OWNER | ✅ OK |
| PATCH | `/api/communities/:id/sections/:id` | ADMIN+OWNER | ADMIN+OWNER | ✅ OK |
| DELETE | `/api/communities/:id/sections/:id` | ADMIN+OWNER | ADMIN+OWNER | ✅ OK |
| GET | `/api/communities/:id/categories` | ALL | ALL | ✅ OK |
| POST | `/api/communities/:id/categories` | ADMIN+OWNER | ADMIN+OWNER | ✅ OK |
| PATCH | `/api/communities/:id/categories/:id` | ADMIN+OWNER | ADMIN+OWNER | ✅ OK |
| DELETE | `/api/communities/:id/categories/:id` | ADMIN+OWNER | ADMIN+OWNER | ✅ OK |
| POST | `/api/communities/:id/categories/reorder` | ADMIN+OWNER | ADMIN+OWNER | ✅ OK |
| GET | `/api/communities/:id/dashboard` | ALL | ADMIN+OWNER | - |
| GET | `/api/communities/:id/membership-plans` | ALL | ALL | ✅ OK |
| POST | `/api/communities/:id/membership-plans` | ADMIN+OWNER | ADMIN+OWNER | ✅ OK |
| GET | `/api/membership-plans/:id` | ALL | ALL | ✅ OK |
| PATCH | `/api/membership-plans/:id` | ADMIN+OWNER | ADMIN+OWNER | ✅ OK |
| DELETE | `/api/membership-plans/:id` | ADMIN+OWNER | ADMIN+OWNER | ✅ OK |
| GET | `/api/communities/:id/member-profile-config` | ALL | ADMIN+OWNER | - |
| PUT | `/api/communities/:id/member-profile-config` | ADMIN+OWNER | ADMIN+OWNER | ✅ OK |
| GET | `/api/communities/:id/self-enrollment/settings` | ADMIN+OWNER | ADMIN+OWNER | ✅ OK |
| PATCH | `/api/communities/:id/self-enrollment/settings` | ADMIN+OWNER | ADMIN+OWNER | ✅ OK |
| POST | `/api/communities/:id/self-enrollment/generate-slug` | ADMIN+OWNER | ADMIN+OWNER | ✅ OK |

---

## Synthèse des Incohérences

### Catégorie 1: isOwner exclu (check `role === "admin"` strict)

| Endpoint | Impact |
|----------|--------|
| POST `/api/payments/connect-community` | OWNER ne peut pas configurer Stripe Connect |
| POST `/api/collections/:id/close` | OWNER ne peut pas clôturer une collecte |
| GET `/api/communities/:id/transactions` | OWNER ne peut pas voir les transactions |
| PUT/DELETE `/api/memberships/:id/tags/*` | OWNER ne peut pas gérer les tags membres |
| PUT/POST/DELETE `/api/tags/:id` (partial) | OWNER peut créer mais pas modifier/supprimer |

### Catégorie 2: Aucun check d'accès (endpoints sensibles non protégés — VÉRIFIÉ)

| Endpoint | Risque | Vérifié |
|----------|--------|---------|
| DELETE `/api/memberships/:id` | Suppression sans vérification | ✅ routes.ts:3138-3163 |
| POST `/api/memberships/:id/regenerate-code` | Régénération code sans auth | ✅ routes.ts:3519 |
| POST `/api/communities/:id/delegates` | Création délégué sans auth | ✅ routes.ts:5263-5293 |
| POST `/api/communities/:id/fees` | Création cotisation sans auth | ✅ routes.ts:5307-5321 |
| DELETE `/api/communities/:id/fees/:id` | Suppression cotisation sans auth | ✅ routes.ts:5348-5356 |
| POST `/api/payments` | Création paiement sans auth | ✅ routes.ts:5424-5436 |
| POST `/api/payments/:id/process` | Traitement paiement sans auth | ✅ routes.ts:5439-5478 |
| POST `/api/events` | Création événement sans auth | ✅ routes.ts:4918-5012 |
| PATCH `/api/events/:id` | Modification événement sans auth | ✅ routes.ts:5015-5103 |
| POST `/api/messages` | Création message sans auth | ✅ routes.ts:5224-5249 |
| PATCH `/api/messages/:id/read` | Marquer lu sans auth | ✅ routes.ts:5252-5259 |

### Catégorie 3: Scope ambigu

| Endpoint | Question |
|----------|----------|
| PATCH `/api/communities/:id/branding` | EDITION ou SETTINGS? |

---

## Recommandations

1. **Uniformiser les checks** — Remplacer tous les `role === "admin"` par `isCommunityAdmin(membership)` pour inclure systématiquement isOwner

2. **Ajouter les guards manquants** — Protéger les endpoints sans vérification (DELETE membres, events, fees)

3. **Clarifier OWNER-only vs ADMIN+scope** — Définir explicitement:
   - OWNER-only: Stripe Connect, changement de plan, suppression communauté
   - ADMIN+scope: Tout le reste avec permission granulaire

4. **Implémenter les permissions manquantes** — Utiliser canManageEvents pour les endpoints EVENT

5. **Documenter les scopes** — Créer une spec officielle des 5 scopes pour le frontend et le backend

---

## Annexe: Endpoints Publics/Membres (hors scope)

Ces endpoints ne nécessitent pas de rôle admin et sont accessibles aux membres:

- `/api/memberships/claim` — Réclamation carte membre
- `/api/memberships/verify/:claimCode` — Vérification code
- `/api/memberships/register-and-claim` — Inscription + réclamation
- `/api/payments/create-membership-session` — Session paiement cotisation
- `/api/payments/create-collection-session` — Session paiement collecte
- `/api/billing/*` — Gestion abonnement SaaS

---

*Fin de l'audit — Aucun code modifié*
