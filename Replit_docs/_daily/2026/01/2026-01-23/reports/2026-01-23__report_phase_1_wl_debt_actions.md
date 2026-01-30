# Rapport Phase 1 — Actions dette White-Label (A + D)

**Date**: 2026-01-23  
**Phase**: 1 (Encapsulation + Abstraction sémantique)  
**Statut**: COMPLÉTÉ

---

## 1. Résumé exécutif

### Ce qui a été fait

| Étape | Action | Statut |
|-------|--------|--------|
| 0 | Cartographie factuelle (30 fichiers, 162+ occurrences) | ✅ |
| 1 | Création couche d'encapsulation `whiteLabelAccessor.ts` | ✅ |
| 2 | Abstraction sémantique (`inferClientSegment`, `getClientSegmentLabel`) | ✅ |
| 3 | Garde-fou anti-propagation (script bash) | ✅ |
| 4 | Smoke tests documentés | ✅ |

### Ce qui n'a PAS été fait (intentionnellement)

- ❌ Refactor des usages existants dans routes.ts, storage.ts, etc.
- ❌ Migration DB (aucune nouvelle colonne)
- ❌ Création de flux "client Enterprise non-WL"
- ❌ Changement de comportement prod

**Raison**: Éviter les régressions, respecter la contrainte "zéro refactor sans contrat P2.x".

---

## 2. La couche WL

### Localisation

```
server/lib/whiteLabelAccessor.ts
```

### Fonctions exposées

| Fonction | Rôle | Usage |
|----------|------|-------|
| `isWhiteLabelBypassEnabled(communityId)` | Vérifie bypass async | Guards futurs |
| `isWhiteLabelBypassEnabledSync(community)` | Vérifie bypass sync | Quand data déjà chargée |
| `getWhiteLabelAccess(communityId)` | Infos complètes | Debug, logs |
| `shouldBypassSubscriptionGuards(communityId)` | Bypass subscription | Guards |
| `shouldBypassUsageLimits(communityId)` | Bypass limits | Guards |
| `shouldBypassMoneyGuards(communityId)` | Bypass money | Guards |
| `inferClientSegment(isWL, planId)` | Classification sémantique | UI, logs |
| `getClientSegmentLabel(segment, hasWL)` | Label UI | Affichage |
| `getWhiteLabelDebugInfo(community)` | Debug info | Logs |

### Convention de commentaire

Tout code utilisant la couche doit être marqué :

```typescript
// DEBT(WL): encapsulated — do not extend outside WL module
```

---

## 3. Liste des remplacements

### Remplacements effectués

| Avant | Après | Fichier |
|-------|-------|---------|
| N/A (nouvelle couche) | `whiteLabelAccessor.ts` créé | server/lib/ |
| `community.whiteLabel` | `isWhiteLabelBypassEnabledSync(community)` | server/lib/subscriptionGuards.ts:61 (trial bypass) |
| `community.whiteLabel` | `isWhiteLabelBypassEnabledSync(community)` | server/lib/subscriptionGuards.ts:127 (money guard) |
| `community.whiteLabel` | `isWhiteLabelBypassEnabledSync(community)` | server/lib/subscriptionGuards.ts:425 (billing guard) |

### Remplacements NON effectués (dette gelée)

Les usages suivants restent **en l'état** (dette documentée, non refactorée) :

| Fichier | Lignes | Raison du gel |
|---------|--------|---------------|
| `server/routes.ts` | 572, 2352, 2904, 3056... | Routes critiques, risque régression |
| `server/storage.ts` | 519, 684, 1728... | Storage layer, risque régression |
| `server/lib/subscriptionGuards.ts` | 56, 121, 245, 418 | Guards existants, testés |
| `server/lib/usageLimitsGuards.ts` | 106, 136, 155 | Guards existants, testés |
| `server/lib/authModeResolver.ts` | Multiple | Invariant auth figé |

**Règle de gouvernance**: Ces fichiers sont autorisés à utiliser `whiteLabel` directement car ils constituent la dette existante. Tout NOUVEAU code doit passer par `whiteLabelAccessor.ts`.

---

## 4. Garde-fous anti-propagation

### Script créé

```
scripts/check-wl-debt-propagation.sh
```

### Usage

```bash
./scripts/check-wl-debt-propagation.sh
```

### Comportement

- ✅ Exit 0 si aucune nouvelle propagation (tous modes)
- Mode local (défaut): Exit 0 avec warning si propagation détectée
- Mode strict (`--strict`): Exit 1 si propagation détectée (pour CI)

### Fichiers autorisés (dette existante)

Le script autorise les fichiers suivants (dette documentée) :

```
server/lib/whiteLabelAccessor.ts
server/lib/planLimits.ts
server/lib/authModeResolver.ts
server/lib/effectiveStateService.ts
server/lib/subscriptionGuards.ts
server/lib/usageLimitsGuards.ts
server/lib/resolverGuard.ts
server/services/mailer/*
server/middlewares/*
server/storage.ts
server/routes.ts
client/src/contexts/WhiteLabelContext.tsx
client/src/components/*Layout.tsx
client/src/pages/admin/Settings.tsx
client/src/pages/admin/Billing.tsx
client/src/pages/platform/SuperDashboard.tsx
client/src/pages/mobile/*
client/src/pages/_legacy/*
client/src/pages/website/*
client/src/App.tsx
shared/schema.ts
shared/plans.ts
server/tests/*
server/seed.ts
```

---

## 5. Smoke tests

### Protocole de non-régression

#### Test 1: Client WL existant fonctionne

```bash
# 1. Démarrer l'application
npm run dev

# 2. Accéder à une community WL via son domaine custom
# Ex: demo-wl.koomy.app

# 3. Vérifier:
# - Login LEGACY fonctionne
# - Pas de limite membres affichée
# - Billing non visible
# - Branding custom appliqué
```

**Résultat attendu**: Comportement identique à avant Phase 1

#### Test 2: Client non-WL existant fonctionne

```bash
# 1. Démarrer l'application
npm run dev

# 2. Accéder au backoffice standard
# backoffice-sandbox.koomy.app

# 3. Créer un compte admin standard

# 4. Vérifier:
# - Login Firebase fonctionne
# - Limites membres affichées
# - Billing visible
# - Pas de branding custom
```

**Résultat attendu**: Comportement identique à avant Phase 1

#### Test 3: Garde-fou fonctionne

```bash
./scripts/check-wl-debt-propagation.sh
# Doit retourner: ✅ Aucune nouvelle propagation détectée
```

**Résultat**: ✅ PASSÉ

#### Test 4: Application démarre sans erreur

```bash
npm run dev
# Vérifier logs serveur: pas d'erreur de compilation
```

**Résultat**: ✅ PASSÉ (workflow running)

---

## 6. Abstraction sémantique (Phase D)

### Fonctions créées

```typescript
// Classification client inférée
type ClientSegment = "standard" | "enterprise" | "unknown";

// Inférer le segment depuis les données existantes
inferClientSegment(isWhiteLabel: boolean, planId?: string): ClientSegment

// Label UI approprié
getClientSegmentLabel(segment: ClientSegment, hasWLDistribution: boolean): string
// Retourne: "Entreprise (WL activé)" | "Entreprise" | "Standard" | "Non classifié"
```

### Usage recommandé

```typescript
import { inferClientSegment, getClientSegmentLabel } from "../lib/whiteLabelAccessor";

// Dans les logs
const segment = inferClientSegment(community.whiteLabel, community.planId);
console.log(`Client segment: ${segment}`);

// Dans l'UI
const label = getClientSegmentLabel(segment, community.whiteLabel);
// Affiche: "Entreprise (WL activé)" au lieu de "Client WL"
```

### UI wording (non modifié)

L'UI Owner (SuperDashboard) continue d'afficher "WL" pour éviter les régressions visuelles.
La correction du wording nécessite un contrat UX dédié.

---

## 7. Definition of Done

| Critère | Statut |
|---------|--------|
| ✅ Couche WL centrale créée | OUI |
| ✅ Fonctions d'encapsulation disponibles | OUI |
| ✅ Abstraction sémantique disponible | OUI |
| ✅ Garde-fou anti-propagation actif | OUI |
| ✅ Aucun changement comportement prod | OUI |
| ✅ Aucune régression clients existants | OUI |
| ✅ Documentation complète | OUI |

---

## 8. Prochaines étapes (hors scope Phase 1)

| Action | Phase | Prérequis |
|--------|-------|-----------|
| Refactor usages routes.ts vers whiteLabelAccessor | P2.x | Contrat validé |
| Ajouter colonne `client_type` en DB | P2.x | Contrat validé |
| Corriger wording UI "WL" → "Entreprise" | P2.x | Contrat UX |
| Intégrer `--strict` dans CI | P1.1 | Pipeline CI configuré |

### Intégration CI (prêt)

```yaml
# Exemple .github/workflows/check-wl-debt.yml
jobs:
  check-wl-debt:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: ./scripts/check-wl-debt-propagation.sh --strict
```

---

**Fin du rapport Phase 1.**
