# KOOMY — PLAN D'IMPLÉMENTATION TECHNIQUE
## Paiement SaaS, impayés, suspension et résiliation des clients

**Version :** 1.1  
**Date :** 2026-01-12  
**Statut :** Plan technique — Validé pour implémentation  
**Conformité :** [Audit SaaS Clients](./audit-saas-clients-impayés.md) + [Addendum CGV](./addendum-saas-clients-cgv.md)

---

> **RÉFÉRENCE TEMPORELLE UNIQUE**  
> Toutes les transitions sont calculées **exclusivement** à partir de `unpaid_since` (date de la 1ère échéance impayée).  
> Aucune référence au nombre d'échéances Stripe ne doit être utilisée.

---

## Table des matières

1. [Modèle d'états du compte client](#1-modèle-détats-du-compte-client)
2. [Sources de vérité et déclencheurs](#2-sources-de-vérité-et-déclencheurs)
3. [Gestion temporelle](#3-gestion-temporelle)
4. [Impacts fonctionnels par état](#4-impacts-fonctionnels-par-état)
5. [Notifications email](#5-notifications-email)
6. [Cas limites techniques](#6-cas-limites-techniques)
7. [Sécurité, logs et traçabilité](#7-sécurité-logs-et-traçabilité)
8. [Stratégie de déploiement](#8-stratégie-de-déploiement)

---

## 1. Modèle d'états du compte client

### 1.1 Liste exhaustive des statuts

| Statut | Code DB | Période | Description |
|--------|---------|---------|-------------|
| Actif | `ACTIVE` | — | Compte opérationnel, paiements à jour |
| Impayé niveau 1 | `IMPAYE_1` | J+0 à J+15 | Impayé détecté, délai de grâce en cours |
| Impayé niveau 2 | `IMPAYE_2` | J+15 à J+30 | Délai de grâce expiré, avant suspension |
| Suspendu | `SUSPENDU` | À partir de J+30 | Compte gelé, accès bloqué |
| Résilié | `RESILIE` | À partir de J+60 | Contrat terminé |

> **J+X** = X jours après la date `unpaid_since` (date de la 1ère échéance impayée)

### 1.2 Enum Drizzle proposé

```
Enum: subscription_status_enum
Valeurs: 'ACTIVE', 'IMPAYE_1', 'IMPAYE_2', 'SUSPENDU', 'RESILIE'
```

### 1.3 Colonnes à ajouter sur la table `communities`

| Colonne | Type | Description |
|---------|------|-------------|
| `subscription_status` | enum | Statut actuel du compte |
| `subscription_status_changed_at` | timestamp | Date du dernier changement d'état |
| `unpaid_since` | timestamp | Date de la 1ère échéance impayée (null si à jour) |
| `suspended_at` | timestamp | Date de suspension (null si non suspendu) |
| `terminated_at` | timestamp | Date de résiliation (null si actif) |

### 1.4 Conditions d'entrée/sortie par état

> Toutes les références temporelles sont calculées depuis `unpaid_since`.

#### ACTIVE

| Entrée | Sortie |
|--------|--------|
| Souscription initiale réussie | Échéance impayée détectée → `IMPAYE_1` (J+0) |
| Paiement complet reçu (depuis tout état) | — |

#### IMPAYE_1 (J+0 à J+15)

| Entrée | Sortie |
|--------|--------|
| J+0 : Impayé détecté, `unpaid_since` = date échéance | Paiement complet reçu → `ACTIVE` |
| — | J+15 atteint sans paiement → `IMPAYE_2` |

#### IMPAYE_2 (J+15 à J+30)

| Entrée | Sortie |
|--------|--------|
| J+15 : Délai de grâce expiré | Paiement complet reçu → `ACTIVE` |
| — | J+30 atteint sans paiement → `SUSPENDU` |

#### SUSPENDU (J+30 à J+60)

| Entrée | Sortie |
|--------|--------|
| J+30 : Suspension effective | Paiement complet reçu → `ACTIVE` |
| — | J+60 atteint sans paiement → `RESILIE` |

#### RESILIE (à partir de J+60)

| Entrée | Sortie |
|--------|--------|
| J+60 : Résiliation automatique | Réactivation manuelle uniquement (admin plateforme) |
| Demande explicite du client | — |

### 1.5 Diagramme des transitions autorisées

```
                     ┌────────────────────────────────────────────┐
                     │                                            │
                     │              PAIEMENT REÇU                 │
                     │                                            │
                     ▼                                            │
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    │
│  ACTIVE  │───▶│ IMPAYE_1 │───▶│ IMPAYE_2 │───▶│ SUSPENDU │────┘
│          │    │          │    │          │    │          │
└──────────┘    └────┬─────┘    └────┬─────┘    └────┬─────┘
     ▲               │               │               │
     │               │ PAIEMENT      │ PAIEMENT      │ 30 JOURS
     │               │               │               │
     │               ▼               ▼               ▼
     │          ┌──────────┐    ┌──────────┐    ┌──────────┐
     └──────────│  ACTIVE  │    │  ACTIVE  │    │ RESILIE  │
                │ (retour) │    │ (retour) │    │          │
                └──────────┘    └──────────┘    └──────────┘
```

**Transitions interdites :**
- `ACTIVE` → `IMPAYE_2` (doit passer par `IMPAYE_1`)
- `ACTIVE` → `SUSPENDU` (doit passer par `IMPAYE_1` puis `IMPAYE_2`)
- `RESILIE` → `ACTIVE` (sauf intervention manuelle admin plateforme)
- `IMPAYE_1` → `SUSPENDU` (doit passer par `IMPAYE_2`)

---

## 2. Sources de vérité et déclencheurs

### 2.1 Source de vérité : Stripe

| Donnée | Source Stripe | Utilisation Koomy |
|--------|---------------|-------------------|
| Statut abonnement | `subscription.status` | Indicateur principal |
| Dernière facture | `invoice.status` | Détection impayé |
| Date prochaine échéance | `subscription.current_period_end` | Calcul des délais |
| Historique paiements | `invoices` | Audit trail |

**Principe fondamental :** Stripe est la source de vérité pour les paiements. Koomy réagit aux webhooks Stripe.

### 2.2 Webhooks Stripe à écouter

| Webhook | Action Koomy |
|---------|--------------|
| `invoice.payment_succeeded` | Retour à `ACTIVE` si impayé |
| `invoice.payment_failed` | Évaluer passage en `IMPAYE_1` ou `IMPAYE_2` |
| `customer.subscription.updated` | Sync statut |
| `customer.subscription.deleted` | Passage en `RESILIE` |
| `invoice.finalized` | Notification échéance à venir |

### 2.3 Déclencheurs de transition

> **Règle absolue :** Toutes les transitions sont calculées depuis `unpaid_since`.

| Transition | Déclencheur | Mécanique |
|------------|-------------|-----------|
| `ACTIVE` → `IMPAYE_1` | Webhook `invoice.payment_failed` | Immédiat (J+0), `unpaid_since` = date échéance |
| `IMPAYE_1` → `IMPAYE_2` | J+15 depuis `unpaid_since` | Job planifié quotidien |
| `IMPAYE_2` → `SUSPENDU` | J+30 depuis `unpaid_since` | Job planifié quotidien |
| `SUSPENDU` → `RESILIE` | J+60 depuis `unpaid_since` | Job planifié quotidien |
| `*` → `ACTIVE` | Webhook `invoice.payment_succeeded` (paiement complet) | Temps réel, `unpaid_since` = NULL |

### 2.4 Job planifié quotidien

**Nom :** `check-subscription-status`  
**Fréquence :** Tous les jours à 02:00 UTC  
**Actions :**

1. Récupérer toutes les communautés avec `unpaid_since IS NOT NULL`
2. Pour chaque communauté :
   - Calculer le nombre de jours depuis `unpaid_since`
   - Appliquer la transition appropriée
   - Envoyer les notifications correspondantes
   - Logger la transition

---

## 3. Gestion temporelle

### 3.1 Référence temporelle unique

> **`unpaid_since`** est la SEULE référence pour toutes les transitions.  
> Elle correspond à la date de l'échéance impayée (pas à la date de détection).

### 3.2 Calcul des délais

| État | Période | Calcul |
|------|---------|--------|
| `IMPAYE_1` | J+0 à J+15 | De `unpaid_since` à `unpaid_since` + 15 jours |
| `IMPAYE_2` | J+15 à J+30 | De `unpaid_since` + 15 jours à `unpaid_since` + 30 jours |
| `SUSPENDU` | J+30 à J+60 | De `unpaid_since` + 30 jours à `unpaid_since` + 60 jours |
| `RESILIE` | À partir de J+60 | À partir de `unpaid_since` + 60 jours |

### 3.3 Chronologie type

```
J+0   : Échéance due, tentative de prélèvement échouée
        → IMPAYE_1, unpaid_since = date de l'échéance
J+7   : Rappel email (E04)
J+14  : Dernier rappel email (E05)
J+15  : → IMPAYE_2
J+27  : Alerte J-3 avant suspension (E07)
J+28  : Alerte J-2 avant suspension (E08)
J+29  : Alerte J-1 avant suspension (E09)
J+30  : → SUSPENDU (E10)
J+37  : Rappel compte suspendu (E11)
J+44  : Rappel compte suspendu (E11)
J+51  : Rappel compte suspendu (E11)
J+53  : Alerte J-7 avant résiliation (E12)
J+60  : → RESILIE (E13)
```

> Les références J+X sont toujours calculées depuis `unpaid_since`.

### 3.4 Mécanique de non-restriction pour IMPAYE_2

**Règle produit :** `IMPAYE_2` n'applique AUCUNE restriction fonctionnelle (identique à `IMPAYE_1`).

**Implémentation :**

```
Fonction: hasFullAccess(community)
  SI community.subscription_status IN ('ACTIVE', 'IMPAYE_1', 'IMPAYE_2')
    RETOURNER true
  SINON
    RETOURNER false
```

**Seul `SUSPENDU` et `RESILIE` bloquent l'accès.**

---

## 4. Impacts fonctionnels par état

### 4.1 Matrice des accès

| Fonctionnalité | ACTIVE | IMPAYE_1 | IMPAYE_2 | SUSPENDU | RESILIE |
|----------------|--------|----------|----------|----------|---------|
| Connexion back-office | ✅ | ✅ | ✅ | ❌ | ❌ |
| API communauté | ✅ | ✅ | ✅ | ❌ | ❌ |
| App membres | ✅ | ✅ | ✅ | ❌ | ❌ |
| Cartes membres | ✅ | ✅ | ✅ | ❌ | ❌ |
| Création contenu | ✅ | ✅ | ✅ | ❌ | ❌ |
| Notifications sortantes | ✅ | ✅ | ✅ | ❌ | ❌ |
| Modification paramètres | ✅ | ✅ | ✅ | ❌ | ❌ |
| **Export données** | ✅ | ✅ | ✅ | ✅ | ✅ |
| Bandeau d'alerte | ❌ | ✅ | ✅ | N/A | N/A |

### 4.2 Export des données (SUSPENDU et RESILIE)

> **Règle produit :** L'export des données est **AUTORISÉ** même en état `SUSPENDU` ou `RESILIE`.

| Aspect | Règle |
|--------|-------|
| **Accès** | ✅ Autorisé |
| **Mode** | Lecture seule uniquement |
| **Génération dynamique** | ❌ Interdite |
| **Modification** | ❌ Interdite |
| **Objectif** | Conformité légale (RGPD), réduction des litiges |

**Fonctionnalités d'export autorisées :**
- Téléchargement de la liste des membres (CSV/Excel)
- Téléchargement de l'historique des événements
- Téléchargement des données de la communauté
- Téléchargement des factures

**Fonctionnalités d'export INTERDITES :**
- Génération de nouveaux rapports
- Export de données nécessitant un traitement temps réel
- Toute action modifiant les données

### 4.3 Affichage côté utilisateur

#### Bandeau d'alerte (IMPAYE_1 et IMPAYE_2)

**Couleur :** Orange pour `IMPAYE_1`, Rouge pour `IMPAYE_2`

**Texte IMPAYE_1 :**
> "Votre paiement est en retard. Régularisez votre situation pour éviter toute interruption de service. [Bouton: Payer maintenant]"

**Texte IMPAYE_2 :**
> "URGENT : Votre compte sera suspendu dans X jours. Régularisez immédiatement. [Bouton: Payer maintenant]"

#### Page de blocage (SUSPENDU)

**Message admin :**
> "Votre compte Koomy est suspendu en raison d'un impayé de [MONTANT] €. Régularisez votre situation pour retrouver l'accès à vos services."
>
> [Bouton principal: Régulariser maintenant]
> [Lien secondaire: Contacter le support]

**Message membres :**
> "L'accès à [Nom communauté] est temporairement indisponible. Veuillez contacter votre administrateur."

#### Page de fin (RESILIE)

**Message admin :**
> "Votre compte Koomy a été résilié le [DATE]. Pour réactiver votre compte, veuillez contacter notre équipe."
>
> [Bouton: Contacter le support]
> [Lien: Télécharger mes données]

### 4.4 Middleware de vérification

**Point d'injection :** Toutes les routes API communautaires

```
Middleware: checkCommunityAccess(communityId)
  community = getCommunity(communityId)
  
  SI community.subscription_status == 'SUSPENDU'
    RETOURNER 403 { error: "ACCOUNT_SUSPENDED", message: "..." }
  
  SI community.subscription_status == 'RESILIE'
    RETOURNER 403 { error: "ACCOUNT_TERMINATED", message: "..." }
  
  CONTINUER
```

---

## 5. Notifications email

### 5.1 Liste exhaustive des emails

| ID | Nom | Déclencheur | Destinataires |
|----|-----|-------------|---------------|
| `E01` | Échéance à venir | J-7 avant échéance | Admin principal |
| `E02` | Paiement échoué | Webhook payment_failed | Admin principal + contacts facturation |
| `E03` | Passage IMPAYE_1 | Transition vers IMPAYE_1 | Admin principal + contacts facturation |
| `E04` | Rappel 1 | J+7 en IMPAYE_1 | Admin principal |
| `E05` | Rappel 2 (dernier) | J+14 en IMPAYE_1 | Admin principal |
| `E06` | Passage IMPAYE_2 | Transition vers IMPAYE_2 | Tous les admins |
| `E07` | Alerte J-3 | J+27 (3j avant suspension) | Tous les admins |
| `E08` | Alerte J-2 | J+28 | Tous les admins |
| `E09` | Alerte J-1 | J+29 | Tous les admins |
| `E10` | Suspension effective | Transition vers SUSPENDU | Tous les admins |
| `E11` | Rappel suspendu | Hebdomadaire en SUSPENDU | Admin principal |
| `E12` | Alerte résiliation | J-7 avant résiliation | Tous les admins |
| `E13` | Résiliation effective | Transition vers RESILIE | Tous les admins |

### 5.2 Contenu des emails

#### E03 — Passage IMPAYE_1

**Objet :** Action requise — Paiement en retard pour [Nom communauté]

**Corps :**
```
Bonjour [Prénom],

Le paiement de votre abonnement Koomy a échoué.

Communauté : [Nom communauté]
Montant dû : [Montant] €
Date d'échéance : [Date]

Pour éviter toute interruption de service, veuillez régulariser 
votre situation dans les 15 prochains jours.

[BOUTON : Régulariser maintenant]

Besoin d'aide ? Répondez à cet email.

L'équipe Koomy
```

#### E07/E08/E09 — Alertes J-3/J-2/J-1

**Objet :** URGENT — Suspension de votre compte dans [X] jour(s)

**Corps :**
```
Bonjour [Prénom],

Votre compte Koomy sera suspendu dans [X] jour(s).

Montant dû : [Montant] €
Échéances concernées : [Dates]

Une suspension entraînera :
❌ Perte d'accès au back-office
❌ Désactivation de l'application pour vos membres
❌ Cartes membres inactives

[BOUTON : Régulariser maintenant pour éviter la suspension]

L'équipe Koomy
```

#### E10 — Suspension effective

**Objet :** Compte Koomy suspendu — [Nom communauté]

**Corps :**
```
Bonjour [Prénom],

Votre compte Koomy est désormais suspendu.

Montant dû : [Montant] €

Ce qui se passe maintenant :
❌ Vous ne pouvez plus accéder au back-office
❌ Vos membres ne peuvent plus utiliser l'application
❌ Les cartes membres sont désactivées

Vos données sont conservées. Régularisez votre situation 
pour réactiver votre compte immédiatement.

[BOUTON : Régulariser et réactiver]

Sans régularisation sous 30 jours, votre compte sera résilié.

L'équipe Koomy
```

### 5.3 Prévention des doublons

| Règle | Implémentation |
|-------|----------------|
| Un seul email par transition | Vérifier `subscription_status_changed_at` avant envoi |
| Pas de rappel si déjà payé | Vérifier statut Stripe avant envoi programmé |
| Espacement minimum | 24h entre deux emails au même destinataire |

**Table de tracking :**

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | serial | PK |
| `community_id` | integer | FK vers communities |
| `email_type` | varchar | Code email (E01, E02...) |
| `sent_at` | timestamp | Date d'envoi |
| `recipient_email` | varchar | Destinataire |

---

## 6. Cas limites techniques

### 6.1 Paiement reçu juste avant suspension

**Scénario :** Le paiement est validé à J+29.5, le job de suspension tourne à J+30.

**Règle technique :**
1. Le webhook `invoice.payment_succeeded` arrive
2. Le statut passe immédiatement à `ACTIVE`
3. `unpaid_since` est mis à NULL
4. Le job quotidien vérifie `subscription_status` avant toute action
5. Aucune suspension n'est appliquée

**Séquence :**
```
1. Webhook reçu → UPDATE communities SET subscription_status = 'ACTIVE', unpaid_since = NULL
2. Job quotidien → SELECT ... WHERE subscription_status IN ('IMPAYE_1', 'IMPAYE_2')
3. Communauté non sélectionnée car déjà ACTIVE
```

### 6.2 Paiement reçu juste après suspension

**Scénario :** Le compte est suspendu à J+30, le paiement arrive à J+30.5.

**Règle technique :**
1. Le webhook `invoice.payment_succeeded` arrive
2. Vérification que le paiement couvre TOUTES les échéances dues
3. Si paiement complet : statut → `ACTIVE`
4. Notification de réactivation envoyée
5. Accès restauré immédiatement

**Délai de réactivation :** < 15 minutes après réception du webhook

### 6.3 Paiement partiel

**Scénario :** Le client doit 200€ (2 échéances) et paie 100€.

**Règle technique :**
1. Le paiement partiel est crédité sur le compte Stripe
2. La facture reste `open` ou `partially_paid`
3. Aucun changement de statut Koomy
4. Notification : "Paiement reçu — Solde restant : 100€"
5. Le compte reste dans son état actuel

**Vérification :**
```
SI invoice.amount_paid < invoice.amount_due
  NE PAS changer le statut
  Envoyer notification "paiement partiel"
```

### 6.4 Carte expirée

**Scénario :** La carte enregistrée expire avant la prochaine échéance.

**Mécanique :**
1. Stripe envoie `customer.source.expiring` (J-30)
2. Koomy envoie notification "Mettez à jour votre carte"
3. Si non mise à jour : échec de paiement → processus standard

**Notifications :**
- J-30 : "Votre carte expire bientôt"
- J-7 : "Dernière chance de mettre à jour votre carte"

### 6.5 Client suspendu qui tente de se connecter

**Mécanique :**
1. L'utilisateur s'authentifie (succès)
2. Récupération de sa communauté
3. Vérification `subscription_status`
4. Si `SUSPENDU` : redirection vers page de blocage
5. La page affiche le montant dû et le bouton de paiement

**Routes accessibles même si suspendu :**
- `/billing` (pour régulariser)
- `/export` (pour récupérer ses données)
- `/support` (pour contacter le support)

### 6.6 Client résilié qui tente de se connecter

**Mécanique :**
1. L'utilisateur s'authentifie (succès)
2. Récupération de sa communauté
3. Vérification `subscription_status`
4. Si `RESILIE` : redirection vers page de fin
5. La page propose de contacter le support ou télécharger les données

**Aucune réactivation automatique possible.** Nouvelle souscription requise.

---

## 7. Sécurité, logs et traçabilité

### 7.1 Table d'audit des transitions

**Nom :** `subscription_status_audit`

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | serial | PK |
| `community_id` | integer | FK vers communities |
| `previous_status` | enum | Statut avant transition |
| `new_status` | enum | Statut après transition |
| `transition_reason` | varchar | Raison (PAYMENT_FAILED, PAYMENT_RECEIVED, DELAY_EXPIRED, MANUAL) |
| `triggered_by` | varchar | 'SYSTEM', 'WEBHOOK', 'ADMIN' |
| `stripe_event_id` | varchar | ID de l'événement Stripe (si applicable) |
| `created_at` | timestamp | Horodatage |
| `metadata` | jsonb | Données supplémentaires |

### 7.2 Logs obligatoires

| Événement | Données loggées |
|-----------|-----------------|
| Transition de statut | community_id, previous_status, new_status, reason, timestamp |
| Envoi de notification | community_id, email_type, recipient, timestamp |
| Tentative de paiement | community_id, amount, status, stripe_invoice_id |
| Accès bloqué | community_id, user_id, route_attempted, timestamp |

### 7.3 Rétention des logs

| Type | Durée de rétention |
|------|-------------------|
| Logs de transition | 3 ans (légal) |
| Logs de notification | 1 an |
| Logs de paiement | 10 ans (comptable) |
| Logs d'accès | 1 an |

### 7.4 Accès aux logs

| Rôle | Accès |
|------|-------|
| Support Koomy | Lecture seule, filtré par communauté |
| Admin plateforme | Lecture complète |
| Juridique | Export sur demande |

---

## 8. Stratégie de déploiement

### 8.1 Feature flag

**Nom :** `FEATURE_SUBSCRIPTION_STATUS_V2`

**Valeurs :**
- `disabled` : Ancien système (pas de gestion des impayés)
- `shadow` : Nouveau système en parallèle, sans blocage réel
- `enabled` : Nouveau système actif

### 8.2 Plan de déploiement

| Phase | Durée | Actions |
|-------|-------|---------|
| **Phase 1 : Shadow mode** | 2 semaines | Déploiement avec flag `shadow`. Les transitions sont calculées et loggées mais aucun blocage n'est appliqué. Vérification manuelle des calculs. |
| **Phase 2 : Beta** | 2 semaines | Activation sur 10% des nouvelles communautés. Monitoring intensif. |
| **Phase 3 : Rollout progressif** | 4 semaines | 25% → 50% → 75% → 100% des nouvelles communautés. |
| **Phase 4 : Migration** | 4 semaines | Application aux communautés existantes. Synchronisation des statuts avec Stripe. |

### 8.3 Rétrocompatibilité

**Communautés existantes avec impayé :**
1. Récupérer l'historique des factures Stripe
2. Calculer `unpaid_since` basé sur la 1ère facture impayée
3. Appliquer le statut correspondant
4. Envoyer une notification "Nouvelle politique de facturation"

**Communautés existantes à jour :**
1. Statut = `ACTIVE`
2. `unpaid_since` = NULL
3. Aucune notification

### 8.4 Rollback

**Déclencheurs de rollback :**
- Taux de faux positifs > 1%
- Plaintes client > 5 par jour
- Bug critique identifié

**Procédure :**
1. Passer le feature flag à `disabled`
2. Restaurer les accès bloqués à tort
3. Envoyer des excuses aux clients impactés
4. Analyser et corriger

**Temps de rollback :** < 5 minutes (changement de configuration)

### 8.5 Monitoring

| Métrique | Seuil d'alerte |
|----------|----------------|
| Transitions vers SUSPENDU | > 10/jour → notification équipe |
| Paiements après suspension | < 50% → revoir les notifications |
| Erreurs webhook | > 1% → investigation |
| Temps de réactivation | > 30 minutes → bug |

---

## Annexe : Checklist d'implémentation

### Backend

- [ ] Créer enum `subscription_status_enum`
- [ ] Ajouter colonnes à `communities`
- [ ] Créer table `subscription_status_audit`
- [ ] Créer table `subscription_emails_sent`
- [ ] Implémenter middleware `checkCommunityAccess`
- [ ] Configurer webhooks Stripe
- [ ] Implémenter job quotidien `check-subscription-status`
- [ ] Implémenter envoi des notifications
- [ ] Ajouter routes `/billing`, `/export`

### Frontend

- [ ] Composant bandeau d'alerte impayé
- [ ] Page de blocage (suspendu)
- [ ] Page de fin (résilié)
- [ ] Intégration Stripe Checkout pour régularisation

### Ops

- [ ] Configurer feature flag
- [ ] Configurer alertes monitoring
- [ ] Documenter procédure de rollback
- [ ] Former le support client

---

*Document technique établi le 2026-01-12.*  
*Strictement conforme à l'audit produit et à l'addendum contractuel.*
