# Cleanup Member Quota from Contract Tab - Implementation Report

**Date**: 2026-01-30  
**Domain**: SAAS_OWNER  
**Type**: UX Cleanup  

## Contexte

Dans la modal "Configuration White Label" (SaaS Owner), il existait une confusion entre :
- **Onglet Quotas** : section "Quota Membres (Grand Compte / Enterprise)" avec maxMembers default + override contractuel
- **Onglet Contract** : section "Quota membres (contrat WL)" avec membres inclus / seuil d'alerte / supplément/membre

Cette duplication créait de la confusion pour les utilisateurs commerciaux.

## Décision produit

- **Onglet Quotas** = limites opérationnelles (admins, membres) → SOURCE UNIQUE
- **Onglet Contract** = frais setup, maintenance, statut, échéances → PAS de quotas membres

## Changements effectués

### Fichiers modifiés

1. `client/src/pages/platform/SuperDashboard.tsx`

### Sections supprimées

1. **Section "Quota membres (contrat WL)"** dans l'onglet Contract
   - Champ "Membres inclus" (`wlIncludedMembers`)
   - Champ "Seuil d'alerte" (`wlSoftLimit`)
   - Champ "Supplément/membre" (`wlAdditionalFeePerMember`)
   - Texte explicatif

2. **Lignes du "Résumé contrat"** mentionnant les quotas membres WL
   - "Quota membres WL: X membres"
   - "Supplément/membre: X €"

### Ce qui reste

- **Onglet Quotas** contient :
  - "Quota Administrateurs" (inchangé)
  - "Quota Membres (Grand Compte / Enterprise)" (inchangé)

- **Onglet Contract** contient :
  - Frais de setup
  - Maintenance annuelle
  - Mode de facturation
  - Statut maintenance
  - Prochaine échéance
  - Résumé contrat (sans mention des quotas membres)

### Variables d'état conservées

Les variables suivantes sont conservées car elles peuvent être utilisées pour d'autres fonctionnalités futures ou dans le payload d'enregistrement :
- `wlIncludedMembers`
- `wlSoftLimit`
- `wlAdditionalFeePerMember`

Ces valeurs ne sont plus affichées/éditables dans l'UI Contract mais restent dans le modèle de données pour compatibilité.

## Backend

Aucun changement requis. Les endpoints existants restent compatibles.

## Tests manuels effectués

1. ✅ Ouvrir SaaS Owner → client WL → modal "Configuration White Label"
2. ✅ Onglet **Quotas** : présence de "Quota Admins" et "Quota Membres (Grand Compte / Enterprise)"
3. ✅ Onglet **Contract** : absence de "Quota membres (contrat WL)"
4. ✅ "Résumé contrat" ne contient plus de référence aux quotas membres WL
5. ✅ Application compile sans erreurs

## État final

- UX simplifiée : une seule source pour les quotas membres (onglet Quotas)
- Onglet Contract recentré sur les aspects financiers/contractuels
- Pas de perte de données (les champs DB restent intacts)
