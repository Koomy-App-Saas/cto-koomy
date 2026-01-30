# Variables d'environnement Railway

Ce document liste toutes les variables d'environnement nécessaires pour déployer Koomy sur Railway.

## Base de données

| Variable | Description | Obligatoire | Exemple |
|----------|-------------|-------------|---------|
| `DATABASE_URL` | URL de connexion PostgreSQL | ✅ | `postgresql://user:pass@host:5432/db` |

## Stripe (Paiements)

| Variable | Description | Obligatoire | Exemple |
|----------|-------------|-------------|---------|
| `STRIPE_SECRET_KEY` | Clé secrète Stripe | ✅ | `sk_live_...` ou `sk_test_...` |
| `STRIPE_PUBLISHABLE_KEY` | Clé publique Stripe | ✅ | `pk_live_...` ou `pk_test_...` |
| `STRIPE_WEBHOOK_SECRET` | Secret du webhook Stripe | ✅ | `whsec_...` |
| `STRIPE_PRICE_PLUS_MONTHLY` | ID prix PLUS mensuel | ❌ | `price_...` |
| `STRIPE_PRICE_PLUS_YEARLY` | ID prix PLUS annuel | ❌ | `price_...` |
| `STRIPE_PRICE_PRO_MONTHLY` | ID prix PRO mensuel | ❌ | `price_...` |
| `STRIPE_PRICE_PRO_YEARLY` | ID prix PRO annuel | ❌ | `price_...` |

## Email (SendGrid)

| Variable | Description | Obligatoire | Exemple |
|----------|-------------|-------------|---------|
| `EMAIL_PROVIDER` | Provider email (doit être `sendgrid`) | ⚠️ | `sendgrid` |
| `SENDGRID_API_KEY` | Clé API SendGrid | ⚠️ | `SG.xxxxxxxxxx` |
| `MAIL_FROM` | Adresse d'expéditeur | ⚠️ | `noreply@koomy.app` |
| `MAIL_FROM_NAME` | Nom d'expéditeur | ❌ | `Koomy` |
| `MAIL_REPLY_TO` | Adresse de réponse | ❌ | `support@koomy.app` |

> ⚠️ **Note importante**: Si ces variables ne sont pas configurées, les emails seront **ignorés** (skipped) avec un warning dans les logs, mais les opérations (création de membre, etc.) continueront sans erreur.

## Object Storage (R2/S3)

| Variable | Description | Obligatoire | Exemple |
|----------|-------------|-------------|---------|
| `OBJECT_STORAGE_PROVIDER` | Provider de stockage | ❌ | `s3-r2` ou `replit-object-storage` |
| `R2_ENDPOINT` | Endpoint Cloudflare R2 | Si R2 | `https://xxx.r2.cloudflarestorage.com` |
| `R2_ACCESS_KEY_ID` | Clé d'accès R2 | Si R2 | `...` |
| `R2_SECRET_ACCESS_KEY` | Secret R2 | Si R2 | `...` |
| `R2_BUCKET_NAME` | Nom du bucket R2 | Si R2 | `koomy-assets` |

## Session

| Variable | Description | Obligatoire | Exemple |
|----------|-------------|-------------|---------|
| `SESSION_SECRET` | Secret pour les sessions | ✅ | Chaîne aléatoire longue |

## Production

| Variable | Description | Obligatoire | Exemple |
|----------|-------------|-------------|---------|
| `NODE_ENV` | Environnement | ✅ | `production` |
| `PORT` | Port du serveur | ❌ | `5000` (défaut) |

## Configuration minimale pour Railway

```bash
# Base de données (fourni par Railway PostgreSQL)
DATABASE_URL=postgresql://...

# Session
SESSION_SECRET=your-random-secret-here

# Stripe
STRIPE_SECRET_KEY=sk_live_...
STRIPE_PUBLISHABLE_KEY=pk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...

# Email (optionnel mais recommandé)
EMAIL_PROVIDER=sendgrid
SENDGRID_API_KEY=SG.xxxxxxxxxx
MAIL_FROM=noreply@votredomaine.com
MAIL_FROM_NAME=UNSA Lidl

# Production
NODE_ENV=production
```

## Comportement sans configuration email

Si `EMAIL_PROVIDER` n'est pas `sendgrid` ou si `SENDGRID_API_KEY` est absent:

1. Les fonctions d'envoi d'email retournent `{ success: false, skipped: true }`
2. Un warning est loggé: `[Email] Provider not configured, skipping send`
3. Les opérations (création de membre, invitation, etc.) **continuent normalement**
4. Aucune exception n'est levée

Cela permet de déployer et tester l'application sans configuration email fonctionnelle.
