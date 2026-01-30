# Audit de Sécurité - Koomy Platform
## Projet hébergé sur Replit

**Date de l'audit :** 17 décembre 2024 (mis à jour le 9 janvier 2026)  
**Version :** 1.1  
**Environnement :** Replit (Production + Développement)  
**Auditeur :** Ingénieur Sécurité Senior (AppSec + Cloud + DevOps)

---

## Résumé Exécutif

Cette évaluation de sécurité couvre l'application Koomy, une plateforme SaaS multi-tenant de gestion de communautés hébergée sur Replit. L'analyse révèle une architecture globalement bien conçue avec plusieurs bonnes pratiques en place, mais identifie également des axes d'amélioration critiques avant une mise à l'échelle.

### Points Forts
- ✅ Hashage des mots de passe avec bcrypt (salt rounds 10-12)
- ✅ Validation des entrées via Zod schemas
- ✅ Utilisation de Drizzle ORM (protection contre injection SQL)
- ✅ Vérification des signatures webhooks Stripe
- ✅ Exclusion des données sensibles (passwordHash) des réponses API
- ✅ Séparation des rôles utilisateurs (accounts/users/admins)
- ✅ Gestion des secrets via Replit Secrets Manager

### Points d'Attention Critiques
- ✅ Rate limiting implémenté sur endpoints d'authentification (express-rate-limit)
- ✅ Helmet ajouté pour les headers de sécurité
- ⚠️ Pas de protection CSRF explicite
- ⚠️ Vulnérabilités modérées dans les dépendances (npm audit)
- ✅ Sessions avec expiration côté serveur pour Platform Admin (2h)

### Niveau de Risque Global : **BAS-MOYEN** (amélioré depuis v1.0)

---

## 1. Vue d'ensemble de l'Architecture

### 1.1 Flux Global

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Client Web    │────▶│   Express.js    │────▶│  PostgreSQL     │
│   (React/Vite)  │     │   Backend API   │     │  (Neon DB)      │
└─────────────────┘     └─────────────────┘     └─────────────────┘
         │                       │
         │                       ├──▶ Stripe API (Paiements)
         │                       ├──▶ SendGrid (Emails)
         │                       ├──▶ OpenAI API (IA)
         │                       └──▶ Object Storage (Fichiers)
         │
┌─────────────────┐
│  Mobile Apps    │
│ (Capacitor)     │
└─────────────────┘
```

### 1.2 Stack Technique

| Composant | Technologie | Version |
|-----------|-------------|---------|
| Backend | Node.js + Express.js + TypeScript | Express 4.21.2 |
| Frontend | React 19 + Vite 7 | React 19.2.0 |
| Base de données | PostgreSQL (Neon Serverless) | Drizzle ORM 0.39.1 |
| Authentification | bcryptjs + sessions | bcryptjs 3.0.3 |
| Validation | Zod | Zod 3.25.76 |
| Paiements | Stripe | Stripe 18.5.0 |
| Mobile | Capacitor | 8.0.0 |

### 1.3 Séparation des Environnements

| Environnement | Description | Isolation |
|---------------|-------------|-----------|
| Development | Repl en développement | Même instance Replit |
| Production | Deployment Replit | Instance séparée |

**Observation :** La séparation dev/prod est gérée via les déploiements Replit. Les variables d'environnement sont partagées (mode "shared") entre les deux environnements.

---

## 2. Sécurité de l'Environnement Replit

### 2.1 Gestion des Secrets

**Secrets détectés :**
- `DATABASE_URL` - Chaîne de connexion PostgreSQL
- `STRIPE_WEBHOOK_SECRET` - Validation webhooks Stripe
- `SESSION_SECRET` - Signature des sessions
- `AI_INTEGRATIONS_OPENAI_API_KEY` - Clé API OpenAI
- `PGDATABASE`, `PGHOST`, `PGPORT`, `PGUSER`, `PGPASSWORD` - Credentials DB

**Bonnes pratiques observées :**
- ✅ Secrets stockés dans Replit Secrets Manager (pas en dur dans le code)
- ✅ Aucune clé API visible dans le code source
- ✅ Variables sensibles accédées via `process.env`

**Risques identifiés :**
- ⚠️ Les secrets sont en mode "shared" (identiques dev/prod)
- ⚠️ Pas de rotation automatique des secrets
- ⚠️ Les collaborateurs du Repl ont accès à tous les secrets

**Recommandations :**
1. Séparer les secrets dev/prod (environnements distincts)
2. Implémenter une politique de rotation des clés API
3. Limiter l'accès aux secrets aux collaborateurs nécessaires

### 2.2 Isolation des Repls (Sandboxing)

Replit utilise des conteneurs isolés avec les caractéristiques suivantes :
- Système de fichiers isolé par Repl
- Réseau isolé avec NAT
- Ressources CPU/RAM limitées par plan

**Limites du sandboxing Replit :**
- Pas d'isolation réseau niveau VPC
- Pas de whitelisting IP natif
- Logs accessibles aux collaborateurs

### 2.3 Risques Mode Public/Privé

| Mode | Risque | Statut actuel |
|------|--------|---------------|
| Code public | Exposition du code source | ⚠️ À vérifier |
| Secrets exposés | Fuite de credentials | ✅ Secrets protégés |
| Logs publics | Fuite d'informations | ⚠️ Logs accessibles |

---

## 3. Sécurité des Bases de Données

### 3.1 Configuration Neon PostgreSQL

| Aspect | Configuration | Évaluation |
|--------|---------------|------------|
| Hébergeur | Neon (serverless) | ✅ Conforme |
| Connexion | SSL via DATABASE_URL | ✅ Chiffré |
| IP Whitelisting | Non activé | ⚠️ Recommandé |
| Lecture/Écriture | Connexion unique | ⚠️ Pas de séparation |

### 3.2 Gestion des Credentials

```typescript
// server/db.ts - Connexion sécurisée
if (!process.env.DATABASE_URL) {
  throw new Error("DATABASE_URL must be set.");
}
export const pool = new Pool({ connectionString: process.env.DATABASE_URL });
```

**Observations :**
- ✅ Credentials stockés en secret, pas dans le code
- ✅ Connexion via pool avec WebSocket (Neon Serverless)
- ⚠️ Même connexion pour lecture et écriture

### 3.3 Protection contre Injection SQL

**Drizzle ORM** est utilisé systématiquement, ce qui paramétrise automatiquement les requêtes :

```typescript
// Exemple de requête sécurisée (server/storage.ts)
const result = await db.select().from(users).where(eq(users.email, email));
```

**Évaluation : ✅ Protection efficace contre l'injection SQL**

### 3.4 Sauvegardes et Récupération

| Aspect | Disponibilité |
|--------|---------------|
| Sauvegardes automatiques | ✅ Neon gère les backups |
| Point-in-time recovery | ✅ Disponible (plan Neon) |
| Réplication | ✅ Read replicas disponibles |

---

## 4. Sécurité des API

### 4.1 Authentification

**Architecture d'authentification :**

| Type d'utilisateur | Méthode | Stockage session |
|-------------------|---------|------------------|
| Mobile (accounts) | Email/Password | Côté client |
| Admin (users) | Email/Password | Côté client |
| Platform Admin | Email/Password + globalRole | Côté client |

**Implémentation du hashage :**

```typescript
const SALT_ROUNDS = 12;

async function hashPassword(password: string): Promise<string> {
  return bcrypt.hash(password, SALT_ROUNDS);
}

async function verifyPassword(password: string, hash: string): Promise<boolean> {
  return bcrypt.compare(password, hash);
}
```

**Évaluation :**
- ✅ bcrypt avec salt rounds 10-12 (sécurisé)
- ✅ Vérification timing-safe via bcrypt.compare
- ⚠️ Pas de sessions côté serveur (stateless)
- ⚠️ Pas de JWT ou tokens avec expiration

### 4.2 Protection contre les Attaques

| Type d'attaque | Protection | Statut |
|----------------|------------|--------|
| Brute force | Rate limiting (express-rate-limit) | ✅ **Implémenté** |
| Injection SQL | Drizzle ORM (paramétré) | ✅ Protégé |
| XSS | sanitizeHtml() pour emails | ⚠️ Partiel |
| CSRF | Token CSRF | ❌ **Absent** |
| Replay attack | Nonce/timestamp | ❌ **Absent** |

### 4.3 Rate Limiting - **IMPLÉMENTÉ** ✅

**Rate limiting implémenté avec express-rate-limit (Jan 2026).**

Protection active sur :
- `/api/accounts/login` - 5 tentatives / 15 min
- `/api/admin/login` - 5 tentatives / 15 min
- `/api/platform/login` - 5 tentatives / 15 min + blocage IP hors France
- `/api/accounts/register` - 3 comptes / heure / IP

Configuration actuelle :

```javascript
const rateLimit = require('express-rate-limit');

const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // 5 tentatives
  message: { error: 'Trop de tentatives, réessayez dans 15 minutes' }
});

app.use('/api/*/login', loginLimiter);
```

### 4.4 Validation des Entrées

**Zod est utilisé pour la validation :**

```typescript
// Validation avec schema Zod
const validated = insertCommunitySchema.parse(req.body);

// Gestion des erreurs
if (error instanceof z.ZodError) {
  return res.status(400).json({ error: fromZodError(error).toString() });
}
```

**Évaluation :**
- ✅ Validation systématique des données structurées
- ✅ Messages d'erreur formatés (pas de stack traces)
- ⚠️ Certaines routes ont une validation manuelle basique

### 4.5 Headers de Sécurité - **IMPLÉMENTÉ** ✅

**Helmet ajouté pour les headers de sécurité (Jan 2026).**

Headers configurés :
- ✅ `X-Content-Type-Options: nosniff`
- ✅ `X-Frame-Options: DENY`
- ✅ `Strict-Transport-Security` (via Cloudflare)
- ✅ `X-XSS-Protection: 1; mode=block`
- ⚠️ `Content-Security-Policy` (basique)

---

## 5. Sécurité des Données Utilisateurs

### 5.1 Stockage des Mots de Passe

| Critère | Implémentation | Évaluation |
|---------|----------------|------------|
| Algorithme | bcrypt | ✅ Standard industrie |
| Salt rounds | 10-12 | ✅ Suffisant |
| Salt unique | Oui (bcrypt natif) | ✅ Sécurisé |

### 5.2 Protection des Données Sensibles

**Exclusion des mots de passe des réponses :**

```typescript
// Pattern utilisé systématiquement
const { passwordHash, ...accountWithoutPassword } = account;
return res.json({ account: accountWithoutPassword });
```

**Données personnelles stockées :**
- Emails (comptes et membres)
- Noms/Prénoms
- Numéros de téléphone
- Adresses
- Photos de profil

### 5.3 Intégration Stripe (Paiements)

**Sécurité des webhooks :**

```typescript
// server/stripe.ts - Vérification signature
const event = stripe.webhooks.constructEvent(
  payloadString, 
  signature, 
  webhookSecret
);
```

**Évaluation :**
- ✅ Signature webhook vérifiée
- ✅ Pas de stockage de données de carte
- ✅ Tokens Stripe non exposés côté client
- ✅ Stripe Connect pour paiements communautés

### 5.4 Conformité RGPD (Aspects Techniques)

| Exigence RGPD | Implémentation | Statut |
|---------------|----------------|--------|
| Minimisation des données | Champs nécessaires seulement | ✅ |
| Chiffrement au repos | Neon (chiffré) | ✅ |
| Chiffrement en transit | HTTPS/SSL | ✅ |
| Droit à l'oubli | Pas d'endpoint dédié | ⚠️ À implémenter |
| Export des données | Pas d'endpoint dédié | ⚠️ À implémenter |
| Logs d'accès | Partiels | ⚠️ À améliorer |

---

## 6. Sécurité du Code et des Dépendances

### 6.1 Audit npm

**Résultat de `npm audit` :**

| Sévérité | Nombre | Packages concernés |
|----------|--------|-------------------|
| Critique | 0 | - |
| Haute | 0 | - |
| Modérée | 4 | drizzle-kit, esbuild, @esbuild-kit/* |
| Basse | 1 | express-session |

**Vulnérabilités modérées détectées :**
1. **esbuild** (≤0.24.2) - GHSA-67mh-4wv8-2f99 : Requêtes cross-origin en dev
2. **drizzle-kit** - Dépendance transitive de esbuild

**Recommandation :** Mettre à jour drizzle-kit vers une version corrigée

### 6.2 Dépendances Sensibles

| Package | Usage | Risque |
|---------|-------|--------|
| bcryptjs | Hashage mots de passe | ✅ Bas (pure JS) |
| stripe | Paiements | ✅ Maintenu activement |
| express-session | Sessions | ⚠️ Vulnérabilité basse |
| openai | API IA | ✅ Maintenu activement |

### 6.3 Variables Sensibles dans le Code

**Recherche de patterns à risque :**
- ❌ Aucune clé API en dur détectée
- ❌ Aucun mot de passe en dur détecté
- ✅ Toutes les variables sensibles via `process.env`

### 6.4 Pipeline CI/CD

**Statut :** Pas de pipeline CI/CD dédié

Replit gère :
- Build automatique (Vite + esbuild)
- Déploiement via interface Replit

**Manquants :**
- Tests automatisés de sécurité
- SAST (Static Application Security Testing)
- DAST (Dynamic Application Security Testing)
- Scan de dépendances automatique

---

## 7. Risques Spécifiques à Replit

### 7.1 Limites de Replit en Production

| Aspect | Limite Replit | Impact |
|--------|---------------|--------|
| Uptime SLA | Pas de SLA garanti | ⚠️ Risque disponibilité |
| Scaling horizontal | Limité | ⚠️ Problèmes de charge |
| IP statique | Non disponible | ⚠️ Pas de whitelisting |
| VPC/Réseau privé | Non disponible | ⚠️ Isolation limitée |
| Logs persistants | 7 jours max | ⚠️ Audit limité |
| Compliance (SOC2, etc.) | Non certifié | ⚠️ Certains clients exclus |

### 7.2 Comparaison avec Cloud Classique

| Critère | Replit | AWS/GCP |
|---------|--------|---------|
| Facilité déploiement | ✅ Excellent | ⚠️ Complexe |
| Coût initial | ✅ Bas | ⚠️ Variable |
| Scaling | ⚠️ Limité | ✅ Illimité |
| Sécurité réseau | ⚠️ Basique | ✅ VPC, Security Groups |
| Compliance | ⚠️ Non certifié | ✅ SOC2, ISO27001, etc. |
| Support SLA | ⚠️ Non garanti | ✅ Garanti (selon plan) |

### 7.3 Cas d'Usage Appropriés

**Replit adapté pour :**
- ✅ Prototypage et MVP
- ✅ Applications internes
- ✅ Petites communautés (<1000 utilisateurs)
- ✅ Développement et tests

**Replit non adapté pour :**
- ❌ Applications critiques (finance, santé)
- ❌ Gros volumes (>10k utilisateurs simultanés)
- ❌ Exigences compliance strictes
- ❌ Données très sensibles (HIPAA, PCI-DSS niveau 1)

---

## 8. Recommandations

### 8.1 Actions Immédiates (Quick Wins)

| # | Action | Priorité | Effort | Statut |
|---|--------|----------|--------|--------|
| 1 | **Implémenter rate limiting** sur les endpoints login | 🔴 Critique | 1h | ✅ Fait |
| 2 | **Ajouter helmet** pour les headers de sécurité | 🔴 Critique | 30min | ✅ Fait |
| 3 | **Mettre à jour npm packages** (npm audit fix) | 🟠 Haute | 30min | En cours |
| 4 | **Séparer secrets dev/prod** | 🟠 Haute | 1h | En cours |

### 8.2 Actions à Moyen Terme

| # | Action | Priorité | Effort |
|---|--------|----------|--------|
| 5 | Implémenter protection CSRF | 🟠 Haute | 2h |
| 6 | Ajouter logs d'audit (connexions, actions sensibles) | 🟠 Haute | 4h |
| 7 | Implémenter sessions avec expiration côté serveur | 🟡 Moyenne | 4h |
| 8 | Ajouter endpoint export données (RGPD) | 🟡 Moyenne | 4h |
| 9 | Ajouter endpoint suppression compte (RGPD) | 🟡 Moyenne | 4h |
| 10 | Configurer CORS strictement | 🟡 Moyenne | 1h |

### 8.3 Actions Avant Montée en Charge

| # | Action | Priorité | Effort |
|---|--------|----------|--------|
| 11 | Évaluer migration vers cloud (AWS/GCP) si >5k users | 🟡 Moyenne | Variable |
| 12 | Implémenter monitoring de sécurité (alertes) | 🟡 Moyenne | 8h |
| 13 | Ajouter 2FA pour les admins | 🟡 Moyenne | 8h |
| 14 | Tests de pénétration professionnels | 🟡 Moyenne | Externe |
| 15 | Politique de rotation des clés API | 🟢 Basse | 2h |

### 8.4 Checklist Sécurité Minimale

```
[x] Rate limiting sur authentification (Jan 2026)
[x] Headers de sécurité (helmet) (Jan 2026)
[ ] Mise à jour des dépendances vulnérables
[ ] Séparation secrets dev/prod
[ ] Protection CSRF
[x] Logs d'audit activés (Platform Admin)
[x] Sessions avec expiration (Platform Admin 2h)
[x] CORS configuré (Cloudflare)
[ ] Tests de sécurité automatisés
[ ] Documentation des procédures de sécurité
```

---

## Annexes

### A. Commandes d'Audit Utilisées

```bash
# Audit des dépendances
npm audit --json

# Recherche de secrets dans le code
grep -r "API_KEY\|SECRET\|PASSWORD" --include="*.ts" server/

# Vérification des variables d'environnement
env | grep -E "(SECRET|KEY|PASSWORD|TOKEN)"
```

### B. Références

- [OWASP Top 10 2021](https://owasp.org/Top10/)
- [Node.js Security Best Practices](https://nodejs.org/en/docs/guides/security/)
- [Stripe Security Best Practices](https://stripe.com/docs/security)
- [RGPD - Exigences Techniques](https://www.cnil.fr/)

### C. Glossaire

| Terme | Définition |
|-------|------------|
| bcrypt | Algorithme de hashage de mots de passe |
| CSRF | Cross-Site Request Forgery |
| Rate Limiting | Limitation du nombre de requêtes par IP/utilisateur |
| Drizzle ORM | Object-Relational Mapping pour TypeScript |
| Neon | Base de données PostgreSQL serverless |

---

**Document généré le :** 17 décembre 2024  
**Dernière mise à jour :** 9 janvier 2026  
**Prochaine revue recommandée :** Juillet 2026  
**Contact sécurité :** security@koomy.app
