# 🔐 KOOMY — Environnements & Secrets Policy

## 1. Objectif du document

Ce document définit **les règles strictes de gestion des environnements et des secrets** chez **Koomy**.

Objectifs :
- Garantir **l’isolation totale** entre PROD, SANDBOX et LOCAL
- Éviter toute **contamination de données**
- Sécuriser les accès (API, DB, Stripe, emails, CDN)
- Fournir un **cadre non négociable** pour les équipes actuelles et futures

> ⚠️ Toute violation de ces règles est considérée comme **critique**, même sans incident visible.

---

## 2. Environnements officiels Koomy

| Environnement | Rôle | Accès utilisateurs | Données réelles |
|--------------|------|-------------------|----------------|
| **PRODUCTION** | Exploitation réelle | Clients finaux | ✅ Oui |
| **SANDBOX** | Tests réalistes / démo | Internes / prospects | ❌ Non |
| **LOCAL** | Développement | Dev uniquement | ❌ Non |

Aucun autre environnement n’est autorisé sans validation CTO.

---

## 3. Convention des variables d’environnement

### Variables fondamentales

| Variable | Description | Obligatoire |
|--------|-------------|-------------|
| `NODE_ENV` | Environnement Node | ✅ |
| `KOOMY_ENV` | Environnement métier Koomy | ✅ |
| `DATABASE_URL` | URL PostgreSQL | ✅ |

### Valeurs autorisées

```txt
NODE_ENV=production | development
KOOMY_ENV=production | sandbox | local
```

❌ Toute autre valeur est interdite.

---

## 4. Règles absolues d’isolation

### 4.1 Base de données

| Environnement | Base autorisée |
|--------------|---------------|
| PROD | Neon branch `main` / `production` |
| SANDBOX | Neon branch `development` |
| LOCAL | DB locale ou Neon dédiée |

🚫 **Il est strictement interdit** :
- qu’un environnement SANDBOX pointe vers une DB PROD
- qu’un seed s’exécute sur une DB PROD

Des **garde-fous applicatifs bloquants** doivent empêcher le serveur de démarrer en cas d’incohérence.

---

## 5. Garde-fous obligatoires côté backend

### 5.1 Vérification au démarrage

Au démarrage du serveur :
- comparer `KOOMY_ENV` avec les patterns de `DATABASE_URL`
- **refuser de démarrer** en cas de mismatch

Exemples bloquants :
- `KOOMY_ENV=sandbox` + DB prod
- `KOOMY_ENV=production` + DB dev

---

## 6. Gestion des seeds

Les scripts de seed doivent :
- vérifier explicitement `KOOMY_ENV === sandbox`
- vérifier l’identité réelle de la DB (nom, host)
- **refuser toute exécution** si la DB ressemble à une prod

Aucun seed ne doit être exécutable sans garde-fou.

---

## 7. Secrets & credentials

### 7.1 Principe général

- ❌ Aucun secret en dur dans le code
- ❌ Aucun secret partagé entre environnements
- ✅ Un secret = un environnement

### 7.2 Secrets critiques

| Secret | PROD | SANDBOX |
|------|------|---------|
| Stripe API Key | live | test |
| Stripe Webhook Secret | prod | sandbox |
| SendGrid / Email | prod | sandbox |
| JWT / Session Secret | unique | unique |
| DEBUG / INTERNAL | ❌ interdit | ✅ autorisé |

---

## 8. Endpoints de debug (SANDBOX uniquement)

Les endpoints de debug :
- sont **interdits en PROD** (404 hard)
- nécessitent un **header secret**
- ne doivent jamais exposer `DATABASE_URL`

Exemple :
```txt
GET /api/_debug/db-identity
X-Debug-Secret: <secret>
```

---

## 9. Nommage des domaines

### 9.1 Production

- site public : `www.koomy.app`
- app : `koomy.app`
- api : `api.koomy.app`
- backoffice : `backoffice.koomy.app`
- saas owner : `lorpesikoomyadmin.koomy.app`

### 9.2 Sandbox

- site public : `sitepublic-sandbox.koomy.app`
- app : `sandbox.koomy.app`
- api : `api-sandbox.koomy.app`
- backoffice : `backoffice-sandbox.koomy.app`
- saas owner : `lorpesikoomyadmin-sandbox.koomy.app`

Aucun domaine SANDBOX ne doit pointer vers la prod.

---

## 10. Règle de publication

- **PROD** ne déploie que depuis `main`
- **SANDBOX** ne déploie que depuis `staging`
- Aucun push direct en prod

Le passage `staging → main` suit le **Feature Delivery Playbook**.

---

## 11. Responsabilités

| Rôle | Responsabilité |
|----|---------------|
| Fondateur / CTO | Validation finale |
| Replit | Implémentation conforme |
| Futurs devs | Respect strict |

---

## 12. Principe final

> **La sécurité n’est pas un ajout.
> C’est une condition d’existence du produit.**

Tout ce qui n’est pas explicitement autorisé dans ce document est **interdit par défaut**.

