# KOOMY — AUTH MIGRATION FIREBASE-ONLY: UI FOLLOWUPS

**Date**: 2026-01-24  
**Scope**: Admin/Backoffice UI/UX  
**Statut**: POST-MIGRATION FOLLOWUPS

---

## 1. BOUTON GOOGLE (Admin/Backoffice)

### Statut actuel: ❌ DÉSACTIVÉ (intentionnel) — VÉRIFIÉ

**Grep proof**:
```bash
$ rg -n "Google.*admin" client/src/components/unified/
client/src/components/unified/UnifiedAuthLogin.tsx:122:      toast.error("L'authentification Google n'est pas disponible pour les administrateurs");
client/src/components/unified/UnifiedAuthRegister.tsx:218:      toast.error("L'authentification Google n'est pas disponible pour les administrateurs");
```

**Code actuel** (`UnifiedAuthLogin.tsx:120-124`):
```typescript
if (isAdmin) {
  toast.error("L'authentification Google n'est pas disponible pour les administrateurs");
  return;
}
```

### Décision à prendre

| Option | Avantages | Inconvénients | Recommandation |
|--------|-----------|---------------|----------------|
| **OFF permanent** | Sécurité maximale, contrôle email | UX moins fluide | ✅ RECOMMANDÉ |
| **ON avec restrictions** | UX meilleure | Risque comptes Google non-vérifiés | ⚠️ À évaluer |

### Action requise

- [x] **Vérification**: Google bloqué pour admin dans UnifiedAuthLogin ET UnifiedAuthRegister
- [ ] **Décision produit**: Confirmer que Google reste OFF pour admin
- [ ] **UI optionnel**: Masquer visuellement le bouton Google pour admin (actuellement présent mais bloqué)

### Justification sécurité

Les administrateurs doivent avoir des comptes vérifiés et contrôlés. L'authentification email/password permet:
- Validation du domaine email
- Contrôle par l'organisation
- Audit trail clair

---

## 2. MOT DE PASSE OUBLIÉ (Admin)

### Statut actuel: ✅ IMPLÉMENTÉ

**Grep proof**:
```bash
$ rg -n "sendPasswordResetEmail" client/src/pages/admin/Login.tsx
11:import { signInWithEmailAndPassword, sendPasswordResetEmail } from "@/lib/firebase";
60:      const result = await sendPasswordResetEmail(email);
```

**Code existant** (`client/src/pages/admin/Login.tsx`):
```typescript
const handleForgotPassword = async () => {
  const result = await sendPasswordResetEmail(email);
  // Toast success/error handled
};

<button onClick={handleForgotPassword} data-testid="button-forgot-password">
  {isResettingPassword ? "Envoi..." : "Mot de passe oublié ?"}
</button>
```

### Écrans vérifiés

| Écran | Fichier | Statut |
|-------|---------|--------|
| Login admin | `client/src/pages/admin/Login.tsx:53-72` | ✅ IMPLÉMENTÉ |
| Login unifié | `client/src/components/unified/UnifiedAuthLogin.tsx:189-212` | ✅ IMPLÉMENTÉ |
| Mobile admin legacy | `client/src/pages/_legacy/MobileAdminLogin.tsx:174` | ⚠️ Lien présent mais non fonctionnel |

### Action requise

- [x] **Vérifier existence**: Bouton existe sur Login admin et Login unifié
- [x] **Implémentation**: `sendPasswordResetEmail` Firebase utilisé
- [ ] **Tester**: Vérifier réception email + flow reset en sandbox
- [ ] **Fix MobileAdminLogin**: Le lien "Mot de passe oublié" n'a pas de handler (basse priorité)

---

## 3. MESSAGES D'ERREUR VISIBLES

### Statut actuel: ⚠️ NON PROUVÉ — À VÉRIFIER EN SANDBOX

**Erreurs à couvrir**:

| Erreur Firebase | Message UX FR | Toast type |
|-----------------|---------------|------------|
| `auth/wrong-password` | "Mot de passe incorrect" | error |
| `auth/user-not-found` | "Aucun compte avec cet email" | error |
| `auth/invalid-email` | "Format email invalide" | error |
| `auth/too-many-requests` | "Trop de tentatives, réessayez plus tard" | warning |
| `auth/network-request-failed` | "Erreur réseau, vérifiez votre connexion" | error |

### Action requise

- [ ] **Audit**: Vérifier que chaque erreur Firebase affiche un toast clair
- [ ] **Test**: Simuler chaque erreur et vérifier le message
- [ ] **Fix**: Corriger les messages manquants ou incorrects

### Code exemple attendu

```typescript
try {
  await signInWithEmailAndPassword(auth, email, password);
} catch (error: any) {
  const code = error.code;
  switch (code) {
    case 'auth/wrong-password':
      toast.error("Mot de passe incorrect");
      break;
    case 'auth/user-not-found':
      toast.error("Aucun compte avec cet email");
      break;
    case 'auth/invalid-email':
      toast.error("Format email invalide");
      break;
    case 'auth/too-many-requests':
      toast.warning("Trop de tentatives, réessayez plus tard");
      break;
    default:
      toast.error("Erreur de connexion");
  }
}
```

---

## 4. ÉCRANS RELIQUES À SUPPRIMER

### Statut: ⚠️ NON PROUVÉ — À AUDITER

### À vérifier

| Élément | Fichier potentiel | Action |
|---------|-------------------|--------|
| Page "code" post-auth | `client/src/pages/*` | Supprimer si existe |
| Modal legacy login | `client/src/components/*` | Supprimer si existe |
| Redirect vers /api/admin/login | Tout fichier | Supprimer |

### Grep de vérification

```bash
# Vérifier qu'il n'y a pas de page "code" orpheline
rg -l "code.*verification|verify.*code" client/src/pages/

# Vérifier qu'il n'y a pas de modal legacy
rg -l "legacy.*login|login.*legacy" client/src/components/
```

### Action requise

- [ ] **Audit**: Lancer les grep ci-dessus
- [ ] **Identifier**: Lister les fichiers reliques
- [ ] **Supprimer**: Nettoyer les fichiers obsolètes
- [ ] **Tester**: Vérifier que le flow fonctionne sans ces fichiers

---

## 5. INDICATION DE CHARGEMENT

### Statut actuel: ⚠️ NON PROUVÉ — À VÉRIFIER

**Pendant le login**:
- [ ] Spinner visible pendant Firebase auth
- [ ] Bouton désactivé pendant loading
- [ ] Message "Connexion en cours..." ou équivalent

### Action requise

- [ ] **Vérifier**: L'état loading est-il bien géré?
- [ ] **Améliorer**: Ajouter spinner/disabled si manquant

---

## 6. SESSION PERSISTENCE (F5)

### Statut actuel: ✅ IMPLÉMENTÉ

**Comportement attendu**:
- Refresh (F5) → utilisateur reste connecté
- Token Firebase persisté via `firebase.auth().setPersistence(browserLocalPersistence)`

### Action requise

- [ ] **Tester**: Confirmer que F5 ne déconnecte pas
- [ ] **Log**: Vérifier que `ensureFirebaseToken()` fonctionne au boot

---

## 7. LOGOUT COMPLET

### Statut actuel: ✅ IMPLÉMENTÉ

**Actions logout requises**:
1. `signOut(auth)` — Firebase signout
2. `clearAllAuth()` — Nettoyage storage
3. Redirect vers login

### Action requise

- [ ] **Tester**: Logout puis vérifier qu'un accès direct à une route protégée redirige vers login
- [ ] **Vérifier**: Pas de "session fantôme" après logout

---

## 8. PRIORITÉS

| Priorité | Item | Effort | Impact |
|----------|------|--------|--------|
| 🔴 P1 | Mot de passe oublié | 2h | Critique (users locked out) |
| 🟡 P2 | Messages erreur | 1h | Important (UX) |
| 🟡 P2 | Supprimer écrans reliques | 2h | Maintenance |
| 🟢 P3 | Décision bouton Google | 0h | Produit |
| 🟢 P3 | Loading indicators | 1h | Nice-to-have |

---

## CHECKLIST VALIDATION UI

- [ ] Login email/password fonctionne
- [ ] Login affiche erreurs claires (mauvais password, user not found)
- [ ] Mot de passe oublié existe et fonctionne
- [ ] Refresh F5 ne déconnecte pas
- [ ] Logout nettoie complètement la session
- [ ] Pas de bouton Google actif (ou bloqué avec message)
- [ ] Pas d'écran relique accessible

---

**FIN DU RAPPORT UI_FOLLOWUPS**
