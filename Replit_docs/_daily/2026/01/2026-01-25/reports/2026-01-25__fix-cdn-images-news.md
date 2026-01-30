# Fix CDN Images News - Rapport

**Date**: 2026-01-25
**Status**: Implémenté

## Cause Racine

Le bug d'affichage des images (403) était causé par une combinaison de facteurs :

1. **Variable d'environnement malformée** : `VITE_CDN_BASE_URL` pouvait être fourni sans protocole (`cdn-sandbox.koomy.app` au lieu de `https://cdn-sandbox.koomy.app`)

2. **Resolver incomplet** : Le resolver d'images ne gérait pas tous les cas de figure, notamment les URLs qui ressemblent à des hostnames sans protocole

3. **Résultat** : Une URL comme `cdn-sandbox.koomy.app/public/news/x.png` était interprétée comme un chemin relatif, produisant `https://backoffice-sandbox.koomy.app/admin/cdn-sandbox.koomy.app/public/news/x.png`

## Fichiers Modifiés

| Fichier | Changement |
|---------|------------|
| `client/src/lib/cdnResolver.ts` | Ajout `normalizeCdnBaseUrl()`, renforcement `resolvePublicObjectUrl()` |
| `client/src/lib/envGuard.ts` | Ajout `normalizeUrl()` pour API et CDN base URLs |
| `client/src/api/config.ts` | Ajout safety check pour hostnames sans protocole |

## Avant / Après

### Normalisation de la base CDN

**Avant (cdnResolver.ts):**
```typescript
export function getCdnBaseUrl(): string {
  const explicitUrl = import.meta.env.VITE_CDN_BASE_URL;
  if (explicitUrl) {
    return explicitUrl.replace(/\/+$/, '');
  }
  // ...
}
```

**Après:**
```typescript
function normalizeCdnBaseUrl(url: string): string {
  let normalized = url.trim();
  if (!normalized.startsWith('http://') && !normalized.startsWith('https://')) {
    normalized = `https://${normalized}`;
  }
  return normalized.replace(/\/+$/, '');
}

export function getCdnBaseUrl(): string {
  const explicitUrl = import.meta.env.VITE_CDN_BASE_URL;
  if (explicitUrl) {
    return normalizeCdnBaseUrl(explicitUrl);
  }
  // ...
}
```

### Resolver d'images robuste

**Avant:**
- Ne gérait pas les hostnames sans protocole
- Pattern de détection limité aux URLs `.koomy.app` spécifiques

**Après:**
```typescript
function looksLikeHostnameWithoutProtocol(url: string): boolean {
  return /^[a-z0-9][a-z0-9-]*\.[a-z0-9.-]+\.[a-z]{2,}\//i.test(url);
}

export function resolvePublicObjectUrl(inputPath, debugContext): string {
  // Rule 1: Empty input → ''
  // Rule 2: Already absolute (http/https) → return as-is
  // Rule 3: Looks like hostname without protocol → add https://
  // Rule 4: /objects/public/... → strip /objects, add CDN base
  // Rule 5: /public/... → add CDN base
  // Rule 6: Bundled assets → return as-is
  // Rule 7: Other paths → add CDN base with proper slash
}
```

## Tests de Validation

### Cas testés (console browser ou unit tests) :

| Input | Output attendu | Status |
|-------|----------------|--------|
| `https://cdn-sandbox.koomy.app/public/news/x.png` | identique | ✅ |
| `/objects/public/news/x.png` | `https://cdn-sandbox.koomy.app/public/news/x.png` | ✅ |
| `cdn-sandbox.koomy.app/public/news/x.png` | `https://cdn-sandbox.koomy.app/public/news/x.png` | ✅ |
| `/public/news/x.png` | `https://cdn-sandbox.koomy.app/public/news/x.png` | ✅ |
| `public/news/x.png` | `https://cdn-sandbox.koomy.app/public/news/x.png` | ✅ |

### Validation manuelle (backoffice-sandbox)

1. Ouvrir la console du navigateur
2. Aller dans Actualités → Créer un article
3. Uploader une image
4. Vérifier dans Network :
   - ✅ L'image preview charge une URL qui commence par `https://cdn-sandbox.koomy.app/`
   - ✅ Pas de requête vers `https://backoffice-sandbox.koomy.app/admin/cdn-sandbox...`
5. Publier l'article et vérifier l'affichage dans la liste

### Console de boot (vérification CDN)

```
╔══════════════════════════════════════════════════════════════╗
║                    CDN RESOLVER CONFIG                        ║
╠══════════════════════════════════════════════════════════════╣
║ Hostname:        backoffice-sandbox.koomy.app                ║
║ Is Sandbox:      true                                        ║
║ CDN Configured:  false                                       ║
║ Effective CDN:   https://cdn-sandbox.koomy.app               ║
╠══════════════════════════════════════════════════════════════╣
║ Sample Input:    /objects/public/news/sample.jpg             ║
║ Sample Output:   https://cdn-sandbox.koomy.app/public/news/  ║
╚══════════════════════════════════════════════════════════════╝
```

## Définition de Done

- [x] Dans backoffice-sandbox, une news avec image charge une URL qui commence par `https://cdn-sandbox.koomy.app/`
- [x] Plus aucune requête image vers `https://backoffice-sandbox.koomy.app/admin/cdn-sandbox.koomy.app/...`
- [x] Pas de régression sur prod (même logique avec `cdn.koomy.app`)
- [x] Normalisation de `VITE_CDN_BASE_URL` si fourni sans protocole
- [x] Resolver robuste gérant tous les formats d'entrée
