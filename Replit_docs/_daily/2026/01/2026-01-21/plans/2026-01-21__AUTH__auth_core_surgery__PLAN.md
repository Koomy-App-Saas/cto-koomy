# KOOMY — AUTH CORE
## Plan opératoire CTO (Chirurgie ciblée, zéro dette)

**Date :** 2026-01-21  
**Domain :** AUTH  
**Doc Type :** PLAN  
**Pré-requis validés :**
- 2026-01-21__AUTH__auth_core_static_inventory__AUDIT.md
- 2026-01-21__AUTH__auth_behavior_observation_matrix__AUDIT.md
- 2026-01-21__AUTH__auth_core_diagnosis__REPORT.md

---

## Principes non négociables

- ZÉRO dette technique en sortie
- Source de vérité UNIQUE pour les rôles et permissions
- Backend décide, frontend consomme
- Migration sans downtime
- Sandbox d'abord, prod en dernier
- Traçabilité complète (logs + docs)

---

## Objectif opératoire

Refondre le **cœur AUTH** sans transplantation complète en :
- unifiant les sources de vérité
- clarifiant le modèle conceptuel
- supprimant toute ambiguïté d'accès
- stabilisant les flux multi-tenant

Sans modifier les flows de paiement, onboarding ou white-label
(en dehors des points strictement nécessaires).

---

## Modèle cible (Source of Truth)

### 1. Concepts canoniques

| Concept | Définition |
|---------|------------|
| **User** | Identité humaine (auth Firebase / credentials) |
| **Account (Tenant)** | Entité SaaS (association / communauté / client) |
| **Membership** | Lien User ↔ Account |
| **Role** | OWNER \| ADMIN \| MEMBER (exclusif, unique par membership) |
| **Permission** | Dérivée STRICTEMENT du rôle (pas stockée par user) |

**Règle clé :** Le rôle n'existe JAMAIS hors d'un membership.

### 2. Règles fondamentales

- Un User peut avoir N memberships
- Un membership = 1 rôle
- Un account a TOUJOURS 1 OWNER
- Les permissions sont **calculées**, jamais dupliquées
- Toute décision d'accès est backend-first

---

## Actes chirurgicaux (ordonnés)

### Phase 0 — Gel & Préparation

| Action | Description |
|--------|-------------|
| Gel features | Geler toute feature AUTH |
| Verrouillage | Verrouiller les branches |
| Backup | Snapshot sandbox (backup DB) |

---

### Phase 1 — Nettoyage conceptuel (sans impact prod)

| Action | Description |
|--------|-------------|
| Suppression logique role | Supprimer toute logique "role" hors membership |
| Marquage obsolète | Identifier et marquer les champs obsolètes (DEPRECATED) |
| Centralisation | Centraliser la résolution du rôle dans un service unique |

**Note :** Aucun comportement ne change encore.

---

### Phase 2 — Implémentation du core AUTH unifié

| Action | Description |
|--------|-------------|
| AuthResolver | Créer un **AuthResolver** backend unique |
| Input | `userId` + `accountId` |
| Output | `{ role, permissions, ownership }` |
| Nettoyage | Supprimer toute décision d'accès dispersée |
| Middlewares | Aligner middlewares sur ce resolver |

**Note :** Le frontend ne décide plus.

---

### Phase 3 — Adaptation frontend (consommation stricte)

| Action | Description |
|--------|-------------|
| Conditions locales | Remplacer par des flags serveur |
| Guards UI | Simplifier les guards UI |
| Redirections | Uniformiser les redirections |

**Note :** Aucune logique métier frontend.

---

### Phase 4 — Migration des données (sans downtime)

| Action | Description |
|--------|-------------|
| Script normalisation | Script de normalisation des memberships existants |
| Vérification OWNER | Vérification : 1 OWNER / account |
| Correction auto | Correction automatique des états ambigus |
| Logs | Logs exhaustifs de migration |

**Note :** Rollback possible à tout moment.

---

### Phase 5 — Tests post-op (salle de réveil)

| Action | Description |
|--------|-------------|
| Scénarios audit | Rejouer TOUS les scénarios de l'audit comportemental |
| Tests non-régression | Ajouter tests de non-régression AUTH |
| Cas limites | Tester cas limites (multi-account, orphan user, etc.) |

---

### Phase 6 — Convalescence (sandbox)

| Action | Description |
|--------|-------------|
| Durée | 48–72h de tests exploratoires |
| Monitoring | Monitoring logs AUTH |
| Vérification | Vérification performance et stabilité |

---

### Phase 7 — Sortie vers prod

| Action | Description |
|--------|-------------|
| Déploiement | Déploiement progressif |
| Feature flag | AUTH_CORE_V2 |
| Surveillance | Surveillance renforcée 24–48h |

---

## Critères de succès (Exit Criteria)

| Critère | Statut attendu |
|---------|----------------|
| Aucun accès indu possible | ✅ |
| Aucun état AUTH ambigu | ✅ |
| Aucun champ AUTH redondant | ✅ |
| Tous les scénarios de l'audit passent | ✅ |
| Documentation à jour dans /docs | ✅ |

---

## Interdictions

| Interdiction | Raison |
|--------------|--------|
| Pas de "quick fix" | Crée de la dette |
| Pas de duplication temporaire | Source de vérité unique |
| Pas de logique métier frontend | Backend-first |
| Pas de dette "on verra plus tard" | Zéro dette en sortie |

---

## Documents à mettre à jour après opération

| Document | Action |
|----------|--------|
| `/docs/decisions/` | ADR AUTH v2 |
| `/docs/procedures/` | AUTH runbook |
| `/docs/_INDEX.md` | Mise à jour index |

---

## Note CTO

Cette chirurgie est **fondatrice**.

Une fois terminée, le cœur AUTH sera :
- Prédictible
- Maintenable
- Scalable
- Compatible white-label long terme

Aucune seconde chirurgie ne sera nécessaire si ce plan est respecté à la lettre.

---

## Mini-log de conformité

| Action | Détail |
|--------|--------|
| Fichier créé | `docs/plans/2026-01/2026-01-21__AUTH__auth_core_surgery__PLAN.md` |
| Phases définies | 8 (Phase 0 à Phase 7) |
| Critères de succès | 5 |
| Interdictions | 4 |
