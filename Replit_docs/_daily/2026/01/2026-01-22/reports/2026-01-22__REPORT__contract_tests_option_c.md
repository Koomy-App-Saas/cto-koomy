# KOOMY — Contract Tests Option C (Identity & Onboarding 2026-01)

**Date**: 2026-01-22  
**Version**: 1.0  
**Statut**: ✅ Livré

---

## 1. Résumé

Ce rapport documente la mise en place du **Test Harness contractuel** pour valider l'implémentation Option C du contrat Identité & Onboarding.

### Tests implémentés

| ID | Test | Statut |
|----|------|--------|
| T1 | STANDARD: Register self-service crée community + trial | ⏭️ SKIP* |
| T2 | WL: Firebase strictement interdit | ⏭️ SKIP* |
| T3 | SaaS Owner: Firebase interdit | ⏭️ SKIP* |
| T4 | ENUM: aucune trace de "pending" | ✅ PASS |
| T5 | Identity resolution via `user_identities` | ✅ PASS |
| T6 | Anti-orphans | ✅ PASS |

*SKIP = Firebase credentials non configurés

---

## 2. Prérequis

### 2.1 Environnement
- Node.js 20+
- Base de données PostgreSQL accessible
- Serveur API en cours d'exécution (port 5000)

### 2.2 Variables d'environnement (optionnelles pour tests complets)

```bash
# API Configuration
CONTRACT_TEST_API_BASE_URL=http://localhost:5000
CONTRACT_TEST_PUBLIC_HOST=sitepublic-sandbox.koomy.app
CONTRACT_TEST_WL_HOST=wl-sandbox.koomy.app
CONTRACT_TEST_OWNER_HOST=saasowner-sandbox.koomy.app

# Test Data Generation
CONTRACT_TEST_EMAIL_PREFIX=ct_
CONTRACT_TEST_SEED_SECRET=test_seed_2026

# Firebase Test User (requis pour T1, T2, T3)
CONTRACT_TEST_FIREBASE_TEST_USER_EMAIL=test@example.com
CONTRACT_TEST_FIREBASE_TEST_USER_PASSWORD=your_test_password
FIREBASE_API_KEY=your_firebase_api_key
```

Voir `scripts/contract-tests/.env.example` pour le template complet.

---

## 3. Commandes d'exécution

### Exécution des tests contractuels
```bash
npx tsx scripts/contract-tests/runner.ts
```

### Exécution avec variables d'environnement
```bash
CONTRACT_TEST_API_BASE_URL=http://localhost:5000 npx tsx scripts/contract-tests/runner.ts
```

---

## 4. Output exemple

```
╔═══════════════════════════════════════════════════════════════╗
║       KOOMY — CONTRACT TESTS (Option C)                       ║
║       Contrat Identité & Onboarding (2026-01)                 ║
╚═══════════════════════════════════════════════════════════════╝


--- Running T1_STANDARD_REGISTER ---
⏭️ T1_STANDARD_REGISTER: SKIP (0ms)
   Firebase credentials not configured (CONTRACT_TEST_FIREBASE_* env vars)

--- Running T2_WL_FIREBASE_FORBIDDEN ---
⏭️ T2_WL_FIREBASE_FORBIDDEN: SKIP (1340ms)
   Firebase credentials not configured

--- Running T3_SAAS_OWNER_FIREBASE_FORBIDDEN ---
⏭️ T3_SAAS_OWNER_FIREBASE_FORBIDDEN: SKIP (0ms)
   Firebase credentials not configured

--- Running T4_ENUM_NO_PENDING ---
✅ T4_ENUM_NO_PENDING: PASS (173ms)
   Enum correctly rejects "pending" value

--- Running T5_IDENTITY_RESOLUTION ---
✅ T5_IDENTITY_RESOLUTION: PASS (637ms)
   Found 9 identities (0 Firebase, 9 Legacy)

--- Running T6_ANTI_ORPHANS ---
✅ T6_ANTI_ORPHANS: PASS (305ms)
   No orphan identities and no users with firebase_uid missing identity record

╔═══════════════════════════════════════════════════════════════╗
║                        SUMMARY                                ║
╚═══════════════════════════════════════════════════════════════╝

Total: 6 tests
✅ Passed: 3
❌ Failed: 0
⏭️ Skipped: 3

Success rate: 50.0%

⚠️ Some tests were skipped (configure Firebase env vars for full coverage)
```

---

## 5. Architecture des fichiers

```
scripts/contract-tests/
├── config.ts      # Configuration et types
├── helpers.ts     # Fonctions utilitaires (HTTP, Firebase, DB)
├── tests.ts       # Implémentation T1-T6
├── runner.ts      # Runner principal
└── .env.example   # Template des variables d'env
```

---

## 6. Détail des tests

### T1_STANDARD_REGISTER
- **Objectif**: Valider que l'inscription self-service crée une communauté STANDARD avec trial 14j
- **Prérequis**: Firebase credentials configurés
- **Vérifie**:
  - HTTP 200/201 avec `communityId`
  - `subscription_status = trialing`
  - `trial_ends_at` ≈ now + 14 jours (±5 min)

### T2_WL_FIREBASE_FORBIDDEN
- **Objectif**: Valider que Firebase est rejeté pour contexte White-Label
- **Prérequis**: Firebase credentials + host WL configurés
- **Vérifie**: HTTP 403 avec code `FORBIDDEN_CONTRACT` ou `FIREBASE_FORBIDDEN_FOR_WL`

### T3_SAAS_OWNER_FIREBASE_FORBIDDEN
- **Objectif**: Valider que Firebase est rejeté pour SaaS Owner Platform
- **Prérequis**: Firebase credentials + host owner configurés
- **Vérifie**: HTTP 403/401 rejet Firebase

### T4_ENUM_NO_PENDING
- **Objectif**: Confirmer qu'aucun statut "pending" n'existe
- **Prérequis**: Aucun (DB query)
- **Vérifie**: 0 rows avec `subscription_status = 'pending'`

### T5_IDENTITY_RESOLUTION
- **Objectif**: Valider intégrité table `user_identities`
- **Prérequis**: Aucun (DB query)
- **Vérifie**:
  - Table contient des données
  - Tous les providers sont valides (FIREBASE ou LEGACY_KOOMY)

### T6_ANTI_ORPHANS
- **Objectif**: Détecter orphelins DB
- **Prérequis**: Aucun (DB query)
- **Vérifie**:
  - Aucune identity avec `user_id` référençant user inexistant
  - Aucun user avec `firebase_uid` sans identity correspondante

---

## 7. Limitations

| Limitation | Impact | Solution |
|------------|--------|----------|
| Google Auth popup non testable | T1 ne peut tester Firebase Google provider | Utiliser email/password Firebase test user |
| Credentials Firebase requis | T1-T3 skippés sans config | Configurer un user Firebase test en sandbox |
| Host-based routing | T2-T3 dépendent du header Host | Simuler via `X-Forwarded-Host` |

---

## 8. Matrice PASS/FAIL attendue

| Scénario | T1 | T2 | T3 | T4 | T5 | T6 |
|----------|----|----|----|----|----|----|
| Sandbox complet (Firebase config) | PASS | PASS | PASS | PASS | PASS | PASS |
| Dev local (sans Firebase) | SKIP | SKIP | SKIP | PASS | PASS | PASS |
| WL uniquement | SKIP | PASS | SKIP | PASS | PASS | PASS |

---

## 9. Prochaines étapes

1. **Configurer Firebase test user** dans environnement sandbox pour valider T1-T3
2. **Ajouter CI/CD** pour exécution automatique des tests contractuels
3. **Étendre T1** pour vérifier création identity dans `user_identities`
4. **Ajouter T7** pour tester upgrade flow (si applicable)

---

## 10. Références

- Contrat: `docs/architecture/CONTRAT_IDENTITE_ONBOARDING_2026-01.md`
- Phase 1: `docs/reports/2026-01-22__REPORT__option_c_phase_1_tenant_auth_enforcement.md`
- Phase 2: `docs/reports/2026-01-22__REPORT__option_c_phase_2_user_identities.md`
