# Rapport d'Audit Sécurité - lorpesikoomyadmin.koomy.app

**Date:** 13 Janvier 2026  
**Cible:** Dashboard Platform Admin Koomy  
**URL:** https://lorpesikoomyadmin.koomy.app

---

## 1. Cartographie d'accès (Edge -> App)

### Hébergement

| Aspect | Valeur |
|--------|--------|
| Plateforme | Railway (production) / Replit (développement) |
| Type de service | Express.js Node.js monolithique |
| Port interne | 5000 |
| Protocole | HTTP/1.1, HTTPS (TLS terminé par Railway/Cloudflare) |

**Chemin de requête:**
```
Client → DNS → Cloudflare → Railway → Express.js (port 5000)
```

### Routage basé sur le host

Le serveur utilise un middleware de réécriture basé sur le hostname (`server/index.ts` lignes 178-232):

| Host | Préfixe interne | Page d'accueil |
|------|-----------------|----------------|
| `lorpesikoomyadmin.koomy.app` | `/platform` | `/platform/login` |
| `app.koomy.app` | `/app` | `/app/login` |
| `app-pro.koomy.app` | `/app/admin` | `/app/admin/login` |
| `backoffice.koomy.app` | `/admin` | `/admin/login` |

### Routes publiques vs protégées

| Type | Chemins |
|------|---------|
| **Publiques** | `/`, `/login`, `/assets/*`, `/*.js`, `/*.css`, `/api/platform/login` |
| **Protégées** | `/api/platform/*` (sauf login), `/platform/*` (SPA protégé côté client) |

### Protocoles

| Protocole | Utilisé | Chemins |
|-----------|---------|---------|
| HTTP/HTTPS | Oui | Tous |
| WebSocket | Non | - |
| SSE | Non | - |
| Long-polling | Non | - |

**Note:** Aucun WebSocket ni SSE détecté dans le code server pour le dashboard platform.

---

## 2. Authentification & Sessions (CRITIQUE)

### Mécanisme d'authentification

| Aspect | Valeur | Fichier source |
|--------|--------|----------------|
| Type | Session server-side avec token opaque | `server/routes.ts:2372` |
| Stockage token | `localStorage` côté client | Client SPA |
| Transmission | Header `Authorization: Bearer {token}` | `server/routes.ts:2560` |
| Génération token | `crypto.randomBytes(32).toString('hex')` | `server/routes.ts:2372` |
| Durée session | **2 heures** | `server/routes.ts:2254-2255` |
| Session unique | Oui (revoke all on login) | `server/routes.ts:2376` |
| Table sessions | `platform_sessions` | PostgreSQL |

### Endpoints d'authentification

| Endpoint | Method | Auth requise | Sensibilité | Rate Limit |
|----------|--------|--------------|-------------|------------|
| `/api/platform/login` | POST | Non | CRITIQUE | 5/15min |
| `/api/platform/logout` | POST | Oui (token) | Haute | - |
| `/api/platform/validate-session` | POST | Oui (token) | Haute | - |
| `/api/platform/renew-session` | POST | Oui (token) | Haute | - |

### Sécurités supplémentaires

| Protection | Détail |
|------------|--------|
| **IP Whitelist** | France uniquement (`countryCode !== 'FR'`) - `server/routes.ts:2427` |
| **Lockout** | 5 tentatives max, blocage 30 minutes |
| **Email vérifié** | Requis pour login |
| **Audit logs** | Toutes actions enregistrées dans `platform_audit_logs` |

### Endpoints API Platform (tous protégés)

| Endpoint | Method | Rôle requis | Fonction |
|----------|--------|-------------|----------|
| `/api/platform/audit-logs` | GET | platform_super_admin | Logs d'audit |
| `/api/platform/all-communities` | GET | platform_* | Liste communautés |
| `/api/platform/plans/:id` | PUT | platform_super_admin | Modifier plan |
| `/api/platform/communities/:id/full-access` | POST/DELETE | platform_super_admin | Accès complet |
| `/api/platform/communities/:id/white-label` | PATCH | platform_super_admin | Config white-label |
| `/api/platform/communities/:id/create-owner-admin` | POST | platform_super_admin | Créer admin |
| `/api/platform/communities/:id/name` | PATCH | platform_super_admin | Renommer |
| `/api/platform/communities/:id/details` | GET | platform_* | Détails |
| `/api/platform/full-access-communities` | GET | platform_* | Liste full access |
| `/api/platform/metrics` | GET | platform_* | Métriques |
| `/api/platform/revenue-*` | GET | platform_* | Analytics revenus |
| `/api/platform/top-communities` | GET | platform_* | Top communautés |
| `/api/platform/payments*` | GET | platform_* | Paiements |
| `/api/platform/health/*` | GET | platform_* | Santé système |
| `/api/platform/analytics/*` | GET | platform_* | Analytics |
| `/api/platform/users` | GET/POST | platform_super_admin | Gestion users |
| `/api/platform/users/:id/role` | PATCH/DELETE | platform_super_admin | Rôles |
| `/api/platform/verify` | POST | Non (token email) | Vérification email |
| `/api/platform/resend-verification` | POST | Non | Renvoi email |
| `/api/platform/tickets*` | GET/PATCH/POST | platform_* | Support |
| `/api/platform/contacts` | GET | platform_* | Contacts commerciaux |

---

## 3. Dépendances externes indispensables

### Ressources tierces chargées

| Domaine | Rôle | Impact si bloqué |
|---------|------|------------------|
| `fonts.googleapis.com` | Polices (Inter, Nunito, Montserrat) | UI dégradée |
| `fonts.gstatic.com` | Fichiers polices | UI dégradée |
| `js.stripe.com` | SDK Stripe (paiements) | Checkout bloqué |
| `api.stripe.com` | API Stripe (backend) | Paiements impossibles |
| `hooks.stripe.com` | iFrames Stripe | Éléments paiement cassés |
| `www.googletagmanager.com` | Google Analytics 4 | Analytics non fonctionnel |
| `cdn.koomy.app` | CDN images/assets R2 | Images manquantes |

### Services backend

| Service | Usage | Endpoint webhook |
|---------|-------|------------------|
| **Stripe** | Paiements SaaS + Connect | `/api/stripe/webhook` |
| **SendGrid** | Emails transactionnels | N/A (sortant uniquement) |
| **Neon PostgreSQL** | Base de données | N/A (connexion interne) |
| **Cloudflare R2** | Object storage | N/A (accès via SDK) |

**Note:** Pas de Firebase détecté dans le code.

---

## 4. Contraintes réseau utiles à Cloudflare

### WebSocket/SSE

| Type | Utilisé | Chemins |
|------|---------|---------|
| WebSocket | **Non** | - |
| SSE | **Non** | - |

### Routes nécessitant des IP cloud

| Route | Usage | IP attendues |
|-------|-------|--------------|
| `/api/stripe/webhook` | Webhooks Stripe | [IPs Stripe](https://stripe.com/docs/ips) |
| `/api/internal/cron/saas-status` | Job quotidien | IP Railway cron |

### User-Agents attendus

| Type | Supporté | Notes |
|------|----------|-------|
| Desktop browsers | Oui | Chrome, Firefox, Safari, Edge |
| Mobile browsers | Possible mais non ciblé | Dashboard admin = desktop prioritaire |
| curl/wget | Non attendu | Sauf tests/debug |
| Bots | Non attendu | À bloquer |

### Pays attendus

| Pays | Autorisé | Notes |
|------|----------|-------|
| France (FR) | **Oui** | Seul pays autorisé pour `/api/platform/*` |
| Autres UE | **Bloqué** | Retour 403 |
| Hors UE | **Bloqué** | Retour 403 |

**Note importante:** Le code vérifie `countryCode !== 'FR'` pour les endpoints platform.

### Fichiers statiques

| Pattern | Type |
|---------|------|
| `/assets/*` | JS/CSS/images bundlées |
| `/*.js` | Scripts |
| `/*.css` | Styles |
| `/icons/*` | Icônes |
| `/community-logos/*` | Logos communautés |

### Rate limits existants

| Route | Limite | Fenêtre |
|-------|--------|---------|
| `/api/platform/login` | 5 requêtes | 15 minutes |
| `/api/admin/login` | 5 requêtes | 15 minutes |
| `/api/accounts/login` | 5 requêtes | 15 minutes |
| `/api/accounts/register` | 10 requêtes | 1 heure |
| `/api/admin/register` | 10 requêtes | 1 heure |
| `/api/*` (général) | 100 requêtes | 1 minute |
| `/api/stripe/webhook` | **Exempté** | - |

---

## 5. Risques d'exposition actuels

### Indexation

| Aspect | État | Recommandation |
|--------|------|----------------|
| `robots.txt` | **ABSENT** | Créer avec `Disallow: /` |
| Meta `noindex` | **ABSENT** | Ajouter pour `/platform/*` |
| `X-Robots-Tag` | **ABSENT** | Ajouter header |

### Headers exposés

| Header | État | Risque |
|--------|------|--------|
| `Server` | Masqué par Helmet | OK |
| `X-Powered-By` | Masqué par Helmet | OK |
| `X-Frame-Options` | Présent (Helmet) | OK |
| `X-Content-Type-Options` | Présent (Helmet) | OK |

### Erreurs

| Aspect | État | Risque |
|--------|------|--------|
| Stack traces en prod | Non exposées | OK |
| Messages d'erreur | Génériques | OK |

### CORS

| Origines autorisées | Type |
|---------------------|------|
| `https://koomy.app` | Exact |
| `https://app.koomy.app` | Exact |
| `https://www.koomy.app` | Exact |
| `*.koomy.app` | Regex |
| `*.replit.dev` | Regex (dev) |
| `*.replit.app` | Regex (dev) |
| `capacitor://localhost` | Exact (mobile) |
| `ionic://localhost` | Exact (mobile) |
| `http://localhost:*` | Dev |

**Note:** Pas de wildcard `*` avec credentials - conforme aux bonnes pratiques.

### CSP (Content Security Policy)

```
default-src: 'self'
script-src: 'self', https://js.stripe.com
style-src: 'self', 'unsafe-inline', https://fonts.googleapis.com
font-src: 'self', https://fonts.gstatic.com
img-src: 'self', data:, https:, blob:
connect-src: 'self', https://api.stripe.com, https://*.koomy.app, wss://*.koomy.app
frame-src: 'self', https://js.stripe.com, https://hooks.stripe.com
```

---

## 6. Recommandations Cloudflare

### a) Allowlist IP (pour webhooks/cron)

```
# Stripe Webhooks - Autoriser les IPs Stripe
/api/stripe/webhook → Autoriser IPs Stripe uniquement

# Cron job - Autoriser Railway
/api/internal/cron/* → Autoriser IPs Railway
```

### b) Geo Allowlist

```
# Pour lorpesikoomyadmin.koomy.app
Autoriser: FR uniquement
Action pour autres: Block ou Challenge
```

### c) Block bots

```
# User-Agent patterns à bloquer
Known Bots → Block
Verified Bots → Block (sauf Stripe webhooks)
```

### d) Block User-Agents techniques

```
# Patterns à bloquer
curl/* → Block (sauf /api/stripe/webhook, /api/internal/cron/*)
wget/* → Block
python-requests/* → Block
Go-http-client/* → Block (sauf webhooks)
```

### e) Rate limiting recommandé

| Route Pattern | Limite | Action |
|---------------|--------|--------|
| `/api/platform/login` | 5/15min | Block |
| `/api/platform/*` | 60/min | Challenge |
| `/platform/*` | 100/min | Challenge |
| `/api/stripe/webhook` | 1000/min | Log only |

### f) Cloudflare Access (optionnel)

Compatibilité: **OUI**

Configuration suggérée:
- Application: `lorpesikoomyadmin.koomy.app`
- Policy: Email domain `@koomy.fr` ou liste emails spécifiques
- Bypass: `/api/stripe/webhook`, `/api/internal/cron/*`

---

## Tableau récapitulatif: Cloudflare Rules Inputs

| Host | Path | Method | Auth | Rate Limit | Geo | Deps externes |
|------|------|--------|------|------------|-----|---------------|
| `lorpesikoomyadmin.koomy.app` | `/` | GET | Non | 100/min | FR only | - |
| `lorpesikoomyadmin.koomy.app` | `/platform/*` | GET | Client-side | 100/min | FR only | - |
| `lorpesikoomyadmin.koomy.app` | `/assets/*` | GET | Non | 1000/min | FR only | - |
| `lorpesikoomyadmin.koomy.app` | `/api/platform/login` | POST | Non | **5/15min** | FR only | - |
| `lorpesikoomyadmin.koomy.app` | `/api/platform/*` | * | Bearer token | 60/min | FR only | - |
| `lorpesikoomyadmin.koomy.app` | `/api/stripe/webhook` | POST | Stripe sig | **Exempté** | **Toutes** | Stripe IPs |
| `lorpesikoomyadmin.koomy.app` | `/api/internal/cron/*` | POST | Header secret | **Exempté** | **Toutes** | Railway IPs |

### Dépendances à autoriser en sortie (CSP)

| Domaine | Port | Protocole | Usage |
|---------|------|-----------|-------|
| `fonts.googleapis.com` | 443 | HTTPS | Fonts CSS |
| `fonts.gstatic.com` | 443 | HTTPS | Fonts files |
| `js.stripe.com` | 443 | HTTPS | Stripe SDK |
| `api.stripe.com` | 443 | HTTPS | Stripe API |
| `hooks.stripe.com` | 443 | HTTPS | Stripe iframes |
| `www.googletagmanager.com` | 443 | HTTPS | GA4 (optionnel) |
| `cdn.koomy.app` | 443 | HTTPS | Assets R2 |

---

## Fichiers de référence

| Fichier | Contenu pertinent |
|---------|-------------------|
| `server/index.ts` | CORS, CSP, Rate limiting, Routing |
| `server/routes.ts` | Tous endpoints API, auth, sessions |
| `server/stripe.ts` | Webhooks Stripe |
| `client/index.html` | Resources externes, meta tags |
| `client/src/lib/analytics.ts` | GA4 configuration |

---

*Rapport généré automatiquement - À valider avant mise en production des règles Cloudflare*
