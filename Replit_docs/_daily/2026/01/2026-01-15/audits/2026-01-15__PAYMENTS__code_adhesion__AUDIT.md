# AUDIT : CODE D'ADHÉSION KOOMY

**Date :** 16 Janvier 2026  
**Contexte :** Évaluation de la possibilité d'utiliser le code d'adhésion comme preuve de possession de l'email

---

## A) TERMINOLOGIE & FLUX ACTUEL

### 1) Naming exact dans le code et l'UI

| Terme | Contexte | Fichier |
|-------|----------|---------|
| `claimCode` | Variable/colonne technique | `shared/schema.ts:452`, `server/routes.ts` |
| `claim_code` | Colonne DB | `user_community_memberships.claim_code` |
| "Code de réclamation" | UI (messages d'erreur) | `server/routes.ts:3840, 3856` |
| "Code d'activation" | UI (email welcome) | `server/routes.ts:8762` |
| "code d'adhésion" | Non trouvé dans le code | — |

**Libellés UI :**
- Page AddCard : pas de libellé i18n spécifique, juste "Le code doit contenir 8 caractères"
- Erreurs backend : "Code de réclamation invalide", "Le code de réclamation est requis"
- Email : "code d'activation"

### 2) Flux actuel complet

```
1. Admin crée membre (POST /api/members)
   → Génère claimCode via generateClaimCode()
   → Stocke dans user_community_memberships.claim_code
   → Envoie email via sendMemberInviteEmail() avec le code

2. Utilisateur reçoit email avec code XXXX-XXXX

3. Utilisateur ouvre l'app mobile
   → Écran /app/add-card (AddCard.tsx)
   → Saisit le code (format XXXX-XXXX)

4. Vérification (GET /api/memberships/verify/:claimCode)
   → Vérifie que le code existe et n'est pas réclamé
   → Retourne displayName, communityName, memberId

5. Si pas de compte Koomy :
   → Création via /api/memberships/register-and-claim
   → Fournit email, password, firstName, lastName + claimCode
   → Crée le compte PUIS réclame le membership

6. Si compte existant :
   → POST /api/memberships/claim
   → Lie la carte au compte (accountId)
   → Met claimCode = null, claimedAt = now()
```

### 3) Moment de création du mot de passe

**Réponse :** L'utilisateur crée son mot de passe sur l'écran de signup `/api/memberships/register-and-claim`.

- Endpoint : `POST /api/memberships/register-and-claim`
- Fichier : `server/routes.ts:1835`
- Données requises : `claimCode, email, password, firstName, lastName`

Le mot de passe est créé **en même temps** que l'entrée du code, dans un flux combiné (register + claim en une transaction).

---

## B) PROPRIÉTÉS DU CODE D'ADHÉSION (SÉCURITÉ)

### 4) Stockage du code

| Propriété | Valeur |
|-----------|--------|
| **Table** | `user_community_memberships` |
| **Colonne** | `claim_code` (type: `text`) |
| **Fichier schéma** | `shared/schema.ts:452` |
| **Unique ?** | Non contraint en DB, mais commentaire indique "unique when set" |

```typescript
claimCode: text("claim_code"), // code to link card to account (e.g., XXXX-XXXX) - unique when set
```

### 5) Lien code ↔ email

| Question | Réponse |
|----------|---------|
| Code lié à un email ? | **Indirectement** via le membre |
| Vérification backend ? | **NON** |

**Détail :** Le code est lié à un `membership` qui a un champ `email`. Cependant, lors du `register-and-claim`, le backend :
- Vérifie que le code existe
- **NE vérifie PAS** que l'email fourni correspond à `membership.email`

```typescript
// server/routes.ts:1854
const membership = await storage.getMembershipByClaimCode(normalizedCode);
// → Aucune comparaison membership.email vs email fourni par l'utilisateur
```

**⚠️ RISQUE :** Un utilisateur peut créer un compte avec un email DIFFÉRENT de celui du membre et réclamer le code.

### 6) Usage unique du code

| Question | Réponse |
|----------|---------|
| Usage unique ? | **OUI** |
| Comportement après claim | Code mis à `null` |

```typescript
// server/storage.ts:940-944
.set({ 
  accountId, 
  claimedAt: new Date(),
  claimCode: null  // ← Code effacé après réclamation
})
```

**Si réutilisation :** `getMembershipByClaimCode()` retourne `undefined` → erreur "Invalid claim code".

### 7) Durée de validité (TTL)

| Question | Réponse |
|----------|---------|
| TTL actuel ? | **AUCUN** |
| Expiration ? | Le code est valide indéfiniment |

**Raison historique :** Simplicité de l'implémentation initiale. Pas de date d'expiration stockée.

**Recommandation :** 
- **OUI**, ajouter un TTL de 7-14 jours
- Ajouter colonne `claim_code_expires_at` timestamp
- Vérifier `WHERE claim_code_expires_at > NOW()` lors de la validation

### 8) Entropie du code / format

| Propriété | Valeur |
|-----------|--------|
| **Format** | `XXXX-XXXX` (8 caractères + tiret) |
| **Caractères** | `ABCDEFGHJKLMNPQRSTUVWXYZ23456789` (32 chars) |
| **Entropie** | 32^8 = **1,099,511,627,776** combinaisons (~40 bits) |

```typescript
// server/routes.ts:45-53
function generateClaimCode(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code = '';
  for (let i = 0; i < 8; i++) {
    if (i === 4) code += '-';
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return code;
}
```

**Guessable ?** Non en pratique (1 trillion de possibilités), mais nécessite rate limiting pour être vraiment sûr.

### 9) Régénération du code

| Question | Réponse |
|----------|---------|
| Endpoint de renvoi | `POST /api/memberships/:id/resend-claim-code` |
| Code précédent invalidé ? | **OUI** - nouveau code généré, remplace l'ancien |

```typescript
// server/routes.ts:3300-3301
const newCode = generateClaimCode();
const updated = await storage.updateMembership(req.params.id, { claimCode: newCode });
```

### 10) Protection anti brute-force

| Endpoint | Rate limit ? | Détail |
|----------|--------------|--------|
| `/api/memberships/claim` | **NON SPÉCIFIQUE** | Couvert par rate limit API général |
| `/api/memberships/verify/:code` | **NON SPÉCIFIQUE** | Couvert par rate limit API général |
| `/api/memberships/:id/resend-claim-code` | **OUI** | Max 3/10min par membership |

**Rate limit général (server/index.ts:156-163) :**
```typescript
const apiRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // 100 requests per window
  ...
});
```

**⚠️ RISQUE :** 100 requêtes/15min permettent théoriquement de tester ~400 codes/heure. Avec 1 trillion de possibilités, le brute-force n'est pas viable, mais un rate limit plus strict sur `/claim` serait prudent.

**Recommandation :** Ajouter rate limit spécifique sur `/api/memberships/claim` (ex: 5 tentatives/minute).

---

## C) IDENTITÉ UTILISATEUR (EMAIL) & VÉRIFICATION ACTUELLE

### 11) Gestion de l'auth et vérification email

| Système | Utilisé ? |
|---------|-----------|
| Firebase Auth | **NON** |
| DB interne | **OUI** (table `platform_users`, colonne `email_verified_at`) |

**Schéma (shared/schema.ts:357-358) :**
```typescript
isActive: boolean("is_active").default(false), // false until email verified (for platform admins)
emailVerifiedAt: timestamp("email_verified_at"), // when email was verified
```

**Note :** Cette vérification s'applique aux **platform admins**, pas aux membres mobile.

### 12) Email de vérification systématique ?

| Flux | Email de vérification ? |
|------|------------------------|
| Signup classique (`/api/accounts/register`) | À vérifier (pas de champ `emailVerifiedAt` dans `accounts`) |
| Signup via code (`/api/memberships/register-and-claim`) | **NON** |
| Platform admin signup | OUI (via `emailVerifiedAt`) |

**Pour les membres mobile :** La table `accounts` n'a **pas** de champ `emailVerifiedAt`. Les comptes sont actifs dès création.

### 13) Création via code : peut-on finaliser sans vérification ?

**Réponse : OUI**

L'utilisateur peut :
1. Recevoir le code par email (envoyé à l'adresse du membre)
2. Créer un compte avec **n'importe quel email**
3. Finaliser l'activation sans aucune vérification

**Comportement actuel réel :** Aucun lien de vérification n'est envoyé dans le flux `register-and-claim`.

### 14) Peut-on créer un compte avec un email différent du code ?

**Réponse : OUI (FAILLE)**

Le backend ne vérifie **pas** que l'email fourni correspond à `membership.email` :

```typescript
// server/routes.ts:1837-1856
const { claimCode, email, password, firstName, lastName } = req.body;
const membership = await storage.getMembershipByClaimCode(normalizedCode);
// → Aucune comparaison entre `email` (fourni) et `membership.email` (attendu)
```

**Correction recommandée :**
```typescript
if (membership.email && membership.email.toLowerCase() !== email.toLowerCase()) {
  return res.status(400).json({ 
    error: "L'email doit correspondre à celui associé à votre adhésion" 
  });
}
```

**Fichiers concernés :**
- `server/routes.ts` : endpoint `POST /api/memberships/register-and-claim`

### 15) Changement d'email après création

| Question | Réponse |
|----------|---------|
| UI existe ? | **NON** visible dans les écrans de profil |
| Endpoint backend ? | **NON** d'endpoint dédié pour changer l'email du compte |
| Contraintes | — |

**Note :** L'email du `membership` peut être modifié par l'admin via la page Members, mais l'email du `account` (auth) n'a pas d'UI de modification.

---

## D) RECOMMANDATION (SANS CODER)

### 16) Le code peut-il remplacer la vérification email ?

**Réponse : NON (en l'état actuel)**

**Justification :**
1. ❌ Le code n'est **pas vérifié** comme étant lié à l'email utilisé pour le signup
2. ❌ Un attaquant avec accès au code peut créer un compte avec un email qu'il contrôle
3. ❌ Pas de TTL = code valide indéfiniment (risque si email compromis plus tard)
4. ⚠️ Rate limiting insuffisant sur l'endpoint `/claim`

**Le code prouve seulement :** "quelqu'un a eu accès à ce code" — pas "cette personne possède l'email du membre".

### 17) Conditions minimales pour supprimer l'email de vérification

Si le code devait remplacer la vérification email, il faudrait **au minimum** :

| Condition | Priorité | Statut actuel |
|-----------|----------|---------------|
| **Forcer email = membership.email** | CRITIQUE | ❌ À implémenter |
| TTL 7-14 jours | Élevée | ❌ À ajouter |
| Usage unique | Élevée | ✅ OK |
| Rate limiting sur `/claim` | Élevée | ⚠️ Partiel |
| Invalidation à la régénération | Moyenne | ✅ OK |

### 18) Deux options

#### Option 1 : Changement minimal (V1 rapide)

**Principe :** Forcer l'email du signup = email du membership

| Tâche | Estimation | Fichiers |
|-------|------------|----------|
| Valider email = membership.email | S | `server/routes.ts` |
| Ajouter rate limit `/claim` 5/min | S | `server/index.ts` |
| **Total** | **S (1-2h)** | 2 fichiers |

**Code à ajouter (routes.ts:1854) :**
```typescript
if (membership.email && membership.email.toLowerCase() !== email.toLowerCase()) {
  return res.status(400).json({ 
    error: "L'email doit correspondre à celui de votre invitation" 
  });
}
```

**Limites :** Pas de TTL, dépend du rate limit général pour la sécurité.

---

#### Option 2 : Solution propre (alignée sécurité/scalabilité)

**Principe :** Code comme vrai token de possession d'email

| Tâche | Estimation | Fichiers |
|-------|------------|----------|
| Valider email = membership.email | S | `server/routes.ts` |
| Ajouter colonne `claim_code_expires_at` | S | `shared/schema.ts` |
| Générer TTL 14 jours à la création | S | `server/routes.ts` (4 endroits) |
| Vérifier expiration dans `getMembershipByClaimCode` | S | `server/storage.ts` |
| Rate limit spécifique `/claim` (5/min/IP) | S | `server/index.ts` |
| Rate limit `/verify/:code` (10/min/IP) | S | `server/index.ts` |
| Endpoint pour étendre le TTL (admin) | M | `server/routes.ts` |
| Migration DB | S | `npm run db:push` |
| **Total** | **M (4-6h)** | 4 fichiers + migration |

**Schéma modifié :**
```typescript
claimCode: text("claim_code"),
claimCodeExpiresAt: timestamp("claim_code_expires_at"), // ← Nouveau
```

**Bénéfices :**
- Code = preuve de possession de l'email (car envoyé uniquement à cet email)
- TTL limite l'exposition en cas de compromission
- Rate limiting bloque le brute-force
- Compatible avec la suppression de l'email de vérification

---

## RÉSUMÉ EXÉCUTIF

| Question clé | Réponse |
|--------------|---------|
| Le code est-il une preuve de possession email ? | **NON en l'état** (email non vérifié) |
| Risque principal ? | Création de compte avec email différent |
| Fix minimal ? | Forcer `signup.email == membership.email` |
| Fix complet ? | + TTL + rate limiting dédié |

---

*Rapport généré le 16 Janvier 2026*
