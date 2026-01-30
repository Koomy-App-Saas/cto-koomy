# UI — Hide Tags Tab in Back Office

## Résumé

Masquage de l'onglet **Tags** dans le menu du Back Office via feature flag.

## Ce qui a été masqué

| Élément | Fichier | Action |
|---------|---------|--------|
| Menu item "Tags" (Web) | `client/src/components/layouts/AdminLayout.tsx` | Conditionné par feature flag |
| Menu item "Tags" (Mobile) | `client/src/components/MobileAdminLayout.tsx` | Conditionné par feature flag |
| Lien "Créer des tags" | `client/src/pages/admin/Members.tsx` | Conditionné par feature flag |

## Où est le flag

**Fichier:** `client/src/lib/featureFlags.ts`

```typescript
export const FEATURE_FLAGS = {
  TAGS_ENABLED: false,  // ← Toggle ici
} as const;
```

## Comment réactiver

```typescript
// Dans client/src/lib/featureFlags.ts
TAGS_ENABLED: true,
```

## Fichiers modifiés

| Fichier | Changement |
|---------|------------|
| `client/src/lib/featureFlags.ts` | Nouveau fichier - flags centralisés |
| `client/src/components/layouts/AdminLayout.tsx` | Import flag + condition sur menu item |
| `client/src/components/MobileAdminLayout.tsx` | Import flag + condition sur menu item mobile |
| `client/src/pages/admin/Members.tsx` | Import flag + condition sur lien "Créer des tags" |

## Tests de validation

- [x] Back Office : le menu ne montre plus "Tags"
- [x] Navigation : aucun lien mort
- [x] Build : workflow démarre sans erreur

## Notes

- Le code Tags n'a pas été supprimé
- La feature est **gelée**, pas supprimée
- Réactivation possible en 1 ligne

FIN
