# Koomy Mobile - Guide de développement Capacitor

Ce document explique comment construire et déployer l'application mobile Koomy avec Capacitor.

## Prérequis

### Pour tous
- Node.js 18+ et npm
- Capacitor CLI installé (`npm install`)

### Pour Android
- **Android Studio** (dernière version)
- **Java 17 JDK** 
- **Android SDK** (API level 24+, ciblant Android 7.0+)
- Émulateur Android ou appareil physique

### Pour iOS
- **macOS** uniquement
- **Xcode 14+**
- **CocoaPods** : `sudo gem install cocoapods`
- Compte Apple Developer ($99/an pour publier)

---

## Structure du projet mobile

```
koomy/
├── capacitor.config.ts     # Configuration Capacitor
├── android/                # Projet Android natif
├── ios/                    # Projet iOS natif (si généré)
├── dist/public/            # Build web pour mobile
└── client/src/pages/mobile/  # Pages de l'app mobile
```

---

## Routes de l'application mobile

### App membre publique (`/app/*`)
- `/app/login` - Connexion membre
- `/app/hub` - Hub des communautés
- `/app/add-card` - Ajouter une carte
- `/app/:communityId/home` - Accueil communauté
- `/app/:communityId/card` - Carte membre
- `/app/:communityId/news` - Actualités
- `/app/:communityId/events` - Événements
- `/app/:communityId/messages` - Messages
- `/app/:communityId/profile` - Profil
- `/app/:communityId/payment` - Paiement
- `/app/:communityId/support` - Support

### App admin mobile (`/app/admin/*`)
- `/app/admin/login` - Connexion admin
- `/app/admin/register` - Inscription admin
- `/app/:communityId/admin` - Dashboard admin
- `/app/:communityId/admin/members` - Gestion membres
- `/app/:communityId/admin/articles` - Gestion articles
- `/app/:communityId/admin/events` - Gestion événements
- `/app/:communityId/admin/scanner` - Scanner QR

---

## Commandes de développement

### Build web
```bash
npm run build
```
Génère les fichiers dans `dist/public/`.

### Synchroniser avec Capacitor
```bash
npm run cap:sync
```
Copie le build web vers les projets natifs.

### Ouvrir Android Studio
```bash
npm run android
```

### Ouvrir Xcode (macOS uniquement)
```bash
npm run ios
```

### Build complet + Sync
```bash
npm run build:mobile
```

---

## Premier lancement Android

1. **Build le projet web** :
   ```bash
   npm run build
   ```

2. **Synchroniser Capacitor** :
   ```bash
   npx cap sync android
   ```

3. **Ouvrir dans Android Studio** :
   ```bash
   npx cap open android
   ```

4. **Dans Android Studio** :
   - Attendre que Gradle synchronise le projet
   - Sélectionner un émulateur ou appareil
   - Cliquer sur "Run" (▶️)

---

## Premier lancement iOS

1. **Build le projet web** :
   ```bash
   npm run build
   ```

2. **Synchroniser Capacitor** :
   ```bash
   npx cap sync ios
   ```

3. **Ouvrir dans Xcode** :
   ```bash
   npx cap open ios
   ```

4. **Dans Xcode** :
   - Configurer le "Signing & Capabilities" avec votre Team
   - Sélectionner un simulateur ou appareil
   - Cliquer sur "Run" (▶️)

---

## Configuration de l'API

L'app mobile utilise la même API que le web. Configurez l'URL de l'API via la variable d'environnement :

```bash
# .env ou environnement
VITE_API_URL=https://app.koomy.app/api
```

Pour le développement local :
```bash
VITE_API_URL=http://localhost:5000/api
```

---

## Génération des icônes et splash screens

### Structure des assets
```
resources/
├── icon.png          # 1024x1024 icône de l'app
├── splash.png        # 2732x2732 splash screen
└── icon-foreground.png  # Android adaptive icon
```

### Générer les assets
```bash
npx capacitor-assets generate
```

---

## Build de production

### Android APK
1. Ouvrir Android Studio
2. Build → Build Bundle(s) / APK(s) → Build APK(s)
3. APK dans `android/app/build/outputs/apk/release/`

### Android App Bundle (pour Play Store)
1. Build → Generate Signed Bundle / APK
2. Choisir "Android App Bundle"
3. Configurer ou créer un keystore
4. AAB dans `android/app/build/outputs/bundle/release/`

### iOS Archive
1. Ouvrir Xcode
2. Product → Archive
3. Uploader vers App Store Connect

---

## Publication

### Google Play Store
1. Créer un compte Google Play Developer (25$ une fois)
2. Console : https://play.google.com/console
3. Créer une application
4. Uploader l'AAB signé
5. Compléter les fiches (description, screenshots, politique de confidentialité)

### Apple App Store
1. Créer un compte Apple Developer ($99/an)
2. App Store Connect : https://appstoreconnect.apple.com
3. Créer une application
4. Uploader via Xcode (Product → Archive → Distribute)
5. Compléter les métadonnées

---

## Plugins Capacitor recommandés

```bash
# Caméra (photo de profil)
npm install @capacitor/camera

# Notifications push
npm install @capacitor/push-notifications

# Partage natif
npm install @capacitor/share

# Stockage local
npm install @capacitor/preferences

# État réseau
npm install @capacitor/network

# Splash screen
npm install @capacitor/splash-screen

# Après installation
npx cap sync
```

---

## Dépannage

### Écran blanc après lancement
- Vérifier que `webDir` dans `capacitor.config.ts` pointe vers le bon dossier
- Vérifier que `npm run build` a réussi
- Vérifier les logs dans Android Studio / Xcode

### Erreurs Gradle (Android)
- Mettre à jour Gradle quand proposé
- Nettoyer : `cd android && ./gradlew clean`

### Erreurs CocoaPods (iOS)
- Mettre à jour : `cd ios/App && pod install --repo-update`

### API non accessible
- Vérifier `VITE_API_URL`
- Pour le développement, autoriser le cleartext dans `capacitor.config.ts`

---

## Variables d'environnement

| Variable | Description | Exemple |
|----------|-------------|---------|
| `VITE_API_URL` | URL de l'API backend | `https://app.koomy.app/api` |

---

## Changelog

| Date | Version | Description |
|------|---------|-------------|
| 15/12/2024 | 1.0.0 | Configuration initiale Capacitor |

---

*Document maintenu par l'équipe Koomy*
