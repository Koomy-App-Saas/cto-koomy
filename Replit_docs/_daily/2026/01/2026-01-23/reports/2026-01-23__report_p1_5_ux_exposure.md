# Rapport P1.5 — Exposition UX Server-First

**Date**: 2026-01-23  
**Contrat**: `koomy_contract_ux_trial_free_payant_p1_5_v1.md`  
**Spec**: `koomy_spec_exposure_status_limits_capabilities_p1_5_v1.md`

---

## 1. Cartographie du code existant

### 1.1 Endpoints pré-existants

| Endpoint | Rôle | Limite |
|----------|------|--------|
| `GET /api/communities/:id` | Données community (incl. planId, subscriptionStatus) | Pas de limits/capabilities |
| `GET /api/communities/:id/quota` | `{ canAdd, current, max, planName }` | Membres uniquement |
| `GET /api/billing/status` | Vérifie si Stripe est configuré | Pas le statut community |

### 1.2 Modules existants réutilisés

| Module | Fonctions | Rôle |
|--------|-----------|------|
| `server/lib/planLimits.ts` | `getEffectivePlan()`, `getPlanCapabilities()` | Récupère plan + limits + capabilities |
| `server/lib/usageLimitsGuards.ts` | `getMemberCount()`, `getAdminCount()` | Comptage usage actuel |
| `server/lib/subscriptionGuards.ts` | `MONEY_BLOCKED_STATUSES`, `isMoneyAllowed()` | Logique blocage argent |

### 1.3 Logique "effective state" existante

La fonction `getEffectivePlan()` (ligne 235-272 de `planLimits.ts`) centralise déjà :
- Plan effectif
- Limits (maxMembers, maxAdmins)
- Capabilities du plan
- subscriptionStatus
- isWhiteLabel
- trialEndsAt

**Manquant avant P1.5** : exposition unifiée pour l'UI avec usage actuel + reason pour capabilities désactivées.

---

## 2. Endpoint créé

### `GET /api/communities/:communityId/subscription-state`

**Fichier**: `server/routes.ts` (ligne 4769-4800)  
**Auth**: Requiert token admin/delegate de la communauté  
**Module service**: `server/lib/effectiveStateService.ts`

---

## 3. Couche "Effective State" centralisée

### Fichier créé: `server/lib/effectiveStateService.ts`

**Fonction principale**: `getSubscriptionState(communityId: string)`

**Logique des overrides**:
1. White-label → bypass total (money_allowed=true, toutes capabilities enabled)
2. trialing → money_allowed=false, capabilities argent disabled avec reason="trialing"
3. past_due/canceled → money_allowed=false, capabilities argent disabled avec reason correspondante
4. active → tout enabled selon plan

**Réutilisation**:
- Appelable par l'endpoint d'exposition
- Peut être utilisé par les guards d'enforcement (P1.4, P0.2)

---

## 4. Payload réel (exemples JSON)

### 4.1 Community trialing (7 jours restants, plan PLUS)

```json
{
  "subscription_status": "trialing",
  "plan_code": "plus",
  "plan_name": "Plus",
  "is_white_label": false,
  "trial_days_remaining": 7,
  "trial_ends_at": "2026-01-30T16:00:00.000Z",
  "purge_scheduled_at": null,
  "limits": {
    "members": { "current": 25, "max": 500 },
    "admins": { "current": 2, "max": 3 }
  },
  "capabilities": {
    "qrCard": { "enabled": true },
    "dues": { "enabled": false, "reason": "trialing" },
    "messaging": { "enabled": true },
    "events": { "enabled": true },
    "analytics": { "enabled": true },
    "advancedAnalytics": { "enabled": false, "reason": "plan" },
    "exportData": { "enabled": true },
    "apiAccess": { "enabled": false, "reason": "plan" },
    "multiAdmin": { "enabled": true }
  },
  "money_allowed": false,
  "billing_cta": "activate"
}
```

### 4.2 Community active (plan PRO)

```json
{
  "subscription_status": "active",
  "plan_code": "pro",
  "plan_name": "Pro",
  "is_white_label": false,
  "trial_days_remaining": null,
  "trial_ends_at": null,
  "purge_scheduled_at": null,
  "limits": {
    "members": { "current": 25, "max": 5000 },
    "admins": { "current": 2, "max": 10 }
  },
  "capabilities": {
    "qrCard": { "enabled": true },
    "dues": { "enabled": true },
    "messaging": { "enabled": true },
    "events": { "enabled": true },
    "analytics": { "enabled": true },
    "advancedAnalytics": { "enabled": true },
    "exportData": { "enabled": true },
    "apiAccess": { "enabled": true },
    "multiAdmin": { "enabled": true }
  },
  "money_allowed": true,
  "billing_cta": "manage"
}
```

### 4.3 Community past_due

```json
{
  "subscription_status": "past_due",
  "plan_code": "plus",
  "plan_name": "Plus",
  "is_white_label": false,
  "trial_days_remaining": null,
  "trial_ends_at": null,
  "purge_scheduled_at": null,
  "limits": {
    "members": { "current": 25, "max": 500 },
    "admins": { "current": 2, "max": 3 }
  },
  "capabilities": {
    "qrCard": { "enabled": true },
    "dues": { "enabled": false, "reason": "past_due" },
    "messaging": { "enabled": true },
    "events": { "enabled": true },
    "analytics": { "enabled": true },
    "advancedAnalytics": { "enabled": false, "reason": "plan" },
    "exportData": { "enabled": true },
    "apiAccess": { "enabled": false, "reason": "plan" },
    "multiAdmin": { "enabled": true }
  },
  "money_allowed": false,
  "billing_cta": "reactivate"
}
```

### 4.4 White-label (bypass total)

```json
{
  "subscription_status": "active",
  "plan_code": "whitelabel",
  "plan_name": "Whitelabel",
  "is_white_label": true,
  "trial_days_remaining": null,
  "trial_ends_at": null,
  "purge_scheduled_at": null,
  "limits": {
    "members": { "current": 25, "max": null },
    "admins": { "current": 2, "max": null }
  },
  "capabilities": {
    "qrCard": { "enabled": true },
    "dues": { "enabled": true },
    "messaging": { "enabled": true },
    "events": { "enabled": true },
    "analytics": { "enabled": true },
    "advancedAnalytics": { "enabled": true },
    "exportData": { "enabled": true },
    "apiAccess": { "enabled": true },
    "multiAdmin": { "enabled": true }
  },
  "money_allowed": true,
  "billing_cta": null
}
```

---

## 5. Codes d'erreur et mapping

### 5.1 Codes existants réutilisés

| Code | Source | Utilisation |
|------|--------|-------------|
| `SUBSCRIPTION_NOT_ACTIVE` | `subscriptionGuards.ts:24` | Guard money bloqué |
| `USAGE_LIMIT_EXCEEDED` | `usageLimitsGuards.ts:8` | Limite dépassée |
| `CAPABILITY_NOT_ALLOWED` | `usageLimitsGuards.ts:16` | Capability non disponible |
| `TRIAL_PAYMENTS_DISABLED` | `usageLimitsGuards.ts:23` | Argent bloqué en trial |

### 5.2 Nouveaux codes ajoutés

| Code | Fichier | Contexte |
|------|---------|----------|
| `USER_NOT_FOUND` | `routes.ts:4779` | Endpoint subscription-state |
| `ACCESS_DENIED` | `routes.ts:4788` | Endpoint subscription-state |
| `SUBSCRIPTION_STATE_ERROR` | `routes.ts:4797` | Erreur technique |

---

## 6. Tests

### Fichier: `server/tests/subscription-state.test.ts`

**Résultat**: 28/28 tests passés

**Commande d'exécution**:
```bash
npx vitest run --root . server/tests/subscription-state.test.ts
```

**Catégories de tests**:
1. Structure du payload (7 tests)
2. Trialing community (5 tests)
3. Active subscription (4 tests)
4. past_due subscription (4 tests)
5. canceled subscription (3 tests)
6. White-label bypass (5 tests)

---

## 7. Diff prompt vs réalité

| Aspect prompt | Réalité code | Alignement |
|---------------|--------------|------------|
| subscription_status | `subscription_status` | ✅ |
| plan identifier | `plan_code` + `plan_name` | ✅ |
| limits + current_usage | `limits: { members: { current, max }, admins: { current, max } }` | ✅ |
| capabilities (enabled/disabled + reason) | `capabilities: { [key]: { enabled, reason? } }` | ✅ |
| trial_days_remaining | `trial_days_remaining` (calculé) | ✅ |
| purge_scheduled_at | `purge_scheduled_at` | ✅ |
| CTA billing | `billing_cta: "activate" \| "reactivate" \| "manage" \| null` | ✅ |

**Zéro invention** : Tous les champs proviennent de données existantes (DB + calculs).

---

## 8. Definition of Done

| Critère | Statut |
|---------|--------|
| UI peut afficher statut sans supposer | ✅ `subscription_status` exposé |
| UI peut afficher limites + usage sans calcul local | ✅ `limits.members/admins.current/max` |
| UI peut savoir si capability disabled et pourquoi | ✅ `capabilities.[key].enabled + reason` |
| trial: money disabled, billing accessible | ✅ `money_allowed=false`, `billing_cta="activate"` |
| past_due/canceled: lecture OK, mutations bloquées | ✅ Guards P1.4/P0.2 inchangés |
| Tests passants | ✅ 28/28 |

---

## 9. Fichiers modifiés/créés

| Fichier | Action |
|---------|--------|
| `server/lib/effectiveStateService.ts` | Créé (135 lignes) |
| `server/routes.ts` | Modifié (+32 lignes, import + endpoint) |
| `server/tests/subscription-state.test.ts` | Créé (230 lignes) |

---

**Fin du rapport P1.5.**
