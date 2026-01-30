# Rapport: Refonte Portail Admin Desktop — CODE-FIRST + Création Interne

**Date:** 2026-01-23  
**Auteur:** Agent  
**Version:** 1.0

---

## Résumé Exécutif

Cette mise à jour refactorisse le portail admin desktop selon les spécifications produit:
- **Layout 2 colonnes** : Marketing à gauche, Actions à droite
- **Design clair** : Fond clair, pas trop sombre, desktop-first
- **Création communauté interne** : Plus de redirection vers le site public
- **Aucun bouton Google** : Email/password uniquement
- **CODE-FIRST** : Flux invitation prioritaire

---

## Changements Frontend

### AdminLogin.tsx - Nouvelle Structure

#### Layout 2 Colonnes

| Colonne | Contenu |
|---------|---------|
| Gauche (50%) | Logo, baseline, features, pricing info, gradient purple/indigo |
| Droite (50%) | 3 actions principales, fond clair |

#### Colonne Gauche - Marketing
- Logo Koomy + titre "Gérez votre communauté simplement"
- 5 features avec icônes: Membres, Cotisations, Événements, QR Check-in, Cartes digitales
- Bloc "Plans flexibles" avec pricing

#### Colonne Droite - Actions (3 cards)

| Card | CTA | Action |
|------|-----|--------|
| Créer ma communauté | Gradient purple | Flow `/api/admin/register-community` |
| J'ai un code d'invitation | Blanc avec border | Flow invitation code-first |
| Se connecter | Blanc avec border | Flow login email/password |

### Design System

- **Fond principal**: `linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%)` (clair)
- **Colonne marketing**: `linear-gradient(135deg, #1e1b4b 0%, #312e81 50%, #4338ca 100%)` (purple)
- **Cards actions**: `bg-white border border-gray-200`
- **Bouton principal**: `bg-purple-600 hover:bg-purple-700`
- **Typographie**: Gris foncé pour texte, pas de blanc sur fond clair

---

## Changements Backend

### Nouvel Endpoint `/api/admin/register-community`

**Route:** `POST /api/admin/register-community`  
**Auth:** Aucune (création de compte)

**Body:**
```json
{
  "communityName": "string (required)",
  "email": "string (required)",
  "password": "string (required, min 8 chars)",
  "firstName": "string (optional)",
  "lastName": "string (optional)"
}
```

**Réponse succès (201):**
```json
{
  "ok": true,
  "user": { "id", "email", "firstName", "lastName", "role" },
  "community": { "id", "name", "memberJoinCode", "subscriptionStatus", "trialEndDate" },
  "memberships": [...]
}
```

**Logique:**
1. Vérifie email non existant
2. Hash password avec bcrypt
3. Crée user avec role 'admin'
4. Crée community avec `subscriptionStatus: 'trialing'`, `trialEndDate: J+14`
5. Crée membership owner avec `isOwner: true`, `adminRole: 'super_admin'`
6. Génère `memberJoinCode` automatique

---

## Flows Utilisateur

### Flow 1 - Créer une communauté

1. Clic sur card "Créer ma communauté"
2. Formulaire: Nom communauté, Prénom/Nom (optionnel), Email, Mot de passe
3. Appel `/api/admin/register-community`
4. Redirection `/admin/dashboard`

### Flow 2 - Invitation Admin

1. Clic sur card "J'ai un code d'invitation"
2. Formulaire: Code XXXX-XXXX, Email, Mot de passe
3. Appel `/api/admin/join-with-credentials`
4. Redirection `/admin/dashboard`

### Flow 3 - Connexion

1. Clic sur card "Se connecter"
2. Formulaire: Email, Mot de passe
3. Appel `/api/admin/login`
4. Redirection `/admin/dashboard`

---

## Check-list DoD

| # | Critère | Statut |
|---|---------|--------|
| 1 | Portail admin desktop 2 colonnes (marketing + actions) | ✅ |
| 2 | Design plus clair, moins sombre | ✅ |
| 3 | CTA "Créer une communauté" crée bien un club via `/api/admin/register-community` | ✅ |
| 4 | Trial 14 jours, status trialing | ✅ |
| 5 | Parcours "Invitation Admin" fonctionne | ✅ |
| 6 | Parcours "Se connecter" fonctionne | ✅ |
| 7 | Aucun bouton Google visible | ✅ |
| 8 | Aucun renvoi vers site public pour créer communauté | ✅ |

---

## Fichiers Modifiés

| Fichier | Modification |
|---------|-------------|
| `client/src/pages/admin/Login.tsx` | Refonte complète: 2 colonnes, design clair, 4 views (main/login/invitation/register) |
| `client/src/pages/admin/JoinCommunity.tsx` | Migration vers legacy auth (plus de Firebase) |
| `server/routes.ts` | Nouvel endpoint `/api/admin/register-community` + modification `/api/admin/login` + endpoint `/api/admin/join-with-credentials` |
| `docs/rapports/2026-01-23__REPORT__admin_auth_ui_refonte_email_only.md` | Rapport précédent |

---

## Sécurité

- **Passwords hashed**: bcrypt (10 rounds)
- **Email normalisé**: lowercase + trim
- **Vérification email unique**: Avant création
- **Trial automatique**: 14 jours, pas de CB
- **Aucun Firebase côté admin**: Contrat respecté

---

## Conclusion

Le portail admin desktop est maintenant conforme aux spécifications produit:
- Design professionnel 2 colonnes, clair et lisible
- Création de communauté intégrée (pas de redirection externe)
- Aucun bouton Google visible
- Flux invitation code-first fonctionnel
- Trial 14 jours automatique sans CB
