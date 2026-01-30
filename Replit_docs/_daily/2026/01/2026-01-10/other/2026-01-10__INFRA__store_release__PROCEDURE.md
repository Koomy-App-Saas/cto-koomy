# Store Release Guide - Koomy Mobile Apps

## Overview

This guide explains how to build store-ready mobile applications for:
- **Koomy Member** (app.koomy.members) - Public member app
- **Koomy Pro** (app.koomy.admin) - Administrator app  
- **White-label tenants** - Branded community apps (e.g., UNSA Lidl)

## Prerequisites

- Node.js 18+
- Android Studio (for Android builds)
- Xcode (for iOS builds, macOS only)
- Valid signing credentials (for production releases)

## Quick Start

### Android Release Builds

```bash
# Koomy Member
node packages/mobile-build/index.mjs member --release --android

# Koomy Pro (Admin)
node packages/mobile-build/index.mjs admin --release --android

# White-label tenant
node packages/mobile-build/index.mjs tenant unsa-lidl --release --android
```

### iOS Release Builds

```bash
# Koomy Member
node packages/mobile-build/index.mjs member --release --ios

# Koomy Pro (Admin)
node packages/mobile-build/index.mjs admin --release --ios

# White-label tenant
node packages/mobile-build/index.mjs tenant unsa-lidl --release --ios
```

## CLI Options

| Option | Description |
|--------|-------------|
| `--release` | Full store-ready build with native assets |
| `--android` | Build for Android only |
| `--ios` | Build for iOS only |
| `--skip-web-build` | Reuse existing dist/ (faster rebuild) |
| `--prepare-only` | Generate artifacts without native platforms |

## Output Structure

After a release build, artifacts are generated in:

```
artifacts/mobile/<AppName>/
├── dist/public/          # Web assets (Capacitor webDir)
├── android/              # Android Studio project
│   ├── app/
│   │   ├── src/main/res/
│   │   │   ├── mipmap-mdpi/    # 48px icons
│   │   │   ├── mipmap-hdpi/    # 72px icons
│   │   │   ├── mipmap-xhdpi/   # 96px icons
│   │   │   ├── mipmap-xxhdpi/  # 144px icons
│   │   │   └── mipmap-xxxhdpi/ # 192px icons
│   │   └── build.gradle
│   └── build.gradle
├── ios/                  # Xcode project
│   └── App/
│       └── Assets.xcassets/
│           └── AppIcon.appiconset/
├── capacitor.config.ts   # Capacitor configuration
├── build-manifest.json   # Build metadata
├── version.json          # Version info
└── keystore.properties   # Android signing (if configured)
```

## Android Signing

### Option 1: Environment Variables (Recommended for CI/CD)

Set these environment variables before running the build:

```bash
export ANDROID_KEYSTORE_PATH="/path/to/your/keystore.jks"
export ANDROID_KEYSTORE_PASSWORD="your-keystore-password"
export ANDROID_KEY_ALIAS="your-key-alias"
export ANDROID_KEY_PASSWORD="your-key-password"

node packages/mobile-build/index.mjs member --release --android
```

The CLI will automatically generate `keystore.properties` in the artifact directory.

### Option 2: Secrets Directory

Place your keystore file at:
```
secrets/android/<bundleId>/keystore.jks
```

For example:
```
secrets/android/app.koomy.members/keystore.jks
secrets/android/app.koomy.admin/keystore.jks
secrets/android/app.koomy.unsalidl/keystore.jks
```

The CLI will detect and use it automatically.

### Building the AAB

After the release build completes:

```bash
cd artifacts/mobile/KoomyMemberApp/android
./gradlew bundleRelease
```

The signed AAB will be at:
```
android/app/build/outputs/bundle/release/app-release.aab
```

### Building an APK (for testing)

```bash
cd artifacts/mobile/KoomyMemberApp/android
./gradlew assembleRelease
```

Output: `android/app/build/outputs/apk/release/app-release.apk`

## iOS Release

### Prerequisites

- macOS with Xcode installed
- Apple Developer account
- Valid provisioning profiles and certificates

### Building for App Store

1. Run the release build:
   ```bash
   node packages/mobile-build/index.mjs member --release --ios
   ```

2. Open in Xcode:
   ```bash
   cd artifacts/mobile/KoomyMemberApp
   npx cap open ios
   ```

3. In Xcode:
   - Select your Team in Signing & Capabilities
   - Set the Bundle Identifier (already configured)
   - Select Product → Archive
   - In Organizer, click "Distribute App"
   - Choose "App Store Connect" or "Ad Hoc"

## App Identities

| App | Bundle ID | Display Name |
|-----|-----------|--------------|
| Koomy Member | app.koomy.members | Koomy |
| Koomy Pro | app.koomy.admin | Koomy Pro |
| UNSA Lidl | app.koomy.unsalidl | UNSA Lidl |

## Native Assets Generated

### Android Icons (10 variants)
- `ic_launcher.png` - Standard launcher icon (5 densities: mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi)
- `ic_launcher_foreground.png` - Adaptive icon foreground (5 densities)

### iOS Icons (18 variants)
- 8 iPhone icons (20pt, 29pt, 40pt, 60pt at 2x and 3x)
- 9 iPad icons (20pt, 29pt, 40pt, 76pt, 83.5pt at 1x and 2x)
- 1 ios-marketing icon (1024x1024 for App Store)
- Contents.json with proper idioms (iphone, ipad, ios-marketing)

### Splash Screens (if splash.png provided)
- Android: 5 density variants in drawable folders
- iOS: 6 variants in Splash.imageset

## Troubleshooting

### "index.html not found" Error

The CLI expects web assets in `dist/public/`. If you see this error:
- Run `npm run build` first, or
- Remove `--skip-web-build` flag

### Signing Errors

1. Verify keystore path is absolute
2. Check passwords are correct
3. Ensure key alias exists in keystore

### Android Studio Not Found

Install Android Studio and ensure `ANDROID_HOME` is set:
```bash
export ANDROID_HOME=~/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools
```

## Version Management

Version is defined in:
- **member/admin**: `packages/mobile-build/index.mjs` (APPS object)
- **tenants**: `tenants/<id>/config.ts` (version field)

Update `version.name` (e.g., "1.0.0") and `version.code` (e.g., 1) before each store release.

## CI/CD Integration

Example GitHub Actions workflow:

```yaml
- name: Build Android Release
  env:
    ANDROID_KEYSTORE_PATH: ${{ secrets.KEYSTORE_PATH }}
    ANDROID_KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
    ANDROID_KEY_ALIAS: ${{ secrets.KEY_ALIAS }}
    ANDROID_KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}
  run: |
    npm install
    npm run build
    node packages/mobile-build/index.mjs member --release --android
    cd artifacts/mobile/KoomyMemberApp/android
    ./gradlew bundleRelease
```
