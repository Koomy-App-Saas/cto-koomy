# Koomy SaaS Platform - Guide de Déploiement

Ce document décrit la configuration des 3 environnements de déploiement.

## Environnements

| Environnement | Description | Hébergeur |
|---------------|-------------|-----------|
| **DEV** | Développement et tests | Replit |
| **PROD API** | Backend API en production | Railway ou Render |
| **PROD Frontend** | Frontend web en production | Vercel |

---

## Variables d'Environnement

### Variables Communes (tous environnements)

| Variable | Description | Obligatoire |
|----------|-------------|-------------|
| `NODE_ENV` | `development` ou `production` | Oui |
| `PORT` | Port du serveur (défaut: 5000) | Non |
| `DATABASE_URL` | URL PostgreSQL Neon | Oui |

### Variables Backend (PROD API)

| Variable | Description | Obligatoire |
|----------|-------------|-------------|
| `DATABASE_URL` | `postgresql://user:pass@host/db?sslmode=require` | Oui |
| `STRIPE_WEBHOOK_SECRET` | Secret webhook Stripe | Oui |
| `PUBLIC_URL` | URL publique du frontend (ex: `https://app.koomy.app`) | Oui |
| `PRODUCTION_API_URL` | URL de l'API (ex: `https://api.koomy.app`) | Oui |

**Note** : Stripe et SendGrid sont gérés via les intégrations Replit sur Replit. Pour un hébergement externe, configurer également :
- `STRIPE_SECRET_KEY` ou utiliser la variable via le connecteur Stripe
- SendGrid via leur SDK ou un service SMTP alternatif

### Variables Frontend (PROD Frontend / Vercel)

| Variable | Description | Obligatoire |
|----------|-------------|-------------|
| `VITE_API_URL` | URL de l'API backend (ex: `https://api.koomy.app`) | Oui |
| `VITE_PUBLIC_URL` | URL publique du site (ex: `https://app.koomy.app`) | Non |

### Variables Mobile (Build Capacitor)

| Variable | Description | Obligatoire |
|----------|-------------|-------------|
| `PRODUCTION_API_URL` | URL API pour l'app mobile native | Oui |

---

## Configuration par Environnement

### DEV (Replit)

Aucune configuration manuelle requise. Les variables Replit sont détectées automatiquement :
- `REPLIT_DEV_DOMAIN` → Utilisé pour les meta tags OG
- `REPLIT_INTERNAL_APP_DOMAIN` → Utilisé en production Replit

```bash
# Lancer en développement
npm run dev
```

### PROD API (Railway / Render)

Variables à configurer dans le dashboard Railway/Render :

```env
NODE_ENV=production
PORT=5000
DATABASE_URL=postgresql://user:password@host:5432/koomy?sslmode=require
STRIPE_WEBHOOK_SECRET=whsec_...
PUBLIC_URL=https://app.koomy.app
PRODUCTION_API_URL=https://api.koomy.app
```

**Note** : Pour un hébergement hors Replit, il faudra également reconfigurer :
- Le client Stripe (actuellement via intégration Replit)
- Le service email (actuellement via intégration SendGrid Replit)

### PROD Frontend (Vercel)

Variables à configurer dans Vercel :

```env
NODE_ENV=production
VITE_API_URL=https://api.koomy.app
VITE_PUBLIC_URL=https://app.koomy.app
```

---

## Commandes de Build

### Installation des dépendances

```bash
npm install
```

### Build complet (API + Frontend)

```bash
npm run build
```

Produit :
- `dist/` - Backend compilé
- `dist/public/` - Frontend compilé

### Démarrage en production

```bash
npm run start
# ou
node dist/index.js
```

### Build Capacitor (Mobile PROD)

```bash
# 1. Définir l'URL API de production
export PRODUCTION_API_URL=https://api.koomy.app

# 2. Build du frontend mobile
npm run build

# 3. Synchroniser avec Capacitor
npx cap sync

# 4. Build Android (release)
cd artifacts/mobile/UNSALidlApp
./build-release.sh

# 5. Build iOS (via Xcode)
npx cap open ios
```

---

## Endpoints de Santé

### GET /health

Endpoint simple pour les healthchecks cloud (Railway, Vercel, AWS ELB).

```bash
curl https://api.koomy.app/health
```

Réponse :
```json
{
  "ok": true,
  "timestamp": "2026-01-03T07:09:43.228Z"
}
```

### GET /api/health

Endpoint détaillé pour diagnostics mobile et monitoring.

```bash
curl https://api.koomy.app/api/health
```

Réponse :
```json
{
  "status": "ok",
  "timestamp": "2026-01-03T07:09:43.228Z",
  "server": "koomy-api",
  "version": "1.3.6",
  "uptime": 12345.67,
  "traceId": "abc123",
  "receivedHeaders": {
    "platform": "web",
    "userAgent": "Mozilla/5.0..."
  }
}
```

---

## Sécurité : Garde-fou Replit en Production

**Important** : En `NODE_ENV=production`, le système vérifie qu'aucune URL ne contient `replit`.

Si une URL Replit est détectée en production, une erreur explicite est levée :

```
ERROR: Replit URL detected in production environment. 
Set PRODUCTION_API_URL to your production domain.
```

Cette protection empêche les déploiements accidentels avec des URLs de développement.

---

## Checklist de Déploiement

### Avant le déploiement PROD API

- [ ] `DATABASE_URL` pointe vers Neon production
- [ ] `STRIPE_SECRET_KEY` est la clé **live** (pas test)
- [ ] `STRIPE_WEBHOOK_SECRET` correspond au webhook prod
- [ ] `SENDGRID_API_KEY` est configurée
- [ ] `SESSION_SECRET` est unique et sécurisé (32+ caractères)
- [ ] `PUBLIC_URL` et `PRODUCTION_API_URL` sont les domaines finaux

### Avant le déploiement PROD Frontend

- [ ] `VITE_API_URL` pointe vers l'API de production
- [ ] Build réussi sans erreurs
- [ ] Test de connexion à l'API depuis Vercel

### Avant le build Mobile

- [ ] `PRODUCTION_API_URL` est l'URL API finale
- [ ] Certificats de signature configurés
- [ ] Version et versionCode incrémentés

---

## Fallback et Priorités

### Résolution de l'URL publique (meta tags)

1. `PUBLIC_URL` (variable explicite)
2. `VITE_PUBLIC_URL` (variable Vite)
3. `REPLIT_INTERNAL_APP_DOMAIN` (production Replit)
4. `REPLIT_DEV_DOMAIN` (développement Replit)

### Résolution de l'URL API (mobile)

1. `PRODUCTION_API_URL` (si définie)
2. Fallback Replit (DEV uniquement)
3. **Erreur** si Replit URL en production

---

## Support

Pour toute question de déploiement, contacter l'équipe technique Koomy.
