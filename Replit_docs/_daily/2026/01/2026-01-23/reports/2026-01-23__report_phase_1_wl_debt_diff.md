# Rapport Phase 1 — Diff technique dette White-Label

**Date**: 2026-01-23  
**Phase**: 1 (A + D)

---

## 1. Fichiers créés

| Fichier | Lignes | Rôle |
|---------|--------|------|
| `server/lib/whiteLabelAccessor.ts` | ~220 | Couche d'encapsulation centrale WL |
| `scripts/check-wl-debt-propagation.sh` | ~95 | Garde-fou anti-propagation |
| `docs/rapports/report_phase_1_wl_debt_code_map.md` | ~180 | Cartographie exhaustive |
| `docs/rapports/report_phase_1_wl_debt_actions.md` | ~200 | Rapport d'actions |
| `docs/rapports/report_phase_1_wl_debt_diff.md` | Ce fichier | Diff technique |

---

## 2. Fichiers modifiés

**Aucun fichier existant n'a été modifié.**

La Phase 1 est purement additive pour éviter les régressions.

---

## 3. Résumé par fichier créé

### 3.1 server/lib/whiteLabelAccessor.ts

**Objectif**: Centraliser tous les accès au flag WL

**Exports principaux**:
```typescript
// Types
export type ClientSegment = "standard" | "enterprise" | "unknown";
export type DistributionMode = "koomy_app" | "white_label";
export interface WhiteLabelAccessResult { ... }

// Fonctions async
export async function isWhiteLabelBypassEnabled(communityId: string): Promise<boolean>
export async function getWhiteLabelAccess(communityId: string): Promise<WhiteLabelAccessResult | null>
export async function shouldBypassSubscriptionGuards(communityId: string): Promise<boolean>
export async function shouldBypassUsageLimits(communityId: string): Promise<boolean>
export async function shouldBypassMoneyGuards(communityId: string): Promise<boolean>

// Fonctions sync
export function isWhiteLabelBypassEnabledSync(community: { whiteLabel?: boolean | null }): boolean
export function inferClientSegment(isWhiteLabel: boolean, planId?: string | null): ClientSegment
export function getClientSegmentLabel(segment: ClientSegment, hasWLDistribution: boolean): string
export function getWhiteLabelDebugInfo(community: { ... }): Record<string, unknown>
```

**Dépendances**:
- `../db` (Drizzle DB)
- `@shared/schema` (communities)
- `drizzle-orm` (eq)

**Risques**: Aucun (nouveau fichier, non utilisé par le code existant)

### 3.2 scripts/check-wl-debt-propagation.sh

**Objectif**: Détecter les nouvelles propagations de la dette WL

**Comportement**:
- Recherche les patterns `\.whiteLabel|isWhiteLabel` dans le code
- Exclut les fichiers autorisés (dette existante documentée)
- Retourne exit 0 si OK, warning si propagation détectée

**Intégration CI suggérée**:
```yaml
# .github/workflows/check-wl-debt.yml (exemple)
jobs:
  check-wl-debt:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: ./scripts/check-wl-debt-propagation.sh
```

**Risques**: Aucun (script standalone, non intégré au build)

---

## 4. Risques globaux

| Risque | Probabilité | Impact | Mitigation |
|--------|-------------|--------|------------|
| Nouveau code ignore whiteLabelAccessor | Moyenne | Faible | Garde-fou + code review |
| Script bash non exécuté en CI | Haute | Moyen | Ajouter à CI ultérieurement |
| Confusion entre couche et usages legacy | Faible | Faible | Documentation claire |

---

## 5. Rollback minimal

### Si problème avec whiteLabelAccessor.ts

```bash
rm server/lib/whiteLabelAccessor.ts
```

Impact: Aucun (fichier non utilisé par le code existant)

### Si problème avec le script

```bash
rm scripts/check-wl-debt-propagation.sh
```

Impact: Aucun (script standalone)

### Rollback complet Phase 1

```bash
git revert HEAD  # Si commité
# ou
rm server/lib/whiteLabelAccessor.ts
rm scripts/check-wl-debt-propagation.sh
rm docs/rapports/report_phase_1_wl_debt_*.md
```

Impact: Retour à l'état pré-Phase 1, aucune régression fonctionnelle.

---

## 6. Intégration future (hors scope)

### Pour utiliser la couche dans le code existant

Exemple de migration d'un guard existant :

**Avant** (dette actuelle):
```typescript
// server/lib/subscriptionGuards.ts:56
if (community.whiteLabel) {
  return { allowed: true, reason: "white_label_bypass" };
}
```

**Après** (Phase 2.x):
```typescript
import { isWhiteLabelBypassEnabledSync } from "./whiteLabelAccessor";

// DEBT(WL): encapsulated — do not extend outside WL module
if (isWhiteLabelBypassEnabledSync(community)) {
  return { allowed: true, reason: "white_label_bypass" };
}
```

**Prérequis**: Contrat P2.x validé, tests de non-régression.

---

## 7. Vérification post-déploiement

### Commandes de vérification

```bash
# 1. Vérifier que l'application démarre
npm run dev
# Attendre "server ready" dans les logs

# 2. Vérifier TypeScript compile
npx tsc --noEmit
# Doit retourner sans erreur

# 3. Vérifier garde-fou
./scripts/check-wl-debt-propagation.sh
# Doit afficher: ✅ Aucune nouvelle propagation détectée

# 4. Vérifier tests existants
npm test
# Les tests existants doivent passer
```

---

**Fin du rapport diff.**
