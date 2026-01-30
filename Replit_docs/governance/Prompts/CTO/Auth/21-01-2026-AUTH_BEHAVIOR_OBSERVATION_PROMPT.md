# KOOMY — AUTH CORE
## Tests d’observation comportementale (READ-ONLY)

⚠️ INSTRUCTION ABSOLUE  
Aucune modification de code n’est autorisée.  
Tu observes le comportement réel du système tel qu’il est.

---

## 🎯 OBJECTIF

Observer et documenter le **comportement réel** du système
authentification / rôles / autorisations dans la sandbox actuelle.

---

## 📦 LIVRABLE UNIQUE

Créer le fichier suivant :

/docs/audit/AUTH_BEHAVIOR_MATRIX.md

---

## 🧾 FORMAT OBLIGATOIRE (POUR CHAQUE SCÉNARIO)

Pour chaque test, documenter strictement :

- État initial exact
- Action utilisateur
- Résultat observé
- Résultat attendu (logique métier)
- Divergence (oui / non)
- Gravité perçue

Aucune supposition.  
Aucun “normalement”.  
Uniquement du constat.

---

## 🧪 SCÉNARIOS MINIMUM À TESTER

1. Utilisateur sans organisation → login
2. Utilisateur avec 1 organisation (MEMBER) → accès back-office
3. Utilisateur ADMIN → action de gestion
4. Utilisateur OWNER → action critique
5. Utilisateur avec 2 organisations → switch organisation
6. Utilisateur avec membership supprimée
7. Utilisateur loggé avec rôle incohérent
8. Utilisateur invité / incomplet
9. Cas limite post-onboarding
10. Cas limite post-paiement

---

## ⛔ INTERDICTIONS ABSOLUES

- Ne pas proposer de refonte
- Ne pas suggérer d’amélioration
- Ne pas corriger de bug
- Ne pas nettoyer le code

Tu es en observation clinique, pas en intervention.
