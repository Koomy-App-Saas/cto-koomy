# KOOMY — AUTH FIREBASE ONLY: COMMUNITYID AUDIT

**Date**: 2026-01-24  
**Scope**: Frontend communityId handling  
**Objectif**: Empêcher les URLs `/api/communities//...` (double slash)

---

## 1. INVENTAIRE DES USAGES

### Grep raw output

```bash
$ rg -n "\`/api/communities/\$\{communityId\}" client/src --glob "*.ts" --glob "*.tsx" | wc -l
```

**Résultat**: 50+ occurrences dans les fichiers admin

### Fichiers principaux concernés

| Fichier | Nb occurrences | Risque |
|---------|----------------|--------|
| `pages/admin/Members.tsx` | 10 | ⚠️ Élevé |
| `pages/admin/Settings.tsx` | 20+ | ⚠️ Élevé |
| `pages/admin/Dashboard.tsx` | 5 | ⚠️ Élevé |
| `pages/admin/Sections.tsx` | 6 | ⚠️ Élevé |
| `pages/admin/Events.tsx` | ~10 | ⚠️ Élevé |
| `pages/admin/Admins.tsx` | 5 | ⚠️ Élevé |
| `pages/admin/Payments.tsx` | 6 | ⚠️ Élevé |
| `components/MobileAdminLayout.tsx` | 15 | ⚠️ Élevé |
| `lib/api.ts` | 5 | ⚠️ Élevé |

---

## 2. PROBLÈME IDENTIFIÉ

### Symptôme

Si `communityId` est `undefined` ou `""`, les URLs deviennent:
```
/api/communities//sections  ← DOUBLE SLASH
/api/communities/undefined/sections  ← STRING "undefined"
```

### Conséquence

- Erreur 404 ou comportement inattendu
- Données corrompues ou non chargées
- UX confuse pour l'utilisateur

---

## 3. SOURCES DE communityId

### Contexte AuthContext

```typescript
// client/src/contexts/AuthContext.tsx
const { communityId } = useAuth();
```

Le `communityId` vient de:
1. `selectCommunity(id)` — appelé après login
2. Persisté dans localStorage
3. Restauré au boot

### Risques

| Situation | communityId | Risque |
|-----------|-------------|--------|
| Juste après login, avant selectCommunity | `undefined` | ⚠️ |
| Après logout | `undefined` | ⚠️ |
| localStorage corrompu | `""` ou `"undefined"` | ⚠️ |
| Nouveau compte sans communauté | `undefined` | ⚠️ |

---

## 4. RECOMMANDATIONS

### 4.1 Guard au niveau API helpers

```typescript
// client/src/api/httpClient.ts
export function validateCommunityId(communityId: string | undefined): string {
  if (!communityId || communityId === 'undefined' || communityId === '') {
    throw new Error('COMMUNITY_ID_REQUIRED: communityId is empty or undefined');
  }
  return communityId;
}
```

### 4.2 Guard au niveau hooks

```typescript
// Avant chaque useQuery avec communityId
const { communityId } = useAuth();

// Guard
if (!communityId) {
  return { data: null, isLoading: false, error: 'No community selected' };
}

// Puis utiliser
queryKey: [`/api/communities/${communityId}/sections`]
```

### 4.3 Guard au niveau UI

```typescript
// Dans les pages admin
if (!communityId) {
  return (
    <div className="error-screen">
      <h1>Aucune communauté sélectionnée</h1>
      <p>Veuillez sélectionner une communauté pour continuer.</p>
    </div>
  );
}
```

### 4.4 Assertion dev-only

```typescript
// Pour debugging
if (process.env.NODE_ENV === 'development') {
  console.assert(communityId, 'communityId is required but was:', communityId);
}
```

---

## 5. AUDIT PAR FICHIER

### pages/admin/Members.tsx

```typescript
// Ligne 64
queryKey: [`/api/communities/${communityId}/members`]
```

**Recommandation**: Ajouter guard au début du composant

### pages/admin/Settings.tsx

```typescript
// Lignes 69, 143, 152, etc.
queryKey: [`/api/communities/${communityId}`]
```

**Recommandation**: Ajouter guard + early return si !communityId

### components/MobileAdminLayout.tsx

```typescript
// Ligne 113
queryKey: [`/api/communities/${communityId}`]
```

**Recommandation**: Ce composant wrapper devrait valider communityId en premier

---

## 6. PLAN D'ACTION

| Priorité | Action | Fichier(s) | Effort |
|----------|--------|------------|--------|
| P1 | Ajouter `validateCommunityId` helper | `httpClient.ts` | 30min |
| P1 | Guard dans AdminLayout wrapper | `AdminLayout.tsx` | 1h |
| P2 | Ajouter guards dans chaque page admin | `pages/admin/*` | 2h |
| P3 | Ajouter assertions dev-only | Tous fichiers | 1h |

---

## 7. TESTS RECOMMANDÉS

### Test manuel

1. Se connecter comme admin
2. Ouvrir DevTools > Console
3. Exécuter: `localStorage.removeItem('koomy_community_id')`
4. Refresh page
5. **Attendu**: Message clair "Aucune communauté sélectionnée"
6. **Pas**: Double slash dans les requêtes réseau

### Test automatisé (suggestion)

```typescript
describe('communityId validation', () => {
  it('should not make API calls with empty communityId', () => {
    // Mock communityId = undefined
    // Render admin page
    // Assert: no network calls to /api/communities//
  });
});
```

---

## 8. STATUT ACTUEL

| Check | Statut | Détail |
|-------|--------|--------|
| Guard global httpClient | ⚠️ NON IMPLÉMENTÉ | À ajouter |
| Guard AdminLayout | ⚠️ À VÉRIFIER | Peut exister |
| Guards pages individuelles | ⚠️ INCOHÉRENT | Certaines pages ont, d'autres non |
| Assertions dev | ⚠️ NON IMPLÉMENTÉ | À ajouter |
| UI message clair | ⚠️ À VÉRIFIER | Peut exister |

---

**FIN DU RAPPORT COMMUNITYID_AUDIT**
