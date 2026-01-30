# KOOMY — Firebase-Only Auth Migration QA MINIMAL

**Date**: 2026-01-24
**Durée estimée**: 30 minutes
**Environnement**: Sandbox (backoffice-sandbox.koomy.app)

---

## C1) 12 Scénarios de Test

### Scénario 1: Admin Login Email/Password

**Objectif**: Vérifier la connexion admin via Firebase

| Étape | Action |
|-------|--------|
| 1 | Aller sur `backoffice-sandbox.koomy.app` |
| 2 | Saisir email admin valide |
| 3 | Saisir mot de passe correct |
| 4 | Cliquer "Connexion" |

**Endpoints touchés**:
- Firebase Auth (signInWithEmailAndPassword)
- `GET /api/auth/me`

**Résultat attendu**:
- Toast "Connexion réussie"
- Redirection vers dashboard ou select-community
- Console: `[AUTH] Firebase user authenticated`

**Log backend attendu**:
```
[AUTH_ME] Firebase auth successful, accountId=xxx
```

**Stop condition**: 401 ou message d'erreur affiché

---

### Scénario 2: Admin Mauvais Mot de Passe

**Objectif**: Vérifier le message d'erreur UX

| Étape | Action |
|-------|--------|
| 1 | Aller sur page login admin |
| 2 | Saisir email admin valide |
| 3 | Saisir mot de passe INCORRECT |
| 4 | Cliquer "Connexion" |

**Résultat attendu**:
- Toast d'erreur visible ("Identifiants incorrects" ou similaire)
- Message d'erreur affiché dans le formulaire
- Pas de redirection

**Stop condition**: Erreur silencieuse (console only) ou crash

---

### Scénario 3: Refresh Page (F5)

**Objectif**: Vérifier la persistence de session

| Étape | Action |
|-------|--------|
| 1 | Se connecter en tant qu'admin |
| 2 | Attendre le dashboard |
| 3 | Appuyer F5 (refresh) |

**Résultat attendu**:
- Session maintenue
- Dashboard affiché (pas de retour login)
- Console: `[AUTH] Firebase session restored`

**Stop condition**: Retour à la page login

---

### Scénario 4: CRUD Section

**Objectif**: Vérifier les opérations sur sections

| Étape | Action |
|-------|--------|
| 1 | Aller dans Paramètres > Sections |
| 2 | Créer une section "Test QA" |
| 3 | Modifier le nom en "Test QA Modifié" |
| 4 | Supprimer la section |

**Endpoints touchés**:
- `POST /api/communities/:id/sections`
- `PATCH /api/communities/:id/sections/:id`
- `DELETE /api/communities/:id/sections/:id`

**Résultat attendu**:
- 200 OK sur chaque opération
- Toast de succès
- Liste mise à jour

**Stop condition**: 401 ou 403 sur une opération

---

### Scénario 5: CRUD Event

**Objectif**: Vérifier les opérations sur événements

| Étape | Action |
|-------|--------|
| 1 | Aller dans Événements |
| 2 | Créer un événement "Test Event QA" |
| 3 | Modifier le titre |
| 4 | Supprimer l'événement |

**Endpoints touchés**:
- `POST /api/communities/:id/events`
- `PATCH /api/communities/:id/events/:id`
- `DELETE /api/communities/:id/events/:id`

**Résultat attendu**: 200 OK sur chaque opération

**Stop condition**: 401 ou 403

---

### Scénario 6: CRUD News

**Objectif**: Vérifier les opérations sur actualités

| Étape | Action |
|-------|--------|
| 1 | Aller dans Actualités |
| 2 | Créer une news "Test News QA" |
| 3 | Modifier le contenu |
| 4 | Supprimer la news |

**Endpoints touchés**:
- `POST /api/communities/:id/news`
- `PATCH /api/communities/:id/news/:id`
- `DELETE /api/communities/:id/news/:id`

**Résultat attendu**: 200 OK sur chaque opération

**Stop condition**: 401 ou 403

---

### Scénario 7: Create Admin / Assign Role

**Objectif**: Vérifier l'ajout d'un administrateur

| Étape | Action |
|-------|--------|
| 1 | Aller dans Paramètres > Équipe |
| 2 | Ajouter un nouvel admin (email) |
| 3 | Attribuer un rôle |

**Endpoints touchés**:
- `POST /api/communities/:id/admins`

**Résultat attendu**:
- 200 OK
- Nouvel admin dans la liste

**Stop condition**: 401 ou 403

---

### Scénario 8: Switch Community

**Objectif**: Vérifier le changement de communauté (si multi-club)

| Étape | Action |
|-------|--------|
| 1 | Se connecter avec un compte multi-communauté |
| 2 | Sélectionner une communauté |
| 3 | Vérifier l'URL contient le bon communityId |
| 4 | Changer de communauté |

**Résultat attendu**:
- URL: `/app/{communityId}/admin`
- Pas de double slash `//`
- Données de la bonne communauté affichées

**Stop condition**: Double slash dans URL ou mauvaises données

---

### Scénario 9: Membre Login (Wallet)

**Objectif**: Vérifier le login membre séparé du flux admin

| Étape | Action |
|-------|--------|
| 1 | Aller sur `sandbox.koomy.app` |
| 2 | Se connecter en tant que membre |

**Résultat attendu**:
- Accès au hub membre
- Pas d'interférence avec le flux admin

**Stop condition**: Erreur auth ou redirection admin

---

### Scénario 10: Claim Flow (code déjà utilisé)

**Objectif**: Vérifier la gestion des codes déjà réclamés

| Étape | Action |
|-------|--------|
| 1 | Utiliser un code de claim déjà réclamé |
| 2 | Vérifier le comportement |

**Résultat attendu**:
- Message explicite "Code déjà utilisé"
- Redirection vers hub (pas écran relique)

**Stop condition**: Écran bloquant ou erreur non gérée

---

### Scénario 11: Token Non-JWT (test sécurité)

**Objectif**: Vérifier que les tokens legacy sont rejetés

| Étape | Action |
|-------|--------|
| 1 | Via Postman/curl, envoyer requête avec token 33 caractères |
| 2 | Exemple: `Authorization: Bearer abc123def456ghi789jkl012mno345pq` |

**Endpoint test**: `GET /api/communities/:id/sections`

**Résultat attendu**:
- 401 Unauthorized
- Code: `FIREBASE_AUTH_REQUIRED`

**Stop condition**: 200 OK avec token legacy

---

### Scénario 12: Logout Complet

**Objectif**: Vérifier le nettoyage de session

| Étape | Action |
|-------|--------|
| 1 | Se connecter en admin |
| 2 | Cliquer Déconnexion |
| 3 | Vérifier retour à la page login |
| 4 | Tenter d'accéder au dashboard directement |

**Résultat attendu**:
- Retour page login
- Accès dashboard bloqué (redirection login)
- Console: `[AUTH] Signed out`

**Stop condition**: Accès dashboard après logout

---

## C2) Critères Go/No-Go PROD

### Go (tous requis)

| Critère | Condition |
|---------|-----------|
| ✅ Login admin | Fonctionne avec Firebase |
| ✅ CRUD sections | 0 erreur 401/403 |
| ✅ CRUD events | 0 erreur 401/403 |
| ✅ CRUD news | 0 erreur 401/403 |
| ✅ Refresh page | Session maintenue |
| ✅ Logout | Nettoyage complet |
| ✅ Token length | Jamais 33 caractères |
| ✅ Legacy endpoint | `/api/admin/login` retourne 410 |

### No-Go (bloquants)

| Critère | Action |
|---------|--------|
| ❌ Erreur 401 non expliquée | Investiguer avant PROD |
| ❌ Token legacy accepté | Corriger requireFirebaseOnly |
| ❌ Logout incomplet | Corriger signOut() |
| ❌ Reset password cassé | Implémenter avant PROD |

---

**FIN DU QA MINIMAL**
