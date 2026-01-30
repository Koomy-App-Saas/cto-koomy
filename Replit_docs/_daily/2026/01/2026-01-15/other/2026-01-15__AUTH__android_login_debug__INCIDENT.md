# ANDROID_LOGIN_DEBUG_REPORT.md

## Rapport de Debug - Login Android

**Date:** 2026-01-01  
**Version:** 1.3.6 (build code 10)  
**Tenant:** UNSA Lidl  
**Statut:** ✅ INSTRUMENTATION COMPLÈTE

---

## 1. Système de Traçage Implémenté

### A) TraceID par Requête

Chaque requête HTTP génère un `traceId` unique (format `TR-XXXXXXXX`) :
- Envoyé en header `X-Trace-Id`
- Affiché à l'écran en cas d'erreur login
- Logué côté client ET serveur

**Headers envoyés automatiquement:**
```
X-Trace-Id: TR-ABC12345
X-Platform: android
X-Is-Native: true
```

### B) Écran Diagnostics

Accessible via **7 taps sur le logo** de l'app.

**Informations affichées:**
- Version app + code
- Platform (android/ios/web)
- Is Native (Yes/No)
- wl.json loaded + contenu
- API Base URL
- Last Request (traceId, method, fullUrl, headers)
- Last Response (status, durationMs, body snippet)
- Last Error (message, stack, code)
- Request History (20 dernières)
- Boutons: Test Health, Test Echo, Copier

### C) Logs Client Structurés

```javascript
[API TRACE TR-ABC123] 📤 REQUEST {
  method: "POST",
  path: "/api/accounts/login",
  fullUrl: "https://koomy-saas-plateforme-lamine7.replit.app/api/accounts/login",
  headers: {...},
  bodyKeys: ["email", "password"]
}

[API TRACE TR-ABC123] 📥 RESPONSE {
  status: 200,
  ok: true,
  durationMs: 245,
  bodySnippet: "..."
}
```

---

## 2. Instrumentation Serveur

### A) Middleware de Logging

Chaque requête API est loggée :
```
[REQ TR-ABC123] POST /api/accounts/login {
  platform: "android",
  isNative: "true",
  host: "koomy-saas-plateforme-lamine7.replit.app",
  userAgent: "..."
}
[RES TR-ABC123] 200 POST /api/accounts/login (156ms)
```

### B) Endpoint /api/health

```bash
$ curl -H "X-Trace-Id: TEST-123" -H "X-Platform: android" \
    https://koomy-saas-plateforme-lamine7.replit.app/api/health

{
  "status": "ok",
  "timestamp": "2026-01-01T22:25:33.988Z",
  "server": "koomy-api",
  "version": "1.3.6",
  "uptime": 30.112,
  "traceId": "TEST-123",
  "receivedHeaders": {
    "platform": "android",
    "userAgent": "curl/8.7.1"
  }
}
```

### C) Endpoint /api/debug/echo

Vérifie exactement ce que le serveur reçoit :
```bash
$ curl -X POST -H "Content-Type: application/json" \
    -H "X-Trace-Id: ECHO-456" -H "X-Platform: android" \
    -d '{"testMessage":"Hello"}' \
    https://koomy-saas-plateforme-lamine7.replit.app/api/debug/echo

{
  "echo": true,
  "traceId": "ECHO-456",
  "timestamp": "2026-01-01T22:25:34.294Z",
  "receivedBody": {"testMessage": "Hello"},
  "receivedHeaders": {
    "contentType": "application/json",
    "platform": "android",
    "traceId": "ECHO-456"
  }
}
```

### D) Handler 404 Amélioré

```
[404 TR-XYZ789] ❌ Route not found
[404 TR-XYZ789]   Method: POST
[404 TR-XYZ789]   Path: /api/wrong-endpoint
[404 TR-XYZ789]   Original URL: /api/wrong-endpoint
[404 TR-XYZ789]   Platform: android
[404 TR-XYZ789]   IP: xxx
[404 TR-XYZ789]   User-Agent: xxx
```

---

## 3. Affichage Erreur Login avec TraceID

En cas d'erreur de login, l'UI affiche maintenant :
- Message d'erreur + code HTTP
- TraceID pour diagnostic

```
┌─────────────────────────────────┐
│ ⚠️ Email ou mot de passe       │
│    incorrect [401]              │
│ Trace: TR-4K7BQWML              │
└─────────────────────────────────┘
```

---

## 4. Tests Effectués

| Test | Résultat | Détails |
|------|----------|---------|
| Health endpoint | ✅ PASS | Status 200, traceId retourné |
| Echo endpoint | ✅ PASS | Body + headers confirmés |
| TraceID header | ✅ PASS | Reçu côté serveur |
| wl.json loading | ✅ PASS | apiBaseUrl correct |
| fullUrl logging | ✅ PASS | URL complète visible |

---

## 5. Checklist Hypothèses Vérifiées

| Hypothèse | Status | Notes |
|-----------|--------|-------|
| baseUrl vide → localhost | ✅ FIXED | Guard ensureApiConfigLoaded() |
| mauvais prefix /api | ✅ OK | Routes alignées web/mobile |
| double slash URL | ✅ OK | buildUrl() normalise |
| HTTPS/TLS | ✅ OK | Headers reçus correctement |
| timeout | ✅ OK | 30s configuré |
| erreur parse JSON | ✅ OK | Logging du body snippet |
| CORS | N/A | CapacitorHttp ne utilise pas CORS |
| Content-Type | ✅ OK | application/json vérifié |

---

## 6. Build v1.3.6 Généré

```
artifacts/mobile/UNSALidlApp/
├── android/                    # Projet Android Studio
├── ios/                        # Projet Xcode
├── public/wl.json              # Config white-label
├── capacitor.config.ts         # Config Capacitor
└── build-manifest.json         # Métadonnées build
```

**wl.json contenu:**
```json
{
  "apiBaseUrl": "https://koomy-saas-plateforme-lamine7.replit.app",
  "version": { "name": "1.3.6", "code": 10 }
}
```

---

## 7. Procédure de Test AAB

### 1. Installer le build
```bash
cd artifacts/mobile/UNSALidlApp
npx cap open android
# Build > Generate Signed Bundle
```

### 2. Tester depuis l'app
1. Installer l'AAB via Play Console (Internal Testing)
2. Ouvrir l'app
3. Tap 7x sur le logo → Écran Diagnostics
4. Appuyer "Test Health" → Doit afficher 200 OK
5. Appuyer "Test Echo" → Doit afficher le body reçu
6. Tenter un login avec email invalide
7. Vérifier que l'erreur affiche le TraceID
8. Noter le TraceID et vérifier les logs serveur

### 3. Vérification serveur
Chercher dans les logs :
```
[REQ TR-XXXXXXXX] POST /api/accounts/login
[RES TR-XXXXXXXX] 401 POST /api/accounts/login (XXms)
```

---

## 8. Credentials de Test

**Compte existant:**
- Email: `mlaminesylla@yahoo.fr`
- Password: `Koomy2025!`

---

## 9. Fichiers Modifiés

| Fichier | Modification |
|---------|--------------|
| `client/src/api/config.ts` | TraceID generator, request/response/error logs, history |
| `client/src/api/httpClient.ts` | Headers X-Trace-Id/X-Platform, logging structuré |
| `client/src/components/DiagnosticScreen.tsx` | UI complète avec tests et historique |
| `client/src/pages/mobile/WhiteLabelLogin.tsx` | Affichage TraceID sur erreur |
| `server/routes.ts` | Middleware trace, /api/health, /api/debug/echo, 404 handler |
| `tenants/unsa-lidl/config.ts` | Version 1.3.6, code 10 |

---

## 10. Conclusion

**Instrumentation complète implémentée** permettant de :
- Voir exactement quelle URL est appelée (fullUrl)
- Tracer chaque requête avec un ID unique
- Corréler logs client ↔ serveur
- Diagnostiquer depuis l'app (écran caché)
- Afficher les erreurs avec contexte complet

**Prochaine étape:** Installer l'AAB v1.3.6 et capturer un TraceID de login pour confirmer le bon fonctionnement.
