# Rapport: Refonte Auth Admin - Email Only (No Firebase)

**Date:** 2026-01-23  
**Auteur:** Agent  
**Version:** 1.0

---

## Résumé Exécutif

Cette mise à jour implémente le contrat d'identité 2026-01 pour les administrateurs:
- **ADMINS = LEGACY ONLY** (email/password uniquement)
- **Google/Firebase INTERDIT** pour tous les admins
- Firebase reste **REQUIS** pour les membres de communautés STANDARD

---

## Changements Backend

### 1. Endpoint `/api/admin/login` (routes.ts ~2500-2510)

**AVANT:**
```typescript
// Bloquait les admins STANDARD avec FIREBASE_REQUIRED
if (adminWlCheck.found && !adminWlCheck.isWL) {
  return res.status(403).json({
    error: "Cette communauté utilise l'authentification Google...",
    code: "FIREBASE_REQUIRED"
  });
}
```

**APRÈS:**
```typescript
// CONTRACT 2026-01 UPDATED: Admins = Legacy only (no Firebase check)
console.log(`[Admin Login ${traceId}] CONTRACT_2026_01: admin_legacy_auth_allowed`);
```

### 2. Nouvel Endpoint `/api/admin/join-with-credentials` (routes.ts ~2900-3050)

Endpoint pour le flux "invitation code-first" qui combine:
- Validation du code d'invitation (8 chars, XXXX-XXXX)
- Authentification email/password (ou création user si nouveau)
- Création du membership admin dans la communauté

**Fonctionnalités:**
- Vérifie `whiteLabel: false` (STANDARD uniquement)
- Hash bcrypt pour création nouveaux users
- Vérification membership existant
- Retourne user + memberships + session

---

## Changements Frontend

### AdminLogin.tsx - Design 3 Blocs

Structure desktop refactorisée avec 3 blocs distincts:

| Bloc | Contenu | Action |
|------|---------|--------|
| 1. Créer communauté | Lien externe site public | Découvrir/Créer |
| 2. Code invitation | Formulaire XXXX-XXXX | Entrer mon code |
| 3. Connexion admin | Email/password | Se connecter |

**Google/Firebase supprimé:**
- Aucun bouton Google visible
- Aucun appel Firebase dans la logique de connexion admin

### UnifiedAuthLogin.tsx

**Comportement existant correct:**
- Ligne 369: `{!isAdmin && ( ... )` masque Google pour les admins
- Les membres continuent à voir Google (Firebase requis)

---

## Matrice de Compatibilité Auth

| Type User | Communauté STANDARD | Communauté WL |
|-----------|---------------------|---------------|
| Admin | Legacy email/pwd ✅ | Legacy email/pwd ✅ |
| Membre | Firebase Google ✅ | Legacy email/pwd ✅ |

---

## Tests Recommandés

### Test 1: Login Admin Legacy
```
POST /api/admin/login
{ email: "admin@test.com", password: "xxx" }
→ 200 OK (plus de FIREBASE_REQUIRED)
```

### Test 2: Join avec Credentials
```
POST /api/admin/join-with-credentials
{ joinCode: "XXXX1234", email: "new@admin.com", password: "xxx" }
→ 201 Created + membership
```

### Test 3: UI Desktop Admin
- Vérifier 3 blocs visibles
- Vérifier absence bouton Google
- Vérifier flux invitation → login combiné

---

## Impact Sécurité

- **Isolation maintenue**: WL/STANDARD toujours séparés
- **Passwords hashed**: bcrypt pour tous nouveaux users
- **No Firebase leak**: Admins n'ont jamais accès aux tokens Firebase
- **Audit trail**: Logs avec traceId pour chaque action

---

## Fichiers Modifiés

| Fichier | Modification |
|---------|-------------|
| `server/routes.ts` | Suppression check FIREBASE_REQUIRED + nouvel endpoint join-with-credentials |
| `client/src/pages/admin/Login.tsx` | Design 3 blocs, Google supprimé (existant) |
| `client/src/pages/admin/JoinCommunity.tsx` | Suppression Firebase, utilise /api/admin/join-with-credentials |
| `client/src/components/unified/UnifiedAuthLogin.tsx` | Masquage Google pour admins (existant, vérifié) |

---

## Conclusion

Le contrat d'identité 2026-01 est maintenant correctement appliqué:
- Tous les administrateurs utilisent exclusivement l'authentification legacy (email/password)
- Firebase/Google est réservé aux membres de communautés STANDARD
- L'UI admin desktop présente clairement les 3 options disponibles
