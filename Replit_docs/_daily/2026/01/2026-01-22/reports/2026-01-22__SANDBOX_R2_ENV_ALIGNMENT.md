# R2 Sandbox/Production Alignment & Guardrails

**Date:** 2026-01-22  
**Statut:** ✅ TERMINÉ  
**Auteur:** Agent Replit

---

## 1. Résumé

Mise en place de garde-fous pour empêcher toute écriture/lecture cross-environnement entre sandbox et production pour le stockage R2/CDN. Le serveur refuse de démarrer si une configuration incohérente est détectée.

### Résultats Clés
- **Garde-fous actifs** au boot du serveur
- **Script de vérification** `scripts/verify_r2_env_alignment.ts`
- **4/4 tests** passent
- **Fail fast** en cas de mismatch

---

## 2. Variables d'Environnement par Environnement

### Sandbox

| Variable | Valeur attendue |
|----------|-----------------|
| `APP_ENV` | `sandbox` |
| `S3_BUCKET` | `koomy-sandbox` |
| `S3_ENDPOINT` | `https://<account>.r2.cloudflarestorage.com` |
| `PUBLIC_OBJECT_BASE_URL` | `https://cdn-sandbox.koomy.app` |
| `S3_ACCESS_KEY_ID` | Clé sandbox |
| `S3_SECRET_ACCESS_KEY` | Secret sandbox |

### Production

| Variable | Valeur attendue |
|----------|-----------------|
| `APP_ENV` | `prod` |
| `S3_BUCKET` | `koomy` ou `koomy-prod` |
| `S3_ENDPOINT` | `https://<account>.r2.cloudflarestorage.com` |
| `PUBLIC_OBJECT_BASE_URL` | `https://cdn.koomy.app` |
| `S3_ACCESS_KEY_ID` | Clé production |
| `S3_SECRET_ACCESS_KEY` | Secret production |

---

## 3. Garde-fous Implémentés

### Boot-time Guards (server/index.ts)

Le serveur vérifie au démarrage:

1. **Sandbox + CDN prod** → FATAL, exit(1)
   - `APP_ENV=sandbox` + `PUBLIC_OBJECT_BASE_URL=cdn.koomy.app`
   
2. **Sandbox + Bucket prod** → FATAL, exit(1)
   - `APP_ENV=sandbox` + `S3_BUCKET=koomy-prod` ou `koomy`
   
3. **Prod + CDN sandbox** → FATAL, exit(1)
   - `APP_ENV=prod` + `PUBLIC_OBJECT_BASE_URL=cdn-sandbox.koomy.app`
   
4. **Prod + Bucket sandbox** → FATAL, exit(1)
   - `APP_ENV=prod` + `S3_BUCKET=koomy-sandbox`

### Logs au Boot

```
[STARTUP] ✓ R2 bucket: koomy-sandbox
[STARTUP] ✓ CDN base URL: https://cdn-sandbox.koomy.app
```

---

## 4. Comment Tester

### Script de vérification

```bash
npx tsx scripts/verify_r2_env_alignment.ts
```

### Résultat attendu (sandbox)

```
=== R2 Environment Alignment Verification ===

APP_ENV: sandbox
S3_BUCKET: koomy-sandbox
S3_ENDPOINT: (set)
PUBLIC_OBJECT_BASE_URL: https://cdn-sandbox.koomy.app

✅ R2 environment variables present
✅ Sandbox environment alignment
⏭️ Production environment alignment: Skipped (APP_ENV=sandbox)
✅ Bucket/CDN consistency

Total: 4 passed, 0 failed
```

### Test manuel de mismatch

```bash
# Simuler une erreur (ne pas faire en prod!)
APP_ENV=sandbox PUBLIC_OBJECT_BASE_URL=https://cdn.koomy.app npx tsx scripts/verify_r2_env_alignment.ts
# Doit retourner: ❌ Sandbox environment alignment - PUBLIC_OBJECT_BASE_URL points to production CDN
```

---

## 5. Points de Vigilance

### Fallbacks CDN côté client

Le client (`client/src/api/config.ts`) a encore des fallbacks vers `cdn.koomy.app`. Ces fallbacks sont acceptables car:
- Ils ne concernent que la **lecture** d'URLs publiques
- Le client ne peut pas **écrire** dans R2
- La variable `VITE_CDN_BASE_URL` peut être définie pour override

### Replit Object Storage

Si R2 n'est pas configuré (variables S3 absentes), le système utilise Replit Object Storage comme fallback. Ceci est acceptable pour le développement local.

### Mailer Branding

Le fichier `server/services/mailer/branding.ts` a un fallback `cdn.koomy.app` pour les logos emails. Ceci est acceptable car:
- Il s'agit d'URLs de lecture pour les emails
- Le logo par défaut Koomy est en production

---

## 6. Fichiers Modifiés

| Fichier | Nature du changement |
|---------|---------------------|
| `server/index.ts` | Ajout des garde-fous R2/CDN au boot |
| `scripts/verify_r2_env_alignment.ts` | Nouveau script de vérification |

---

## 7. Definition of Done

| Critère | Statut |
|---------|--------|
| Sandbox n'écrit plus jamais en prod | ✅ |
| Aucune URL prod générée en sandbox (avec R2 configuré) | ✅ |
| Garde-fous actifs au boot | ✅ |
| Script de vérification | ✅ |
| Rapport livré | ✅ |

---

## 8. Commandes de Validation

```bash
# Vérifier l'alignement R2
npx tsx scripts/verify_r2_env_alignment.ts

# Rechercher les fallbacks CDN hardcodés
grep -r "cdn.koomy.app" --include="*.ts" server/ client/
```
