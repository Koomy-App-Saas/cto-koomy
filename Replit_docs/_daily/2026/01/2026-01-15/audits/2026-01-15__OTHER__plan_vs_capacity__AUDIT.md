# KOOMY - Audit Plan vs Capacité

**Date**: 19 janvier 2026  
**Périmètre**: Gestion des plans, limites d'adhérents, flux upgrade

---

## 1. Où est stocké le plan ?

| Question | Réponse |
|----------|---------|
| `planId` en base ? | **OUI** - Colonne `planId` dans table `communities` (FK vers `plans.id`) |
| Calculé dynamiquement ? | **NON** |
| Recalculé selon nombre d'adhérents ? | **NON** |

**Localisation exacte**:
- `shared/schema.ts` ligne 274: `planId: varchar("plan_id", { length: 50 }).references(() => plans.id).notNull()`
- Le plan est un champ statique, modifié uniquement par appel API explicite

---

## 2. Où sont définies les limites ?

| Source | Type | Localisation |
|--------|------|--------------|
| `shared/plans.ts` | Constantes TypeScript | `KOOMY_PLANS` (lignes 24-255) |
| Table `plans` | Base de données | Colonnes `max_members`, `max_admins` |
| `storage.checkMemberQuota()` | Logique conditionnelle | `server/storage.ts` (lignes 581-630) |

**Définition des limites par plan** (source: `shared/plans.ts`):

| Plan | maxMembers | maxAdmins |
|------|------------|-----------|
| FREE | 20 | 1 |
| PLUS | 300 | null (illimité) |
| PRO | 1000 | null (illimité) |
| GRAND_COMPTE | null (illimité) | null (illimité) |

**Exception GRAND_COMPTE**: La limite est définie par `community.contractMemberLimit` (contrat individuel).

---

## 3. Cas upgrade FREE → PLUS - Flux exact

### 3.1 UI (Frontend)

**Fichier**: `client/src/pages/admin/Billing.tsx`

```
Clic sur plan PLUS
→ handlePlanClick(plan)
→ setShowUpgradeDialog(true) (si newSortOrder > currentSortOrder)
→ handleConfirmChange()
→ changePlanMutation.mutate(selectedPlan.id)
```

**Mutation** (lignes 76-96):
```
authPatch(`/api/communities/${communityId}/plan`, { planId: newPlanId })
```

### 3.2 API (Backend)

**Fichier**: `server/routes.ts` ligne 2977

```
app.patch("/api/communities/:id/plan", async (req, res) => {
  const { planId } = req.body;
  const community = await storage.changeCommunityPlan(req.params.id, planId);
  return res.json(community);
});
```

### 3.3 Storage (Logique métier)

**Fichier**: `server/storage.ts` ligne 554

```
async changeCommunityPlan(communityId: string, newPlanId: string): Promise<Community> {
  // 1. Récupère community et nouveau plan
  // 2. Vérifie si downgrade possible (memberCount <= newPlan.maxMembers)
  // 3. UPDATE communities SET planId = newPlanId
  return updated;
}
```

### 3.4 Base de données

```sql
UPDATE communities SET plan_id = 'plus' WHERE id = :communityId
```

### 3.5 Stripe

| Attendu | Réel |
|---------|------|
| Création Checkout Session | **AUCUN APPEL** |
| Vérification paiement | **AUCUN** |
| Webhook confirmation | **AUCUN** |

### 3.6 Décision "upgrade validé"

**Localisation**: `server/storage.ts` ligne 568

La décision est prise ici:
```typescript
if (newPlan.maxMembers !== null && memberCount > newPlan.maxMembers) {
  throw new PlanDowngradeNotAllowedError(...);
}
// Sinon → upgrade validé automatiquement
```

**Critère unique**: Le nombre de membres actuel doit être inférieur à la limite du nouveau plan.

---

## 4. Logique erronée identifiée

| Question | Réponse |
|----------|---------|
| Le plan est-il déduit du nombre d'adhérents ? | **NON** - Le plan est un état contractuel (champ DB) |
| Le plan est-il un état contractuel ? | **OUI** - Mais modifiable sans paiement |

**Contradiction fondamentale**:

Le plan est stocké comme un état contractuel (impliquant un engagement), mais le code permet de le modifier sans déclencher de paiement Stripe.

La vérification `memberCount <= newPlan.maxMembers` n'est appliquée que pour les **downgrades** (passage à un plan inférieur), jamais pour les **upgrades**.

---

## 5. Écart Attendu vs Réel

| Élément | Attendu | Réel |
|---------|---------|------|
| **Plan** | Contrat payé (engagement commercial lié à un paiement) | Champ DB modifiable sans paiement via PATCH API |
| **Upgrade** | Paiement requis avant activation | Validation directe sans aucun appel Stripe |
| **Limite** | Droit associé au plan (capacité achetée) | Critère de classement pour refuser les downgrades uniquement |
| **Downgrade** | Remboursement prorata ou fin de période | Refusé si memberCount > newPlan.maxMembers (aucune logique financière) |

---

## Synthèse

Le système actuel traite le plan comme un **paramètre de capacité** (combien de membres puis-je avoir) plutôt que comme un **contrat commercial** (quel abonnement ai-je payé).

Conséquences:
1. Un utilisateur FREE peut passer à PLUS sans payer
2. L'upgrade est instantané et effectif immédiatement
3. Stripe n'est pas notifié du changement de plan
4. Aucun abonnement Stripe n'est créé ou modifié
5. Les limites servent uniquement à bloquer les downgrades

---

## Fichiers clés analysés

| Fichier | Rôle |
|---------|------|
| `shared/plans.ts` | Définition des plans et limites (constantes) |
| `shared/schema.ts` | Schéma DB avec `planId` sur communities |
| `server/routes.ts` ligne 2977 | Route PATCH /plan |
| `server/storage.ts` ligne 554 | Fonction changeCommunityPlan |
| `client/src/pages/admin/Billing.tsx` | UI de changement de plan |
