# KOOMY — AUTH Phase 3 — Guards Lot 1 (WRITE Critique)

**Date :** 2026-01-21  
**Domain :** AUTH  
**Doc Type :** RAPPORT  
**Scope :** Backend (Sandbox)  
**Statut :** Finalisé  
**Environnement :** Sandbox (KOOMY_ENV=sandbox)

---

## Objectif

Application progressive des guards Firebase sur le premier lot de routes WRITE critiques.

---

## Flag KOOMY_AUTH_BACKFILL_EMAIL

| Variable | Description | Défaut Sandbox | Défaut Prod |
|----------|-------------|----------------|-------------|
| `KOOMY_AUTH_BACKFILL_EMAIL` | Active le fallback email + backfill firebase_uid | `true` | `false` |

**Comportement :**
- Si `true` : lookup par firebase_uid, puis fallback par email + backfill automatique
- Si `false` : lookup par firebase_uid uniquement (pas de backfill)
- Log sécurisé : `firebase_uid` + `account_id` uniquement (pas d'email en clair)

---

## Hiérarchie des Rôles (Phase 3 Simplifiée)

```
OWNER (isOwner=true) > ADMIN (role="admin") > MANAGER > MEMBER
```

**Rôles réservés (non utilisés Phase 3) :**
- `SUPER_ADMIN` (défini dans schema, pas appliqué)
- `DELEGATE` (défini dans schema, pas appliqué)
- Sous-types `adminRole` (support_admin, finance_admin, etc.)

---

## Routes Protégées (Lot 1)

### Routes Modifiées

| Route | Méthode | Guard(s) | Niveau | Risque |
|-------|---------|----------|--------|--------|
| `/api/communities/:id` | PUT | `requireMembership("id")` + `requireAdmin` | ADMIN | Élevé |
| `/api/communities/:communityId/admins` | POST | `requireMembership("communityId")` + `requireOwner` | OWNER | Critique |
| `/api/memberships/:id` | DELETE | `requireFirebaseAuth` + vérif admin via authContext | ADMIN | Critique |
| `/api/memberships/:id` | PATCH | `requireFirebaseAuth` + vérif admin via authContext | ADMIN | Élevé |

**Note :** DELETE/PATCH memberships vérifient le rôle admin via `authContext.memberships` (pas storage lookup).

### Routes Hors Scope (Non Modifiées)

| Route | Raison |
|-------|--------|
| `/api/payments/*` | Webhooks Stripe |
| `/api/billing/*` | Subscriptions |
| `/api/platform/*` | Auth séparée plateforme |
| `/api/collections/*` | Paiements |

---

## Tests Manuels

### Test 1 : Sans Token Firebase → 401

| Route | Méthode | Résultat | Code |
|-------|---------|----------|------|
| `/api/communities/test-id` | PUT | `{"error":"auth_required"}` | 401 |
| `/api/communities/test-id/admins` | POST | `{"error":"auth_required"}` | 401 |
| `/api/memberships/test-id` | DELETE | `{"error":"auth_required"}` | 401 |
| `/api/memberships/test-id` | PATCH | `{"error":"auth_required"}` | 401 |

**Verdict : PASS** - Toutes les routes protégées rejettent les requêtes sans token.

### Tests à valider avec token Firebase (via /__auth_test)

| Scénario | Attendu | À tester |
|----------|---------|----------|
| Token valide, pas de membership | 403 `membership_required` | Manuel |
| Token valide, MEMBER sur communauté | 403 `insufficient_role` (sur admin routes) | Manuel |
| Token valide, ADMIN sur communauté | 200 OK | Manuel |
| Token valide, OWNER sur communauté | 200 OK (toutes routes) | Manuel |

---

## Fichiers Modifiés

| Fichier | Modification |
|---------|-------------|
| `server/routes.ts` | Import guards + application sur 4 routes |
| `server/middlewares/attachAuthContext.ts` | Flag KOOMY_AUTH_BACKFILL_EMAIL + log sécurisé |
| `server/middlewares/guards.ts` | Documentation hiérarchie Phase 3 |
| `docs/audits/2026-01-21__AUTH__routes_audit_phase3.md` | Audit routes complet |

---

## Codes d'Erreur Normalisés

| Code HTTP | Code Erreur | Description |
|-----------|-------------|-------------|
| 401 | `auth_required` | Token Firebase absent ou invalide |
| 403 | `membership_required` | Pas de membership dans la communauté |
| 403 | `insufficient_role` | Rôle insuffisant pour l'opération |
| 400 | `missing_community_id` | Paramètre communityId absent |

---

## Prochaines Étapes

1. **Tests avec token Firebase réel** via /__auth_test
2. **Lot 2** : Routes sections/catégories (si Lot 1 stable)
3. **Décision prod** : Après validation sandbox complète

---

## Conclusion

- 4 routes WRITE critiques protégées avec guards Firebase Phase 3
- Flag KOOMY_AUTH_BACKFILL_EMAIL permet contrôle sandbox/prod
- Tests sans token : 100% PASS (401 sur toutes les routes)
- Aucune modification sur paiements/webhooks/facturation
