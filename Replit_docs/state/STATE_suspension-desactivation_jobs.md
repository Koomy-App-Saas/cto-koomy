# RAPPORT D'AUDIT — SUSPENSION / DÉSACTIVATION / JOBS PLANIFIÉS

**Date de l'audit**: 2026-01-25  
**Version**: 1.0  
**Portée**: Code Koomy - Mécanismes de suspension, désactivation, et automatisations

---

## 1. Résumé Exécutif

### Ce qui existe déjà

| Domaine | Statut | Maturité |
|---------|--------|----------|
| Cycle de vie SaaS (ACTIVE→IMPAYE_1→IMPAYE_2→SUSPENDU→RESILIE) | ✅ Complet | Production-ready |
| Job CRON quotidien avec verrou distribué | ✅ Complet | Production-ready |
| Système de purge automatique (J+90) | ✅ Complet | Production-ready |
| Emails automatisés (8 types) avec déduplication | ✅ Complet | Production-ready |
| Composants UI (SaasStatusBanner, SaasBlockedPage) | ✅ Complet | Production-ready |
| Suspension par quota membres (suspendedByQuotaLimit) | ✅ Complet | Production-ready |
| Audit trail (subscription_status_audit) | ✅ Complet | Production-ready |

### Ce qui manque / Zones floues

| Élément | Statut | Impact |
|---------|--------|--------|
| Guards API sur endpoints Back-Office pour SUSPENDU/RESILIE | ⚠️ Partiel | Medium - L'UI bloque mais pas l'API |
| Tests E2E du cycle complet | ⚠️ Absent | Medium - Validation manuelle requise |
| Intégration SaasStatusBanner dans tous les layouts | ⚠️ Partiel | Low - Visible seulement dans certaines vues |
| Export données pour RESILIE | ⚠️ Partiel | Medium - Bouton présent mais endpoint non vérifié |

---

## 2. Carte des États & Transitions

### 2.1 Machine d'État SaaS (Paiement)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        CYCLE DE VIE SAAS CLIENT                            │
└─────────────────────────────────────────────────────────────────────────────┘

                           ┌──────────────┐
                           │   ACTIVE     │
                           │  (opérationnel)│
                           └──────┬───────┘
                                  │
                  invoice.payment_failed (Stripe Webhook)
                                  │
                                  ▼
                           ┌──────────────┐
                           │  IMPAYE_1    │
                           │  (J+0 à J+15) │◄─────────────────┐
                           └──────┬───────┘                   │
                                  │                           │
                  J+15 (CRON Job DELAY_EXPIRED)               │
                                  │                           │
                                  ▼                           │
                           ┌──────────────┐                   │
                           │  IMPAYE_2    │    invoice.payment_succeeded
                           │ (J+15 à J+30) │    (Stripe Webhook)
                           └──────┬───────┘                   │
                                  │                           │
                  J+30 (CRON Job DELAY_EXPIRED)               │
                                  │                           │
                                  ▼                           │
                           ┌──────────────┐                   │
                           │  SUSPENDU    │───────────────────┤
                           │ (J+30 à J+60) │                   │
                           └──────┬───────┘                   │
                                  │                           │
                  J+60 (CRON Job DELAY_EXPIRED)               │
                                  │                           │
                                  ▼                           │
                           ┌──────────────┐                   │
                           │   RESILIE    │───────────────────┘
                           │  (à partir J+60)│
                           └──────┬───────┘
                                  │
                  J+90 (CRON Job + 30 jours après RESILIE)
                                  │
                                  ▼
                           ┌──────────────┐
                           │    PURGE     │
                           │ (données supprimées)│
                           └──────────────┘
```

### 2.2 Tableau des Transitions

| De | Vers | Déclencheur | Délai | Fichier |
|----|------|-------------|-------|---------|
| ACTIVE | IMPAYE_1 | `invoice.payment_failed` webhook | Immédiat | `server/stripe.ts:1007` |
| IMPAYE_1 | IMPAYE_2 | CRON Job `DELAY_EXPIRED` | J+15 | `server/services/saasStatusJob.ts:27` |
| IMPAYE_2 | SUSPENDU | CRON Job `DELAY_EXPIRED` | J+30 | `server/services/saasStatusJob.ts:48` |
| SUSPENDU | RESILIE | CRON Job `DELAY_EXPIRED` | J+60 | `server/services/saasStatusJob.ts:69` |
| RESILIE | PURGE | CRON Job `schedulePurge()` | J+90 | `server/services/purgeService.ts:262` |
| IMPAYE_* / SUSPENDU / RESILIE | ACTIVE | `invoice.payment_succeeded` webhook | Immédiat | `server/stripe.ts:922` |

### 2.3 Machine d'État Membres (Quota)

```
┌──────────────────────────────────────────────────────────────┐
│               SUSPENSION QUOTA MEMBRES                       │
└──────────────────────────────────────────────────────────────┘

  ┌─────────┐                            ┌─────────────────────┐
  │ ACTIVE  │    limit exceeded          │ SUSPENDED           │
  │ member  │ ─────────────────────────► │ (suspendedByQuotaLimit)│
  └─────────┘                            └─────────────────────┘
       ▲                                          │
       │      plan upgrade / member deleted       │
       └──────────────────────────────────────────┘
```

---

## 3. Règles Actuelles (Langage Produit)

### 3.1 Règles SaaS Client Status

| Règle | Description |
|-------|-------------|
| R1 | Un impayé Stripe déclenche immédiatement le passage en IMPAYE_1 |
| R2 | Le délai de grâce total est de 30 jours avant suspension |
| R3 | La suspension bloque tout accès au back-office (sauf export données) |
| R4 | La résiliation intervient à J+60 avec planification de purge |
| R5 | Un paiement réussi réactive immédiatement le compte (même depuis RESILIE) |
| R6 | La purge des données survient 30 jours après la résiliation (J+90 total) |
| R7 | Une réactivation annule toute purge planifiée |

### 3.2 Règles Quota Membres

| Règle | Description |
|-------|-------------|
| Q1 | Les membres au-delà de la limite du plan sont suspendus automatiquement |
| Q2 | L'ordre de suspension suit la date d'adhésion (FIFO - les plus récents d'abord) |
| Q3 | Un upgrade de plan réactive automatiquement les membres dans la nouvelle limite |
| Q4 | Enterprise et White-Label bypassen les limites de quota |

### 3.3 Règles Email

| Règle | Description |
|-------|-------------|
| E1 | Chaque type d'email n'est envoyé qu'une fois par période d'impayé |
| E2 | La déduplication utilise `communityId + emailType + unpaidSince` |
| E3 | Un avertissement "suspension imminente" est envoyé à J+27 |
| E4 | Un avertissement "résiliation imminente" est envoyé à J+57 |

---

## 4. Mapping Technique

### 4.1 Modèle de Données (DB)

#### Table `communities`

| Colonne | Type | Description | Écrit par | Lu par |
|---------|------|-------------|-----------|--------|
| `saas_client_status` | enum | ACTIVE, IMPAYE_1, IMPAYE_2, SUSPENDU, RESILIE | stripe.ts, saasStatusJob.ts | routes.ts, UI |
| `saas_status_changed_at` | timestamp | Date du dernier changement de statut | storage.ts:transitionSaasStatus | Audit, UI |
| `unpaid_since` | timestamp | Date de détection premier impayé (référence J+N) | storage.ts:transitionSaasStatus | saasStatusJob.ts, saasEmailService.ts |
| `suspended_at` | timestamp | Date de passage en SUSPENDU | storage.ts:transitionSaasStatus | UI (SaasBlockedPage) |
| `terminated_at` | timestamp | Date de passage en RESILIE | storage.ts:transitionSaasStatus | UI (SaasBlockedPage) |
| `purge_scheduled_at` | timestamp | Date de purge planifiée (J+90) | purgeService.ts:schedulePurge | purgeService.ts:runPurgeJob |
| `purge_status` | enum | scheduled, canceled_by_reactivation, executed | purgeService.ts | purgeService.ts |
| `purge_executed_at` | timestamp | Date d'exécution de la purge | purgeService.ts:executePurge | Audit |

**Fichier de définition**: `shared/schema.ts` (lignes 79-100, 349-357)

#### Table `user_community_memberships`

| Colonne | Type | Description | Écrit par | Lu par |
|---------|------|-------------|-----------|--------|
| `status` | enum | active, expired, suspended | routes.ts, subscriptionGuards.ts | routes.ts, UI |
| `suspended_by_quota_limit` | boolean | true si suspendu par dépassement quota | subscriptionGuards.ts:enforceCommunityPlanLimits | routes.ts:login, UI |

**Fichier de définition**: `shared/schema.ts` (lignes 557-558)

#### Table `subscription_status_audit`

| Colonne | Type | Description |
|---------|------|-------------|
| `previous_status` | text | Statut avant transition |
| `new_status` | text | Statut après transition |
| `transition_reason` | enum | PAYMENT_FAILED, PAYMENT_SUCCEEDED, DELAY_EXPIRED, MANUAL |
| `triggered_by` | text | Source: WEBHOOK, DAILY_JOB, etc. |
| `stripe_event_id` | text | ID événement Stripe (si applicable) |
| `metadata` | jsonb | Données contextuelles enrichies |

**Fichier de définition**: `shared/schema.ts` (lignes 1009-1022)

#### Table `subscription_emails_sent`

| Colonne | Type | Description |
|---------|------|-------------|
| `community_id` | varchar | FK vers community |
| `email_type` | text | Type d'email envoyé |
| `related_unpaid_since` | timestamp | Référence période impayé (pour déduplication) |
| `recipient_email` | text | Adresse destinataire |

**Fichier de définition**: `shared/schema.ts` (usage dans storage.ts:3524-3556)

#### Table `cron_locks` (dynamique)

| Colonne | Type | Description |
|---------|------|-------------|
| `lock_name` | varchar(100) PK | Identifiant unique du verrou |
| `owner_token` | varchar(50) | Token UUID du propriétaire |
| `acquired_at` | timestamp | Date d'acquisition |
| `expires_at` | timestamp | Date d'expiration (10 min par défaut) |

**Fichier de définition**: `server/storage.ts` (lignes 3722-3728)

### 4.2 Enums Définis

```typescript
// shared/schema.ts

// Statut SaaS Client (ligne 79-85)
export const saasClientStatusEnum = pgEnum("saas_client_status", [
  "ACTIVE",      // Compte opérationnel, paiements à jour
  "IMPAYE_1",    // J+0 à J+15 : Impayé détecté, délai de grâce
  "IMPAYE_2",    // J+15 à J+30 : Délai de grâce expiré, avant suspension
  "SUSPENDU",    // J+30 à J+60 : Compte gelé, accès bloqué
  "RESILIE"      // À partir de J+60 : Contrat terminé
]);

// Raison de transition (ligne 88-93)
export const saasTransitionReasonEnum = pgEnum("saas_transition_reason", [
  "PAYMENT_FAILED",     // Webhook Stripe payment_failed
  "PAYMENT_SUCCEEDED",  // Webhook Stripe payment_succeeded
  "DELAY_EXPIRED",      // Job quotidien - délai expiré
  "MANUAL"              // Action manuelle admin plateforme
]);

// Statut de purge (ligne 96-100)
export const purgeStatusEnum = pgEnum("purge_status", [
  "scheduled",              // Purge planifiée (J+90 après canceled)
  "canceled_by_reactivation", // Purge annulée car communauté réactivée
  "executed"                // Purge exécutée avec succès
]);

// Statut membre (ligne 8)
export const memberStatusEnum = pgEnum("member_status", ["active", "expired", "suspended"]);
```

### 4.3 API Guards (Middleware/Checks)

#### Guards SaaS Status

| Endpoint | Condition | Réponse | Message | Fichier |
|----------|-----------|---------|---------|---------|
| `POST /api/mobile/login` | `suspendedByQuotaLimit` sur tous les memberships | 403 | "Tous vos accès sont suspendus" | routes.ts:1797-1805 |
| `GET /api/mobile/me` | `suspendedByQuotaLimit` sur tous les memberships | 403 | "Tous vos accès sont suspendus" | routes.ts:1873-1882 |
| `POST /api/events/:id/paid-registration` | `subscriptionStatus !== "active"` | 403 | "Subscription required for paid events" | routes.ts:7298-7301, 7417-7420 |

#### Guards Quota/Plan

| Endpoint | Condition | Réponse | Message | Fichier |
|----------|-----------|---------|---------|---------|
| Création membre | `enforceCommunityPlanLimits()` | Auto-suspend | N/A (membres excédentaires suspendus) | subscriptionGuards.ts:243 |
| Création tag | `requireWithinLimit("maxTags")` | 403 | "Plan limit reached for tags" | routes.ts (via middleware) |
| Création événement | `requireWithinLimit("maxEvents")` | 403 | "Plan limit reached for events" | routes.ts (via middleware) |

### 4.4 Stripe Webhooks

| Événement | Handler | Action | Fichier |
|-----------|---------|--------|---------|
| `invoice.payment_failed` | `handlePaymentFailed()` | ACTIVE → IMPAYE_1 + email | stripe.ts:977-1044 |
| `invoice.payment_succeeded` | `handlePaymentSucceeded()` | IMPAYE_* → ACTIVE + cancel purge + email | stripe.ts:897-974 |
| `customer.subscription.updated` | `handleSubscriptionUpdated()` | Met à jour subscriptionStatus legacy | stripe.ts:652 |
| `customer.subscription.deleted` | `handleSubscriptionDeleted()` | subscriptionStatus → canceled | stripe.ts:658 |

### 4.5 Jobs CRON

| Nom | Endpoint | Fréquence | Action | Lock ID | Fichiers |
|-----|----------|-----------|--------|---------|----------|
| SaaS Status Transitions | `POST /api/internal/cron/saas-status` | Quotidien (Railway) | Transitions J+N + emails + purges | 8675309 | routes.ts:12295, saasStatusJob.ts |

#### Détail du Job SaaS Status

```
DÉCLENCHEMENT: POST /api/internal/cron/saas-status
SÉCURITÉ: Header x-cron-secret = CRON_SECRET
VERROU: PostgreSQL cron_locks avec expiration 10min + ownership token

ÉTAPES:
1. Acquérir verrou distribué (tryAcquireAdvisoryLock)
2. Si verrou acquis:
   a. Transitions IMPAYE_1 → IMPAYE_2 (J+15)
   b. Transitions IMPAYE_2 → SUSPENDU (J+30)
   c. Transitions SUSPENDU → RESILIE (J+60) + schedulePurge
   d. Emails pré-escalade (J+27, J+57)
   e. Exécution purges planifiées (J+90)
3. Libérer verrou (releaseAdvisoryLock)
4. Retourner résumé des transitions
```

#### Calcul des Seuils (getCommunitiesNeedingStatusTransition)

```typescript
// server/storage.ts lignes 3480-3520

IMPAYE_1 → IMPAYE_2: WHERE saas_client_status = 'IMPAYE_1' 
                     AND unpaid_since <= NOW() - 15 days

IMPAYE_2 → SUSPENDU: WHERE saas_client_status = 'IMPAYE_2' 
                     AND unpaid_since <= NOW() - 30 days

SUSPENDU → RESILIE:  WHERE saas_client_status = 'SUSPENDU' 
                     AND unpaid_since <= NOW() - 60 days
```

### 4.6 Service de Purge

#### Tables Supprimées (ordre de dépendance)

```
1. member_tags              11. membership_fees
2. article_tags             12. membership_plans
3. article_sections         13. messages
4. event_attendance         14. support_tickets
5. event_registrations      15. events
6. ticket_responses         16. news_articles
7. subscription_emails_sent 17. enrollment_requests
8. subscription_status_audit 18. user_community_memberships
9. community_monthly_usage  19. tags
10. transactions, payments, 20. categories, sections
    payment_requests,       21. community_member_profile_config
    collections             22. communities (dernier)
```

#### Object Storage

```typescript
// server/services/purgeService.ts:86-118

Chemins supprimés:
- public/communities/{communityId}/*
- .private/communities/{communityId}/*
```

---

## 5. Frontend: Comportement UI

### 5.1 Composants de Statut

| Composant | Statuts affichés | UX | Fichier |
|-----------|------------------|-------|---------|
| `SaasStatusBanner` | IMPAYE_1, IMPAYE_2 | Bannière d'alerte avec CTA "Régulariser" | SaasStatusBanner.tsx:13-102 |
| `SaasBlockedPage` | SUSPENDU, RESILIE | Page bloquante full-screen | SaasStatusBanner.tsx:113-206 |

### 5.2 Tableau Feature / Statut Bloquant / UX

| Feature | Statut Bloquant | UX Actuelle | Fichier |
|---------|-----------------|-------------|---------|
| Back-office complet | SUSPENDU, RESILIE | Page bloquante SaasBlockedPage | SaasStatusBanner.tsx |
| Événements payants | past_due, canceled, trialing | 403 côté API | routes.ts:7298 |
| Login mobile | suspendedByQuotaLimit (tous) | 403 + message | routes.ts:1797 |
| Création membre | Quota dépassé | Auto-suspension membres excédentaires | subscriptionGuards.ts:243 |

### 5.3 Indicateurs Visuels

| Statut | Couleur | Icône | data-testid |
|--------|---------|-------|-------------|
| IMPAYE_1 | Amber (bg-amber-50) | AlertTriangle | banner-impaye-1 |
| IMPAYE_2 | Orange (bg-orange-50) | AlertTriangle | banner-impaye-2 |
| SUSPENDU | Orange (bg-orange-100) | XCircle | page-blocked-suspendu |
| RESILIE | Rouge (bg-red-100) | XCircle | page-blocked-resilie |

### 5.4 Affichage Membres Suspendus

| Composant | Affichage | Fichier |
|-----------|-----------|---------|
| AdminLayout | Badge "X membre(s) suspendu(s) (limite: 20)" | AdminLayout.tsx:259-262 |
| MobileAdminLayout | Badge "X suspendu(s)" | MobileAdminLayout.tsx:262-265 |
| Members list | Badge "Désactivé (limite du plan)" | Members.tsx:688-698 |

---

## 6. Observabilité / Logs

### 6.1 Logs Structurés

| Type | Format | Fichier |
|------|--------|---------|
| Transition SaaS | `[CRON] Starting SaaS status transitions at {timestamp}` | routes.ts:12317 |
| Purge planifiée | `{ type: "purge_scheduled", communityId, purgeScheduledAt }` | purgeService.ts:282-289 |
| Purge annulée | `{ type: "purge_canceled", communityId, reason }` | purgeService.ts:292-298 |
| Purge exécutée | `{ type: "purge_executed", ...result }` | purgeService.ts:301-306 |
| Email envoyé | `Email {emailType} sent for community {communityId}` | saasEmailService.ts |

### 6.2 Audit Trail

Table `subscription_status_audit`:
- Chaque transition est enregistrée avec horodatage
- Métadonnées enrichies (stripeEventId, montants, unpaidSince préservé)
- Requêtable via `storage.getSaasStatusAudit(communityId)`

### 6.3 TraceID

| Endpoint | Préfixe | Exemple |
|----------|---------|---------|
| Login mobile | `[Login {traceId}]` | `[Login LG-abc123]` |
| Me endpoint | `[ME {traceId}]` | `[ME ME-def456]` |
| CRON job | `[CRON]` | `[CRON] Starting...` |
| Purge | `[PURGE]` | `[PURGE] Scheduled...` |

---

## 7. Tests Existants

### 7.1 Tests Unitaires

| Fichier | Couverture | Statut |
|---------|------------|--------|
| server/tests/purge-service.test.ts | Contrats purge (PurgeResult, status, tables) | ✅ Présent |
| server/tests/subscription-state.test.ts | Transitions d'état (mock) | ✅ Présent |

### 7.2 Manques Évidents

| Type | Description | Impact |
|------|-------------|--------|
| Tests E2E | Cycle complet ACTIVE→PURGE avec webhooks mockés | High |
| Tests intégration | CRON job avec base de données réelle | Medium |
| Tests UI | SaasStatusBanner et SaasBlockedPage | Low |
| Tests email | Déduplication et contenu | Medium |

---

## 8. Incohérences / Risques Identifiés

| # | Catégorie | Description | Sévérité | Recommandation |
|---|-----------|-------------|----------|----------------|
| 1 | API Guard | Pas de blocage API explicite pour SUSPENDU/RESILIE sur tous les endpoints back-office | Medium | Ajouter middleware global `requireActiveSaasStatus()` |
| 2 | Frontend | SaasStatusBanner non intégré dans tous les layouts | Low | Vérifier intégration AdminLayout principal |
| 3 | Export | Bouton "Exporter mes données" sur SaasBlockedPage - endpoint non vérifié | Medium | Vérifier/implémenter export RGPD |
| 4 | Purge | catch(() => {}) silencieux sur suppressions de tables | Low | Logger les erreurs de suppression |
| 5 | Email | Pas de retry en cas d'échec SMTP | Medium | Implémenter queue avec retry |
| 6 | Verrou | Expiration 10min peut être courte si job long | Low | Augmenter à 30min ou refresh périodique |

---

## 9. Checklist de Validation Fonctionnelle

### Scénarios de Test

| # | Scénario | Préconditions | Actions | Résultat Attendu |
|---|----------|---------------|---------|------------------|
| 1 | Impayé initial | Community ACTIVE, billingMode=self_service | Déclencher webhook `invoice.payment_failed` | Statut → IMPAYE_1, email envoyé |
| 2 | Escalade J+15 | Community IMPAYE_1, unpaidSince < J-15 | Exécuter CRON job | Statut → IMPAYE_2, email envoyé |
| 3 | Suspension J+30 | Community IMPAYE_2, unpaidSince < J-30 | Exécuter CRON job | Statut → SUSPENDU, suspendedAt set, email envoyé |
| 4 | Résiliation J+60 | Community SUSPENDU, unpaidSince < J-60 | Exécuter CRON job | Statut → RESILIE, purge planifiée J+90 |
| 5 | Purge J+90 | Community RESILIE, purgeScheduledAt <= now | Exécuter CRON job | Données supprimées, purgeStatus=executed |
| 6 | Réactivation | Community IMPAYE_2 | Déclencher webhook `invoice.payment_succeeded` | Statut → ACTIVE, timestamps reset |
| 7 | Réactivation annule purge | Community RESILIE, purgeStatus=scheduled | Déclencher webhook payment_succeeded | Statut → ACTIVE, purgeStatus=canceled_by_reactivation |
| 8 | Blocage UI suspendu | Community SUSPENDU | Accéder au back-office | SaasBlockedPage affiché |
| 9 | Quota dépassé | Community FREE, 25 membres | Ajouter 6ème membre | Membres 21-25 suspendedByQuotaLimit=true |
| 10 | Déduplication email | IMPAYE_1, email déjà envoyé | Re-trigger payment_failed | Pas de nouvel email |

---

## 10. Comment Reproduire

### 10.1 Déclencher Transition IMPAYE_1

```bash
# Webhook Stripe simulé (remplacer les IDs)
curl -X POST https://your-domain/api/webhooks/stripe \
  -H "Content-Type: application/json" \
  -H "stripe-signature: FAKE_SIG_FOR_TEST" \
  -d '{
    "type": "invoice.payment_failed",
    "data": {
      "object": {
        "id": "in_test_123",
        "subscription": "sub_test_456",
        "amount_due": 2900,
        "currency": "eur"
      }
    }
  }'
```

### 10.2 Exécuter CRON Job Manuellement

```bash
# Endpoint CRON (nécessite secret)
curl -X POST https://your-domain/api/internal/cron/saas-status \
  -H "x-cron-secret: YOUR_CRON_SECRET"
```

### 10.3 Vérifier Statut Community

```sql
-- Dans la console PostgreSQL
SELECT id, name, saas_client_status, unpaid_since, suspended_at, 
       terminated_at, purge_scheduled_at, purge_status
FROM communities 
WHERE billing_mode = 'self_service';
```

### 10.4 Vérifier Audit Trail

```sql
SELECT * FROM subscription_status_audit 
WHERE community_id = 'your-community-id'
ORDER BY created_at DESC
LIMIT 10;
```

### 10.5 Vérifier Emails Envoyés

```sql
SELECT * FROM subscription_emails_sent
WHERE community_id = 'your-community-id'
ORDER BY created_at DESC;
```

### 10.6 Simuler Réactivation

```bash
# Webhook Stripe payment_succeeded
curl -X POST https://your-domain/api/webhooks/stripe \
  -H "Content-Type: application/json" \
  -H "stripe-signature: FAKE_SIG_FOR_TEST" \
  -d '{
    "type": "invoice.payment_succeeded",
    "data": {
      "object": {
        "id": "in_test_789",
        "subscription": "sub_test_456",
        "amount_paid": 2900,
        "currency": "eur"
      }
    }
  }'
```

---

## Annexes

### A. Constantes Clés

| Constante | Valeur | Fichier |
|-----------|--------|---------|
| `DAY_IN_MS` | 86400000 | saasStatusJob.ts:11, purgeService.ts:33 |
| `PURGE_DELAY_DAYS_AFTER_RESILIE` | 30 | purgeService.ts:34 |
| `SAAS_STATUS_LOCK_ID` | 8675309 | routes.ts:12293 |
| Lock expiration | 10 minutes | storage.ts:3701 |

### B. Références Documentation

| Document | Chemin |
|----------|--------|
| Plan implémentation SaaS paiement | docs/plan-implementation-saas-paiement.md |
| Contrat identité onboarding | docs/architecture/CONTRAT_IDENTITE_ONBOARDING_2026-01.md |
| Inventory plans/capabilities | docs/contracts/2026-01/STATE_plans-capabilities-limits_inventory.md |

---

*Fin du rapport d'audit — Généré le 2026-01-25*
