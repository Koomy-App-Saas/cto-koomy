# Suppression de la fonctionnalité "Promotion Banner"

**Date de suppression :** 6 janvier 2026  
**Décision :** Suppression définitive, sans remplacement

## Contexte

La fonctionnalité **Promotion** permettait d'afficher des bannières promotionnelles :
- Sur l'écran d'accueil de l'application membre (`HOME_TOP`)
- En bas des articles d'actualités (`ARTICLE_BOTTOM`)

Objectif initial : mettre en avant une promotion, une actualité ou un message (idée venue lors du travail sur Lagny).

## Raisons de la suppression

Après analyse produit, cette fonctionnalité a été identifiée comme une **fausse bonne idée** :
- Elle alourdissait l'UI
- Elle brouillait le message principal
- Elle détournait Koomy de son objectif (gestion de communauté, pas vitrine marketing)
- Elle créait de la complexité inutile (gestion d'état, affichage conditionnel, support)

## Éléments supprimés

### Frontend

| Fichier | Description |
|---------|-------------|
| `client/src/components/PromotionBanner.tsx` | Composant de bannière promotionnelle |
| `client/src/pages/admin/Promotions.tsx` | Page admin web de gestion |
| `client/src/pages/mobile/admin/Promotions.tsx` | Page admin mobile de gestion |

**Références nettoyées :**
- `client/src/App.tsx` - Imports et routes supprimés
- `client/src/pages/mobile/Home.tsx` - Bannière HOME_TOP retirée
- `client/src/pages/mobile/NewsDetail.tsx` - Bannière ARTICLE_BOTTOM retirée
- `client/src/components/layouts/AdminLayout.tsx` - Menu admin retiré
- `client/src/components/MobileAdminLayout.tsx` - Menu admin mobile retiré

### Backend

| Fichier | Description |
|---------|-------------|
| `server/routes.ts` | 6 endpoints API supprimés (`/api/communities/:id/promotions/*`, `/api/promotions/:id/*`) |
| `server/storage.ts` | 7 méthodes de stockage supprimées |

### Base de données

| Élément | Description |
|---------|-------------|
| Table `community_promotions` | Table de stockage des bannières |
| Enum `promotion_placement` | Valeurs HOME_TOP, ARTICLE_BOTTOM |
| Relations Drizzle | `communityPromotionsRelations` supprimé |

### Plans et capacités

| Fichier | Modification |
|---------|--------------|
| `shared/schema.ts` | Propriété `privatePromotions` supprimée du type `PlanCapabilities` |
| `shared/plans.ts` | Capability `privatePromotions` retirée des 4 plans officiels |

### Configuration mobile

| Fichier | Modification |
|---------|--------------|
| `packages/mobile-build/schema.mjs` | Feature `promotions` supprimée du schéma et des défauts |
| `tenants/unsa-lidl/features.ts` | Feature `promotions` supprimée |
| `docs/architecture.md` | Référence supprimée des DEFAULT_FEATURES |

### Documentation

**Fichiers nettoyés :**
- `docs/API_KOOMY_REFERENCE.md` - Section API Promotions supprimée
- `docs/FONCTIONNALITES_INCOMPLETES.md` - Référence Promotions.tsx supprimée
- `docs/architecture.md` - Feature promotions retirée
- `docs/enterprise-accounts.md` - Exemple hasPromotionsCapability remplacé

## Données en production

Aucune donnée métier critique impactée. La table `community_promotions` était faiblement utilisée et peut être supprimée sans migration de données.

## Vérifications post-suppression

- [ ] Aucun affichage de bannière sur l'écran d'accueil
- [ ] Aucun affichage de bannière dans les articles
- [ ] Aucun menu "Promotions" ou "Bannières" dans le back-office
- [ ] Aucun appel réseau lié à `/promotions`
- [ ] Build TypeScript OK (pas d'erreurs de compilation)
- [ ] Application plus claire et plus rapide

## Notes

Cette fonctionnalité est considérée comme **abandonnée définitivement**.
