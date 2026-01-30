# 🚨 KOOMY — Incident & Rollback Protocol

## 1. Objectif du document

Ce document définit **la procédure officielle de gestion des incidents** chez **Koomy**.

Il vise à :
- Réagir vite **sans paniquer**
- Protéger les données et les paiements
- Décider clairement entre **rollback** et **hotfix**
- Éviter les décisions improvisées
- Assurer une traçabilité post-incident

> ⚠️ Un incident mal géré coûte plus cher qu’un bug.

---

## 2. Définition d’un incident

Un incident est toute situation qui :
- impacte des utilisateurs réels
- met en danger des données
- bloque un paiement
- dégrade fortement l’expérience
- expose une faille de sécurité

---

## 3. Niveaux d’incident

### 🟢 Niveau 1 — Mineur

- Bug UI
- Problème isolé sans perte de données
- Fonctionnalité secondaire indisponible

➡️ Action :
- Fix planifié
- Aucun rollback

---

### 🟠 Niveau 2 — Majeur

- Feature clé cassée
- Erreurs récurrentes
- Paiements partiellement impactés

➡️ Action :
- Analyse immédiate
- Rollback ou hotfix rapide

---

### 🔴 Niveau 3 — Critique

- Données corrompues
- Paiements en erreur
- Faille de sécurité
- API indisponible

➡️ Action :
- Rollback immédiat
- Mise en maintenance si nécessaire

---

## 4. Chaîne de décision

| Étape | Responsable |
|----|------------|
| Détection | Monitoring / retour user |
| Qualification | Fondateur / CTO |
| Décision | Fondateur / CTO |
| Exécution | Dev / Replit |
| Communication | Fondateur |

Une seule personne décide. Pas de débat en temps réel.

---

## 5. Rollback vs Hotfix

### 5.1 Rollback

À privilégier si :
- Bug introduit récemment
- Impact large
- Cause inconnue

Avantages :
- Rapide
- Prévisible
- Réversible

---

### 5.2 Hotfix

À privilégier si :
- Cause clairement identifiée
- Impact limité
- Rollback impossible ou risqué

⚠️ Tout hotfix doit être :
- minimal
- documenté
- suivi d’un correctif propre

---

## 6. Procédure de rollback standard

1. Identifier la dernière version stable
2. Revenir sur le commit / release stable
3. Redéployer PROD
4. Vérifier :
   - API
   - Auth
   - Paiements
5. Geler les nouveaux déploiements

---

## 7. Environnements et incidents

### PROD

- Tolérance zéro
- Priorité : stabilité

### SANDBOX

- Terrain d’analyse
- Reproduction du bug
- Validation du correctif

🚫 Ne jamais tester un correctif destructeur en PROD.

---

## 8. Paiements & Stripe

En cas d’incident paiement :
- Vérifier les webhooks
- Suspendre les opérations à risque
- Ne jamais rejouer un webhook à l’aveugle

Si doute → rollback.

---

## 9. Communication

### Interne

- Documenter l’incident
- Noter : cause, impact, durée

### Externe (si nécessaire)

- Message simple
- Pas de justification technique
- Engagement de correction

---

## 10. Post-mortem (obligatoire)

Après chaque incident majeur :
- Analyse de la cause racine
- Identification du point de rupture
- Mesure corrective
- Mise à jour des procédures

Sans post-mortem = incident non résolu.

---

## 11. Interdictions absolues

- ❌ Corriger directement en PROD sans décision
- ❌ Enchaîner les hotfixs sans analyse
- ❌ Blâmer une personne

---

## 12. Principe fondateur

> **En situation de crise, on protège le produit avant l’ego.**

La meilleure décision est souvent la plus simple :
**revenir à un état stable, puis comprendre.**

