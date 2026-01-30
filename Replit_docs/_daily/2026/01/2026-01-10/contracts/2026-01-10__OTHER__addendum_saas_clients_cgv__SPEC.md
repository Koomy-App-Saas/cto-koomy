# KOOMY — ADDENDUM CONTRACTUEL
## Clients SaaS Koomy (facturation, impayés, suspension)

**Version :** 1.0  
**Date :** 2026-01-12  
**Statut :** Addendum contractuel — base CGV  
**Périmètre :** Clients SaaS standards Koomy (souscription en ligne)

---

## 1. OBJET

Le présent addendum a pour objet de définir les règles applicables à la :
- facturation des services SaaS Koomy,
- gestion des impayés,
- suspension et résiliation des comptes clients Koomy.

Il complète les Conditions Générales de Vente (CGV) de Koomy et prévaut sur toute disposition antérieure contradictoire.

---

## 2. PÉRIMÈTRE D'APPLICATION

Les présentes règles s'appliquent **exclusivement** :
- aux clients ayant souscrit aux services Koomy via une souscription en ligne (self-onboarding).

Sont explicitement exclus du présent périmètre :
- les grands comptes faisant l'objet d'un contrat spécifique négocié,
- les membres des communautés gérées via la plateforme Koomy,
- les adhésions, cotisations ou paiements internes aux associations, clubs ou syndicats.

---

## 3. FACTURATION

Les services Koomy sont facturés de manière récurrente selon la formule choisie lors de la souscription.

Chaque échéance donne lieu à une facture exigible à la date prévue.

Le Client est seul responsable de la validité de ses moyens de paiement.

---

## 4. DÉFAUT DE PAIEMENT

En cas de non-paiement d'une échéance à la date prévue, le compte client entre dans un état de retard de paiement sans interruption immédiate de service.

Koomy n'accepte pas plus de **deux (2) échéances impayées simultanément**.

---

## 5. GESTION DES IMPAYÉS

### 5.1 Première échéance impayée

En cas de première échéance impayée :
- le compte client reste pleinement actif,
- aucune restriction fonctionnelle n'est appliquée,
- une notification d'information est adressée au Client par email.

Le Client dispose d'un délai de **quinze (15) jours** pour régulariser sa situation.

---

### 5.2 Seconde échéance impayée

Si la situation n'est pas régularisée avant la date de la seconde échéance :
- le compte client reste actif,
- aucune restriction fonctionnelle n'est appliquée,
- des notifications de rappel sont envoyées au Client.

Le Client dispose d'un second délai de **quinze (15) jours** pour régulariser avant toute suspension.

---

## 6. SUSPENSION DU COMPTE

À compter de la constatation de **deux (2) échéances impayées**, Koomy se réserve le droit de suspendre le compte client.

La suspension entraîne :
- le blocage de l'accès au back-office Koomy,
- la désactivation des fonctionnalités de gestion,
- la suspension de l'accès aux cartes et services associés.

La suspension n'entraîne aucune suppression de données.

---

## 7. RÉSILIATION

Si une **troisième échéance** devient impayée sans régularisation préalable, Koomy se réserve le droit de résilier le compte client.

La résiliation entraîne :
- la fermeture définitive de l'accès au service,
- la fin de la relation contractuelle.

La résiliation ne constitue pas une suppression immédiate des données.

---

## 8. RÉGULARISATION

### 8.1 Avant suspension
Toute régularisation effectuée avant la suspension entraîne le maintien du service sans interruption.

### 8.2 Après suspension
Toute régularisation effectuée après suspension et avant résiliation entraîne la réactivation du compte.

### 8.3 Après résiliation
Aucune réactivation automatique n'est possible après résiliation.
Toute reprise nécessite une nouvelle souscription ou une décision commerciale spécifique.

---

## 9. CONSERVATION DES DONNÉES

En cas de résiliation, les données du Client sont conservées pendant une durée minimale de **trois (3) mois**, notamment à des fins :
- légales,
- comptables,
- de gestion des litiges.

La suppression définitive des données intervient conformément aux obligations légales et à la politique de conservation des données de Koomy.

---

## 10. NOTIFICATIONS

Toutes les communications relatives :
- aux impayés,
- aux rappels,
- à la suspension,
- à la résiliation,

sont effectuées **exclusivement par email**, à l'adresse renseignée par le Client.

Chaque notification contient, lorsque applicable, un lien direct permettant la régularisation du paiement.

---

## 11. ENTRÉE EN VIGUEUR

Le présent addendum entre en vigueur à compter de sa publication et s'applique à toute souscription postérieure.

---

## TABLEAU RÉCAPITULATIF

| Situation | Délai | Action Koomy | Conséquence |
|-----------|-------|--------------|-------------|
| 1ère échéance impayée | J+0 | Notification email | Service maintenu |
| Délai de grâce 1 | 15 jours | Rappels | Service maintenu |
| 2ème échéance impayée | J+15 | Notification urgente | Service maintenu |
| Délai de grâce 2 | 15 jours | Rappels quotidiens | Service maintenu |
| Suspension | J+30 | Blocage compte | Accès suspendu |
| 3ème échéance impayée | J+60 | Notification résiliation | Compte résilié |

---

## LIEN AVEC L'AUDIT PRODUIT

Ce document contractuel est issu de l'audit produit : [`docs/audit-saas-clients-impayés.md`](./audit-saas-clients-impayés.md)

L'audit produit contient les détails techniques et fonctionnels complets, notamment :
- les états système (`ACTIVE`, `IMPAYE_1`, `IMPAYE_2`, `SUSPENDU`, `RESILIE`)
- les impacts fonctionnels détaillés
- les templates de notifications
- les cas limites et règles produit

---

**FIN DE L'ADDENDUM CONTRACTUEL — SAAS CLIENTS KOOMY**
