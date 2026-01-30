# KOOMY — IMPACT MAP POST MIGRATION

**Date**: 2026-01-24  
**Scope**: Firebase-only migration impacts  
**Format**: Table avec risques et tests

---

## 1. UI IMPACTS

| Domaine | Changement | Risque | Symptôme | Fix | Test de non-régression |
|---------|------------|--------|----------|-----|------------------------|
| Google Button (Admin) | Bloqué avec toast error | Faible | Admin clique → toast "Google non disponible" | Masquer bouton ou afficher disabled | Click Google → toast apparaît |
| Google Button (Member) | Reste actif | Aucun | Fonctionne normalement | N/A | Login Google membre OK |
| Erreur mdp incorrect | Firebase error mapping | Moyen | Code technique affiché | Mapping codes → messages FR | Mauvais mdp → "Mot de passe incorrect" |
| Erreur compte inexistant | Firebase error mapping | Moyen | "user-not-found" affiché | Mapping → "Aucun compte avec cet email" | Email inexistant → message clair |
| Écran claim code | Peut apparaître après login | Élevé | User bloqué sur écran claim | Skip si déjà membre | Login → direct dashboard |
| Redirections post-login | Dépend communityId | Moyen | Redirect vers mauvaise page | Vérifier communityId avant redirect | Login → dashboard correct |

---

## 2. AUTHCONTEXT / HYDRATION

| Domaine | Changement | Risque | Symptôme | Fix | Test de non-régression |
|---------|------------|--------|----------|-----|------------------------|
| `koomy_auth_token` | Conservé pour WL legacy | Faible | Token legacy lu mais non utilisé admin | Ignorer si non-WL | Token absent → Firebase utilisé |
| `koomy_auth_token_ts` | Timestamp legacy | Faible | Expiration mal calculée | Utiliser Firebase token expiry | F5 après 2h → reste connecté |
| Firebase token persistence | localStorage par Firebase | Aucun | Token auto-refreshé | N/A | Session persiste après F5 |
| communityId localStorage | Clé custom persistée | Moyen | Si absent → URLs cassées | Guard validateCommunityId | Clear communityId → message erreur |

### Clés localStorage

| Clé | Statut post-migration | Action |
|-----|----------------------|--------|
| `koomy_auth_token` | CONSERVÉ (WL only) | Ignorer pour admin standard |
| `koomy_auth_token_ts` | CONSERVÉ (WL only) | Ignorer pour admin standard |
| `firebase:*` | ACTIF | Token Firebase persisté |
| `koomy_community_id` | ACTIF | Requis pour API calls |

---

## 3. PERMISSIONS / RBAC

| Domaine | Changement | Risque | Symptôme | Fix | Test de non-régression |
|---------|------------|--------|----------|-----|------------------------|
| Admin role required | 403 si non-admin | Moyen | Membre tente action admin | Message clair "Rôle admin requis" | Membre → 403 sur POST section |
| Community mismatch | 403 si mauvaise communauté | Moyen | Admin d'autre club | Message "Accès non autorisé" | Admin club A → 403 sur club B |
| Firebase token expired | 401 auto-refresh | Faible | Token expiré silencieusement | Auto-refresh via Firebase SDK | Session longue → refresh auto |
| Legacy token rejeté | 401 FIREBASE_AUTH_REQUIRED | Aucun | Token legacy sur route admin | Erreur claire + redirect login | Token legacy → 401 + redirect |

---

## 4. COMMUNITY SELECTION

| Domaine | Changement | Risque | Symptôme | Fix | Test de non-régression |
|---------|------------|--------|----------|-----|------------------------|
| communityId vide | URLs `/api/communities//` | ÉLEVÉ | 404 ou erreur serveur | Guard global validateCommunityId | Clear localStorage → message UI |
| communityId undefined | URLs avec "undefined" | ÉLEVÉ | 404 | Early return si !communityId | communityId=undefined → pas d'appel |
| Multi-club admin | 1 admin = 1 club (règle) | Moyen | Blocking screen | Afficher écran "Config non supportée" | Admin 2 clubs → blocking screen |
| Aucun club | Blocking screen | Moyen | Admin sans club | Afficher "Aucun club associé" | Admin 0 clubs → blocking screen |

### Zones où communityId requis

| Zone | Fichier | Nb usages | Guard existant |
|------|---------|-----------|----------------|
| Members page | `pages/admin/Members.tsx` | 10 | ⚠️ Aucun |
| Settings page | `pages/admin/Settings.tsx` | 20+ | ⚠️ Aucun |
| Dashboard | `pages/admin/Dashboard.tsx` | 5 | ⚠️ Aucun |
| Sections page | `pages/admin/Sections.tsx` | 6 | ⚠️ Aucun |
| MobileAdminLayout | `components/MobileAdminLayout.tsx` | 15 | ⚠️ Aucun |
| API helpers | `lib/api.ts` | 5 | ⚠️ Aucun |

---

## 5. SÉCURITÉ

| Domaine | Changement | Risque | Symptôme | Fix | Test de non-régression |
|---------|------------|--------|----------|-----|------------------------|
| /api/admin/login | Retourne 410 GONE | Aucun | Endpoint inaccessible | N/A | POST → 410 |
| Token legacy sur admin | 401 rejected | Aucun | Accès refusé | N/A | Token 33 chars → 401 |
| Firebase token verify | Server-side validation | Aucun | Token validé par Firebase Admin | N/A | Token invalide → 401 |
| Session hijacking | Firebase handles | Aucun | Tokens signés cryptographiquement | N/A | Fake token → rejected |

---

## 6. MOBILE / NATIVE

| Domaine | Changement | Risque | Symptôme | Fix | Test de non-régression |
|---------|------------|--------|----------|-----|------------------------|
| Wallet app (membre) | Firebase auth | Aucun | Login membre Firebase | N/A | Login membre OK |
| Admin mobile app | Firebase auth | Faible | Login admin Firebase | Tester sur device | Login admin mobile OK |
| Token storage native | getAuthToken() | Moyen | Token legacy vs Firebase | Vérifier source token | Token source = Firebase |
| Deep links | Redirect après login | Moyen | Mauvaise destination | Tester deep links | Deep link → correct screen |

### Écrans mobile impactés

| App | Écran | Impact | Test |
|-----|-------|--------|------|
| MemberApp | Login | Firebase only | Login email → dashboard |
| MemberApp | Register | Firebase only | Register → claim flow |
| AdminApp | Login | Firebase only | Login admin → dashboard |
| AdminApp | CRUD | Firebase guards | Create event → success |

---

## 7. RÉSUMÉ DES RISQUES

| Niveau | Domaine | Count |
|--------|---------|-------|
| ÉLEVÉ | communityId vide | 2 |
| MOYEN | Error mapping UI | 3 |
| MOYEN | Community selection | 2 |
| MOYEN | Permissions | 2 |
| FAIBLE | Token legacy | 2 |
| AUCUN | Sécurité | 4 |

### Top 3 risques à adresser

1. **communityId vide** → Guard global à implémenter
2. **Écran claim code** → Skip si déjà membre
3. **Error mapping** → Vérifier tous les codes Firebase

---

**FIN IMPACT_MAP_POST_MIGRATION**
