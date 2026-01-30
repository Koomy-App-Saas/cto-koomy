# Rapport de gouvernance : Dette White-Label

**Date**: 2026-01-23  
**Statut**: READ-ONLY (Aucune modification code autorisée)  
**Référence**: `replit_prompt_governance_white_label_debt_assumed.md`

---

## 1. Engagement fondateur (rappel)

> **Koomy ne parle plus de "client WL" comme typologie produit.**  
> **Koomy parle de "client Entreprise", puis précise son mode de distribution.**

| Terme historique (DETTE) | Terme canonique (CIBLE) |
|--------------------------|-------------------------|
| Client WL | Client Enterprise |
| Community WL | Community Enterprise + option WL |
| whiteLabel=true | clientType=enterprise + distributionOptions.whiteLabel=true |

---

## 2. Où le terme WL est utilisé comme type client

### 2.1 Schéma DB (shared/schema.ts)

| Colonne | Table | Usage dette |
|---------|-------|-------------|
| `white_label` | communities | Booléen déterminant le "type" de client |
| `white_label_tier` | communities | Niveau WL (basic/standard/premium) comme typologie |
| `white_label_included_members` | communities | Quota WL comme contrat client |
| `white_label_max_members_soft_limit` | communities | Limite WL comme règle client |
| `white_label_additional_fee_per_member_cents` | communities | Tarif WL comme facturation client |

### 2.2 Backend Guards

| Fichier | Pattern | Ligne(s) |
|---------|---------|----------|
| `server/lib/subscriptionGuards.ts` | `if (community.whiteLabel)` → bypass | 56, 121, 245, 418 |
| `server/lib/usageLimitsGuards.ts` | `if (effectivePlan.isWhiteLabel)` → bypass | 106, 136, 155 |
| `server/lib/effectiveStateService.ts` | `if (isWhiteLabel)` → all enabled | 58-145 |
| `server/lib/planLimits.ts` | `isWhiteLabel` dans retour | 196, 269 |

### 2.3 Auth Mode (Invariant hardcodé)

```typescript
// server/lib/authModeResolver.ts:12-13
// Invariant: whiteLabel=true → authMode=LEGACY_ONLY, whiteLabel=false → authMode=FIREBASE_ONLY
```

Le flag `whiteLabel` **détermine le système d'authentification** — traitement comme type client, pas comme option.

### 2.4 Frontend

| Fichier | Usage dette |
|---------|-------------|
| `client/src/contexts/WhiteLabelContext.tsx` | Contexte React basé sur WL comme type |
| `client/src/pages/platform/SuperDashboard.tsx` | Affiche "clients WL" comme catégorie |
| `client/src/pages/mobile/WhiteLabelLogin.tsx` | Page login spécifique au "type WL" |
| `client/src/components/WhiteLabelMemberApp.tsx` | App membre "type WL" |
| `client/src/lib/appModeResolver.ts` | Mode applicatif basé sur WL |

---

## 3. Où WL agit comme super-flag (bypass)

### 3.1 Bypass Subscription Guards

```typescript
// server/lib/subscriptionGuards.ts:56
if (community.whiteLabel) {
  return { allowed: true, reason: "white_label_bypass" };
}
```

**Impact**: Les communities WL ne sont jamais bloquées par les guards de subscription (trial, past_due, canceled).

### 3.2 Bypass Usage Limits

```typescript
// server/lib/usageLimitsGuards.ts:106
if (effectivePlan.isWhiteLabel) {
  return { canAdd: true, current: memberCount, max: null };
}
```

**Impact**: Les communities WL n'ont pas de limite de membres/admins.

### 3.3 Bypass Capabilities

```typescript
// server/lib/effectiveStateService.ts:84
if (isWhiteLabel) {
  return { enabled: true }; // All capabilities enabled
}
```

**Impact**: Les communities WL ont toutes les capabilities activées sans vérification de plan.

### 3.4 Bypass Money Guards

```typescript
// server/lib/effectiveStateService.ts:129
const moneyAllowed = isWhiteLabel || !MONEY_BLOCKED_STATUSES.includes(subscriptionStatus);
```

**Impact**: Les communities WL peuvent toujours effectuer des opérations financières.

### 3.5 Bypass Billing CTA

```typescript
// server/lib/effectiveStateService.ts:60
if (isWhiteLabel) return null; // No billing CTA
```

**Impact**: Les communities WL n'ont jamais de CTA billing (géré en externe).

---

## 4. Impacts connus

### 4.1 Impact Auth

| Aspect | Comportement actuel (dette) |
|--------|----------------------------|
| Mode auth | `whiteLabel=true` → LEGACY_ONLY |
| Firebase | Interdit pour communities WL |
| Session | Même durée (2h) mais auth différent |

### 4.2 Impact Billing

| Aspect | Comportement actuel (dette) |
|--------|----------------------------|
| Stripe Billing | Ignoré pour WL |
| Trial system | Bypass pour WL |
| past_due/canceled | Bypass pour WL |
| CTA billing | null pour WL |

### 4.3 Impact Limits

| Aspect | Comportement actuel (dette) |
|--------|----------------------------|
| maxMembers | null (illimité) pour WL |
| maxAdmins | null (illimité) pour WL |
| Quotas events | Bypass pour WL |

### 4.4 Impact UI

| Zone | État actuel (dette) |
|------|---------------------|
| SuperDashboard | Affiche "Clients WL" comme catégorie |
| Settings communauté | Pas de distinction Enterprise vs WL |
| Billing page | Masquée pour WL |

---

## 5. Zones à ne plus étendre

### 5.1 Colonnes DB à ne PAS ajouter

❌ Ne pas créer de nouvelles colonnes `white_label_*` pour des features non-distribution.

Exemples interdits :
- `white_label_can_export` → utiliser `planId` + `capabilities`
- `white_label_support_level` → utiliser contrat Enterprise
- `white_label_custom_limits` → utiliser `maxMembersAllowed` existant

### 5.2 Guards à ne PAS étendre

❌ Ne pas ajouter de nouveaux `if (community.whiteLabel)` pour des features métier.

Pattern interdit :
```typescript
// ❌ INTERDIT
if (community.whiteLabel) {
  // nouvelle feature bypass
}
```

Pattern recommandé (en attendant refactor) :
```typescript
// ✅ ACCEPTABLE (avec documentation dette)
if (community.planId === "GRAND_COMPTE" || community.whiteLabel) {
  // DEBT: whiteLabel used as client type (see governance WL prompt)
}
```

### 5.3 UI à ne PAS étendre

❌ Ne pas ajouter de nouvelles références "WL" comme catégorie client dans l'UI.

Exemples interdits :
- Nouveau dashboard "Clients WL"
- Nouveaux filtres "Type: WL"
- Nouveaux rapports "Revenue WL"

---

## 6. Prérequis pour un futur refactor

### 6.1 Contrat produit requis

Un contrat dédié **"Client Enterprise & Option WL"** doit être validé avant tout refactor.

Ce contrat doit inclure :
1. Définition formelle `clientType: standard | enterprise`
2. Définition formelle `distributionOptions.whiteLabel: boolean`
3. Mapping migration des communities existantes
4. Impact UI Owner
5. Impact facturation
6. Timeline et budget

### 6.2 Phases techniques (estimation)

| Phase | Scope | Effort | Risque |
|-------|-------|--------|--------|
| P2.1 | Ajouter `clientType` colonne + migration | 2-3j | Moyen |
| P2.2 | Refactor guards vers `clientType` | 3-4j | Moyen |
| P2.3 | Redéfinir `whiteLabel` comme option | 2-3j | Faible |
| P2.4 | Refactor UI Owner | 2-3j | Faible |
| P2.5 | Tests + validation | 2-3j | Faible |

**Total estimé**: 11-16 jours

### 6.3 Prérequis données

Avant migration, identifier :
- Combien de communities ont `whiteLabel=true` ?
- Lesquelles ont un contrat Enterprise actif ?
- Lesquelles utilisent réellement la distribution WL (app dédiée, domaine custom) ?

### 6.4 Prérequis tests

Créer une suite de tests de non-régression couvrant :
- Auth mode resolution
- Subscription guards bypass
- Usage limits bypass
- Capabilities computation
- Billing visibility

---

## 7. Règles de gouvernance actives

### RÈGLE 1 — Interprétation

```
WL ≠ Type client
WL = Option de distribution d'un client Enterprise
```

### RÈGLE 2 — Code existant

```
Les usages actuels de whiteLabel sont de la DETTE ASSUMÉE.
Ne pas étendre. Ne pas réinterpréter comme modèle cible.
```

### RÈGLE 3 — Aucun refactor sans contrat

```
Aucun renommage, migration, changement logique ou UI Owner
tant qu'un contrat P2.x n'est pas validé.
```

### RÈGLE 4 — Nouvelles features

```
1. Identifier d'abord : standard ou enterprise
2. Ensuite seulement : WL activé comme distribution
WL ne doit jamais être le point de départ du raisonnement.
```

---

## 8. Documentation dette (template commentaire)

Pour tout code touchant au bypass WL, utiliser ce commentaire :

```typescript
// DEBT: whiteLabel used as client type (see governance WL prompt)
// Target: clientType=enterprise + distributionOptions.whiteLabel
// Refactor: requires P2.x contract validation
```

---

## 9. Résumé exécutif

| Dimension | État actuel | État cible |
|-----------|-------------|------------|
| Modèle client | WL = type | Enterprise = type, WL = option |
| Guards | `if (whiteLabel)` | `if (clientType === 'enterprise')` |
| Auth | WL → LEGACY | Enterprise → LEGACY (si WL activé) |
| Billing | WL bypass | Enterprise bypass (contractuel) |
| UI | "Clients WL" | "Clients Enterprise" + badge WL |

**Statut**: Dette assumée, aucun refactor autorisé sans contrat P2.x.

---

**Fin du rapport de gouvernance.**
