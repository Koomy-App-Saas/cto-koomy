# Solution CORS pour Application Mobile Koomy

Ce document explique la solution implémentée pour résoudre les problèmes CORS rencontrés sur les applications Android/iOS (Capacitor).

---

## Le Problème

### Contexte

Lorsque l'application mobile Capacitor effectue des requêtes HTTP vers le backend :

```
Origin: https://app.koomy.local (WebView Capacitor)
Target: https://xxxxx.replit.dev/api/accounts/login
```

Le navigateur WebView applique les règles **CORS (Cross-Origin Resource Sharing)** et bloque la requête si le serveur ne répond pas avec les bons headers.

### Erreur observée

```
Access to fetch at 'https://<replit-url>/api/accounts/login' 
from origin 'https://app.koomy.local' has been blocked by CORS policy:
No 'Access-Control-Allow-Origin' header is present.
```

### Pourquoi cela se produit

1. **WebView = Navigateur** : Capacitor utilise un WebView qui applique les mêmes règles qu'un navigateur web
2. **Origins différentes** : `app.koomy.local` ≠ `replit.dev`
3. **Preflight OPTIONS** : Les requêtes POST avec `Content-Type: application/json` déclenchent une requête OPTIONS préalable

---

## Solution Implémentée : HTTP Natif (Sans CORS)

### Pourquoi cette approche

| Approche | Avantages | Inconvénients |
|----------|-----------|---------------|
| **CORS côté serveur** | Simple à implémenter | Expose les origins, nécessite maintenance |
| **HTTP Natif (choisi)** | Pas de CORS du tout, plus sécurisé | Nécessite wrapper client |

Les requêtes HTTP natives (OkHttp sur Android, NSURLSession sur iOS) **ne sont pas soumises à CORS** car elles ne passent pas par le contexte navigateur.

### Implémentation

#### Fichier : `client/src/api/httpClient.ts`

```typescript
import { Capacitor } from '@capacitor/core';
import { CapacitorHttp } from '@capacitor/core';

export async function apiFetch(path, options) {
  const url = `${API_BASE_URL}${path}`;
  
  if (Capacitor.isNativePlatform()) {
    // Sur Android/iOS : requête native (pas de CORS)
    return CapacitorHttp.request({
      url,
      method: options.method || 'GET',
      headers: { 'Content-Type': 'application/json' },
      data: options.body
    });
  } else {
    // Sur Web : fetch standard
    return fetch(url, options);
  }
}
```

### Fonctionnement

```
┌─────────────────┐     ┌──────────────────────┐     ┌─────────────┐
│  Code React     │     │  httpClient.ts       │     │  Backend    │
│  (apiFetch)     │────▶│  Détecte plateforme  │────▶│  API        │
└─────────────────┘     └──────────────────────┘     └─────────────┘
                               │
                    ┌──────────┴──────────┐
                    ▼                     ▼
              ┌──────────┐          ┌──────────┐
              │ Web      │          │ Native   │
              │ fetch()  │          │ OkHttp   │
              │ (CORS)   │          │ (no CORS)│
              └──────────┘          └──────────┘
```

---

## APIs Migrées

Les endpoints critiques ont été migrés vers le client HTTP natif :

| Fichier | Endpoints |
|---------|-----------|
| `Login.tsx` | `/api/accounts/login`, `/api/accounts/register` |
| `WhiteLabelLogin.tsx` | `/api/memberships/verify`, `/api/accounts/login`, `/api/memberships/register-and-claim` |
| `AddCard.tsx` | `/api/memberships/verify`, `/api/memberships/claim` |
| `admin/Login.tsx` | `/api/admin/login` |
| `AuthContext.tsx` | `/api/accounts/:id/memberships` |
| `WhiteLabelContext.tsx` | `/api/white-label/config` |

---

## Configuration URL API

### Fichier : `client/src/api/config.ts`

```typescript
import { Capacitor } from '@capacitor/core';

const getApiBaseUrl = (): string => {
  // 1. Variable d'environnement (prioritaire)
  if (import.meta.env.VITE_API_URL) {
    return import.meta.env.VITE_API_URL;
  }
  
  // 2. App native : utiliser l'URL de production
  if (Capacitor.isNativePlatform()) {
    return "https://VOTRE_URL_REPLIT.replit.dev";
  }
  
  // 3. Web : chemin relatif (même serveur)
  return "";
};

export const API_BASE_URL = getApiBaseUrl();
```

### Changer l'URL API à l'avenir

1. **Pour une nouvelle URL Replit** : Modifier `client/src/api/config.ts` ligne 8
2. **Pour un domaine personnalisé** : Modifier la même ligne ou définir `VITE_API_URL` en variable d'environnement
3. **Reconstruire** : `npm run build && npx cap sync android`

---

## Debug et Logs

En mode développement (`import.meta.env.DEV`), le client HTTP affiche des logs :

```
[API] POST /api/accounts/login { native: true }
[API] Response 200 { path: "/api/accounts/login" }
```

Ces logs n'apparaissent pas en production.

### Vérifier sur Android

1. Connecter le téléphone/émulateur
2. Chrome → `chrome://inspect`
3. Sélectionner le WebView Koomy
4. Voir les logs console

---

## Maintenance

### Ajouter un nouvel endpoint

Pour migrer un appel `fetch` vers le client natif :

**Avant :**
```typescript
const response = await fetch(`${API_URL}/api/example`, {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify(data)
});
const result = await response.json();
if (!response.ok) throw new Error(result.error);
```

**Après :**
```typescript
import { apiPost } from "@/api/httpClient";

const response = await apiPost('/api/example', data);
if (!response.ok) throw new Error(response.data?.error);
const result = response.data;
```

### Fonctions disponibles

| Fonction | Usage |
|----------|-------|
| `apiGet(path)` | Requête GET |
| `apiPost(path, body)` | Requête POST |
| `apiPut(path, body)` | Requête PUT |
| `apiPatch(path, body)` | Requête PATCH |
| `apiDelete(path)` | Requête DELETE |

---

## Résumé

| Aspect | Solution |
|--------|----------|
| **Problème** | CORS bloque les requêtes depuis WebView Capacitor |
| **Solution** | Client HTTP natif via CapacitorHttp |
| **Fichier principal** | `client/src/api/httpClient.ts` |
| **Configuration URL** | `client/src/api/config.ts` |
| **Plateforme concernée** | Android, iOS (détection automatique) |
| **Web** | Continue d'utiliser fetch standard |

---

*Document créé le 21 décembre 2024*
