# Rapport Option B: Auth-First-Then-Join (STANDARD Communities)

**Date**: 2026-01-23  
**Statut**: Implémenté  
**Contract Tests**: 6/6 PASS (100%)

## Résumé

Option B implémente le flux "authentification d'abord, puis rejoindre" pour les communautés STANDARD (non white-label). Ce flux sépare clairement l'authentification Firebase de l'adhésion à une communauté.

## Flux Membre STANDARD

```
┌─────────────────────────────────────────────────────────────────────┐
│                    MEMBRE STANDARD FLOW                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  1. /app/login → Login Firebase (email/password ou Google)         │
│          ↓                                                          │
│  2. Firebase Auth Success → Création compte si nouveau              │
│          ↓                                                          │
│  3. /app/hub → CommunityHub (liste memberships)                     │
│          ↓                                                          │
│  4a. Si memberships.length > 0 → Sélectionner communauté            │
│          ↓                                                          │
│  4b. Si memberships.length = 0 → Bouton "Rejoindre" → /app/join     │
│          ↓                                                          │
│  5. /app/join → JoinCommunityStandard (saisie code 8 caractères)    │
│          ↓                                                          │
│  6. POST /api/members/join avec Firebase token + code               │
│          ↓                                                          │
│  7. Création membership → Redirection /app/{communityId}/home       │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## Changements de Schéma

### Table `communities`
- Ajout `member_join_code TEXT UNIQUE` - Code 8 caractères alphanumériques pour rejoindre

### Table `admin_invitations` (nouvelle)
- `id` VARCHAR(50) PRIMARY KEY
- `community_id` VARCHAR(50) REFERENCES communities(id)
- `email` TEXT NOT NULL
- `token` TEXT UNIQUE - Token sécurisé pour l'invitation
- `invited_by` VARCHAR(50) REFERENCES users(id)
- `role` TEXT DEFAULT 'admin'
- `expires_at` TIMESTAMP
- `accepted_at` TIMESTAMP
- `created_at` TIMESTAMP DEFAULT now()

## Endpoints API

### POST /api/members/join
- **Auth**: Firebase Bearer Token requis
- **Body**: `{ code: string }` - Code d'adhésion 8 caractères
- **Validation**:
  - Code normalisé en majuscules, sans tirets
  - Communauté doit avoir `whiteLabel = false` (STANDARD)
  - Contract enforcement: Firebase OBLIGATOIRE pour STANDARD
  - Vérification quota membres
  - Vérification membership existant

- **Réponses**:
  - `201`: Membership créé avec succès
  - `400 MISSING_JOIN_CODE`: Code non fourni
  - `400 INVALID_CODE_LENGTH`: Code n'a pas exactement 8 caractères
  - `404 INVALID_JOIN_CODE`: Code invalide ou communauté non trouvée
  - `409 ALREADY_MEMBER`: Déjà membre de cette communauté
  - `403 FORBIDDEN_CONTRACT`: Tentative rejoindre white-label via Firebase
  - `401`: Token Firebase invalide/manquant

## Composants Frontend

### JoinCommunityStandard.tsx
- Écran mobile pour saisie du code d'adhésion
- Input 8 caractères avec normalisation automatique
- Feedback visuel (loading, erreurs, succès)
- Redirection vers communauté après succès

### CommunityHub.tsx (modifié)
- Bouton "Rejoindre une communauté" adapté:
  - Si `account` (Firebase auth) → `/app/join`
  - Si `user` (Legacy auth) → `/app/add-card` (claim code existant)

## Contract Invariants Respectés

| Rule | Status |
|------|--------|
| whiteLabel=false → authMode=FIREBASE_ONLY | ✅ Enforced |
| whiteLabel=true → authMode=LEGACY_ONLY | ✅ Enforced |
| Firebase forbidden for White-Label | ✅ Returns 403 |
| Firebase forbidden for SaaS Owner | ✅ Returns 403 |

## Tests de Contrat

```
╔═══════════════════════════════════════════════════════════════╗
║       KOOMY — CONTRACT TESTS (Option C)                       ║
╚═══════════════════════════════════════════════════════════════╝

✅ T1_STANDARD_REGISTER: PASS
✅ T2_WL_FIREBASE_FORBIDDEN: PASS
✅ T3_SAAS_OWNER_FIREBASE_FORBIDDEN: PASS
✅ T4_ENUM_NO_PENDING: PASS
✅ T5_IDENTITY_RESOLUTION: PASS
✅ T6_ANTI_ORPHANS: PASS

Success rate: 100.0%
```

## Prochaines Étapes (Non implémenté)

1. **Admin Invitation Flow**: Envoi d'invitations par email avec token sécurisé
2. **Code Generation UI**: Interface admin pour générer/régénérer le `member_join_code`
3. **Email Notifications**: Envoi email avec code après création membership
4. **Deep Link Support**: Support `koomy://join/{code}` pour mobile natif

## Fichiers Modifiés

- `server/routes.ts` - Endpoint POST /api/members/join
- `shared/schema.ts` - Schéma admin_invitations (déclaration Drizzle)
- `client/src/pages/mobile/JoinCommunityStandard.tsx` - Nouvel écran
- `client/src/pages/mobile/CommunityHub.tsx` - Routing conditionnel
- `client/src/App.tsx` - Route /app/join
