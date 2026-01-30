# KOOMY — AUTH BEHAVIOR OBSERVATION MATRIX
## Étape 2: Audit comportemental — Observation terrain

**Date :** 2026-01-21  
**Domain :** AUTH  
**Doc Type :** AUDIT  
**Prérequis :** 2026-01-21__AUTH__auth_core_static_inventory__AUDIT.md  
**Environnement :** Sandbox (development)

---

## Objectif

Cette matrice documente les observations comportementales du système d'authentification Koomy, en testant des scénarios réels pour identifier les divergences entre comportement attendu et observé.

**Aucune supposition. Aucun jugement technique. Uniquement des faits observables.**

---

## Matrice d'observation

### Scénario 1: Utilisateur sans organisation → login

| Critère | Valeur |
|---------|--------|
| **État initial** | Email non existant dans les tables `users` et `accounts` |
| **Action utilisateur** | `POST /api/admin/login` avec email `nonexistent@test.com` |
| **Résultat observé** | `401 {"error":"Email ou mot de passe incorrect","traceId":"AUDIT-SC1-NOUSER"}` |
| **Résultat attendu** | 401 - Utilisateur inconnu |
| **Divergence** | Non |
| **Gravité perçue** | N/A |

---

### Scénario 2: Utilisateur MEMBER → tentative accès back-office

| Critère | Valeur |
|---------|--------|
| **État initial** | Membership avec `role="member"` existe, mais aucun compte dans table `accounts` (carte non réclamée) |
| **Action utilisateur** | `POST /api/accounts/login` avec email membre |
| **Résultat observé** | `401 {"error":"Email ou mot de passe incorrect"}` |
| **Résultat attendu** | 401 - Compte inexistant dans accounts table |
| **Divergence** | Non |
| **Gravité perçue** | N/A |

**Observation additionnelle :** Les cartes membres créées par admin (sans claim) n'ont pas de compte dans `accounts`, donc login échoue naturellement.

---

### Scénario 3: Utilisateur ADMIN → login backoffice

| Critère | Valeur |
|---------|--------|
| **État initial** | User `admin@portbouet-fc.sandbox` avec membership `adminRole="content_admin"` |
| **Action utilisateur** | `POST /api/admin/login` |
| **Résultat observé** | `{"error":"Trop de tentatives de connexion. Veuillez réessayer dans 15 minutes."}` |
| **Résultat attendu** | Login réussi ou 401 si mauvais password |
| **Divergence** | Oui (rate limiting actif) |
| **Gravité perçue** | Faible |

**Observation :** Le rate limiting fonctionne. Impossible de tester le login ADMIN dans cette session.

---

### Scénario 4: Utilisateur OWNER → login et accès

| Critère | Valeur |
|---------|--------|
| **État initial** | User `owner@portbouet-fc.sandbox` avec membership `isOwner=true`, `adminRole="super_admin"` |
| **Action utilisateur** | `POST /api/admin/login` avec password `Test@12345!` |
| **Résultat observé** | Login réussi. Données retournées : |

```json
{
  "user": {
    "id": "98586ffb-7bb2-4e0a-bdf5-22f13216c867",
    "firstName": "Kouadio",
    "lastName": "Yao",
    "email": "owner@portbouet-fc.sandbox"
  },
  "memberships": [{
    "id": "bae54493-90a6-49d9-b32b-d2ee660bc516",
    "userId": "98586ffb-7bb2-4e0a-bdf5-22f13216c867",
    "accountId": null,
    "communityId": "sandbox-portbouet-fc",
    "role": "admin",
    "adminRole": "super_admin",
    "isOwner": true,
    "sectionScope": "ALL",
    "permissions": []
  }],
  "sessionToken": "98586ffb-7bb2-4e0a-bdf5-22f13216c867:mknrdgu7:6vggviow"
}
```

| Critère | Valeur |
|---------|--------|
| **Résultat attendu** | Login réussi avec memberships |
| **Divergence** | Partielle |
| **Gravité perçue** | Moyenne |

**Observations critiques :**
1. `accountId: null` → OWNER n'a pas de compte mobile lié
2. `permissions: []` → Tableau vide malgré `isOwner=true`
3. `role: "admin"` ET `adminRole: "super_admin"` ET `isOwner: true` → Triple source de vérité

---

### Scénario 5: OWNER → accès ressources protégées

| Critère | Valeur |
|---------|--------|
| **État initial** | Token session OWNER valide |
| **Action utilisateur** | `GET /api/communities/{id}/members` avec Bearer token |
| **Résultat observé** | 200 - Liste des membres retournée |
| **Résultat attendu** | Accès autorisé |
| **Divergence** | Non |
| **Gravité perçue** | N/A |

---

### Scénario 6: User admin tente login via /api/accounts/login

| Critère | Valeur |
|---------|--------|
| **État initial** | User `owner@portbouet-fc.sandbox` existe dans `users` table |
| **Action utilisateur** | `POST /api/accounts/login` avec même email/password |
| **Résultat observé** | `401 {"error":"Email ou mot de passe incorrect"}` |
| **Résultat attendu** | 401 - Compte non trouvé dans `accounts` table |
| **Divergence** | Non |
| **Gravité perçue** | N/A |

**Observation :** La séparation `users` (backoffice) vs `accounts` (mobile) fonctionne. Un admin backoffice n'a pas automatiquement de compte mobile.

---

### Scénario 7: Login avec credentials vides

| Critère | Valeur |
|---------|--------|
| **État initial** | N/A |
| **Action utilisateur** | `POST /api/admin/login` avec `{"email": "", "password": ""}` |
| **Résultat observé** | `400 {"error":"Email et mot de passe requis","traceId":"AUDIT-SC2-EMPTY"}` |
| **Résultat attendu** | 400 - Validation échoue |
| **Divergence** | Non |
| **Gravité perçue** | N/A |

---

### Scénario 8: Membership avec userId mais accountId NULL

| Critère | Valeur |
|---------|--------|
| **État initial** | Membership OWNER avec `userId="98586ffb..."`, `accountId=null` |
| **Action utilisateur** | Login via `/api/admin/login` |
| **Résultat observé** | Login réussi via `users` table lookup |
| **Résultat attendu** | Login réussi |
| **Divergence** | Non |
| **Gravité perçue** | N/A |

**Observation :** Le système gère correctement le cas `accountId=null` pour les admins backoffice.

---

### Scénario 9: Community.ownerId NULL

| Critère | Valeur |
|---------|--------|
| **État initial** | Community `sandbox-portbouet-fc` avec `ownerId: null` |
| **Action utilisateur** | GET community details |
| **Résultat observé** | Community retournée avec `ownerId: null` |
| **Résultat attendu** | ownerId devrait référencer le user owner |
| **Divergence** | Oui |
| **Gravité perçue** | Moyenne |

**Observation critique :** La table `communities` a `ownerId=null` alors qu'une membership avec `isOwner=true` existe. Double source de vérité non synchronisée.

---

### Scénario 10: Membre avec carte non réclamée (accountId NULL, userId NULL)

| Critère | Valeur |
|---------|--------|
| **État initial** | Membership avec `userId=null`, `accountId=null`, `role="member"`, `claimCode="RVQP-N982"` |
| **Action utilisateur** | N/A (observation données) |
| **Résultat observé** | Membership existe sans identité attachée |
| **Résultat attendu** | État valide pour carte non réclamée |
| **Divergence** | Non |
| **Gravité perçue** | N/A |

**Observation :** Les cartes membres créées par admin existent avec `userId=null` ET `accountId=null`, en attente de claim via code.

---

## Résumé des divergences identifiées

| # | Scénario | Divergence | Gravité |
|---|----------|------------|---------|
| 4 | OWNER login | `permissions: []` vide malgré `isOwner=true` | Moyenne |
| 4 | OWNER login | Triple source rôle: `role`, `adminRole`, `isOwner` | Moyenne |
| 9 | Community | `ownerId: null` vs membership `isOwner=true` | Moyenne |

---

## Scénarios non testés (limitations)

| Scénario | Raison |
|----------|--------|
| Admin (non-owner) login | Rate limiting actif |
| Switch organisation | Nécessite user multi-community |
| Platform admin login | Requiert IP France |
| Session expirée | Nécessite attente 2h |
| Community SUSPENDU | Aucune community en état suspendu |
| Post-paiement | Stripe non configuré en sandbox |

---

## Journal d'observation

| Critère | Valeur |
|---------|--------|
| Date des tests | 2026-01-21 08:25 UTC |
| Environnement | Sandbox (development) |
| Serveur | localhost:5000 |
| Base de données | Development (Neon PostgreSQL) |
| Comptes utilisés | `owner@portbouet-fc.sandbox` (OWNER), `admin@portbouet-fc.sandbox` (ADMIN - rate limited), `nonexistent@test.com` (test) |
| Limitations | Rate limiting actif sur certains comptes, Stripe non configuré, pas de community SUSPENDU |

---

## Mini-log de conformité

| Action | Détail |
|--------|--------|
| Fichier mis à jour | `docs/audits/2026-01/AUTH/2026-01-21__AUTH__auth_behavior_observation_matrix__AUDIT.md` |
| Tests exécutés | 10 scénarios observés |
| Divergences documentées | 3 |
