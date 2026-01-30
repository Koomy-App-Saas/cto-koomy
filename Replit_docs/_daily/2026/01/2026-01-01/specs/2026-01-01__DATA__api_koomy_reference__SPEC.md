# Koomy - Référence API Backend

Ce document recense l'ensemble des APIs backend utilisées par l'application Koomy (web et mobile), avec leurs URLs de production/sandbox et leurs cas d'usage.

**Dernière mise à jour :** 22 janvier 2026  
**Version :** 2.1 (ajout documentation Sandbox)

---

## Environnements

### Architecture Multi-Environnement

Koomy utilise une architecture sandbox/production isolée pour garantir la sécurité des données.

| Environnement | Usage | Base de données | CDN |
|---------------|-------|-----------------|-----|
| **Production** | Clients réels, données live | Neon PostgreSQL (prod) | cdn.koomy.app |
| **Sandbox** | Tests, démos, développement | Neon PostgreSQL (sandbox) | cdn-sandbox.koomy.app |
| **Développement** | Local (Replit dev) | DB dev locale | Replit Object Storage |

### Variable d'Environnement KOOMY_ENV

| Valeur | Description |
|--------|-------------|
| `production` | Environnement de production |
| `sandbox` | Environnement de test/démo |
| `development` | Développement local |

### Guardrails de Sécurité

Le serveur refuse de démarrer si `KOOMY_ENV` ne correspond pas aux patterns de `DATABASE_URL` :

| Pattern DATABASE_URL | Environnement attendu |
|---------------------|----------------------|
| `/main`, `/production`, `-prod-`, `koomy-prod` | production |
| `/dev`, `/development`, `-sandbox-`, `koomy-sandbox` | sandbox/development |

---

## Configuration Critique pour Mobile

### URL Backend par Environnement

| Environnement | URL API | CDN Assets |
|---------------|---------|------------|
| **Production** | `https://api.koomy.app` | `https://cdn.koomy.app` |
| **Sandbox** | `https://api-sandbox.koomy.app` | `https://cdn-sandbox.koomy.app` |
| **Développement (Replit)** | `https://{repl-id}.replit.dev` | Replit Object Storage |
| **Développement local** | `http://localhost:5000` | Local |

### Configuration Mobile (Capacitor)

**Fichier :** `client/src/api/config.ts`

```typescript
import { Capacitor } from '@capacitor/core';

const getApiBaseUrl = (): string => {
  if (import.meta.env.VITE_API_URL) {
    return import.meta.env.VITE_API_URL;
  }
  
  if (Capacitor.isNativePlatform()) {
    return "https://VOTRE_URL_REPLIT.replit.dev"; // URL PRODUCTION
  }
  
  return ""; // Web relatif
};

export const API_BASE_URL = getApiBaseUrl();
```

### Points d'Attention Mobile

| Risque | Description | Solution |
|--------|-------------|----------|
| **URL .local** | `app.koomy.local` (Capacitor hostname) n'est PAS un backend valide | Toujours utiliser l'URL Replit complète |
| **HTTP non sécurisé** | Android bloque les requêtes HTTP non-HTTPS | Utiliser uniquement HTTPS |
| **CORS** | Requêtes cross-origin bloquées | Le backend doit autoriser l'origin mobile |
| **Sandbox/Prod mismatch** | App sandbox pointant vers API prod | Vérifier cohérence KOOMY_ENV |

---

## API Environnement et Debug

### Endpoints Environnement

| Méthode | Path | Description | Auth | Disponibilité |
|---------|------|-------------|------|---------------|
| GET | `/api/env` | Retourne l'environnement actuel | Non | Tous |
| GET | `/api/_debug/db-identity` | Identité base de données | Header secret | Sandbox uniquement |

### GET `/api/env`

Retourne les informations d'environnement pour le frontend.

**Response :**
```json
{
  "env": "sandbox",
  "isSandbox": true,
  "isProduction": false
}
```

**Usage Frontend :**
- Affichage du bandeau "SANDBOX" dans AdminLayout
- Validation avant opérations de paiement (envGuard.ts)

### GET `/api/_debug/db-identity` (Sandbox uniquement)

Endpoint de debug pour valider l'identité de la base de données. Protégé par secret.

**Prérequis :**
- `KOOMY_ENV=sandbox` (retourne 404 en production)
- Header `X-Debug-Secret: {DEBUG_IDENTITY_SECRET}`

**Response :**
```json
{
  "env": "sandbox",
  "nodeEnv": "development",
  "database": {
    "name": "koomy_sandbox",
    "host": "ep-xxx-sandbox.neon.tech",
    "port": 5432
  },
  "patterns": {
    "matchesProd": false,
    "matchesSandbox": true
  }
}
```

**Sécurité :** Ne jamais exposer DATABASE_URL complet.

---

## 1. API Authentification Membres (Accounts)

**Module Backend :** `server/routes.ts` (lignes 107-325)  
**Usage :** Application mobile membre Koomy

### Endpoints

| Méthode | Path | Description | Auth |
|---------|------|-------------|------|
| POST | `/api/accounts/register` | Inscription compte membre | Non |
| POST | `/api/accounts/login` | Connexion compte membre | Non |
| GET | `/api/accounts/:id` | Récupérer infos compte | Non* |
| PATCH | `/api/accounts/:id` | Modifier profil (nom, prénom) | Non* |
| PATCH | `/api/accounts/:id/avatar` | Modifier avatar | Non* |
| PATCH | `/api/accounts/:id/password` | Changer mot de passe | Non* |
| POST | `/api/accounts/:id/deletion-request` | Demander suppression RGPD | Non* |
| GET | `/api/accounts/:id/memberships` | Lister les adhésions du compte | Non* |

*Auth implicite via ID en paramètre

### Détails

#### POST `/api/accounts/login`

**Critique pour mobile** - Premier appel après lancement de l'app.

**Request :**
```json
{
  "email": "user@example.com",
  "password": "motdepasse"
}
```

**Response Success (200) :**
```json
{
  "account": {
    "id": "uuid",
    "email": "user@example.com",
    "firstName": "Jean",
    "lastName": "Dupont",
    "avatar": null
  },
  "memberships": [
    {
      "id": "uuid",
      "communityId": "uuid",
      "memberId": "M001",
      "displayName": "Jean Dupont",
      "role": "member",
      "status": "active"
    }
  ]
}
```

**Response Error (401) :**
```json
{
  "error": "Invalid credentials"
}
```

**Consommation Frontend :**
- `client/src/pages/mobile/Login.tsx` (ligne 44)
- `client/src/pages/mobile/WhiteLabelLogin.tsx` (ligne 143)

#### POST `/api/accounts/register`

**Request :**
```json
{
  "email": "user@example.com",
  "password": "motdepasse",
  "firstName": "Jean",
  "lastName": "Dupont"
}
```

**Consommation Frontend :**
- `client/src/pages/mobile/Login.tsx` (ligne 95)

---

## 2. API Adhésions (Memberships)

**Module Backend :** `server/routes.ts` (lignes 327-473)  
**Usage :** Réclamation de carte membre, liaison compte-communauté

### Endpoints

| Méthode | Path | Description | Auth |
|---------|------|-------------|------|
| POST | `/api/memberships/claim` | Réclamer une adhésion avec code | Non* |
| GET | `/api/memberships/verify/:claimCode` | Vérifier validité d'un code | Non |
| POST | `/api/memberships/register-and-claim` | Inscription + réclamation en une fois | Non |
| POST | `/api/memberships` | Créer une adhésion (admin) | Admin |
| PATCH | `/api/memberships/:id` | Modifier une adhésion | Admin |
| DELETE | `/api/memberships/:id` | Supprimer une adhésion | Admin |
| POST | `/api/memberships/:id/regenerate-code` | Régénérer code de réclamation | Admin |

### Détails

#### GET `/api/memberships/verify/:claimCode`

Vérifie si un code de réclamation est valide et non encore utilisé.

**Response Success :**
```json
{
  "valid": true,
  "displayName": "Jean Dupont",
  "communityName": "Club Échecs Paris",
  "communityLogo": "https://...",
  "memberId": "M001",
  "section": "Paris Centre"
}
```

**Consommation Frontend :**
- `client/src/pages/mobile/AddCard.tsx` (ligne 48)
- `client/src/pages/mobile/WhiteLabelLogin.tsx` (ligne 56)

---

## 3. API Authentification Admin/Back-Office

**Module Backend :** `server/routes.ts` (lignes 479-645)  
**Usage :** Connexion des administrateurs communauté

### Endpoints

| Méthode | Path | Description | Auth |
|---------|------|-------------|------|
| POST | `/api/admin/login` | Connexion admin communauté | Non |
| POST | `/api/admin/register` | Inscription admin (avec code invitation) | Non |

### Détails

#### POST `/api/admin/login`

**Request :**
```json
{
  "email": "admin@example.com",
  "password": "motdepasse"
}
```

**Response :**
```json
{
  "user": {
    "id": "uuid",
    "firstName": "Admin",
    "lastName": "User",
    "email": "admin@example.com",
    "avatar": null,
    "phone": null
  },
  "memberships": [
    {
      "id": "uuid",
      "communityId": "uuid",
      "adminRole": "super_admin",
      "community": {
        "id": "uuid",
        "name": "Club Échecs Paris",
        "logo": null
      }
    }
  ]
}
```

**Consommation Frontend :**
- `client/src/pages/mobile/admin/Login.tsx` (ligne 25)
- `client/src/pages/admin/Login.tsx`

---

## 4. API Authentification Plateforme (Super Admin)

**Module Backend :** `server/routes.ts` (lignes 680-1079)  
**Usage :** Accès SuperDashboard plateforme Koomy

### Sécurité Renforcée

| Mesure | Description |
|--------|-------------|
| **Restriction IP** | France uniquement (header CloudFlare CF-IPCountry) |
| **Session 2h** | Expiration automatique, renouvellement obligatoire |
| **Session unique** | Nouvelle connexion révoque les sessions existantes |
| **Rate limiting** | 5 échecs = blocage 15 minutes |
| **Audit complet** | Toutes les actions tracées |

### Endpoints

| Méthode | Path | Description | Auth |
|---------|------|-------------|------|
| POST | `/api/platform/login` | Connexion super admin | Non |
| POST | `/api/platform/validate-session` | Valider token session | Token |
| POST | `/api/platform/renew-session` | Renouveler session (2h) | Token |
| POST | `/api/platform/logout` | Déconnexion | Token |
| GET | `/api/platform/audit-logs` | Logs d'audit | Token |

### Détails

#### POST `/api/platform/login`

**Request :**
```json
{
  "email": "admin@koomy.app",
  "password": "motdepasse"
}
```

**Response Success :**
```json
{
  "user": {
    "id": "uuid",
    "firstName": "Platform",
    "lastName": "Admin",
    "email": "admin@koomy.app",
    "globalRole": "platform_super_admin",
    "isPlatformOwner": true
  },
  "session": {
    "token": "hex-token-32-bytes",
    "expiresAt": "2024-12-21T16:30:00.000Z",
    "durationHours": 2
  }
}
```

**Response Error (403) - Hors France :**
```json
{
  "error": "Accès refusé. La plateforme d'administration est uniquement accessible depuis la France.",
  "countryCode": "US"
}
```

---

## 5. API Communautés

**Module Backend :** `server/routes.ts` (lignes 1082-1270)

### Endpoints

| Méthode | Path | Description | Auth |
|---------|------|-------------|------|
| GET | `/api/communities` | Liste communautés publiques (sans white-label) | Non |
| GET | `/api/platform/all-communities` | Toutes les communautés (avec white-label) | Platform |
| GET | `/api/communities/:id` | Détails d'une communauté | Non |
| POST | `/api/communities` | Créer une communauté | Admin |
| PUT | `/api/communities/:id` | Modifier une communauté | Admin |
| GET | `/api/communities/:id/quota` | Vérifier quota membres | Admin |
| PATCH | `/api/communities/:id/plan` | Changer de plan | Platform |

### Détails

#### GET `/api/communities`

**Important Mobile :** Utilisé pour afficher le hub des communautés.

Retourne uniquement les communautés publiques (exclut les white-label).

**Response :**
```json
[
  {
    "id": "uuid",
    "name": "Club Échecs Paris",
    "logo": null,
    "description": "Le club d'échecs pour tous",
    "memberCount": 150,
    "planId": "free",
    "whiteLabel": false
  }
]
```

---

## 6. API White Label

**Module Backend :** `server/routes.ts` (lignes 56-104)

### Endpoints

| Méthode | Path | Description | Auth |
|---------|------|-------------|------|
| GET | `/api/white-label/config` | Configuration white-label par hostname | Non |

### Détails

#### GET `/api/white-label/config`

Détecte automatiquement si le domaine d'accès est un white-label.

**Request :** Aucun body, détection par hostname

**Response (white-label actif) :**
```json
{
  "whiteLabel": true,
  "communityId": "uuid",
  "communityName": "UNSA Lidl France",
  "communityLogo": "https://...",
  "brandConfig": {
    "appName": "UNSA Lidl",
    "brandColor": "#e30613",
    "logoUrl": "https://..."
  },
  "whiteLabelTier": "premium",
  "hostname": "unsalidlfrance.koomy.app"
}
```

**Response (pas white-label) :**
```json
{
  "whiteLabel": false,
  "hostname": "app.koomy.app"
}
```

---

## 7. API Contenu (News, Events)

**Module Backend :** `server/routes.ts` (lignes 1740-1860)

### Endpoints News

| Méthode | Path | Description | Auth |
|---------|------|-------------|------|
| GET | `/api/communities/:communityId/news` | Liste actualités | Non |
| GET | `/api/news/:id` | Détail actualité | Non |
| POST | `/api/news` | Créer actualité | Admin |
| PATCH | `/api/news/:id` | Modifier actualité | Admin |

### Endpoints Events

| Méthode | Path | Description | Auth |
|---------|------|-------------|------|
| GET | `/api/communities/:communityId/events` | Liste événements | Non |
| GET | `/api/events/:id` | Détail événement | Non |
| POST | `/api/events` | Créer événement | Admin |
| PATCH | `/api/events/:id` | Modifier événement | Admin |

---

## 8. API Tags & Segmentation

**Module Backend :** `server/routes.ts` (lignes 4889-5080)

### Endpoints

| Méthode | Path | Description | Auth |
|---------|------|-------------|------|
| GET | `/api/communities/:communityId/tags` | Liste tags | Admin |
| POST | `/api/communities/:communityId/tags` | Créer tag | Admin |
| GET | `/api/tags/:id` | Détail tag | Admin |
| PUT | `/api/tags/:id` | Modifier tag | Admin |
| POST | `/api/tags/:id/deactivate` | Désactiver tag | Admin |
| DELETE | `/api/tags/:id` | Supprimer tag | Admin |
| GET | `/api/communities/:communityId/memberships/:membershipId/tags` | Tags d'un membre | Admin |
| PUT | `/api/communities/:communityId/memberships/:membershipId/tags` | Assigner tags | Admin |

**Consommation Frontend :**
- `client/src/pages/mobile/admin/Tags.tsx` (lignes 80, 107, 134, 162)

---

## 10. API Paiements (Stripe)

**Module Backend :** `server/routes.ts` (lignes 3719-4275)

### Endpoints

| Méthode | Path | Description | Auth |
|---------|------|-------------|------|
| POST | `/api/payments/create-koomy-subscription-session` | Abonnement SaaS | Admin |
| POST | `/api/payments/connect-community` | Activer Stripe Connect | Admin |
| POST | `/api/payments/create-membership-session` | Paiement cotisation | Member |
| POST | `/api/payments/membership/checkout-session` | Session Checkout Stripe | Member |
| POST | `/api/payments/create-collection-session` | Don/Collecte | Member |
| GET | `/api/billing/status` | Statut facturation | Admin |
| POST | `/api/billing/checkout` | Checkout abonnement | Admin |
| POST | `/api/billing/portal` | Portail client Stripe | Admin |

---

## 11. API Collections (Fundraising)

**Module Backend :** `server/routes.ts` (lignes 3955-4395)

### Endpoints

| Méthode | Path | Description | Auth |
|---------|------|-------------|------|
| POST | `/api/collections` | Créer collecte | Admin |
| GET | `/api/collections/:communityId` | Liste collectes | Admin |
| GET | `/api/communities/:communityId/collections/all` | Toutes collectes | Admin |
| POST | `/api/collections/:id/close` | Clôturer collecte | Admin |

---

## 12. API Plans Tarifaires (SaaS)

**Module Backend :** `server/routes.ts` (lignes 1174-1270)

### Endpoints

| Méthode | Path | Description | Auth |
|---------|------|-------------|------|
| GET | `/api/plans` | Liste plans publics | Non |
| GET | `/api/plans/:id` | Détail plan par ID | Non |
| GET | `/api/plans/code/:code` | Détail plan par code | Non |
| PUT | `/api/platform/plans/:id` | Modifier plan | Platform |

---

## 12bis. API Formules d'Adhésion (Membership Plans)

**Module Backend :** `server/routes.ts` (lignes 7383-7600)  
**Usage :** Gestion des formules d'adhésion par communauté (tarifs membres)

### Endpoints

| Méthode | Path | Description | Auth |
|---------|------|-------------|------|
| GET | `/api/communities/:communityId/membership-plans` | Liste formules | Admin |
| POST | `/api/communities/:communityId/membership-plans` | Créer formule | Admin |
| GET | `/api/membership-plans/:id` | Détail formule | Admin |
| PATCH | `/api/membership-plans/:id` | Modifier formule | Admin |
| DELETE | `/api/membership-plans/:id` | Supprimer formule | Admin |

### Types de Formules (v2 - Janvier 2026)

| Type | Description | Champs requis |
|------|-------------|---------------|
| `FIXED_PERIOD` | Période fixe (année civile ou saison) | `fixedPeriodType` |
| `ROLLING_DURATION` | Durée glissante depuis inscription | `rollingDurationMonths` |

### Sous-types FIXED_PERIOD

| Valeur | Période | Dates calculées |
|--------|---------|-----------------|
| `CALENDAR_YEAR` | Année civile | 1 jan - 31 déc |
| `SEASON` | Saison sportive | 1 sept - 31 juil |

### Détails

#### POST `/api/communities/:communityId/membership-plans`

**Request (FIXED_PERIOD) :**
```json
{
  "name": "Adhésion Saison 2025-2026",
  "membershipType": "FIXED_PERIOD",
  "fixedPeriodType": "SEASON",
  "price": 5000,
  "isActive": true
}
```

**Request (ROLLING_DURATION) :**
```json
{
  "name": "Adhésion 12 mois",
  "membershipType": "ROLLING_DURATION",
  "rollingDurationMonths": 12,
  "price": 3500,
  "isActive": true
}
```

**Response :**
```json
{
  "id": "uuid",
  "communityId": "uuid",
  "name": "Adhésion Saison 2025-2026",
  "membershipType": "FIXED_PERIOD",
  "fixedPeriodType": "SEASON",
  "rollingDurationMonths": null,
  "price": 5000,
  "isActive": true
}
```

### Calcul Automatique des Dates

Lors de la création d'une adhésion membre avec une formule :

| Type | membershipStartDate | membershipValidUntil | membershipSeasonLabel |
|------|---------------------|---------------------|----------------------|
| SEASON | 1er sept de la saison en cours | 31 juil suivant | "2025–2026" |
| CALENDAR_YEAR | 1er jan de l'année en cours | 31 déc de l'année | null |
| ROLLING_DURATION | Date de création | Date + X mois | null |

**Consommation Frontend :**
- `client/src/pages/admin/MembershipPlans.tsx`
- `client/src/pages/admin/Members.tsx`
- `client/src/pages/admin/MemberDetails.tsx`

---

## 13. API Messages

**Module Backend :** `server/routes.ts`

### Endpoints

| Méthode | Path | Description | Auth |
|---------|------|-------------|------|
| POST | `/api/messages` | Envoyer message | Member/Admin |
| GET | `/api/messages/:conversationId` | Historique conversation | Member/Admin |

**Consommation Frontend :**
- `client/src/pages/mobile/admin/Messages.tsx` (ligne 89)

---

## 14. API Chat IA

**Module Backend :** `server/routes.ts` (ligne 3570)

### Endpoints

| Méthode | Path | Description | Auth |
|---------|------|-------------|------|
| POST | `/api/chat` | Chat avec assistant IA | Non |

**Consommation Frontend :**
- `client/src/components/ChatWidget.tsx` (ligne 71)

---

## 15. API Contact Commercial

**Module Backend :** `server/routes.ts` (lignes 3604-3630)

### Endpoints

| Méthode | Path | Description | Auth |
|---------|------|-------------|------|
| POST | `/api/contact` | Soumettre formulaire contact | Non |
| GET | `/api/platform/contacts` | Liste contacts (platform) | Platform |

---

## Récapitulatif : APIs Critiques pour Build Mobile

### APIs Obligatoires pour un Build Android/iOS Fonctionnel

| Priorité | API | Endpoint | Usage |
|----------|-----|----------|-------|
| **1** | Accounts Login | `POST /api/accounts/login` | Connexion utilisateur |
| **2** | Accounts Register | `POST /api/accounts/register` | Inscription |
| **3** | White-Label Config | `GET /api/white-label/config` | Détection branding |
| **4** | Account Memberships | `GET /api/accounts/:id/memberships` | Récupérer adhésions |
| **5** | Community Details | `GET /api/communities/:id` | Infos communauté |
| **6** | Communities List | `GET /api/communities` | Hub communautés |
| **7** | News List | `GET /api/communities/:id/news` | Actualités |
| **8** | Events List | `GET /api/communities/:id/events` | Événements |
| **9** | Membership Verify | `GET /api/memberships/verify/:code` | Vérifier code |
| **10** | Membership Claim | `POST /api/memberships/claim` | Réclamer carte |

### Configuration Mobile Requise

```typescript
// client/src/api/config.ts
export const API_BASE_URL = Capacitor.isNativePlatform()
  ? "https://VOTRE_URL_PRODUCTION.replit.dev"  // OBLIGATOIRE
  : "";
```

---

## Checklist Avant Build Mobile

- [ ] `API_BASE_URL` pointe vers l'URL de production (pas localhost, pas .local)
- [ ] Le serveur Replit est démarré et accessible
- [ ] Les credentials de test fonctionnent (`demo@koomy.app` / `Demo2025!`)
- [ ] L'application utilise HTTPS (pas HTTP)
- [ ] Capacitor est synchronisé (`npx cap sync android`)

---

## Annexes

### Client HTTP Utilisé

L'application utilise `fetch` natif pour toutes les requêtes API :

```typescript
const response = await fetch(`${API_URL}/api/accounts/login`, {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({ email, password })
});
```

### Fichiers Frontend Consommant les APIs

| Fichier | APIs Utilisées |
|---------|----------------|
| `client/src/pages/mobile/Login.tsx` | accounts/login, accounts/register |
| `client/src/pages/mobile/AddCard.tsx` | memberships/verify, memberships/claim |
| `client/src/pages/mobile/admin/Login.tsx` | admin/login |
| `client/src/pages/mobile/admin/Tags.tsx` | tags/* |
| `client/src/contexts/AuthContext.tsx` | accounts/:id/memberships |
| `client/src/contexts/WhiteLabelContext.tsx` | white-label/config |

---

## Routage Frontend par Hostname (Sandbox/Production)

### Hostnames Connus

Le frontend utilise un routage déterministe basé sur le hostname pour éviter les appels API inutiles.

| Hostname Sandbox | Hostname Production | Mode | Shell |
|-----------------|---------------------|------|-------|
| sitepublic-sandbox.koomy.app | koomy.app | SITE_PUBLIC | WebsiteHome |
| sandbox.koomy.app | app.koomy.app | WALLET | MobileLogin |
| backoffice-sandbox.koomy.app | backoffice.koomy.app | BACKOFFICE | AdminLogin |
| club-mobile-sandbox.koomy.app | app-pro.koomy.app | CLUB_MOBILE | MobileAdminLogin |
| saasowner-sandbox.koomy.app | lorpesikoomyadmin.koomy.app | SAAS_OWNER | PlatformLogin |

### Comportement

- **Hostname connu** (`isForcedMode: true`) → Pas de fetch `/wl.json` ni `/api/white-label/config`
- **Hostname inconnu *.koomy.app** → Mode WHITE_LABEL (lookup DB requis)
- **localhost, *.replit.dev** → Mode STANDARD (landing page)

### Fichier de Résolution

**Fichier :** `client/src/lib/appModeResolver.ts`

---

## Résolution URLs CDN (Assets)

### Architecture CDN

| Environnement | CDN URL | Fallback API |
|---------------|---------|--------------|
| Production | cdn.koomy.app | api.koomy.app/objects/ |
| Sandbox | cdn-sandbox.koomy.app | api-sandbox.koomy.app/objects/ |
| Développement | Replit Object Storage | /objects/ (local) |

### Résolveur Centralisé

**Fichier :** `client/src/lib/cdnResolver.ts`

```typescript
export function resolveCdnUrl(relativePath: string): string {
  // Détecte automatiquement l'environnement
  // et préfixe le bon CDN
}
```

### Détection du Provider

| Variable | Provider |
|----------|----------|
| `S3_ENDPOINT` défini | Cloudflare R2 (production/sandbox) |
| `DEFAULT_OBJECT_STORAGE_BUCKET_ID` défini | Replit Object Storage (dev) |

---

## Checklist Environnement

### Avant déploiement Sandbox

- [ ] `KOOMY_ENV=sandbox` configuré
- [ ] `DATABASE_URL` pointe vers base sandbox
- [ ] CDN configuré sur cdn-sandbox.koomy.app
- [ ] Stripe en mode test
- [ ] Bandeau "SANDBOX" visible dans backoffice

### Avant déploiement Production

- [ ] `KOOMY_ENV=production` configuré
- [ ] `DATABASE_URL` pointe vers base production
- [ ] CDN configuré sur cdn.koomy.app
- [ ] Stripe en mode live
- [ ] Pas de bandeau "SANDBOX"

---

*Document créé le 21 décembre 2024*  
*Mise à jour : 22 janvier 2026 (ajout documentation Sandbox/Production)*
