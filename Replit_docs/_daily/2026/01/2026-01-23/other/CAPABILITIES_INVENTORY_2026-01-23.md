# Inventaire des Capacités Koomy

**Date**: 2026-01-23  
**Commit SHA**: 6fd6261  
**Méthodologie**: Analyse statique du code (lecture uniquement, aucune exécution)

---

# 🟦 Plateforme : Web – App Member

## A) Authentification & Session

| Capacité | État | Détails |
|----------|------|---------|
| Login email/password | 🟢 Implémenté | `UnifiedAuthLogin.tsx` via Firebase `signInWithEmailAndPassword` |
| Login Google | 🟢 Implémenté | `signInWithGoogle` via Firebase GoogleAuthProvider |
| Signup | 🟢 Implémenté | `UnifiedAuthRegister.tsx` via Firebase `createUserWithEmailAndPassword` |
| Reset password | 🟢 Implémenté | `sendPasswordResetEmail` intégré dans UnifiedAuthLogin |
| Session persistante | 🟢 Implémenté | Token Firebase stocké via `storage.ts`, refresh via `/api/auth/me` |
| Logout | 🟢 Implémenté | `logout()` dans AuthContext, efface storage + Firebase signOut |
| Guards de routes | 🟢 Implémenté | `withWhiteLabelGuard` HOC dans App.tsx |
| Multi-rôles (member/admin) | 🟡 Partiel | Distinction account (member) vs user (admin) dans AuthContext |

## B) Rôles & Accès

| Capacité | État | Détails |
|----------|------|---------|
| Distinction Member / Admin | 🟢 Implémenté | `account` pour members, `user` pour admins dans AuthContext |
| Mapping rôle → route | 🟢 Implémenté | Member → `/app/hub`, Admin → `/admin/dashboard` |
| Accès conditionnel | 🟢 Implémenté | Guards vérifient `account` ou `user` présent |
| Claims Firebase / backend | 🟡 Partiel | Firebase Auth utilisé, claims backend via `providerId` |

## C) Navigation & Pages

| Route | Page | État |
|-------|------|------|
| `/auth` | AuthChoice (Welcome) | 🟢 Active |
| `/auth/login` | AuthLogin | 🟢 Active |
| `/auth/register` | AuthRegister | 🟢 Active |
| `/app/hub` | CommunityHub | 🟢 Active |
| `/app/join` | JoinCommunityStandard | 🟢 Active |
| `/app/add-card` | AddCard | 🟢 Active |
| `/app/claim/:code` | ClaimVerified | 🟢 Active |
| `/app/:communityId/home` | MobileHome | 🟢 Active (guarded) |
| `/app/:communityId/card` | MobileCard | 🟢 Active (guarded) |
| `/app/:communityId/news` | MobileNews | 🟢 Active (guarded) |
| `/app/:communityId/news/:articleId` | MobileNewsDetail | 🟢 Active (guarded) |
| `/app/:communityId/events` | MobileEvents | 🟢 Active (guarded) |
| `/app/:communityId/events/:eventId` | MobileEventDetail | 🟢 Active (guarded) |
| `/app/:communityId/messages` | MobileMessages | 🟢 Active (guarded) |
| `/app/:communityId/profile` | MobileProfile | 🟢 Active (guarded) |
| `/app/:communityId/profile/personal-info` | PersonalInfo | 🟢 Active |
| `/app/:communityId/profile/notifications` | Notifications | 🟢 Active |
| `/app/:communityId/profile/security` | SecurityPrivacy | 🟢 Active |
| `/app/:communityId/profile/build-info` | BuildInfo | 🟢 Active |
| `/app/:communityId/payment` | MobilePayment | 🟢 Active (guarded) |
| `/app/:communityId/support` | MobileSupport | 🟢 Active (guarded) |
| `/app/payment/success` | MobilePaymentSuccess | 🟢 Active |
| `/app/payment/cancel` | MobilePaymentCancel | 🟢 Active |
| `/app/login` | Legacy redirect | 🟡 Redirect vers `/auth` |

## D) Fonctionnalités "métier"

| Capacité | État | Détails |
|----------|------|---------|
| Voir communautés (Hub) | 🟢 Implémenté | CommunityHub affiche les memberships |
| Rejoindre communauté | 🟢 Implémenté | `/app/join`, `/join/:slug` (self-enrollment) |
| Claim membership (code) | 🟢 Implémenté | `/app/claim/:code`, `/api/memberships/claim` |
| Carte membre | 🟢 Implémenté | `/app/:communityId/card`, QR code généré |
| Événements (liste) | 🟢 Implémenté | `/app/:communityId/events` |
| Événements (détail) | 🟢 Implémenté | `/app/:communityId/events/:eventId` |
| Actualités (liste) | 🟢 Implémenté | `/app/:communityId/news` |
| Actualités (détail) | 🟢 Implémenté | `/app/:communityId/news/:articleId` |
| Messages | 🟢 Implémenté | `/app/:communityId/messages` |
| Paiement membre | 🟢 Implémenté | `/app/:communityId/payment`, Stripe intégré |
| Profil | 🟢 Implémenté | Édition infos personnelles, notifications, sécurité |
| Support | 🟢 Implémenté | `/app/:communityId/support` |

## E) Paiement & Plans

| Capacité | État | Détails |
|----------|------|---------|
| Paiement cotisation | 🟢 Implémenté | Stripe Checkout via `/api/payments` |
| Contributions (collectes) | 🟢 Implémenté | `/api/contributions`, Stripe Connect |
| Webhooks Stripe | 🟢 Implémenté | `/api/webhooks/stripe` |

## F) Intégrations techniques

| Service | État | Fichiers |
|---------|------|----------|
| Firebase Auth | 🟢 Configuré | `client/src/lib/firebase.ts` |
| Stripe | 🟢 Configuré | `server/stripe.ts`, `server/stripeConnect.ts` |
| SendGrid (email) | 🟢 Configuré | `server/services/mailer/mailer.ts` |
| CDN (R2) | 🟢 Configuré | `client/src/lib/cdnResolver.ts` |
| Object Storage | 🟢 Configuré | Replit Object Storage |

## G) État de maturité global: 🟢 Production-ready

---

# 🟦 Plateforme : Web – App Admin (Back-office)

## A) Authentification & Session

**CONTRAT IDENTITÉ**: Admins = LEGACY_ONLY (Firebase INTERDIT)

| Capacité | État | Détails |
|----------|------|---------|
| Login email/password | 🟢 Implémenté | `AdminLogin.tsx`, `/api/admin/login` (LEGACY auth) |
| Login Google | ⚪ Absent | INTERDIT par contrat (admins = legacy only) |
| Signup | 🔴 Désactivé | Route redirige vers `/admin/login` (contrat: join-only) |
| Reset password | 🟡 Partiel | Non implémenté côté legacy (backend only) |
| Session persistante | 🟢 Implémenté | Token JWT stocké, refresh via API |
| Logout | 🟢 Implémenté | AuthContext `logout()` |
| Guards de routes | 🟢 Implémenté | Vérification `user` dans AuthContext |
| Multi-rôles | 🟢 Implémenté | `adminRoleEnum`: super_admin, support_admin, finance_admin, content_admin, admin |

## B) Rôles & Accès

| Capacité | État | Détails |
|----------|------|---------|
| Distinction rôles admin | 🟢 Implémenté | 5 rôles définis dans schema |
| Règle 1 admin = 1 club | 🟢 Implémenté | Blocking screen si 0 ou >1 clubs |
| Accès conditionnel | 🟢 Implémenté | Guards vérifient `user` et `currentCommunity` |

## C) Navigation & Pages

| Route | Page | État |
|-------|------|------|
| `/admin/login` | AdminLogin | 🟢 Active |
| `/admin/register` | Redirect | 🟡 Redirige vers `/admin/login` |
| `/admin/join` | AdminJoinCommunity | 🟢 Active |
| `/admin/select-community` | AdminSelectCommunity | 🟢 Active |
| `/admin/dashboard` | AdminDashboard | 🟢 Active |
| `/admin/members` | AdminMembers | 🟢 Active |
| `/admin/members/:id` | AdminMemberDetails | 🟢 Active |
| `/admin/news` | AdminNews | 🟢 Active |
| `/admin/events` | AdminEvents | 🟢 Active |
| `/admin/events/:id` | AdminEventDetails | 🟢 Active |
| `/admin/messages` | AdminMessages | 🟢 Active |
| `/admin/admins` | AdminAdmins | 🟢 Active |
| `/admin/sections` | AdminSections | 🟢 Active |
| `/admin/categories` | AdminCategories | 🟢 Active |
| `/admin/support` | AdminSupport | 🟢 Active |
| `/admin/payments` | AdminPayments | 🟢 Active |
| `/admin/billing` | AdminBilling | 🟢 Active |
| `/admin/billing/success` | BillingSuccess | 🟢 Active |
| `/admin/billing/cancel` | BillingCancel | 🟢 Active |
| `/billing/return` | BillingReturn | 🟢 Active |
| `/admin/finances` | AdminFinances | 🟢 Active |
| `/admin/tags` | AdminTags | 🟢 Active |
| `/admin/membership-plans` | AdminMembershipPlans | 🟢 Active |
| `/admin/settings` | AdminSettings | 🟢 Active |

## D) Fonctionnalités "métier"

| Capacité | État | Détails |
|----------|------|---------|
| Dashboard stats | 🟢 Implémenté | AdminDashboard avec métriques |
| Gestion membres | 🟢 Implémenté | Liste, détails, édition, tags |
| Gestion actualités | 🟢 Implémenté | CRUD articles, sections, catégories |
| Gestion événements | 🟢 Implémenté | CRUD events, inscriptions, QR check-in |
| Messaging | 🟢 Implémenté | Conversations admin/membres |
| Gestion admins | 🟢 Implémenté | Invitations, rôles |
| Sections/régions | 🟢 Implémenté | Gestion arborescence |
| Catégories | 🟢 Implémenté | Classification articles |
| Tags | 🟢 Implémenté | Tags utilisateur/contenu/hybrid |
| Plans cotisation | 🟢 Implémenté | FIXED_PERIOD, ROLLING_DURATION |
| Paiements | 🟢 Implémenté | Suivi paiements membres |
| Finances | 🟢 Implémenté | Collectes, transactions |
| Facturation SaaS | 🟢 Implémenté | Stripe Billing, upgrade/downgrade |
| Support | 🟢 Implémenté | Tickets support |
| Settings | 🟢 Implémenté | Paramètres communauté |
| Self-enrollment | 🟢 Implémenté | Lien public `/join/:slug` |

## E) Paiement & Plans

| Capacité | État | Détails |
|----------|------|---------|
| Plans SaaS (FREE/PLUS/PRO) | 🟢 Implémenté | `shared/plans.ts` |
| Stripe Checkout | 🟢 Implémenté | Upgrade via checkout obligatoire |
| Stripe Billing Portal | 🟢 Implémenté | `/api/billing/portal` |
| Webhooks | 🟢 Implémenté | `checkout.session.completed`, subscriptions |

## F) État de maturité global: 🟡 Partiel (admin signup désactivé)

---

# 🟦 Plateforme : Back-office Mobile (Admin)

## A) Authentification & Session

**CONTRAT IDENTITÉ**: Admins = LEGACY_ONLY (Firebase INTERDIT)

| Capacité | État | Détails |
|----------|------|---------|
| Login email/password | 🟢 Implémenté | `MobileAdminAuthLogin.tsx` via LEGACY auth (backend) |
| Login Google | ⚪ Absent | INTERDIT par contrat |
| Signup | 🟡 Partiel | Route existe mais contrat = join-only |
| Session persistante | 🟢 Implémenté | Via AuthContext + Capacitor Preferences |
| Logout | 🟢 Implémenté | AuthContext |

## B) Navigation & Pages

| Route | Page | État |
|-------|------|------|
| `/app/admin/auth` | MobileAdminAuthChoice | 🟢 Active |
| `/app/admin/auth/login` | MobileAdminAuthLogin | 🟢 Active |
| `/app/admin/auth/register` | MobileAdminAuthRegister | 🟢 Active |
| `/app/admin/select-community` | MobileAdminSelectCommunity | 🟢 Active |
| `/app/:communityId/admin` | MobileAdminHome | 🟢 Active |
| `/app/:communityId/admin/scanner` | MobileAdminScanner | 🟢 Active |
| `/app/:communityId/admin/messages` | MobileAdminMessages | 🟢 Active |
| `/app/:communityId/admin/articles` | MobileAdminArticles | 🟢 Active |
| `/app/:communityId/admin/events` | MobileAdminEvents | 🟢 Active |
| `/app/:communityId/admin/collections` | MobileAdminCollections | 🟢 Active |
| `/app/:communityId/admin/members` | MobileAdminMembers | 🟢 Active |
| `/app/:communityId/admin/finances` | MobileAdminFinances | 🟢 Active |
| `/app/:communityId/admin/tags` | MobileAdminTags | 🟢 Active |
| `/app/:communityId/admin/settings` | MobileAdminSettings | 🟢 Active |
| `/app/admin/login` | Legacy redirect | 🟡 Redirige vers `/app/admin/auth` |
| `/app/admin/register` | Legacy redirect | 🟡 Redirige vers `/app/admin/auth` |

## C) Fonctionnalités "métier"

| Capacité | État | Détails |
|----------|------|---------|
| Dashboard mobile | 🟢 Implémenté | MobileAdminHome |
| Scanner QR (check-in) | 🟢 Implémenté | MobileAdminScanner |
| Gestion membres | 🟢 Implémenté | Liste, actions rapides |
| Gestion articles | 🟢 Implémenté | CRUD articles |
| Gestion événements | 🟢 Implémenté | CRUD events |
| Collectes | 🟢 Implémenté | Gestion campagnes |
| Messages | 🟢 Implémenté | Conversations |
| Finances | 🟢 Implémenté | Vue finances |
| Tags | 🟢 Implémenté | Gestion tags |
| Settings | 🟢 Implémenté | Paramètres |

## D) État de maturité global: 🟡 Partiel (signup désactivé par contrat)

---

# 🟦 Plateforme : Mobile Shell (Capacitor / Android / iOS)

## A) État des builds

| App | Android | iOS | État |
|-----|---------|-----|------|
| KoomyMemberApp | 🟢 Présent | 🟢 Présent | Buildable |
| KoomyAdminApp | 🟢 Présent | 🟡 Partiel | Buildable (Android complet) |
| UNSALidlApp (White-Label) | 🟢 Présent | 🟢 Présent | Buildable |

## B) Infrastructure

| Capacité | État | Détails |
|----------|------|---------|
| Detection native | 🟢 Implémenté | `client/src/lib/capacitor.ts` - `isNativeApp()` |
| Platform detection | 🟢 Implémenté | `getPlatform()` retourne android/ios/web |
| Build system | 🟢 Implémenté | `packages/mobile-build/` CLI unifié |
| Asset generation | 🟢 Implémenté | `generate-assets.mjs` |
| Android signing | 🟢 Implémenté | `android-signing.mjs` |
| Tenant configs | 🟢 Implémenté | `tenants/{tenant-id}/config.ts` |
| Capacitor config | 🟢 Implémenté | Configs par app dans `artifacts/mobile/` |

## C) Capacitor Plugins configurés

| Plugin | État | Détails |
|--------|------|---------|
| @capacitor/core | 🟢 Installé | Base Capacitor |
| SplashScreen | 🟢 Configuré | Config dans capacitor.config.ts |
| StatusBar | 🟢 Configuré | Style et couleur personnalisés |
| Keyboard | 🟢 Configuré | Resize body |
| Preferences | 🟢 Utilisé | Storage natif via `storage.ts` |

## D) Routing natif

| Comportement | État | Détails |
|--------------|------|---------|
| Root natif | 🟢 Implémenté | `isNativeApp()` → AuthChoice ou WhiteLabelMemberApp |
| White-Label detection | 🟢 Implémenté | WhiteLabelContext + wl.json |
| Storage persistant | 🟢 Implémenté | Capacitor Preferences pour token/account |
| API calls | 🟢 Implémenté | httpClient avec headers X-Platform, X-Is-Native |

## E) État de maturité global: 🟢 Buildable et navigable

---

# 🟦 Plateforme : Platform Super Admin

## A) Authentification

**CONTRAT IDENTITÉ**: Platform = LEGACY_ONLY (Firebase INTERDIT)

| Capacité | État | Détails |
|----------|------|---------|
| Login | 🟢 Implémenté | `/platform/login`, `/api/platform/login` (LEGACY auth) |
| Session validation | 🟢 Implémenté | `/api/platform/validate-session` |
| Session renewal | 🟢 Implémenté | `/api/platform/renew-session` |
| IP restriction (France) | 🟢 Implémenté | Whitelist IP configuré |
| Audit logs | 🟢 Implémenté | `platform_audit_logs` table |

## B) Navigation & Pages

| Route | Page | État |
|-------|------|------|
| `/platform/login` | PlatformLogin | 🟢 Active |
| `/platform/dashboard` | SuperDashboard | 🟢 Active |

## C) Fonctionnalités

| Capacité | État | Détails |
|----------|------|---------|
| Toutes communautés | 🟢 Implémenté | `/api/platform/all-communities` |
| Métriques plateforme | 🟢 Implémenté | `/api/platform/metrics` |
| Analytics (top, at-risk, growth) | 🟢 Implémenté | Endpoints analytics |
| Full Access VIP | 🟢 Implémenté | `/api/platform/communities/:id/full-access` |
| White-label toggle | 🟢 Implémenté | `/api/platform/communities/:id/white-label` |
| Gestion utilisateurs | 🟢 Implémenté | `/api/platform/users` |
| Tickets support | 🟢 Implémenté | `/api/platform/tickets` |
| Health monitoring | 🟢 Implémenté | `/api/platform/health/*` |

## D) État de maturité global: 🟢 Production-ready

---

# 🟦 Plateforme : Owner Platform (Global Cockpit)

**CONTRAT IDENTITÉ**: Owner = LEGACY_ONLY (Firebase INTERDIT)

## A) Navigation & Pages

| Route | Page | État |
|-------|------|------|
| `/owner/login` | OwnerLogin | 🟢 Active (LEGACY auth) |
| `/owner` | OwnerDashboard | 🟢 Active |

## B) Fonctionnalités

| Capacité | État | Détails |
|----------|------|---------|
| Email templates | 🟢 Implémenté | `/api/owner/email-templates` |
| Email logs | 🟢 Implémenté | `/api/owner/email-logs` |
| Test emails | 🟢 Implémenté | `/api/owner/email-templates/test` |

## C) État de maturité global: 🟢 Implémenté

---

# 🟦 Plateforme : Routes Publiques

## A) Join public (Self-Enrollment)

| Route | Page | État |
|-------|------|------|
| `/join/:slug` | JoinPage | 🟢 Active |

## B) Debug (Sandbox only)

| Route | Page | État |
|-------|------|------|
| `/__env` | EnvCheck | 🟢 Active (debug) |

---

# 🟦 Plateforme : Website Commercial

## A) Navigation & Pages

| Route | Page | État |
|-------|------|------|
| `/website` | WebsiteHome | 🟢 Active |
| `/website/pricing` | WebsitePricing | 🟢 Active |
| `/website/faq` | WebsiteFAQ | 🟢 Active |
| `/website/contact` | WebsiteContact | 🟢 Active |
| `/website/demo` | WebsiteDemo | 🟢 Active |
| `/website/terms` | WebsiteTerms | 🟢 Active |
| `/website/legal` | WebsiteLegal | 🟢 Active |
| `/website/privacy` | WebsitePrivacy | 🟢 Active |
| `/website/support` | WebsiteSupport | 🟢 Active |
| `/website/blog` | WebsiteBlog | 🟢 Active |
| `/website/features` | WebsiteFeatures | 🟢 Active |
| `/website/signup` | Redirect | 🟡 Redirige vers `/website/pricing` |
| `/website/download` | Redirect | 🟡 Redirige vers `/app/login` |

## B) Fonctionnalités

| Capacité | État | Détails |
|----------|------|---------|
| Formulaire contact | 🟢 Implémenté | `/api/contact` |
| Chat widget | 🟢 Implémenté | `/api/chat` (AI?) |
| Cookie consent | 🟢 Implémenté | `CookieConsent.tsx` |
| Google Analytics 4 | 🟢 Implémenté | GA4 avec consent GDPR |

## C) État de maturité global: 🟢 Production-ready

---

# 📊 Résumé API Backend

**Total routes**: ~230 endpoints

## Catégories principales

| Catégorie | Nombre approx. | État |
|-----------|----------------|------|
| Accounts (membres) | ~15 | 🟢 |
| Admin auth | ~5 | 🟢 |
| Communities | ~25 | 🟢 |
| Members/Memberships | ~20 | 🟢 |
| Articles/News | ~10 | 🟢 |
| Events (V2) | ~15 | 🟢 |
| Messages | ~10 | 🟢 |
| Payments/Billing | ~20 | 🟢 |
| Collections | ~10 | 🟢 |
| Tags | ~10 | 🟢 |
| Sections/Categories | ~10 | 🟢 |
| Platform admin | ~30 | 🟢 |
| Owner | ~5 | 🟢 |
| Self-enrollment | ~10 | 🟢 |
| Webhooks | ~2 | 🟢 |
| Debug/Health | ~15 | 🟢 |

---

# 🔐 Intégrations externes configurées

| Service | État | Fichiers clés |
|---------|------|---------------|
| Firebase Auth | 🟢 Configuré | `client/src/lib/firebase.ts`, `client/.env` |
| Stripe Payments | 🟢 Configuré | `server/stripe.ts`, `server/stripeClient.ts` |
| Stripe Connect | 🟢 Configuré | `server/stripeConnect.ts` |
| SendGrid (email) | 🟢 Configuré | `server/services/mailer/mailer.ts` |
| Neon PostgreSQL | 🟢 Configuré | `DATABASE_URL` env |
| Cloudflare R2 (CDN) | 🟢 Configuré | `cdn.koomy.app` |
| Replit Object Storage | 🟢 Configuré | Bucket configuré |
| Google Analytics 4 | 🟢 Configuré | `client/src/lib/analytics.ts` |

---

# ⚠️ Capacités partielles ou fragiles identifiées

| Capacité | Plateforme | État | Raison |
|----------|------------|------|--------|
| Firebase domain auth | Replit Dev | 🟡 | Domaines *.replit.dev non autorisés dans Firebase Console |
| Login Google (admin/platform/owner) | All Admin | ⚪ | INTERDIT par contrat (Firebase = members ONLY) |
| Admin signup | Web Admin | 🔴 | Route redirige vers login (contrat: join-only) |
| Admin reset password | Web Admin | 🟡 | Non implémenté côté legacy (backend only) |
| iOS Admin build | Mobile | 🟡 | Partiel (android complet, iOS à vérifier) |
| Mobile Admin signup | Mobile Admin | 🟡 | Route existe mais contrat = join-only |

## Rappel Contrat Identité (2026-01)

| Mode | Auth | Plateformes |
|------|------|-------------|
| FIREBASE_ONLY | Firebase Auth (email/password + Google) | Web Member, Mobile Member |
| LEGACY_ONLY | Legacy Koomy (email/password backend) | Web Admin, Mobile Admin, Platform, Owner, White-Label |

---

# 📝 Légende

- 🟢 Implémenté et utilisable
- 🟡 Implémenté mais partiel / fragile
- 🔴 Présent dans le code mais inutilisable
- ⚪ Absent

---

**Fin du rapport**  
**Document généré le**: 2026-01-23  
**Commit SHA**: 6fd6261
