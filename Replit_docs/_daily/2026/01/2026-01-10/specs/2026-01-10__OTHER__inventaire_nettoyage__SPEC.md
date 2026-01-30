# Inventaire Nettoyage Projet Koomy

**Date:** 13 Janvier 2026  
**Statut:** ✅ ARCHIVAGE EFFECTUÉ  
**Projet:** SaaS multi-tenant en production

---

## Résumé Exécutif

| Catégorie | Nombre | Statut |
|-----------|--------|--------|
| Fichiers actifs (A) | ~200+ | ✅ Conservés |
| Doublons potentiels (B) | 2 | ✅ Conservés (placeholders) |
| Fichiers orphelins (C) | 4 | ✅ Archivés |
| Assets non utilisés | 217 | ✅ Archivés |
| Fichiers à risque (D) | auth/payment/email | ⛔ Non touchés |

### Archivage effectué le 13/01/2026

```
archive/
├── scripts-oneshot/          (2 fichiers)
│   ├── cleanup-strasbourg.ts
│   └── migrate-displayname.ts
├── components-unused/        (2 fichiers)
│   ├── spinner.tsx
│   └── staticPlans.ts
└── assets-unused/
    ├── screenshots/          (23 fichiers)
    ├── docs/                 (2 fichiers)
    ├── prompts/              (169 fichiers)
    ├── icons/                (16 fichiers)
    └── misc/                 (7 fichiers)

TOTAL: 221 fichiers archivés
```

---

## CATÉGORIE A - FICHIERS ACTIFS (NE PAS TOUCHER)

### Fichiers critiques (auth, paiement, email, webhook)
```
server/stripe.ts              - Paiements Stripe
server/stripeClient.ts        - Client Stripe (importé par stripe.ts, stripeConnect.ts)
server/stripeConnect.ts       - Stripe Connect
server/routes.ts              - Toutes les routes API
server/storage.ts             - Accès base de données
server/services/mailer/*      - Système email
server/services/saasEmailService.ts - Emails SaaS
server/services/saasStatusJob.ts    - Job transitions SaaS
shared/schema.ts              - Schéma DB Drizzle
```

### Fichiers de configuration racine
```
vite.config.ts                - Config Vite (importé par build)
drizzle.config.ts             - Config Drizzle (utilisé par db:push)
postcss.config.js             - Config PostCSS
capacitor.config.ts           - Config Capacitor racine
vite-plugin-meta-images.ts    - Plugin Vite (importé dans vite.config.ts)
```

### Scripts utilisés (référencés dans package.json ou .replit)
```
script/build.ts               - "build": "tsx script/build.ts"
script/generate-capacitor-config.ts - Utilisé par cap:wl
scripts/pages-redirects.mjs   - "build:pages"
scripts/build-pages-unsalidl.mjs - Référencé dans package.json
```

### Packages mobile-build
```
packages/mobile-build/*       - CLI de build mobile (structure monorepo)
```

### Tenants white-label
```
tenants/unsa-lidl/*           - Config client white-label actif
```

---

## CATÉGORIE B - DOUBLONS POTENTIELS

| Fichier | Doublon de | Preuve | Action proposée |
|---------|------------|--------|-----------------|
| `infra/env/README.md` | N/A | Fichier vide/placeholder | Garder (structure) |
| `infra/deploy/README.md` | N/A | Fichier vide/placeholder | Garder (structure) |

**Commandes utilisées:**
```bash
find infra -type f
# Résultat: 2 README.md vides (placeholders pour structure future)
```

---

## CATÉGORIE C - FICHIERS ORPHELINS

| Fichier | Raison | Preuve | Action proposée |
|---------|--------|--------|-----------------|
| `client/src/components/ui/spinner.tsx` | Jamais importé | `rg -l "Spinner\|spinner" client/src` → uniquement le fichier lui-même | ARCHIVER |
| `client/src/data/staticPlans.ts` | Défini mais jamais importé | `rg "staticPlans" client/src` → seulement définition locale | ARCHIVER |
| `script/cleanup-strasbourg.ts` | Script one-shot terminé | Utilisé pour cleanup data Strasbourg, pas dans configs | ARCHIVER |
| `scripts/migrate-displayname.ts` | Migration one-shot terminée | Pas dans package.json ni .replit | ARCHIVER |
| `scripts/generate-playstore-screenshots.ts` | Script utilitaire dev | Pas dans configs, usage manuel | GARDER (utils dev) |

### Preuves détaillées

**spinner.tsx:**
```bash
$ rg -l "Spinner|spinner" client/src
client/src/components/ui/spinner.tsx  # <- seulement lui-même
# Aucun import trouvé dans l'application
```

**staticPlans.ts:**
```bash
$ rg "staticPlans" client/src
client/src/data/staticPlans.ts
25:export const staticPlans: Plan[] = getAllPlans()...
# Défini mais jamais importé par d'autres fichiers
```

**cleanup-strasbourg.ts:**
```bash
$ rg "cleanup-strasbourg" package.json .replit
# Aucun résultat - script exécuté manuellement une fois
$ head -10 script/cleanup-strasbourg.ts
# Usage: npx tsx script/cleanup-strasbourg.ts --confirm
# Script de nettoyage one-shot pour données Strasbourg
```

**migrate-displayname.ts:**
```bash
$ rg "migrate-displayname" package.json .replit
# Aucun résultat - migration terminée
```

---

## CATÉGORIE D - FICHIERS À RISQUE (INTERDICTION DE SUPPRESSION)

### Stripe/Paiements
```
server/stripe.ts
server/stripeClient.ts
server/stripeConnect.ts
```

### Authentification
```
client/src/contexts/AuthContext.tsx
client/src/lib/storage.ts
server/routes.ts (sessions platform)
```

### Email
```
server/services/mailer/*
server/services/saasEmailService.ts
```

### Webhooks
```
server/stripe.ts (webhook handler)
server/routes.ts (/api/stripe/webhook, /api/internal/cron/*)
```

### Base de données
```
server/storage.ts
server/db.ts
shared/schema.ts
drizzle.config.ts
```

### Infrastructure
```
.replit
package.json
tsconfig.json
vite.config.ts
```

---

## Scripts de développement (à conserver)

Ces scripts ne sont pas orphelins mais des utilitaires de développement exécutés manuellement:

| Script | Usage |
|--------|-------|
| `scripts/seed-sandbox-portbouet.ts` | Seed data sandbox |
| `scripts/seed-unsalidl-sections.ts` | Seed sections UNSA Lidl |
| `scripts/qa-comprehensive-test.ts` | Tests QA |
| `scripts/qa-mobile-display-test.ts` | Tests mobile |
| `scripts/check-subscription-status.ts` | Vérification status |
| `scripts/build-koomy-admin.mjs` | Build admin app |
| `scripts/build-koomy-members.mjs` | Build members app |
| `scripts/build-unsa-lidl.mjs` | Build white-label |
| `scripts/sync-api-config.mjs` | Sync config API |

---

## Dossiers à ignorer (générés/cache)

```
node_modules/          - Dépendances npm
dist/                  - Build output
.cache/                - Cache TypeScript
artifacts/             - Builds mobile générés
android/               - Généré par Capacitor
ios/                   - Généré par Capacitor
attached_assets/       - Assets utilisateur (screenshots, docs)
```

---

## PLAN DE NETTOYAGE PROPOSÉ

### Phase 1 - Archivage (recommandé)
```bash
mkdir -p archive/scripts-oneshot archive/components-unused

# Scripts one-shot terminés
mv script/cleanup-strasbourg.ts archive/scripts-oneshot/
mv scripts/migrate-displayname.ts archive/scripts-oneshot/

# Composants non utilisés
mv client/src/components/ui/spinner.tsx archive/components-unused/
mv client/src/data/staticPlans.ts archive/components-unused/
```

### Phase 2 - Nettoyage dossiers vides
```bash
# Vérifier si infra/ est utilisé avant suppression
# Actuellement: 2 README.md placeholders
# Action: GARDER pour structure future
```

---

## VALIDATION REQUISE

❌ **AUCUNE ACTION EFFECTUÉE**  
❌ **AUCUN FICHIER SUPPRIMÉ**  
❌ **AUCUN COMMIT**

Ce rapport est un inventaire uniquement.  
Validation humaine requise avant toute modification.

---

## Commandes de vérification utilisées

```bash
# Recherche imports
rg -l "pattern" path/

# Liste fichiers
find . -type f -name "*.ts" ! -path "./node_modules/*"

# Vérification package.json
rg "script-name" package.json .replit
```
