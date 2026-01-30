# Suppression "Gestion des délégués" de la webapp mobile admin

**Date:** 2026-01-28  
**Type:** Retrait fonctionnalité frontend  
**Impact:** Webapp mobile admin uniquement

## Décision Produit

La fonctionnalité "Gestion des délégués/admins" est retirée de la webapp mobile admin.
Toute l'administration (gestion des admins, rôles, privilèges) se fait désormais **uniquement dans le Back-Office**.

**Raison:** Complexité trop élevée pour le lancement, nécessite une gestion fine des privilèges.

## Fichiers modifiés

### `client/src/pages/mobile/admin/Settings.tsx`
- **Avant:** ~400 lignes avec gestion complète des délégués
- **Après:** ~70 lignes, uniquement 3 options

**Code retiré:**
- États: `showDelegates`, `showAddDelegate`, `editingDelegate`, `newDelegateEmail`, `newDelegateName`
- Query: `/api/communities/${communityId}/memberships`
- Mutations: `updatePermissionsMutation`, `addDelegateMutation`, `removeDelegateMutation`
- Composants: Écran liste délégués, écran ajout délégué, écran édition permissions
- Entrée menu "Gestion des délégués"

**Imports supprimés:**
- `useState`, `useQuery`, `useMutation`, `useQueryClient`
- Icônes: `Users`, `X`, `Plus`, `Newspaper`, `Calendar`, `Wallet`, `MessageSquare`, `UserCog`, `Trash2`, `Shield`
- Composants: `Input`, `Switch`, `Badge`, `Avatar`, `AvatarFallback`, `toast`
- Types: `UserCommunityMembership`
- Constante: `PERMISSION_LABELS`

## Fonctionnalités conservées

L'écran Paramètres mobile admin contient maintenant uniquement:
1. ✅ Scanner QR Code
2. ✅ Accéder au Back-Office
3. ✅ Déconnexion

## Points testés

- [x] Webapp mobile admin → Paramètres: aucune mention de "Gestion des délégués"
- [x] Scanner QR Code accessible
- [x] "Accéder au Back-Office" fonctionne
- [x] Déconnexion OK
- [x] Palette de couleurs inchangée

## Notes

Les références au type `DelegatePermissions` dans d'autres fichiers sont conservées car:
- C'est un type backend utilisé pour le système de permissions
- Il est nécessaire pour le contrôle d'accès aux fonctionnalités (articles, événements, etc.)

Les mentions de "délégué" dans la webapp membre (`Messages.tsx`, `WhiteLabelLogin.tsx`) sont conservées car:
- Elles concernent le contact avec les délégués côté membre
- Elles ne font pas partie de l'administration

## Backend

Aucune modification backend. Les API de gestion des délégués restent disponibles pour le Back-Office.
