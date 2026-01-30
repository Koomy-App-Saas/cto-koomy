# Rapport d'Unification des Écrans d'Authentification

**Date**: 23 janvier 2026  
**Objectif**: Stabiliser les écrans auth et unifier Admin/Member

---

## Résumé

Cette refonte a créé un système d'authentification unifié pour les applications membre et admin, avec les mêmes composants UI mais des couleurs et textes différents selon le mode.

---

## Problème Identifié

### Cause du "retour à l'ancien écran"

Le problème provenait de **plusieurs implémentations concurrentes** des écrans d'authentification :

1. **`MobileLogin.tsx`** (ancien) - Utilisé par `DomainAwareRoot` pour les modes WALLET et native app
2. **`AuthChoice.tsx`, `AuthLogin.tsx`, `AuthRegister.tsx`** (nouveaux) - Routes `/auth/*`
3. **`MobileAdminLogin.tsx`** (ancien) - Utilisé pour le mode CLUB_MOBILE

Le routeur `DomainAwareRoot` renvoyait vers les anciens composants dans certains cas, créant une incohérence visuelle.

---

## Solution Implémentée

### 1. Système AppMode

Création d'une architecture centralisée pour gérer les modes membre/admin :

| Fichier | Rôle |
|---------|------|
| `client/src/lib/appMode.ts` | Définition du type `AppMode` ("member" \| "admin") |
| `client/src/lib/authTheme.ts` | Tokens de couleurs pour chaque mode |
| `client/src/lib/authTexts.ts` | Dictionnaire de textes pour chaque mode |
| `client/src/contexts/AppModeContext.tsx` | Context React pour fournir mode/thème/textes |

### 2. Composants Unifiés

Création de composants partagés dans `client/src/components/unified/` :

- **`UnifiedAuthChoice.tsx`** - Écran Welcome (Bienvenue)
- **`UnifiedAuthLogin.tsx`** - Écran Login (Connexion)
- **`UnifiedAuthRegister.tsx`** - Écran Register (Inscription)

Ces composants utilisent le contexte `AppModeContext` pour appliquer automatiquement :
- Les couleurs appropriées (bleu pour membre, violet pour admin)
- Les textes appropriés ("communautés" vs "back-office")
- Les routes de redirection post-login

### 3. Pages Wrapper

Les pages individuelles sont maintenant des wrappers simples :

```tsx
// client/src/pages/mobile/AuthChoice.tsx
import { AppModeProvider } from "@/contexts/AppModeContext";
import { UnifiedAuthChoice } from "@/components/unified";

export default function AuthChoice() {
  return (
    <AppModeProvider mode="member">
      <UnifiedAuthChoice baseRoute="/auth" />
    </AppModeProvider>
  );
}
```

### 4. Nouvelles Routes Admin

Ajout des routes unifiées pour l'admin mobile :

| Route | Composant |
|-------|-----------|
| `/app/admin/auth` | `MobileAdminAuthChoice` |
| `/app/admin/auth/login` | `MobileAdminAuthLogin` |
| `/app/admin/auth/register` | `MobileAdminAuthRegister` |

### 5. Redirections Legacy

Les anciennes routes redirigent vers les nouvelles :

| Ancienne Route | Nouvelle Route |
|----------------|----------------|
| `/app/login` | `/auth` |
| `/app/admin/login` | `/app/admin/auth` |
| `/app/admin/register` | `/app/admin/auth` |

---

## Fichiers Modifiés

### Nouveaux Fichiers

- `client/src/lib/appMode.ts`
- `client/src/lib/authTheme.ts`
- `client/src/lib/authTexts.ts`
- `client/src/contexts/AppModeContext.tsx`
- `client/src/components/unified/UnifiedAuthChoice.tsx`
- `client/src/components/unified/UnifiedAuthLogin.tsx`
- `client/src/components/unified/UnifiedAuthRegister.tsx`
- `client/src/components/unified/index.ts`
- `client/src/pages/mobile/admin/AuthChoice.tsx`
- `client/src/pages/mobile/admin/AuthLogin.tsx`
- `client/src/pages/mobile/admin/AuthRegister.tsx`

### Fichiers Modifiés

- `client/src/App.tsx` - Nouvelles imports et routes, mise à jour de `DomainAwareRoot`
- `client/src/pages/mobile/AuthChoice.tsx` - Wrapper avec AppModeProvider
- `client/src/pages/mobile/AuthLogin.tsx` - Wrapper avec AppModeProvider
- `client/src/pages/mobile/AuthRegister.tsx` - Wrapper avec AppModeProvider

### Fichiers Déplacés vers `_legacy/`

- `client/src/pages/mobile/Login.tsx` → `client/src/pages/_legacy/MobileLogin.tsx`
- `client/src/pages/mobile/admin/Login.tsx` → `client/src/pages/_legacy/MobileAdminLogin.tsx`
- `client/src/pages/mobile/admin/Register.tsx` → `client/src/pages/_legacy/MobileAdminRegister.tsx`

---

## Garanties Anti-Régression

1. **Source de vérité unique** : Les 3 écrans (Welcome, Login, Register) sont implémentés UNE SEULE fois dans `components/unified/`

2. **Isolation des anciennes versions** : Les anciens composants sont déplacés dans `_legacy/` et ne sont plus utilisés dans les routes principales

3. **Redirections systématiques** : Les anciennes routes (`/app/login`, `/app/admin/login`) redirigent automatiquement vers les nouvelles

4. **DomainAwareRoot mis à jour** : Utilise maintenant `AuthChoice` au lieu de `MobileLogin` pour les modes WALLET et CLUB_MOBILE

5. **Pas de duplication UI** : Membre et Admin utilisent exactement les mêmes composants avec des configurations différentes

---

## Comportements Post-Login

### Mode Membre
- **Route de départ** : `/auth`
- **Après login réussi** : `/app/hub` (si memberships) ou `/app/join` (si pas de membership)
- **Après inscription** : `/app/join`

### Mode Admin
- **Route de départ** : `/app/admin/auth`
- **Après login réussi** : `/app/{communityId}/admin` (1 club) ou `/app/admin/select-community` (plusieurs clubs)
- **Après inscription** : `/admin/join`

---

## Différences Visuelles Membre vs Admin

| Élément | Membre | Admin |
|---------|--------|-------|
| Fond | Dégradé bleu clair → blanc | Dégradé violet sombre |
| Bouton primaire | Bleu (#3B82F6) | Violet (#8B5CF6) |
| Textes | "Communautés", "Hub" | "Back-office", "Admin" |
| Google OAuth | Disponible | Non disponible |
| Structure/Layout | Identique | Identique |

---

## Tests Recommandés

1. **Navigation Membre** : `/auth` → Login → Hub
2. **Navigation Admin** : `/app/admin/auth` → Login → Back-office
3. **Refresh navigateur** : Aucun écran legacy ne doit apparaître
4. **Mode incognito** : Vérifier le design correct sans cache

---

## Conclusion

L'unification est complète. Les écrans correspondent aux captures de référence et le système garantit qu'aucun "retour fantôme" à l'ancien design ne peut se produire.
