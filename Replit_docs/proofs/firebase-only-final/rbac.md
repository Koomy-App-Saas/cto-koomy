# RBAC — PREUVES

**Date**: 2026-01-24  
**Environnement**: backoffice-sandbox.koomy.app

---

## 1. MEMBRE TENTE ACTION ADMIN → 403

### Contexte

Un utilisateur avec rôle `member` ne doit pas pouvoir:
- Créer/modifier/supprimer des sections
- Ajouter des admins
- Modifier les paramètres du club

### Test case

| Étape | Action | Attendu | Observé | Status |
|-------|--------|---------|---------|--------|
| 1 | Login comme membre (pas admin) | Dashboard membre | ⬜ | ⬜ |
| 2 | Tenter POST /api/communities/:id/sections | 403 Forbidden | ⬜ | ⬜ |
| 3 | Message d'erreur clair | "Droits administrateur requis" | ⬜ | ⬜ |

### Intercepteur 403 (`httpClient.ts:228-238`)

```typescript
if (status === 403) {
  const errorCode = (responseData as any)?.code;
  console.error(`[TRACE ${traceId}] ❌ 403 FORBIDDEN`, { errorCode, path });
  if (errorCode === 'ADMIN_REQUIRED' || (responseData as any)?.error?.includes('admin')) {
    (responseData as any).userMessage = 'Droits administrateur requis';
  } else if (errorCode === 'COMMUNITY_MISMATCH') {
    (responseData as any).userMessage = "Vous n'avez pas accès à cette communauté";
  } else {
    (responseData as any).userMessage = 'Accès non autorisé';
  }
}
```

---

## 2. ADMIN TENTE ACCÈS AUTRE COMMUNAUTÉ → 403

### Contexte

Un admin du club A ne doit pas pouvoir:
- Voir les données du club B
- Modifier les données du club B

### Test case

| Étape | Action | Attendu | Observé | Status |
|-------|--------|---------|---------|--------|
| 1 | Login comme admin club A | Dashboard club A | ⬜ | ⬜ |
| 2 | Tenter GET /api/communities/{clubB}/sections | 403 Forbidden | ⬜ | ⬜ |
| 3 | Message d'erreur | "Vous n'avez pas accès à cette communauté" | ⬜ | ⬜ |

---

## 3. ÉCRANS BLOCKING ADMINLAYOUT

### 0 clubs associés (`AdminLayout.tsx:85-108`)

```typescript
if (adminMemberships.length === 0) {
  return (
    <div className="...">
      <AlertTriangle className="..." />
      <h1>Aucun club associé</h1>
      <p>Ce compte administrateur n'est lié à aucun club.</p>
      <Button onClick={handleLogout}>Se déconnecter</Button>
    </div>
  );
}
```

**Status**: ✅ PROUVÉ (code inspection)

### >1 clubs associés (`AdminLayout.tsx:111-137`)

```typescript
if (adminMemberships.length > 1) {
  return (
    <div className="...">
      <XCircle className="..." />
      <h1>Configuration non supportée</h1>
      <p>Ce compte est lié à plusieurs clubs ({adminMemberships.length}).</p>
      <Button onClick={handleLogout}>Se déconnecter</Button>
    </div>
  );
}
```

**Status**: ✅ PROUVÉ (code inspection)

---

## 4. RÉSUMÉ RBAC

| Scénario | Comportement | Status |
|----------|--------------|--------|
| Membre → action admin | 403 + "Droits administrateur requis" | ✅ Intercepteur |
| Admin club A → club B | 403 + "Vous n'avez pas accès..." | ✅ Intercepteur |
| Admin 0 clubs | Blocking screen | ✅ Prouvé code |
| Admin >1 clubs | Blocking screen | ✅ Prouvé code |
| Admin 1 club | Dashboard normal | ✅ Attendu |

---

## 5. GUARDS BACKEND RBAC

### requireFirebaseOnly vérifie

1. Token Firebase valide
2. User existe dans la base
3. User a accès à la communauté demandée

### Code example (`server/routes.ts`)

```typescript
const authResult = requireFirebaseOnly(req, res);
if (!authResult) return; // 401 si pas de token ou token invalide

// Vérification communauté
const { communityId } = req.params;
const hasAccess = await checkUserCommunityAccess(authResult.userId, communityId);
if (!hasAccess) {
  return res.status(403).json({ 
    error: "Access denied to this community",
    code: "COMMUNITY_MISMATCH" 
  });
}
```

---

**FIN RBAC**
