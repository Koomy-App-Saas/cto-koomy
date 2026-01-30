# P0 NETWORK GUARDS — PREUVES

**Date**: 2026-01-24  
**Environnement**: backoffice-sandbox.koomy.app

---

## 1. GUARDS IMPLÉMENTÉS

### 1.1 validateCommunityId()

**Fichier**: `client/src/api/httpClient.ts`  
**Ligne**: 26-31

```typescript
export function validateCommunityId(communityId: string | undefined | null): string {
  if (!communityId || communityId === 'undefined' || communityId === 'null' || communityId.trim() === '') {
    console.error('[GUARD] validateCommunityId BLOCKED:', { communityId });
    throw new InvalidCommunityIdError(communityId);
  }
  return communityId;
}
```

**Comportement**:
- Bloque si `undefined`, `null`, `"undefined"`, `"null"`, ou chaîne vide
- Throw `InvalidCommunityIdError` avec message clair
- Log console pour debug

### 1.2 validatePath()

**Fichier**: `client/src/api/httpClient.ts`  
**Ligne**: 38-64

```typescript
function validatePath<T>(path: string, traceId: string): ApiResponse<T> | null {
  // Check for double slashes (except in protocol)
  const pathWithoutProtocol = path.replace(/^https?:\/\//, '');
  if (pathWithoutProtocol.includes('//')) {
    console.error('[GUARD] URL contains double slash:', { path, traceId });
    return { ok: false, status: 400, ... };
  }
  
  // Check for /undefined/ or /null/ in path
  if (/\/(undefined|null)\//.test(path) || path.endsWith('/undefined') || path.endsWith('/null')) {
    console.error('[GUARD] URL contains undefined/null:', { path, traceId });
    return { ok: false, status: 400, ... };
  }
  
  return null;
}
```

**Comportement CRITIQUE**:
- Intégré dans `apiFetch()` **APRÈS** `buildUrl(baseUrl, path)` (lignes 105-110)
- Valide l'URL FINALE (pas seulement le path)
- Attrape les double slashes causés par: `baseUrl/` + `/path`
- Bloque AVANT envoi réseau si URL invalide
- Retourne erreur 400 avec message clair

**Ligne exacte d'intégration** (`httpClient.ts:105-110`):
```typescript
const fullUrl = buildUrl(baseUrl, path);

// P0 GUARD: Validate FINAL URL after concatenation
const urlError = validatePath<T>(fullUrl, traceId);
if (urlError) {
  return urlError;
}
```

---

## 2. PREUVES CAPTURES CONSOLE

### 2.1 Test double slash bloqué

```bash
# Simulation: communityId = ""
URL: /api/communities//sections

Console attendu:
[GUARD] URL contains double slash: { path: "/api/communities//sections", traceId: "xxx" }

Réseau: ❌ AUCUNE REQUÊTE (bloqué avant envoi)
```

**Capture à faire en sandbox**:  
⬜ Ouvrir DevTools → Console  
⬜ Clear localStorage communityId  
⬜ Naviguer vers Sections  
⬜ Vérifier log `[GUARD] URL contains double slash`  
⬜ Network tab: 0 requêtes avec `//`

### 2.2 Test undefined bloqué

```bash
# Simulation: communityId = undefined
URL: /api/communities/undefined/sections

Console attendu:
[GUARD] URL contains undefined/null: { path: "/api/communities/undefined/sections", traceId: "xxx" }

Réseau: ❌ AUCUNE REQUÊTE (bloqué avant envoi)
```

---

## 3. PREUVES NETWORK TAB

### Template de validation

| Test | URL testée | Requête envoyée? | Console log | Status |
|------|-----------|------------------|-------------|--------|
| communityId = "" | `/api/communities//sections` | ❌ Non | `[GUARD] double slash` | ⬜ À CAPTURER |
| communityId = undefined | `/api/communities/undefined/sections` | ❌ Non | `[GUARD] undefined/null` | ⬜ À CAPTURER |
| communityId = "uuid-valid" | `/api/communities/abc123/sections` | ✅ Oui | - | ⬜ À CAPTURER |

---

## 4. CRITÈRE DE SUCCÈS

✅ **Network tab = 0 requêtes avec `//` ou `undefined`**

### Vérification

1. Ouvrir backoffice-sandbox.koomy.app
2. Se connecter comme admin
3. Ouvrir DevTools → Network
4. Filtrer par "communities"
5. Naviguer sur toutes les pages admin
6. Vérifier: aucune URL ne contient `//` ni `undefined`

---

**FIN P0_NETWORK_GUARDS**
