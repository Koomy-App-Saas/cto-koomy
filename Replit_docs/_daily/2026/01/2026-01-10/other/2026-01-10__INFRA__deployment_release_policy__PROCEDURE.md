# 🚀 KOOMY — Deployment & Release Policy

## 1. Objectif du document

Ce document définit **la politique officielle de déploiement et de mise en production** de la plateforme **Koomy**.

Objectifs :
- Garantir la **stabilité en production**
- Éliminer les déploiements improvisés
- Encadrer les responsabilités
- Assurer une traçabilité complète des releases
- Aligner technique, produit et business

> ⚠️ Un déploiement n’est jamais anodin. Il engage la plateforme, les données et la crédibilité.

---

## 2. Environnements de déploiement

| Environnement | Branche Git | Objectif |
|-------------|------------|----------|
| **LOCAL** | feature/* | Développement |
| **SANDBOX** | staging | Tests réalistes / démos |
| **PRODUCTION** | main | Exploitation réelle |

Aucun autre flux n’est autorisé.

---

## 3. Règles de branches Git

### 3.1 Branches autorisées

- `main` : production uniquement
- `staging` : pré-production / sandbox
- `feature/*` : développement isolé

🚫 Interdictions :
- Push direct sur `main`
- Déployer `feature/*` sur PROD

---

## 4. Conditions préalables à un déploiement

Avant tout déploiement :

- ✅ Feature validée fonctionnellement
- ✅ Tests réalisés en SANDBOX
- ✅ Aucune régression critique connue
- ✅ Conformité aux documents fondateurs

Un déploiement peut être refusé même si le code compile.

---

## 5. Procédure de déploiement SANDBOX

1. Merge `feature/*` → `staging`
2. Déploiement automatique vers SANDBOX
3. Tests complets :
   - parcours utilisateur
   - paiements test
   - rôles & permissions
4. Validation formelle CTO

---

## 6. Procédure de mise en production

1. Validation finale CTO
2. Merge `staging` → `main`
3. Déploiement PROD
4. Vérifications post-release :
   - API
   - Auth
   - Paiements
   - Logs

Aucun correctif ne doit être poussé immédiatement après sans analyse.

---

## 7. Versioning

- Version incrémentale
- Une version = un état stable
- Rollback possible vers la version précédente

Les versions doivent être traçables.

---

## 8. Fenêtres de déploiement

- Déploiements PROD préférés :
  - en semaine
  - heures ouvrées
- Éviter les soirs / week-ends sauf urgence

---

## 9. Déploiements d’urgence

En cas d’incident critique :
- Application du **Incident & Rollback Protocol**
- Priorité à la stabilité
- Post-mortem obligatoire

---

## 10. Rôles et responsabilités

| Rôle | Responsabilité |
|----|---------------|
| Fondateur / CTO | Décision finale |
| Replit | Implémentation technique |
| Équipe future | Respect du process |

---

## 11. Interdictions absolues

- ❌ Déployer pour "tester"
- ❌ Corriger directement en PROD
- ❌ Déployer sans rollback possible

---

## 12. Principe fondateur

> **La production est un actif, pas un terrain d’expérimentation.**

Chaque release doit :
- être voulue
- être comprise
- pouvoir être annulée

