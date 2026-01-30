# CDN Image 404 - Root Cause Analysis

**Date**: 2026-01-30  
**Domain**: CDN / Object Storage  
**Type**: RCA (Root Cause Analysis)  

## Executive Summary

L'environnement sandbox Replit utilise **Replit Object Storage** (pas S3/R2), donc les images uploadées passent par le fallback API `/api/objects/*` et non par le CDN externe. Le problème CDN 404 concerne spécifiquement les **environnements déployés** (prodv2, sandbox externe) qui utilisent S3/R2.

## Étape 1 — Audit Backend

### 1.1 Route d'upload (`POST /api/uploads/image-direct`)

**Fichier**: `server/routes.ts` (lignes 7256-7393)

**Logique de construction de la clé R2** (ligne 7349):
```typescript
const r2Key = `public/${folder}/${objectId}.${extension}`;
```

**objectPath retourné** (ligne 7382):
```typescript
const objectPath = `/objects/${r2Key}`;
// Exemple: /objects/public/white-label/abc123.png
```

### 1.2 Détection du provider

**Fichier**: `server/objectStorage.ts`

Le système détecte automatiquement le provider :

| Provider | Condition | Variables requises |
|----------|-----------|-------------------|
| `s3-r2` | `S3_ENDPOINT && S3_BUCKET && S3_ACCESS_KEY_ID && S3_SECRET_ACCESS_KEY` | S3_* vars |
| `replit-object-storage` | `DEFAULT_OBJECT_STORAGE_BUCKET_ID` | PRIVATE_OBJECT_DIR, PUBLIC_OBJECT_SEARCH_PATHS |
| `unknown` | Aucune condition satisfaite | - |

### 1.3 Variables d'environnement actuelles (Replit)

| Variable | Présente | Type |
|----------|----------|------|
| `DEFAULT_OBJECT_STORAGE_BUCKET_ID` | ✅ Secret | Bucket ID |
| `PUBLIC_OBJECT_SEARCH_PATHS` | ✅ Secret | Chemins publics |
| `PRIVATE_OBJECT_DIR` | ✅ Secret | Répertoire privé |
| `S3_ENDPOINT` | ❌ Non défini | - |
| `S3_BUCKET` | ❌ Non défini | - |
| `KOOMY_ENV` | ✅ Dev = `sandbox` | Environnement |

**Conclusion**: L'environnement Replit utilise `replit-object-storage`, pas S3/R2.

## Étape 2 — Audit CDN

### 2.1 Frontend CDN Resolver

**Fichier**: `client/src/lib/cdnResolver.ts`

**Transformation** (ligne 189-196):
```typescript
// Input: /objects/public/white-label/abc.png
// Étape 1: strip /objects/ → public/white-label/abc.png
// Étape 2: add CDN base + namespace prefix
// Output: ${cdnBase}${namespacePrefix}/${normalizedPath}
```

**Exemple sans namespace prefix**:
- Input: `/objects/public/white-label/abc.png`
- Output: `https://cdn-sandbox.koomy.app/public/white-label/abc.png`

**Exemple avec namespace prefix** (`VITE_CDN_NAMESPACE_PREFIX=/koomyprodv2`):
- Input: `/objects/public/white-label/abc.png`
- Output: `https://cdn.koomy.app/koomyprodv2/public/white-label/abc.png`

### 2.2 Source du CDN URL

| Priorité | Source | Condition |
|----------|--------|-----------|
| 1 | `VITE_CDN_BASE_URL` | Explicitement défini |
| 2 | Inferred from API | `api-prodv2.koomy.app` → `cdn-prodv2.koomy.app` |
| 3 | Fallback hostname | `sandbox` → `cdn-sandbox`, sinon → `cdn` |

## Étape 3 — Diagnostic

### 3.1 Environnement Replit (dev/staging)

| Élément | Valeur | Preuve |
|---------|--------|--------|
| Provider | `replit-object-storage` | Logs boot + env vars |
| objectPath retourné | `/objects/public/<folder>/<uuid>.png` | Code ligne 7382 |
| CDN résolu | `https://cdn.koomy.app/public/...` | Console logs |
| Accès images | Via `/api/objects/*` fallback | Pas de S3 |

**Résultat**: Les images fonctionnent via le fallback API, pas le CDN externe.

### 3.2 Environnement Sandbox Externe (saasowner-sandbox.koomy.app)

Si déployé avec S3/R2 :

| Élément | Valeur attendue | Problème potentiel |
|---------|-----------------|-------------------|
| R2 Key écrite | `public/white-label/abc.png` | Correct |
| objectPath retourné | `/objects/public/white-label/abc.png` | Correct |
| CDN URL générée | `https://cdn-sandbox.koomy.app/public/white-label/abc.png` | ⚠️ Dépend de namespace |
| Namespace bucket | `koomysandbox/` ? | **Non vérifié** |

### 3.3 Environnement Prodv2 (koomyprodv2.koomy.app)

| Élément | Valeur attendue | Problème potentiel |
|---------|-----------------|-------------------|
| R2 Key écrite | `public/...` | ⚠️ Devrait être `koomyprodv2/public/...` ? |
| objectPath retourné | `/objects/public/...` | Correct |
| CDN URL | `https://cdn.koomy.app/koomyprodv2/public/...` | ⚠️ Besoin `VITE_CDN_NAMESPACE_PREFIX` |

## Cause Racine Identifiée

### Scénario A : Namespace mismatch (PROBABLE)

Le bucket R2 utilise un namespace prefix (`koomyprodv2/`), mais :
1. **Backend** : écrit `public/...` sans namespace
2. **CDN/Cloudflare** : sert `namespace/public/...`
3. **Frontend** : génère URL avec namespace (si `VITE_CDN_NAMESPACE_PREFIX` défini)

**Mismatch** : La clé R2 n'a pas le namespace, mais l'URL CDN l'attend.

### Scénario B : Backend doit inclure le namespace

Si le bucket R2 organise les objets avec un namespace :
- Key devrait être : `koomysandbox/public/...` (sandbox)
- Key devrait être : `koomyprodv2/public/...` (prodv2)

## Solution Recommandée

### Option 1 : Backend inclut le namespace (RECOMMANDÉE)

Ajouter une env var côté backend pour le namespace :

```typescript
// server/routes.ts
const namespacePrefix = process.env.R2_NAMESPACE_PREFIX || '';
const r2Key = `${namespacePrefix}public/${folder}/${objectId}.${extension}`;
```

**Variables requises par environnement** :

| Env | R2_NAMESPACE_PREFIX | VITE_CDN_NAMESPACE_PREFIX |
|-----|---------------------|---------------------------|
| sandbox | `koomysandbox/` | `/koomysandbox` |
| prodv2 | `koomyprodv2/` | `/koomyprodv2` |
| prod | (vide) | (vide) |

### Option 2 : CDN/Worker transforme le path

Configurer Cloudflare Worker pour mapper :
- `/public/...` → `namespace/public/...`

(Moins recommandé car dépend de config externe)

## Prochaines Actions

1. **VÉRIFIER** : Quelle est la structure réelle du bucket R2 sandbox/prodv2 ?
   - Utiliser Cloudflare dashboard ou `wrangler r2 object list`
   - Chercher si les objets sont sous `koomysandbox/public/...` ou `public/...`

2. **DÉCIDER** : Où mettre le namespace prefix ?
   - Backend (lors de l'écriture R2) → plus propre
   - Frontend (lors de la génération URL) → déjà implémenté

3. **IMPLÉMENTER** : Une seule règle de mapping cohérente

## Tests de Vérification (à exécuter sur sandbox externe)

```bash
# 1. Upload une image
curl -X POST https://api-sandbox.koomy.app/api/uploads/image-direct \
  -F "file=@test.png" -F "folder=test-rca" \
  -H "Authorization: Bearer <token>"
# Noter l'objectPath retourné

# 2. Vérifier la présence dans R2 (via wrangler ou dashboard)
# Chercher: public/test-rca/<uuid>.png ET koomysandbox/public/test-rca/<uuid>.png

# 3. Tester les URLs CDN
curl -I https://cdn-sandbox.koomy.app/public/test-rca/<uuid>.png
curl -I https://cdn-sandbox.koomy.app/koomysandbox/public/test-rca/<uuid>.png
```

## Conclusion

Le problème vient d'un **mismatch entre la clé R2 écrite et le chemin CDN attendu**. La solution nécessite d'aligner :
1. La clé R2 écrite par le backend
2. Le namespace prefix configuré côté CDN
3. Le namespace prefix utilisé par le frontend

Sans accès direct au bucket R2 ou à la config Cloudflare, il est impossible de déterminer exactement quelle URL est correcte. Les tests manuels ci-dessus permettront de trancher.
