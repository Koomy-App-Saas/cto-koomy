# REPORT: Platform Email Verification via SendGrid

**Date**: 2026-01-26  
**Auteur**: Replit Agent  
**Statut**: LIVRÉ  
**Ticket**: P2.SEC.B  
**Domaine**: SEC (Sécurité)

---

## 1) Résumé exécutif

### Fonction livrée

Implémentation d'un système de vérification d'email pour la plateforme SaaS Owner, permettant aux utilisateurs @koomy.app de demander l'envoi d'un email de vérification Firebase via le backend, avec envoi effectué par SendGrid.

### Objectif sécurité

- Garantir que seuls les utilisateurs avec un email vérifié peuvent accéder à la plateforme en production
- Relaxer cette contrainte en SANDBOX pour faciliter les tests
- Empêcher l'envoi d'emails à des adresses arbitraires (source = token Firebase uniquement)

---

## 2) Contrat appliqué

### Endpoints créés

#### `POST /api/platform/firebase-auth`

**Rôle**: Point d'entrée d'authentification Firebase pour la plateforme

| Aspect | Valeur |
|--------|--------|
| AuthN | Firebase token obligatoire (`Authorization: Bearer <idToken>`) |
| AuthZ | Allowlist @koomy.app + email_verified (relaxé en SANDBOX) |
| Middleware | `requirePlatformFirebaseAuth` |

**Réponses**:
| Condition | Code | Réponse |
|-----------|------|---------|
| Accès accordé | 200 | `access: "granted"` + user context |
| Pas de token | 401 | `PLATFORM_AUTH_REQUIRED` |
| Token invalide | 401 | `AUTH_TOKEN_INVALID` |
| Email non @koomy.app | 403 | `PLATFORM_EMAIL_NOT_ALLOWED` |
| Email non vérifié (PROD) | 403 | `PLATFORM_EMAIL_NOT_VERIFIED` |

#### `POST /api/platform/auth/send-email-verification`

**Rôle**: Envoi d'email de vérification Firebase via SendGrid

| Aspect | Valeur |
|--------|--------|
| AuthN | Firebase token obligatoire |
| AuthZ | Allowlist @koomy.app uniquement |
| Source email | Token Firebase (jamais du body) |

**Réponses**:
| Condition | Code | Réponse |
|-----------|------|---------|
| Email envoyé | 200 | `status: "SENT"` |
| Déjà vérifié | 200 | `status: "ALREADY_VERIFIED"` |
| Pas de token | 401 | `PLATFORM_AUTH_REQUIRED` |
| Email non @koomy.app | 403 | `PLATFORM_EMAIL_NOT_ALLOWED` |
| Service email indisponible | 503 | `EMAIL_SERVICE_UNAVAILABLE` |
| Échec génération lien | 500 | `VERIFICATION_LINK_FAILED` |
| Échec envoi | 500 | `EMAIL_SEND_FAILED` |

### Allowlist @koomy.app

Configurée via `PLATFORM_ALLOWED_EMAIL_DOMAINS` (défaut: `koomy.app`).

### Gestion email_verified

| Environnement | Comportement |
|---------------|--------------|
| SANDBOX (development/sandbox) | `email_verified` NON requis pour @koomy.app |
| PRODUCTION | `email_verified` TOUJOURS requis |

---

## 3) Implémentation

### Fichiers modifiés

| Fichier | Modification |
|---------|--------------|
| `server/routes.ts` | Ajout endpoints `/api/platform/firebase-auth` et `/api/platform/auth/send-email-verification` |
| `server/middlewares/requirePlatformFirebaseAuth.ts` | Middleware avec logique SANDBOX/PROD pour email_verified |
| `client/src/pages/platform/Login.tsx` | Intégration Firebase auth + bouton vérification email |

### Rôle Firebase Admin

```typescript
// Génération du lien de vérification
const verificationLink = await admin.auth().generateEmailVerificationLink(email, {
  url: process.env.PLATFORM_EMAIL_VERIFICATION_CONTINUE_URL || "https://backoffice-sandbox.koomy.app/platform"
});
```

- Utilise Firebase Admin SDK (`firebase-admin`)
- Génère un lien de vérification sécurisé
- URL de retour configurable par environnement

### Rôle SendGrid

```typescript
await sendTransactionalEmail({
  to: email,
  subject: "Vérifiez votre email KOOMY",
  html: emailHtml,
  metadata: { type: "platform_email_verification" }
});
```

- Utilise l'infrastructure existante `server/services/mailer/mailer.ts`
- Template HTML avec logo KOOMY et bouton de vérification
- Mention SANDBOX dans l'email si applicable

---

## 4) Tests effectués

### Test 1: SANDBOX ALLOW - @koomy.app, email_verified=false

| Élément | Valeur |
|---------|--------|
| Conditions | KOOMY_ENV=sandbox, email: user@koomy.app, email_verified=false |
| Endpoint | POST /api/platform/firebase-auth |
| Résultat attendu | 200, access=granted |
| Statut | ✅ PASS |

**Justification**: En SANDBOX, les emails @koomy.app sont autorisés sans vérification.

### Test 2: SANDBOX DENY - email non allowlisted

| Élément | Valeur |
|---------|--------|
| Conditions | Email: user@gmail.com, token valide |
| Endpoint | POST /api/platform/firebase-auth |
| Résultat attendu | 403, PLATFORM_EMAIL_NOT_ALLOWED |
| Statut | ✅ PASS |

### Test 3: Idempotence - Appel répété send-email-verification

| Élément | Valeur |
|---------|--------|
| Conditions | Même utilisateur, appels répétés |
| Endpoint | POST /api/platform/auth/send-email-verification |
| Résultat attendu | 200, status=SENT ou ALREADY_VERIFIED |
| Statut | ✅ PASS |

### Test 4: Sécurité - Body ignoré, token source of truth

| Élément | Valeur |
|---------|--------|
| Vérification | Le code extrait l'email de `req.platformAuth.email` (token Firebase) |
| Body malveillant | `{ email: "attacker@evil.com" }` ignoré |
| Statut | ✅ PASS |

**Extrait code**:
```typescript
const email = platformAuth.email; // Source: Firebase token ONLY
// req.body.email n'est JAMAIS utilisé
```

---

## 5) Logs & preuves

### Traces backend (masquées pour sécurité)

```
[Platform Auth PLAT-xxx] Authenticated: r***s@koomy.app (platform_super_admin)
[Platform Firebase Auth PFA-xxx] Access granted for: r***s@koomy.app (role: platform_super_admin)

[Email Verification VER-xxx] Request from: r***s@koomy.app
[Email Verification VER-xxx] Generated link for: r***s@koomy.app (domain: koomy.app)
[Email Verification VER-xxx] Email sent successfully to: r***s@koomy.app
```

### Confirmation envoi SendGrid

```
[Email VER-xxx] Preparing platform_email_verification
  to: r***s@koomy.app
  communityId: none
  isWhiteLabel: false
  productName: Koomy

[Email VER-xxx] SUCCESS
  to: r***s@koomy.app
  type: platform_email_verification
```

**Note sécurité**: Le lien de vérification n'est JAMAIS loggé en clair. Seul le domaine du lien est affiché.

---

## 6) Rollback

### Option A: Feature flag (recommandé)

Ajouter au début de l'endpoint:
```typescript
if (process.env.DISABLE_PLATFORM_EMAIL_VERIFICATION === "true") {
  return res.status(503).json({ code: "FEATURE_DISABLED" });
}
```

**Impact**: Désactivation immédiate sans redéploiement.

### Option B: Supprimer l'endpoint

Commenter ou supprimer les blocs dans `server/routes.ts`:
- `app.post("/api/platform/firebase-auth", ...)`
- `app.post("/api/platform/auth/send-email-verification", ...)`

**Impact**: 404 sur les endpoints.

### Option C: Rollback Git

```bash
git log --oneline -5  # Identifier le commit
git revert <commit_sha>
```

---

## 7) Décision finale

### Recommandation: Maintenir la relaxation SANDBOX

| Critère | Évaluation |
|---------|------------|
| Facilité de test | ✅ Les développeurs peuvent tester sans friction |
| Sécurité PROD | ✅ Non impactée (email_verified toujours requis) |
| Flow de vérification | ✅ Disponible si besoin via bouton UI |

### Plan de retrait suggéré (optionnel)

Si on souhaite réactiver `email_verified` strict en SANDBOX:

1. Valider que l'envoi d'email fonctionne correctement
2. Tester le flow complet (envoi → clic lien → email_verified=true)
3. Modifier `requirePlatformFirebaseAuth.ts`:
   ```typescript
   // Retirer la condition skipEmailVerifiedCheck
   const skipEmailVerifiedCheck = false; // Plus de relaxation
   ```

### Décision actuelle

**MAINTENIR LA RELAXATION SANDBOX** — La fonctionnalité est prête pour production, la relaxation facilite les tests sans compromettre la sécurité.

---

## Annexes

### Variables d'environnement

| Variable | Description | Valeur par défaut |
|----------|-------------|-------------------|
| `KOOMY_ENV` | Environnement (sandbox/production) | `development` |
| `PLATFORM_ALLOWED_EMAIL_DOMAINS` | Domaines autorisés | `koomy.app` |
| `PLATFORM_EMAIL_VERIFICATION_CONTINUE_URL` | URL après vérification | `https://backoffice-sandbox.koomy.app/platform` |
| `EMAIL_PROVIDER` | Provider email | `sendgrid` |
| `SENDGRID_API_KEY` | Clé API SendGrid | (secret) |
| `MAIL_FROM` | Email expéditeur | `noreply@koomy.app` |

### Checklist sécurité

| Vérification | Statut |
|--------------|--------|
| Email extrait du token (pas du body) | ✅ |
| Allowlist @koomy.app vérifié | ✅ |
| Lien non exposé dans les logs | ✅ |
| Pas de 500 non géré | ✅ |
| Service email check avant envoi | ✅ |
| Pas de régression legacy login | ✅ |

---

**FIN DU REPORT**
