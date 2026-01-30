# Inventaire des Fonctionnalités Koomy

> **Date d'audit** : 9 janvier 2026  
> **Sources** : server/routes.ts (208 routes), shared/schema.ts (30+ tables), client/src/pages (50+ écrans)

---

## 1. Tableau des Capabilities

### Module: AUTH (Authentification)

| Action utilisateur | Où | Rôle | Preuve | Notes/Limites |
|---|---|---|---|---|
| Créer un compte Koomy | Mobile | Public | `POST /api/accounts/register`, `accounts` table | Email + password |
| Se connecter (membre) | Mobile | Member | `POST /api/accounts/login` | Token Bearer |
| Se connecter (admin) | Web Admin | Admin | `POST /api/admin/login` | Session-based |
| Se connecter (plateforme) | Web Platform | Super-admin | `POST /api/platform/login` | Session 2h, vérification email obligatoire |
| Réclamer une carte membre (claim code) | Mobile | Member | `POST /api/memberships/claim`, `claimCode` field | Code XXXX-XXXX |
| Inscription + claim en un pas | Mobile | Member | `POST /api/memberships/register-and-claim` | Création compte + liaison carte |
| Vérifier email | Web/Mobile | All | `POST /api/platform/verify` | Token par email |
| Renouveler session plateforme | Web Platform | Super-admin | `POST /api/platform/renew-session` | Expiration 2h |
| Déconnexion plateforme | Web Platform | Super-admin | `POST /api/platform/logout` | |

### Module: MEMBERS (Gestion des membres)

| Action utilisateur | Où | Rôle | Preuve | Notes/Limites |
|---|---|---|---|---|
| Lister les membres | Web Admin, Mobile Admin | Admin | `GET /api/communities/:id/members`, `Members.tsx` | Avec filtres section/tags |
| Voir détails membre | Web Admin, Mobile Admin | Admin | `GET /api/memberships/:id`, `MemberDetails.tsx` | |
| Créer un membre | Web Admin, Mobile Admin | Admin | `POST /api/memberships` | Génère claimCode + memberId |
| Modifier un membre | Web Admin | Admin | `PATCH /api/memberships/:id` | Tous champs éditables |
| Supprimer un membre | Web Admin | Admin | `DELETE /api/memberships/:id` | Protection owner |
| Régénérer code d'activation | Web Admin, Mobile Admin | Admin | `POST /api/memberships/:id/regenerate-code` | Nouveau claimCode |
| Renvoyer code d'activation | Web Admin, Mobile Admin | Admin | `POST /api/memberships/:id/resend-claim-code` | Rate limit 3/10min |
| Attribuer tags à un membre | Web Admin | Admin | `PUT /api/communities/:id/memberships/:id/tags` | Multi-tags |
| Voir carte membre | Mobile | Member | `Card.tsx` | QR code (selon plan) |
| Modifier profil personnel | Mobile | Member | `PersonalInfo.tsx`, `PATCH /api/accounts/me` | |
| Changer mot de passe | Mobile | Member | `PATCH /api/accounts/:id/password` | |
| Demander suppression compte | Mobile | Member | `POST /api/accounts/:id/deletion-request` | |

### Module: SECTIONS & TAGS (Organisation)

| Action utilisateur | Où | Rôle | Preuve | Notes/Limites |
|---|---|---|---|---|
| Lister sections | Web Admin | Admin | `GET /api/communities/:id/sections`, `Sections.tsx` | |
| Créer section | Web Admin | Admin | `POST /api/communities/:id/sections`, `sections` table | |
| Modifier section | Web Admin | Admin | `PATCH /api/sections/:id` | |
| Supprimer section | Web Admin | Admin | `DELETE /api/sections/:id` | |
| Lister tags | Web Admin, Mobile Admin | Admin | `GET /api/communities/:id/tags`, `Tags.tsx` | |
| Créer tag | Web Admin, Mobile Admin | Admin | `POST /api/communities/:id/tags` | Couleur, type (user/content) |
| Modifier tag | Web Admin | Admin | `PUT /api/tags/:id` | |
| Désactiver tag | Web Admin | Admin | `POST /api/tags/:id/deactivate` | Soft delete |
| Supprimer tag | Web Admin | Admin | `DELETE /api/tags/:id` | Hard delete |

### Module: CONTENT (Actualités)

| Action utilisateur | Où | Rôle | Preuve | Notes/Limites |
|---|---|---|---|---|
| Lister actualités | Mobile, Web Admin | Member/Admin | `GET /api/communities/:id/news`, `News.tsx` | |
| Rechercher actualités | Mobile | Member | `News.tsx` (searchQuery state) | Recherche texte + filtres |
| Filtrer par catégorie | Mobile | Member | `News.tsx` (selectedCategoryId) | |
| Voir détail article | Mobile | Member | `NewsDetail.tsx`, `GET /api/news/:id` | |
| Créer article | Web Admin, Mobile Admin | Admin | `POST /api/news`, `Articles.tsx` | Brouillon/Publié |
| Modifier article | Web Admin, Mobile Admin | Admin | `PATCH /api/news/:id` | |
| Supprimer article | Web Admin | Admin | `DELETE /api/news/:id` | |
| Gérer catégories (rubriques) | Web Admin | Admin | `Categories.tsx`, `/api/communities/:id/categories` | CRUD complet |
| Attribuer tags aux articles | Web Admin | Admin | `PUT /api/articles/:id/tags` | Ciblage contenu |

### Module: EVENTS (Événements)

| Action utilisateur | Où | Rôle | Preuve | Notes/Limites |
|---|---|---|---|---|
| Lister événements | Mobile, Web Admin | Member/Admin | `GET /api/communities/:id/events`, `Events.tsx` | |
| Voir détail événement | Mobile | Member | `EventDetail.tsx` | |
| Créer événement | Web Admin, Mobile Admin | Admin | `POST /api/events` | V2 avec RSVP, ciblage |
| Modifier événement | Web Admin, Mobile Admin | Admin | `PATCH /api/events/:id` | |
| Supprimer événement | Web Admin | Admin | `DELETE /api/events/:id` | |
| S'inscrire (RSVP) | Mobile | Member | `POST /api/events/:id/registrations` | Selon mode RSVP |
| Annuler inscription | Mobile | Member | `DELETE /api/events/:id/registrations/:id` | À confirmer |
| Voir inscrits | Web Admin | Admin | `EventDetails.tsx` | Stats par statut |
| Scanner présence (QR) | Mobile Admin | Admin | `Scanner.tsx`, `eventAttendance` table | |
| Créer événement payant | Web Admin | Admin | `isPaid`, `priceCents` fields | Quota selon plan |

### Module: PAYMENTS (Paiements)

| Action utilisateur | Où | Rôle | Preuve | Notes/Limites |
|---|---|---|---|---|
| Configurer Stripe Connect | Web Admin | Admin | `POST /api/payments/connect-community` | Express account |
| Voir état paiements communauté | Web Admin | Admin | `GET /api/communities/:id/payments`, `Payments.tsx` | |
| Créer demande de paiement | Web Admin | Admin | `POST /api/payment-requests` | Cotisations |
| Payer cotisation en ligne | Mobile | Member | `POST /api/payments/create-membership-session` | Stripe Checkout |
| Marquer cotisation payée (manuel) | Web Admin | Admin | `POST /api/memberships/:id/mark-paid` | |
| Voir transactions | Web Admin | Admin | `GET /api/communities/:id/transactions` | Historique unifié |
| Créer collecte (cagnotte) | Web Admin, Mobile Admin | Admin | `POST /api/collections`, `Collections.tsx` | |
| Contribuer à une collecte | Mobile | Member | `POST /api/payments/create-collection-session` | |
| Fermer collecte | Web Admin | Admin | `POST /api/collections/:id/close` | |

### Module: BILLING (Facturation SaaS)

| Action utilisateur | Où | Rôle | Preuve | Notes/Limites |
|---|---|---|---|---|
| Voir état abonnement | Web Admin | Admin | `GET /api/billing/status`, `Billing.tsx` | |
| Souscrire/changer plan | Web Admin | Admin | `POST /api/billing/checkout` | Stripe Billing |
| Accéder portail Stripe | Web Admin | Admin | `POST /api/billing/portal` | Gestion abonnement |
| Voir quotas (membres) | Web Admin | Admin | `GET /api/communities/:id/quota` | Limite selon plan |

### Module: MESSAGING (Messagerie)

| Action utilisateur | Où | Rôle | Preuve | Notes/Limites |
|---|---|---|---|---|
| Voir conversations | Mobile, Web Admin | Member/Admin | `GET /api/communities/:id/conversations`, `Messages.tsx` | |
| Voir messages conversation | Mobile, Web Admin | Member/Admin | `GET /api/communities/:id/messages/:conversationId` | |
| Envoyer message | Mobile, Web Admin | Member/Admin | `POST /api/messages` | |
| Marquer message lu | Mobile | Member | `PATCH /api/messages/:id/read` | |

### Module: SUPPORT

| Action utilisateur | Où | Rôle | Preuve | Notes/Limites |
|---|---|---|---|---|
| Créer ticket support | Mobile, Web Admin | Member/Admin | `POST /api/tickets`, `Support.tsx` | |
| Voir mes tickets | Mobile, Web Admin | Member/Admin | `GET /api/tickets` | |
| Modifier ticket | Web Admin | Admin | `PATCH /api/tickets/:id` | Status, priorité |
| Voir tous tickets (plateforme) | Web Platform | Super-admin | `GET /api/platform/tickets` | |
| Répondre à ticket | Web Platform | Super-admin | `POST /api/platform/tickets/:id/responses` | |
| Assigner ticket | Web Platform | Super-admin | `PATCH /api/platform/tickets/:id/assign` | |

### Module: ADMIN (Gestion communauté)

| Action utilisateur | Où | Rôle | Preuve | Notes/Limites |
|---|---|---|---|---|
| Tableau de bord | Web Admin | Admin | `Dashboard.tsx` | Stats basiques |
| Paramètres communauté | Web Admin | Admin | `Settings.tsx`, `PUT /api/communities/:id` | Infos, branding |
| Gérer administrateurs | Web Admin | Owner | `Admins.tsx`, `/api/communities/:id/delegates` | Multi-admin (selon plan) |
| Gérer plans d'adhésion | Web Admin | Admin | `MembershipPlans.tsx`, `/api/communities/:id/membership-plans` | CRUD complet |
| Configurer champs profil | Web Admin | Admin | `PUT /api/communities/:id/member-profile-config` | Adresse, contact urgence, mineurs |
| Migration ID membres | Web Admin | Admin | `POST /api/communities/:id/migrate-member-ids` | Préfixe personnalisé |

### Module: WHITE-LABEL

| Action utilisateur | Où | Rôle | Preuve | Notes/Limites |
|---|---|---|---|---|
| Configurer branding | Web Admin | Admin | `PATCH /api/communities/:id/branding` | Logo, couleurs |
| Obtenir config white-label | Mobile | System | `GET /api/white-label/config`, `GET /api/whitelabel/by-host` | wl.json |
| Activer white-label | Web Platform | Super-admin | `PATCH /api/platform/communities/:id/white-label` | |

### Module: PLATFORM (Super-admin Koomy)

| Action utilisateur | Où | Rôle | Preuve | Notes/Limites |
|---|---|---|---|---|
| Dashboard plateforme | Web Platform | Super-admin | `SuperDashboard.tsx` | Métriques globales |
| Lister toutes communautés | Web Platform | Super-admin | `GET /api/platform/all-communities` | |
| Voir détails communauté | Web Platform | Super-admin | `GET /api/platform/communities/:id/details` | |
| Accorder Full Access VIP | Web Platform | Super-admin | `POST /api/platform/communities/:id/full-access` | Bypass limites |
| Retirer Full Access | Web Platform | Super-admin | `DELETE /api/platform/communities/:id/full-access` | |
| Créer admin owner | Web Platform | Super-admin | `POST /api/platform/communities/:id/create-owner-admin` | |
| Modifier nom communauté | Web Platform | Super-admin | `PATCH /api/platform/communities/:id/name` | |
| Voir audit logs | Web Platform | Super-admin | `GET /api/platform/audit-logs` | Toutes actions tracées |
| Voir métriques | Web Platform | Super-admin | `GET /api/platform/metrics` | MRR, MAU, etc. |
| Analytics avancées | Web Platform | Super-admin | `GET /api/platform/analytics/*` | Top communities, growth, etc. |
| Gérer utilisateurs plateforme | Web Platform | Super-admin | `GET/POST /api/platform/users` | |
| Modifier rôle utilisateur | Web Platform | Super-admin | `PATCH /api/platform/users/:id/role` | |
| Gérer templates email | Web Platform | Owner | `GET/PUT /api/owner/email-templates/:type` | |
| Voir logs emails | Web Platform | Owner | `GET /api/owner/email-logs` | |
| Voir contacts commerciaux | Web Platform | Super-admin | `GET /api/platform/contacts` | Formulaire contact |

### Module: NOTIFICATIONS & EMAIL

| Action utilisateur | Où | Rôle | Preuve | Notes/Limites |
|---|---|---|---|---|
| Voir notifications | Mobile | Member | `Notifications.tsx` | À confirmer - in-app |
| Email invitation membre | System | - | `sendMemberInviteEmail()` | Avec claimCode |
| Email bienvenue admin | System | - | `sendWelcomeEmail()` | |
| Email vérification | System | - | `sendVerificationEmail()` | |
| Email credentials admin | System | - | `sendAdminCredentialsEmail()` | |

---

## 2. Tables de base de données clés

| Table | Description | Relations principales |
|---|---|---|
| `accounts` | Comptes utilisateurs (app mobile) | → memberships |
| `users` | Admins back-office + plateforme | → memberships, communities |
| `communities` | Tenants/Communautés | → plan, memberships, events, news... |
| `plans` | Plans tarifaires (FREE/PLUS/PRO/GRAND_COMPTE) | → communities |
| `userCommunityMemberships` | Cartes membres (junction) | → account, community, tags |
| `sections` | Divisions régionales/locales | → community |
| `tags` | Tags pour segmentation | → community, members, articles |
| `newsArticles` | Actualités/Articles | → community, category |
| `categories` | Rubriques d'actualités | → community |
| `events` | Événements V2 | → community, registrations |
| `eventRegistrations` | Inscriptions événements | → event, membership |
| `eventAttendance` | Présences scannées | → event, membership |
| `messages` | Messagerie membre-admin | → community, membership |
| `collections` | Cagnottes/Fundraising | → community |
| `transactions` | Paiements unifiés | → community, membership, collection |
| `membershipPlans` | Plans d'adhésion communauté | → community |
| `supportTickets` | Tickets support | → user, community |
| `platformAuditLogs` | Audit actions plateforme | → user |
| `emailTemplates` | Templates emails personnalisables | - |

---

## 3. Capabilities par Plan

| Capability | FREE | PLUS | PRO | GRAND_COMPTE |
|---|:---:|:---:|:---:|:---:|
| maxMembers | 20 | 300 | 5000 | Illimité |
| maxAdmins | 1 | ∞ | ∞ | ∞ |
| qrCard | ❌ | ✅ | ✅ | ✅ |
| dues (cotisations) | ❌ | ✅ | ✅ | ✅ |
| messaging | ❌ | ✅ | ✅ | ✅ |
| events | ✅ | ✅ | ✅ | ✅ |
| eventRsvp | ❌ | ✅ | ✅ | ✅ |
| eventPaid | ❌ | ✅ (2/mois) | ✅ (∞) | ✅ (∞) |
| eventTargeting | ❌ | ❌ | ✅ | ✅ |
| eventCapacity | ❌ | ❌ | ✅ | ✅ |
| eventWaitlist | ❌ | ❌ | ❌ | ✅ |
| analytics | ❌ | ✅ | ✅ | ✅ |
| advancedAnalytics | ❌ | ❌ | ✅ | ✅ |
| exportData | ❌ | ❌ | ✅ | ✅ |
| multiAdmin | ❌ | ❌ | ✅ | ✅ |
| customization | ❌ | ❌ | ✅ | ✅ |
| prioritySupport | ❌ | ✅ | ✅ | ✅ |
| whiteLabeling | ❌ | ❌ | ❌ | ✅ |
| customDomain | ❌ | ❌ | ❌ | ✅ |
| dedicatedManager | ❌ | ❌ | ❌ | ✅ |

---

## 4. Proposition Arborescence Help Center

### Priorité 1: PAIEMENTS (Urgence haute)
- **Mon paiement / Ma cotisation**
  - Payer ma cotisation en ligne
  - Vérifier mon statut de paiement
  - Problème de paiement refusé
  - Demander un remboursement
- **Événements payants**
  - S'inscrire à un événement payant
  - Annuler une inscription payante
- **Pour les administrateurs**
  - Configurer Stripe Connect
  - Créer une demande de paiement
  - Marquer une cotisation payée manuellement
  - Voir les transactions

### Priorité 2: ACCÈS (Connexion, Compte)
- **Je n'arrive pas à me connecter**
  - Mot de passe oublié
  - Code d'activation invalide
  - Compte bloqué
- **Activer ma carte membre**
  - Où trouver mon code d'activation
  - Activer ma carte avec le code
  - Mon code ne fonctionne pas
- **Gérer mon compte**
  - Modifier mes informations
  - Changer mon mot de passe
  - Supprimer mon compte

### Priorité 3: PROBLÈMES TECHNIQUES (Bugs)
- **L'application ne fonctionne pas**
  - L'app plante au démarrage
  - Les images ne s'affichent pas
  - Erreur de connexion réseau
- **Ma carte membre**
  - Le QR code ne fonctionne pas
  - Ma carte n'apparaît pas
- **Actualités et événements**
  - Je ne vois pas les nouveaux articles
  - Un événement n'apparaît pas

### Priorité 4: UTILISATION COURANTE
- **Actualités**
  - Consulter les actualités
  - Rechercher un article
  - Filtrer par catégorie
- **Événements**
  - Voir les événements à venir
  - S'inscrire à un événement
  - Annuler mon inscription
- **Messagerie**
  - Contacter un administrateur
  - Voir mes conversations

### Priorité 5: FONCTIONS AVANCÉES
- **Pour les administrateurs**
  - Ajouter un nouveau membre
  - Créer un article / actualité
  - Organiser un événement
  - Gérer les sections et tags
  - Configurer les plans d'adhésion
  - Personnaliser ma communauté
- **Abonnement Koomy**
  - Comparer les plans
  - Passer au plan supérieur
  - Gérer mon abonnement

---

## 5. Éléments "À confirmer"

| Élément | Statut | Raison |
|---|---|---|
| Push notifications | À confirmer | Capacitor config présent, implémentation backend non vérifiée |
| Export CSV membres | À confirmer | Capability `exportData` existe, UI non localisée |
| API access externe | À confirmer | Capability `apiAccess` existe, documentation non trouvée |
| Annulation inscription événement | À confirmer | Route non explicitement trouvée |
| Notifications in-app | À confirmer | Page `Notifications.tsx` existe, contenu non audité |
| Multi-communauté par compte | À confirmer | Capability existe, flow non audité |

---

**Fin de l'inventaire**
