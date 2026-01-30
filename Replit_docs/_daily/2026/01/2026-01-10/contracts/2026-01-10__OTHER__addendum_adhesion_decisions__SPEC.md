# KOOMY — ADDENDUM DÉCISIONNEL PRODUIT
## Adhésion des membres — Paiement & Facturation

**Version :** 1.0  
**Date :** 2026-01-12  
**Statut :** DÉCISIONS PRODUIT FINALES — OPPOSABLES  
**Portée :** Mise à jour de l'audit produit "Adhésion des membres"

---

## PRÉAMBULE

Ce document complète et verrouille l'audit produit existant sur l'adhésion des membres.

Il a pour objectif de :
- trancher les points laissés ouverts
- éliminer toute ambiguïté d'interprétation
- figer le contrat produit AVANT toute implémentation

Ce document est **décisionnel**, pas exploratoire.  
Il prévaut sur toute hypothèse antérieure.

---

## 1. POSITIONNEMENT FONDAMENTAL DE KOOMY

Koomy est une plateforme de gestion destinée aux **clubs, associations et syndicats**.

**Les clients de Koomy sont les organisations, pas les membres individuels.**

Par conséquent :
- Koomy **ne prend aucune décision à la place des gestionnaires**
- Koomy **n'impose aucune sanction automatique aux membres**
- Koomy se limite volontairement à :
  - calculer
  - afficher
  - historiser
  - notifier

Toutes les décisions relatives à une adhésion (suspension, résiliation, réactivation) sont **humaines**.

---

## 2. GOUVERNANCE DES RÈGLES

### Décision actée

| Élément | Décision |
|---------|----------|
| Règles paramétrables par communauté | ❌ NON |
| Délais de grâce configurables | ❌ NON |
| Suspension automatique | ❌ NON |
| Résiliation automatique | ❌ NON |

Les règles sont :
- **figées côté Koomy**
- **neutres**
- **identiques pour toutes les communautés**

**Principe :** Koomy fournit une lecture objective de la situation, jamais une décision.

---

## 3. PAIEMENT MANUEL (CASH, CHÈQUE, VIREMENT)

### Décision actée

| Élément | Décision |
|---------|----------|
| Paiement manuel dans l'inscription en ligne | ❌ EXCLU |
| Gestion cash/chèque/virement dans le tunnel digital | ❌ NON |

### Process officiel

Le paiement manuel est traité **entièrement offline** :
1. Le gestionnaire encaisse le paiement
2. Le gestionnaire crée le compte membre manuellement
3. Le gestionnaire définit lui-même le statut

**Principe :** Koomy n'est **jamais responsable** d'un paiement manuel.

---

## 4. ADHÉSION ILLIMITÉE (SYNDICATS, CAS UNSA)

### Décision actée

| Élément | Décision |
|---------|----------|
| Suspension automatique | ❌ NON |
| Résiliation automatique | ❌ NON |
| Affichage des états (retard, montant dû, historique) | ✅ OUI |
| Notifications informatives | ✅ OUI |

Le gestionnaire du compte :
- décide de la suspension
- décide de la résiliation
- décide de la réactivation

**Principe :** Koomy respecte les obligations humaines, sociales et syndicales.

---

## 5. RETARD DE PAIEMENT — STATUT PAR DÉFAUT

### Décision actée

| Élément | Décision |
|---------|----------|
| Membre en retard | Reste **ACTIF** |
| État "EN RETARD" | ✅ Visible (informatif) |
| Coupure automatique des droits | ❌ NON |

**Principe :** Le statut "en retard" est **informatif**, jamais punitif.

---

## 6. CARTE DE MEMBRE VS STATUT RÉEL

### Décision actée

| Élément | Décision |
|---------|----------|
| Valeur juridique de la carte | ❌ AUCUNE |
| Source de vérité | ✅ Statut d'adhésion uniquement |

La carte peut afficher :
- une pastille d'état (vert, orange, rouge)
- un statut synchronisé en temps réel

**Principe :** En cas de contrôle, c'est le statut qui prévaut, jamais la carte seule.

---

## 7. CHANGEMENT DE CYCLE DE FACTURATION

### Décision actée (FERMÉE)

| Élément | Décision |
|---------|----------|
| Changement de cycle en cours d'adhésion | ❌ IMPOSSIBLE |
| Prorata | ❌ NON |
| Effet immédiat | ❌ NON |
| Changement au renouvellement | ✅ OUI |

Le cycle est :
- choisi à l'inscription
- figé pour toute la période active

**Principe :** Simplicité, lisibilité, zéro dette comptable.

---

## 8. CHANGEMENT DE MODE DE PAIEMENT

### Décision actée

| Élément | Décision |
|---------|----------|
| Interruption automatique par Koomy | ❌ NON |
| Fallback automatique sans consentement | ❌ NON |

Le changement de mode de paiement :
- n'interrompt pas le système côté Koomy
- relève du choix du gestionnaire ou du contexte communautaire

**Principe :** Koomy privilégie la transparence et le consentement.

---

## 9. RÉSILIATION

### Décision actée

| Élément | Décision |
|---------|----------|
| Nature de la résiliation | STATUT (pas une suppression) |
| Réversibilité | ✅ OUI |
| Historisation | ✅ OUI |
| Conservation RGPD | ✅ OUI |
| Résiliation automatique par Koomy | ❌ NON |

Qui peut résilier :
- le membre (ex : "quitter le club")
- le gestionnaire

**Principe :** Aucune résiliation automatique par Koomy.

---

## 10. NOTIFICATIONS & COMMUNICATION

### Décision actée

| Élément | Décision |
|---------|----------|
| Notifications | ✅ OBLIGATOIRES |
| Désactivables | ❌ NON |
| Canal prioritaire | 📧 Email |

### Événements notifiés systématiquement

| Événement | Notification |
|-----------|--------------|
| Paiement dû | ✅ |
| Paiement en retard | ✅ |
| Rappel de paiement | ✅ |
| Suspension (si décidée) | ✅ |
| Résiliation (si décidée) | ✅ |
| Expiration prochaine (durée fixe) | ✅ |

Chaque email inclut un **lien direct de régularisation**.

**Principe :** Information, transparence, réduction des litiges.

---

## 11. STATUT FINAL DU CONTRAT PRODUIT

| Élément | Statut |
|---------|--------|
| Audit produit | ✅ Complété |
| Décisions fondatrices | ✅ Tranchées |
| Ambiguïtés | ❌ Éliminées |
| Dette produit future | ❌ Évitée |

---

## TABLEAU RÉCAPITULATIF DES DÉCISIONS

| Domaine | Décision | Justification |
|---------|----------|---------------|
| Automatisation sanctions | ❌ Aucune | Koomy ne décide pas à la place des humains |
| Paiement manuel en ligne | ❌ Exclu | Gestion 100% offline |
| Suspension automatique | ❌ Jamais | Décision du gestionnaire |
| Résiliation automatique | ❌ Jamais | Décision du gestionnaire |
| Changement cycle en cours | ❌ Impossible | Simplicité comptable |
| Prorata | ❌ Non | Éviter la dette technique |
| Notifications | ✅ Obligatoires | Transparence, conformité |
| Carte = statut | ❌ Non | Seul le statut fait foi |

---

## IMPACT SUR L'AUDIT INITIAL

L'audit produit (`docs/audit-adhesion-membres.md`) doit être lu conjointement avec cet addendum.

**Corrections apportées :**

| Section audit | Correction |
|---------------|------------|
| 3.4 Paiement en retard | Pas de suspension automatique |
| 5.3 Transitions de statut | Toutes les transitions sont manuelles |
| 6.x Cas limites | Aucune action automatique, uniquement affichage |
| 7.2 Paramètres configurables | ❌ Supprimés — règles figées |

---

**FIN DE L'ADDENDUM DÉCISIONNEL**

*Ce document sert de référence unique pour toute implémentation future.*
