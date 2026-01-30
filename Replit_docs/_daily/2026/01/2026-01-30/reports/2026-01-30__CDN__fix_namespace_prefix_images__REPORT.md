# RAPPORT D'IMPLÉMENTATION — Fix CDN Namespace Prefix

**Date** : 2026-01-30  
**Domaine** : CDN / Images  
**Type** : Correctif (Bug Fix)  
**Statut** : Complété  
**Environnement cible** : Production (prodv2)

---

## Contexte

### Problème signalé
Les images (logos clubs, avatars users) ne s'affichent pas en production (prodv2).

### Diagnostic

| URL | Status |
|-----|--------|
| `https://cdn-prodv2.koomy.app/public/logos/<uuid>.png` | 404 ❌ |
| `https://cdn-prodv2.koomy.app/koomyprodv2/public/logos/<uuid>.png` | 200 ✅ |

**Cause** : Le bucket R2 prodv2 utilise un namespace prefix `/koomyprodv2` qui n'était pas inclus dans la construction des URLs CDN.

---

## Solution implémentée

### Approche
Fix minimal dans le resolver CDN centralisé, avec configuration via variable d'environnement Vite.

### Modifications

**Fichier** : `client/src/lib/cdnResolver.ts`

#### 1. Nouvelle fonction `getCdnNamespacePrefix()`

```typescript
export function getCdnNamespacePrefix(): string {
  const prefix = import.meta.env.VITE_CDN_NAMESPACE_PREFIX;
  if (!prefix) return '';
  
  // Ensure it starts with / but doesn't end with /
  let normalized = prefix.trim();
  if (!normalized.startsWith('/')) {
    normalized = `/${normalized}`;
  }
  normalized = normalized.replace(/\/+$/, '');
  
  return normalized;
}
```

#### 2. Modification de `resolvePublicObjectUrl()`

**Avant** :
```typescript
const resolvedUrl = `${cdnBase}/${normalizedPath}`;
```

**Après** :
```typescript
const namespacePrefix = getCdnNamespacePrefix();
const resolvedUrl = `${cdnBase}${namespacePrefix}/${normalizedPath}`;
```

#### 3. Mise à jour des diagnostics boot

Ajout de l'affichage du namespace prefix dans les logs de démarrage.

---

## Configuration requise

### Variable d'environnement (PROD uniquement)

```env
VITE_CDN_NAMESPACE_PREFIX=/koomyprodv2
```

### Comportement

| VITE_CDN_NAMESPACE_PREFIX | URL générée |
|---------------------------|-------------|
| (non défini) | `https://cdn-prodv2.koomy.app/public/logos/xxx.png` |
| `/koomyprodv2` | `https://cdn-prodv2.koomy.app/koomyprodv2/public/logos/xxx.png` |

**Rétrocompatibilité** : Si la variable n'est pas définie, le comportement est inchangé.

---

## Fichiers modifiés

| Fichier | Description |
|---------|-------------|
| `client/src/lib/cdnResolver.ts` | Ajout `getCdnNamespacePrefix()` + intégration dans résolution URLs |

---

## Tests de validation

### A) Avant déploiement (sandbox)
1. Vérifier que l'app compile sans erreur
2. Vérifier les logs CDN boot (doivent afficher `Namespace Pfx: (none)`)
3. Vérifier qu'une image existante s'affiche toujours

### B) Après déploiement (prod)
1. Ajouter `VITE_CDN_NAMESPACE_PREFIX=/koomyprodv2` dans les env vars front prod
2. Redéployer
3. Ouvrir backoffice prod, vérifier une image (logo communauté)
4. Network tab : URL doit être `.../koomyprodv2/public/logos/...` → 200
5. Vérifier avatar utilisateur → 200

### C) Upload nouveau logo
1. Uploader un nouveau logo dans settings communauté
2. Vérifier affichage immédiat
3. Rafraîchir la page → logo toujours visible

---

## Rollback

En cas de régression :

1. **Option rapide** : Supprimer `VITE_CDN_NAMESPACE_PREFIX` des env vars front et redéployer
2. **Option complète** : Revert du commit

---

## Analyse technique

### Flow de résolution d'image

```
┌─────────────────────────────────────────────────────────────────┐
│ Composant (AdminLayout, MemberDetails, etc.)                    │
│                                                                  │
│ <img src={resolvePublicObjectUrl(community.logo)} />            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ community.logo = "/objects/public/logos/xxx.png"
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ resolvePublicObjectUrl()                                        │
│                                                                  │
│ 1. Strip /objects prefix → "public/logos/xxx.png"               │
│ 2. Get cdnBase → "https://cdn-prodv2.koomy.app"                 │
│ 3. Get namespacePrefix → "/koomyprodv2"                         │
│ 4. Build URL → "https://cdn-prodv2.koomy.app/koomyprodv2/       │
│                 public/logos/xxx.png"                           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ CDN (R2 bucket)                                                  │
│                                                                  │
│ Object key: koomyprodv2/public/logos/xxx.png → 200 ✅            │
└─────────────────────────────────────────────────────────────────┘
```

### Composants impactés (utilisant le resolver)

Tous les composants qui affichent des images utilisent déjà le resolver centralisé :
- `AdminLayout` (logo sidebar)
- `MobileLayout` (logo header)
- `MemberDetails` (avatar)
- `PersonalInfo` (avatar)
- `News`, `NewsDetail` (images articles)
- `MiniMembershipCard` (logo communauté)
- etc.

Aucune modification nécessaire dans ces composants.

---

## Checklist de clôture

- [x] Diagnostic effectué
- [x] Fix minimal implémenté
- [x] Rétrocompatibilité vérifiée (absence de env var = comportement inchangé)
- [x] Code review architecte : PASS
- [x] Compilation sandbox OK
- [ ] Configuration env var PROD
- [ ] Déploiement PROD
- [ ] Tests visuels PROD

---

## Prochaines étapes

1. **Ajouter la variable d'environnement en PROD** :
   ```
   VITE_CDN_NAMESPACE_PREFIX=/koomyprodv2
   ```

2. **Redéployer le front PROD**

3. **Valider les images** sur backoffice prod
