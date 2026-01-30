# Rapport : Propositions d'implémentation — Client Entreprise non-WL

**Date**: 2026-01-23  
**Type**: Analyse stratégique (pas d'exécution)  
**Statut**: Document de travail CTO

---

## 1. Lecture de l'existant

### 1.1 Où "Enterprise" existe déjà dans le code

| Élément | Localisation | Description |
|---------|--------------|-------------|
| `accountType` enum | `shared/schema.ts:75` | `"STANDARD" \| "GRAND_COMPTE"` — **typologie client** |
| `PLAN_CODES.GRAND_COMPTE` | `shared/schema.ts:248` | Plan dédié Enterprise |
| `KOOMY_PLANS.GRAND_COMPTE` | `shared/plans.ts:199-254` | Définition complète du plan Enterprise |
| `distributionChannels` | `shared/schema.ts:342` | JSONB `{ whiteLabelApp?, koomyWallet? }` — **canaux de distribution** |
| `billingMode` | `shared/schema.ts:312` | `"self_service" \| "manual_contract"` — mode de facturation |
| `contractMemberLimit` | `shared/schema.ts:343` | Limite membres contractuelle pour Grand Compte |
| `inferClientSegment()` | `server/lib/whiteLabelAccessor.ts:183-201` | Infère "enterprise" si `planId === "enterprise" \| "GRAND_COMPTE"` |
| `DEFAULT_LIMITS.enterprise` | `server/lib/planLimits.ts:27` | Limites illimitées (`null`) pour enterprise |
| `DEFAULT_CAPABILITIES.enterprise` | `server/lib/planLimits.ts:83-99` | Toutes capabilities activées |
| `storage.getMemberQuotaInfo()` | `server/storage.ts:675` | Vérifie `accountType === "GRAND_COMPTE"` pour utiliser `contractMemberLimit` |

**Conclusion**: L'architecture pour Enterprise existe au niveau schéma et plan. La brique "Enterprise" est **partiellement implémentée**.

### 1.2 Où WL est supposé obligatoire pour Enterprise

| Zone | Fichier | Logique actuelle | Problème |
|------|---------|------------------|----------|
| Bypass subscription guards | `subscriptionGuards.ts` | `if (isWhiteLabelBypassEnabledSync(community))` | Vérifie `whiteLabel`, pas `accountType` |
| Bypass usage limits | `usageLimitsGuards.ts` | `if (effectivePlan.isWhiteLabel)` | Vérifie `isWhiteLabel`, pas `accountType` |
| Bypass money guards | `subscriptionGuards.ts` | `if (isWhiteLabelBypassEnabledSync(community))` | Vérifie `whiteLabel`, pas `accountType` |
| EffectivePlan | `planLimits.ts:162` | `isWhiteLabel: community.whiteLabel` | Propage `whiteLabel` au lieu de `isEnterprise` |
| Auth mode | `authModeResolver.ts` | `if (community.whiteLabel) → LEGACY` | WL force auth legacy |

**Résumé**: Les bypass sont conditionnés par `whiteLabel` (distribution) et non par `accountType` (typologie client).

### 1.3 Briques déjà compatibles sans modification

| Brique | Raison de compatibilité |
|--------|-------------------------|
| `KOOMY_PLANS.GRAND_COMPTE` | Plan complet avec toutes capabilities |
| `accountType` colonne | Existe en DB, peut être positionné à `GRAND_COMPTE` |
| `billingMode` colonne | Peut être `manual_contract` indépendamment de `whiteLabel` |
| `contractMemberLimit` | Fonctionne déjà si `accountType === "GRAND_COMPTE"` |
| `inferClientSegment()` | Détecte déjà `planId === "enterprise"` comme segment Enterprise |
| `distributionChannels.koomyWallet` | Champ existe, peut être `true` pour distribution Koomy standard |
| Auth Firebase | Fonctionne si `whiteLabel === false` (auth mode = FIREBASE_ONLY) |

---

## 2. Scénarios d'implémentation possibles

### 2.1 Scénario A : "Enterprise Flag" dédié

**Description**:  
Ajouter un flag `isEnterprise` calculé ou stocké, et modifier les bypass pour utiliser `accountType === "GRAND_COMPTE"` au lieu de `whiteLabel`.

**Chemin d'implémentation**:
1. Modifier `EffectivePlan` pour inclure `isEnterprise: community.accountType === "GRAND_COMPTE"`
2. Modifier les bypass dans `whiteLabelAccessor.ts` :
   ```typescript
   export function shouldBypassForEnterprise(community: { accountType?: string }): boolean {
     return community.accountType === "GRAND_COMPTE";
   }
   ```
3. Remplacer les conditions `isWhiteLabel` par `isEnterprise || isWhiteLabel` dans les guards
4. Créer une community avec `accountType = "GRAND_COMPTE"`, `whiteLabel = false`

**Réutilisé tel quel**:
- Schema existant (`accountType`, `billingMode`, `contractMemberLimit`)
- Plan GRAND_COMPTE existant
- Auth Firebase (car `whiteLabel = false`)

**Adaptation minimale**:
- `whiteLabelAccessor.ts`: ajouter fonction `isEnterpriseAccount()`
- `planLimits.ts`: ajouter `isEnterprise` à `EffectivePlan`
- `subscriptionGuards.ts`: modifier 3 conditions
- `usageLimitsGuards.ts`: modifier 3 conditions

**Risques techniques**:
- Moyen: nécessite modification de 4-5 fichiers
- Faible: pas de migration DB (champs existent)
- Faible: les guards sont centralisés et bien testés

**Risques produit**:
- Faible: clients WL existants non impactés
- Moyen: besoin de clarifier UX Owner pour distinguer Enterprise WL vs Enterprise non-WL

**Effort estimé**: MOYEN (3-5 jours)

---

### 2.2 Scénario B : "Contrat Billing = Bypass" (Minimal)

**Description**:  
Utiliser `billingMode === "manual_contract"` comme condition de bypass au lieu de `whiteLabel`. Tout client sous contrat manuel (Enterprise) bypass les guards, qu'il ait WL ou non.

**Chemin d'implémentation**:
1. Modifier `whiteLabelAccessor.ts` :
   ```typescript
   export function isContractBypassEnabled(community: { billingMode?: string }): boolean {
     return community.billingMode === "manual_contract";
   }
   ```
2. Modifier les bypass pour utiliser `billingMode === "manual_contract" || whiteLabel`
3. Créer une community avec `billingMode = "manual_contract"`, `whiteLabel = false`

**Réutilisé tel quel**:
- Schema existant (`billingMode`)
- Plan libre (peut être GRAND_COMPTE ou autre)
- Auth Firebase

**Adaptation minimale**:
- `whiteLabelAccessor.ts`: ajouter fonction `isContractBypassEnabled()`
- `subscriptionGuards.ts`: modifier 3 conditions
- `usageLimitsGuards.ts`: modifier 3 conditions

**Risques techniques**:
- Faible: modification très ciblée
- Faible: pas de migration DB

**Risques produit**:
- Moyen: `billingMode` devient un "super-flag" sémantiquement ambigu
- Faible: clients WL existants ont déjà `billingMode = manual_contract`

**Effort estimé**: FAIBLE (1-2 jours)

---

### 2.3 Scénario C : "Distribution Channel" explicite

**Description**:  
Utiliser `distributionChannels.koomyWallet === true` pour identifier les clients Enterprise distribués via Koomy standard (non-WL), et adapter les bypass.

**Chemin d'implémentation**:
1. Créer une community avec :
   - `accountType = "GRAND_COMPTE"`
   - `whiteLabel = false`
   - `distributionChannels = { koomyWallet: true, whiteLabelApp: false }`
2. Modifier les bypass :
   ```typescript
   const isEnterprise = community.accountType === "GRAND_COMPTE";
   const bypassEnabled = community.whiteLabel || isEnterprise;
   ```
3. L'auth reste Firebase car `whiteLabel = false`

**Réutilisé tel quel**:
- Schema existant complet
- Plan GRAND_COMPTE
- Auth Firebase
- `distributionChannels` comme metadata informative

**Adaptation minimale**:
- Conditions de bypass (même modifications que Scénario A)

**Risques techniques**:
- Moyen: même niveau que Scénario A
- Faible: `distributionChannels` est informatif, pas un guard

**Risques produit**:
- Faible: sémantique claire (Enterprise = bypass, WL = distribution)

**Effort estimé**: MOYEN (3-5 jours)

---

### 2.4 Scénario D : "Quick Win" — Activation manuelle via Owner

**Description**:  
Permettre à l'Owner d'activer manuellement les bypass pour une community non-WL via un champ dédié `bypassGuards: boolean`.

**Chemin d'implémentation**:
1. Ajouter colonne `bypassGuards: boolean` au schema
2. Migration: `ALTER TABLE communities ADD COLUMN bypass_guards BOOLEAN DEFAULT FALSE`
3. Modifier les bypass : `if (community.whiteLabel || community.bypassGuards)`
4. UI Owner: checkbox "Bypass Guards" dans les settings community

**Réutilisé tel quel**:
- Tout l'existant

**Adaptation minimale**:
- Schema: 1 nouvelle colonne
- Migration: 1 ALTER TABLE
- Guards: 4-5 conditions modifiées
- UI Owner: 1 checkbox

**Risques techniques**:
- Faible: modification atomique
- Moyen: migration DB (mais simple)

**Risques produit**:
- Élevé: crée un nouveau "super-flag" sans sémantique métier claire
- Élevé: contourne le problème sans le résoudre

**Effort estimé**: FAIBLE (1-2 jours) mais DETTE CRÉÉE

---

## 3. Scénario recommandé

### Recommandation : Scénario A — "Enterprise Flag" dédié

**Pourquoi ce scénario**:

1. **Sémantique correcte**: Distingue clairement typologie client (`accountType`) vs distribution (`whiteLabel`)
2. **Alignement contrat P2.8**: Respecte "Entreprise = typologie, White-Label = option"
3. **Pas de super-flag ambigu**: `billingMode` reste un mode de facturation, pas un proxy de bypass
4. **Réutilise l'existant**: `accountType` et `GRAND_COMPTE` existent déjà
5. **Pas de migration DB**: Les colonnes nécessaires sont déjà présentes
6. **Maintient invariants auth**: `whiteLabel = false` → Firebase, indépendant du type Enterprise

**Hypothèses requises**:

| Hypothèse | À valider avec |
|-----------|----------------|
| `accountType === "GRAND_COMPTE"` implique bypass complet des guards | Contrat produit |
| Un client Enterprise non-WL utilise Firebase auth (membres + admins) | Contrat P0.x (Identité) |
| Les limites Enterprise utilisent `contractMemberLimit` (pas plan.maxMembers) | Contrat P1.x (Limites) |
| L'UI Owner affiche "Entreprise" vs "Entreprise (WL)" distinctement | Contrat UX à définir |

**Ce qui doit être contractuellement validé avant implémentation**:

1. **P2.8 bis**: Confirmation que `accountType = GRAND_COMPTE` sans `whiteLabel = true` est un cas valide
2. **P1.x addendum**: Les bypass de limites s'appliquent à tout `GRAND_COMPTE`, pas seulement WL
3. **P0.x invariant**: Confirmer que Enterprise non-WL = Firebase auth (pas Legacy)
4. **UX Owner**: Wireframes pour distinguer visuellement Enterprise + WL vs Enterprise seul

---

## 4. Résumé comparatif

| Critère | A (Enterprise Flag) | B (Billing=Bypass) | C (Distribution) | D (Quick Win) |
|---------|--------------------|--------------------|------------------|---------------|
| Sémantique | ✅ Correcte | ⚠️ Ambiguë | ✅ Correcte | ❌ Hack |
| Migration DB | ❌ Aucune | ❌ Aucune | ❌ Aucune | ⚠️ 1 colonne |
| Effort | Moyen | Faible | Moyen | Faible |
| Risque régression | Faible | Faible | Faible | Faible |
| Risque dette | ❌ Aucun | ⚠️ Ambigu | ❌ Aucun | ⚠️ Élevé |
| Alignement P2.8 | ✅ Parfait | ⚠️ Partiel | ✅ Parfait | ❌ Contourne |

---

## 5. Informations manquantes

| Information | Impact |
|-------------|--------|
| Nombre de clients Enterprise non-WL à onboarder court terme | Priorisation urgence |
| Confirmation que `accountType` n'est pas utilisé ailleurs de façon incompatible | Risque de régression |
| Wireframes UX Owner pour Enterprise + WL vs Enterprise seul | Design UI |
| Contrat P2.8 validé formellement | Go/No-Go implémentation |

---

## 6. Conclusion

L'architecture pour supporter un client Enterprise non-WL **existe partiellement** dans le code actuel :
- Les champs DB sont présents (`accountType`, `distributionChannels`, `billingMode`)
- Le plan GRAND_COMPTE est défini
- L'inférence sémantique `inferClientSegment()` détecte déjà ce cas

Le blocage actuel est **localisé dans les guards** qui utilisent `whiteLabel` comme proxy pour "Enterprise", au lieu d'utiliser `accountType`.

La solution recommandée (Scénario A) nécessite **~3-5 jours d'effort** et **aucune migration DB**, uniquement des modifications de logique conditionnelle dans 4-5 fichiers déjà centralisés.

---

**Fin du rapport.**
