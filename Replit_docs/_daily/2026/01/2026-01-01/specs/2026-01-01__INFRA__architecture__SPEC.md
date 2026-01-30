# Koomy - Architecture Monorepo

## Vue d'ensemble

Koomy est une plateforme SaaS multi-tenant pour la gestion de communautés (syndicats, clubs, associations). 
L'architecture est organisée en monorepo structuré pour supporter :
- Applications web multiples (plateforme, back-office, apps membre/admin)
- Applications mobiles natives (Android/iOS via Capacitor)
- Clients white-label avec branding personnalisé

## Structure du projet

```
koomy/
├── apps/
│   ├── api/                        # Backend API (Express / REST)
│   │
│   ├── web/
│   │   ├── platform-admin/         # SaaS Owner Dashboard
│   │   ├── backoffice/             # Back-office communautés
│   │   ├── website/                # Site commercial Koomy
│   │   ├── app-member/             # UI Web App Membre (Vite/React)
│   │   └── app-admin/              # UI Web App Admin (Koomy Pro)
│   │
│   └── mobile-shells/
│       ├── member/                 # Template Capacitor app membre
│       ├── admin/                  # Template Capacitor app admin
│       └── tenants/
│           └── unsa-lidl/          # Overrides Capacitor UNSA Lidl
│
├── packages/
│   ├── shared-schema/              # Schémas DB & types Drizzle
│   ├── api-client/                 # SDK API partagé
│   ├── ui-kit/                     # Design system commun
│   └── mobile-build/               # CLI unique de build natif
│       ├── index.mjs               # Point d'entrée principal
│       ├── load-tenant.mjs         # Chargeur TypeScript via tsx
│       ├── schema.mjs              # Schémas Zod + DEFAULT_FEATURES
│       ├── validate-assets.mjs     # Validation icon/splash
│       └── generate-capacitor-config.mjs  # Génération dynamique
│
├── assets/
│   ├── koomy/
│   │   ├── member/                 # Icône, splash app membre
│   │   └── admin/                  # Icône, splash Koomy Pro
│   └── tenants/
│       └── unsa-lidl/              # Assets UNSA Lidl
│           ├── icon.png            # 1024x1024 obligatoire
│           ├── splash.png          # Optionnel (2732x2732 recommandé)
│           └── logo.png            # Optionnel
│
├── tenants/
│   └── unsa-lidl/
│       ├── config.ts               # Config fonctionnelle (validée Zod)
│       ├── theme.ts                # Couleurs / branding
│       └── features.ts             # Feature flags
│
├── artifacts/                      # GENERATED – GITIGNORE
│   └── mobile/
│       ├── KoomyMemberApp/
│       ├── KoomyAdminApp/
│       └── UnsaLidlApp/
│
├── infra/
│   ├── env/                        # Conventions variables
│   └── deploy/                     # Docs Replit / Vercel / Stores
│
└── docs/
    └── architecture.md             # Ce fichier
```

## Phase 1 : Sécurisation technique (Déc 2024)

### 1. Validation des assets (obligatoire)

| Asset | Requis | Dimensions | Format |
|-------|:------:|------------|--------|
| icon.png | ✅ OUI | 1024x1024 exactement | PNG |
| splash.png | ❌ NON | 2732x2732 recommandé | PNG |
| logo.png | ❌ NON | Libre | PNG |

Le build **échoue** si :
- `icon.png` est absent
- `icon.png` n'est pas 1024x1024
- Format non-PNG/JPG

### 2. Validation schema Zod (config.ts)

Toutes les configs tenant sont validées au chargement via Zod :

```typescript
// Champs obligatoires dans tenants/{id}/config.ts
{
  tenant: string,           // "client-id"
  communityId: string,      // UUID
  brandName: string,        // "Client Name"
  apiBaseUrl: string,       // URL de l'API
  app: {
    bundleId: string,       // "app.koomy.clientid" (format valide)
    appName: string,        // "Client Name"
    scheme?: string,        // "clientid" (optionnel)
  },
  version: {
    name: string,           // "1.0.0" (semver)
    code: number,           // 1 (entier positif)
  },
}
```

Le build **échoue** avec messages d'erreur détaillés si un champ est manquant ou invalide.

### 3. Capacitor config dynamique

Les fichiers `apps/mobile-shells/**/capacitor.config.ts` sont des **templates**.

Le CLI génère dynamiquement dans `artifacts/mobile/{App}/` :
- `capacitor.config.ts` - avec appId, appName injectés
- `version.json` - métadonnées de version
- `package.json` - pour npm install

**Aucune config hardcodée n'est utilisée pour le build final.**

### 4. Features avec défauts explicites

```typescript
// DEFAULT_FEATURES (packages/mobile-build/schema.mjs)
{
  news: true,
  events: true,
  directory: true,
  documents: true,
  chat: true,
  collections: true,
  tickets: true,
  polls: true,
  marketplace: false,
  camera: false,
  pushNotifications: true,
  showPoweredByKoomy: true,
}
```

Les features du tenant sont **mergées** avec les défauts :
```typescript
const finalFeatures = { ...DEFAULT_FEATURES, ...tenantFeatures };
```

Aucune feature n'est `undefined`.

## Commandes CLI mobile-build v2.0

```bash
# Aide
node packages/mobile-build/index.mjs help

# Lister les tenants
node packages/mobile-build/index.mjs list

# Build app membre Koomy
node packages/mobile-build/index.mjs member

# Build app admin Koomy Pro
node packages/mobile-build/index.mjs admin

# Build white-label
node packages/mobile-build/index.mjs tenant unsa-lidl

# Build tous les tenants
node packages/mobile-build/index.mjs tenant --all
```

### Modes de build

| Option | Description |
|--------|-------------|
| `--prepare-only` | Build web + génère artifacts, **sans** Capacitor |
| `--with-native` | Build complet incluant `cap add` + `cap sync` |
| `--skip-web-build` | Utilise le `dist/` existant |
| `--platform <p>` | android, ios, ou all (défaut: all) |
| `--require-splash` | Rend splash.png obligatoire |

### Exemples

```bash
# Préparation rapide (CI/test)
node packages/mobile-build/index.mjs tenant unsa-lidl --prepare-only

# Build natif complet (local)
node packages/mobile-build/index.mjs admin --with-native --platform android

# Rebuild rapide après changement web
node packages/mobile-build/index.mjs member --skip-web-build
```

### Output généré

```
artifacts/mobile/{AppName}/
├── dist/                   # Assets web bundlés
├── capacitor.config.ts     # Config générée dynamiquement
├── version.json            # Métadonnées version
├── package.json            # Pour npm install + scripts Capacitor
├── build-manifest.json     # Infos de build
├── icon.png                # Icône copiée
├── logo.png                # Logo copié (si présent)
└── splash.png              # Splash copié (si présent)
```

## Ajout d'un nouveau client white-label

### Étape 1 : Créer les configs

```bash
mkdir -p tenants/{client}
```

Créer `tenants/{client}/config.ts` :

```typescript
export const tenantConfig = {
  tenant: "client-id",
  communityId: "00000000-0000-0000-0000-000000000000", // UUID réel
  brandName: "Client Name",
  baseUrl: "https://client.koomy.app",
  apiBaseUrl: "https://koomy-saas-plateforme-lamine7.replit.app",
  isWhiteLabel: true,
  
  app: {
    bundleId: "app.koomy.clientid",
    appName: "Client Name",
    scheme: "clientid",
  },
  
  version: {
    name: "1.0.0",
    code: 1,
  },
};

export type TenantConfig = typeof tenantConfig;
```

Créer `tenants/{client}/theme.ts` :

```typescript
export const tenantTheme = {
  primaryColor: "#HEX",
  primaryColorDark: "#HEX",
  secondaryColor: "#HEX",
  backgroundColor: "#FFFFFF",
  textColor: "#1F2937",
};

export type TenantTheme = typeof tenantTheme;
```

Créer `tenants/{client}/features.ts` :

```typescript
export const tenantFeatures = {
  // Override des defaults (tout le reste reste à true/false par défaut)
  marketplace: false,
  showPoweredByKoomy: true,
};

export type TenantFeatures = typeof tenantFeatures;
```

### Étape 2 : Ajouter les assets

```bash
mkdir -p assets/tenants/{client}
# Ajouter icon.png (1024x1024 PNG obligatoire)
# Optionnel: logo.png, splash.png
```

### Étape 3 : Builder

```bash
# Validation + build web + préparation
node packages/mobile-build/index.mjs tenant {client} --prepare-only

# Ou build complet avec Capacitor
node packages/mobile-build/index.mjs tenant {client} --with-native
```

## Règles techniques

### Builds mobiles

| Règle | Description |
|-------|-------------|
| ❌ Pas de `android/` ou `ios/` versionné | Générés à la demande |
| ✅ UI dans `client/src/` | Code React partagé (monolithique) |
| ✅ `mobile-shells/` = templates | Capacitor config de référence |
| ✅ `tenants/` = configs TypeScript | Validées par Zod |
| ✅ Artifacts dans `artifacts/` | Gitignored, régénérés à chaque build |

### Erreurs explicites

Le CLI échoue avec messages clairs pour :
- Assets manquants ou invalides
- Config tenant incomplète
- Version manquante
- BundleId mal formaté

## Applications

### Mobile

| App | Bundle ID | Description |
|-----|-----------|-------------|
| Koomy Member | `app.koomy.members` | App membre native |
| Koomy Pro | `app.koomy.admin` | App admin native (caméra QR) |
| UNSA Lidl | `app.koomy.unsalidl` | White-label UNSA Lidl |

## Permissions mobiles

| Permission | Member | Admin | White-label |
|------------|:------:|:-----:|:-----------:|
| Push Notifications | ✅ | ✅ | ✅ |
| Photo Library | ✅ | ✅ | ✅ |
| Vibration | ✅ | ✅ | ✅ |
| Camera | ❌ | ✅ | ❌ |

## Stack technique

- **Frontend**: React 19, TypeScript, Vite, Tailwind CSS, shadcn/ui
- **Backend**: Node.js, Express, Drizzle ORM
- **Database**: PostgreSQL (Neon)
- **Mobile**: Capacitor (Android + iOS)
- **Routing**: Wouter
- **State**: TanStack React Query
- **i18n**: react-i18next (FR/EN)
- **Validation**: Zod (configs tenant)
- **Assets**: image-size (validation dimensions)

---

*Dernière mise à jour: Janvier 2026 - Membership Plans V2, Events V2*
