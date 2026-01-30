# P2.2 - Templates de permissions Admin (UI-only)

**Date**: 2026-01-26  
**Objectif**: Ajouter des templates de pré-cochage UI pour la création d'administrateurs

## Résumé

Implémentation complète des templates de permissions pour l'écran "Nouvel Administrateur" :
- 3 templates prédéfinis (UI-only)
- Select dropdown optionnel
- Permission "Paramètres" réservée au propriétaire (disabled)

## Fichiers créés/modifiés

| Fichier | Action | Description |
|---------|--------|-------------|
| `client/src/features/admins/permissionTemplates.ts` | Créé | Définition des 3 templates |
| `client/src/pages/admin/Admins.tsx` | Modifié | Select template + SETTINGS owner-only |
| `client/src/features/admins/__tests__/adminPermissionTemplates.test.ts` | Créé | 7 tests unitaires |

## Templates définis

| ID | Label | Permissions |
|----|-------|-------------|
| `operational_admin` | Administrateur opérationnel | MEMBERS, CONTENT, EVENTS |
| `finance_admin` | Administrateur finances | FINANCE |
| `communication_admin` | Administrateur communication | CONTENT |

## Clés de permissions utilisées (alignement vérifié)

Les clés correspondent exactement à celles du backend (`AdminPermission` type) :
- `MEMBERS` - Gestion des adhérents
- `FINANCE` - Accès données financières
- `CONTENT` - Articles et messages
- `EVENTS` - Gestion événements
- `SETTINGS` - Configuration (owner-only, non-sélectionnable)

## Comportement UI

1. **Sélection template** → Pré-coche les permissions définies
2. **Changement de template** → Écrase la sélection précédente
3. **Retour "Aucun"** → Vide les permissions
4. **Modification manuelle** → Libre après application du template
5. **SETTINGS** → Affiché disabled avec icône Lock et mention "Réservé au propriétaire"

## Tests ajoutés

| Test | Statut |
|------|--------|
| 3 templates présents | ✅ |
| operational_admin permissions correctes | ✅ |
| finance_admin permissions correctes | ✅ |
| communication_admin permissions correctes | ✅ |
| Aucun template ne contient SETTINGS | ✅ |
| getTemplateById retourne le bon template | ✅ |
| getTemplateById retourne undefined si invalide | ✅ |

**Total : 7/7 tests verts**

## Conformité contrat

- [x] UI templates = pré-cochage uniquement
- [x] Pas de champ "rôle" créé
- [x] Aucun templateId envoyé au backend
- [x] SETTINGS owner-only (disabled)
- [x] Aucun fichier server/* modifié
- [x] Matrice contractuelle respectée

## Note explicite

**Aucun backend modifié, templates non persistés.** Le backend reçoit uniquement la liste finale des permissions cochées, sans aucune information sur le template utilisé.
