# BUILD PROOF - UNSA Lidl Android v1.5.1 (6)

**Date**: 2026-01-01  
**Commit**: 08a728c  
**Tenant**: unsa-lidl  
**Bundle ID**: app.koomy.unsalidl

---

## 1. Preuve de version - Gradle (build.gradle)

```gradle
// artifacts/mobile/UNSALidlApp/android/app/build.gradle

android {
    namespace "app.koomy.unsalidl"
    compileSdk rootProject.ext.compileSdkVersion
    defaultConfig {
        applicationId "app.koomy.unsalidl"
        minSdkVersion rootProject.ext.minSdkVersion
        targetSdkVersion rootProject.ext.targetSdkVersion
        versionCode 6                    // ✅ CONFIRMÉ
        versionName "1.5.1"              // ✅ CONFIRMÉ
        ...
    }
}
```

---

## 2. Preuve de version - Config Tenant

```typescript
// tenants/unsa-lidl/config.ts

export const tenantConfig = {
  tenant: "unsa-lidl",
  brandName: "UNSA Lidl",
  version: {
    name: "1.5.1",    // ✅ CONFIRMÉ
    code: 6,          // ✅ CONFIRMÉ
  },
  ...
};
```

---

## 3. Preuve de version - version.json

```json
// artifacts/mobile/UNSALidlApp/version.json

{
  "appId": "app.koomy.unsalidl",
  "appName": "UNSA Lidl",
  "versionName": "1.5.1",    // ✅ CONFIRMÉ
  "versionCode": 6,          // ✅ CONFIRMÉ
  "isWhiteLabel": true,
  "generatedAt": "2026-01-01T23:34:23.187Z"
}
```

---

## 4. Correctifs inclus dans ce build

| Correctif | Status | Fichier(s) |
|-----------|--------|------------|
| Stockage hybride (Preferences natif / localStorage web) | ✅ Inclus | `client/src/lib/storage.ts` |
| AuthContext hydratation async + authReady | ✅ Inclus | `client/src/contexts/AuthContext.tsx` |
| Auth guard attend authReady avant redirect | ✅ Inclus | `client/src/components/WhiteLabelMemberApp.tsx` |
| Endpoint GET /api/accounts/me (auth required) | ✅ Inclus | `server/routes.ts` |
| Diagnostics (7 taps) version + auth state + Verify /me | ✅ Inclus | `client/src/components/DiagnosticScreen.tsx` |
| Suppression délai 500ms (flow déterministe) | ✅ Inclus | `client/src/pages/mobile/WhiteLabelLogin.tsx` |
| Token serveur (plus de fabrication client) | ✅ Inclus | `server/routes.ts`, `WhiteLabelLogin.tsx` |

---

## 5. Instructions de build (à exécuter localement)

### Prérequis
- Android Studio avec SDK 34+
- Java 17+
- Node.js 18+

### Étapes

```bash
# 1. Depuis la racine du projet
cd artifacts/mobile/UNSALidlApp

# 2. Synchroniser Capacitor (OBLIGATOIRE)
npx cap sync android

# 3. Build
cd android
./gradlew clean
./gradlew assembleDebug      # APK debug
./gradlew bundleRelease      # AAB release (store)
```

### Localisation des artefacts générés

| Type | Chemin |
|------|--------|
| APK Debug | `android/app/build/outputs/apk/debug/app-debug.apk` |
| AAB Release | `android/app/build/outputs/bundle/release/app-release.aab` |

### Renommer les artefacts

```bash
# Après le build, copier et renommer:
cp android/app/build/outputs/apk/debug/app-debug.apk \
   releases/UNSALidlApp-1.5.1\(6\)-debug.apk

cp android/app/build/outputs/bundle/release/app-release.aab \
   releases/UNSALidlApp-1.5.1\(6\)-release.aab
```

---

## 6. Vérification post-build (aapt dump)

```bash
# Vérifier la version dans l'APK généré:
$ANDROID_SDK_ROOT/build-tools/34.0.0/aapt dump badging app-debug.apk | grep version

# Résultat attendu:
# versionCode='6' versionName='1.5.1'
```

---

## 7. Endpoints API inclus

| Endpoint | Méthode | Auth | Description |
|----------|---------|------|-------------|
| `/api/health` | GET | Non | Vérification connectivité |
| `/api/accounts/me` | GET | Bearer token | Vérification session |
| `/api/accounts/login` | POST | Non | Login + token serveur |
| `/api/white-label/config` | GET | Non | Config white-label |

---

## 8. Checklist finale

- [x] versionCode = 6 dans build.gradle
- [x] versionName = "1.5.1" dans build.gradle
- [x] Config tenant mise à jour (tenants/unsa-lidl/config.ts)
- [x] wl.json mis à jour avec version
- [x] Capacitor sync exécuté
- [x] Correctifs auth persistence inclus
- [x] Diagnostics 7-tap fonctionnels
- [x] Endpoint /api/accounts/me opérationnel
- [x] Token serveur (pas de fabrication client)
- [ ] Build APK debug (à faire localement)
- [ ] Build AAB release (à faire localement)
- [ ] Vérification aapt dump (à faire après build)
