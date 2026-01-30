# AUTH_ANDROID_404_REPORT.md

## Rapport de Validation - Correction 404 Login Android

**Date:** 2026-01-01  
**Version:** 1.3.4 (build code 8)  
**Tenant:** UNSA Lidl

---

## Cause Racine

Le problème de 404 lors du login sur Android avait **deux causes principales** :

### 1. URL API figée au load-time (CRITIQUE)

```typescript
// AVANT (BROKEN)
const API_BASE_URL = getApiBaseUrl(); // Évalué une seule fois au démarrage
const url = `${API_BASE_URL}${path}`;  // Utilise une valeur potentiellement vide

// APRES (FIXED)
const baseUrl = getApiBaseUrl();  // Appelé dynamiquement à chaque requête
await ensureApiConfigLoaded();    // Guard qui attend le chargement de wl.json
const url = buildUrl(baseUrl, path); // Construction normalisée sans double-slash
```

### 2. Absence de guard pour wl.json

Sur Android natif, `wl.json` est chargé de façon asynchrone depuis les assets embarqués. Sans guard, les requêtes API partaient **avant** que `wl.json` soit chargé, résultant en une URL incorrecte ou vide.

---

## Corrections Implémentées

### A) `client/src/api/config.ts`

- `ensureApiConfigLoaded()` : Guard async qui attend le chargement complet de wl.json
- `isApiConfigReady()` : Check synchrone pour savoir si la config est prête
- `buildUrl()` : Construction d'URL robuste avec normalisation des slashes
- `getDiagnostics()` / `updateDiagnostics()` : Tracking de l'état pour debug

### B) `client/src/api/httpClient.ts`

- Appel automatique de `ensureApiConfigLoaded()` avant toute requête native
- Logging détaillé : platform, baseUrl, fullUrl, status, erreurs
- `testHealthEndpoint()` : Fonction de test du serveur

### C) `server/routes.ts`

- `GET /api/health` : Endpoint de diagnostic (status, uptime, version)
- 404 handler avec logging détaillé (method, path, IP, user-agent, headers)

### D) `client/src/components/DiagnosticScreen.tsx`

- Écran de diagnostics caché (tap 7x sur le logo)
- Affiche : platform, apiBaseUrl, wlJsonLoaded, lastRequest, healthCheck
- Permet de tester /api/health depuis l'app

### E) `client/src/pages/mobile/WhiteLabelLogin.tsx`

- Hook `useDiagnosticTrigger` pour activer les diagnostics
- `useEffect` qui appelle `ensureApiConfigLoaded()` au montage sur native

---

## URL Finale Utilisée

```
POST https://koomy-saas-plateforme-lamine7.replit.app/api/accounts/login
Content-Type: application/json

{
  "email": "...",
  "password": "..."
}
```

**Source:** `wl.json` embarqué dans les assets Android :
```json
{
  "tenant": "unsa-lidl",
  "apiBaseUrl": "https://koomy-saas-plateforme-lamine7.replit.app",
  "brandName": "UNSA Lidl",
  "communityId": "2b129b86-3a39-4d19-a6fc-3d0cec067a79"
}
```

---

## Checklist de Tests

| Test | Résultat | Notes |
|------|----------|-------|
| `/api/health` depuis web | ✅ PASS | `{"status":"ok","version":"1.3.2"}` |
| wl.json inclus dans build | ✅ PASS | Vérifié dans `artifacts/mobile/UNSALidlApp/public/wl.json` |
| Build v1.3.4 généré | ✅ PASS | Version code 8 |
| apiBaseUrl correct dans wl.json | ✅ PASS | `https://koomy-saas-plateforme-lamine7.replit.app` |
| Écran diagnostics accessible | ✅ PASS | 7 taps sur le logo |
| 404 handler logging | ✅ PASS | Logs détaillés sur routes non trouvées |

---

## Instructions de Build

```bash
# Télécharger le dossier artifacts/mobile/UNSALidlApp

# Build debug APK
cd android
./gradlew assembleDebug
# Output: android/app/build/outputs/apk/debug/app-debug.apk

# Build release AAB (pour Play Store)
./gradlew bundleRelease
# Output: android/app/build/outputs/bundle/release/app-release.aab
```

---

## Comment Utiliser l'Écran de Diagnostics

1. Ouvrir l'app sur Android
2. Sur l'écran de login, **taper 7 fois** sur le logo
3. L'écran de diagnostics s'affiche avec :
   - Platform info (Android, version)
   - API Configuration (wl.json loaded, apiBaseUrl)
   - Bouton "Test /api/health" pour vérifier la connexion serveur
   - Dernière requête (URL, status code, erreur)
   - Contenu brut de wl.json

---

## Compte de Test

- **Email:** mlaminesylla@yahoo.fr
- **Mot de passe:** Koomy2025!

---

## Résumé

✅ **Cause identifiée** : URL API évaluée avant le chargement de wl.json  
✅ **Correction implémentée** : Guard async + construction URL robuste  
✅ **Diagnostics ajoutés** : Health endpoint + écran debug + logging détaillé  
✅ **Build prêt** : v1.3.3 (code 7) dans `artifacts/mobile/UNSALidlApp`
