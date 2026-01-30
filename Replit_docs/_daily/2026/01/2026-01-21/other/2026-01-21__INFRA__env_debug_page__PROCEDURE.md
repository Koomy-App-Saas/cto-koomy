# KOOMY — Cloudflare Pages
## Vérification injection env vars VITE_* (Sandbox) — Procédure (TEMPORAIRE)

**Date :** 2026-01-21  
**Domain :** INFRA  
**Doc Type :** PROCEDURE  
**Scope :** Frontend (Cloudflare Pages) uniquement  
**Status :** TEMPORAIRE - À supprimer après validation

---

## Objectif

Vérifier que Cloudflare Pages injecte correctement les variables `VITE_*` au build (ex: `VITE_FIREBASE_PROJECT_ID=koomy-sandbox`).

---

## Route de debug

**URL :** `https://<host-sandbox>/__env`

**Variables affichées :**
- `import.meta.env.MODE`
- `import.meta.env.CF_PAGES_BRANCH`
- `import.meta.env.CF_PAGES_COMMIT_SHA`
- `import.meta.env.VITE_FIREBASE_PROJECT_ID`
- `import.meta.env.VITE_FIREBASE_AUTH_DOMAIN`
- `import.meta.env.VITE_API_BASE_URL`
- `import.meta.env.VITE_CDN_BASE_URL`

---

## Protection d'accès

La route est accessible uniquement si le hostname contient :
- `sandbox`
- `localhost`
- `127.0.0.1`
- `.replit.dev`
- `.replit.app`

En production, la page affiche "Access Denied".

---

## Tests de validation

1. Déployer la sandbox (Cloudflare Pages rebuild)
2. Ouvrir `/__env` sur le host sandbox
3. Vérifier que :
   - `FIREBASE.PROJECT_ID === "koomy-sandbox"`
   - `API.BASE_URL` correspond au host sandbox attendu
   - `CDN.BASE_URL` correspond au CDN attendu

---

## Fichiers concernés

| Fichier | Action |
|---------|--------|
| `client/src/pages/debug/EnvCheck.tsx` | Page de debug créée |
| `client/src/App.tsx` | Route `/__env` ajoutée |

---

## Retrait (zéro dette)

Pour supprimer cette fonctionnalité après validation :

```bash
# 1. Supprimer le fichier de la page
rm client/src/pages/debug/EnvCheck.tsx

# 2. Dans client/src/App.tsx, supprimer :
#    - L'import : import EnvCheck from "@/pages/debug/EnvCheck";
#    - La route : <Route path="/__env" component={EnvCheck} />
```

**Critère :** En prod, la route affiche "Access Denied".

---

## Mini-log

| Date | Action |
|------|--------|
| 2026-01-21 | Création route `/__env` et page `EnvCheck.tsx` |
