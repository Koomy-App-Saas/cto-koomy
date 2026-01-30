# Limites de Membres par Plan

**Date de mise à jour** : Décembre 2024

## Nouvelles Limites

| Plan | Code | Limite Membres | Prix |
|------|------|----------------|------|
| Free Starter | STARTER_FREE | 50 | Gratuit |
| Communauté Plus | COMMUNAUTE_STANDARD | 200 | 9,90€/mois |
| Communauté Pro | COMMUNAUTE_PRO | 1 000 | 29€/mois |
| Grand Compte | ENTREPRISE_CUSTOM | Illimité | Sur devis |
| White Label | WHITE_LABEL | Illimité | 4 900€/an |

## Modifications Effectuées

### Fichiers modifiés

1. **`client/src/data/staticPlans.ts`**
   - `growth.maxMembers`: 1000 → 200
   - `scale.maxMembers`: 5000 → 1000
   - Textes features mis à jour

2. **`server/seed.ts`**
   - Mêmes modifications pour les nouveaux déploiements

3. **Base de données `plans`**
   - `max_members` mis à jour pour growth et scale
   - `capabilities.members.max` mis à jour dans le JSON
   - `features` array mis à jour avec les nouveaux textes

## Enforcement Backend

La vérification des limites est effectuée dans `server/storage.ts` :

### Fonction `checkMemberQuota(communityId)`

```typescript
const canAdd = hasFullAccess || max === null || current < max;
```

- Vérifie le plan actif de la communauté
- Compare `memberCount` avec `plan.maxMembers`
- Respecte le mode "Full Access VIP" (illimité si actif)

### Points de contrôle

Tous les chemins de création de membres passent par `storage.createMembership()` qui appelle `checkMemberQuota()` :

- Création membre manuelle (admin)
- Import CSV (via bulk create)
- Création délégué
- Onboarding owner

### Codes d'erreur

| Erreur | Message |
|--------|---------|
| `MemberLimitReachedError` | "Votre communauté a atteint la limite de X membres pour le plan Y. Merci de mettre à niveau votre abonnement." |
| `PlanDowngradeNotAllowedError` | "Impossible de passer au plan X avec Y membres actifs (limite: Z)" |

## Communautés au-dessus des seuils

### Stratégie appliquée

- **Aucune suppression de membres existants**
- **Blocage des nouveaux ajouts uniquement**
- L'UI affiche un warning "Vous dépassez la limite de votre plan"

### Vérifier les communautés concernées

```sql
SELECT 
  c.name,
  c.member_count,
  p.name as plan_name,
  p.max_members
FROM communities c
JOIN plans p ON c.plan_id = p.id
WHERE p.max_members IS NOT NULL 
  AND c.member_count > p.max_members;
```

## Stripe

Les prix Stripe n'ont pas été modifiés. Les Price IDs restent identiques.
La logique de mapping/validation des quotas est gérée côté backend Koomy, pas côté Stripe.
