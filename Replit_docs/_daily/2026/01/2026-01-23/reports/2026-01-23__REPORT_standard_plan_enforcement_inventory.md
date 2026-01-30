# Rapport d'inventaire - Enforcement des limites de plan STANDARD

**Date :** 2026-01-23  
**Scope :** Clients self-service STANDARD uniquement (WL hors scope)

---

## 1. État actuel du codebase

### 1.1 Plan actif d'une communauté

| Élément | Localisation | Description |
|---------|--------------|-------------|
| `communities.planId` | `shared/schema.ts:225` | ID du plan actif (varchar FK → plans) |
| `communities.subscriptionStatus` | `shared/schema.ts:226` | Status: trialing, active, past_due, canceled |
| `communities.maxMembersAllowed` | `shared/schema.ts:239` | Override manuel de la limite (nullable) |
| `communities.whiteLabel` | `shared/schema.ts:232` | Boolean pour bypass WL |

### 1.2 Limites de membres par plan

| Source | Localisation | Description |
|--------|--------------|-------------|
| `plans.maxMembers` | `shared/schema.ts:437` | Limite membres en DB (integer nullable) |
| `DEFAULT_LIMITS` | `server/lib/planLimits.ts:12-18` | Fallback si pas en DB |
| `FREE_MEMBER_LIMIT` | `server/lib/subscriptionGuards.ts:11` | Constante = 20 (à remplacer) |

**Valeurs par plan :**
- free: 50 membres (DEFAULT_LIMITS) 
- plus: 500 membres
- pro: 5000 membres
- enterprise/whitelabel: null (illimité)

### 1.3 Comptage des membres

| Fonction | Localisation | Description |
|----------|--------------|-------------|
| `getCommunityMemberships()` | `server/storage.ts` | Liste tous les memberships |
| Query directe | `server/lib/subscriptionGuards.ts:183-192` | Filtre role="member" |

### 1.4 Mécanisme de gel existant

| Élément | Localisation | Description |
|---------|--------------|-------------|
| `suspendedByQuotaLimit` | `shared/schema.ts:547` | Boolean flag sur membership |
| `status` (enum) | `shared/schema.ts:543` | active/expired/suspended |
| `suspendMembersBeyondFreeLimit()` | `server/lib/subscriptionGuards.ts:179-218` | Fonction de suspension |
| `reactivateSuspendedMembers()` | `server/lib/subscriptionGuards.ts:223-253` | Fonction de réactivation |

### 1.5 Guards argent existants

| Guard | Localisation | Description |
|-------|--------------|-------------|
| `requireActiveSubscriptionForMoney()` | `server/lib/subscriptionGuards.ts:80-141` | Middleware Express |
| `isMoneyAllowed()` | `server/lib/subscriptionGuards.ts:20-23` | Check status = active |
| `MONEY_BLOCKED_STATUSES` | `server/lib/subscriptionGuards.ts:8` | trialing, past_due, canceled |

### 1.6 Blocage login existant

| Endpoint | Localisation | Description |
|----------|--------------|-------------|
| `/api/accounts/login` | `server/routes.ts:1759-1772` | Filtre memberships suspendus |
| `/api/accounts/me` | `server/routes.ts` | Même logique |

---

## 2. Écarts avec la spécification

### 2.1 Problèmes identifiés

| Problème | Impact | Priorité |
|----------|--------|----------|
| `FREE_MEMBER_LIMIT=20` codé en dur | Ne respecte pas plan.maxMembers | CRITIQUE |
| Enforcement uniquement à expiration trial | Pas d'enforcement dynamique | CRITIQUE |
| Pas de dégel auto à suppression membre | UX incomplète | HAUTE |
| Pas d'enforcement au changement de plan | Downgrade non géré | HAUTE |
| Pas d'enforcement à l'ajout de membre | Dépassement possible | HAUTE |

### 2.2 Fonctions existantes à adapter

1. **`suspendMembersBeyondFreeLimit()`** → Renommer et utiliser `plan.maxMembers` dynamique
2. **`reactivateSuspendedMembers()`** → OK, mais doit être appelée plus largement
3. **`requireActiveSubscriptionForMoney()`** → OK, déjà implémentée

### 2.3 Points d'appel manquants

L'enforcement doit être appelé :
- [x] Après expiration trial (checkAndUpdateTrialExpiry)
- [ ] Après ajout membre (backoffice)
- [ ] Après inscription via lien invitation
- [ ] Après suppression membre
- [ ] Après changement de plan (upgrade/downgrade)

---

## 3. Fichiers impactés

### Backend
- `server/lib/subscriptionGuards.ts` - Refactoring enforcement
- `server/lib/planLimits.ts` - Source de vérité maxMembers
- `server/routes.ts` - Points d'appel enforcement
- `server/stripe.ts` - Webhook upgrade/downgrade

### Shared
- `shared/schema.ts` - Champ existant OK (suspendedByQuotaLimit)

### Frontend (UI)
- `client/src/components/layouts/AdminLayout.tsx` - Bandeau
- `client/src/components/MobileAdminLayout.tsx` - Bandeau mobile
- `client/src/pages/admin/Members.tsx` - Badge "Désactivé"

---

## 4. Risques identifiés

| Risque | Mitigation |
|--------|------------|
| Migration non nécessaire | Réutiliser `suspendedByQuotaLimit` existant |
| Performance sur grandes communautés | Query optimisée avec ORDER BY + LIMIT |
| Race condition ajout multiple membres | Transaction ou enforcement post-commit |
| Confusion terminologie gel/suspended | Garder nomenclature existante (suspended) |

---

## 5. Décision architecturale

**Nomenclature :** Conserver `suspendedByQuotaLimit` (déjà existant, pas de migration).

**Fonction centrale :** Créer `enforceCommunityPlanLimits(communityId)` qui :
1. Récupère `plan.maxMembers` via `getCommunityLimits()`
2. Liste membres triés par `joinDate ASC`
3. Suspend les membres > limit
4. Réactive les membres <= limit (si précédemment suspendus par quota)

**Pas de nouvelle colonne nécessaire** - le champ `suspendedByQuotaLimit` suffit.

---

## 6. Plan d'implémentation

1. Créer `enforceCommunityPlanLimits()` dans `subscriptionGuards.ts`
2. Intégrer appels dans routes membres (add, delete)
3. Intégrer appels dans changement de plan
4. Intégrer appels dans webhooks Stripe
5. Mettre à jour UI avec badges
6. Écrire tests

