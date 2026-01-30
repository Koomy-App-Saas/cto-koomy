# Rapport: Env Contract (API/CDN) - Toutes Apps + Owner Platform

**Date:** 22 janvier 2026  
**Version:** 1.0  
**Objectif:** Cohérence sandbox/prod sur toutes les surfaces avec fail-fast EnvGuard

---

## 1. Résumé des Changements

### 1.1 Surfaces Impactées

| Surface | Fichiers modifiés | Type de changement |
|---------|-------------------|-------------------|
| **Member App** | `api/config.ts`, `cdnResolver.ts` | Résolution environment-aware |
| **Admin App** | `api/config.ts`, `cdnResolver.ts` | Résolution environment-aware |
| **Backoffice** | `envGuard.ts` | Fail-fast mismatch detection |
| **Site Public** | `appModeResolver.ts` | Hostname detection |
| **Owner Platform** | `pages/owner/*`, `App.tsx` | Nouvelle surface ajoutée |

### 1.2 Fichiers Créés

| Fichier | Description |
|---------|-------------|
| `client/src/pages/owner/Login.tsx` | Page de connexion Owner Platform |
| `client/src/pages/owner/Dashboard.tsx` | Dashboard minimal avec env info |

### 1.3 Fichiers Modifiés

| Fichier | Changements |
|---------|-------------|
| `client/src/lib/appModeResolver.ts` | Ajout mode OWNER + hostnames owner.koomy.app / owner-sandbox.koomy.app |
| `client/src/lib/envGuard.ts` | Fallback environment-aware, check prod→sandbox API, log amélioré |
| `client/src/lib/cdnResolver.ts` | Suppression fallback hardcodé, utilisation environment-aware |
| `client/src/api/config.ts` | Résolution API environment-aware, plus de fallback prod uniquement |
| `client/src/App.tsx` | Ajout routes /owner/* et import composants Owner |

---

## 2. Variables d'Environnement par Environnement

### 2.1 Sandbox

| Variable | Valeur |
|----------|--------|
| `VITE_API_BASE_URL` | `https://api-sandbox.koomy.app` |
| `VITE_CDN_BASE_URL` | `https://cdn-sandbox.koomy.app` |
| `KOOMY_ENV` (backend) | `sandbox` |
| `APP_ENV` (backend) | `sandbox` |

### 2.2 Production

| Variable | Valeur |
|----------|--------|
| `VITE_API_BASE_URL` | `https://api.koomy.app` |
| `VITE_CDN_BASE_URL` | `https://cdn.koomy.app` |
| `KOOMY_ENV` (backend) | `production` |
| `APP_ENV` (backend) | `prod` |

### 2.3 Fallback Automatique (sans env vars)

| Hostname | API Fallback | CDN Fallback |
|----------|--------------|--------------|
| `*-sandbox.koomy.app` | api-sandbox.koomy.app | cdn-sandbox.koomy.app |
| `sandbox.koomy.app` | api-sandbox.koomy.app | cdn-sandbox.koomy.app |
| `demo-*.koomy.app` | api-sandbox.koomy.app | cdn-sandbox.koomy.app |
| `*.koomy.app` (autres) | api.koomy.app | cdn.koomy.app |
| `koomy.app` | api.koomy.app | cdn.koomy.app |

---

## 3. Comportement EnvGuard (Fail-Fast)

### 3.1 Conditions de Blocage

| Hostname | API | CDN | Résultat |
|----------|-----|-----|----------|
| `*-sandbox.koomy.app` | api.koomy.app | - | ❌ BLOQUÉ |
| `*-sandbox.koomy.app` | - | cdn.koomy.app | ❌ BLOQUÉ |
| `backoffice.koomy.app` | api-sandbox.koomy.app | - | ❌ BLOQUÉ |
| `backoffice.koomy.app` | - | cdn-sandbox.koomy.app | ❌ BLOQUÉ |
| `*-sandbox.koomy.app` | api-sandbox.koomy.app | cdn-sandbox.koomy.app | ✅ OK |
| `backoffice.koomy.app` | api.koomy.app | cdn.koomy.app | ✅ OK |

### 3.2 Log de Boot Standard

Chaque app affiche au démarrage:

```
╔══════════════════════════════════════════════════════════════╗
║                    ENV GUARD DIAGNOSTICS                      ║
╠══════════════════════════════════════════════════════════════╣
║ Hostname:       sandbox.koomy.app                            ║
║ Is Sandbox:     true                                         ║
║ API Base URL:   https://api-sandbox.koomy.app                ║
║ CDN Base URL:   https://cdn-sandbox.koomy.app                ║
║ Mismatch:       false                                        ║
╚══════════════════════════════════════════════════════════════╝
```

---

## 4. Owner Platform

### 4.1 Hostnames

| Environnement | Hostname |
|---------------|----------|
| Production | `owner.koomy.app` |
| Sandbox | `owner-sandbox.koomy.app` |

### 4.2 Routes

| Route | Composant | Description |
|-------|-----------|-------------|
| `/owner/login` | `OwnerLogin` | Page de connexion |
| `/owner` | `OwnerDashboard` | Dashboard minimal |

### 4.3 Fonctionnalités (Scaffold)

- Affichage de l'environnement (sandbox/production)
- Affichage des URLs API et CDN effectives
- Indicateur de configuration (explicite vs fallback)
- Placeholder pour futures fonctionnalités

### 4.4 Sécurité (TODO)

- [ ] Guard role "owner" (à implémenter)
- [ ] Authentification Firebase ou custom
- [ ] Audit logs des accès

---

## 5. Tests Manuels à Exécuter

### 5.1 Test Sandbox (backoffice-sandbox.koomy.app)

1. Accéder à `https://backoffice-sandbox.koomy.app`
2. Ouvrir la console développeur
3. Vérifier:
   - [ ] `[EnvGuard] ✓ Environment check passed`
   - [ ] `API Base URL: https://api-sandbox.koomy.app`
   - [ ] `CDN Base URL: https://cdn-sandbox.koomy.app`
   - [ ] Bandeau "SANDBOX" visible

### 5.2 Test Production (backoffice.koomy.app)

1. Accéder à `https://backoffice.koomy.app`
2. Ouvrir la console développeur
3. Vérifier:
   - [ ] `[EnvGuard] ✓ Environment check passed`
   - [ ] `API Base URL: https://api.koomy.app`
   - [ ] `CDN Base URL: https://cdn.koomy.app`
   - [ ] Pas de bandeau "SANDBOX"

### 5.3 Test Owner Platform

1. Accéder à `https://owner-sandbox.koomy.app`
2. Vérifier:
   - [ ] Page de login Owner affichée
   - [ ] Bandeau "SANDBOX ENVIRONMENT"
   - [ ] Info environnement visible (API, CDN, Mode)

### 5.4 Test Mismatch (simulation)

Avec variables incorrectes (dev seulement):

```env
VITE_API_BASE_URL=https://api.koomy.app  # PROD
```

Sur `sandbox.koomy.app`:
- [ ] `[EnvGuard] Environment mismatch: ...`
- [ ] Erreur visible dans la console

---

## 6. Points de Vigilance

### 6.1 Firebase Domains

Les domaines suivants doivent être autorisés dans Firebase Console:

**Sandbox:**
- `sandbox.koomy.app`
- `backoffice-sandbox.koomy.app`
- `club-mobile-sandbox.koomy.app`
- `sitepublic-sandbox.koomy.app`
- `saasowner-sandbox.koomy.app`
- `owner-sandbox.koomy.app`

**Production:**
- `app.koomy.app`
- `backoffice.koomy.app`
- `app-pro.koomy.app`
- `koomy.app`
- `lorpesikoomyadmin.koomy.app`
- `owner.koomy.app`

### 6.2 Cloudflare Pages (_redirects)

Vérifier que les scripts de build (`scripts/pages-redirects.mjs`) utilisent l'API appropriée selon l'environnement:

```
# Sandbox build
/api/* https://api-sandbox.koomy.app/api/:splat 200

# Production build
/api/* https://api.koomy.app/api/:splat 200
```

### 6.3 Hardcodes Restants (Acceptables)

| Fichier | Hardcode | Raison |
|---------|----------|--------|
| `server/services/mailer/branding.ts` | `api.koomy.app` | Fallback emails (backend contrôlé) |
| `server/routes.ts` | `cdn.koomy.app` | Whitelist CORS (sécurité) |
| `tenants/*/wl.json` | `api.koomy.app` | Config tenant prod uniquement |

---

## 7. Checklist Definition of Done

- [x] Toutes les surfaces sandbox utilisent cdn-sandbox + api-sandbox
- [x] EnvGuard bloque tout mismatch (API ou CDN)
- [x] Résolution environment-aware (hostname → fallback approprié)
- [x] Owner Platform détectable via host (owner.koomy.app / owner-sandbox.koomy.app)
- [x] Owner Platform affiche dashboard minimal avec env info
- [x] Routes /owner/login et /owner ajoutées
- [x] AppModeResolver inclut mode OWNER
- [x] Log de boot standard dans console
- [x] Rapport livré

---

*Document généré le 22 janvier 2026*
