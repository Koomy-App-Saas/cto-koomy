# Koomy - Documentation Technique

**Dernière mise à jour : 22 janvier 2026, 09:00 UTC**
**Audit interne : 22 janvier 2026**

---

## Table des Matières

1. [Vue d'Ensemble](#1-vue-densemble)
2. [Architecture Système](#2-architecture-système)
3. [Stack Technologique](#3-stack-technologique)
4. [Structure du Projet](#4-structure-du-projet)
5. [Modèle de Données](#5-modèle-de-données)
6. [API Backend](#6-api-backend)
7. [Applications Frontend](#7-applications-frontend)
8. [Modèle Économique](#8-modèle-économique)
9. [Intégrations Externes](#9-intégrations-externes)
10. [Sécurité et Authentification](#10-sécurité-et-authentification)
11. [Environnements Sandbox/Production](#11-environnements-sandboxproduction)
12. [Déploiement](#12-déploiement)
13. [État Actuel du Développement](#13-état-actuel-du-développement)
14. [Change Log - Audit Update](#14-change-log---audit-update)

---

## 1. Vue d'Ensemble

### Description

Koomy est une plateforme SaaS multi-tenant de gestion de communautés, destinée aux syndicats, clubs, associations et organisations à but non lucratif. Elle offre un écosystème digital complet comprenant :

- **Application mobile membre** (`/app/*`) : Accès aux actualités, événements, carte de membre virtuelle, paiements
- **Application mobile admin** (`/app/admin/*`) : Gestion opérationnelle pour les administrateurs sur le terrain
- **Backoffice web** (`/admin/*`) : Interface complète de gestion pour les administrateurs de communauté
- **Portail plateforme** (`/platform/*`) : Supervision globale pour les super-administrateurs Koomy
- **Site web commercial** (`/`) : Acquisition clients, tarifs, démo, contact

### Langues Supportées

- Français (principal)
- Anglais (en cours d'implémentation via react-i18next)

---

## 2. Architecture Système

### Architecture Multi-Tenant

```
┌─────────────────────────────────────────────────────────────────────┐
│                           KOOMY PLATFORM                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐   │
│  │ Community A │ │ Community B │ │ Community C │ │ Community N │   │
│  │ (Tenant 1)  │ │ (Tenant 2)  │ │ (Tenant 3)  │ │ (Tenant N)  │   │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘   │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │                    SHARED INFRASTRUCTURE                      │   │
│  │  ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐ │   │
│  │  │ Express.js │ │ PostgreSQL │ │   Stripe   │ │  SendGrid  │ │   │
│  │  │  (API)     │ │   (Neon)   │ │ (Payments) │ │  (Emails)  │ │   │
│  │  └────────────┘ └────────────┘ └────────────┘ └────────────┘ │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Isolation des Données

- Chaque communauté est identifiée par un `communityId` (UUID)
- Toutes les tables tenant-specific contiennent une référence `communityId`
- Les requêtes sont systématiquement filtrées par `communityId`
- Pas de partage de données entre communautés

---

## 3. Stack Technologique

### Frontend

| Technologie | Version | Usage |
|-------------|---------|-------|
| React | 19.2.0 | Framework UI |
| TypeScript | 5.6.3 | Typage statique |
| Vite | 7.3.0 | Build tool & dev server |
| Wouter | 3.3.5 | Routing client |
| TanStack Query | 5.60.5 | State management serveur |
| Tailwind CSS | 4.1.14 | Styling utility-first |
| shadcn/ui | - | Composants UI (Radix-based) |
| Radix UI | * | Primitives accessibles |
| Lucide React | 0.545.0 | Icônes |
| Framer Motion | 12.23.24 | Animations |
| react-i18next | 16.3.5 | Internationalisation |
| react-hook-form | 7.66.0 | Gestion formulaires |
| Recharts | 2.15.4 | Graphiques |
| react-qr-code | 2.0.18 | Génération QR codes |

### Backend

| Technologie | Version | Usage |
|-------------|---------|-------|
| Node.js | 20.x | Runtime |
| Express.js | 4.21.2 | Framework HTTP |
| TypeScript | 5.6.3 | Typage statique |
| tsx | 4.20.5 | Runtime TypeScript |
| Drizzle ORM | 0.39.1 | ORM type-safe |
| drizzle-zod | 0.7.0 | Validation schémas |
| Zod | 3.25.76 | Validation runtime |
| Passport.js | 0.7.0 | Authentification |
| bcryptjs | 3.0.3 | Hachage mots de passe |
| express-session | 1.18.1 | Gestion sessions |

### Base de Données

| Technologie | Version | Usage |
|-------------|---------|-------|
| PostgreSQL | 16 | Base de données |
| Neon | - | Hébergement serverless |
| @neondatabase/serverless | 0.10.4 | Client WebSocket |
| Drizzle Kit | 0.31.4 | Migrations |

### Services Externes

| Service | Usage |
|---------|-------|
| Stripe | Paiements (Billing + Connect Express) |
| SendGrid | Envoi d'emails transactionnels |
| OpenAI | Génération de contenu IA (actif via AI Integrations) |
| Cloudflare R2 | Stockage d'objets (production) |
| Replit Object Storage | Stockage d'objets (développement) |
| Cloudflare CDN | Distribution d'assets (cdn.koomy.app / cdn-sandbox.koomy.app) |
| Firebase Auth | Authentification (mode keyless, Google Sign-In) |

---

## 4. Structure du Projet

```
koomy/
├── client/                     # Frontend React
│   ├── src/
│   │   ├── components/         # Composants réutilisables
│   │   │   ├── ui/            # shadcn/ui components
│   │   │   └── layouts/       # Layouts (Mobile, Admin, etc.)
│   │   ├── pages/             # Pages par contexte
│   │   │   ├── admin/         # Backoffice web (17 pages)
│   │   │   ├── mobile/        # App mobile membre (15 pages)
│   │   │   │   └── admin/     # App mobile admin (12 pages)
│   │   │   ├── platform/      # Portail super-admin (2 pages)
│   │   │   └── website/       # Site commercial (11 pages)
│   │   ├── hooks/             # Custom React hooks
│   │   ├── lib/               # Utilitaires (queryClient, utils)
│   │   ├── i18n/              # Traductions FR/EN
│   │   ├── App.tsx            # Routes principales
│   │   └── main.tsx           # Point d'entrée
│   └── index.html
│
├── server/                     # Backend Express
│   ├── services/
│   │   └── mailer/            # Service d'emails
│   │       ├── mailer.ts      # Logique SendGrid
│   │       ├── emailTypes.ts  # Types d'emails
│   │       └── renderer.ts    # Templates HTML
│   ├── db.ts                  # Connexion PostgreSQL
│   ├── index.ts               # Serveur Express
│   ├── routes.ts              # 228 endpoints API (11k+ lignes)
│   ├── storage.ts             # Repository pattern (3645 lignes)
│   ├── stripe.ts              # Stripe Billing
│   ├── stripeConnect.ts       # Stripe Connect Express
│   ├── stripeClient.ts        # Client Stripe mutualisé
│   ├── objectStorage.ts       # Object Storage (R2/Replit)
│   ├── seed.ts                # Données de seed
│   ├── static.ts              # Fichiers statiques (prod)
│   └── vite.ts                # Middleware Vite (dev)
│
├── shared/
│   └── schema.ts              # Schéma Drizzle (1214 lignes)
│
├── package.json
├── tsconfig.json
├── vite.config.ts
├── drizzle.config.ts
└── .replit
```

---

## 5. Modèle de Données

### Tables Principales

#### Tables Plateforme (Niveau Global)

| Table | Description |
|-------|-------------|
| `plans` | Plans d'abonnement Koomy (Free, Standard, Pro, Enterprise) |
| `accounts` | Comptes utilisateurs app mobile (email/password) |
| `users` | Administrateurs backoffice et plateforme |
| `faqs` | Questions fréquentes |
| `commercialContacts` | Prospects du site commercial |
| `emailTemplates` | Templates d'emails personnalisables |
| `emailLogs` | Historique des emails envoyés |

#### Tables Tenant (Par Communauté)

| Table | Description |
|-------|-------------|
| `communities` | Communautés (tenants) avec config |
| `userCommunityMemberships` | Adhésions membre-communauté |
| `sections` | Divisions régionales/locales |
| `newsArticles` | Actualités |
| `events` | Événements |
| `supportTickets` | Tickets de support |
| `ticketResponses` | Réponses aux tickets |
| `messages` | Messages membre-admin |
| `membershipFees` | Tarifs de cotisation |
| `paymentRequests` | Demandes de paiement |
| `payments` | Paiements complétés |
| `collections` | Cagnottes/collectes |
| `transactions` | Transactions unifiées |

### Énumérations (Enums)

```typescript
// Statuts d'abonnement
subscriptionStatusEnum: ["active", "past_due", "canceled"]

// Statuts de membre
memberStatusEnum: ["active", "expired", "suspended"]

// Statuts de contribution
contributionStatusEnum: ["up_to_date", "expired", "pending", "late"]

// Rôles admin plateforme
userGlobalRoleEnum: ["platform_super_admin", "platform_support", "platform_commercial"]

// Statuts de collecte
collectionStatusEnum: ["open", "closed", "canceled"]

// Types de transaction
transactionTypeEnum: ["subscription", "membership", "collection"]

// Statuts de transaction
transactionStatusEnum: ["pending", "succeeded", "failed", "refunded"]

// Types d'emails
emailTypeEnum: [
  "welcome_community_admin",
  "invite_delegate",
  "invite_member",
  "reset_password",
  "verify_email",
  "new_event",
  "new_collection",
  "collection_contribution_thanks",
  "message_to_admin"
]
```

### Diagramme de Relations Simplifié

```
accounts ──────┐
               ├──► userCommunityMemberships ◄──── users
               │            │
               │            ▼
communities ◄──┴─────── (communityId) ──────┐
     │                                       │
     ├── newsArticles                        │
     ├── events                              │
     ├── sections                            │
     ├── messages                            │
     ├── supportTickets                      │
     │       └── ticketResponses             │
     ├── membershipFees                      │
     │       └── paymentRequests             │
     ├── payments                            │
     ├── collections ──────────┐             │
     │                         │             │
     └── transactions ◄────────┴─────────────┘
```

---

## 6. API Backend

### Vue d'Ensemble

- **Base URL** : `/api/*`
- **Format** : JSON
- **Authentification** : Sessions Express (cookie-based)
- **Validation** : Zod schemas

### Catégories d'Endpoints (228 routes - audit janvier 2026)

| Catégorie | Endpoints | Description |
|-----------|-----------|-------------|
| Auth | ~8 | Login, register, logout, password reset |
| Communities | ~10 | CRUD communautés, configuration |
| Members | ~12 | Gestion des membres, adhésions |
| News | ~6 | Articles, publication |
| Events | ~6 | Événements, participations |
| Messages | ~6 | Messagerie membre-admin |
| Payments | ~15 | Stripe, cotisations, collectes |
| Support | ~8 | Tickets, FAQ |
| Platform | ~10 | Super-admin, analytics |
| Files | ~5 | Upload, Object Storage |
| Misc | ~30 | Autres endpoints |

### Patterns API Principaux

```typescript
// Pattern GET liste
GET /api/communities/:communityId/members
→ Returns: Member[]

// Pattern GET détail
GET /api/communities/:communityId/members/:memberId
→ Returns: Member

// Pattern POST création
POST /api/communities/:communityId/members
Body: { email, displayName, role, ... }
→ Returns: { memberId, claimCode }

// Pattern PATCH mise à jour
PATCH /api/communities/:communityId/members/:memberId
Body: { status, section, ... }
→ Returns: Member

// Pattern DELETE suppression
DELETE /api/communities/:communityId/members/:memberId
→ Returns: { success: true }
```

---

## 7. Applications Frontend

### 7.1 Application Mobile Membre (`/app/*`)

**Routes principales :**
- `/app/login` - Connexion compte
- `/app/hub` - Hub multi-communautés
- `/app/:communityId/home` - Accueil communauté
- `/app/:communityId/news` - Actualités
- `/app/:communityId/events` - Événements
- `/app/:communityId/card` - Carte de membre virtuelle
- `/app/:communityId/messages` - Messagerie
- `/app/:communityId/profile` - Profil
- `/app/:communityId/payment` - Paiement cotisation

**Fonctionnalités :**
- Carte de membre virtuelle avec QR code
- Consultation actualités et événements
- Participation aux collectes
- Messagerie avec les administrateurs
- Paiement des cotisations

### 7.2 Application Mobile Admin (`/app/admin/*`)

**Routes principales :**
- `/app/admin/login` - Connexion admin
- `/app/:communityId/admin` - Tableau de bord
- `/app/:communityId/admin/scanner` - Scanner QR présence
- `/app/:communityId/admin/members` - Gestion membres
- `/app/:communityId/admin/articles` - Gestion actualités
- `/app/:communityId/admin/events` - Gestion événements
- `/app/:communityId/admin/collections` - Gestion collectes
- `/app/:communityId/admin/finances` - Finances

**Fonctionnalités :**
- Scanner QR codes pour pointage présence
- Gestion rapide des membres sur le terrain
- Publication d'actualités urgentes
- Suivi des collectes en temps réel

### 7.3 Backoffice Web (`/admin/*`)

**Routes principales :**
- `/admin/login` - Connexion
- `/admin/register` - Création communauté
- `/admin/select-community` - Sélection communauté
- `/admin/dashboard` - Tableau de bord
- `/admin/members` - Gestion membres complète
- `/admin/news` - Gestion actualités
- `/admin/events` - Gestion événements
- `/admin/messages` - Messagerie
- `/admin/finances` - Finances et collectes
- `/admin/payments` - Configuration paiements
- `/admin/billing` - Abonnement Koomy
- `/admin/settings` - Paramètres communauté

**Fonctionnalités :**
- Gestion complète des membres (import Excel)
- Configuration de la communauté
- Personnalisation couleurs et logo
- Gestion des sections/régions
- Configuration Stripe Connect
- Tableau de bord analytique

### 7.4 Portail Plateforme (`/platform/*`)

**Routes :**
- `/platform/login` - Connexion super-admin
- `/platform/dashboard` - Super Dashboard

**Fonctionnalités :**
- Vue globale toutes communautés
- Gestion des plans et abonnements
- Octroi Full Access VIP
- Analytics plateforme
- Gestion des contacts commerciaux

### 7.5 Site Web Commercial (`/`)

**Routes :**
- `/` - Page d'accueil
- `/pricing` - Tarifs
- `/demo` - Demande de démo
- `/contact` - Contact
- `/faq` - FAQ
- `/blog` - Blog
- `/support` - Support
- `/terms` - CGU
- `/privacy` - Politique de confidentialité
- `/legal` - Mentions légales

---

## 8. Modèle Économique

### 8.1 Flux de Revenus

```
┌─────────────────────────────────────────────────────────────────────┐
│                        MODÈLE ÉCONOMIQUE KOOMY                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  FLUX 1: ABONNEMENTS SAAS (Stripe Billing)                          │
│  ┌────────────────────────────────────────┐                         │
│  │ Communauté ──► Koomy                   │                         │
│  │ (Abonnement mensuel/annuel)            │                         │
│  │                                         │                         │
│  │ Plans: Free / Standard / Pro / Custom   │                         │
│  └────────────────────────────────────────┘                         │
│                                                                      │
│  FLUX 2: PAIEMENTS COMMUNAUTAIRES (Stripe Connect Express)          │
│  ┌────────────────────────────────────────┐                         │
│  │ Membre ──► Communauté (via Koomy)      │                         │
│  │                                         │                         │
│  │ • Cotisations                           │                         │
│  │ • Collectes/Cagnottes                   │                         │
│  │                                         │                         │
│  │ Commission Koomy: 2% par défaut         │                         │
│  └────────────────────────────────────────┘                         │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### 8.2 Plans Tarifaires

| Plan | Prix/mois | Prix/an | Membres max | Fonctionnalités |
|------|-----------|---------|-------------|-----------------|
| **Free** | 0€ | 0€ | 50 | Basique, pas de paiements |
| **Standard** | ~29€ | ~290€ | 1 000 | Toutes fonctionnalités |
| **Pro** | ~79€ | ~790€ | 5 000 | + Support prioritaire |
| **Enterprise** | Sur devis | - | Illimité | White-label possible |

### 8.3 Schéma de Données Paiements

```typescript
// Table transactions
{
  id: string,
  communityId: string,
  membershipId: string | null,
  collectionId: string | null,
  type: "subscription" | "membership" | "collection",
  amountTotalCents: number,          // Montant total payé
  amountFeeKoomyCents: number,       // Commission Koomy (2%)
  amountToCommunity: number,         // Net pour la communauté
  stripePaymentIntentId: string,
  stripeChargeId: string,
  stripeTransferId: string,          // Transfert vers compte Connect
  stripeApplicationFeeId: string,    // ID de la commission Koomy
  status: "pending" | "succeeded" | "failed" | "refunded",
  createdAt: Date,
  completedAt: Date
}
```

---

## 9. Intégrations Externes

### 9.1 Stripe

**Stripe Billing (Abonnements SaaS)**
- Création produits et prix
- Gestion abonnements communautés
- Webhooks : `invoice.paid`, `customer.subscription.updated`, etc.

**Stripe Connect Express (Paiements Communautaires)**
- Onboarding Express pour chaque communauté
- Création sessions de paiement
- Transferts automatiques avec commission
- Webhooks : `checkout.session.completed`, `account.updated`

### 9.2 SendGrid

**Types d'emails supportés :**
- `welcome_community_admin` - Bienvenue nouvel admin
- `invite_delegate` - Invitation délégué
- `invite_member` - Invitation membre
- `reset_password` - Réinitialisation mot de passe
- `verify_email` - Vérification email
- `new_event` - Notification nouvel événement
- `new_collection` - Notification nouvelle collecte
- `collection_contribution_thanks` - Remerciement contribution
- `message_to_admin` - Message vers admin

### 9.3 Object Storage (R2/Replit)

> ⚠️ **UPDATED** - Anciennement "Google Cloud Storage", remplacé par Cloudflare R2 (production) et Replit Object Storage (développement).

**Usages :**
- Stockage des logos communautés
- Photos d'articles et événements
- Documents importés

**Architecture multi-provider :**
- Production : Cloudflare R2 (S3-compatible)
- Développement : Replit Object Storage (sidecar local)
- CDN : cdn.koomy.app / cdn-sandbox.koomy.app

---

## 10. Sécurité et Authentification

### 10.1 Modèle d'Authentification

**Deux modes d'authentification coexistent :**

#### Mode Classique (Legacy)
- Authentification email/password
- Sessions Express (cookie-based)
- Utilisé pour le backoffice et l'app mobile admin

#### Mode Firebase (Production)
- Firebase Auth (mode keyless - pas de service account JSON)
- Supporte email/password ET Google Sign-In
- Token ID Firebase vérifié côté backend via Firebase Admin SDK
- Pattern base de données : `provider_id` + `auth_provider = 'firebase'` (pas de colonne firebase_uid)
- Mot de passe nullable pour les comptes Google Sign-In

**Trois niveaux d'authentification :**

1. **Comptes App Mobile** (`accounts`)
   - Authentification Firebase (email/password ou Google Sign-In)
   - Token ID Firebase avec TTL 50 minutes
   - Accès aux communautés via `userCommunityMemberships`

2. **Administrateurs Backoffice** (`users`)
   - Authentification email/password (mode classique)
   - Rôles : `admin`, `delegate`
   - Permissions granulaires par délégué

3. **Super-Administrateurs Plateforme** (`users` avec `globalRole`)
   - `platform_super_admin` : Accès total
   - `platform_support` : Support client
   - `platform_commercial` : Gestion commerciale

### 10.2 Firebase Admin SDK (Keyless Mode)

```typescript
// server/lib/firebaseAdmin.ts
// Mode: Keyless (Application Default Credentials)
// Contrainte: Org Policy iam.disableServiceAccountKeyCreation active
// ENV requis: FIREBASE_PROJECT_ID (ex: "koomy-sandbox")

export async function verifyFirebaseToken(idToken: string): Promise<{
  uid: string;
  email?: string;
} | null>
```

### 10.3 Permissions Délégués

```typescript
interface DelegatePermissions {
  canManageArticles: boolean;
  canManageEvents: boolean;
  canManageCollections: boolean;
  canManageMessages: boolean;
  canManageMembers: boolean;
  canScanPresence: boolean;
}
```

### 10.4 Protection des Routes

```typescript
// Middleware de vérification admin
const requireAdmin = async (req, res, next) => {
  const { userId } = req.session;
  const { communityId } = req.params;
  
  const membership = await storage.getUserMembership(userId, communityId);
  
  if (!membership || (membership.role !== 'admin' && membership.role !== 'delegate')) {
    return res.status(403).json({ error: 'Forbidden' });
  }
  
  req.membership = membership;
  next();
};
```

---

## 11. Environnements Sandbox/Production

### 11.1 Isolation des Environnements

**Architecture bi-environnement stricte :**

| Environnement | Base de données | CDN | API |
|---------------|-----------------|-----|-----|
| Production | Neon (main branch) | cdn.koomy.app | api.koomy.app |
| Sandbox | Neon (dev branch) | cdn-sandbox.koomy.app | api-sandbox.koomy.app |

### 11.2 Guardrails Backend (server/index.ts)

Le serveur refuse de démarrer si une incohérence est détectée :

```typescript
// KOOMY_ENV=sandbox + DATABASE_URL production → FATAL EXIT
// KOOMY_ENV=production + DATABASE_URL sandbox → FATAL EXIT
// APP_ENV=sandbox + STRIPE_SECRET_KEY sk_live_* → FATAL EXIT
// APP_ENV=prod + STRIPE_SECRET_KEY sk_test_* → FATAL EXIT
```

**Variables d'environnement clés :**
- `KOOMY_ENV`: sandbox | production | development
- `APP_ENV`: sandbox | prod (pour Stripe URLs)

### 11.3 Guardrails Frontend (client/src/lib/envGuard.ts)

L'application bloque au démarrage si :
- Hostname sandbox + CDN production
- Hostname production + CDN sandbox

```typescript
// Détection hostname sandbox
const SANDBOX_HOSTNAME_PATTERNS = [
  /sandbox/i, /-sandbox\./i, /demo-/i, /-dev\./i
];

// Détection CDN production vs sandbox
// Production: cdn.koomy.app
// Sandbox: cdn-sandbox.koomy.app
```

### 11.4 CDN Resolver Centralisé (client/src/lib/cdnResolver.ts)

Module unique pour résolution URLs CDN :

```typescript
// Résolution environnement-aware
getCdnBaseUrl(): string  // https://cdn(-sandbox).koomy.app
resolvePublicObjectUrl(path: string): string
```

### 11.5 Stockage Objet (R2/Replit)

**Production (Cloudflare R2) :**
- Endpoint: S3-compatible (configuré via S3_ENDPOINT)
- Bucket: configuré via S3_BUCKET env var
- CDN: cdn.koomy.app (configuré via PUBLIC_OBJECT_BASE_URL)

**Développement (Replit Object Storage) :**
- Endpoint: Sidecar local (127.0.0.1:1106)
- Bucket: DEFAULT_OBJECT_STORAGE_BUCKET_ID

**Pattern URL :**
```
Database: /objects/public/{folder}/{uuid}.{ext}
CDN:      https://cdn.koomy.app/public/{folder}/{uuid}.{ext}
```

---

## 12. Déploiement

### 12.1 Configuration Actuelle

| Paramètre | Valeur |
|-----------|--------|
| **Plateforme** | Replit |
| **Type** | Autoscale Deployment |
| **Port** | 5000 (exposé sur 80) |
| **Build** | `npm run build` |
| **Start** | `npm run start` |

### 12.2 Variables d'Environnement

```bash
# Base de données
DATABASE_URL=postgresql://...

# Environnement
KOOMY_ENV=sandbox|production|development
APP_ENV=sandbox|prod

# Stripe
STRIPE_SECRET_KEY=sk_...
STRIPE_WEBHOOK_SECRET=whsec_...

# Firebase Auth
FIREBASE_PROJECT_ID=koomy-sandbox|koomy-prod

# SendGrid (via Replit Connector)
# Géré automatiquement

# Object Storage (Replit)
DEFAULT_OBJECT_STORAGE_BUCKET_ID=...
PUBLIC_OBJECT_SEARCH_PATHS=...
PRIVATE_OBJECT_DIR=...

# Object Storage (R2 Production)
S3_ENDPOINT=...
S3_BUCKET=...
S3_ACCESS_KEY_ID=...
S3_SECRET_ACCESS_KEY=...
PUBLIC_OBJECT_BASE_URL=https://cdn.koomy.app

# PostgreSQL (auto)
PGHOST=...
PGPORT=...
PGUSER=...
PGPASSWORD=...
PGDATABASE=...
```

### 12.3 Domaines Actifs

**Production :**

| Sous-domaine | Interface |
|--------------|-----------|
| `koomy.app` | Site commercial |
| `app.koomy.app` | App mobile membre (wallet) |
| `app-pro.koomy.app` | App mobile admin |
| `backoffice.koomy.app` | Backoffice web |
| `lorpesikoomyadmin.koomy.app` | Portail plateforme SaaS Owner |
| `cdn.koomy.app` | CDN assets |
| `api.koomy.app` | API backend |

**Sandbox :**

| Sous-domaine | Interface |
|--------------|-----------|
| `sitepublic-sandbox.koomy.app` | Site commercial |
| `sandbox.koomy.app` | App mobile membre (wallet) |
| `club-mobile-sandbox.koomy.app` | App mobile admin |
| `backoffice-sandbox.koomy.app` | Backoffice web |
| `saasowner-sandbox.koomy.app` | Portail plateforme SaaS Owner |
| `cdn-sandbox.koomy.app` | CDN assets |
| `api-sandbox.koomy.app` | API backend |

---

## 13. État Actuel du Développement

### 13.1 Fonctionnalités Implémentées (Janvier 2026)

**Phase 1 - MVP Core :** ✅ Complété
- Multi-tenant architecture
- Gestion des communautés
- Gestion des membres et adhésions
- Actualités et événements
- Messagerie membre-admin
- Carte de membre virtuelle avec QR code
- Scanner QR présence

**Phase 2A - Paiements SaaS :** ✅ Complété
- Intégration Stripe Billing
- Plans d'abonnement (Free, Plus, Pro, Enterprise)
- Webhooks de facturation
- Flow de paiement avant accès (Option A)

**Phase 2B - Paiements Communautaires :** ✅ Complété
- Stripe Connect Express onboarding
- Paiement cotisations membres
- Collectes/cagnottes
- Commission Koomy 2%
- Interface finances admin
- Section collectes actives sur page d'accueil membre

**Phase 3 - Firebase Auth :** ✅ Complété
- Firebase Auth (mode keyless)
- Google Sign-In
- Token ID verification backend
- Pattern provider_id + auth_provider

**Phase 4 - Environnements :** ✅ Complété
- Isolation sandbox/production
- Guardrails backend (fail-fast)
- Guardrails frontend (EnvGuard)
- CDN resolver centralisé
- Cloudflare R2 storage

### 13.2 En Cours / Prévu

**Phase 5 - Améliorations UX :**
- [ ] Internationalisation complète FR/EN
- [ ] Push notifications
- [ ] PWA optimisations
- [ ] Import Excel membres amélioré

**Phase 6 - Fonctionnalités Avancées :**
- [x] Intégration OpenAI (génération contenu) - ✅ Actif
- [ ] Analytics avancés
- [ ] Export PDF relevés
- [ ] API publique documentée

### 13.3 Métriques Techniques (Audit Janvier 2026)

| Métrique | Valeur |
|----------|--------|
| Routes API | 228 |
| Lignes code routes.ts | 11 151 |
| Lignes code storage.ts | 3 645 |
| Lignes code schema.ts | 1 214 |
| Tables base de données | 37 |
| Enums PostgreSQL | 39 |
| Pages frontend | 78 |
| Composants React | 75 |
| Dépendances npm | 100+ |

### 13.4 Limitations Connues

1. ~~**Authentification** : Sessions en mémoire en dev (memorystore)~~ ⚠️ OBSOLETE - Firebase Auth en production
2. **Pool DB** : Pas de configuration explicite des limites
3. **Cache** : Pas de caching applicatif implémenté
4. ~~**Rate Limiting** : Pas de protection contre les abus~~ ✅ Rate limiting implémenté
5. **i18n** : Certains nouveaux textes en français uniquement

### 13.5 Contact Technique

Pour toute question technique, contacter l'équipe Koomy via le portail plateforme ou le support.

---

## 14. Change Log - Audit Update

### Audit du 22 janvier 2026

| Section | Type | Description |
|---------|------|-------------|
| Header | UPDATED | Date mise à jour, ajout mention audit |
| Table des matières | UPDATED | Ajout sections 11 (Environnements) et 14 (Change Log) |
| 3. Services Externes | UPDATED | Ajout Firebase Auth, Cloudflare R2, CDN, Replit Object Storage |
| 9.3 Object Storage | UPDATED | Anciennement "Google Cloud Storage", maintenant R2/Replit multi-provider |
| 10.1 Modèle d'Authentification | UPDATED | Ajout mode Firebase (keyless), Google Sign-In, pattern provider_id |
| 10.2 Firebase Admin SDK | ADDED | Nouvelle sous-section |
| 11. Environnements Sandbox/Production | ADDED | Nouvelle section complète |
| 11.2 Guardrails Backend | ADDED | Documentation isolation serveur |
| 11.3 Guardrails Frontend | ADDED | Documentation EnvGuard |
| 11.4 CDN Resolver | ADDED | Module centralisé |
| 11.5 Stockage Objet R2/Replit | ADDED | Architecture multi-provider |
| 12.2 Variables d'Environnement | UPDATED | Ajout KOOMY_ENV, APP_ENV, FIREBASE_PROJECT_ID, S3_* |
| 12.3 Domaines | UPDATED | Distinction Production/Sandbox, ajout CDN et API |
| 13.1 Fonctionnalités | UPDATED | Ajout Phase 3 (Firebase Auth) et Phase 4 (Environnements) |
| 13.2 En Cours / Prévu | UPDATED | Renumérotation phases, OpenAI marqué comme actif |
| 13.3 Métriques Techniques | UPDATED | Toutes métriques mises à jour selon audit réel du code |
| 13.4 Limitations Connues | UPDATED | Marquage OBSOLETE pour points résolus |

### Justifications

1. **Firebase Auth** : Intégration réelle dans le code (server/lib/firebaseAdmin.ts, client/src/lib/firebase.ts)
2. **Cloudflare R2** : Configuration S3-compatible dans server/objectStorage.ts
3. **Guardrails** : Code vérifié dans server/index.ts et client/src/lib/envGuard.ts
4. **Métriques** : Comptage réel via wc -l et grep sur le code source

---

*Document généré automatiquement - Version 2.1*
*Dernière mise à jour : 22 janvier 2026*
*Audit interne : 22 janvier 2026*
*Métriques vérifiées via commandes : wc -l, grep -c*
