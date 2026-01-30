# KOOMY — FOLLOWUPS BACKLOG

**Date**: 2026-01-24  
**Scope**: Corrections post-migration Firebase-only  
**Format**: Priorisé P0/P1/P2/P3

---

## LÉGENDE PRIORITÉS

| Priorité | Définition | SLA |
|----------|------------|-----|
| P0 | Bloquant production | Immédiat |
| P1 | UX critique | < 24h |
| P2 | Tech debt | < 1 semaine |
| P3 | Nice-to-have | Backlog |

---

## P0 — BLOQUANT PRODUCTION

| Priority | Item | Where | Fix outline | Tests | Owner |
|----------|------|-------|-------------|-------|-------|
| P0 | Guard global communityId | `httpClient.ts` | Ajouter `validateCommunityId()` qui throw si vide/undefined | Clear localStorage communityId → erreur UI claire, pas de requête réseau | - |
| P0 | Guard communityId AdminLayout | `AdminLayout.tsx` | Early return avec message "Aucune communauté sélectionnée" si !communityId | F5 sans communityId → écran bloquant propre | - |
| P0 | Empêcher URLs `//` ou `undefined` | Toutes pages admin | Wrapper API calls avec validation | Aucune requête réseau avec `//` dans URL | - |

---

## P1 — UX CRITIQUE

| Priority | Item | Where | Fix outline | Tests | Owner |
|----------|------|-------|-------------|-------|-------|
| P1 | Skip écran claim code si déjà membre | `ClaimVerified.tsx` ou flow post-login | Vérifier membership existant avant affichage | Login membre existant → direct home | - |
| P1 | Mapping erreurs Firebase complet | `firebase.ts` | Ajouter tous les codes: `too-many-requests`, `network-request-failed`, `email-already-in-use`, `weak-password` | Chaque erreur → message FR clair | - |
| P1 | Message erreur 401 FIREBASE_AUTH_REQUIRED | `httpClient.ts` | Intercepter 401 → toast + redirect login | Token expiré → toast "Session expirée" + redirect | - |
| P1 | Message erreur 403 Admin role | Pages admin | Afficher "Vous n'avez pas les droits admin" | Membre sur page admin → message clair | - |
| P1 | Écran blocking 0 clubs | `AdminLayout.tsx` | Si admin.communities.length === 0 → écran "Aucun club associé" | Admin sans club → écran informatif | - |
| P1 | Écran blocking >1 clubs | `AdminLayout.tsx` | Si admin.communities.length > 1 → écran "Configuration non supportée" | Admin 2 clubs → écran informatif | - |

---

## P2 — TECH DEBT

| Priority | Item | Where | Fix outline | Tests | Owner |
|----------|------|-------|-------------|-------|-------|
| P2 | Nettoyage localStorage legacy | `AuthContext.tsx` | Supprimer `koomy_auth_token*` au login Firebase (sauf WL) | Login standard → localStorage propre | - |
| P2 | Réactiver Google Sign-In admin | `UnifiedAuthLogin.tsx`, `UnifiedAuthRegister.tsx` | Supprimer le blocage, tester flow complet | Click Google → login OK → dashboard | - |
| P2 | Normaliser guards frontend | Toutes pages admin | Hook `useRequireAuth()` qui redirect si !user | Accès page sans auth → redirect login | - |
| P2 | Supprimer fichiers `_legacy/` | `pages/_legacy/` | Supprimer ou archiver après confirmation non-usage | Build sans erreurs, pas de références | - |
| P2 | Assertions dev communityId | Toutes pages admin | `console.assert(communityId, 'communityId required')` en dev | Console warnings en dev si problème | - |
| P2 | Uniformiser guard type | `routes.ts` | Utiliser uniquement `requireFirebaseOnly` ou doc clear sur différence | Code review: un seul pattern | - |

---

## P3 — NICE-TO-HAVE

| Priority | Item | Where | Fix outline | Tests | Owner |
|----------|------|-------|-------------|-------|-------|
| P3 | Bouton Google disabled visuellement | `UnifiedAuthLogin.tsx` | Style disabled + tooltip "Bientôt disponible" | Bouton grisé, non-cliquable | - |
| P3 | Logs debug conditionnels | `AuthContext.tsx` | Flag `DEBUG_AUTH` pour activer logs verbeux | Logs visibles seulement si flag activé | - |
| P3 | Monitoring token refresh | Analytics | Tracker fréquence token refresh Firebase | Dashboard analytics | - |
| P3 | Tests E2E auth flows | Cypress/Playwright | Suite complète: login, logout, F5, CRUD | CI/CD green | - |

---

## BATCH FIXES RECOMMANDÉ

### Batch 1: P0 Guards (1-2h)

1. Créer `validateCommunityId()` dans `lib/validation.ts`
2. Intégrer dans `httpClient.ts` avant chaque appel
3. Ajouter guard dans `AdminLayout.tsx`
4. Tester: clear localStorage → erreur propre

### Batch 2: P1 UX (2-3h)

1. Compléter mapping erreurs Firebase
2. Ajouter intercepteur 401/403 dans httpClient
3. Skip claim code si membre existant
4. Écrans blocking 0/1+ clubs

### Batch 3: P2 Cleanup (2-3h)

1. Nettoyage localStorage au login
2. Hook `useRequireAuth()`
3. Audit et suppression `_legacy/`
4. Réactivation Google (optionnel)

---

## MÉTRIQUES SUCCÈS

| Métrique | Avant | Après | Cible |
|----------|-------|-------|-------|
| Requêtes avec `//` | ? | 0 | 0 |
| Erreurs Firebase non mappées | 4+ | 0 | 0 |
| Écrans blocking manquants | 2 | 0 | 0 |
| Fichiers legacy actifs | 3+ | 0 | 0 |

---

## DÉPENDANCES

```
P0 Guards → P1 UX → P2 Cleanup → P3 Nice-to-have
```

Les P0 doivent être faits AVANT de valider en production.

---

**FIN FOLLOWUPS_BACKLOG**
