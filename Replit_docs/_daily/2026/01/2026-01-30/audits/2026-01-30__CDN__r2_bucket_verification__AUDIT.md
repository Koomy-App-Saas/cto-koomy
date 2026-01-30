# Vérification R2 Bucket & CDN — Checklist d'exécution

**Date**: 2026-01-30  
**Statut**: À EXÉCUTER MANUELLEMENT  
**CDN Prod**: https://cdn-prodv2.koomy.app  
**CDN Sandbox**: https://cdn-sandbox.koomy.app  

---

## PRÉREQUIS

- Accès au dashboard Cloudflare (compte avec droits R2)
- OU wrangler CLI configuré (`wrangler login`)
- Terminal pour exécuter les tests curl

---

## 1. PREUVE BUCKET R2 — Structure réelle

### 1.1 Sandbox

**Via Cloudflare Dashboard** : R2 → Bucket sandbox → Objects → Filtrer

**Via wrangler CLI** :
```bash
# Remplacer <BUCKET_SANDBOX> par le nom réel du bucket
wrangler r2 object list <BUCKET_SANDBOX> --prefix "public/white-label/" --max-keys 5
wrangler r2 object list <BUCKET_SANDBOX> --prefix "koomysandbox/public/white-label/" --max-keys 5
```

**RÉSULTATS À COLLER ICI** :

```
# Bucket name: ____________________

# Listing prefix="public/white-label/"
[COLLER OUTPUT ICI]

# Listing prefix="koomysandbox/public/white-label/"
[COLLER OUTPUT ICI]
```

**CONCLUSION SANDBOX** :
- [ ] Les objets sont sous `public/...` (sans namespace)
- [ ] Les objets sont sous `koomysandbox/public/...` (avec namespace)

---

### 1.2 Prodv2

```bash
# Remplacer <BUCKET_PRODV2> par le nom réel du bucket
wrangler r2 object list <BUCKET_PRODV2> --prefix "public/white-label/" --max-keys 5
wrangler r2 object list <BUCKET_PRODV2> --prefix "koomyprodv2/public/white-label/" --max-keys 5
```

**RÉSULTATS À COLLER ICI** :

```
# Bucket name: ____________________

# Listing prefix="public/white-label/"
[COLLER OUTPUT ICI]

# Listing prefix="koomyprodv2/public/white-label/"
[COLLER OUTPUT ICI]
```

**CONCLUSION PRODV2** :
- [ ] Les objets sont sous `public/...` (sans namespace)
- [ ] Les objets sont sous `koomyprodv2/public/...` (avec namespace)

---

## 2. VARIABLES D'ENVIRONNEMENT DÉPLOYÉES

### 2.1 Sandbox (saasowner-sandbox.koomy.app)

**Où vérifier** : Platform de déploiement (Render/Fly/autre) → Environment Variables

| Variable | Valeur |
|----------|--------|
| `VITE_CDN_BASE_URL` | |
| `VITE_CDN_NAMESPACE_PREFIX` | |
| `S3_BUCKET` | |
| `S3_ENDPOINT` | |

### 2.2 Prodv2

| Variable | Valeur |
|----------|--------|
| `VITE_CDN_BASE_URL` | |
| `VITE_CDN_NAMESPACE_PREFIX` | |
| `S3_BUCKET` | |
| `S3_ENDPOINT` | |

---

## 3. TESTS CURL — Vérité CDN

### 3.1 Récupérer un UUID réel

Depuis les logs de l'API (sandbox ou prodv2), chercher un upload récent :
```
[UP-XXXXXXXX] Upload success: { r2Key: "public/white-label/<UUID>.png", ... }
```

**UUID trouvé** : `________________________________`

### 3.2 Tests Sandbox

```bash
# Remplacer <UUID> par la valeur réelle
curl -I https://cdn-sandbox.koomy.app/public/white-label/<UUID>.png
curl -I https://cdn-sandbox.koomy.app/koomysandbox/public/white-label/<UUID>.png
```

**RÉSULTATS** :

```
# Test 1: /public/white-label/<UUID>.png
HTTP/2 ___
Content-Type: ___
Cache-Control: ___

# Test 2: /koomysandbox/public/white-label/<UUID>.png
HTTP/2 ___
Content-Type: ___
Cache-Control: ___
```

### 3.3 Tests Prodv2

```bash
curl -I https://cdn-prodv2.koomy.app/public/white-label/<UUID>.png
curl -I https://cdn-prodv2.koomy.app/koomyprodv2/public/white-label/<UUID>.png
```

**RÉSULTATS** :

```
# Test 1: /public/white-label/<UUID>.png
HTTP/2 ___

# Test 2: /koomyprodv2/public/white-label/<UUID>.png
HTTP/2 ___
```

---

## 4. MATRICE DE VÉRITÉ (À REMPLIR)

| Env | Clé R2 réelle | URL CDN 200 | URL CDN 404 | Mismatch ? |
|-----|---------------|-------------|-------------|------------|
| sandbox | | | | |
| prodv2 | | | | |

---

## 5. DIAGNOSTIC FINAL

### Scénario identifié (cocher UN seul) :

- [ ] **A** : Clé R2 = `public/...`, CDN attend `public/...` → **OK, pas de fix**
- [ ] **B** : Clé R2 = `public/...`, CDN attend `namespace/public/...` → **Fix frontend : supprimer VITE_CDN_NAMESPACE_PREFIX**
- [ ] **C** : Clé R2 = `namespace/public/...`, CDN attend `namespace/public/...` → **OK, ajouter VITE_CDN_NAMESPACE_PREFIX**
- [ ] **D** : Clé R2 = `public/...`, bucket attend `namespace/public/...` → **Fix backend : ajouter R2_NAMESPACE_PREFIX**

---

## 6. FIX PROPOSÉ (seulement après preuves)

### Si scénario B (supprimer namespace frontend) :

**Environnement** : sandbox / prodv2  
**Action** : Supprimer `VITE_CDN_NAMESPACE_PREFIX` de la config déployée  
**Impact** : Frontend uniquement, aucun changement code  

### Si scénario C (ajouter namespace frontend) :

**Environnement** : sandbox / prodv2  
**Action** : Définir `VITE_CDN_NAMESPACE_PREFIX=/koomysandbox` (ou `/koomyprodv2`)  
**Impact** : Frontend uniquement, aucun changement code  

### Si scénario D (ajouter namespace backend) :

**Action** : Modifier `server/routes.ts` ligne 7349 :
```typescript
const namespacePrefix = process.env.R2_NAMESPACE_PREFIX || '';
const r2Key = `${namespacePrefix}public/${folder}/${objectId}.${extension}`;
```

**Puis** : Ajouter `R2_NAMESPACE_PREFIX=koomysandbox/` (ou `koomyprodv2/`) aux env vars backend

**Impact** : Backend + env vars, les nouveaux uploads seront corrects

**Migration objets existants** : Nécessaire si objets existants doivent être accessibles

---

## SIGNATURE

**Vérification effectuée par** : ____________________  
**Date** : ____________________  
**Conclusion** : ____________________  
