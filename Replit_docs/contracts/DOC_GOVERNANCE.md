# Koomy - Gouvernance Documentaire

**Version**: 1.0  
**Date**: 2026-01-21  
**Statut**: En vigueur

---

## 1. Principes Fondamentaux

### 1.1 Aucune suppression

Les documents ne sont jamais supprimés. Les documents obsolètes sont déplacés vers `/docs/archives/`.

### 1.2 Aucun écrasement

Un fichier existant ne peut pas être écrasé. En cas de mise à jour majeure, créer une nouvelle version avec suffixe `-v2`, `-v3`, etc.

### 1.3 Traçabilité

Toute modification documentaire doit être traçable via Git. Les déplacements/renommages sont documentés dans les rapports de réorganisation.

---

## 2. Convention de Nommage (Obligatoire)

### 2.1 Format standard

```
YYYY-MM-DD__DOMAIN__TOPIC__DOC_TYPE.md
```

### 2.2 Composants

| Composant | Description | Valeurs |
|-----------|-------------|---------|
| `YYYY-MM-DD` | Date ISO | 2026-01-21 |
| `DOMAIN` | Domaine fonctionnel | AUTH, ROLES, PAYMENTS, ONBOARDING, SECURITY, WL, UI, DATA, INFRA, OTHER |
| `TOPIC` | Description courte | snake_case, sans accents |
| `DOC_TYPE` | Type de document | AUDIT, REPORT, PLAN, DECISION, INCIDENT, PROCEDURE, SPEC, CHECKLIST, RUNBOOK |

### 2.3 Exemples conformes

```
2026-01-21__ROLES__backoffice_role_simplification__REPORT.md
2026-01-21__AUTH__admin_login_500__INCIDENT.md
2026-01-20__PAYMENTS__membership_plans_500_fix__REPORT.md
2026-01-19__ONBOARDING__self_onboarding_presence__AUDIT.md
```

---

## 3. Arborescence

```
docs/
├── _INDEX.md              # Table des matières (source of truth)
├── audits/                # Analyses de l'existant
│   └── YYYY-MM/
│       ├── AUTH/
│       ├── ROLES/
│       ├── PAYMENTS/
│       ├── ONBOARDING/
│       ├── SECURITY/
│       ├── WL/
│       └── OTHER/
├── reports/               # Rapports d'implémentation/correction
│   └── YYYY-MM/
├── decisions/             # ADR (Architecture Decision Records)
│   └── YYYY-MM/
├── incidents/             # Postmortems
│   └── YYYY-MM/
├── implementation/        # Plans et specs d'implémentation
│   └── YYYY-MM/
├── procedures/            # Procédures et runbooks
│   └── YYYY-MM/
├── security/              # Sécurité
│   ├── audits/
│   ├── policies/
│   └── reports/
├── contracts/             # Documents stables (ce fichier)
├── snapshots/             # Copies figées
│   └── YYYY-MM/
└── archives/              # Documents obsolètes
    └── YYYY-MM/
```

---

## 4. Règles de Rangement

| Type de document | Dossier cible |
|------------------|---------------|
| Audit (analyse existant) | `audits/YYYY-MM/DOMAIN/` |
| Rapport (résultat d'action) | `reports/YYYY-MM/` |
| Décision architecturale | `decisions/YYYY-MM/` |
| Incident / Postmortem | `incidents/YYYY-MM/` |
| Plan d'implémentation | `implementation/YYYY-MM/` |
| Procédure / Runbook | `procedures/YYYY-MM/` |
| Audit de sécurité | `security/audits/` |
| Politique de sécurité | `security/policies/` |
| Document contractuel stable | `contracts/` |
| Document obsolète | `archives/YYYY-MM/` |
| Snapshot historique | `snapshots/YYYY-MM/` |

---

## 5. Mise à Jour de l'Index

### 5.1 Obligation

Tout document "structurant" doit être référencé dans `/docs/_INDEX.md`.

### 5.2 Documents structurants

- Audits majeurs
- Décisions architecturales
- Procédures opérationnelles
- Incidents critiques
- Rapports de jalons importants

---

## 6. Format Minimum

### 6.1 Audit

```markdown
# [Titre]

**Date**: YYYY-MM-DD  
**Domaine**: DOMAIN  
**Auteur**: [Nom ou Agent]

## Résumé

## Périmètre analysé

## Observations

## Recommandations

## Prochaines étapes
```

### 6.2 Report

```markdown
# [Titre]

**Date**: YYYY-MM-DD  
**Domaine**: DOMAIN

## Résumé exécutif

## Contexte

## Actions réalisées

## Résultats

## Prochaines étapes
```

### 6.3 Incident

```markdown
# [Titre]

**Date**: YYYY-MM-DD  
**Sévérité**: Critique/Haute/Moyenne/Basse

## Résumé

## Timeline

## Cause racine

## Impact

## Actions correctives

## Leçons apprises
```

---

## 7. Prompt Compliance

### 7.1 Règle

Quand un audit, report, plan, ou tout autre document est demandé, le fichier livré **doit** :

1. Respecter la convention de nommage
2. Être placé dans le bon dossier
3. Être référencé dans `_INDEX.md` si structurant
4. Suivre le format minimum correspondant

### 7.2 Non-conformité

Toute livraison non conforme doit être refusée et corrigée avant acceptation.

### 7.3 Vérification

Avant de livrer un document :

```
□ Nom conforme : YYYY-MM-DD__DOMAIN__TOPIC__TYPE.md
□ Dossier correct selon le type
□ Format minimum respecté
□ _INDEX.md mis à jour si nécessaire
```

---

## 8. Historique

| Date | Version | Changement |
|------|---------|------------|
| 2026-01-21 | 1.0 | Création initiale |

---

**Ce document est la source of truth pour la gouvernance documentaire Koomy.**
