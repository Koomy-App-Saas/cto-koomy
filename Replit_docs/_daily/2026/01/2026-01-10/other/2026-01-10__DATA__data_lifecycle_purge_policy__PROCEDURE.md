# 🧹 KOOMY — Data Lifecycle & Purge Policy

## 1. Objectif du document

Ce document définit **le cycle de vie des données chez Koomy**, de leur création à leur suppression.

Objectifs principaux :
- Garantir une **séparation stricte PROD / SANDBOX**
- Prévenir toute **pollution de données**
- Encadrer les **resets sandbox**, démos et tests
- Assurer une **conformité RGPD pragmatique**
- Fournir des règles claires pour les équipes futures

> ⚠️ Toute donnée qui n’a plus de raison métier d’exister doit être supprimée.

---

## 2. Typologie des données

### 2.1 Données critiques (PROD)

- Utilisateurs réels
- Comptes clients
- Adhésions actives
- Paiements, factures, historiques
- Logs légaux / contractuels

➡️ **Jamais supprimées sans procédure légale ou décision CTO.**

---

### 2.2 Données fonctionnelles

- Contenus éditoriaux
- Événements
- Paramétrages de clubs
- Templates, médias

➡️ Peuvent être modifiées ou supprimées selon besoin produit.

---

### 2.3 Données temporaires / techniques

- Comptes de test
- Clubs sandbox
- Tokens temporaires
- Données de debug

➡️ **Éligibles à purge automatique.**

---

## 3. Règles par environnement

### 3.1 Production

- Aucune suppression massive autorisée
- Suppression ciblée uniquement (RGPD, résiliation)
- Toute purge doit être :
  - tracée
  - justifiée
  - validée

---

### 3.2 Sandbox

La sandbox est **jetable par nature**.

Règles :
- ❌ Aucune donnée PROD ne doit exister
- ✅ Toutes les données peuvent être supprimées
- ✅ Resets complets autorisés

Cas d’usage :
- Tests réalistes
- Démos client
- Validation de features
- Tests Stripe / Webhooks

---

### 3.3 Local

- Données 100 % éphémères
- Suppression libre
- Aucun backup requis

---

## 4. Politique de purge SANDBOX

### 4.1 Quand purger ?

- Avant une démo importante
- Après un cycle de tests
- Avant une nouvelle feature majeure
- Si incohérence détectée

---

### 4.2 Ce qui doit être purgé

- Utilisateurs
- Clubs
- Adhésions
- Paiements test
- Invitations
- Historique d’événements

---

### 4.3 Méthodes autorisées

- Script SQL manuel
- Script automatisé sécurisé
- Reset complet de la DB sandbox

🚫 Interdiction absolue d’utiliser ces scripts sur PROD.

---

## 5. Gestion des données de démonstration

### 5.1 Données démo officielles

- Clubs sandbox identifiés
- Comptes démo nommés explicitement
- Préfixes recommandés :
  - `demo_`
  - `sandbox_`

Exemple :
- `sandbox-portbouet-fc`

---

### 5.2 Interdictions

- Réutiliser des données PROD
- Copier des emails réels
- Utiliser de vrais moyens de paiement

---

## 6. RGPD — suppression utilisateur (PROD)

### 6.1 Cas légitimes

- Demande explicite utilisateur
- Fin de relation contractuelle

---

### 6.2 Principe

- Suppression logique ou anonymisation
- Conservation minimale légale si nécessaire

Exemples :
- Email anonymisé
- Nom remplacé
- Historique conservé sans identité

---

## 7. Logs & traçabilité

Toute purge doit :
- être documentée
- indiquer : qui / quand / pourquoi
- être reproductible

---

## 8. Interdictions absolues

- ❌ Purger la PROD pour corriger un bug
- ❌ Tester une feature destructrice en PROD
- ❌ Importer des données PROD en SANDBOX

---

## 9. Responsabilités

| Rôle | Responsabilité |
|----|---------------|
| Fondateur / CTO | Décision finale |
| Replit | Implémentation conforme |
| Équipe future | Respect strict |

---

## 10. Principe fondateur

> **Les données sont une responsabilité.
> Leur suppression fait partie du produit.**

Tout ce qui n’est pas explicitement conservé doit être considéré comme **éligible à suppression**.

