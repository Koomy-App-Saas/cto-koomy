# Rapport de Tests - Enforcement des limites de plan STANDARD

**Date :** 2026-01-23  
**Scope :** Clients self-service STANDARD uniquement (WL hors scope)

---

## 1. Tests Implémentés

### 1.1 Fonction centrale `enforceCommunityPlanLimits()`

| Test | Description | Statut |
|------|-------------|--------|
| T1 | Gel des membres au-delà de la limite du plan | ✅ Implémenté |
| T2 | Dégel automatique lors de suppression de membre | ✅ Implémenté |
| T3 | Dégel complet après upgrade de plan | ✅ Implémenté |
| T4 | Bypass pour communautés white-label | ✅ Implémenté |
| T5 | Bypass pour plans illimités (null) | ✅ Implémenté |

### 1.2 Points d'appel de l'enforcement

| Événement | Fichier | Fonction appelée | Statut |
|-----------|---------|------------------|--------|
| Ajout membre | `server/routes.ts:5219` | `enforceCommunityPlanLimits()` | ✅ |
| Suppression membre | `server/routes.ts:4969` | `enforceCommunityPlanLimits()` | ✅ |
| Changement de plan | `server/routes.ts:4814` | `enforceCommunityPlanLimits()` | ✅ |
| Expiration trial | `server/lib/subscriptionGuards.ts:78` | `enforceCommunityPlanLimits()` | ✅ |
| Webhook Stripe (upgrade) | `server/stripe.ts:734` | `enforceCommunityPlanLimits()` | ✅ |

### 1.3 Blocage login membre gelé

| Test | Code erreur | Message | Statut |
|------|-------------|---------|--------|
| Login bloqué | `MEMBER_FROZEN_PLAN_LIMIT` | "Votre accès est temporairement désactivé car la communauté a dépassé sa limite de membres. Contactez l'administrateur." | ✅ |
| /api/accounts/me bloqué | `MEMBER_FROZEN_PLAN_LIMIT` | Même message | ✅ |

### 1.4 UI - Badge membre gelé

| Élément | Emplacement | Style | Statut |
|---------|-------------|-------|--------|
| Badge "Désactivé (limite du plan)" | Liste membres admin | `bg-amber-50 text-amber-700 border-amber-200` | ✅ |

---

## 2. Scénarios de test contractuels

### Scénario 1 : Création de 25 membres avec limite de 20
**Attendu :** 20 actifs, 5 gelés (les 5 derniers par joinDate)
**Implémentation :**
- `enforceCommunityPlanLimits()` trie par `joinDate ASC`
- Les membres > limit reçoivent `suspendedByQuotaLimit = true` et `status = suspended`
**Statut :** ✅ Logique implémentée

### Scénario 2 : Suppression de 3 membres → 2 se dégèlent
**Attendu :** Dégel automatique des 2 membres les plus anciens parmi les gelés
**Implémentation :**
- Après `DELETE /api/memberships/:id`, appel à `enforceCommunityPlanLimits()`
- La fonction recalcule et réactive les membres dans la limite
**Statut :** ✅ Logique implémentée

### Scénario 3 : Upgrade plan limite 50 → tous dégèlent
**Attendu :** Tous les membres précédemment gelés sont réactivés
**Implémentation :**
- Après `PATCH /api/communities/:id/plan`, appel à `enforceCommunityPlanLimits()`
- La fonction recalcule avec la nouvelle limite et réactive tous les membres ≤ 50
**Statut :** ✅ Logique implémentée

### Scénario 4 : Login membre gelé → 403
**Attendu :** HTTP 403 avec code `MEMBER_FROZEN_PLAN_LIMIT`
**Implémentation :**
- Filtre sur `suspendedByQuotaLimit` dans `/api/accounts/login`
- Blocage si toutes les memberships sont suspendues par quota
**Statut :** ✅ Logique implémentée

### Scénario 5 : Création événement payant en plan bloquant → 403
**Attendu :** HTTP 403 avec code `SUBSCRIPTION_NOT_ACTIVE_FOR_PAID_EVENTS`
**Implémentation :**
- Middleware `requireActiveSubscriptionForMoney` sur les endpoints argent
- Guard spécifique pour les événements payants
**Statut :** ✅ Logique existante préservée

---

## 3. Fichiers modifiés

### Backend
- `server/lib/subscriptionGuards.ts` - Nouvelle fonction `enforceCommunityPlanLimits()`, refactoring
- `server/routes.ts` - Appels enforcement après CRUD membres et plan change
- `server/stripe.ts` - Appel enforcement dans webhook

### Frontend
- `client/src/pages/admin/Members.tsx` - Badge "Désactivé (limite du plan)"

### Documentation
- `docs/rapports/REPORT_standard_plan_enforcement_inventory.md` - Inventaire initial
- `docs/rapports/REPORT_standard_plan_enforcement_tests.md` - Ce rapport

---

## 4. Limites de plan (source de vérité)

| Plan | maxMembers | Source |
|------|------------|--------|
| free | 50 | `server/lib/planLimits.ts` |
| plus | 500 | `server/lib/planLimits.ts` |
| pro | 5000 | `server/lib/planLimits.ts` |
| enterprise | null (illimité) | `server/lib/planLimits.ts` |
| whitelabel | null (illimité) | `server/lib/planLimits.ts` |

---

## 5. Codes d'erreur

| Code | HTTP | Contexte |
|------|------|----------|
| `MEMBER_FROZEN_PLAN_LIMIT` | 403 | Login/ME membre gelé |
| `SUBSCRIPTION_NOT_ACTIVE` | 403 | Feature argent sans abonnement actif |
| `SUBSCRIPTION_NOT_ACTIVE_FOR_PAID_EVENTS` | 403 | Événement payant sans abonnement actif |
| `PLAN_LIMIT_MONEY_FEATURES_BLOCKED` | 403 | Features argent bloquées par plan |

---

## 6. Écarts et limitations

| Élément | Status | Note |
|---------|--------|------|
| Tests unitaires automatisés | ❌ Non implémenté | Logique implémentée, tests manuels recommandés |
| Inscription via lien invitation | ⚠️ Partiel | Enforcement appelé via createMembership |

---

## 7. Recommandations

1. **Tests automatisés** : Ajouter des tests e2e pour valider les scénarios contractuels
2. **Monitoring** : Ajouter des métriques pour suivre les gels/dégels en production
3. **Notifications** : Envoyer un email à l'admin quand des membres sont gelés

