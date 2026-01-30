# P2.3 - Périmètre éditorial par section (WRITE-only)

**Date**: 2026-01-26  
**Objectif**: Implémenter le périmètre de section pour les admins "terrain"

## Résumé

Implémentation du périmètre éditorial pour les administrateurs avec restrictions de section :
- **Contenu/Événements** : Lecture globale, création/publication limitée aux sections autorisées
- **UI** : Champ périmètre affiché uniquement si CONTENT ou EVENTS coché

## Champs DB utilisés (existants)

| Champ | Table | Description |
|-------|-------|-------------|
| `sectionScope` | user_community_memberships | "ALL" \| "SELECTED" |
| `sectionIds` | user_community_memberships | JSONB array des section IDs autorisées |

**Note** : Aucune migration requise - les champs existaient déjà dans le schéma.

## Fichiers modifiés

| Fichier | Action | Description |
|---------|--------|-------------|
| `client/src/pages/admin/Admins.tsx` | Modifié | Périmètre affiché si CONTENT/EVENTS coché |
| `server/lib/errors/productError.ts` | Modifié | Ajout codes EDITORIAL_SCOPE_VIOLATION, MESSAGE_SCOPE_VIOLATION |
| `server/routes.ts` | Modifié | ProductError sur violations de périmètre |
| `shared/lib/sectionScope.ts` | Créé | Module partagé avec helpers scope alignés backend |
| `client/src/features/admins/__tests__/editorialScope.test.ts` | Créé | 31 tests du scope (imports réels) |

## Endpoints impactés

### Articles (CONTENT)
| Endpoint | Enforcement |
|----------|-------------|
| `POST /api/news` | WRITE - Vérifie sectionIds dans périmètre |
| `PATCH /api/news/:id` | WRITE - Vérifie sections dans périmètre |
| `GET /api/news/*` | READ - Aucun filtre (lecture globale) |

### Événements (EVENTS)
| Endpoint | Enforcement |
|----------|-------------|
| `POST /api/events` | WRITE - Vérifie sectionId dans périmètre |
| `PATCH /api/events/:id` | WRITE - Vérifie section dans périmètre |
| `GET /api/events/*` | READ - Aucun filtre (lecture globale) |

## Règles appliquées

1. **READ** : Global pour tous les admins (pas de filtre)
2. **WRITE** : Vérifié contre `sectionScope` / `sectionIds`
3. **OWNER** : Accès complet (sectionScope ignoré)
4. **ALL scope** : Aucune restriction
5. **SELECTED scope** : Limité aux sectionIds stockées

## Codes d'erreur ProductError

| Code | HTTP | Contexte |
|------|------|----------|
| `EDITORIAL_SCOPE_VIOLATION` | 403 | Création contenu/événement hors périmètre |
| `MESSAGE_SCOPE_VIOLATION` | 403 | Message hors périmètre (réservé future impl.) |

## Tests ajoutés (31 tests)

### Role Check Functions (8 tests)
| Test | Statut |
|------|--------|
| isOwnerMembership true pour isOwner flag | ✅ |
| isOwnerMembership true pour super_admin (legacy) | ✅ |
| isOwnerMembership false pour admin régulier | ✅ |
| isOwnerMembership false pour null | ✅ |
| isBackofficeAdminMembership true pour owner | ✅ |
| isBackofficeAdminMembership true pour admin role | ✅ |
| isBackofficeAdminMembership true pour adminRole=admin (legacy) | ✅ |
| isBackofficeAdminMembership false pour null | ✅ |

### Section Scope Functions (14 tests)
| Test | Statut |
|------|--------|
| getAllowedSectionIds retourne null pour owner | ✅ |
| getAllowedSectionIds retourne null pour super_admin (legacy) | ✅ |
| getAllowedSectionIds retourne array pour adminRole=admin | ✅ |
| getAllowedSectionIds retourne null pour ALL scope | ✅ |
| getAllowedSectionIds retourne array pour SELECTED scope | ✅ |
| getAllowedSectionIds retourne null pour null membership | ✅ |
| canAccessSection owner accède partout | ✅ |
| canAccessSection ALL scope accède partout | ✅ |
| canAccessSection SELECTED peut accéder sections autorisées | ✅ |
| canAccessSection SELECTED bloqué hors scope | ✅ |
| canAccessSection null sectionId = global → OK | ✅ |
| canAccessSection null membership → false | ✅ |
| validateSectionAccess owner valide toutes sections | ✅ |
| validateSectionAccess SELECTED rejette hors scope | ✅ |

### Enforcement Tests (9 tests)
| Test | Statut |
|------|--------|
| Article création dans section autorisée → OK | ✅ |
| Article création hors scope → échec | ✅ |
| Article global (sans sections) → OK | ✅ |
| Event création dans section autorisée → OK | ✅ |
| Event création hors scope → échec | ✅ |
| Event global (null section) → OK | ✅ |
| validateSectionAccess owner sections multiples | ✅ |
| validateSectionAccess ALL scope sections multiples | ✅ |
| validateSectionAccess empty array always valid | ✅ |

## UI - Périmètre de création éditoriale

Champ affiché **uniquement** si CONTENT ou EVENTS est coché :
- Label : "Périmètre de création éditoriale"
- Description : "Définit les sections où cet admin peut créer du contenu et des événements"
- Options : Switch "Toutes les sections" + multi-select sections si désactivé

## Module partagé `shared/lib/sectionScope.ts`

Fonctions exportées (alignées avec backend routes.ts):
- `isOwnerMembership()` - vérifie isOwner flag + roles legacy (super_admin, owner)
- `isBackofficeAdminMembership()` - inclut adminRole handling
- `getAllowedSectionIds()` - retourne null pour accès complet, array pour scope limité
- `canAccessSection()` - valide accès à une section unique
- `validateSectionAccess()` - valide array de sections

## Conformité contrat

- [x] Scope stocké côté backend (ALL vs SECTIONS + ids)
- [x] UI scope affichée seulement si CONTENT/EVENTS cochés
- [x] Enforcement WRITE-only sur CONTENT/EVENTS (READ global)
- [x] ProductError sur violations (codes stables + traceId)
- [x] Tests unitaires verts (31 tests)
- [x] Module partagé aligné avec logique backend

## Note explicite

**Aucun rôle ajouté, seuls CONTENT/EVENTS impactés.** Le système utilise les champs existants `sectionScope` et `sectionIds` sans modification de schéma.

La messagerie (READ+WRITE section-only) nécessite une évolution du modèle de données car les messages n'ont pas de relation directe avec les sections - cette fonctionnalité est différée à une version future.
