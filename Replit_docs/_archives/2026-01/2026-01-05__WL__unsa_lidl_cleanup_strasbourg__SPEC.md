# Nettoyage Section Strasbourg - UNSA Lidl

## Contexte

Ce script est conçu pour la **livraison du compte UNSA Lidl**. Il supprime les données de démonstration (seed) de la section "Strasbourg" avant la mise en production.

**IMPORTANT**: Ce script est réservé à la livraison UNSA Lidl uniquement.

## Fonctionnement

Le script :
1. Recherche la section nommée "Strasbourg" dans la base de données
2. Identifie tous les membres appartenant à cette section
3. En mode DRY-RUN : affiche un aperçu sans supprimer
4. En mode CONFIRM : supprime les membres et la section

### Dépendances gérées

Le script gère automatiquement les relations :
- `memberTags` : supprimés
- `messages` : supprimés (messages envoyés par ces membres)
- `transactions` : références de membership mises à null (transactions conservées pour audit)
- `userCommunityMemberships` : supprimés
- `sections` : section Strasbourg supprimée

## Exécution

### Mode DRY-RUN (prévisualisation)

```bash
npx tsx script/cleanup-strasbourg.ts
```

Ce mode :
- Ne supprime **rien**
- Affiche l'ID de la section Strasbourg
- Affiche le nombre de membres trouvés
- Affiche un échantillon de 10 membres (id, email, date création)
- Retourne un résumé JSON

### Mode CONFIRM (suppression réelle)

```bash
npx tsx script/cleanup-strasbourg.ts --confirm
```

Ce mode :
- Exécute la suppression dans une **transaction** (atomique)
- Supprime tous les membres de Strasbourg et leurs dépendances
- Supprime la section Strasbourg
- Retourne un résumé JSON des actions effectuées

## Exemple de sortie JSON

### DRY-RUN

```json
{
  "success": true,
  "dryRun": true,
  "sectionId": "abc123",
  "communityId": "unsa-lidl-id",
  "sectionName": "Strasbourg",
  "membersFound": 25,
  "membersSample": [
    {
      "id": "member-1",
      "email": "demo1@example.com",
      "displayName": "Jean Demo",
      "createdAt": "2024-12-01T10:00:00.000Z"
    }
  ],
  "membersDeleted": 0,
  "memberTagsDeleted": 0,
  "messagesDeleted": 0,
  "transactionsUpdated": 0,
  "sectionDeleted": false,
  "errors": [],
  "message": "DRY-RUN complete. Would delete 25 members and 1 section."
}
```

### CONFIRM (après suppression)

```json
{
  "success": true,
  "dryRun": false,
  "sectionId": "abc123",
  "communityId": "unsa-lidl-id",
  "sectionName": "Strasbourg",
  "membersFound": 25,
  "membersSample": [...],
  "membersDeleted": 25,
  "memberTagsDeleted": 25,
  "messagesDeleted": 3,
  "transactionsUpdated": 2,
  "sectionDeleted": true,
  "errors": [],
  "message": "Successfully deleted 25 members and section \"Strasbourg\"."
}
```

## Sécurités

1. **Mode DRY-RUN par défaut** : Sans `--confirm`, rien n'est supprimé
2. **Validation unique** : Erreur si plusieurs sections "Strasbourg" existent
3. **Idempotent** : Si la section n'existe pas, retourne "Already cleaned up"
4. **Transaction atomique** : Tout ou rien, pas d'état partiel
5. **Audit des transactions** : Les transactions sont conservées, seule la référence membership est retirée

## Vérifications post-exécution

Après avoir exécuté `--confirm`, vérifier :

```sql
-- Vérifier que Strasbourg n'existe plus
SELECT * FROM sections WHERE name = 'Strasbourg';
-- Résultat attendu : 0 lignes

-- Vérifier qu'aucun membre n'est dans Strasbourg
SELECT COUNT(*) FROM user_community_memberships WHERE section = 'Strasbourg';
-- Résultat attendu : 0

-- Vérifier que les autres sections sont intactes
SELECT name, COUNT(*) as member_count 
FROM sections s 
LEFT JOIN user_community_memberships m ON m.section = s.name 
WHERE s.community_id = 'UNSA_LIDL_ID'
GROUP BY s.name;
```
