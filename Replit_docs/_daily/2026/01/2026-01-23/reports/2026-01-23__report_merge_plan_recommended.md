# Plan de Merge Recommandé : Phase 1 WL + Enterprise non-WL

**Date**: 2026-01-23  
**Auteur**: Agent  
**Branche source**: `staging`  
**Branche cible**: `main`

---

## A) Résumé Exécutif

Le chantier de merge comprend **~48 commits** sur `staging` non présents dans `main`, représentant **~60k lignes** de modifications sur **453 fichiers**.

**Stratégie recommandée** : Découpage en **3 PRs séquentielles** pour isoler les risques :

1. **PR1 - Subscription Foundation** : Trial, limits, billing enforcement, purge (déjà stable)
2. **PR2 - WL Debt Encapsulation** : `whiteLabelAccessor.ts` + garde-fou + rapports Phase 1 WL
3. **PR3 - Enterprise Bypass** : Guards modifiés + UI SaaS Owner pour Enterprise non-WL

Chaque PR est autonome et peut être rollback indépendamment. Aucune migration DB n'est requise.

---

## B) Découpage en PRs

### PR1 : Subscription Foundation (Trial + Limits + Billing + Purge)

**But** : Merger l'infrastructure de gestion des abonnements (trial 14j, limites plan, enforcement billing, purge J+90).

**Commits inclus** (du plus ancien au plus récent) :
- `8196251` Implement trial limits and block money features until subscription is active
- `f4d6c59` Improve subscription checks for payment-related functionalities
- `1d7c295` Restrict access to payment features based on active subscription status
- `733918c` Add a prominent trial banner to the admin interface
- `72bfb2a` Add suspension reason for members exceeding community limits
- `66c4cd9` Adjust trial expiration and member suspension logic
- `51bf8ca` Implement past due trial banner and protect suspended members count
- `f56e758` Improve plan limit enforcement and member suspension handling
- `9970073` Add subscription enforcement to block premium features for overdue accounts
- `8ede39b` Implement automatic downgrade, suspension, and data purging
- `5416741` Implement automatic data purging for inactive communities
- `3e37e6f` Implement usage limits and capacity enforcement for community plans
- `da0450b` Enforce plan limits and capabilities across the application
- `f99674f` Document existing application capabilities and contract annex
- `1d4752c` Generate contract annex and conformity report
- `fe31952` Add detailed status and capability exposure for user accounts
- `4835daf` Add endpoint to expose community subscription state and details

**Fichiers majeurs modifiés** :
| Fichier | Type | Risque |
|---------|------|--------|
| `server/lib/subscriptionGuards.ts` | Nouveau | Moyen |
| `server/lib/usageLimitsGuards.ts` | Nouveau | Moyen |
| `server/lib/planLimits.ts` | Nouveau | Moyen |
| `server/lib/effectiveStateService.ts` | Nouveau | Faible |
| `server/services/purgeService.ts` | Nouveau | Moyen |
| `server/routes.ts` | Modifié | Élevé |
| `server/storage.ts` | Modifié | Élevé |
| `client/src/pages/admin/*.tsx` | Modifié | Moyen |

**Points d'attention** :
- `server/routes.ts` est une **hot zone** (4000+ lignes de diff)
- Conflit probable avec main sur routes.ts → résolution manuelle requise
- `subscriptionGuards.ts` utilise des helpers de `whiteLabelAccessor.ts` (PR2)

**Smoke tests avant merge** :
1. `npm run build` → compilation réussie
2. `npm run dev` → démarrage sans erreur
3. Test endpoint `/api/communities/:id/subscription-state` → 200 OK
4. Test trial banner visible pour community en trial
5. Test membre suspendu non comptabilisé dans quotas

**Rollback** :
```bash
git revert --no-commit <sha_pr1>
npm run build
```

---

### PR2 : WL Debt Encapsulation (Phase 1 WL A+D)

**But** : Encapsuler la dette WL sans casser les clients existants. Introduire `whiteLabelAccessor.ts` comme point central.

**Commits inclus** :
- `6bd6a60` Document client model ambiguities and historical debt
- `3311eb2` Document governance rules for white-label debt
- `8f49c8e` Create strategic report on white-label debt
- `0fb636f` Centralize white-label checks and prevent new direct usages

**Fichiers modifiés** :
| Fichier | Type | Risque |
|---------|------|--------|
| `server/lib/whiteLabelAccessor.ts` | Nouveau | Faible |
| `server/lib/subscriptionGuards.ts` | Modifié | Moyen |
| `scripts/check-wl-debt-propagation.sh` | Nouveau | Faible |
| `docs/rapports/report_phase_1_wl_*.md` | Nouveau | Aucun |

**Dépendances** :
- PR1 doit être mergée avant (subscriptionGuards.ts dépend de whiteLabelAccessor)

**Points d'attention** :
- `subscriptionGuards.ts` est modifié dans PR1 ET PR2 → conflit probable
- Solution : cherry-pick `0fb636f` APRÈS PR1

**Smoke tests avant merge** :
1. `./scripts/check-wl-debt-propagation.sh` → PASSED
2. `npx tsc --noEmit` → compilation OK
3. Community WL existante : accès backoffice sans changement
4. Community standard : trial enforced normalement

**Rollback** :
```bash
git revert 0fb636f
# whiteLabelAccessor devient unused, mais pas d'impact fonctionnel
```

---

### PR3 : Enterprise Bypass + UI SaaS Owner

**But** : Permettre la création de clients Enterprise non-WL via l'UI SaaS Owner, avec bypass des guards.

**Commits inclus** :
- `e286a95` Add strategic report analyzing enterprise client onboarding
- `b4380db` Add enterprise bypass functionality to subscription and usage guards
- `1af8753` Add ability to create enterprise clients without white-label branding

**Fichiers modifiés** :
| Fichier | Type | Risque |
|---------|------|--------|
| `server/lib/planLimits.ts` | Modifié | Moyen |
| `server/lib/subscriptionGuards.ts` | Modifié | Moyen |
| `server/lib/usageLimitsGuards.ts` | Modifié | Moyen |
| `server/lib/whiteLabelAccessor.ts` | Modifié | Faible |
| `server/routes.ts` | Modifié | Moyen |
| `server/storage.ts` | Modifié | Moyen |
| `client/src/pages/platform/SuperDashboard.tsx` | Modifié | Moyen |

**Dépendances** :
- PR2 doit être mergée avant (whiteLabelAccessor doit exister)

**Points d'attention** :
- Logique bypass : `accountType === GRAND_COMPTE` OU `whiteLabel === true`
- Aucune migration DB (champ `account_type` existe déjà)

**Smoke tests avant merge** :
1. `npx tsc --noEmit` → compilation OK
2. `./scripts/check-wl-debt-propagation.sh` → PASSED
3. UI SaaS Owner : créer client Grand Compte + Koomy App
4. Vérifier DB : `account_type = 'GRAND_COMPTE'`, `white_label = false`
5. Vérifier bypass : trial/money guards ignorés pour ce client

**Rollback** :
```bash
git revert 1af8753 b4380db
# Garde-fou WL reste, mais Enterprise bypass retiré
```

---

## C) Checklists

### Checklist "Avant Merge" (par PR)

| Item | PR1 | PR2 | PR3 |
|------|-----|-----|-----|
| Compilation TypeScript OK | ☐ | ☐ | ☐ |
| Tests unitaires passent | ☐ | ☐ | ☐ |
| Garde-fou WL OK (`check-wl-debt-propagation.sh`) | N/A | ☐ | ☐ |
| Workflow `npm run dev` démarre | ☐ | ☐ | ☐ |
| Pas de régression endpoint critique | ☐ | ☐ | ☐ |
| Rapports mis à jour | ☐ | ☐ | ☐ |

### Checklist "Après Merge"

| Item | Description |
|------|-------------|
| ☐ | `main` branch updated locally |
| ☐ | `git pull origin main` sur environnement sandbox |
| ☐ | Rebuild complet sandbox |
| ☐ | Smoke tests sandbox passent |
| ☐ | Logs sans erreurs critiques |

### Checklist "Validation Sandbox"

| Test | Critère de succès |
|------|-------------------|
| ☐ Création community standard | Trial 14j visible, money blocked |
| ☐ Création community WL | Bypass trial, accès complet |
| ☐ Création community Enterprise non-WL | `accountType=GRAND_COMPTE`, `whiteLabel=false`, bypass actif |
| ☐ Upgrade plan | Stripe checkout fonctionne |
| ☐ Suspension membre | Membre over-quota suspendu |
| ☐ Purge J+90 | Job exécutable sans erreur |

### Checklist "Go/No-Go Prod"

| Critère | Requis | Status |
|---------|--------|--------|
| Sandbox stable 24h | Oui | ☐ |
| Aucune régression WL signalée | Oui | ☐ |
| Aucune erreur 500 dans logs | Oui | ☐ |
| Backup DB récent | Oui | ☐ |
| Rollback plan documenté | Oui | ☐ |
| Équipe notifiée | Oui | ☐ |

---

## D) Points Bloquants Éventuels

### Conflit `server/routes.ts`

**Problème** : Fichier massif (4000+ lignes de diff), modifié dans les 3 PRs.

**Contournement** :
1. Merger PR1 d'abord
2. Rebase PR2 sur main après PR1
3. Rebase PR3 sur main après PR2
4. Résoudre conflits manuellement à chaque étape

### Conflit `server/lib/subscriptionGuards.ts`

**Problème** : Modifié dans PR1, PR2 et PR3.

**Contournement** :
1. PR1 crée le fichier
2. PR2 ajoute l'import de `whiteLabelAccessor`
3. PR3 ajoute le bypass Enterprise

Les modifications sont additives (pas de suppression), donc conflits résolubles.

### Dépendance implicite `whiteLabelAccessor`

**Problème** : PR3 utilise `shouldBypassGuardsSync()` de `whiteLabelAccessor.ts` créé en PR2.

**Contournement** : Respecter l'ordre PR1 → PR2 → PR3, pas de parallélisation.

---

## E) Récapitulatif des fichiers "Hot Zones"

| Fichier | Commits | Risque | Notes |
|---------|---------|--------|-------|
| `server/routes.ts` | 20+ | **Élevé** | Merge manuel requis |
| `server/storage.ts` | 10+ | Moyen | Interface WhiteLabelUpdate modifiée |
| `server/lib/subscriptionGuards.ts` | 5+ | Moyen | Logique guards critique |
| `server/lib/planLimits.ts` | 3+ | Moyen | Ajout isEnterprise |
| `client/src/pages/platform/SuperDashboard.tsx` | 3+ | Moyen | UI modal WL étendue |

---

## F) Timeline Recommandée

| Jour | Action | Durée estimée |
|------|--------|---------------|
| J+0 matin | PR1 : Préparation + tests locaux | 2h |
| J+0 midi | PR1 : Merge staging → main (sandbox) | 1h |
| J+0 après-midi | PR1 : Validation sandbox | 2h |
| J+1 matin | PR2 : Rebase + merge | 1h |
| J+1 midi | PR2 : Validation sandbox + WL non-régression | 2h |
| J+1 après-midi | PR3 : Rebase + merge | 1h |
| J+1 soir | PR3 : Validation Enterprise non-WL | 2h |
| J+2 | Go/No-Go production | - |

**Total estimé** : 2 jours de travail safe.

---

**Fin du rapport.**
