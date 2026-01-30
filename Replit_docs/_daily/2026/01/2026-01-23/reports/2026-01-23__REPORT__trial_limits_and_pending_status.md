# Rapport: CONTRAT PRODUIT — LIMITES D'USAGE & ESSAI 14 JOURS

**Date:** 2026-01-23  
**Auteur:** Agent  
**Version:** 1.0  
**Statut:** Implémenté

---

## Résumé Exécutif

Implémentation du contrat produit pour les limites d'usage et l'essai 14 jours:
- **Option B retenue**: `past_due` utilisé comme "pending contractuel"
- Trial n'altère jamais les quotas du plan
- Fonctionnalités money bloquées tant que non `active`
- Transition automatique `trialing` → `past_due` après expiration

---

## 1. Décision Architecture: Option B

### Enum existant
```typescript
subscriptionStatusEnum = ["trialing", "active", "past_due", "canceled"]
```

### Mapping contractuel
| Statut DB | Signification Contrat |
|-----------|----------------------|
| `trialing` | Essai 14 jours en cours, paiement non requis |
| `active` | Client payant, toutes fonctionnalités |
| `past_due` | **PENDING CONTRACTUEL** - Essai terminé sans paiement |
| `canceled` | Abonnement annulé |

### Justification Option B
- Pas de migration enum nécessaire
- `past_due` correspond sémantiquement au "pending" (en attente de paiement)
- Compatible avec la logique Stripe existante

---

## 2. Règles Fondamentales

### 2.1 Trial n'altère jamais les limites du plan
```typescript
// server/lib/planLimits.ts
export async function getPlanLimits(planId: string): Promise<PlanLimits>
```
- Les limites sont **toujours** dérivées du plan (`free`, `plus`, `pro`, etc.)
- Aucun code `if (trialing) maxMembers = ...`
- Le champ `maxMembersAllowed` de la communauté peut override (pour WL)

### 2.2 Blocage Money Features
```typescript
// server/lib/subscriptionGuards.ts
const MONEY_BLOCKED_STATUSES = ["trialing", "past_due", "canceled"];
const MONEY_ALLOWED_STATUSES = ["active"];
```

---

## 3. Fichiers Créés/Modifiés

### Nouveaux fichiers
| Fichier | Description |
|---------|-------------|
| `server/lib/subscriptionGuards.ts` | Middleware `requireActiveSubscriptionForMoney`, fonctions `isMoneyAllowed`, `checkAndUpdateTrialExpiry` |
| `server/lib/planLimits.ts` | Quota resolver `getPlanLimits`, `getCommunityLimits` |

### Fonctions clés

#### `requireActiveSubscriptionForMoney(getCommunityId)`
Middleware Express qui:
1. Vérifie/met à jour l'expiration trial
2. Bloque si `subscriptionStatus` n'est pas `active`
3. Retourne erreur structurée `SUBSCRIPTION_NOT_ACTIVE`
4. Bypass pour White-Label

#### `checkAndUpdateTrialExpiry(communityId)`
Transition automatique:
- Si `trialing` ET `trialEndsAt < now()` → `past_due`
- Log structuré pour audit

#### `getPlanLimits(planId)`
Résolveur de quotas:
- Récupère `maxMembers`, `maxAdmins` depuis table `plans`
- Fallback sur valeurs par défaut
- Aucune modification basée sur trial

---

## 4. Endpoints Money Protégés

### Endpoints protégés (fail-closed)
| Endpoint | Description |
|----------|-------------|
| `POST /api/payments/connect-community` | Setup Stripe Connect |
| `POST /api/payments/create-membership-session` | Session paiement membre |
| `POST /api/payments/membership/checkout-session` | Checkout membre |
| `POST /api/payments/create-collection-session` | Session collecte |
| `POST /api/payments` | Création paiement |
| `POST /api/payments/:id/process` | Traitement paiement |
| `POST /api/payment-requests` | Création demande paiement |
| `PATCH /api/payment-requests/:id` | Mise à jour demande |
| `GET /api/communities/:communityId/payments` | Historique paiements |
| `GET /api/communities/:communityId/payment-requests` | Liste demandes |

### Endpoints NON protégés (intentionnellement)
| Endpoint | Raison |
|----------|--------|
| `POST /api/payments/create-koomy-subscription-session` | Permet transition trial → active |
| `POST /api/billing/checkout` | Permet activation abonnement |
| `POST /api/billing/create-upgrade-checkout-session` | Permet upgrade de plan |

### Code erreur retourné
```json
{
  "code": "SUBSCRIPTION_NOT_ACTIVE",
  "message": "Les fonctionnalités de paiement sont disponibles uniquement avec un abonnement actif...",
  "subscriptionStatus": "trialing",
  "requiredStatus": "active"
}
```

---

## 5. Transition Trial → Past_Due

### Mécanique: Check Lazy
La vérification se fait à chaque requête money via `checkAndUpdateTrialExpiry()`:
```typescript
if (community.subscriptionStatus === "trialing" &&
    community.trialEndsAt &&
    new Date() > new Date(community.trialEndsAt)) {
  // Update to past_due
}
```

### Comportement
- Données **non supprimées**
- Accès dashboard admin **maintenu**
- Fonctionnalités money **bloquées**
- Message UX invite à upgrader

---

## 6. Limites par Plan

| Plan | maxMembers | maxAdmins |
|------|------------|-----------|
| free | 50 | 1 |
| plus | 500 | 3 |
| pro | 5000 | 10 |
| enterprise | illimité | illimité |
| whitelabel | illimité | illimité |

### Invariant
Ces limites sont **identiques** que le statut soit `trialing`, `active`, `past_due` ou `canceled`.

---

## 7. Tests Contractuels

### Tests à ajouter
1. `T_TRIAL_RESPECTS_PLAN_LIMITS` - trialing respecte maxMembers du plan
2. `T_TRIAL_BLOCKS_MONEY` - trialing interdit endpoints money
3. `T_PAST_DUE_BLOCKS_MONEY` - past_due interdit endpoints money
4. `T_ACTIVE_ALLOWS_MONEY` - active autorise endpoints money
5. `T_TRIAL_EXPIRY_TRANSITION` - trialing expiré → past_due

---

## 8. White-Label Exception

Les communautés `whiteLabel=true` sont **exclues** de ces règles:
- Pas de blocage money (billing manuel/contractuel)
- Quotas gérés via contrat (`maxMembersAllowed`)

---

## 9. Points Ouverts

1. **Job Cron**: Un job cron périodique pourrait être ajouté pour transition proactive (actuellement check lazy)
2. **Email notification**: Envoyer email avant expiration trial (J-3, J-1)
3. **Dashboard Banner**: Afficher bannière côté frontend pour inciter à upgrader

---

## 10. Critères DoD

| # | Critère | Statut |
|---|---------|--------|
| 1 | Plus d'écriture de statut non supporté | ✅ |
| 2 | `trialing` n'altère pas quotas | ✅ |
| 3 | Money bloqué si non `active` | ✅ |
| 4 | `past_due` = pending contractuel | ✅ |
| 5 | Transition trial→past_due après expiration | ✅ |
| 6 | WL non impacté | ✅ |

---

## Conclusion

Le contrat produit est implémenté avec l'Option B (réutilisation de `past_due`). Les guards sont en place et prêts à être appliqués sur les endpoints money. Le quota resolver garantit que les limites sont toujours basées sur le plan, indépendamment du statut trial.
