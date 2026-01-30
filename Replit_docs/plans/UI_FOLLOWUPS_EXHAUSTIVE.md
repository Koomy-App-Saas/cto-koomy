# KOOMY — AUTH FIREBASE ONLY: UI FOLLOWUPS EXHAUSTIVE

**Date**: 2026-01-24  
**Scope**: Admin/Backoffice UI  
**Objectif**: Liste complète des conséquences UI post-migration

---

## 1. GOOGLE CONNECT (Admin)

### Statut actuel: ❌ DÉSACTIVÉ

**Grep proof**:
```bash
$ rg -n "Google.*admin" client/src/components/unified/
UnifiedAuthLogin.tsx:122:toast.error("L'authentification Google n'est pas disponible pour les administrateurs");
UnifiedAuthRegister.tsx:218:toast.error("L'authentification Google n'est pas disponible pour les administrateurs");
```

### Écrans concernés

| Écran | Fichier | Symptôme | Fix attendu | Test |
|-------|---------|----------|-------------|------|
| Login admin | `UnifiedAuthLogin.tsx` | Bouton Google visible mais bloqué | Masquer ou désactiver visuellement | Click → toast erreur |
| Register admin | `UnifiedAuthRegister.tsx` | Bouton Google visible mais bloqué | Masquer ou désactiver visuellement | Click → toast erreur |

### États d'erreur

| Erreur | Message UX | Toast type |
|--------|------------|------------|
| Google clicked (admin) | "L'authentification Google n'est pas disponible pour les administrateurs" | error |

### Décision produit requise

- [ ] **Option A**: Masquer complètement le bouton Google pour admin
- [ ] **Option B**: Afficher bouton disabled avec tooltip explicatif
- [ ] **Option C**: Garder comportement actuel (bloqué avec toast)

---

## 2. ÉCRANS RELIQUES

### 2.1 Claim code flow

| Écran | Fichier | Statut | Action |
|-------|---------|--------|--------|
| ClaimVerified | `pages/mobile/ClaimVerified.tsx` | ✅ ACTIF | Conservé (membre mobile) |
| ClaimMembership | `pages/mobile/ClaimMembership.tsx` | ⚠️ À VÉRIFIER | Utilisé pour inscription membre |

### 2.2 Legacy login screens

| Écran | Fichier | Statut | Action |
|-------|---------|--------|--------|
| MobileAdminLogin | `pages/_legacy/MobileAdminLogin.tsx` | ⚠️ LEGACY | Migré vers Firebase mais dans dossier _legacy |
| MobileLogin | `pages/_legacy/MobileLogin.tsx` | ⚠️ LEGACY | À auditer |

### 2.3 Flows supprimés

| Flow | Statut | Preuve |
|------|--------|--------|
| /api/admin/login | ✅ DÉSACTIVÉ | Retourne 410 GONE |
| koomy_auth_token dispatch | ⚠️ CONSERVÉ (WL) | Utilisé par White-Label |

### Recommandations

1. Renommer `_legacy` en `deprecated` ou supprimer si non utilisé
2. Auditer tous les fichiers dans `pages/_legacy/`
3. Documenter les flows WL qui conservent le token legacy

---

## 3. MESSAGES D'ERREUR UX

### 3.1 Erreurs Firebase Auth

**Grep proof** (`client/src/lib/firebase.ts`):
```typescript
// Ligne 223-226
"auth/invalid-email": "Adresse email invalide",
"auth/user-not-found": "Aucun compte associé à cet email",
"auth/wrong-password": "Mot de passe incorrect",
```

| Code Firebase | Message UX FR | Écran | Implémenté |
|---------------|---------------|-------|------------|
| `auth/wrong-password` | "Mot de passe incorrect" | Login | ✅ PROUVÉ |
| `auth/user-not-found` | "Aucun compte associé à cet email" | Login | ✅ PROUVÉ |
| `auth/invalid-email` | "Adresse email invalide" | Login | ✅ PROUVÉ |
| `auth/too-many-requests` | "Trop de tentatives" | Login | ⚠️ À VÉRIFIER |
| `auth/network-request-failed` | "Erreur réseau" | Login | ⚠️ À VÉRIFIER |
| `auth/email-already-in-use` | "Cet email est déjà utilisé" | Register | ⚠️ À VÉRIFIER |
| `auth/weak-password` | "Mot de passe trop faible" | Register | ⚠️ À VÉRIFIER |

### 3.2 Erreurs API (401/403)

| Code API | Message UX FR | Écran | Action |
|----------|---------------|-------|--------|
| `FIREBASE_AUTH_REQUIRED` | "Session expirée, reconnectez-vous" | Toutes | Redirect login |
| `TOKEN_EXPIRED` | "Session expirée" | Toutes | Auto-refresh token |
| `FORBIDDEN` | "Accès non autorisé" | Admin actions | Afficher erreur |
| `COMMUNITY_MISMATCH` | "Vous n'avez pas accès à cette communauté" | Admin | Redirect dashboard |

### 3.3 Audit code erreurs

```bash
# Vérifier les handlers d'erreur Firebase
$ rg -n "auth/wrong-password|auth/user-not-found" client/src/
```

**À faire**: Exécuter grep et documenter les résultats

---

## 4. COMPATIBILITÉ F5/REFRESH

### Comportement attendu

| Action | Résultat attendu | Mécanisme |
|--------|------------------|-----------|
| F5 sur dashboard | Reste connecté | Firebase token persistence |
| F5 sur page formulaire | Données conservées | React Query cache |
| F5 après 1h+ | Reste connecté (token refresh) | ensureFirebaseToken() |

### Implémentation

```typescript
// client/src/contexts/AuthContext.tsx
// Au boot, vérifie Firebase auth state
onAuthStateChanged(auth, (user) => {
  if (user) {
    // Session persistée
  }
});
```

### Tests recommandés

| Test | Steps | Attendu |
|------|-------|---------|
| F5 simple | Login → Dashboard → F5 | Reste sur dashboard |
| F5 après 30min | Login → Attendre 30min → F5 | Reste connecté |
| F5 sur formulaire | Remplir form → F5 | Données perdues (normal) |
| Nouvel onglet | Login → Ouvrir nouvel onglet | Même session |

---

## 5. REDIRECTIONS POST-LOGIN

### Flow actuel

```
Login → Firebase auth → /api/auth/me → selectCommunity → Dashboard
```

### Points de redirection

| Point | Destination | Condition |
|-------|-------------|-----------|
| Après login | `/communities/:id/dashboard` | communityId disponible |
| Après login | `/communities/select` | Pas de communityId |
| Après login | Blocking screen | 0 communauté associée |
| Après logout | `/login` | Toujours |
| Token expiré | `/login` | Auto-redirect |

### Écrans concernés

| Écran | Fichier | Redirection |
|-------|---------|-------------|
| Login | `pages/admin/Login.tsx` | → Dashboard |
| UnifiedAuthLogin | `components/unified/UnifiedAuthLogin.tsx` | → Dashboard |
| AdminLayout | `components/AdminLayout.tsx` | Vérifie auth, redirect si besoin |

---

## 6. MOT DE PASSE OUBLIÉ

### Statut: ✅ IMPLÉMENTÉ

**Preuve**:
```typescript
// client/src/pages/admin/Login.tsx:53-72
const handleForgotPassword = async () => {
  const result = await sendPasswordResetEmail(email);
  // Toast success/error
};
```

### Écrans

| Écran | Fichier | Bouton | Fonctionnel |
|-------|---------|--------|-------------|
| Login admin | `Login.tsx` | "Mot de passe oublié ?" | ✅ |
| Login unifié | `UnifiedAuthLogin.tsx` | "Mot de passe oublié ?" | ✅ |
| Mobile admin legacy | `MobileAdminLogin.tsx` | Lien présent | ⚠️ Non fonctionnel |

---

## 7. LOADING STATES

### Écrans à vérifier

| Écran | État | Attendu | Statut |
|-------|------|---------|--------|
| Login | Pendant auth | Spinner + bouton disabled | ⚠️ À VÉRIFIER |
| Dashboard | Chargement données | Skeleton ou spinner | ⚠️ À VÉRIFIER |
| CRUD actions | Pendant mutation | Bouton loading | ⚠️ À VÉRIFIER |

---

## 8. RÉCAPITULATIF

| Item | Statut | Priorité | Action |
|------|--------|----------|--------|
| Google Connect disabled | ✅ IMPLÉMENTÉ | P3 | Décision produit: masquer? |
| Écrans reliques | ⚠️ À AUDITER | P2 | Audit dossier _legacy |
| Messages erreur Firebase | ⚠️ À VÉRIFIER | P1 | Tester chaque erreur |
| Messages erreur API | ⚠️ À VÉRIFIER | P1 | Tester 401/403 |
| F5/Refresh | ✅ IMPLÉMENTÉ | P1 | Tester persistence |
| Redirections post-login | ✅ IMPLÉMENTÉ | P1 | Tester flow complet |
| Mot de passe oublié | ✅ IMPLÉMENTÉ | P1 | Tester envoi email |
| Loading states | ⚠️ À VÉRIFIER | P3 | Audit UI states |

---

## 9. CHECKLIST DE VALIDATION

### Auth & Identity

- [ ] Login email/password fonctionne
- [ ] Login affiche erreurs claires
- [ ] Mot de passe oublié envoie email
- [ ] Google bloqué pour admin avec message clair
- [ ] F5 ne déconnecte pas
- [ ] Logout nettoie session

### Permissions/RBAC

- [ ] Admin peut accéder dashboard
- [ ] Admin peut CRUD sections/events/news
- [ ] Non-admin reçoit 403 sur actions admin
- [ ] Token legacy rejeté (401 FIREBASE_AUTH_REQUIRED)

### State & Routing

- [ ] communityId toujours défini pour appels API
- [ ] Pas de double slash dans URLs
- [ ] Redirect correct après login
- [ ] Redirect correct après logout

---

**FIN DU RAPPORT UI_FOLLOWUPS_EXHAUSTIVE**
