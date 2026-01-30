# Rapport de Simplification des Rôles Backoffice V1

**Date:** 20 Janvier 2026  
**Version:** 1.0  
**Statut:** Implémenté

---

## 1. Objectif

Simplifier le modèle de rôles du backoffice pour V1, en exposant uniquement **2 rôles** :

| Rôle Affiché | Clé Interne | Description |
|--------------|-------------|-------------|
| **Propriétaire** | OWNER | Créateur du club, accès complet, non modifiable |
| **Administrateur** | ADMIN | Accès backoffice avec privilèges |

Les autres utilisateurs sont considérés comme **MEMBER** sans accès backoffice.

---

## 2. Mapping Legacy → V1

Les rôles legacy sont préservés en base de données pour rétrocompatibilité mais masqués dans l'UI.

| Rôle Legacy | Mapping V1 | Accès Backoffice |
|-------------|------------|------------------|
| `super_admin` | OWNER | ✅ Oui |
| `owner` | OWNER | ✅ Oui |
| `admin` | ADMIN | ✅ Oui |
| `delegate` | MEMBER | ❌ Non |
| `manager` | MEMBER | ❌ Non |
| `finance_admin` | MEMBER | ❌ Non |
| `content_admin` | MEMBER | ❌ Non |
| `member` | MEMBER | ❌ Non |

**Flag `isOwner`** : Si `isOwner === true`, le membre est toujours considéré comme OWNER indépendamment de son rôle DB.

---

## 3. Helpers Backend Centralisés

**Fichier:** `server/routes.ts` (lignes 98-141)

### isOwner(membership)
```typescript
function isOwner(membership: MembershipForRoleCheck): boolean {
  if (!membership) return false;
  if (membership.isOwner === true) return true;
  if (membership.role === "super_admin" || membership.role === "owner") return true;
  if (membership.adminRole === "super_admin" || membership.adminRole === "owner") return true;
  return false;
}
```

### isBackofficeAdmin(membership)
```typescript
function isBackofficeAdmin(membership: MembershipForRoleCheck): boolean {
  if (!membership) return false;
  if (isOwner(membership)) return true;
  if (membership.role === "admin") return true;
  if (membership.adminRole === "admin") return true;
  return false;
}
```

### isCommunityAdmin(membership) - Alias
```typescript
function isCommunityAdmin(membership: MembershipForRoleCheck): boolean {
  return isBackofficeAdmin(membership);
}
```

---

## 4. Écrans UI Modifiés

### client/src/pages/admin/Admins.tsx

| Modification | Avant | Après |
|--------------|-------|-------|
| Filtre admins | `role === "admin" \|\| role === "super_admin"` | `isOwner === true \|\| role ∈ ["admin", "super_admin", "owner"]` |
| Affichage rôle | "Super Admin" / "Admin Local" | "Propriétaire" / "Administrateur" |
| Badge OWNER | Badge violet "Super Admin" | Badge violet avec 🔒 "Propriétaire" |
| Badge ADMIN | Badge bleu "Admin Local" | Badge bleu "Administrateur" |
| Action OWNER | Bouton Supprimer visible | "Non modifiable" (grisé) |
| Création rôle | Select "Super Admin" / "Admin" | Rôle fixe "Administrateur" |
| Périmètre OWNER | "Global (National)" | "Accès complet" |
| Périmètre ADMIN | Section ou "Non défini" | Section ou "Toutes sections" |

### Changements clés :
1. **Sélecteur de rôle supprimé** : Lors de la création d'un administrateur, le rôle est toujours "admin"
2. **OWNER protégé** : Le propriétaire ne peut pas être modifié/supprimé via l'UI
3. **Affichage simplifié** : Seuls 2 badges sont affichés (Propriétaire/Administrateur)

---

## 5. Guards Endpoints (via isCommunityAdmin)

Le helper `isCommunityAdmin()` est un alias de `isBackofficeAdmin()` et est utilisé pour protéger les endpoints suivants :

| Endpoint | Guard | Comportement |
|----------|-------|--------------|
| POST /api/memberships | isCommunityAdmin | 403 si MEMBER |
| DELETE /api/memberships/:id | isCommunityAdmin | 403 si MEMBER |
| POST /api/memberships/:id/regenerate-code | isCommunityAdmin | 403 si MEMBER |
| POST /api/communities/:id/delegates | isCommunityAdmin | 403 si MEMBER |
| POST /api/communities/:id/fees | isCommunityAdmin | 403 si MEMBER |
| DELETE /api/communities/:id/fees/:id | isCommunityAdmin | 403 si MEMBER |
| POST /api/payments | isCommunityAdmin | 403 si MEMBER |
| POST /api/payments/:id/process | isCommunityAdmin | 403 si MEMBER |
| POST /api/events | isCommunityAdmin OU canManageEvents | 403 si non autorisé |
| PATCH /api/events/:id | isCommunityAdmin OU canManageEvents | 403 si non autorisé |
| POST /api/messages | isCommunityAdmin OU canManageContent | 403 si non autorisé |

---

## 6. Checklist Tests

### Tests OWNER
- [ ] OWNER affiché comme "Propriétaire" avec icône 🔒
- [ ] OWNER ne peut pas être supprimé (bouton masqué)
- [ ] OWNER peut accéder à tous les endpoints protégés
- [ ] OWNER avec `isOwner=true` reconnu même si `role="member"`
- [ ] OWNER avec `role="super_admin"` reconnu comme OWNER

### Tests ADMIN
- [ ] ADMIN affiché comme "Administrateur"
- [ ] ADMIN peut être supprimé (retrait des droits)
- [ ] ADMIN peut accéder aux endpoints protégés
- [ ] Création ADMIN assigne `role="admin"`
- [ ] ADMIN section affichée correctement

### Tests MEMBER
- [ ] MEMBER n'apparaît pas dans la liste des administrateurs
- [ ] MEMBER reçoit 403 sur endpoints protégés
- [ ] Legacy `delegate` traité comme MEMBER (pas d'accès backoffice)
- [ ] Legacy `manager` traité comme MEMBER

### Tests UI
- [ ] Pas de sélecteur de rôle "Super Admin" visible
- [ ] Pas de rôles legacy visibles (delegate, manager, etc.)
- [ ] Création admin = rôle "admin" uniquement
- [ ] Affectation section optionnelle visible

---

## 7. Contraintes Respectées

✅ **Pas de suppression DB** : Les rôles legacy restent en base  
✅ **Rétrocompatibilité** : Les anciennes données fonctionnent  
✅ **Centralisation** : Helpers `isOwner()` et `isBackofficeAdmin()` uniques  
✅ **Pas de migration** : Aucune modification de schéma requise  
✅ **UI masquée** : Les rôles legacy sont invisibles pour les utilisateurs

---

## 8. Fichiers Modifiés

| Fichier | Type | Description |
|---------|------|-------------|
| `server/routes.ts` | Backend | Helpers isOwner(), isBackofficeAdmin(), isCommunityAdmin() |
| `client/src/pages/admin/Admins.tsx` | Frontend | Simplification affichage rôles |

---

## 9. Limitations Connues (V1)

### Permissions Fines (canManage*)
Les helpers `canManageArticles`, `canManageEvents`, `canManageMessages`, etc. utilisent encore la logique delegate :
```typescript
if (membership.role === 'delegate' && membership.canManageArticles === true) return true;
```

**Impact V1** : Un membre avec `role="delegate"` et `canManageArticles=true` peut encore gérer les articles. Cela est conservé intentionnellement pour ne pas casser les fonctionnalités existantes.

**Recommandation Post-V1** : Refactoriser `canManageArticles` et similaires pour exiger `isBackofficeAdmin()` comme prérequis.

### Écrans Non Mis à Jour
Les écrans suivants peuvent encore afficher des références aux rôles legacy :
- `client/src/pages/mobile/admin/*` - Écrans mobile admin
- `client/src/components/MobileAdminLayout.tsx` - Layout mobile

**Impact V1** : Cosmétique uniquement, la sécurité est assurée par les guards backend.

---

## 10. Prochaines Étapes (Post-V1)

1. **Migration progressive** : Convertir les `super_admin` en `isOwner=true` + `role="admin"`
2. **Nettoyage DB** : Supprimer les rôles legacy non utilisés
3. **Refactor permissions** : Aligner `canManage*` sur `isBackofficeAdmin()`
4. **Audit UI mobile** : Mettre à jour les écrans mobile admin
5. **Tests E2E** : Valider OWNER/ADMIN/MEMBER avec la checklist

---

*Rapport généré automatiquement - Koomy Platform*
