# AUDIT — Suspension / Résiliation / Purge / Guards API / UX Frontend

**Date:** 2026-01-25  
**Scope:** État réel du code Koomy pour la gestion des suspensions, résiliations et blocages  
**Statut:** 🔴 GAPS CRITIQUES P0 identifiés

---

## Table des matières

1. [Machine d'état communauté](#1-machine-détat-communauté)
2. [Délais de grâce](#2-délais-de-grâce)
3. [Emailing](#3-emailing)
4. [Purge](#4-purge)
5. [Guards API](#5-guards-api)
6. [Frontend UX](#6-frontend-ux)
7. [Recommandations P0/P1](#7-recommandations-p0p1)

---

## 1. Machine d'état communauté

### 1.1 Statuts disponibles

```typescript
// shared/schema.ts:79-84
export const saasClientStatusEnum = pgEnum("saas_client_status", [
  "ACTIVE",      // Compte opérationnel, paiements à jour
  "IMPAYE_1",    // J+0 à J+15 : Impayé détecté, délai de grâce
  "IMPAYE_2",    // J+15 à J+30 : Délai de grâce expiré, avant suspension
  "SUSPENDU",    // J+30 à J+60 : Compte gelé, accès bloqué
  "RESILIE"      // À partir de J+60 : Contrat terminé
]);
```

**Fichier source:** `shared/schema.ts` lignes 79-84

### 1.2 Champs de la communauté liés

| Champ | Type | Description |
|-------|------|-------------|
| `saasClientStatus` | enum | Statut courant (défaut: "ACTIVE") |
| `saasStatusChangedAt` | timestamp | Date du dernier changement de statut |
| `unpaidSince` | timestamp | **Référence temporelle unique** pour tous les J+N |
| `suspendedAt` | timestamp | Date d'entrée en SUSPENDU |
| `terminatedAt` | timestamp | Date d'entrée en RESILIE |
| `purgeScheduledAt` | timestamp | Date planifiée pour la purge |
| `purgeStatus` | enum | scheduled / completed / canceled_by_reactivation |
| `billingMode` | text | "self_service" ou "contract" |

**Fichier source:** `shared/schema.ts` lignes 349-360

### 1.3 Transitions et déclencheurs

| Transition | Trigger | Source |
|------------|---------|--------|
| * → IMPAYE_1 | Stripe `invoice.payment_failed` | Webhook Stripe |
| IMPAYE_1 → IMPAYE_2 | CRON quotidien (J+15) | `saasStatusJob.ts` ligne 25-43 |
| IMPAYE_2 → SUSPENDU | CRON quotidien (J+30) | `saasStatusJob.ts` ligne 46-64 |
| SUSPENDU → RESILIE | CRON quotidien (J+60) | `saasStatusJob.ts` ligne 67-90 |
| * → ACTIVE | Stripe `invoice.paid` / `payment_intent.succeeded` | Webhook Stripe |

### 1.4 Principe de préservation de `unpaidSince`

```typescript
// server/storage.ts:3418-3434
// IMPORTANT: unpaidSince is the SINGLE temporal reference for all J+N calculations
// It should only be set once when entering IMPAYE_1 and preserved until ACTIVE
switch (newStatus) {
  case "ACTIVE":
    // Clear all unpaid timestamps when returning to ACTIVE
    updateData.unpaidSince = null;
    break;
  case "IMPAYE_1":
    // Set unpaidSince only if not already set (first unpaid event)
    if (!community.unpaidSince) {
      updateData.unpaidSince = options?.unpaidSinceOverride || now;
    }
    break;
  case "IMPAYE_2":
  case "SUSPENDU":
  case "RESILIE":
    // Preserve existing unpaidSince - temporal escalation, not new event
    break;
}
```

**Fichier source:** `server/storage.ts` lignes 3418-3447

---

## 2. Délais de grâce

### 2.1 Seuils codés

| Transition | Délai (jours) | Fichier | Ligne |
|------------|---------------|---------|-------|
| IMPAYE_1 → IMPAYE_2 | **J+15** | `server/storage.ts` | 3492 |
| IMPAYE_2 → SUSPENDU | **J+30** | `server/storage.ts` | 3497 |
| SUSPENDU → RESILIE | **J+60** | `server/storage.ts` | 3502 |
| RESILIE → PURGE | **J+90** (30 jours après RESILIE) | `server/services/purgeService.ts` | 34 |

### 2.2 Calcul des seuils

```typescript
// server/storage.ts:3480-3521
async getCommunitiesNeedingStatusTransition(targetStatus: "IMPAYE_2" | "SUSPENDU" | "RESILIE") {
  switch (targetStatus) {
    case "IMPAYE_2":
      currentStatus = "IMPAYE_1";
      daysThreshold = 15;  // J+15
      break;
    case "SUSPENDU":
      currentStatus = "IMPAYE_2";
      daysThreshold = 30;  // J+30
      break;
    case "RESILIE":
      currentStatus = "SUSPENDU";
      daysThreshold = 60;  // J+60
      break;
  }
  
  const thresholdDate = new Date(now.getTime() - daysThreshold * 24 * 60 * 60 * 1000);
  
  // Query: billing_mode = 'self_service' AND saas_client_status = currentStatus AND unpaid_since <= thresholdDate
}
```

### 2.3 Constante de délai purge

```typescript
// server/services/purgeService.ts:34
const PURGE_DELAY_DAYS_AFTER_RESILIE = 30; // J+30 after RESILIE = J+90 total
```

---

## 3. Emailing

### 3.1 Types d'emails

| Type | Moment d'envoi | Fichier |
|------|----------------|---------|
| `saas_payment_failed` | Stripe webhook payment_failed | `saasEmailService.ts` ligne 62-120 |
| `saas_warning_impaye2` | Transition vers IMPAYE_2 (J+15) | `saasEmailService.ts` ligne 271-314 |
| `saas_suspension_imminent` | J+27 via `sendPreEscalationWarnings()` | `saasStatusJob.ts` ligne 120-124 |
| `saas_account_suspended` | Transition vers SUSPENDU (J+30) | `saasEmailService.ts` ligne 122-161 |
| `saas_termination_imminent` | J+57 via `sendPreEscalationWarnings()` | `saasStatusJob.ts` ligne 128-132 |
| `saas_account_terminated` | Transition vers RESILIE (J+60) | `saasEmailService.ts` ligne 163-199 |
| `saas_reactivation_success` | Retour à ACTIVE après paiement | `saasEmailService.ts` ligne 201-225 |
| `saas_subscription_started` | Première souscription validée | `saasEmailService.ts` ligne 227-269 |

### 3.2 Déduplication

```typescript
// server/storage.ts:3524-3554
async hasEmailBeenSent(communityId: string, emailType: string, relatedUnpaidSince?: Date): Promise<boolean> {
  if (relatedUnpaidSince) {
    // Check avec tolérance de 1 seconde sur unpaidSince
    const tolerance = 1000;
    const minDate = new Date(relatedUnpaidSince.getTime() - tolerance);
    const maxDate = new Date(relatedUnpaidSince.getTime() + tolerance);
    
    // SQL: WHERE community_id = ? AND email_type = ? 
    //      AND related_unpaid_since >= minDate AND related_unpaid_since <= maxDate
  } else {
    // Check si déjà envoyé (pour emails non liés à unpaidSince)
  }
}
```

### 3.3 Stockage des emails

**Table:** `subscription_emails_sent`

| Colonne | Description |
|---------|-------------|
| `id` | UUID |
| `communityId` | FK vers community |
| `emailType` | Type d'email (enum textuel) |
| `recipientEmail` | Email destinataire |
| `relatedUnpaidSince` | Timestamp de référence pour déduplication |
| `sentAt` | Timestamp d'envoi |
| `metadata` | JSONB (détails additionnels) |

**Fichier source:** `shared/schema.ts` lignes 1020-1033

---

## 4. Purge

### 4.1 Délai exact

- **Planification:** À la transition vers RESILIE (J+60)
- **Exécution:** 30 jours après planification (J+90 total)

```typescript
// server/services/purgeService.ts:45-57
export async function schedulePurge(communityId: string): Promise<void> {
  const now = new Date();
  const purgeScheduledAt = new Date(now.getTime() + PURGE_DELAY_DAYS_AFTER_RESILIE * DAY_IN_MS);
  
  await db.update(communities)
    .set({
      purgeScheduledAt,
      purgeStatus: "scheduled",
    })
    .where(eq(communities.id, communityId));
}
```

### 4.2 Tables supprimées (ordre de dépendance)

L'ordre de suppression respecte les contraintes de clés étrangères :

| # | Table | Notes |
|---|-------|-------|
| 1 | `member_tags` | Dépend de memberships |
| 2 | `article_tags` | Dépend de news_articles |
| 3 | `article_sections` | Dépend de news_articles |
| 4 | `event_attendance` | Dépend de events |
| 5 | `event_registrations` | Dépend de events |
| 6 | `ticket_responses` | Dépend de support_tickets |
| 7 | `subscription_emails_sent` | Direct sur communityId |
| 8 | `subscription_status_audit` | Direct sur communityId |
| 9 | `community_monthly_usage` | Direct sur communityId |
| 10 | `transactions` | Direct sur communityId |
| 11 | `payments` | Direct sur communityId |
| 12 | `payment_requests` | Direct sur communityId |
| 13 | `collections` | Direct sur communityId |
| 14 | `membership_fees` | Direct sur communityId |
| 15 | `membership_plans` | Direct sur communityId |
| 16 | `messages` | Direct sur communityId |
| 17 | `support_tickets` | Direct sur communityId |
| 18 | `events` | Direct sur communityId |
| 19 | `news_articles` | Direct sur communityId |
| 20 | `enrollment_requests` | Direct sur communityId |
| 21 | `user_community_memberships` | Direct sur communityId |
| 22 | `tags` | Direct sur communityId |
| 23 | `categories` | Direct sur communityId |
| 24 | `sections` | Direct sur communityId |
| 25 | `community_member_profile_config` | Direct sur communityId |
| 26 | `communities` | **Dernière table** |

**Fichier source:** `server/services/purgeService.ts` lignes 121-233

### 4.3 Stockage objet

```typescript
// server/services/purgeService.ts:86-119
async function deleteCommunityObjectStorage(communityId: string): Promise<boolean> {
  try {
    const publicPath = `public/communities/${communityId}`;
    const privatePath = `.private/communities/${communityId}`;
    
    try {
      // Liste et suppression objets publics
    } catch (e) {
      console.log(`[PURGE] No public objects for ${communityId} or already deleted`);
    }
    
    try {
      // Liste et suppression objets privés
    } catch (e) {
      console.log(`[PURGE] No private objects for ${communityId} or already deleted`);
    }
    
    return true;
  } catch (error) {
    console.error(`[PURGE] Failed to delete object storage for ${communityId}:`, error);
    return false;
  }
}
```

**Gestion des erreurs:**
- Les erreurs internes (list/delete) sont loggées mais n'interrompent pas le processus (graceful degradation)
- Les erreurs globales sont loggées avec `console.error` et retournent `false`
- Le résultat `objectStorageDeleted` est capturé dans `PurgeResult` pour audit

### 4.4 Logs de purge

```typescript
// server/services/purgeService.ts:282-307
export function logPurgeScheduled(communityId: string, purgeDate: Date): void {
  console.log(JSON.stringify({
    type: "purge_scheduled",
    timestamp: new Date().toISOString(),
    communityId,
    purgeScheduledAt: purgeDate.toISOString(),
    delayDaysAfterResilie: PURGE_DELAY_DAYS_AFTER_RESILIE,
  }));
}

export function logPurgeExecuted(result: PurgeResult): void {
  console.log(JSON.stringify({
    type: "purge_executed",
    timestamp: new Date().toISOString(),
    ...result,
  }));
}
```

### 4.5 Annulation de purge

```typescript
// server/services/purgeService.ts:59-68
export async function cancelPurge(communityId: string): Promise<void> {
  await db.update(communities)
    .set({
      purgeScheduledAt: null,
      purgeStatus: "canceled_by_reactivation",
    })
    .where(eq(communities.id, communityId));
}
```

---

## 5. Guards API

### 5.1 État actuel — 🔴 CRITIQUE

**Résultat de la recherche dans `server/routes.ts` :**

```bash
grep -n "SUSPENDU\|RESILIE\|saasClientStatus" server/routes.ts
# Résultat: AUCUNE CORRESPONDANCE
```

**Conclusion:** Il n'existe **AUCUN guard API** vérifiant `saasClientStatus` sur les endpoints back-office.

### 5.2 Endpoints communauté (extraction)

Voici une liste non-exhaustive des endpoints qui **devraient** être bloqués en SUSPENDU/RESILIE mais qui ne le sont **PAS** :

| Méthode | Endpoint | Risque |
|---------|----------|--------|
| POST | `/api/communities/:communityId/admins` | Ajout d'admins |
| POST | `/api/communities/:communityId/news` | Création d'articles |
| PATCH | `/api/communities/:communityId/news/:id` | Modification d'articles |
| DELETE | `/api/communities/:communityId/news/:id` | Suppression d'articles |
| POST | `/api/communities/:communityId/events` | Création d'événements |
| POST | `/api/communities/:communityId/categories` | Création de rubriques |
| POST | `/api/communities/:communityId/fees` | Création de cotisations |
| POST | `/api/communities/:communityId/tags` | Création de tags |
| PATCH | `/api/communities/:communityId/sections/:id` | Modification de sections |
| DELETE | `/api/communities/:communityId/sections/:id` | Suppression de sections |
| POST | `/api/communities/:communityId/delegates` | Ajout de délégués |
| PATCH | `/api/communities/:communityId/branding` | Modification du branding |
| PUT | `/api/communities/:communityId/member-profile-config` | Config profil membre |
| POST | `/api/communities/:communityId/membership-plans` | Création d'offres d'adhésion |
| PATCH | `/api/communities/:communityId/self-enrollment/settings` | Paramètres auto-inscription |

**Total approximatif:** ~50+ endpoints sous `/api/communities/:communityId/*` sans protection.

### 5.3 Endpoints qui doivent rester accessibles

| Endpoint | Raison |
|----------|--------|
| GET `/api/communities/:communityId` | Lecture info basique (pour afficher bannière) |
| GET `/api/communities/:communityId/subscription-state` | Vérifier état abonnement |
| GET `/api/billing/*` | Permettre régularisation |
| POST `/api/billing/create-checkout-session` | Payer |
| GET `/api/data-export/*` | RGPD : export données |

### 5.4 Proposition de middleware global

```typescript
// server/middleware/saasStatusGuard.ts (À CRÉER)

// Routes explicitement autorisées même en SUSPENDU/RESILIE
const ALLOWLIST_EXACT = [
  'GET /api/communities/:communityId',
  'GET /api/communities/:communityId/subscription-state',
];

const ALLOWLIST_PREFIX = [
  '/api/billing/',           // Toutes les routes billing (checkout, retry, verify)
  '/api/data-export/',       // Export RGPD obligatoire
];

// Routes bloquées même en lecture (données sensibles)
const BLOCKED_GET_ROUTES = [
  '/api/communities/:communityId/members',
  '/api/communities/:communityId/payments',
  '/api/communities/:communityId/transactions',
  '/api/communities/:communityId/conversations',
  '/api/communities/:communityId/messages',
];

export async function saasStatusGuard(req: Request, res: Response, next: NextFunction) {
  const { communityId } = req.params;
  
  // Skip si pas de communityId dans la route
  if (!communityId) return next();
  
  // Normaliser le path pour la comparaison
  const normalizedPath = req.path.replace(communityId, ':communityId');
  const methodPath = `${req.method} ${normalizedPath}`;
  
  // Skip si route explicitement autorisée
  if (ALLOWLIST_EXACT.includes(methodPath)) return next();
  if (ALLOWLIST_PREFIX.some(prefix => req.path.startsWith(prefix))) return next();
  
  const community = await storage.getCommunity(communityId);
  if (!community) return res.status(404).json({ error: 'COMMUNITY_NOT_FOUND' });
  
  const blockedStatuses = ['SUSPENDU', 'RESILIE'];
  if (!blockedStatuses.includes(community.saasClientStatus || 'ACTIVE')) {
    return next(); // Statut OK, continuer
  }
  
  // Pour SUSPENDU/RESILIE: bloquer toutes les écritures + GET sensibles
  const isBlockedGet = req.method === 'GET' && 
    BLOCKED_GET_ROUTES.some(route => normalizedPath.startsWith(route.replace(':communityId', communityId)));
  
  if (req.method !== 'GET' || isBlockedGet) {
    console.log(`[GUARD] Blocked ${methodPath} for suspended/terminated community ${communityId}`);
    return res.status(403).json({
      error: 'ACCOUNT_SUSPENDED_OR_TERMINATED',
      code: community.saasClientStatus,
      message: 'Votre compte est suspendu ou résilié. Veuillez régulariser votre situation.',
      paymentUrl: `/api/billing/retry-checkout?communityId=${communityId}`,
      supportEmail: 'support@koomy.app',
    });
  }
  
  next(); // GET non-sensible autorisé
}
```

---

## 6. Frontend UX

### 6.1 Composants existants (non utilisés)

**Fichier:** `client/src/components/SaasStatusBanner.tsx`

| Composant | Statuts gérés | État d'intégration |
|-----------|---------------|-------------------|
| `SaasStatusBanner` | IMPAYE_1, IMPAYE_2 | 🔴 **NON IMPORTÉ** |
| `SaasBlockedPage` | SUSPENDU, RESILIE | 🔴 **NON IMPORTÉ** |

**Recherche d'imports:**

```bash
grep -r "SaasStatusBanner\|SaasBlockedPage" client/src --include="*.tsx" --include="*.ts"
# Résultat: Seulement dans le fichier de définition lui-même
```

### 6.2 AdminLayout — État actuel

**Fichier:** `client/src/components/layouts/AdminLayout.tsx`

**Vérifications actuelles:**

| Vérification | Ligne | Comportement |
|--------------|-------|--------------|
| `subscriptionStatus === "past_due"` | 52 | Variable définie mais utilisée uniquement pour comptage membres suspendus |
| `isPendingPayment` | 163 | Bloque si `past_due && !stripeSubscriptionId` OU `trialExpired` |
| Bannière trial | 238-249 | Affichée si en période d'essai |
| Bannière sandbox | 231-236 | Affichée si `isSandbox` |

**Vérifications MANQUANTES:**

- ❌ Aucune vérification de `saasClientStatus`
- ❌ Aucun import de `SaasStatusBanner`
- ❌ Aucun import de `SaasBlockedPage`
- ❌ Aucun blocage pour SUSPENDU/RESILIE

### 6.3 CTA disponibles dans SaasBlockedPage

Le composant `SaasBlockedPage` (lignes 104-206) propose :

- **Bouton "Contacter le support"** : `onContactSupport` callback
- **Bouton "Exporter mes données"** : `onExportData` callback
- **Mention RGPD** : "Conformément au RGPD, vous conservez le droit d'exporter vos données."

**⚠️ Manquant:** Bouton "Régulariser" / "Payer" n'est pas présent dans `SaasBlockedPage`.

### 6.4 SaasStatusBanner — CTA existants

Le composant `SaasStatusBanner` (lignes 13-102) propose :

- **IMPAYE_1:** Bouton "Régulariser maintenant" (`onPayNow`)
- **IMPAYE_2:** Bouton "Régulariser immédiatement" (`onPayNow`) avec style urgence

### 6.5 Intégration proposée

```tsx
// client/src/components/layouts/AdminLayout.tsx

import { SaasStatusBanner, SaasBlockedPage } from "@/components/SaasStatusBanner";

// Dans le composant, avant le return principal :
const saasStatus = currentCommunity?.saasClientStatus || "ACTIVE";

// Blocage total pour SUSPENDU/RESILIE
if (saasStatus === "SUSPENDU" || saasStatus === "RESILIE") {
  return (
    <SaasBlockedPage 
      status={saasStatus}
      communityName={currentCommunity.name}
      suspendedAt={currentCommunity.suspendedAt}
      terminatedAt={currentCommunity.terminatedAt}
      onContactSupport={() => window.location.href = "mailto:support@koomy.app"}
      onExportData={() => window.location.href = `/api/data-export/${currentCommunity.id}`}
      onPayNow={() => window.location.href = `/api/billing/retry-checkout?communityId=${currentCommunity.id}`}
    />
  );
}

// Dans le return, après les bannières existantes :
<SaasStatusBanner 
  status={saasStatus}
  daysUnpaid={calculateDaysUnpaid(currentCommunity.unpaidSince)}
  onPayNow={() => window.location.href = `/api/billing/retry-checkout?communityId=${currentCommunity.id}`}
  onContactSupport={() => window.location.href = "mailto:support@koomy.app"}
/>
```

---

## 7. Recommandations P0/P1

### P0 — Sécurité & Cohérence (Bloquant)

| # | Action | Effort | Fichier(s) |
|---|--------|--------|------------|
| **P0.1** | Créer middleware global `saasStatusGuard` | 4h | `server/middleware/saasStatusGuard.ts` |
| **P0.2** | Appliquer le middleware sur toutes les routes `/api/communities/:communityId/*` | 2h | `server/routes.ts` |
| **P0.3** | Définir liste whitelist des endpoints autorisés (billing, export) | 1h | Configuration |
| **P0.4** | Tests unitaires du guard | 3h | `server/__tests__/saasStatusGuard.test.ts` |

### P1 — UX Business (Important)

| # | Action | Effort | Fichier(s) |
|---|--------|--------|------------|
| **P1.1** | Intégrer `SaasStatusBanner` dans AdminLayout | 2h | `AdminLayout.tsx` |
| **P1.2** | Intégrer `SaasBlockedPage` dans AdminLayout | 2h | `AdminLayout.tsx` |
| **P1.3** | Ajouter CTA "Régulariser" dans `SaasBlockedPage` | 1h | `SaasStatusBanner.tsx` |
| **P1.4** | Créer endpoint `/api/data-export/:communityId` si non existant | 4h | `server/routes.ts` |
| **P1.5** | Ajouter indicateur visuel du statut dans header/sidebar | 2h | `AdminLayout.tsx` |

### P2 — Améliorations (Nice-to-have)

| # | Action | Notes |
|---|--------|-------|
| **P2.1** | Logger les tentatives d'accès bloquées par le guard | Audit trail |
| **P2.2** | Dashboard SaaS Owner pour visualiser statuts clients | Monitoring |
| **P2.3** | Alertes temps réel sur transitions SUSPENDU/RESILIE | Ops |

---

## Annexes

### A. CRON Infrastructure

**Endpoint:** `POST /api/internal/cron/saas-status`  
**Fichier:** `server/routes.ts` lignes 12288-12350

**Sécurité:**
- Header `x-cron-secret` requis (comparé à `CRON_SECRET` env var)
- Advisory lock avec ID `8675309` pour éviter exécutions concurrentes
- Timeout lock: 10 minutes

```typescript
// server/routes.ts:12293
const SAAS_STATUS_LOCK_ID = 8675309;
```

**Table de locks:**
```sql
-- server/storage.ts:3722-3728
CREATE TABLE IF NOT EXISTS cron_locks (
  lock_name VARCHAR(100) PRIMARY KEY,
  owner_token VARCHAR(50) NOT NULL,
  acquired_at TIMESTAMP NOT NULL,
  expires_at TIMESTAMP NOT NULL
)
```

### B. Schéma des transitions

```
                    Stripe invoice.payment_failed
                              │
                              ▼
┌────────┐ ─────────────► ┌─────────┐
│ ACTIVE │                │IMPAYE_1 │
└────────┘ ◄───────────── └─────────┘
    ▲     Stripe payment    │
    │        success        │ J+15
    │                       ▼
    │                 ┌─────────┐
    │                 │IMPAYE_2 │
    │                 └─────────┘
    │                       │
    │                       │ J+30
    │                       ▼
    │                 ┌─────────┐
    └─────────────────│SUSPENDU │
    Stripe payment    └─────────┘
       success              │
                           │ J+60
                           ▼
                     ┌─────────┐      J+90      ┌───────┐
                     │ RESILIE │ ───────────► │ PURGE │
                     └─────────┘              └───────┘
```

### C. Fichiers clés

| Fichier | Rôle |
|---------|------|
| `shared/schema.ts` | Définition enums et tables |
| `server/storage.ts` | Fonctions transitionSaasStatus, getCommunitiesNeedingStatusTransition |
| `server/services/saasStatusJob.ts` | Job CRON de transition automatique |
| `server/services/saasEmailService.ts` | Envoi emails avec déduplication |
| `server/services/purgeService.ts` | Purge des données et Object Storage |
| `server/routes.ts` (12288-12350) | Endpoint CRON |
| `client/src/components/SaasStatusBanner.tsx` | Composants UI (non utilisés) |
| `client/src/components/layouts/AdminLayout.tsx` | Layout admin (sans guards SaaS) |

---

**Fin du rapport**

*Généré par audit automatisé du code source Koomy*
