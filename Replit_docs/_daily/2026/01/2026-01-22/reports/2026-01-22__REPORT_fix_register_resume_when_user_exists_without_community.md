# Fix: Register Resume When User Exists Without Community

**Date:** 2026-01-22  
**Type:** Bug Fix / Idempotency  
**Environment:** Sandbox + Production  
**Status:** COMPLETED

---

## Problème Initial

En sandbox, on observait:
- Les utilisateurs Firebase (Google Sign-In) étaient créés dans Firebase
- Mais les clubs (communities) n'étaient pas toujours créés en DB
- Parfois l'utilisateur existe dans Firebase mais pas en DB (ou existe partiellement)
- L'onboarding KOOMY restait incomplet, bloquant les tests

## Cause Racine

Le code `/api/admin/register` rejetait avec `EMAIL_TAKEN` dès qu'un `account` existait dans la table `accounts` (utilisateurs mobiles), sans vérifier si c'était le même utilisateur Firebase.

Cas problématiques non gérés:
1. Account mobile existe avec le même `firebaseUid` (via `providerId`) → devrait permettre la création d'un user admin
2. User existe mais sans community → devrait reprendre le flow et créer la community

---

## Solution Implémentée

### 1. Amélioration du Case 3 (Account Exists)

**Avant:**
```typescript
} else if (existingAccount) {
  console.log(`REJECT: EMAIL_TAKEN (in accounts)`);
  return res.status(400).json({ code: "EMAIL_TAKEN" });
}
```

**Après:**
```typescript
} else if (existingAccount) {
  // Vérifier si c'est le même Firebase user
  if (existingAccount.authProvider === 'firebase' && existingAccount.providerId === firebaseUser.uid) {
    // Même user → autoriser la création admin
    console.log(`Mobile account exists for same Firebase user, creating admin user`);
    // Fall through to Case 4 (create new user)
  } else if (existingAccount.providerId && existingAccount.providerId !== firebaseUser.uid) {
    // Différent Firebase user → rejeter
    return res.status(409).json({ code: "EMAIL_ALREADY_LINKED" });
  } else {
    // Account email-only → rejeter
    return res.status(400).json({ code: "EMAIL_TAKEN" });
  }
}
```

### 2. Amélioration de la détection "User Exists Without Community"

**Avant:**
```typescript
if (existingUserByUid || existingUserByEmail) {
  // Check for community
}
```

**Après:**
```typescript
const userExistedBefore = existingUserByUid || existingUserByEmail || (existingAccount && user);

if (userExistedBefore && user) {
  console.log(`REGISTER_STATE`, { hasUser, hasAccount, hasOwnerCommunity });
  
  if (ownedCommunity) {
    return res.status(409).json({ 
      code: "ALREADY_REGISTERED", 
      communityId: ownedCommunity.communityId 
    });
  }
  
  console.log(`RESUME_CREATE_COMMUNITY_START`);
  // Create community + membership
}
```

---

## Fichiers Modifiés

| Fichier | Lignes | Modification |
|---------|--------|--------------|
| `server/routes.ts` | 2688-2733 | Nouveau Case 3 avec vérification `providerId` |
| `server/routes.ts` | 2912-2945 | Condition élargie + logs REGISTER_STATE/RESUME_CREATE_COMMUNITY |
| `server/routes.ts` | 2988-2992 | Log RESUME_CREATE_COMMUNITY_OK |

---

## Nouveaux Logs de Diagnostic

| Log Pattern | Signification |
|-------------|---------------|
| `REGISTER_STATE { hasUser, hasAccount, hasOwnerCommunity }` | État du user avant décision |
| `RESUME_CREATE_COMMUNITY_START` | User existe sans community, création en cours |
| `RESUME_CREATE_COMMUNITY_OK` | Community + membership créés avec succès |
| `REGISTER_ALREADY_HAS_COMMUNITY` | User a déjà une community (rejet 409) |

---

## Tests Attendus

### Test A: Nouvel utilisateur
```
Flow: Google Sign-In (nouveau) → Register (plan=free)
Attendu: 201 + community créée
Log: ATOMIC_SUCCESS
```

### Test B: Utilisateur DB sans community
```
Setup: User existe en DB (via backfill UID), mais 0 membership owner
Flow: Google Sign-In → Register
Attendu: 200/201 + community créée
Log: REGISTER_STATE { hasUser: true, hasOwnerCommunity: false }
      RESUME_CREATE_COMMUNITY_START
      RESUME_CREATE_COMMUNITY_OK
```

### Test C: Utilisateur avec community existante
```
Setup: User avec 1 community owned
Flow: Google Sign-In → Register
Attendu: 409 ALREADY_REGISTERED + communityId
Log: REGISTER_ALREADY_HAS_COMMUNITY
```

### Test D: Email lié à un autre Firebase account
```
Setup: Account mobile avec providerId = "xyz123"
Flow: Google Sign-In (firebaseUid = "abc789") → Register
Attendu: 409 EMAIL_ALREADY_LINKED
Log: REJECT: EMAIL_ALREADY_LINKED (different firebase_uid in account)
```

---

## Vérification SQL

```sql
-- Trouver les users sans community owner
SELECT u.id, u.email, u.firebase_uid, 
       COUNT(m.id) FILTER (WHERE m.is_owner = true) as owned_communities
FROM users u
LEFT JOIN memberships m ON m.user_id = u.id
GROUP BY u.id, u.email, u.firebase_uid
HAVING COUNT(m.id) FILTER (WHERE m.is_owner = true) = 0;

-- Vérifier les accounts mobiles Firebase
SELECT id, email, auth_provider, provider_id 
FROM accounts 
WHERE auth_provider = 'firebase';
```

---

## Codes de Réponse API

| Code | HTTP | Signification |
|------|------|---------------|
| `ALREADY_REGISTERED` | 409 | User a déjà une community |
| `EMAIL_ALREADY_LINKED` | 409 | Email lié à un autre Firebase account |
| `EMAIL_TAKEN` | 400 | Email utilisé par un compte mobile (non-Firebase) |
| (success) | 201 | Community créée (nouveau user ou resume) |

---

**Auteur:** Replit Agent
