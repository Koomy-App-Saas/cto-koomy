# 2026-01-28__DATABASE__prod_v2_schema_expected_from_code__REPORT

## Objective
Document toutes les tables/colonnes attendues par le backend Koomy (source: code Drizzle).

## Source de vérité
- **Fichier principal**: `shared/schema.ts`
- **Validator au startup**: `server/index.ts` (fonction `validateDatabaseSchema`)

## Colonnes requises par le startup validator

Le backend crash si ces colonnes manquent dans `communities`:

| Colonne | Type | Défini dans | Requis |
|---------|------|-------------|--------|
| `max_admins_default` | INTEGER | shared/schema.ts:341 | ✅ OUI |
| `contract_admin_limit` | INTEGER | shared/schema.ts:380 | ✅ OUI |

## Tables attendues par le code (shared/schema.ts)

### Tables d'authentification (Firebase-only compatible)

| Table | Lignes | Description |
|-------|--------|-------------|
| `users` | 414-433 | Back-office admins + platform admins (firebase_uid UNIQUE) |
| `user_identities` | 438-452 | Identités multi-provider (Firebase/Legacy) |
| `accounts` | 192-204 | Comptes membres mobile app (providerId = Firebase UID) |
| `platform_verification_tokens` | 469-476 | Tokens vérification email |
| `platform_sessions` | 479-488 | Sessions admin (2h expiry) |
| `admin_invitations` | 456-466 | Invitations admin |

### Tables métier core

| Table | Lignes | Description |
|-------|--------|-------------|
| `plans` | 241-262 | Plans SaaS (FREE/PLUS/PRO/GRAND_COMPTE) |
| `communities` | 283-412 | Tenants avec config Stripe/White-Label/SaaS |
| `user_community_memberships` | 568-618 | Junction membres/admins |
| `sections` | 625-634 | Sections régionales |
| `membership_plans` | 892-909 | Formules d'adhésion |
| `community_member_profile_config` | 739-747 | Config profil membre |

### Tables de contenu

| Table | Lignes | Description |
|-------|--------|-------------|
| `news_articles` | 750-764 | Articles |
| `categories` | 1015-1024 | Catégories articles |
| `events` | 767-794 | Événements V2 |
| `event_registrations` | 797-810 | RSVP événements |
| `event_attendance` | 813-820 | Présence |
| `messages` | 868-877 | Messagerie |
| `tags` | 1027-1039 | Tags segmentation |
| `member_tags` | 1042-1046 | Pivot membre-tag |
| `article_tags` | 1049-1054 | Pivot article-tag |
| `article_sections` | 1057-1064 | Pivot article-section |

### Tables paiements

| Table | Lignes | Description |
|-------|--------|-------------|
| `collections` | 943-957 | Cagnottes |
| `transactions` | 964-982 | Transactions unifiées |
| `payments` | 927-940 | Paiements legacy |
| `payment_requests` | 912-924 | Demandes paiement |
| `membership_fees` | 880-889 | DEPRECATED |

### Tables support/analytics

| Table | Lignes | Description |
|-------|--------|-------------|
| `support_tickets` | 833-846 | Tickets support |
| `ticket_responses` | 849-856 | Réponses tickets |
| `faqs` | 859-865 | FAQ |
| `platform_metrics_daily` | 1177-1195 | Métriques santé |
| `community_monthly_usage` | 823-830 | Usage quotas événements |

### Tables audit

| Table | Lignes | Description |
|-------|--------|-------------|
| `platform_audit_logs` | 490-512 | Audit actions plateforme |
| `contract_audit_log` | 516-529 | Audit contrats |
| `subscription_status_audit` | 1068-1079 | Audit statuts SaaS |
| `subscription_emails_sent` | 1083-1091 | Anti-duplicate emails |

### Tables commerciales

| Table | Lignes | Description |
|-------|--------|-------------|
| `commercial_contacts` | ~990 | Leads site web |
| `email_templates` | ~997-1002 | Templates email |
| `email_logs` | 1005-1012 | Logs emails |
| `enrollment_requests` | 638-675 | Self-enrollment |

## Enums requis (43 enums)

Tous ces enums sont créés par le patch SQL:

| Enum | Values |
|------|--------|
| `subscription_status` | trialing, active, past_due, canceled |
| `billing_status` | trialing, active, past_due, canceled, unpaid |
| `member_status` | active, expired, suspended |
| `contribution_status` | up_to_date, expired, pending, late |
| `admin_role` | super_admin, support_admin, finance_admin, content_admin, admin |
| `user_global_role` | platform_super_admin, platform_ops, platform_support, platform_finance, platform_commercial, platform_readonly |
| `billing_period` | one_time, monthly, yearly |
| `billing_mode` | self_service, manual_contract |
| `white_label_tier` | basic, standard, premium |
| `maintenance_status` | active, pending, late, stopped |
| `stripe_connect_status` | NOT_CONNECTED, ONBOARDING_REQUIRED, PENDING_REVIEW, RESTRICTED, ACTIVE, DISCONNECTED |
| `account_type` | STANDARD, GRAND_COMPTE |
| `saas_client_status` | ACTIVE, IMPAYE_1, IMPAYE_2, SUSPENDU, RESILIE |
| `saas_transition_reason` | PAYMENT_FAILED, PAYMENT_SUCCEEDED, DELAY_EXPIRED, MANUAL |
| `purge_status` | scheduled, canceled_by_reactivation, executed |
| `self_enrollment_channel` | OFFLINE, ONLINE |
| `self_enrollment_mode` | OPEN, CLOSED |
| `auth_mode` | FIREBASE_ONLY, LEGACY_ONLY |
| `identity_provider` | FIREBASE, LEGACY_KOOMY |
| `membership_billing_type` | one_time, annual |
| `membership_plan_type` | FIXED_PERIOD, ROLLING_DURATION |
| `fixed_period_type` | CALENDAR_YEAR, SEASON |
| `membership_payment_status` | free, due, paid |
| `salutation_enum` | M, Mme, Autre |
| `ticket_status` | open, in_progress, resolved, closed |
| `ticket_priority` | low, medium, high |
| `news_status` | draft, published |
| `scope` | national, local |
| `payment_status` | pending, completed, failed, refunded |
| `payment_request_status` | pending, paid, expired, cancelled |
| `email_type` | welcome_community_admin, invite_delegate, invite_member, reset_password, verify_email, new_event, new_collection, collection_contribution_thanks, message_to_admin |
| `collection_status` | open, closed, canceled |
| `transaction_type` | subscription, membership, collection |
| `transaction_status` | pending, succeeded, failed, refunded |
| `tag_type` | user, content, hybrid |
| `event_visibility_mode` | ALL, SECTION, TAGS |
| `event_rsvp_mode` | NONE, OPTIONAL, REQUIRED, APPROVAL |
| `event_status` | DRAFT, PUBLISHED, CANCELLED |
| `event_registration_status` | GOING, NOT_GOING, WAITLIST, PENDING, CANCELLED |
| `event_payment_status` | NONE, PENDING, PAID, FAILED, REFUNDED |
| `attendance_source` | QR_SCAN, MANUAL |
| `enrollment_request_status` | PENDING, APPROVED, REJECTED, CANCELLED, EXPIRED, CONVERTED |
| `audit_action_enum` | login, logout, session_expired, ... (20 values) |

## Usage table `accounts` (Firebase-only compatible)

La table `accounts` EST utilisée par le code pour les membres mobile:

```typescript
// server/storage.ts - utilisé pour lookup membre
const [account] = await db.select().from(accounts).where(
  and(eq(accounts.providerId, providerId), eq(accounts.authProvider, authProvider))
);

// server/middlewares/attachAuthContext.ts - auth Firebase membres
.where(and(eq(accounts.providerId, decoded.uid), eq(accounts.authProvider, "firebase")))
```

**Conclusion**: `accounts` est REQUIS pour l'auth Firebase des membres. Le champ `providerId` stocke le Firebase UID.

## Check-list d'acceptance

- [ ] Table `communities` contient `max_admins_default` INTEGER
- [ ] Table `communities` contient `contract_admin_limit` INTEGER
- [ ] Table `users` contient `firebase_uid` TEXT UNIQUE
- [ ] Table `accounts` contient `provider_id` TEXT + `auth_provider` TEXT
- [ ] Table `accounts` a `password_hash` NULLABLE (pour Firebase accounts)
- [ ] Index UNIQUE sur `accounts(auth_provider, provider_id)` existe
- [ ] Tous les 43 enums sont créés
- [ ] Backend Railway démarre sans "DATABASE SCHEMA MISMATCH"
- [ ] Endpoint `/health` répond OK

## Commandes de vérification

```sql
-- Vérifier colonnes manquantes communities
SELECT column_name 
FROM information_schema.columns 
WHERE table_name = 'communities' 
  AND column_name IN ('max_admins_default', 'contract_admin_limit');

-- Doit retourner 2 lignes

-- Vérifier table users avec firebase_uid
SELECT column_name, is_nullable, data_type 
FROM information_schema.columns 
WHERE table_name = 'users' AND column_name = 'firebase_uid';

-- Vérifier table accounts
SELECT column_name 
FROM information_schema.columns 
WHERE table_name = 'accounts' 
  AND column_name IN ('provider_id', 'auth_provider');
```
