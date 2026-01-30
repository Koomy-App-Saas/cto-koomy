# 04 — Bug & Incident Management Process (RCA‑First)

## 🎯 Objectif du document

Ce document définit **le processus obligatoire de gestion des bugs et incidents chez KOOMY**.

Il impose une règle non négociable :

> **Aucune correction sans RCA complète.**

Ce processus s’applique à **tous les environnements** (sandbox, staging, prod) et à **tous les niveaux de gravité**.

---

## 🧠 Principe fondamental

Un bug est **un symptôme**, jamais un problème.

Corriger un symptôme sans comprendre la cause racine :
- crée de la dette
- détruit la confiance
- rend le système imprévisible

Chez KOOMY, **le temps investi dans l’analyse est toujours inférieur au coût d’une mauvaise correction**.

---

## 🧱 Sources de vérité obligatoires

Avant toute hypothèse, **les sources suivantes doivent être listées et vérifiées** (selon le bug) :

### 🔹 Code & Historique
- Code actuel (Replit / GitHub)
- Historique des commits liés
- Rapports et audits Replit existants

### 🔹 Backend
- Logs applicatifs
- Logs API (requêtes / réponses)
- Logs d’erreur et de timeout

### 🔹 Frontend
- Logs console
- Réseau (Network tab)
- Comportement utilisateur réel

### 🔹 Données
- Base de données (Neon / Postgres)
- Schémas et contraintes
- Données réelles concernées

### 🔹 Infrastructure
- Cloudflare Pages
- Cloudflare R2 (buckets, namespaces)
- CDN (résolution d’URL, cache)
- Railway (services, variables, régions)

👉 **Aucune RCA n’est valide si une source pertinente n’a pas été explicitement écartée.**

---

## 🧭 Étapes obligatoires du processus RCA

### 1️⃣ Qualification du bug

- Où est observé le bug ? (URL, environnement)
- Qui est impacté ? (user, client, admin)
- Le bug est‑il reproductible ?
- Date et contexte d’apparition

👉 Livrable : **Bug Statement clair et factuel**

---

### 2️⃣ Collecte des preuves

- Logs complets
- Screenshots / vidéos si besoin
- Requêtes exactes (API, SQL)
- Valeurs réelles (IDs, paths, env)

👉 Aucun résumé. **Les preuves brutes priment.**

---

### 3️⃣ Analyse causale (RCA)

- Identifier la **cause racine unique**
- Exclure explicitement les fausses pistes
- Vérifier si le bug est :
  - logique
  - contractuel
  - infra
  - data
  - process

👉 Une RCA doit répondre à : **pourquoi ce bug existe**, pas comment il se manifeste.

---

### 4️⃣ Cartographie d’impact

- Composants impactés
- Données à risque
- Effets secondaires possibles
- Risque de régression

👉 Sans cette étape, **aucune correction n’est autorisée**.

---

### 5️⃣ Options de correction

Toujours proposer :

- **Option A — Correctif minimal** (low risk)
- **Option B — Correction propre** (tech debt réduite)
- **Option C — Refonte ciblée** (scalable)

Avec pour chaque option :
- Avantages
- Inconvénients
- Risques

---

### 6️⃣ Décision & GO

- La décision doit être **explicite**
- Si le fondateur est fatigué → report automatique
- Aucune décision implicite

---

### 7️⃣ Implémentation contrôlée

- Changements minimaux
- Aucun scope creep
- Logs renforcés si nécessaire

---

### 8️⃣ Vérification post‑fix

- Test du scénario initial
- Test des cas limites
- Vérification des logs

👉 Un bug n’est **résolu** que lorsqu’il est **vérifié**, pas quand le code compile.

---

### 9️⃣ Documentation obligatoire

Chaque bug corrigé génère au minimum :

- 1 document RCA (.md)
- 1 note de prévention
- 1 référence croisée dans le journal

---

## 🚨 Interdictions formelles

Il est interdit de :

- Corriger "pour voir"
- Deviner une cause
- Se baser sur une intuition
- Masquer un bug par un fallback silencieux
- Déployer sans validation

---

## 🧯 Cas d’urgence réelle (exception)

En cas de **panne bloquante en production** :

- Patch temporaire autorisé
- RCA complète **obligatoire a posteriori**
- Rollback prêt avant déploiement

---

## ✅ Statut

Ce document est :
- 📁 Archivé à la racine du repo
- 🔒 Opposable à ChatGPT
- 🧠 Référence unique pour tout bug KOOMY

---

> **Chez KOOMY, un bug bien compris est déjà à moitié résolu.**

