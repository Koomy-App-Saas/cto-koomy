# KOOMY — Tags pour tous les plans + Auth Codes + A11y

**Date**: 2026-01-25  
**Status**: Implémenté

## Résumé

Ce rapport documente les changements effectués pour :
1. Rendre la feature TAGS disponible pour tous les plans (suppression du gating Pro/Enterprise)
2. Corriger la confusion token expiré vs erreurs 403
3. Standardiser les codes d'erreurs
4. Corriger le warning a11y DialogContent (DialogDescription)

---

## Changements Backend

### A) Suppression du gating par plan sur les routes tags

**Fichier**: `server/routes.ts`

**Ce qui a été retiré** (route `POST /api/communities/:communityId/tags`):

```typescript
// SUPPRIMÉ:
const community = await storage.getCommunity(communityId);
if (!community) {
  return res.status(404).json({ error: "Community not found" });
}

const plan = await storage.getPlan(community.planId);
if (!plan || (plan.code !== "PRO" && plan.code !== "ENTERPRISE")) {
  return res.status(403).json({ error: "Les tags sont disponibles pour les plans Pro et Entreprise" });
}
```

**Routes impactées**:
- `POST /api/communities/:communityId/tags` - création de tag
- `PUT /api/tags/:id` - mise à jour de tag
- `POST /api/tags/:id/deactivate` - désactivation de tag
- `DELETE /api/tags/:id` - suppression de tag
- `PUT /api/memberships/:membershipId/tags` - assignation de tags à un membre
- `POST /api/memberships/:membershipId/tags/:tagId` - ajout d'un tag à un membre
- `DELETE /api/memberships/:membershipId/tags/:tagId` - retrait d'un tag d'un membre

### B) Auth: standardisation des codes d'erreur

**Fichier**: `server/middlewares/requireFirebaseAuth.ts`

**Avant**:
```typescript
if (!token) {
  res.status(401).json({ error: "missing_token" });
}
// ...
res.status(401).json({ error: "invalid_token" });
```

**Après**:
```typescript
if (!token) {
  res.status(401).json({ error: "Non authentifié", code: "UNAUTHENTICATED" });
}
// ...
if (isExpired) {
  res.status(401).json({ error: "Session expirée", code: "AUTH_TOKEN_EXPIRED" });
} else {
  res.status(401).json({ error: "Token invalide", code: "AUTH_TOKEN_INVALID" });
}
```

### C) Permissions (capabilities/roles)

Toutes les routes tags utilisent maintenant le code standardisé:
```typescript
return res.status(403).json({ error: "Permission insuffisante", code: "CAPABILITY_DENIED" });
```

### D) Codes d'erreur harmonisés

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `UNAUTHENTICATED` | 401 | Token absent |
| `AUTH_TOKEN_EXPIRED` | 401 | Token expiré |
| `AUTH_TOKEN_INVALID` | 401 | Token invalide (signature, format) |
| `CAPABILITY_DENIED` | 403 | Droits insuffisants (pas admin) |

---

## Changements Frontend

### A) Gestion UI selon code d'erreur

**Fichiers**: 
- `client/src/pages/admin/Tags.tsx`
- `client/src/pages/mobile/admin/Tags.tsx`

```typescript
onError: (error: any) => {
  const code = error?.code;
  if (code === "AUTH_TOKEN_EXPIRED" || code === "UNAUTHENTICATED") {
    toast.error("Session expirée, veuillez vous reconnecter");
  } else if (code === "CAPABILITY_DENIED") {
    toast.error("Vous n'avez pas les droits nécessaires");
  } else {
    toast.error(error.message || "Une erreur est survenue");
  }
}
```

### B) Propagation du code d'erreur

Les mutations propagent maintenant le code d'erreur de l'API:
```typescript
if (!res.ok) {
  const error = new Error(res.data?.error || "Failed to create tag") as Error & { code?: string };
  error.code = res.data?.code;
  throw error;
}
```

### C) A11Y DialogContent

**Fichier**: `client/src/pages/admin/Tags.tsx`

Ajout de `DialogDescription` à toutes les modales:

```tsx
<DialogContent>
  <DialogHeader>
    <DialogTitle>Créer un tag</DialogTitle>
    <DialogDescription>
      Créez un nouveau tag pour segmenter vos membres ou catégoriser vos contenus.
    </DialogDescription>
  </DialogHeader>
  ...
</DialogContent>
```

### D) Suppression du gating UI

**Fichier**: `client/src/pages/mobile/admin/Tags.tsx`

Supprimé:
- Variable `isPlanUpgradeRequired`
- Bloc conditionnel affichant "Fonctionnalité Pro"
- Import `Lock` de lucide-react
- Query `plan` (plus nécessaire)

---

## Résultats des Tests

| Test | Attendu | Résultat |
|------|---------|----------|
| Plan free + admin: création tag | 200 OK | ✅ |
| Plan free + membre non admin: création tag | 403 CAPABILITY_DENIED | ✅ |
| Token expiré: création tag | 401 AUTH_TOKEN_EXPIRED | ✅ |
| Warning DialogContent dans console | Aucun | ✅ |

---

## Fichiers Modifiés

| Fichier | Type de changement |
|---------|-------------------|
| `server/routes.ts` | Suppression gating plan, codes erreur standardisés |
| `server/middlewares/requireFirebaseAuth.ts` | Codes erreur AUTH_TOKEN_EXPIRED, UNAUTHENTICATED |
| `client/src/pages/admin/Tags.tsx` | DialogDescription, gestion codes erreur |
| `client/src/pages/mobile/admin/Tags.tsx` | Suppression UI gating, gestion codes erreur |
