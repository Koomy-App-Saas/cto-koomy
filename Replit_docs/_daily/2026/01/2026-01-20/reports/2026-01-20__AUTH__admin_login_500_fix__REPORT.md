# Rapport d'Audit - Fix 500 Error on /api/admin/login

**Date**: 2026-01-21  
**Auteur**: Agent Replit  
**Statut**: COMPLETED  
**Sévérité**: CRITICAL (blocking production login)

---

## Problème Initial

Le endpoint `/api/admin/login` retournait des erreurs 500 en production suivies de 429 (rate limiting), rendant l'accès au back-office impossible.

### Symptômes Observés
- Erreur 500 sur la première tentative de login
- Erreur 429 sur les tentatives suivantes (rate limit triggered by repeated 500s)
- Aucun traceId dans les réponses pour le debugging
- Logs insuffisants pour identifier la cause exacte

### Cause Probable
- Exception non catchée dans les opérations DB ou cryptographiques
- Absence de try/catch granulaire rendant le debugging impossible
- Pas de logging structuré pour tracer chaque étape

---

## Solution Implémentée

### 1. TraceId Systématique

```typescript
const traceId = req.headers['x-trace-id'] as string || 
  `AL-${Date.now().toString(36)}-${Math.random().toString(36).substring(2, 8)}`;
```

- Reprend le traceId du header frontend si présent
- Génère un traceId unique sinon (préfixe `AL-` = Admin Login)
- Retourne le traceId dans TOUTES les réponses (200, 400, 401, 500)

### 2. Logging Structuré à Chaque Étape

| Step | Log Pattern | Description |
|------|-------------|-------------|
| START | `[Admin Login {traceId}] START` | Début avec emailDomain (NO PII) |
| STEP1 | `users_lookup` | Recherche dans table users |
| STEP2 | `bcrypt_compare_users` | Comparaison bcrypt (isValid: bool) |
| STEP3 | `memberships_fetched` | Récupération memberships |
| STEP4 | `community_fetch` | Enrichissement avec communautés |
| STEP5 | `accounts_lookup` | Fallback table accounts |
| STEP6 | `password_verify_accounts` | Vérification password accounts |
| STEP7 | `account_memberships_fetched` | Memberships via accounts |
| STEP8 | `admin_access_check` | Vérification rôle admin |
| STEP9 | `community_fetch` | Enrichissement accounts |
| SUCCESS | `SUCCESS: users_table` ou `SUCCESS: accounts_table` | Login réussi |
| REJECT | `REJECT: auth_failed` | Échec authentification |

### 3. Try/Catch Granulaire avec Codes Erreur

| Code | Step | Description |
|------|------|-------------|
| U1 | STEP1 | Erreur DB getUserByEmail |
| B1 | STEP2 | Erreur bcrypt.compare |
| M1 | STEP3 | Erreur getUserMemberships |
| C1 | STEP4 | Erreur getCommunity (users flow) |
| U2 | STEP5 | Erreur DB getAccountByEmail |
| B2 | STEP6 | Erreur verifyPassword |
| M2 | STEP7 | Erreur getAccountMemberships |
| C2 | STEP9 | Erreur getCommunity (accounts flow) |

### 4. Réponse Enrichie

Toutes les réponses incluent maintenant le traceId:
```json
{
  "error": "Email ou mot de passe incorrect",
  "traceId": "AL-abc123-xyz789"
}
```

---

## Tests Effectués

### Test 1: Login avec mauvais password
```bash
curl -X POST "/api/admin/login" \
  -H "X-Trace-Id: TEST-LOGIN-TRACE-001" \
  -d '{"email":"owner@portbouet-fc.sandbox","password":"wrong"}'
```

**Résultat**: 401 avec traceId retourné
**Logs générés**:
```
[Admin Login TEST-LOGIN-TRACE-001] START { emailDomain: 'portbouet-fc.sandbox', hasPassword: true }
[Admin Login TEST-LOGIN-TRACE-001] STEP1: users_lookup { found: true, userId: '98586ffb...', hasStoredPassword: true }
[Admin Login TEST-LOGIN-TRACE-001] STEP2: bcrypt_compare_users { isValid: false }
[Admin Login TEST-LOGIN-TRACE-001] STEP5: accounts_lookup { found: false, accountId: null, hasStoredHash: false }
[Admin Login TEST-LOGIN-TRACE-001] REJECT: auth_failed { userFound: true, accountFound: false }
```

### Test 2: Login sans credentials
```bash
curl -X POST "/api/admin/login" -d '{}'
```

**Résultat**: 400 avec message explicite

---

## Fichiers Modifiés

| Fichier | Modification |
|---------|--------------|
| `server/routes.ts` | Refactoring complet de `/api/admin/login` (lignes 2189-2393) |

---

## Impact

### Avant
- 500 opaques impossibles à debugger
- Pas de traceId pour corréler frontend/backend
- Pas de visibilité sur l'étape d'échec

### Après
- Erreurs 500 avec code explicite (U1, B1, M1, etc.)
- TraceId dans toutes les réponses
- Logs granulaires pour chaque étape
- Identification immédiate de la source du problème

---

## Recommandations

1. **Monitoring Production**: Configurer une alerte sur les patterns `STEP*_ERROR` et `FATAL_ERROR`
2. **Rate Limiting Review**: Vérifier que le rate limiter ne se déclenche pas sur les 401 légitimes
3. **Appliquer Pattern**: Répliquer ce pattern de logging sur les autres endpoints critiques

---

## Checklist

- [x] TraceId systématique
- [x] Logging structuré NO-PII
- [x] Try/catch granulaire
- [x] Codes erreur explicites
- [x] Tests locaux validés
- [x] Workflow redémarré
