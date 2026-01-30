# FIX: Message d'erreur visible pour mot de passe incorrect

**Date**: 2026-01-24  
**Statut**: Corrigé

## Problème

Sur l'écran de connexion email/mot de passe, quand l'utilisateur saisit un mot de passe incorrect :
- Aucun message d'erreur visible dans l'UI
- L'erreur n'était visible que dans la console

## Cause racine

Le toast.error était appelé mais :
1. Pas d'état local pour afficher l'erreur de manière persistante dans l'UI
2. Le toast peut être manqué si l'utilisateur ne regarde pas au bon moment

## Corrections appliquées

### 1. Nouvel état `loginError` (UnifiedAuthLogin.tsx)

```typescript
const [loginError, setLoginError] = useState<string | null>(null);
```

### 2. Capture et affichage des erreurs

Dans `handleEmailLogin()` :
- Clear l'erreur précédente au début
- Set l'erreur quand Firebase retourne une erreur
- Affiche à la fois toast ET message UI

```typescript
if ("error" in result) {
  console.log("[LOGIN_ERROR] Firebase error:", result.error);
  setLoginError(result.error);
  toast.error(result.error);
  setIsLoading(false);
  return;
}
```

### 3. Message d'erreur visible sous le champ mot de passe

```jsx
{loginError && (
  <div 
    className="mt-2 p-3 rounded-lg bg-red-50 border border-red-200 text-red-700 text-sm"
    data-testid="login-error-message"
  >
    <p className="font-medium">{loginError}</p>
  </div>
)}
```

## Mapping des erreurs Firebase (déjà existant dans firebase.ts)

| Code Firebase | Message utilisateur (FR) |
|---------------|-------------------------|
| `auth/wrong-password` | Mot de passe incorrect |
| `auth/invalid-credential` | Email ou mot de passe incorrect |
| `auth/user-not-found` | Aucun compte associé à cet email |
| `auth/invalid-email` | Adresse email invalide |
| `auth/too-many-requests` | Trop de tentatives, veuillez réessayer plus tard |
| Autre | Erreur de connexion |

## Fichiers modifiés

| Fichier | Modifications |
|---------|--------------|
| `client/src/components/unified/UnifiedAuthLogin.tsx` | Ajout état loginError, affichage message UI |

## Comportement après fix

1. Saisie mot de passe incorrect → message rouge visible immédiatement sous le champ
2. Le bouton "Se connecter" redevient cliquable
3. Pas de refresh / pas de redirection
4. Le message reste visible jusqu'à la prochaine tentative

## Logs attendus

```
[LOGIN_ERROR] Firebase error: Mot de passe incorrect
```

## Critères d'acceptation

| Test | Attendu |
|------|---------|
| Mot de passe faux | Message rouge visible < 1s |
| Pas de refresh | ✓ Page reste stable |
| Bouton réactivé | ✓ Cliquable après erreur |
| Focus sur champ | ✓ Message sous mot de passe |
