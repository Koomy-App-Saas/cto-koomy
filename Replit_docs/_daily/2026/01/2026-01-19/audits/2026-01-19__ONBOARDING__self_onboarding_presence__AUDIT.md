# AUDIT DE PRÉSENCE — Self-Onboarding / Join Link

**Date:** 2026-01-20  
**Type:** Audit (inspection uniquement)  
**Scope:** Fonctionnalité /join/{slug}, enrollment_requests, workflow OPEN/CLOSED

---

## 1. Résumé exécutif

**Verdict: La logique backend est INTACTE et FONCTIONNELLE. La logique frontend de configuration est INTACTE. La gestion des demandes en attente (approve/reject) est ABSENTE de l'UI.**

| Composant | État |
|-----------|------|
| Backend - Endpoints | ✅ Présent et fonctionnel |
| Backend - Storage | ✅ Présent et fonctionnel |
| Backend - Schema DB | ✅ Présent et complet |
| Frontend - Page /join | ✅ Présent et fonctionnel |
| Frontend - Panel Settings | ✅ Présent et fonctionnel |
| Frontend - Liste demandes | ❌ ABSENT |
| Frontend - Actions approve/reject | ❌ ABSENT |

---

## 2. Backend — Analyse détaillée

### 2.1 Endpoints API

| Endpoint | Fichier | Ligne | État |
|----------|---------|-------|------|
| `GET /api/join/:slug` | server/routes.ts | 8975 | ✅ Présent et fonctionnel |
| `POST /api/join/:slug` | server/routes.ts | 9045 | ✅ Présent et fonctionnel |
| `GET /api/communities/:id/enrollment-requests` | server/routes.ts | 9247 | ✅ Présent, non appelé depuis UI |
| `POST .../enrollment-requests/:id/approve` | server/routes.ts | 9275 | ✅ Présent, non appelé depuis UI |
| `POST .../enrollment-requests/:id/reject` | server/routes.ts | 9398 | ✅ Présent, non appelé depuis UI |
| `PATCH .../self-enrollment/settings` | server/routes.ts | ~9550 | ✅ Présent et utilisé |
| `POST .../self-enrollment/generate-slug` | server/routes.ts | 9576 | ✅ Présent et utilisé |

### 2.2 Méthodes Storage

| Méthode | Fichier | Ligne | État |
|---------|---------|-------|------|
| `createEnrollmentRequest` | server/storage.ts | 3414 | ✅ Présent et fonctionnel |
| `getEnrollmentRequest` | server/storage.ts | 3419 | ✅ Présent et fonctionnel |
| `getEnrollmentRequestsByEmail` | server/storage.ts | 3424 | ✅ Présent et fonctionnel |
| `getCommunityEnrollmentRequests` | server/storage.ts | 3434 | ✅ Présent, non appelé depuis UI |
| `getCommunityEnrollmentRequestsCount` | server/storage.ts | 3454 | ✅ Présent et fonctionnel |
| `updateEnrollmentRequest` | server/storage.ts | 3468 | ✅ Présent et fonctionnel |
| `approveEnrollmentRequest` | server/storage.ts | 3476 | ✅ Présent, non appelé depuis UI |
| `rejectEnrollmentRequest` | server/storage.ts | 3489 | ✅ Présent, non appelé depuis UI |
| `convertEnrollmentRequest` | server/storage.ts | 3503 | ✅ Présent et fonctionnel |
| `getExpiredEnrollmentRequests` | server/storage.ts | 3516 | ✅ Présent et fonctionnel |
| `getCommunityBySlug` | server/storage.ts | 3526 | ✅ Présent et fonctionnel |

### 2.3 Tables et Colonnes (shared/schema.ts)

| Élément | Ligne | État |
|---------|-------|------|
| `enrollment_requests` table | 505 | ✅ Défini avec 25+ colonnes |
| `enrollmentRequestStatusEnum` | (implicite) | ✅ PENDING, APPROVED, REJECTED, CONVERTED |
| `selfEnrollmentChannelEnum` | 97 | ✅ OFFLINE, ONLINE |
| `selfEnrollmentModeEnum` | 102 | ✅ OPEN, CLOSED |
| `communities.selfEnrollmentEnabled` | 336 | ✅ boolean |
| `communities.selfEnrollmentChannel` | 337 | ✅ enum |
| `communities.selfEnrollmentMode` | 338 | ✅ enum |
| `communities.selfEnrollmentSlug` | 339 | ✅ text, unique |
| `communities.selfEnrollmentEligiblePlans` | 340 | ✅ jsonb |
| `communities.selfEnrollmentRequiredFields` | 341 | ✅ jsonb |
| `communities.selfEnrollmentSectionsEnabled` | 342 | ✅ boolean |
| `insertEnrollmentRequestSchema` | 1107 | ✅ Zod schema |
| `EnrollmentRequest` type | 1146 | ✅ Type exporté |
| `InsertEnrollmentRequest` type | 1183 | ✅ Type exporté |

---

## 3. Backend — Conditions bloquantes

### 3.1 Conditions dans GET /join/:slug (ligne 8975-9040)

```typescript
// Condition 1: selfEnrollmentEnabled doit être true
if (!community.selfEnrollmentEnabled) {
  return res.status(404).json({ error: "L'inscription en ligne n'est pas activée..." });
}

// Condition 2: selfEnrollmentChannel doit être "ONLINE"
if (community.selfEnrollmentChannel !== "ONLINE") {
  return res.status(404).json({ error: "L'inscription en ligne n'est pas disponible" });
}
```

**Impact:** Ces conditions sont LÉGITIMES (feature flags). Si une communauté n'a pas activé le self-enrollment OU n'a pas choisi le canal ONLINE, la page /join retourne 404.

### 3.2 Conditions dans POST /join/:slug (ligne 9045-9100)

```typescript
// Même validation que GET
if (!community.selfEnrollmentEnabled || community.selfEnrollmentChannel !== "ONLINE") {
  return res.status(404).json({ error: "L'inscription en ligne n'est pas disponible" });
}
```

### 3.3 Aucun flag forcé (false, throw early, return)

Aucune logique de court-circuit artificiel n'a été trouvée. Les conditions existantes sont des feature flags normaux.

---

## 4. Frontend — Analyse détaillée

### 4.1 Routing

| Route | Fichier | Ligne | État |
|-------|---------|-------|------|
| `/join/:slug` | client/src/App.tsx | 228 | ✅ Enregistrée et active |

### 4.2 Page JoinPage.tsx (461 lignes)

| Fonctionnalité | État |
|----------------|------|
| Fetch community via GET /api/join/:slug | ✅ Fonctionnel |
| Affichage logo, nom, couleur communauté | ✅ Fonctionnel |
| Sélection plan d'adhésion | ✅ Fonctionnel |
| Sélection sections (si activé) | ✅ Fonctionnel |
| Formulaire email, prénom, nom, téléphone | ✅ Fonctionnel |
| Consentement RGPD | ✅ Fonctionnel |
| Soumission via POST /api/join/:slug | ✅ Fonctionnel |
| Affichage message de confirmation | ✅ Fonctionnel |
| Gestion quota épuisé | ✅ Fonctionnel |

### 4.3 Panel Settings.tsx — SelfEnrollmentPanel (lignes 1570-1963)

| Fonctionnalité | État |
|----------------|------|
| Toggle selfEnrollmentEnabled | ✅ Visible et fonctionnel |
| Input slug personnalisable | ✅ Visible et fonctionnel |
| Bouton "Générer un lien" | ✅ Visible et fonctionnel |
| Bouton "Copier lien" | ✅ Visible et fonctionnel |
| Bouton "Ouvrir lien" (preview) | ✅ Visible et fonctionnel |
| Select canal (ONLINE/OFFLINE) | ✅ Visible et fonctionnel |
| Select mode (OPEN/CLOSED) | ✅ Visible et fonctionnel |
| Checkboxes formules éligibles | ✅ Visible et fonctionnel |
| Toggle sections activées | ✅ Visible et fonctionnel |
| Bouton "Enregistrer" | ✅ Visible et fonctionnel |

### 4.4 ABSENT — Gestion des demandes

| Fonctionnalité | État | Impact |
|----------------|------|--------|
| Liste des demandes d'inscription (PENDING) | ❌ ABSENT | Admin ne voit pas les demandes |
| Appel GET /api/communities/:id/enrollment-requests | ❌ Non appelé | Aucun fetch des demandes |
| Bouton "Approuver" | ❌ ABSENT | Impossible d'approuver |
| Bouton "Rejeter" | ❌ ABSENT | Impossible de rejeter |
| Compteur de demandes en attente | ❌ ABSENT | Pas de notification |
| Détail d'une demande | ❌ ABSENT | Pas de vue détaillée |

---

## 5. Points de blocage exacts

### 5.1 Backend (aucun blocage technique)

Le backend est 100% opérationnel. Toutes les APIs sont prêtes.

### 5.2 Frontend (manque d'UI)

| Fichier | Problème |
|---------|----------|
| `client/src/pages/admin/Settings.tsx` | `SelfEnrollmentPanel` ne contient aucune section pour lister/gérer les demandes |
| `client/src/` | Aucun composant `EnrollmentRequestsList` ou équivalent |
| `client/src/` | Aucun appel à `/api/communities/:id/enrollment-requests` |

---

## 6. Conclusion

### Diagnostic final

**"La logique est INTACTE mais PARTIELLEMENT DÉBRANCHÉE côté UI."**

| Aspect | Conclusion |
|--------|------------|
| Backend | 100% fonctionnel, aucune régression |
| Frontend - Configuration | 100% fonctionnel, onglet "Inscription en ligne" opérationnel |
| Frontend - Page /join | 100% fonctionnel, formulaire complet |
| Frontend - Gestion demandes | 0% implémenté, UI absente |

### Ce qui fonctionne aujourd'hui

1. Admin peut activer l'inscription en ligne ✅
2. Admin peut générer et partager le lien /join ✅
3. Visiteur peut soumettre une demande ✅
4. La demande est créée en base (status=PENDING) ✅

### Ce qui ne fonctionne PAS (manque d'UI)

1. Admin ne peut pas VOIR les demandes en attente ❌
2. Admin ne peut pas APPROUVER une demande ❌
3. Admin ne peut pas REJETER une demande ❌
4. Aucune notification de nouvelles demandes ❌

### Recommandation

La régression suspectée n'est PAS une suppression de code. C'est une **implémentation incomplète** :
- Phase 1-3 (config + formulaire) = implémentée
- Phase 4 (gestion admin des demandes) = **jamais implémentée**

Pour restaurer la fonctionnalité complète, il faut créer :
1. Composant `EnrollmentRequestsList`
2. Appels API vers `/enrollment-requests`, `/approve`, `/reject`
3. Intégration dans Settings.tsx ou page dédiée

---

## Annexe — Fichiers analysés

| Fichier | Lignes concernées |
|---------|-------------------|
| shared/schema.ts | 95-105, 334-342, 503-542, 1107, 1146, 1183 |
| server/storage.ts | 341-353, 3412-3530 |
| server/routes.ts | 8968-9042, 9245-9420, 9550-9633 |
| client/src/App.tsx | 226-229 |
| client/src/pages/JoinPage.tsx | 1-461 (complet) |
| client/src/pages/admin/Settings.tsx | 270-277, 918-920, 1553-1963 |
