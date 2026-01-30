# Rapport d'alignement du modèle client Koomy

**Date**: 2026-01-23  
**Statut**: READ-ONLY (Aucun refactor sans validation explicite)  
**Référence**: `replit_prompt_alignment_client_enterprise_white_label.md`

---

## 1. Modèle client actuellement implémenté

### 1.1 Typologie par Plan (shared/plans.ts)

Le code définit **4 plans** dans `KOOMY_PLANS`:

| Plan Code | ID | Nom UI | maxMembers | Type |
|-----------|-----|---------|------------|------|
| `FREE` | free | Free | 20 | SaaS public |
| `PLUS` | plus | Plus | 300 | SaaS public |
| `PRO` | pro | Pro | 2000 | SaaS public |
| `GRAND_COMPTE` | enterprise | Grand Compte | null (illimité) | Sur mesure |

**Observation**: Le plan "GRAND_COMPTE" correspond fonctionnellement au concept "Entreprise" du modèle canonique.

### 1.2 Flag whiteLabel (shared/schema.ts)

Le schéma `communities` contient:

```typescript
whiteLabel: boolean("white_label").default(false),
whiteLabelTier: whiteLabelTierEnum("white_label_tier"), // basic | standard | premium
brandConfig: jsonb("brand_config").$type<BrandConfig>(),
customDomain: text("custom_domain").unique(),
whiteLabelIncludedMembers: integer("white_label_included_members"),
whiteLabelMaxMembersSoftLimit: integer("white_label_max_members_soft_limit"),
whiteLabelAdditionalFeePerMemberCents: integer("white_label_additional_fee_per_member_cents"),
```

**Observation**: `whiteLabel` est traité comme un **booléen de type client**, pas comme une option de distribution.

### 1.3 Invariant Auth (server/lib/authModeResolver.ts)

```typescript
// Invariant: whiteLabel=true → authMode=LEGACY_ONLY, whiteLabel=false → authMode=FIREBASE_ONLY
```

Le flag `whiteLabel` **détermine directement le mode d'authentification**, renforçant son rôle de "type de client" plutôt que d'option.

---

## 2. Points d'ambiguïté WL identifiés

### 2.1 Ambiguïté sémantique

| Contexte | Utilisation de "WL" | Interprétation |
|----------|---------------------|----------------|
| `community.whiteLabel` | Booléen true/false | **Type de client** |
| `capabilities.whiteLabeling` | Dans plan capabilities | **Option du plan** |
| `distributionChannels.whiteLabelApp` | Dans config | **Option de distribution** |
| `authMode` decision | Basé sur whiteLabel | **Type de client** |
| Guards bypass | `if (community.whiteLabel)` | **Type de client** |

### 2.2 Confusion Type vs Option

Le code traite `whiteLabel=true` comme une **catégorie mutuellement exclusive** :

```typescript
// server/lib/subscriptionGuards.ts:56
if (community.whiteLabel) {
  return { allowed: true, reason: "white_label_bypass" };
}
```

Alors que le modèle canonique voudrait :
- Client = Standard | Entreprise (basé sur volume/contrat)
- WL = Option de distribution (indépendante du type)

### 2.3 Plan "GRAND_COMPTE" sous-utilisé

Le plan `GRAND_COMPTE` (Enterprise) existe mais :
- N'est **pas utilisé** pour déterminer le bypass des guards
- N'est **pas lié** au flag `whiteLabel`
- La logique utilise `whiteLabel` au lieu de `planId === "GRAND_COMPTE"`

---

## 3. Endroits où "WL" est utilisé comme type de client

### 3.1 Backend - Guards et Services

| Fichier | Ligne(s) | Usage |
|---------|----------|-------|
| `server/lib/subscriptionGuards.ts` | 56, 121, 245, 418 | Bypass total si `whiteLabel=true` |
| `server/lib/usageLimitsGuards.ts` | 106, 136, 155 | Bypass limits si `isWhiteLabel` |
| `server/lib/effectiveStateService.ts` | 58-145 | Bypass capabilities/money si `isWhiteLabel` |
| `server/lib/planLimits.ts` | 196, 269 | Retourne `isWhiteLabel` dans effective plan |
| `server/lib/authModeResolver.ts` | 12-13, 152-188 | Détermine authMode basé sur `whiteLabel` |

### 3.2 Frontend - Contextes et Pages

| Fichier | Usage |
|---------|-------|
| `client/src/contexts/WhiteLabelContext.tsx` | Contexte React pour état WL |
| `client/src/pages/mobile/WhiteLabelLogin.tsx` | Page login dédiée WL |
| `client/src/components/WhiteLabelMemberApp.tsx` | App membre WL |
| `client/src/lib/appModeResolver.ts` | Detection mode WL par hostname |
| `client/src/pages/platform/SuperDashboard.tsx` | Affichage "clients WL" |

### 3.3 Schéma DB

| Table | Colonnes WL |
|-------|-------------|
| `communities` | `white_label`, `white_label_tier`, `white_label_included_members`, `white_label_max_members_soft_limit`, `white_label_additional_fee_per_member_cents` |
| `accounts` | Pas de champ WL direct (dérivé de community) |

---

## 4. Dette identifiée (sans correction)

### 4.1 Dette conceptuelle (HAUTE)

| ID | Description | Impact |
|----|-------------|--------|
| DEBT-001 | `whiteLabel` booléen traité comme type de client | Confusion modèle métier |
| DEBT-002 | Plan `GRAND_COMPTE` non lié à `whiteLabel` | Incohérence logique |
| DEBT-003 | Pas de notion "client Entreprise" distincte du plan | Modèle incomplet |

### 4.2 Dette technique (MOYENNE)

| ID | Description | Impact |
|----|-------------|--------|
| DEBT-004 | Guards hardcodés sur `whiteLabel` au lieu de type client | Maintenance difficile |
| DEBT-005 | `isWhiteLabel` propagé dans tous les services | Couplage fort |
| DEBT-006 | Pas de champ `clientType` (Standard/Enterprise) | Manque d'abstraction |

### 4.3 Dette UX/Produit (BASSE)

| ID | Description | Impact |
|----|-------------|--------|
| DEBT-007 | UI SuperDashboard parle de "clients WL" | Confusion utilisateur |
| DEBT-008 | Terminologie mixte dans les traductions | Incohérence UI |

---

## 5. Recommandation future (contrat P2.x requis)

### 5.1 Phase 1 - Abstraction conceptuelle

1. Ajouter un champ `clientType: "standard" | "enterprise"` sur `communities`
2. Redéfinir `whiteLabel` comme option de distribution (sous-champ de `distributionOptions`)
3. Créer helper `isEnterpriseClient(community)` distinct de `isWhiteLabel(community)`

### 5.2 Phase 2 - Migration Guards

1. Remplacer `if (community.whiteLabel)` par `if (isEnterpriseClient(community))`
2. Conserver `whiteLabel` uniquement pour :
   - Branding custom
   - Domaine dédié
   - App dédiée

### 5.3 Phase 3 - UI Alignment

1. Renommer "Clients WL" → "Clients Entreprise" dans SuperDashboard
2. Ajouter indicateur "Distribution: White-Label" comme sous-info
3. Mettre à jour traductions FR/EN

### 5.4 Estimation effort

| Phase | Effort estimé | Risque |
|-------|---------------|--------|
| Phase 1 | 3-5 jours | Moyen (migration DB) |
| Phase 2 | 2-3 jours | Faible (refactor guards) |
| Phase 3 | 1-2 jours | Très faible (UI only) |

---

## 6. Règles immédiates (sans contrat dédié)

À partir de maintenant :

1. **NE PAS** ajouter de nouveaux usages de `whiteLabel` comme type de client
2. **NE PAS** étendre les colonnes `white_label_*` pour des features non-distribution
3. **DOCUMENTER** tout nouveau bypass avec commentaire `// DEBT: WL-as-type`
4. **PRÉFÉRER** la vérification de plan (`planId === "GRAND_COMPTE"`) pour les features entreprise

---

## 7. Mapping Terminologique

| Terme actuel (dette) | Terme canonique |
|---------------------|-----------------|
| "Client WL" | "Client Entreprise" |
| "Community WL" | "Community Entreprise + option WL" |
| `whiteLabel=true` | `clientType=enterprise` + `distributionOptions.whiteLabel=true` |
| "WL bypass" | "Enterprise bypass" |

---

**Fin du rapport.**

Ce document est une analyse READ-ONLY. Tout refactor nécessite un contrat P2.x dédié avec validation explicite.
