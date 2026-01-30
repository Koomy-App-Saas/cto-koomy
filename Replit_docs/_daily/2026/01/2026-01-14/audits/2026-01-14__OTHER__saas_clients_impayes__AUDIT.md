# KOOMY — AUDIT PRODUIT (SAAS CLIENTS)
## Paiement, impayés et suspension des comptes clients

**Version :** 1.1  
**Date :** 2026-01-12  
**Statut :** Document de référence produit  
**Périmètre :** Clients SaaS standards (self-onboarding uniquement)  
**Addendum CGV :** [Base contractuelle](./addendum-saas-clients-cgv.md)

---

> **LIEN CONTRACTUEL :** Ce document technique est accompagné d'un [Addendum Contractuel](./addendum-saas-clients-cgv.md) qui constitue la base des Conditions Générales de Vente.

---

## Table des matières

1. [Contexte et périmètre](#1-contexte-et-périmètre)
2. [États possibles d'un compte client SaaS](#2-états-possibles-dun-compte-client-saas)
3. [Cycle de vie d'un compte client](#3-cycle-de-vie-dun-compte-client)
4. [Impacts fonctionnels de la suspension](#4-impacts-fonctionnels-de-la-suspension)
5. [Notifications obligatoires](#5-notifications-obligatoires)
6. [Cas limites et règles produit](#6-cas-limites-et-règles-produit)
7. [Cohérence CGV](#7-cohérence-cgv)

---

## 1. Contexte et périmètre

### 1.1 Types de clients Koomy

| Type | Description | Traité dans ce document |
|------|-------------|-------------------------|
| **Client standard** | Souscription en ligne (self-onboarding), facturation automatique | ✅ OUI |
| **Grand compte** | Contrat négocié, facturation manuelle | ❌ NON (audit séparé) |

### 1.2 Règles fondamentales (NON NÉGOCIABLES)

| Règle | Description |
|-------|-------------|
| Tolérance maximale | **2 échéances impayées** |
| Délai de régularisation | **2 × 15 jours** avant la 2ᵉ échéance |
| Suspension | À la **2ᵉ échéance impayée** |
| Résiliation | À la **3ᵉ échéance impayée** |
| Suppression de données | ❌ **JAMAIS automatique** |

### 1.3 Ce qui est HORS périmètre

- Membres des communautés (adhésions)
- Grands comptes
- Détails techniques (Stripe, webhooks, API)

---

## 2. États possibles d'un compte client SaaS

### 2.1 Liste des états

| État | Code | Description |
|------|------|-------------|
| **Actif** | `ACTIVE` | Compte opérationnel, paiements à jour |
| **Impayé niveau 1** | `IMPAYE_1` | 1ère échéance impayée, délai de grâce |
| **Impayé niveau 2** | `IMPAYE_2` | 2ème échéance impayée, avant suspension |
| **Suspendu** | `SUSPENDU` | Accès bloqué, compte gelé |
| **Résilié** | `RESILIE` | Contrat terminé, données conservées |

### 2.2 Détail de chaque état

#### ACTIVE

| Élément | Description |
|---------|-------------|
| **Condition d'entrée** | Souscription validée + paiement initial réussi |
| **Condition de sortie** | Échéance impayée → `IMPAYE_1` |
| **Effets fonctionnels** | ✅ Accès complet au back-office<br>✅ Accès membres actif<br>✅ Cartes membres fonctionnelles<br>✅ Toutes les fonctionnalités du plan |

#### IMPAYE_1 (Première échéance impayée)

| Élément | Description |
|---------|-------------|
| **Condition d'entrée** | 1ère échéance non payée après J+3 (délai Stripe) |
| **Condition de sortie** | Paiement reçu → `ACTIVE`<br>15 jours écoulés sans paiement → `IMPAYE_2` |
| **Délai de grâce** | 15 jours |
| **Effets fonctionnels** | ✅ Accès complet maintenu<br>⚠️ Bandeau d'alerte visible dans le back-office<br>⚠️ Notifications email envoyées |

#### IMPAYE_2 (Deuxième échéance impayée)

| Élément | Description |
|---------|-------------|
| **Condition d'entrée** | 2ème échéance non payée (ou 15 jours après `IMPAYE_1`) |
| **Condition de sortie** | Paiement reçu → `ACTIVE`<br>15 jours écoulés sans paiement → `SUSPENDU` |
| **Délai avant suspension** | 15 jours |
| **Effets fonctionnels** | ✅ Accès maintenu mais restreint<br>⚠️ Alerte permanente<br>⚠️ Emails de relance quotidiens les 3 derniers jours |

#### SUSPENDU

| Élément | Description |
|---------|-------------|
| **Condition d'entrée** | 2ème échéance impayée + 15 jours écoulés |
| **Condition de sortie** | Paiement complet reçu → `ACTIVE`<br>30 jours supplémentaires sans paiement → `RESILIE` |
| **Effets fonctionnels** | ❌ Accès back-office bloqué<br>❌ Accès membres suspendu<br>❌ Cartes membres inactives<br>⚠️ Données conservées intégralement |

#### RESILIE

| Élément | Description |
|---------|-------------|
| **Condition d'entrée** | 3ème échéance impayée ou demande client |
| **Condition de sortie** | Réactivation manuelle uniquement (après régularisation) |
| **Effets fonctionnels** | ❌ Accès totalement bloqué<br>❌ Aucun service disponible<br>✅ Données conservées (RGPD : 3 ans minimum) |

---

## 3. Cycle de vie d'un compte client

### 3.1 Schéma du cycle

```
┌─────────────┐
│ SOUSCRIPTION│
│   EN LIGNE  │
└──────┬──────┘
       │
       ▼
┌─────────────┐    Paiement OK    ┌─────────────┐
│  PAIEMENT   │──────────────────▶│   ACTIVE    │◀──────────┐
│   INITIAL   │                   │             │           │
└─────────────┘                   └──────┬──────┘           │
                                         │                  │
                                  Échéance impayée          │
                                         │                  │
                                         ▼                  │
                                  ┌─────────────┐           │
                                  │  IMPAYE_1   │───────────┤
                                  │  (J+15 max) │  Paiement │
                                  └──────┬──────┘           │
                                         │                  │
                                  Pas de paiement           │
                                  après 15 jours            │
                                         │                  │
                                         ▼                  │
                                  ┌─────────────┐           │
                                  │  IMPAYE_2   │───────────┤
                                  │  (J+15 max) │  Paiement │
                                  └──────┬──────┘           │
                                         │                  │
                                  Pas de paiement           │
                                  après 15 jours            │
                                         │                  │
                                         ▼                  │
                                  ┌─────────────┐           │
                                  │  SUSPENDU   │───────────┘
                                  │  (J+30 max) │  Paiement complet
                                  └──────┬──────┘
                                         │
                                  Pas de paiement
                                  après 30 jours
                                         │
                                         ▼
                                  ┌─────────────┐
                                  │   RESILIE   │
                                  │             │
                                  └─────────────┘
```

### 3.2 Chronologie détaillée d'un impayé

| Jour | Événement | État | Action |
|------|-----------|------|--------|
| J+0 | Échéance due | `ACTIVE` | Tentative de prélèvement |
| J+3 | Échec confirmé | `IMPAYE_1` | Notification email + bandeau |
| J+7 | Rappel | `IMPAYE_1` | Email de relance |
| J+14 | Dernier rappel | `IMPAYE_1` | Email "Dernière chance" |
| J+18 | 2ème échéance due | `IMPAYE_2` | Tentative + notification urgente |
| J+21 | Échec confirmé | `IMPAYE_2` | Relances quotidiennes |
| J+33 | Suspension | `SUSPENDU` | Blocage immédiat + notification |
| J+63 | Résiliation | `RESILIE` | Fin de contrat + notification |

---

## 4. Impacts fonctionnels de la suspension

### 4.1 Tableau des accès par état

| Fonctionnalité | ACTIVE | IMPAYE_1 | IMPAYE_2 | SUSPENDU | RESILIE |
|----------------|--------|----------|----------|----------|---------|
| **Back-office admin** | ✅ | ✅ | ✅ | ❌ | ❌ |
| **Création de membres** | ✅ | ✅ | ⚠️ Limité | ❌ | ❌ |
| **Envoi de notifications** | ✅ | ✅ | ⚠️ Limité | ❌ | ❌ |
| **Gestion des événements** | ✅ | ✅ | ✅ | ❌ | ❌ |
| **App membres** | ✅ | ✅ | ✅ | ❌ | ❌ |
| **Cartes membres** | ✅ | ✅ | ✅ | ❌ | ❌ |
| **Scan QR codes** | ✅ | ✅ | ✅ | ❌ | ❌ |
| **Téléchargement données** | ✅ | ✅ | ✅ | ⚠️ Sur demande | ⚠️ Sur demande |
| **Modification des données** | ✅ | ✅ | ✅ | ❌ | ❌ |

### 4.2 Détail de la suspension

**Ce qui est BLOQUÉ :**
- Connexion au back-office (page de blocage avec message)
- Accès à l'app membres pour tous les membres
- Validation des cartes membres (QR code renvoie "Compte suspendu")
- Envoi d'emails transactionnels
- Création de nouveaux contenus

**Ce qui est CONSERVÉ :**
- Toutes les données (membres, événements, historique)
- Configuration de la communauté
- Historique des paiements
- Possibilité de régularisation

**Message affiché aux admins :**
> "Votre compte est actuellement suspendu en raison d'un impayé. Veuillez régulariser votre situation pour retrouver l'accès à vos services. [Bouton: Régulariser maintenant]"

**Message affiché aux membres :**
> "L'accès à [Nom de la communauté] est temporairement indisponible. Veuillez contacter votre administrateur."

---

## 5. Notifications obligatoires

### 5.1 Types de notifications

| Notification | Destinataire | Moment | Canal |
|--------------|--------------|--------|-------|
| **Échéance à venir** | Admin principal | J-7 avant échéance | Email |
| **Paiement échoué** | Admin principal + contacts facturation | J+0 après échec | Email |
| **Passage en IMPAYE_1** | Admin principal + contacts facturation | J+3 | Email |
| **Rappel IMPAYE_1** | Admin principal | J+7, J+14 | Email |
| **Passage en IMPAYE_2** | Tous les admins | J+18 | Email |
| **Alerte suspension imminente** | Tous les admins | J+30, J+31, J+32 | Email + SMS (si disponible) |
| **Suspension effective** | Tous les admins | J+33 | Email |
| **Rappel compte suspendu** | Admin principal | Hebdomadaire | Email |
| **Résiliation** | Tous les admins | J+63 | Email + courrier recommandé |

### 5.2 Contenu des notifications

#### Notification de paiement échoué

**Objet :** Échec de paiement - Action requise

**Contenu :**
```
Bonjour [Prénom],

Le paiement de votre abonnement Koomy a échoué.

Montant dû : [XXX] €
Date d'échéance : [Date]
Raison : [Provision insuffisante / Carte expirée / ...]

Pour éviter toute interruption de service, veuillez mettre à jour 
vos informations de paiement :

[BOUTON : Régulariser maintenant]

Vous disposez de 15 jours pour régulariser votre situation.

L'équipe Koomy
```

#### Notification de suspension imminente

**Objet :** URGENT - Suspension de votre compte Koomy dans 3 jours

**Contenu :**
```
Bonjour [Prénom],

Malgré nos relances, votre compte présente toujours un impayé.

Montant dû : [XXX] €
Échéances concernées : [Dates]

⚠️ Sans régularisation sous 3 jours, votre compte sera suspendu :
- Vos administrateurs perdront l'accès au back-office
- Vos membres ne pourront plus accéder à l'application
- Les cartes membres seront désactivées

[BOUTON : Régulariser maintenant]

Besoin d'aide ? Contactez-nous : support@koomy.app

L'équipe Koomy
```

#### Notification de suspension effective

**Objet :** Compte Koomy suspendu - [Nom de la communauté]

**Contenu :**
```
Bonjour [Prénom],

Votre compte Koomy est désormais suspendu.

Montant dû : [XXX] €

Ce que cela signifie :
❌ Accès au back-office bloqué
❌ Application membres désactivée
❌ Cartes membres inactives

Vos données sont conservées et votre compte peut être réactivé 
à tout moment en régularisant votre situation.

[BOUTON : Régulariser et réactiver]

Sans régularisation sous 30 jours, votre compte sera résilié.

L'équipe Koomy
```

---

## 6. Cas limites et règles produit

### 6.1 Paiement reçu après suspension

**Scénario :** Le client paie alors que son compte est suspendu.

**Règle produit :**
1. Validation du paiement (automatique si carte/SEPA)
2. Vérification que le montant couvre TOUTES les échéances dues
3. Si paiement complet : réactivation immédiate → `ACTIVE`
4. Si paiement partiel : voir cas 6.2
5. Notification de réactivation envoyée
6. Membres retrouvent l'accès immédiatement

**Délai de réactivation :** < 15 minutes après validation du paiement

### 6.2 Paiement partiel

**Scénario :** Le client paie une partie seulement du montant dû.

**Règle produit :**
- ❌ Pas de réactivation avec paiement partiel
- Le montant partiel est crédité sur le compte
- Notification : "Paiement reçu - Solde restant : [XXX] €"
- Le compte reste dans son état actuel jusqu'à régularisation complète

**Raison :** Éviter les abus (payer 1€ pour réactiver temporairement)

### 6.3 Carte bancaire expirée

**Scénario :** La carte enregistrée expire avant l'échéance.

**Règle produit :**
1. Notification J-30 : "Votre carte expire bientôt"
2. Notification J-7 : "Mettez à jour votre moyen de paiement"
3. Si carte non mise à jour : échec de paiement → processus standard

**Important :** Le client peut mettre à jour sa carte à tout moment dans le back-office.

### 6.4 Échecs répétés de prélèvement

**Scénario :** Plusieurs tentatives de prélèvement échouent (solde insuffisant récurrent).

**Règle produit :**
- Tentative 1 : J+0
- Tentative 2 : J+3
- Tentative 3 : J+7
- Après 3 tentatives échouées : passage en `IMPAYE_1`
- Le client est invité à payer manuellement

### 6.5 Résiliation puis tentative de connexion

**Scénario :** Un admin essaie de se connecter après résiliation.

**Règle produit :**
1. Affichage d'une page dédiée "Compte résilié"
2. Message : "Votre compte a été résilié le [Date]. Pour réactiver votre compte, veuillez nous contacter."
3. Lien vers le support
4. Possibilité de télécharger ses données (RGPD)

**Aucune possibilité de réactivation automatique** après résiliation.

### 6.6 Conservation des données après résiliation

**Règle produit :**
| Type de données | Durée de conservation | Raison |
|-----------------|----------------------|--------|
| Données comptables | 10 ans | Obligations légales |
| Données membres | 3 ans | RGPD + contentieux éventuel |
| Logs d'activité | 1 an | Sécurité |
| Contenu (événements, news) | 3 ans | Contentieux éventuel |

**Suppression définitive :**
- Sur demande explicite du client
- Après expiration des délais légaux
- Processus manuel avec validation

### 6.7 Changement de plan pendant impayé

**Scénario :** Le client veut changer de plan alors qu'il est en impayé.

**Règle produit :**
- ❌ Impossible de changer de plan si impayé
- Le client doit d'abord régulariser
- Message : "Veuillez régulariser votre situation avant de modifier votre abonnement"

### 6.8 Annulation avant la première échéance

**Scénario :** Le client annule son abonnement avant le premier paiement mensuel.

**Règle produit :**
- Le client peut annuler à tout moment
- Accès maintenu jusqu'à la fin de la période payée
- Aucun remboursement prorata (sauf disposition légale)
- Données conservées selon les règles RGPD

---

## 7. Cohérence CGV

### 7.1 Points à intégrer dans les CGV

| Sujet | Clause à prévoir |
|-------|------------------|
| Facturation | Facturation mensuelle/annuelle, à date anniversaire |
| Moyens de paiement | Carte bancaire, SEPA uniquement |
| Retard de paiement | Pénalités de retard (taux légal + 40€ forfaitaire) |
| Suspension | Droit de suspension après 2 échéances impayées |
| Résiliation | Résiliation automatique après 3 échéances impayées |
| Données | Conservation 3 ans minimum, export sur demande |
| Réactivation | Possible après régularisation complète (sauf résiliation) |

### 7.2 Clauses types suggérées

**Clause de suspension :**
> "En cas de défaut de paiement de deux échéances consécutives, Koomy se réserve le droit de suspendre l'accès aux Services après mise en demeure restée infructueuse pendant 15 jours. La suspension prendra effet de plein droit, sans préjudice des sommes dues."

**Clause de résiliation pour impayé :**
> "Le contrat pourra être résilié de plein droit par Koomy en cas de défaut de paiement de trois échéances consécutives, après notification par email adressée au Client. La résiliation n'exonère pas le Client du paiement des sommes dues."

**Clause de conservation des données :**
> "En cas de résiliation, les données du Client seront conservées pendant une durée de trois (3) ans, conformément aux obligations légales et réglementaires. Le Client pourra demander l'export de ses données dans un délai de 30 jours suivant la résiliation."

---

## Annexe : Tableau récapitulatif

| Événement | Délai | Action Koomy | Action Client requise |
|-----------|-------|--------------|----------------------|
| Échéance due | J+0 | Tentative de prélèvement | - |
| Échec 1ère tentative | J+3 | Nouvelle tentative | Vérifier compte/carte |
| Passage IMPAYE_1 | J+3 | Notification + bandeau | Payer sous 15 jours |
| Rappel | J+7 | Email relance | Payer |
| Dernier rappel | J+14 | Email "Dernière chance" | Payer |
| Passage IMPAYE_2 | J+18 | Notification urgente | Payer sous 15 jours |
| Alertes quotidiennes | J+30 à J+32 | Email + SMS | Payer immédiatement |
| Suspension | J+33 | Blocage compte | Payer pour réactiver |
| Rappels hebdo | J+40, J+47, J+54 | Email | Payer |
| Résiliation | J+63 | Fin de contrat | Contact support si besoin |

---

*Document produit établi le 2026-01-12.*  
*Ce document sert de référence pour l'implémentation technique et la rédaction des CGV.*
