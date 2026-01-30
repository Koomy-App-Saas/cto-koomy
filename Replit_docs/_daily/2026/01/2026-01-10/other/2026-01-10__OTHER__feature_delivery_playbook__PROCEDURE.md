# 📘 KOOMY — Feature Delivery Playbook
**Procédure standard d’implémentation de fonctionnalités**  
Version: 1.0  
Statut: Référence officielle interne  
Auteur: Founder / CTO Koomy  

---

## 🎯 Objectifs du document

Ce document définit le **processus obligatoire** de conception, implémentation, test et déploiement des fonctionnalités Koomy.

Il vise à :
- Protéger la production et les clients existants
- Éviter les régressions et les déploiements prématurés
- Structurer la collaboration avec Replit, prestataires et futurs développeurs
- Instaurer une discipline produit et technique durable
- Lutter contre les décisions impulsives, même en contexte d’urgence

---

## 0️⃣ Principe fondamental (NON NÉGOCIABLE)

> **Aucune fonctionnalité ne touche la production sans validation complète en sandbox.**

Conséquences :
- Aucune exception
- Aucun “petit correctif rapide”
- Aucun contournement temporaire
- La sandbox est un passage obligatoire

---

## 1️⃣ Cadrage fonctionnel & produit
**Responsable : Founder / CTO**

### 1.1 Expression du besoin

Toute fonctionnalité commence par un cadrage écrit, même succinct.

Le cadrage doit répondre à :
- Pourquoi cette fonctionnalité est nécessaire
- Quel problème réel elle résout
- Pour quel type d’utilisateur (SaaS owner, admin club, membre, utilisateur public)
- S’agit-il d’un correctif, d’une évolution ou d’une nouvelle brique

📄 Format recommandé :
- Markdown / Notion / Google Doc
- 1 page maximum
- Aucun choix technique à ce stade

---

### 1.2 Décision GO / NO-GO

Avant toute action technique :
- L’impact business est compris
- L’impact sécurité est identifié
- L’impact données (DB, Stripe, utilisateurs) est anticipé

👉 En cas de doute : **NO-GO temporaire** jusqu’à clarification.

---

## 2️⃣ Audit technique préalable
**Responsable : Replit / Dev lead**

Aucune implémentation ne commence sans audit écrit.

### 2.1 Contenu obligatoire de l’audit

L’audit doit préciser :
- Fichiers frontend impactés
- Fichiers backend impactés
- Tables de base de données concernées
- Endpoints API concernés
- Risques identifiés (authentification, multi-tenant, production)
- Dépendances implicites ou effets de bord possibles

📌 **Sans audit écrit → aucune implémentation autorisée.**

---

### 2.2 Validation de l’audit

Le Founder / CTO :
- Relit l’audit
- Challenge les angles morts
- Demande clarification si nécessaire

Tant que l’audit n’est pas clair et validé → **processus bloqué**.

---

## 3️⃣ Plan d’implémentation formel
**Responsable : Replit**

Replit doit fournir un **plan d’implémentation**, pas du code.

### 3.1 Contenu du plan

Le plan doit inclure :
- Étapes numérotées et ordonnées
- Séparation claire frontend / backend
- Variables d’environnement impactées
- Migrations DB (si applicable)
- Points de test attendus

📌 Ce plan fait office de **contrat d’implémentation**.

---

## 4️⃣ OK GO explicite
**Responsable : Founder / CTO**

Avant toute ligne de code, une validation explicite est requise :

> **“OK GO implémentation selon le plan validé.”**

Sans cette validation écrite → implémentation interdite.

---

## 5️⃣ Implémentation contrôlée
**Responsable : Replit**

Règles strictes :
- Implémentation conforme au plan validé
- Aucun ajout non demandé
- Aucun refactoring opportuniste
- Aucun contournement temporaire

Tout écart doit être signalé **avant** d’être implémenté.

---

## 6️⃣ Rapport d’implémentation
**Responsable : Replit**

À la fin de l’implémentation, un rapport est obligatoire :

- Liste des fichiers modifiés
- Fonctionnalités effectivement implémentées
- Éléments volontairement non implémentés
- Risques ou limitations restantes

📌 Sans rapport → la feature est considérée comme non livrée.

---

## 7️⃣ Tests en Preview Replit
**Responsable : Founder / CTO**

Tests manuels minimum :
- Cas nominal
- Cas d’erreur
- Cas edge (reload, session expirée, permissions)

En cas d’anomalie → retour à l’étape 5.

---

## 8️⃣ Déploiement en SANDBOX (étape clé)
**Responsable : CTO**

### 8.1 Environnement sandbox officiel

La sandbox Koomy est un **univers complet et isolé**, comprenant :

- Git branch : `staging`
- Base de données dédiée (Neon dev)
- Sous-domaines sandbox :
  - sitepublic-sandbox.koomy.app
  - sandbox.koomy.app
  - api-sandbox.koomy.app
  - backoffice-sandbox.koomy.app
  - lorpesikoomyadmin-sandbox.koomy.app

🎯 Objectif : tester comme en production, sans aucun risque client.

---

### 8.2 Tests en conditions réelles

Tests obligatoires :
- Création de clubs sandbox
- Création d’utilisateurs test
- Parcours complets
- Tests Stripe en mode test
- Tests desktop et mobile
- Tests QR code et cas terrain si applicable

📌 **Les bugs doivent être éliminés en sandbox, jamais en production.**

---

## 9️⃣ Validation finale production
**Responsable : Founder / CTO**

Checklist obligatoire :
- Sandbox stable
- Aucune dette “on corrigera plus tard”
- Logs propres
- Données cohérentes
- Aucun contournement actif

Sans validation complète → pas de production.

---

## 🔟 Merge & déploiement PROD
**Responsable : CTO**

- Merge `staging → main`
- Déploiement Railway PROD
- Surveillance renforcée post-déploiement

---

## 🧠 Règle d’or finale

> **La vitesse ne justifie jamais une perte de confiance.**  
> Une production cassée coûte toujours plus cher qu’un déploiement retardé.

---

## 📌 Statut du document

Ce document est :
- La référence officielle Koomy
- Applicable à toute feature, correctif ou refonte
- Transmissible tel quel aux équipes futures

Toute dérogation doit être **exceptionnelle, documentée et validée** par le Founder / CTO.
