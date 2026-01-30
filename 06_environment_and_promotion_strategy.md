# 06 — Environment & Promotion Strategy (KOOMY)

## 🎯 Objectif du document

Ce document définit **la stratégie officielle de gestion des environnements et de promotion du code chez KOOMY**.

Il fixe une règle simple et non négociable :

> **Aucun environnement ne doit être ambigu. Aucun flux ne doit être improvisé.**

Les environnements KOOMY sont conçus pour :
- protéger la production
- permettre l’expérimentation contrôlée
- garantir des promotions traçables et réversibles

---

## 🧱 Environnements officiels KOOMY

### 1️⃣ Preview Replit

**Rôle** : environnement de travail et d’exploration

- Généré automatiquement par Replit
- Non contractuel
- Non stable
- Non persistant

Utilisation autorisée :
- exploration du code
- compréhension
- tests unitaires locaux

Interdictions :
- aucune décision produit
- aucun test métier validant
- aucune promotion directe

---

### 2️⃣ Staging (ex-Sandbox)

> ⚠️ **Chez KOOMY, le repo `staging` est la SANDBOX.**

**Rôle** :
- source de vérité fonctionnelle
- environnement de validation
- référence avant toute mise en production

Caractéristiques :
- données cohérentes
- configuration complète
- Firebase, CDN, Stripe en mode TEST
- logs complets

Utilisation autorisée :
- tests fonctionnels complets
- tests utilisateur réels
- validation des parcours

Règle absolue :
> **Tout ce qui est en production doit avoir existé et fonctionné en staging.**

---

### 3️⃣ Production

**Rôle** :
- environnement client
- données réelles
- stabilité maximale

Caractéristiques :
- accès restreint
- branche protégée
- aucune expérimentation

Utilisation autorisée :
- exploitation
- support
- observation

Interdictions :
- debug à chaud
- patch sans rollback

---

## 🔁 Stratégie de promotion des environnements

### Flux officiel

```
Preview Replit → staging → production
```

Aucun autre flux n’est autorisé.

---

## 🧭 Règles de promotion du code

### 1️⃣ Pré-requis avant promotion staging → production

- ✅ Staging à jour
- ✅ Feature validée selon le document 05
- ✅ Aucun bug critique ouvert
- ✅ Logs propres
- ✅ Plan de rollback défini

Sans ces éléments → **promotion interdite**.

---

### 2️⃣ Méthode de promotion

- La promotion se fait **via GitHub**
- Jamais via Replit
- Jamais en local vers prod

Branches :
- `staging` → référence sandbox
- `main` → production

---

### 3️⃣ Protection des branches

- `main` :
  - protégée
  - aucune écriture directe
  - PR obligatoire

- `staging` :
  - accessible
  - contrôlée
  - historisée

---

## 🧯 Rollback & archivage

### Rollback

Tout déploiement doit :
- pouvoir être reverti
- avoir un commit clair
- être documenté

---

### Archivage

- Les anciens `main` sont archivés
- Jamais supprimés
- Référencés par date et version

---

## 🚫 Interdictions formelles

Il est interdit de :

- corriger un bug directement en production
- utiliser prod comme sandbox
- promouvoir sans validation
- bypasser GitHub

---

## ✅ Statut

Ce document est :
- 📁 Archivé à la racine du repo
- 🔒 Opposable à ChatGPT
- 🧭 Référence unique pour la gestion des environnements KOOMY

---

> **Chez KOOMY, la production est un sanctuaire, pas un laboratoire.**

