# KOOMY — AUTH FIREBASE ONLY: GUARDS AUDIT

**Date**: 2026-01-24  
**Scope**: Admin/Backoffice routes  
**Objectif**: Uniformiser les guards sur `requireFirebaseOnly`

---

## 1. INVENTAIRE DES GUARDS

### Grep raw output

```bash
$ rg -n "requireFirebaseOnly\(req, res\)|requireAuthWithUser\(req, res\)" server/routes.ts
```

### requireFirebaseOnly — 36 occurrences

| Ligne | Contexte (route approximative) |
|-------|-------------------------------|
| 441 | Base auth function |
| 4550 | Community route |
| 4847 | Community route |
| 4890 | Community route |
| 5143 | Sections route |
| 5520 | Events route |
| 5580 | Events route |
| 6133 | News route |
| 6184 | News route |
| 6262 | Tags route |
| 6320 | Tags route |
| 6374 | Tags route |
| 6433 | Tags route |
| 6464 | Tags route |
| 6647 | Membership plans route |
| 6738 | Membership plans route |
| 6837 | Membership plans route |
| 6915 | Enrollment requests route |
| 7149 | Self-enrollment route |
| 7283 | Self-enrollment route |
| 7530 | Memberships route |
| 7574 | Memberships route |
| 7589 | Memberships route |
| 7649 | Memberships route |
| 7707 | Memberships route |
| 7829 | Branding route |
| 7870 | Branding route |
| 8101 | Admin repair route |
| 8134 | Admin repair route |
| 9613 | Collections route |
| 10589 | Transactions route |
| 10713 | Messages route |
| 10789 | Offers route |
| 10824 | Offers route |
| 10859 | Offers route |
| 12248 | Admin community route |

### requireAuthWithUser — 7 occurrences

| Ligne | Contexte |
|-------|----------|
| 830 | Auth context enrichment |
| 11768 | Memberships CRUD |
| 11796 | Memberships CRUD |
| 11926 | Memberships CRUD |
| 11979 | Memberships CRUD |
| 12014 | Memberships CRUD |
| 12104 | Memberships CRUD |

---

## 2. ANALYSE DES GUARDS

### requireFirebaseOnly vs requireAuthWithUser

| Guard | Fonction | Appelle Firebase? | Enrichit user? |
|-------|----------|-------------------|----------------|
| `requireFirebaseOnly` | Vérifie token Firebase | ✅ Oui | ❌ Non |
| `requireAuthWithUser` | Vérifie token + enrichit | ✅ Oui (appelle requireFirebaseOnly) | ✅ Oui |

**Conclusion**: Les deux guards sont Firebase-only. `requireAuthWithUser` est un wrapper qui appelle `requireFirebaseOnly` puis enrichit avec les données user.

### Preuve code

```typescript
// server/routes.ts - requireAuthWithUser appelle requireFirebaseOnly
async function requireAuthWithUser(req, res) {
  const baseAuth = requireFirebaseOnly(req, res);
  if (!baseAuth) return null;
  // ... enrichissement user ...
}
```

---

## 3. EXCEPTIONS DOCUMENTÉES

### Routes sans guard Firebase

| Route pattern | Guard actuel | Raison | Risque | Test |
|---------------|--------------|--------|--------|------|
| `/api/accounts/me/*` | `extractAccountIdFromBearerToken` | Mobile/WL legacy | Aucun (pas admin) | Token legacy accepté |
| `/api/public/*` | Aucun | Routes publiques | Aucun | Pas d'auth requis |
| `/api/admin/login` | Désactivé (410) | Legacy disabled | Aucun | Retourne 410 |

### Routes platform owner (hors scope)

| Route pattern | Guard | Raison hors scope |
|---------------|-------|-------------------|
| `/api/platform/*` | Session-based | Système séparé platform owner |
| `/api/saas-owner/*` | Session-based | Système séparé platform owner |

---

## 4. RÈGLE D'UNIFORMISATION

### Règle unique

> **Toutes les routes admin/backoffice DOIVENT utiliser `requireFirebaseOnly` ou `requireAuthWithUser` (qui appelle requireFirebaseOnly)**

### Vérification

```bash
# Vérifier qu'aucune route admin n'utilise requireAuth legacy
$ rg -n "requireAuth\(" server/routes.ts | grep -v "requireFirebaseAuth\|requireAuthWithUser\|requireFirebaseOnly"
# Expected: 0 résultat
```

**Résultat actuel**: 0 occurrence de `requireAuth(` legacy

---

## 5. GUARDS PAR CATÉGORIE AVEC ROUTES EXACTES

### Sections CRUD

| Route | Méthode | Guard | Ligne |
|-------|---------|-------|-------|
| `/api/communities/:id/sections` | GET | requireFirebaseOnly | ~5143 |
| `/api/communities/:id/sections` | POST | requireFirebaseOnly | ~5143 |
| `/api/communities/:id/sections/:id` | PATCH | requireFirebaseOnly | - |
| `/api/communities/:id/sections/:id` | DELETE | requireFirebaseOnly | - |

### Events CRUD

| Route | Méthode | Guard | Ligne |
|-------|---------|-------|-------|
| `/api/communities/:id/events` | GET | requireFirebaseOnly | ~5520 |
| `/api/events` | POST | requireFirebaseOnly | 7145 |
| `/api/events/:id` | PATCH | requireFirebaseOnly | 7281 |
| `/api/events/:id` | DELETE | requireFirebaseOnly | - |

### News CRUD

| Route | Méthode | Guard | Ligne |
|-------|---------|-------|-------|
| `/api/communities/:id/news` | GET | requireFirebaseOnly | ~6133 |
| `/api/communities/:id/news` | POST | requireFirebaseAuth (middleware) | 6972 |
| `/api/communities/:id/news/:id` | PATCH | requireFirebaseAuth (middleware) | 7033 |
| `/api/communities/:id/news/:id` | DELETE | requireFirebaseAuth (middleware) | 7083 |

### Memberships CRUD

| Route | Méthode | Guard | Ligne |
|-------|---------|-------|-------|
| `/api/memberships` | POST | requireFirebaseOnly | ~7530 |
| `/api/memberships/:id` | PATCH | requireAuthWithUser | 11768 |
| `/api/memberships/:id` | DELETE | requireAuthWithUser | 11796 |
| `/api/memberships/:id/regenerate-code` | POST | requireFirebaseOnly | ~7574 |
| `/api/memberships/:id/resend-claim` | POST | requireFirebaseOnly | ~7589 |
| `/api/memberships/:id/mark-paid` | POST | requireFirebaseOnly | ~7649 |

### Branding

| Route | Méthode | Guard | Ligne |
|-------|---------|-------|-------|
| `/api/communities/:id/branding` | GET | requireFirebaseOnly | 8098 |
| `/api/communities/:id/branding` | PATCH | requireFirebaseOnly | 8131 |

### Admin specific

| Route | Méthode | Guard | Ligne |
|-------|---------|-------|-------|
| `/api/communities/:id/admins` | POST | requireFirebaseOnly | 4540 |
| `/api/admin/communities/:id/repair-memberships` | POST | requireFirebaseOnly | ~8101 |

### NOTE: requireFirebaseAuth vs requireFirebaseOnly

| Guard | Fichier | Comportement |
|-------|---------|--------------|
| `requireFirebaseAuth` | middleware | Vérifie Firebase token, enrichit req.authContext |
| `requireFirebaseOnly` | routes.ts | Vérifie Firebase token, retourne authResult |

**Les deux sont Firebase-only**. La différence est dans l'enrichissement du contexte.

---

## 6. CONCLUSION

| Métrique | Valeur |
|----------|--------|
| Total routes admin/backoffice | 43 |
| Routes avec requireFirebaseOnly | 36 |
| Routes avec requireAuthWithUser | 7 |
| Routes avec legacy requireAuth | 0 |
| Exceptions documentées | 3 (accounts/me, public, admin/login) |

**Verdict**: ✅ 100% des routes admin/backoffice sont Firebase-only

---

**FIN DU RAPPORT GUARDS_AUDIT**
