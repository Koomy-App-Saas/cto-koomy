# Self-Onboarding UI — Phase 4 Report

**Date:** 2026-01-20  
**Type:** Implémentation UI  
**Scope:** Gestion admin des demandes d'inscription (approve/reject)

---

## 1. Résumé

La Phase 4 du self-onboarding a été implémentée : l'interface admin pour visualiser et gérer les demandes d'inscription en attente.

| Fonctionnalité | État |
|----------------|------|
| Liste des demandes PENDING | ✅ Implémenté |
| Bouton "Approuver" | ✅ Implémenté |
| Bouton "Rejeter" avec confirmation | ✅ Implémenté |
| Rafraîchissement après action | ✅ Implémenté |
| Feedback visuel (toast) | ✅ Implémenté |

---

## 2. Composants ajoutés

### EnrollmentRequestsPanel

**Fichier:** `client/src/pages/admin/Settings.tsx`  
**Lignes:** 2002-2117 (nouveau composant)

**Fonctionnalités:**
- Fetch des demandes via `GET /api/communities/:id/enrollment-requests?status=PENDING`
- Affichage de chaque demande avec :
  - Prénom / Nom
  - Email
  - Téléphone (si renseigné)
  - Formule choisie
  - Date de création
- Bouton "Approuver" → `POST .../enrollment-requests/:id/approve`
- Bouton "Rejeter" → Modal de confirmation → `POST .../enrollment-requests/:id/reject`
- Toast de succès après chaque action
- Invalidation du cache pour rafraîchir la liste

---

## 3. Fichiers modifiés

| Fichier | Modification |
|---------|--------------|
| `client/src/pages/admin/Settings.tsx` | Ajout imports (XCircle, Clock, User, AlertDialog), ajout composant EnrollmentRequestsPanel, intégration dans SelfEnrollmentPanel |

---

## 4. Endpoints utilisés (existants, non modifiés)

| Endpoint | Méthode | Utilisation |
|----------|---------|-------------|
| `/api/communities/:id/enrollment-requests` | GET | Liste des demandes (filtré par status=PENDING) |
| `/api/communities/:id/enrollment-requests/:requestId/approve` | POST | Approuver une demande |
| `/api/communities/:id/enrollment-requests/:requestId/reject` | POST | Rejeter une demande |

---

## 5. Intégration UI

Le composant `EnrollmentRequestsPanel` est affiché dans l'onglet "Inscription en ligne" de Settings.tsx, **uniquement si** :
- `selfEnrollmentEnabled` = true
- `selfEnrollmentChannel` = "ONLINE"

Il apparaît sous la carte de configuration des paramètres d'inscription.

---

## 6. Checklist de test manuel

### Prérequis
- [ ] Avoir une communauté avec self-enrollment activé (channel = ONLINE)
- [ ] Avoir généré un slug d'inscription
- [ ] Avoir soumis au moins une demande via /join/{slug}

### Tests

| Test | Étapes | Résultat attendu |
|------|--------|------------------|
| Affichage liste vide | Aller dans Settings > Inscription en ligne, aucune demande soumise | Message "Aucune demande en attente" |
| Affichage demandes | Soumettre une demande via /join, revenir dans Settings | La demande apparaît dans la liste |
| Approuver | Cliquer "Approuver" | Toast "Demande approuvée", demande disparaît de la liste |
| Rejeter | Cliquer "Rejeter" > Confirmer | Toast "Demande rejetée", demande disparaît de la liste |
| Infos affichées | Vérifier les infos d'une demande | Prénom, nom, email, formule, date visibles |

---

## 7. Non implémenté (hors scope)

- ❌ Emails automatiques post-approbation/rejet
- ❌ Filtres avancés (par statut, date, etc.)
- ❌ Pagination
- ❌ Paiement Stripe
- ❌ Modification backend

---

## 8. Conformité

| Règle | Respectée |
|-------|-----------|
| Aucune modification backend | ✅ |
| Aucune modification statuts/enums | ✅ |
| Aucun nouveau champ | ✅ |
| UI cohérente avec l'admin existant | ✅ |
| Code isolé sans dette | ✅ |
| Patterns existants réutilisés | ✅ |
