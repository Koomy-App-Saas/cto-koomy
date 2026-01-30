# KOOMY — AUDIT PRODUIT
## Adhésion des membres : durée, cycle de facturation, modes de paiement

**Version :** 1.1  
**Date :** 2026-01-12  
**Statut :** Document de référence produit  
**Addendum :** [Décisions produit finales](./addendum-adhesion-decisions.md)

---

> **IMPORTANT :** Ce document doit être lu conjointement avec l'[Addendum Décisionnel](./addendum-adhesion-decisions.md) qui tranche les décisions produit finales. Les règles de l'addendum prévalent sur toute hypothèse exploratoire ci-dessous.

---

## Table des matières

1. [Concepts fondamentaux](#1-concepts-fondamentaux)
2. [Typologies d'adhésion réelles](#2-typologies-dadhésion-réelles)
3. [Cycles de facturation](#3-cycles-de-facturation)
4. [Modes de paiement](#4-modes-de-paiement)
5. [Statuts d'adhésion](#5-statuts-dadhésion)
6. [Cas limites et règles produit](#6-cas-limites-et-règles-produit)
7. [Recommandations](#7-recommandations)

---

## 1. Concepts fondamentaux

### 1.1 Trois notions distinctes à ne jamais confondre

| Concept | Définition | Exemple |
|---------|-----------|---------|
| **Durée d'adhésion** | Période pendant laquelle le membre a le **droit d'appartenir** à la communauté | "Adhésion valable 1 an à compter de l'inscription" |
| **Cycle de facturation** | Rythme auquel le membre **paie** sa cotisation | "Paiement mensuel de 15€" |
| **Mode de paiement** | Canal utilisé pour effectuer le paiement | "Prélèvement SEPA", "Carte bancaire", "Espèces" |

### 1.2 Pourquoi cette distinction est essentielle

**Ces trois notions sont indépendantes.** Un membre peut avoir :
- Une adhésion **annuelle** (durée = 12 mois)
- Payée **mensuellement** (cycle = mensuel)
- Par **prélèvement SEPA** (mode = SEPA)

Mélanger ces notions crée de la dette produit et des cas impossibles à gérer.

### 1.3 Exemples concrets de combinaisons

| Cas réel | Durée | Cycle | Mode |
|----------|-------|-------|------|
| **Syndicat UNSA** | Illimitée (tant que cotisation à jour) | Mensuel | Prélèvement SEPA |
| **Club de sport** | 1 an (saison) | Annuel ou 3x sans frais | Carte ou chèque |
| **Association culturelle** | 1 an civil | Annuel | Carte, virement, espèces |
| **Amicale d'entreprise** | Illimitée | Prélevé sur salaire | Retenue employeur |

---

## 2. Typologies d'adhésion réelles

### 2.1 Adhésion à durée fixe

**Définition :** L'adhésion expire automatiquement après une période définie.

| Variante | Description | Exemple |
|----------|-------------|---------|
| **Année calendaire** | Du 1er janvier au 31 décembre | Association loi 1901 classique |
| **Année glissante** | 12 mois à partir de l'inscription | Club de fitness |
| **Saison** | Période fixe (sept → juin) | Club sportif amateur |
| **Durée personnalisée** | 3 mois, 6 mois, 2 ans... | Offres promotionnelles |

**Règle produit :** À l'expiration, l'adhésion passe automatiquement en statut "expirée" sauf renouvellement.

### 2.2 Adhésion illimitée (tant que cotisation à jour)

**Définition :** Aucune date de fin. Le membre reste actif tant qu'il paie sa cotisation.

**Cas d'usage :**
- Syndicats (UNSA, CGT, CFDT...)
- Mutuelles
- Ordres professionnels

**Règle produit :** L'adhésion devient "suspendue" ou "résiliée" uniquement en cas d'impayé prolongé ou de démission.

### 2.3 Adhésion ponctuelle (à vie)

**Définition :** Paiement unique, adhésion permanente.

**Cas d'usage :**
- Associations d'anciens élèves
- Clubs de bienfaiteurs
- Membres d'honneur

**Règle produit :** Aucune facturation récurrente, aucune expiration.

### 2.4 Carte de membre sans expiration formelle

**Définition :** Document physique ou numérique délivré sans date de fin imprimée.

**Attention :** La carte n'est pas l'adhésion. Elle peut être :
- Valide indéfiniment mais liée à une adhésion expirée
- Renouvelée chaque année avec nouveau numéro
- Permanente avec QR code vérifiant le statut en temps réel

**Règle produit :** Distinguer clairement "carte valide" et "adhésion active".

---

## 3. Cycles de facturation

### 3.1 Vue d'ensemble

| Cycle | Fréquence | Cas d'usage | Particularités |
|-------|-----------|-------------|----------------|
| **Mensuel** | Chaque mois | Syndicats, abonnements | Prélèvement automatique recommandé |
| **Trimestriel** | Tous les 3 mois | Certaines mutuelles | Moins fréquent |
| **Annuel** | Une fois par an | Associations classiques | Paiement unique ou échelonné |
| **Paiement unique** | Une seule fois | Adhésion à vie, événement | Pas de récurrence |

### 3.2 Paiement échelonné vs paiement récurrent

**Paiement échelonné (3x, 4x, 10x) :**
- Montant total fixe, divisé en plusieurs versements
- Nombre de versements défini à l'avance
- Après le dernier versement, aucun prélèvement supplémentaire
- **Exemple :** Adhésion annuelle à 120€ payée en 3x40€

**Paiement récurrent (abonnement) :**
- Prélèvement continu tant que l'adhésion est active
- Pas de montant total prédéfini
- Résiliation = arrêt des prélèvements
- **Exemple :** Cotisation syndicale de 15€/mois sans limite

| Critère | Échelonné | Récurrent |
|---------|-----------|-----------|
| Durée connue à l'avance | ✅ Oui | ❌ Non |
| Montant total connu | ✅ Oui | ❌ Non |
| Résiliation possible | ⚠️ Engagement | ✅ À tout moment |
| Renouvellement | Manuel | Automatique |

### 3.3 Notion d'engagement

**Avec engagement :**
- Le membre s'engage sur une durée minimale
- Résiliation avant terme = pénalités ou refus
- Exemple : "Engagement 12 mois, résiliation au terme"

**Sans engagement :**
- Résiliation possible à tout moment
- Préavis éventuel (1 mois, fin de période...)
- Exemple : "Cotisation mensuelle, résiliable à tout moment"

### 3.4 Conséquences d'un paiement en retard

| Situation | Impact immédiat | Impact à J+15 | Impact à J+30 |
|-----------|-----------------|---------------|---------------|
| **Prélèvement échoué** | Nouvelle tentative automatique | Notification + statut "en retard" | Suspension possible |
| **Facture non payée** | Rappel automatique | Relance | Suspension |
| **Chèque rejeté** | Notification manuelle | Régularisation demandée | Suspension |

---

## 4. Modes de paiement

### 4.1 Carte bancaire

**Avantages :**
- Paiement instantané
- Confirmation immédiate
- Pas de délai d'encaissement

**Inconvénients :**
- Carte expirée = échec futur
- Frais de transaction (1,4% - 2,9%)
- Opposition possible

**Règle produit :**
- Stocker l'empreinte pour paiements récurrents
- Alerter le membre 30 jours avant expiration de carte
- Prévoir un fallback en cas d'échec

### 4.2 Prélèvement SEPA

**Avantages :**
- Automatisation totale
- Coût faible (0,20€ - 0,50€ par transaction)
- Fiable pour paiements récurrents

**Inconvénients :**
- Délai de mise en place (mandat)
- Délai d'encaissement (3-5 jours)
- Révocation possible par le payeur
- Opposition jusqu'à 8 semaines après prélèvement

**Règle produit :**
- Mandat SEPA obligatoire avant premier prélèvement
- Conservation du mandat 36 mois après dernier prélèvement
- Préavis de 14 jours avant chaque prélèvement (D-14)

### 4.3 Paiement manuel (espèces, chèque, virement)

**Avantages :**
- Accessibilité (pas de carte, pas de compte en ligne)
- Contrôle total par l'association
- Pas de frais de transaction

**Inconvénients :**
- Validation manuelle obligatoire
- Risque d'erreur humaine
- Traçabilité plus complexe
- Délai entre paiement et activation

**Règle produit :**
- **Statut "en attente de validation"** jusqu'à confirmation
- Un administrateur doit valider manuellement
- Horodatage de la validation (qui, quand)
- Possibilité de refuser avec motif

### 4.4 Tableau récapitulatif

| Mode | Activation | Récurrence | Validation | Coût |
|------|------------|------------|------------|------|
| Carte bancaire | Immédiate | ✅ Automatique | Automatique | Moyen |
| SEPA | J+3 à J+5 | ✅ Automatique | Automatique | Faible |
| Virement | J+1 à J+3 | ❌ Manuel | Manuelle | Nul |
| Chèque | Après encaissement | ❌ Manuel | Manuelle | Nul |
| Espèces | Après remise | ❌ Manuel | Manuelle | Nul |

---

## 5. Statuts d'adhésion

### 5.1 Liste des statuts

| Statut | Description | Droits membre |
|--------|-------------|---------------|
| **active** | Cotisation à jour, adhésion valide | ✅ Tous les droits |
| **en_attente** | Inscription faite, paiement non confirmé | ⚠️ Accès limité |
| **en_retard** | Paiement attendu, délai de grâce | ⚠️ Droits maintenus temporairement |
| **suspendue** | Impayé prolongé ou décision admin | ❌ Droits suspendus, compte visible |
| **résiliée** | Fin volontaire ou exclusion | ❌ Aucun droit, données conservées |
| **expirée** | Durée d'adhésion écoulée sans renouvellement | ❌ Aucun droit |

### 5.2 Matrice de transition

```
                    ┌──────────────────────────────────────────────┐
                    │                                              │
                    ▼                                              │
┌─────────┐    ┌─────────┐    ┌───────────┐    ┌──────────┐    ┌───────────┐
│ NOUVELLE │───▶│ EN      │───▶│ ACTIVE    │───▶│ EN       │───▶│ SUSPENDUE │
│ DEMANDE  │    │ ATTENTE │    │           │    │ RETARD   │    │           │
└─────────┘    └─────────┘    └───────────┘    └──────────┘    └───────────┘
                    │              │                │                 │
                    │              │                │                 │
                    ▼              ▼                ▼                 ▼
               ┌─────────┐   ┌──────────┐    ┌──────────┐      ┌───────────┐
               │ REFUSÉE │   │ EXPIRÉE  │    │ ACTIVE   │      │ RÉSILIÉE  │
               │         │   │          │    │ (régul.) │      │           │
               └─────────┘   └──────────┘    └──────────┘      └───────────┘
```

### 5.3 Règles de transition détaillées

#### ACTIVE → EN_RETARD
- **Déclencheur :** Échéance de paiement dépassée
- **Délai de grâce :** Paramétrable (défaut : 7 jours)
- **Droits :** Maintenus pendant le délai de grâce
- **Actions :** Notification automatique au membre

#### EN_RETARD → SUSPENDUE
- **Déclencheur :** Délai de grâce expiré sans paiement
- **Délai :** Paramétrable (défaut : 15 jours après passage en retard)
- **Droits :** Suspendus immédiatement
- **Actions :** Notification, compte désactivé mais visible

#### SUSPENDUE → ACTIVE (régularisation)
- **Déclencheur :** Paiement reçu et validé
- **Effet :** Réactivation immédiate
- **Droits :** Restaurés
- **Actions :** Notification de réactivation

#### SUSPENDUE → RÉSILIÉE
- **Déclencheur :** 
  - Impayé > 90 jours (paramétrable)
  - Décision administrative
  - Demande du membre
- **Effet :** Fin définitive de l'adhésion
- **Données :** Conservées selon RGPD (3 ans minimum)

#### ACTIVE → EXPIRÉE
- **Déclencheur :** Date de fin d'adhésion atteinte
- **Applicable :** Uniquement adhésions à durée fixe
- **Effet :** Aucun droit, invitation à renouveler
- **Actions :** Notification 30, 15, 7 jours avant

---

## 6. Cas limites et règles produit

### 6.1 Paiement mensuel en retard

**Scénario :** Jean paie 15€/mois par SEPA. Le prélèvement de mars échoue.

**Règle produit :**
1. J+0 : Échec du prélèvement → nouvelle tentative automatique à J+3
2. J+3 : Nouvel échec → statut "en_retard", notification au membre
3. J+7 : Fin du délai de grâce → statut "suspendue"
4. Si paiement reçu : retour immédiat à "active"

**Zone de vigilance :** Prévoir un bouton "Régulariser maintenant" visible pour le membre.

### 6.2 Carte bancaire expirée

**Scénario :** Marie a une carte qui expire en mars. Son paiement annuel est prévu en avril.

**Règle produit :**
1. J-30 : Notification "Votre carte expire bientôt, mettez-la à jour"
2. J-7 : Rappel
3. J+0 (expiration) : Paiement échoue si non mise à jour
4. Procédure "en_retard" classique

**Zone de vigilance :** Ne jamais stocker le CVV, uniquement l'empreinte tokenisée.

### 6.3 SEPA rejeté (provision insuffisante)

**Scénario :** Le prélèvement SEPA de Paul est rejeté pour solde insuffisant.

**Règle produit :**
1. J+0 : Notification "Prélèvement rejeté"
2. J+3 : Nouvelle tentative automatique
3. J+7 : Si nouvel échec → statut "en_retard"
4. Possibilité de paiement alternatif (carte) proposée

**Zone de vigilance :** Le membre doit pouvoir changer de mode de paiement facilement.

### 6.4 Paiement cash non confirmé

**Scénario :** Sophie paie en espèces au guichet de l'association, mais l'admin n'a pas validé.

**Règle produit :**
1. Statut reste "en_attente" jusqu'à validation
2. Notification à l'admin pour rappel après 48h
3. Après 7 jours sans validation : alerte au responsable
4. Possibilité de refuser avec motif

**Zone de vigilance :** Un paiement cash non validé ne doit JAMAIS activer automatiquement l'adhésion.

### 6.5 Changement de cycle de paiement

**Scénario :** Lucas passe de paiement annuel à mensuel.

**Règle produit :**
- **Si période en cours payée :** Nouveau cycle démarre à l'expiration
- **Si période en cours non payée :** Application immédiate du nouveau cycle
- **Calcul prorata :** Si montants différents, calculer le reste dû

**Exemple :**
- Lucas a payé 120€ le 1er janvier (annuel)
- Le 1er avril, il demande du mensuel à 12€/mois
- Il a "consommé" 3 mois = 36€
- Reste 84€ de crédit
- Ou : on attend janvier prochain pour appliquer le mensuel

**Recommandation :** Laisser le choix à la communauté (prorata ou à échéance).

### 6.6 Changement de mode de paiement

**Scénario :** Emma passe de carte à SEPA.

**Règle produit :**
1. Arrêt immédiat des prélèvements carte
2. Signature électronique du mandat SEPA
3. Délai de mise en place (3-5 jours)
4. Premier prélèvement SEPA à la prochaine échéance

**Zone de vigilance :** Éviter les doubles prélèvements pendant la transition.

### 6.7 Adhésion illimitée avec impayé

**Scénario :** Pierre (syndicat) ne paie plus depuis 3 mois.

**Règle produit :**
1. Mois 1 sans paiement : "en_retard"
2. Mois 2 : "suspendue"
3. Mois 3 : Notification "dernière relance avant résiliation"
4. Mois 4 : "résiliée" automatiquement (ou décision manuelle)

**Zone de vigilance :** Pour les syndicats, vérifier les règles conventionnelles (certains imposent une procédure de radiation).

### 6.8 Membre suspendu puis régularisation

**Scénario :** Claire était suspendue pour impayé. Elle régularise.

**Règle produit :**
1. Validation du paiement (manuelle si cash, automatique si carte/SEPA)
2. Retour immédiat à "active"
3. Recalcul de la prochaine échéance :
   - Option A : Reprend le cycle normal
   - Option B : Nouvelle période à partir de la régularisation
4. Notification de réactivation

**Recommandation :** Laisser le choix à la communauté.

---

## 7. Recommandations

### 7.1 Principes de conception

1. **Séparer clairement** durée, cycle et mode de paiement dans le modèle de données
2. **Statuts explicites** visibles par le membre ET l'admin
3. **Historique complet** de toutes les transitions de statut
4. **Notifications automatiques** pour chaque changement d'état
5. **Flexibilité** dans les délais de grâce et seuils (paramétrage par communauté)

### 7.2 Paramètres configurables par communauté

| Paramètre | Valeur par défaut | Description |
|-----------|-------------------|-------------|
| `delai_grace_jours` | 7 | Jours avant passage de "en_retard" à "suspendue" |
| `delai_suspension_jours` | 15 | Jours de suspension avant résiliation automatique |
| `delai_resiliation_auto_jours` | 90 | Jours d'impayé avant résiliation automatique |
| `alerte_expiration_carte_jours` | 30 | Jours avant alerte d'expiration de carte |
| `tentatives_prelevement` | 2 | Nombre de tentatives automatiques avant échec |
| `prorata_changement_cycle` | false | Appliquer le prorata en cas de changement de cycle |

### 7.3 Zones de vigilance produit

| Zone | Risque | Mitigation |
|------|--------|------------|
| Double prélèvement | Membre prélevé deux fois | Vérification systématique avant prélèvement |
| Paiement manuel orphelin | Argent reçu, adhésion non activée | Alertes automatiques aux admins |
| Expiration silencieuse | Membre perd ses droits sans notification | Notifications J-30, J-15, J-7, J-1 |
| Changement de cycle | Calculs incohérents | Règles claires, choix de la communauté |
| Données sensibles | Fuite de coordonnées bancaires | Tokenisation, jamais de stockage direct |

### 7.4 Checklist pour implémentation future

- [ ] Modèle de données séparant durée/cycle/mode
- [ ] Machine à états pour les statuts d'adhésion
- [ ] Système de notifications (email, push, SMS)
- [ ] Interface de validation manuelle pour paiements cash
- [ ] Historique auditable des transitions
- [ ] Paramétrage par communauté
- [ ] Gestion des mandats SEPA
- [ ] Alertes d'expiration de carte
- [ ] Calcul de prorata
- [ ] Rapprochement bancaire automatique

---

## Annexe : Glossaire

| Terme | Définition |
|-------|-----------|
| **Adhésion** | Relation formelle entre un membre et une communauté |
| **Cotisation** | Montant dû par le membre à la communauté |
| **Cycle de facturation** | Fréquence des paiements (mensuel, annuel...) |
| **Délai de grâce** | Période pendant laquelle un retard est toléré |
| **Mandat SEPA** | Autorisation de prélèvement signée par le payeur |
| **Prorata** | Calcul proportionnel au temps |
| **Tokenisation** | Remplacement de données sensibles par un jeton sécurisé |

---

*Document rédigé dans le cadre de l'audit produit Koomy.*  
*Ce document est destiné à servir de référence pour une implémentation future.*
