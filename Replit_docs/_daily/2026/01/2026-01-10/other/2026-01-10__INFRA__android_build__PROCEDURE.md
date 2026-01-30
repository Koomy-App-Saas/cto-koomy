# Guide de Build Android - Koomy Mobile App

Ce guide explique comment compiler et publier l'application mobile Koomy pour Android.

## Prérequis

### Sur votre machine locale

| Outil | Version | Téléchargement |
|-------|---------|----------------|
| **Android Studio** | Hedgehog (2023.1.1) ou plus récent | [developer.android.com](https://developer.android.com/studio) |
| **Java JDK** | 17 ou plus récent | Inclus dans Android Studio |
| **Node.js** | 18 ou plus récent | [nodejs.org](https://nodejs.org) |

### Configuration Android Studio

1. Ouvrir Android Studio
2. Aller dans **Tools** → **SDK Manager**
3. Installer :
   - Android SDK Platform 34 (Android 14)
   - Android SDK Build-Tools 34.0.0
   - Android SDK Command-line Tools

---

## Structure du Projet

```
/android                     # Projet Android Studio
  /app
    /src/main
      /assets/public        # Build web (généré par Capacitor)
      /java/.../MainActivity.java
      /res                  # Ressources (icônes, couleurs, styles)
      AndroidManifest.xml   # Permissions et configuration
  build.gradle
  
/capacitor.config.ts        # Configuration Capacitor
/dist/public               # Build web source
```

---

## Commandes de Build

### 1. Préparer le build web

```bash
npm run build
```

Cette commande génère les fichiers web dans `dist/public`.

### 2. Synchroniser avec Android

```bash
npx cap sync android
```

Cette commande :
- Copie `dist/public` vers `android/app/src/main/assets/public`
- Met à jour `capacitor.config.json` dans le projet Android
- Installe/met à jour les plugins natifs

### 3. Ouvrir dans Android Studio

```bash
npx cap open android
```

Ou manuellement : ouvrir le dossier `android/` dans Android Studio.

---

## Développement

### Live Reload (optionnel)

Pour tester les modifications en temps réel sur un appareil :

1. Modifier `capacitor.config.ts` :

```typescript
server: {
  url: 'http://VOTRE_IP_LOCALE:5000',
  cleartext: true,
}
```

2. Lancer le serveur de développement :

```bash
npm run dev
```

3. Reconstruire et déployer :

```bash
npx cap copy android
```

4. Lancer depuis Android Studio

**Note** : Remettre la configuration normale avant le build de production.

---

## Build de Production

### Générer l'APK (debug)

Dans Android Studio :
1. **Build** → **Build Bundle(s) / APK(s)** → **Build APK(s)**
2. L'APK se trouve dans :
   ```
   android/app/build/outputs/apk/debug/app-debug.apk
   ```

### Générer l'AAB (release - Play Store)

1. Créer une clé de signature :

```bash
keytool -genkey -v -keystore koomy-release.keystore \
  -alias koomy -keyalg RSA -keysize 2048 -validity 10000
```

2. Configurer `android/app/build.gradle` avec les informations de signature

3. Dans Android Studio :
   - **Build** → **Generate Signed Bundle / APK**
   - Sélectionner **Android App Bundle**
   - Choisir le keystore et entrer les mots de passe
   - Sélectionner **release** comme variante

4. L'AAB se trouve dans :
   ```
   android/app/build/outputs/bundle/release/app-release.aab
   ```

---

## Configuration de l'Application

### Identité de l'application

| Paramètre | Valeur | Fichier |
|-----------|--------|---------|
| App ID | `app.koomy.mobile` | `capacitor.config.ts` |
| Nom affiché | Koomy | `android/app/src/main/res/values/strings.xml` |
| Version | 1.0.0 | `android/app/build.gradle` |

### Permissions Android

L'application demande les permissions suivantes :

| Permission | Usage |
|------------|-------|
| INTERNET | Connexion API backend |
| CAMERA | Scanner QR codes |
| VIBRATE | Retour haptique |
| READ_MEDIA_IMAGES | Sélection photos profil |

### Icône et Splash Screen

**Icône** : Remplacer les fichiers dans :
- `android/app/src/main/res/mipmap-mdpi/ic_launcher.png` (48x48)
- `android/app/src/main/res/mipmap-hdpi/ic_launcher.png` (72x72)
- `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png` (96x96)
- `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png` (144x144)
- `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` (192x192)

**Splash Screen** : Couleur configurée dans `capacitor.config.ts` → `#44A8FF`

---

## Publication sur Google Play Store

### 1. Préparer les assets

- Icône haute résolution (512x512 PNG)
- Captures d'écran (min. 2, recommandé 8)
- Vidéo promotionnelle (optionnel)
- Description courte (80 caractères max)
- Description complète (4000 caractères max)

### 2. Créer un compte développeur

1. Aller sur [play.google.com/console](https://play.google.com/console)
2. Payer les frais d'inscription (25€ une fois)
3. Compléter les informations du développeur

### 3. Créer l'application

1. **Créer une application** → Remplir les informations
2. Uploader l'AAB signé
3. Remplir les questionnaires (contenu, classification, prix)
4. Soumettre pour révision

---

## Workflow de mise à jour

À chaque nouvelle version :

```bash
# 1. Mettre à jour le code React
git pull

# 2. Reconstruire le build web
npm run build

# 3. Synchroniser avec Android
npx cap sync android

# 4. Mettre à jour la version dans build.gradle
# versionCode = +1, versionName = nouvelle version

# 5. Générer le nouvel AAB signé

# 6. Uploader sur Play Store
```

---

## Dépannage

### L'application affiche une page blanche

1. Vérifier que `dist/public` existe et contient `index.html`
2. Exécuter `npx cap sync android`
3. Nettoyer le build : **Build** → **Clean Project**

### Erreur "SDK location not found"

Créer `android/local.properties` :
```
sdk.dir=/Users/VOTRE_USER/Library/Android/sdk
```

### Erreur Gradle

1. **File** → **Invalidate Caches / Restart**
2. Supprimer `android/.gradle` et réessayer

### L'API ne répond pas

Vérifier que l'URL de l'API est correcte :
- Production : Utiliser l'URL publique de l'API
- Développement : Utiliser l'IP locale avec `cleartext: true`

---

## Configuration White Label

Pour les Grands Comptes avec leur propre branding :

1. Modifier `capacitor.config.ts` :
```typescript
appId: 'app.CLIENT.mobile',
appName: 'NomClient',
plugins: {
  SplashScreen: {
    backgroundColor: '#COULEUR_CLIENT',
  }
}
```

2. Remplacer les icônes avec le branding client

3. Générer un APK/AAB séparé

---

*Guide créé le 21 décembre 2024*
