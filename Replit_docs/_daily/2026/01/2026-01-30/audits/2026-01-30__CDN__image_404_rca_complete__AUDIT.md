# RCA COMPLÈTE : CDN IMAGE 404 — NO FIX BEFORE PROOF

**Date**: 2026-01-30  
**Statut**: EN ATTENTE DE VÉRIFICATION BUCKET  
**Auteur**: Replit Agent  

---

## AVERTISSEMENT

Ce rapport distingue clairement :
- ✅ **PROUVÉ** : Vérifiable directement dans le code source
- ⏳ **À VÉRIFIER** : Nécessite accès au bucket R2 / Cloudflare Dashboard

**AUCUN FIX ne sera proposé avant que les éléments "À VÉRIFIER" soient confirmés.**

---

## ÉTAPE 1 — AUDIT DU BUCKET (À VÉRIFIER)

### 1.1 Provider par environnement

| Environnement | Provider attendu | Bucket name | Namespace | STATUT |
|---------------|------------------|-------------|-----------|--------|
| Replit dev | `replit-object-storage` | `DEFAULT_OBJECT_STORAGE_BUCKET_ID` (secret) | N/A | ⏳ À VÉRIFIER |
| sandbox externe | `s3-r2` (Cloudflare R2) | `S3_BUCKET` (secret) | `koomysandbox/` ? | ⏳ À VÉRIFIER |
| prodv2 | `s3-r2` (Cloudflare R2) | `S3_BUCKET` (secret) | `koomyprodv2/` ? | ⏳ À VÉRIFIER |

### 1.2 Objets à chercher dans le bucket

**ACTION REQUISE** : Via Cloudflare Dashboard ou `wrangler r2 object list`, chercher :

```
# Sandbox
public/white-label/*.png
koomysandbox/public/white-label/*.png

# Prodv2
public/white-label/*.png
koomyprodv2/public/white-label/*.png
```

**FORMAT DE PREUVE ATTENDU** :
```
$ wrangler r2 object list koomy-sandbox-bucket --prefix "public/white-label"
[output exact ici]

$ wrangler r2 object list koomy-sandbox-bucket --prefix "koomysandbox/public/white-label"
[output exact ici]
```

**OU capture d'écran du Cloudflare Dashboard montrant la structure du bucket.**

---

## ÉTAPE 2 — CORRÉLATION BACKEND (PROUVÉ)

### 2.1 Route d'upload analysée

**Fichier** : `server/routes.ts`  
**Route** : `POST /api/uploads/image-direct`  
**Lignes** : 7256-7393

### 2.2 Construction de la clé R2 (PROUVÉ)

```typescript
// Ligne 7349
const r2Key = `public/${folder}/${objectId}.${extension}`;
```

**Exemple concret** :
- folder = `white-label`
- objectId = `abc123-def456`
- extension = `png`
- **r2Key** = `public/white-label/abc123-def456.png`

### 2.3 objectPath retourné au frontend (PROUVÉ)

```typescript
// Ligne 7382
const objectPath = `/objects/${r2Key}`;
```

**Exemple concret** :
- **objectPath** = `/objects/public/white-label/abc123-def456.png`

### 2.4 Namespace dans le backend (PROUVÉ)

| Question | Réponse | Preuve |
|----------|---------|--------|
| Le backend utilise-t-il un namespace ? | **NON** | Ligne 7349 : `public/${folder}/${...}` |
| Existe-t-il une env var `R2_NAMESPACE_PREFIX` ? | **NON** | grep sur codebase = 0 résultat |
| Le namespace est-il implicite ? | **INCONNU** | Dépend de la config S3_BUCKET |

### 2.5 Méthode d'écriture S3/R2 (PROUVÉ)

```typescript
// server/objectStorage.ts, ligne 177-198
private async uploadBufferS3(buffer, key, contentType) {
  const client = getS3Client();
  const bucket = process.env.S3_BUCKET!;  // ← bucket name depuis env
  
  const command = new PutObjectCommand({
    Bucket: bucket,
    Key: key,  // ← clé passée telle quelle, sans transformation
    Body: buffer,
    ContentType: contentType,
  });
  
  await client.send(command);
}
```

**Conclusion** : La clé est écrite **telle quelle** dans le bucket, sans ajout de namespace.

---

## ÉTAPE 3 — CORRÉLATION FRONTEND (PROUVÉ)

### 3.1 Fonction de transformation

**Fichier** : `client/src/lib/cdnResolver.ts`  
**Fonction** : `resolvePublicObjectUrl()`

### 3.2 Transformation exacte (PROUVÉ)

```typescript
// Ligne 189-196
let cdnPath = trimmedUrl.replace(/^\/?objects\//, '');  // strip /objects/
cdnPath = cdnPath.replace(/^objects\//, '');            // handle double prefix
const normalizedPath = cdnPath.replace(/^\/+/, '');     // remove leading slashes

const namespacePrefix = getCdnNamespacePrefix();        // VITE_CDN_NAMESPACE_PREFIX
const resolvedUrl = `${cdnBase}${namespacePrefix}/${normalizedPath}`;
```

### 3.3 Exemple de transformation

**Input** : `/objects/public/white-label/abc123.png`

| Étape | Résultat |
|-------|----------|
| strip `/objects/` | `public/white-label/abc123.png` |
| normalizedPath | `public/white-label/abc123.png` |
| namespacePrefix | `(dépend de VITE_CDN_NAMESPACE_PREFIX)` |

**Output selon configuration** :

| VITE_CDN_NAMESPACE_PREFIX | URL CDN générée |
|---------------------------|-----------------|
| (non défini) | `https://cdn-sandbox.koomy.app/public/white-label/abc123.png` |
| `/koomysandbox` | `https://cdn-sandbox.koomy.app/koomysandbox/public/white-label/abc123.png` |
| `/koomyprodv2` | `https://cdn.koomy.app/koomyprodv2/public/white-label/abc123.png` |

### 3.4 Valeur actuelle de VITE_CDN_NAMESPACE_PREFIX

**Environnement Replit** : ⏳ À VÉRIFIER (probablement non défini)  
**Sandbox externe** : ⏳ À VÉRIFIER  
**Prodv2** : ⏳ À VÉRIFIER  

---

## ÉTAPE 4 — MATRICE DE VÉRITÉ

### 4.1 Éléments prouvés par le code

| Élément | Valeur | Source |
|---------|--------|--------|
| r2Key écrite par backend | `public/<folder>/<uuid>.<ext>` | server/routes.ts:7349 |
| objectPath retourné | `/objects/public/<folder>/<uuid>.<ext>` | server/routes.ts:7382 |
| Transformation front sans namespace | `https://cdn.../public/<folder>/<uuid>.<ext>` | cdnResolver.ts:196 |
| Transformation front avec namespace | `https://cdn.../<namespace>/public/<folder>/<uuid>.<ext>` | cdnResolver.ts:196 |

### 4.2 Éléments à vérifier (OBLIGATOIRE)

| Environnement | Question | Comment vérifier |
|---------------|----------|------------------|
| sandbox | Objets sous `public/...` ou `koomysandbox/public/...` ? | `wrangler r2 object list` |
| sandbox | Valeur de `VITE_CDN_NAMESPACE_PREFIX` ? | Variable d'env déployée |
| prodv2 | Objets sous `public/...` ou `koomyprodv2/public/...` ? | `wrangler r2 object list` |
| prodv2 | Valeur de `VITE_CDN_NAMESPACE_PREFIX` ? | Variable d'env déployée |

### 4.3 Matrice de vérité (À COMPLÉTER)

| Environnement | Clé écrite dans bucket | URL CDN générée | Existe réellement ? |
|---------------|------------------------|-----------------|---------------------|
| sandbox | ⏳ `public/...` ou `koomysandbox/public/...` ? | ⏳ dépend de env var | ⏳ À TESTER |
| prodv2 | ⏳ `public/...` ou `koomyprodv2/public/...` ? | ⏳ dépend de env var | ⏳ À TESTER |

---

## ÉTAPE 5 — SCÉNARIOS POSSIBLES

### Scénario A : Backend écrit `public/...`, CDN attend `public/...`

**Condition** : Bucket sans namespace, `VITE_CDN_NAMESPACE_PREFIX` non défini

| Clé R2 | URL CDN | Match ? |
|--------|---------|---------|
| `public/white-label/abc.png` | `https://cdn.../public/white-label/abc.png` | ✅ OUI |

**Action requise** : Aucune

### Scénario B : Backend écrit `public/...`, CDN attend `namespace/public/...`

**Condition** : Bucket sans namespace, mais `VITE_CDN_NAMESPACE_PREFIX` défini

| Clé R2 | URL CDN | Match ? |
|--------|---------|---------|
| `public/white-label/abc.png` | `https://cdn.../koomysandbox/public/white-label/abc.png` | ❌ NON → 404 |

**Action requise** : Supprimer `VITE_CDN_NAMESPACE_PREFIX`

### Scénario C : Bucket utilise namespace implicite

**Condition** : Le bucket est configuré pour préfixer tous les objets

| Clé passée à S3 | Clé réelle dans bucket | URL CDN attendue |
|-----------------|------------------------|------------------|
| `public/white-label/abc.png` | `koomysandbox/public/white-label/abc.png` | `https://cdn.../koomysandbox/public/white-label/abc.png` |

**Action requise** : Définir `VITE_CDN_NAMESPACE_PREFIX=/koomysandbox`

### Scénario D : Backend doit inclure le namespace explicitement

**Condition** : Le bucket attend le namespace dans la clé

**Action requise** : Ajouter `R2_NAMESPACE_PREFIX` côté backend

```typescript
const namespacePrefix = process.env.R2_NAMESPACE_PREFIX || '';
const r2Key = `${namespacePrefix}public/${folder}/${objectId}.${extension}`;
```

---

## TESTS DE VÉRIFICATION (À EXÉCUTER)

### Test 1 : Vérifier la structure du bucket sandbox

```bash
# Via wrangler CLI
wrangler r2 object list <BUCKET_NAME> --prefix "public/" --max-keys 5
wrangler r2 object list <BUCKET_NAME> --prefix "koomysandbox/" --max-keys 5

# Ou via Cloudflare Dashboard → R2 → Bucket → Objects
```

### Test 2 : Vérifier les URLs CDN

```bash
# Après un upload récent, récupérer le traceId dans les logs
# Puis tester les URLs :

curl -I https://cdn-sandbox.koomy.app/public/white-label/<uuid>.png
curl -I https://cdn-sandbox.koomy.app/koomysandbox/public/white-label/<uuid>.png
```

### Test 3 : Vérifier les env vars déployées

```bash
# Sur sandbox externe
echo $VITE_CDN_NAMESPACE_PREFIX
echo $S3_BUCKET

# Sur prodv2
echo $VITE_CDN_NAMESPACE_PREFIX
echo $S3_BUCKET
```

---

## CONCLUSION

### Ce qui est prouvé :
1. Le backend écrit les objets avec la clé `public/<folder>/<uuid>.<ext>`
2. Aucun namespace n'est ajouté côté backend
3. Le frontend ajoute un namespace **seulement si** `VITE_CDN_NAMESPACE_PREFIX` est défini

### Ce qui doit être vérifié :
1. La structure réelle du bucket R2 (avec ou sans namespace ?)
2. Les valeurs des env vars sur les environnements déployés
3. La configuration du CDN Cloudflare (path mapping ?)

### Prochaine étape :
**AUCUN FIX AVANT** que les tests ci-dessus soient exécutés et documentés avec preuves.

---

## ESPACE POUR PREUVES (À REMPLIR)

### Preuve 1 : Listing bucket sandbox

```
[Coller ici l'output de wrangler r2 object list ou capture d'écran]
```

### Preuve 2 : Listing bucket prodv2

```
[Coller ici l'output de wrangler r2 object list ou capture d'écran]
```

### Preuve 3 : Env vars sandbox

```
VITE_CDN_NAMESPACE_PREFIX = [valeur]
S3_BUCKET = [valeur]
```

### Preuve 4 : Env vars prodv2

```
VITE_CDN_NAMESPACE_PREFIX = [valeur]
S3_BUCKET = [valeur]
```

### Preuve 5 : Tests curl CDN

```
$ curl -I https://cdn-sandbox.koomy.app/public/white-label/<uuid>.png
[réponse]

$ curl -I https://cdn-sandbox.koomy.app/koomysandbox/public/white-label/<uuid>.png
[réponse]
```
