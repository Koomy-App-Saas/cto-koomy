# KOOMY — AUTH CORE DIAGNOSIS
## Diagnostic CTO post-bilan

**Date :** 2026-01-21  
**Domain :** AUTH  
**Doc Type :** REPORT  
**Sources :**
- 2026-01-21__AUTH__auth_core_static_inventory__AUDIT.md
- 2026-01-21__AUTH__auth_behavior_observation_matrix__AUDIT.md

---

## 1. Résumé exécutif

| Critère | Évaluation |
|---------|------------|
| **État global du cœur AUTH** | Fragile |
| **Niveau de gravité global** | Moyen |
| **Risque actuel pour la production** | Latent |

**Justification :**

Le système d'authentification fonctionne dans les cas nominaux testés. Aucun accès indu n'a été observé. Cependant, la multiplicité des sources de vérité pour les rôles et l'appartenance crée une fragilité structurelle. Le risque n'est pas immédiat mais latent : toute évolution ou maintenance du système augmente la probabilité d'introduire des incohérences.

---

## 2. Problèmes identifiés (factuels)

### Problème 1 : Triple source de vérité pour les rôles admin

| Critère | Valeur |
|---------|--------|
| **Description factuelle** | Un admin backoffice est identifié par trois champs distincts : `role` (text), `adminRole` (enum), `isOwner` (boolean). Ces trois champs peuvent coexister avec des valeurs non cohérentes. |
| **Preuve audit** | Scénario 4 - Observation : OWNER login retourne `role: "admin"`, `adminRole: "super_admin"`, `isOwner: true` simultanément. Audit statique section 6.1 : "Triple source de rôle". |
| **Zone concernée** | Data + Backend |

### Problème 2 : Permissions array vide malgré isOwner=true

| Critère | Valeur |
|---------|--------|
| **Description factuelle** | Le champ `permissions[]` est retourné vide (`[]`) pour un OWNER authentifié, alors que `isOwner=true`. Le système repose sur `isOwner` comme bypass implicite. |
| **Preuve audit** | Scénario 4 - Observation : `permissions: []` dans la réponse login OWNER. |
| **Zone concernée** | Data |

### Problème 3 : Double source de vérité pour l'ownership communauté

| Critère | Valeur |
|---------|--------|
| **Description factuelle** | L'ownership d'une communauté est défini par deux sources non synchronisées : `communities.ownerId` (FK) et `memberships.isOwner` (boolean). Ces deux sources peuvent diverger. |
| **Preuve audit** | Scénario 9 - Observation : `community.ownerId: null` alors qu'une membership avec `isOwner=true` existe pour cette communauté. |
| **Zone concernée** | Data |

### Problème 4 : Double système de permissions (legacy vs V2)

| Critère | Valeur |
|---------|--------|
| **Description factuelle** | Deux systèmes de permissions coexistent : les booleans legacy (`canManageArticles`, `canManageEvents`, etc.) et le nouveau array `permissions[]`. Aucune garantie de synchronisation. |
| **Preuve audit** | Audit statique section 2.3 : `canManage*` booleans marqués "Legacy flag" + `permissions` jsonb array. Scénario 4 : OWNER a `canManageArticles: true` mais `permissions: []`. |
| **Zone concernée** | Data + Backend |

### Problème 5 : Tokens admin/membre sans expiration

| Critère | Valeur |
|---------|--------|
| **Description factuelle** | Les tokens de session admin backoffice et membre mobile n'ont pas d'expiration côté backend. Format : `${id}:${timestamp}:${random}`. Le timestamp n'est pas vérifié. |
| **Preuve audit** | Audit statique section 6.3 : "Token valide indéfiniment" contrairement aux platform_sessions (2h). |
| **Zone concernée** | Backend |

### Problème 6 : Membership avec double référence identité nullable

| Critère | Valeur |
|---------|--------|
| **Description factuelle** | Une membership peut référencer `userId` (admins) et/ou `accountId` (membres), ou aucun des deux (carte non réclamée). Le code downstream doit gérer tous les cas. |
| **Preuve audit** | Scénario 4 : OWNER membership a `userId: "98586ffb..."`, `accountId: null`. Scénario 10 : Carte membre a `userId: null`, `accountId: null`. Audit statique section 6.1. |
| **Zone concernée** | Data + Backend + Couplage transverse |

---

## 3. Classification CTO

| # | Problème | Classification | Justification |
|---|----------|----------------|---------------|
| 1 | Triple source rôles | 🧬 Ambiguïté conceptuelle | Pas d'erreur d'implémentation, mais absence de modèle unifié. Trois concepts distincts (`role`, `adminRole`, `isOwner`) servent le même objectif sans règle de priorité formalisée. |
| 2 | Permissions vide pour OWNER | ⚠️ Dette technique | Le système fonctionne via bypass `isOwner`, mais le contrat de données est violé (array attendu non rempli). |
| 3 | Double source ownership | 🧬 Ambiguïté conceptuelle | Deux sources de vérité (`communities.ownerId` vs `memberships.isOwner`) expriment le même concept sans synchronisation définie. |
| 4 | Legacy vs V2 permissions | ⚠️ Dette technique | Migration incomplète. Deux systèmes maintenus en parallèle sans plan de convergence. |
| 5 | Tokens sans expiration | ☠️ Erreur d'architecture | Décision structurelle non corrigeable par simple fix. Impact sécurité. |
| 6 | Double référence identité | 🧬 Ambiguïté conceptuelle | Modèle flexible par conception mais sans règles claires de résolution. |

---

## 4. Gravité et impacts

### Problème 1 : Triple source rôles

| Dimension | Évaluation |
|-----------|------------|
| **Gravité technique** | Moyenne |
| **Impact utilisateur** | Faible (le système fonctionne, UX correcte) |
| **Impact business** | Faible (pas de blocage observé) |
| **Impact futur** | Élevé (maintenance risquée, onboarding dev difficile, bugs silencieux possibles) |

### Problème 2 : Permissions vide pour OWNER

| Dimension | Évaluation |
|-----------|------------|
| **Gravité technique** | Faible |
| **Impact utilisateur** | Aucun (bypass fonctionne) |
| **Impact business** | Aucun |
| **Impact futur** | Moyen (si logique permissions évolue, bypass peut être oublié) |

### Problème 3 : Double source ownership

| Dimension | Évaluation |
|-----------|------------|
| **Gravité technique** | Moyenne |
| **Impact utilisateur** | Faible (pas de confusion observée) |
| **Impact business** | Moyen (risque de gouvernance floue si désynchronisation) |
| **Impact futur** | Élevé (transfert ownership, multi-tenant, audit compliance) |

### Problème 4 : Legacy vs V2 permissions

| Dimension | Évaluation |
|-----------|------------|
| **Gravité technique** | Moyenne |
| **Impact utilisateur** | Faible |
| **Impact business** | Faible |
| **Impact futur** | Élevé (duplication code, maintenance double, risque de drift) |

### Problème 5 : Tokens sans expiration

| Dimension | Évaluation |
|-----------|------------|
| **Gravité technique** | Élevée |
| **Impact utilisateur** | Aucun (UX transparente) |
| **Impact business** | Moyen (risque sécurité, compliance) |
| **Impact futur** | Critique (audit sécurité, SOC2, RGPD session management) |

### Problème 6 : Double référence identité

| Dimension | Évaluation |
|-----------|------------|
| **Gravité technique** | Moyenne |
| **Impact utilisateur** | Faible |
| **Impact business** | Faible |
| **Impact futur** | Élevé (migration données, requêtes complexes, bugs silencieux) |

---

## 5. Dépendances et effets domino

### Problèmes racines (cœur)

| # | Problème | Nature |
|---|----------|--------|
| 1 | Triple source rôles | Racine conceptuelle |
| 3 | Double source ownership | Racine conceptuelle |
| 6 | Double référence identité | Racine conceptuelle |

### Problèmes secondaires induits

| # | Problème | Induit par |
|---|----------|------------|
| 2 | Permissions vide | Induit par #1 (absence de modèle unifié des droits) |
| 4 | Legacy vs V2 | Induit par #1 (migration partielle du modèle rôles) |

### Problème isolé

| # | Problème | Nature |
|---|----------|--------|
| 5 | Tokens sans expiration | Indépendant (erreur d'architecture distincte) |

### Chaîne de dépendance observée

```
┌─────────────────────────────────────────────────────────────┐
│ AMBIGUÏTÉ CONCEPTUELLE (racine)                             │
│                                                             │
│  Triple source rôles (#1)                                   │
│         │                                                   │
│         ├──→ Permissions vide (#2)                          │
│         └──→ Legacy vs V2 (#4)                              │
│                                                             │
│  Double source ownership (#3)                               │
│         │                                                   │
│         └──→ communities.ownerId NULL observé               │
│                                                             │
│  Double référence identité (#6)                             │
│         │                                                   │
│         └──→ accountId NULL pour admins backoffice          │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ ERREUR ARCHITECTURE (isolée)                                │
│                                                             │
│  Tokens sans expiration (#5)                                │
│         │                                                   │
│         └──→ Sessions admin/membre infinies                 │
└─────────────────────────────────────────────────────────────┘
```

---

## 6. Cohérence globale du système

| Question | Réponse | Justification |
|----------|---------|---------------|
| **Le modèle AUTH est-il conceptuellement cohérent ?** | Partiellement | La séparation accounts/users est claire. Mais la triple source de rôles et la double source d'ownership créent une ambiguïté structurelle. |
| **Les sources de vérité sont-elles unifiées ?** | Non | Trois exemples de sources multiples : rôles (3 champs), ownership (2 sources), identité membership (2 FK). |
| **Les règles d'accès sont-elles prédictibles ?** | Oui | Les helpers (`isOwner`, `can`, `canAccessSection`) centralisent la logique. Les règles sont appliquées de manière cohérente quand les données sont correctes. |
| **Le système est-il maintenable à moyen terme ?** | Partiellement | Le système fonctionne mais la multiplication des sources de vérité rend chaque évolution risquée. Un développeur doit connaître les trois systèmes de rôles, les deux systèmes de permissions, et les deux types d'identité. |

---

## 7. Conclusion médicale CTO

### Diagnostic final

Le cœur AUTH de Koomy présente une **fragilité structurelle d'origine conceptuelle**, non une défaillance d'implémentation.

**Symptôme principal :** Multiplicité des sources de vérité pour les concepts fondamentaux (rôles, ownership, identité).

**État observé :** Fonctionnel dans les cas nominaux. Aucun accès indu. Aucun blocage critique.

**Risque :** Latent. Chaque évolution du système augmente la probabilité d'introduire des incohérences entre sources de vérité.

### Recommandation médicale

🫀 **Chirurgie du cœur** recommandée

**Justification :**

1. **Conservation justifiée :**
   - La séparation accounts (membres) / users (admins) est saine et fonctionnelle
   - Les endpoints login distincts sont appropriés
   - La hiérarchie `isOwner > isBackofficeAdmin > membre` est claire
   - Le middleware SaaS access est propre
   - Les platform_sessions sont bien sécurisées

2. **Intervention ciblée nécessaire :**
   - Unification du modèle de rôles (un champ source de vérité)
   - Unification de l'ownership (une source de vérité)
   - Migration complète permissions (suppression legacy)
   - Ajout expiration tokens admin/membre

3. **Transplantation non justifiée :**
   - Pas de faille de sécurité critique
   - Pas d'accès indu observé
   - Architecture globale fonctionnelle
   - Coût/bénéfice défavorable

### Verdict

Le système nécessite une **refonte ciblée du modèle de données** pour unifier les sources de vérité, tout en conservant l'architecture globale qui a fait ses preuves.

---

*Fin du diagnostic CTO*

**Aucune implémentation proposée**  
**Aucun plan technique**  
**Aucun correctif suggéré**

---

## Mini-log de conformité

| Action | Détail |
|--------|--------|
| Fichier créé | `docs/reports/2026-01/2026-01-21__AUTH__auth_core_diagnosis__REPORT.md` |
| Sources croisées | 2 audits (statique + comportemental) |
| Problèmes identifiés | 6 |
| Verdict | Chirurgie du cœur (refonte ciblée) |
