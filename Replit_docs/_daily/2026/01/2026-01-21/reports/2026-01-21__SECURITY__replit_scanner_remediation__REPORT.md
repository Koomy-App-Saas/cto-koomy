# KOOMY — SECURITY
## Rapport Remédiation Scanner Replit (Semgrep + HoundDog)

**Date :** 2026-01-21  
**Domain :** SECURITY  
**Doc Type :** REPORT  
**Scope :** Repo Replit (sandbox/staging)

---

## Résumé Exécutif

Cette remédiation adresse les findings de sécurité détectés par le scanner Replit (Semgrep + HoundDog). Les actions prioritaires ont été exécutées :

- **Page de test temporaire supprimée** : `/__auth_test` et `AuthTest.tsx` retirés
- **Logs sensibles nettoyés** : Aucune exposition d'email, password ou token dans les logs runtime (exception: seed.ts script dev)
- **SQL Injection** : Faux positifs confirmés (Drizzle ORM avec requêtes paramétrées)
- **Command Injection** : Usage contrôlé dans outils de build internes
- **XSS** : Sanitizer HTML existant et fonctionnel
- **Dépendances** : 4 vulnérabilités patchées, 6 restantes nécessitent breaking changes

---

## A) Suppression /__auth_test ✅

| Fichier | Action |
|---------|--------|
| `client/src/pages/debug/AuthTest.tsx` | SUPPRIMÉ |
| `client/src/App.tsx` | Import et route supprimés |

**Vérification :** Route `/__auth_test` retourne page 404 (non routée)

---

## B) Privacy — Logs Sensibles ✅

### Fichiers Modifiés

| Fichier | Ligne(s) | Avant | Après | Statut |
|---------|----------|-------|-------|--------|
| `server/routes.ts` | 1653-1658 | Email + password en clair | IDs uniquement | FIXED |
| `server/routes.ts` | 1667 | Email exposé | "Account not found" | FIXED |
| `server/routes.ts` | 1671-1672 | Email + hash info | Account ID only | FIXED |
| `server/routes.ts` | 1687 | Token partiel | Memberships count | FIXED |
| `server/routes.ts` | 2202 | Deux emails comparés | Membership ID | FIXED |
| `server/routes.ts` | 2250-2251 | Email + token | Account ID | FIXED |
| `server/routes.ts` | 2278-2281 | EmailDomain exposé | hasCredentials bool | FIXED |
| `server/routes.ts` | 1620 | Email dans log | TraceId only | FIXED |
| `server/routes.ts` | 4102 | Email dans log | TraceId only | FIXED |
| `server/routes.ts` | 4262 | Email dans log | MembershipId + TraceId | FIXED |
| `server/routes.ts` | 10132 | Email dans log | RequestId only | FIXED |
| `server/routes.ts` | 10340, 10378 | Email dans log | RequestId only | FIXED |
| `server/services/saasEmailService.ts` | Multiple | owner.email | communityId only | FIXED |

---

## C) Security — SQL Injection ✅

| Fichier | Ligne | Pattern | Statut | Justification |
|---------|-------|---------|--------|---------------|
| `server/storage.ts` | 737 | `sql\`UPPER...\`` | FALSE_POSITIVE | Drizzle ORM paramétré, normalizedInput échappé |
| `server/storage.ts` | 1099-1101 | `sql\`LOWER...\`` | FALSE_POSITIVE | Drizzle ORM paramétré, searchTerm échappé |
| `server/storage.ts` | 1117, 1128 | `sql\`...IN...\`` | FALSE_POSITIVE | Drizzle sql.join avec paramètres |
| `server/storage.ts` | 2687-2688 | `sql\`COALESCE...\`` | FALSE_POSITIVE | Variable interne (amountCents) |
| `server/storage.ts` | 2880-2910 | Tag filters | FALSE_POSITIVE | TagIds viennent du modèle, pas de l'utilisateur |
| `server/storage.ts` | 3143-3617 | Various | FALSE_POSITIVE | Variables internes (dates, lockName) |

**Conclusion :** Drizzle ORM utilise des requêtes paramétrées. Toutes les interpolations `${}` sont sécurisées.

---

## D) Security — Command Injection ✅

| Fichier | Usage | Statut | Justification |
|---------|-------|--------|---------------|
| `packages/mobile-build/index.mjs` | `execSync` avec tenantId | CONTROLLED | TenantId vient d'une liste de répertoires statiques, pas d'input utilisateur. Outil de build interne non exposé. |
| `scripts/build-*.mjs` | `execSync` | CONTROLLED | Scripts de build internes, paramètres hardcodés |

**Risque résiduel :** Faible. Usage interne uniquement.

---

## E) Security — XSS (innerHTML) ✅

| Fichier | Ligne | Pattern | Statut | Justification |
|---------|-------|---------|--------|---------------|
| `client/src/components/RichTextEditor.tsx` | 17, 87, 94 | `innerHTML` | SAFE | Fonction `sanitizeHtml()` implémentée : whitelist de tags (`p`, `br`, `b`, etc.), validation d'attributs, blocage `javascript:` et `data:` dans href |

**Conclusion :** Sanitizer HTML présent et fonctionnel. Pattern accepté.

---

## F) Dépendances Vulnérables

### Patchées (npm audit fix)

| Package | Severity | Status |
|---------|----------|--------|
| preact | High (10.28.0-10.28.1) | FIXED |
| qs | High (<6.14.1) | FIXED |
| body-parser | High (via qs) | FIXED |
| express | High (via qs) | FIXED |

### Non patchées (breaking changes requis)

| Package | Severity | Reason |
|---------|----------|--------|
| esbuild | Moderate | Via drizzle-kit, breaking change |
| @esbuild-kit/* | Moderate | Via drizzle-kit, breaking change |
| drizzle-kit | Moderate | Upgrade to 0.18.1 is breaking |
| tar | High | Via @capacitor/cli, breaking change |
| @capacitor/cli | High | Downgrade to 2.5.0 is breaking |

**Recommandation :** Planifier upgrade drizzle-kit et @capacitor/cli dans sprint dédié avec tests de régression.

---

## G) Tests Effectués ✅

| Test | Résultat |
|------|----------|
| `npm run build` | OK (warnings bénins) |
| `npm run dev` | OK (workflow running) |
| Route protégée 401 | OK (`PUT /api/communities/:id` → `{"error":"auth_required"}`) |
| Route `/__auth_test` inaccessible | OK (retourne page SPA 404) |

---

## Risques Restants

1. **Dépendances vulnérables (6)** : Nécessitent breaking changes, planifier upgrade séparé
2. **esbuild dev server** : Risque modéré, affecte uniquement l'environnement de développement
3. **server/seed.ts** : Logs d'emails dans script de seed (dev only, non exécuté en prod)

---

## Fichiers Modifiés

```
SUPPRIMÉ: client/src/pages/debug/AuthTest.tsx
MODIFIÉ: client/src/App.tsx
MODIFIÉ: server/routes.ts
MODIFIÉ: server/services/saasEmailService.ts
MODIFIÉ: package-lock.json (npm audit fix)
```

---

## Validation

- [x] /__auth_test supprimé et inaccessible
- [x] Zéro logs sensibles (email/password/token)
- [x] SQL injection findings documentés (faux positifs)
- [x] Command injection audité (usage contrôlé)
- [x] XSS audité (sanitizer présent)
- [x] Dépendances patchées (4/10)
- [x] Build + Dev + Routes protégées testés

**Exceptions documentées :**
- `server/seed.ts` : Logs d'emails dans script de développement uniquement (non exécuté en prod)
- Dépendances vulnérables (6) : Nécessitent breaking changes, planifier upgrade séparé

**Statut final :** REMÉDIATION COMPLÈTE pour le runtime production
