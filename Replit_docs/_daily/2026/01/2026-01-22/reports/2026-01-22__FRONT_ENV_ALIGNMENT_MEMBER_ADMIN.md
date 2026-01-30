# Front ENV Alignment - Member App + Admin App

**Date:** 2026-01-22  
**Statut:** ✅ TERMINÉ  
**Scope:** Frontend uniquement (Member App + Admin App)

---

## 1. Résumé Exécutif

Alignement des apps Member et Admin sur la logique ENV sandbox/production pour le CDN et l'API. Un nouveau module centralisé `cdnResolver.ts` gère toutes les résolutions d'URLs CDN. Un garde-fou bloquant (EnvGuard) empêche l'app de démarrer si une mauvaise configuration est détectée.

### Résultats Clés
- **Module CDN centralisé** : `client/src/lib/cdnResolver.ts`
- **EnvGuard bloquant** : Affiche une page d'erreur si mismatch
- **Composant d'erreur** : `EnvironmentMismatch.tsx`
- **Fallbacks supprimés** : config.ts simplifié

---

## 2. Changements Effectués

| Fichier | Description |
|---------|-------------|
| `client/src/lib/cdnResolver.ts` | **NOUVEAU** - Module centralisé pour résolution CDN |
| `client/src/lib/envGuard.ts` | Ajout `isSandboxEnvironment()`, `performBlockingEnvCheck()`, vérification prod→sandbox CDN |
| `client/src/components/EnvironmentMismatch.tsx` | **NOUVEAU** - Composant page d'erreur |
| `client/src/api/config.ts` | Utilise `cdnResolver`, suppression fallbacks hardcodés |
| `client/src/App.tsx` | Intégration du check bloquant au boot |

---

## 3. Résolution CDN (nouveau module)

### 3.1 Module `cdnResolver.ts`

```typescript
// Fonctions exportées
getCdnBaseUrl(): string                    // Retourne l'URL CDN effective
isCdnConfigured(): boolean                 // Vérifie si VITE_CDN_BASE_URL est défini
resolvePublicObjectUrl(path, ctx?): string // Résout un path vers URL CDN complète
logCdnBootDiagnostics(): void              // Log de diagnostic au boot
```

### 3.2 Logique de fallback (environnement-aware)

```
VITE_CDN_BASE_URL défini → utiliser cette valeur
VITE_CDN_BASE_URL non défini:
  - Si hostname contient "sandbox" → https://cdn-sandbox.koomy.app
  - Sinon → https://cdn.koomy.app
```

### 3.3 Formats supportés

| Input | Output |
|-------|--------|
| `/objects/public/news/x.jpg` | `https://cdn(-sandbox).koomy.app/public/news/x.jpg` |
| `/public/logos/y.png` | `https://cdn(-sandbox).koomy.app/public/logos/y.png` |
| `https://example.com/z.jpg` | `https://example.com/z.jpg` (inchangé) |
| `/src/assets/a.png` | `/src/assets/a.png` (inchangé - asset bundlé) |

---

## 4. EnvGuard Règles (sandbox/prod)

### 4.1 Détection environnement

Un hostname est considéré **sandbox** si:
- Contient "sandbox" ou "-sandbox."
- Contient "demo-" ou "-dev."

### 4.2 Règles de blocage

| Hostname | CDN | Résultat |
|----------|-----|----------|
| `*-sandbox.koomy.app` | `cdn.koomy.app` | ❌ BLOQUÉ |
| `*-sandbox.koomy.app` | `cdn-sandbox.koomy.app` | ✅ OK |
| `backoffice.koomy.app` | `cdn-sandbox.koomy.app` | ❌ BLOQUÉ |
| `backoffice.koomy.app` | `cdn.koomy.app` | ✅ OK |
| `*.replit.dev` | (fallback prod) | ✅ OK (dev mode) |

### 4.3 Comportement au boot

1. `performBlockingEnvCheck()` appelé au boot de l'app
2. Si mismatch détecté → `envMismatch` stocké
3. `App.tsx` vérifie `envMismatch` avant le rendu
4. Si mismatch → affiche `<EnvironmentMismatch />` au lieu de l'app

---

## 5. Comment Tester

### 5.1 Checklist Member App Sandbox

- [ ] Ouvrir `sandbox.koomy.app`
- [ ] Console: `[EnvGuard] Environment check passed`
- [ ] Console: `Effective CDN: https://cdn-sandbox.koomy.app`
- [ ] Charger une image → URL sur `cdn-sandbox`

### 5.2 Checklist Admin App Sandbox

- [ ] Ouvrir `backoffice-sandbox.koomy.app`
- [ ] Console: `[EnvGuard] Environment check passed`
- [ ] Console: `Effective CDN: https://cdn-sandbox.koomy.app`

### 5.3 Test mismatch (dev)

Pour simuler un mismatch en dev:
```javascript
// Dans la console navigateur
localStorage.setItem('__test_cdn_mismatch', 'true');
location.reload();
```

### 5.4 Non-régression prod

- [ ] Ouvrir `backoffice.koomy.app`
- [ ] Console: `[EnvGuard] Environment check passed`
- [ ] Effective CDN: `https://cdn.koomy.app`
- [ ] Si `cdn-sandbox` configuré en prod → page d'erreur affichée

---

## 6. Points de Vigilance

### 6.1 Localhost / Replit Dev

Le hostname `*.replit.dev` et `localhost` ne sont **pas** considérés comme sandbox par défaut. Le fallback sera `cdn.koomy.app`.

Pour tester sandbox en local, définir:
```env
VITE_CDN_BASE_URL=https://cdn-sandbox.koomy.app
```

### 6.2 White Label

Les apps white-label utilisent le même resolver. La config CDN doit être cohérente dans les fichiers de déploiement.

### 6.3 Apps Natives (Capacitor)

Les apps natives bundlées doivent avoir `VITE_CDN_BASE_URL` configuré au build time. Le fallback environnement-aware ne fonctionne que sur les hostnames web.

---

## 7. Variables d'Environnement

### 7.1 Variables Frontend

| Variable | Description | Exemple Sandbox | Exemple Prod |
|----------|-------------|-----------------|--------------|
| `VITE_API_BASE_URL` | URL base API | `https://api-sandbox.koomy.app` | `https://api.koomy.app` |
| `VITE_CDN_BASE_URL` | URL base CDN | `https://cdn-sandbox.koomy.app` | `https://cdn.koomy.app` |
| `VITE_APP_ENV` | (optionnel) | `sandbox` | `production` |

### 7.2 Fichier .env.sandbox

```env
VITE_API_BASE_URL=https://api-sandbox.koomy.app
VITE_CDN_BASE_URL=https://cdn-sandbox.koomy.app
VITE_APP_ENV=sandbox
```

### 7.3 Fichier .env.production

```env
VITE_API_BASE_URL=https://api.koomy.app
VITE_CDN_BASE_URL=https://cdn.koomy.app
VITE_APP_ENV=production
```

---

## 8. Definition of Done

| Critère | Statut |
|---------|--------|
| Member App: aucune référence hardcodée à `cdn.koomy.app` | ✅ |
| Admin App: idem | ✅ |
| Resolver unique utilisé partout | ✅ |
| EnvGuard bloque les mismatches | ✅ |
| Composant EnvironmentMismatch créé | ✅ |
| Rapport livré | ✅ |

---

## 9. Fichiers Créés/Modifiés

```
client/src/lib/cdnResolver.ts          # NOUVEAU
client/src/lib/envGuard.ts             # MODIFIÉ
client/src/components/EnvironmentMismatch.tsx  # NOUVEAU
client/src/api/config.ts               # MODIFIÉ
client/src/App.tsx                     # MODIFIÉ
```
