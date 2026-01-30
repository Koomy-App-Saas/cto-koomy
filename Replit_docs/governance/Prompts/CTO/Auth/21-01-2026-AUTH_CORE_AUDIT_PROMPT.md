# KOOMY — AUTH CORE AUDIT
## Bilan clinique (READ-ONLY)

⚠️ INSTRUCTION ABSOLUE  
Tu n’as PAS le droit de modifier le code, ni d’optimiser, ni de corriger quoi que ce soit.  
Tu es en AUDIT PUR.  
Tout changement de code sera considéré comme une faute grave.

---

## 🎯 OBJECTIF

Produire un **bilan clinique exhaustif** du cœur technique de KOOMY, centré exclusivement sur :

- Authentification
- Rôles
- Autorisations
- Appartenance utilisateur ↔ organisation

Tu dois décrire **ce qui existe réellement**, pas ce qui devrait exister.

---

## 🧠 MÉTHODOLOGIE

- Oublie toute hypothèse préalable
- Base-toi uniquement sur le code présent dans le repository
- Ne fais aucune supposition non vérifiable
- Ne propose aucune amélioration ou refonte

---

## 📦 LIVRABLE UNIQUE

Créer le fichier suivant :

/docs/audit/AUTH_CORE_AUDIT.md

---

## 🧾 STRUCTURE OBLIGATOIRE DU DOCUMENT

### 1. Vue d’ensemble
- Où se situe le cœur auth dans le projet
- Quels dossiers / modules sont impliqués
- Description factuelle du flux auth (login → accès → action)

---

### 2. Modèle de données (vérité terrain)
Pour chaque table ou modèle lié à l’auth :

- Nom
- Champs
- Types
- Valeurs possibles
- Contraintes implicites
- Relations

Indiquer clairement :
- Où est stocké le rôle
- Où est stockée l’appartenance
- S’il existe plusieurs sources de vérité

---

### 3. Backend — Décision d’accès
Lister et décrire :

- Middlewares d’authentification
- Guards / policies
- Conditions liées aux rôles (if / else)
- Endpoints critiques (login, me, switch organisation, etc.)

Pour chaque mécanisme :
- Qui décide ?
- Sur quelle donnée ?
- À quel moment ?

---

### 4. Frontend — Hypothèses et couplages
Identifier :

- États d’auth globaux
- Conditions d’affichage basées sur les rôles
- Redirections automatiques
- Cas où le frontend bloque ou autorise un accès

Mettre en évidence toute logique qui relève normalement du backend.

---

### 5. Couplages dangereux
Lister explicitement tout couplage entre l’authentification et :

- Onboarding
- Paiement / Stripe
- White-label
- Routing
- UI conditionnelle

---

### 6. Zones à risque
Sans proposer de correction, identifier :

- Incohérences potentielles
- États impossibles mais observables
- Cas non gérés
- Hypothèses non garanties par le code

---

### 7. Résumé clinique
- Points solides
- Points fragiles
- Zones critiques

⚠️ Aucune recommandation technique  
⚠️ Aucun plan de refonte  
⚠️ Aucun correctif
