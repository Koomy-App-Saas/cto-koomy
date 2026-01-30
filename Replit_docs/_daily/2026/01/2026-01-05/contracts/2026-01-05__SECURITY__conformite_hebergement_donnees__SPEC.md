# Document de Conformité - Hébergement des Données

**Plateforme :** Koomy  
**Version :** 1.0  
**Date de mise à jour :** 15 décembre 2024  
**Responsable :** Koomy SAS

---

## 1. Introduction

Ce document décrit les mesures techniques et organisationnelles mises en place par Koomy pour assurer la conformité de l'hébergement des données personnelles avec le Règlement Général sur la Protection des Données (RGPD - Règlement UE 2016/679).

---

## 2. Localisation des Données

### 2.1 Infrastructure d'Hébergement

| Composant | Fournisseur | Localisation | Certification |
|-----------|-------------|--------------|---------------|
| Base de données PostgreSQL | Neon | EU-Central-1 (Francfort, Allemagne) | SOC 2 Type II, ISO 27001 |
| Stockage objets | Google Cloud Storage | Europe (eu) | ISO 27001, SOC 2/3 |
| Application Web | Replit | États-Unis* | SOC 2 Type II |

*Note : L'application web est hébergée aux États-Unis mais ne stocke aucune donnée personnelle persistante. Toutes les données personnelles sont stockées exclusivement dans l'Union Européenne.

### 2.2 Garanties de Localisation

- **Base de données principale** : Hébergée exclusivement dans le datacenter AWS de Francfort (eu-central-1), Allemagne
- **Sauvegardes** : Répliquées au sein de l'Union Européenne uniquement
- **Aucun transfert hors UE** : Les données personnelles des utilisateurs européens ne quittent jamais le territoire de l'Union Européenne

---

## 3. Types de Données Hébergées

### 3.1 Données des Comptes Utilisateurs

| Catégorie | Données | Base légale |
|-----------|---------|-------------|
| Identification | Nom, prénom, email | Exécution du contrat |
| Authentification | Hash du mot de passe (bcrypt) | Exécution du contrat |
| Profil | Photo de profil, date de naissance | Consentement |
| Contact | Téléphone, adresse | Consentement |

### 3.2 Données des Adhésions

| Catégorie | Données | Base légale |
|-----------|---------|-------------|
| Appartenance | ID communauté, rôle, statut | Exécution du contrat |
| Historique | Date d'adhésion, renouvellements | Intérêt légitime |
| Paiements | Montants, dates, références Stripe | Obligation légale |

### 3.3 Données des Communautés

| Catégorie | Données | Base légale |
|-----------|---------|-------------|
| Organisation | Nom, type, description | Exécution du contrat |
| Contact | Email, téléphone, adresse | Exécution du contrat |
| Configuration | Paramètres, branding | Exécution du contrat |

---

## 4. Mesures de Sécurité Techniques

### 4.1 Chiffrement

- **En transit** : TLS 1.3 pour toutes les communications
- **Au repos** : Chiffrement AES-256 des données sur disque
- **Mots de passe** : Hachage bcrypt avec salt (coût 10)

### 4.2 Contrôle d'Accès

- Authentification par session sécurisée
- Séparation des rôles (membre, admin, super-admin, plateforme)
- Isolation multi-tenant par `communityId`
- Protection CSRF et validation des entrées

### 4.3 Sauvegardes

- Sauvegardes automatiques quotidiennes
- Rétention : 7 jours (sauvegardes journalières), 4 semaines (hebdomadaires)
- Point-in-time recovery disponible
- Tests de restauration périodiques

---

## 5. Droits des Personnes Concernées

### 5.1 Droits Implémentés

| Droit | Implémentation | Délai |
|-------|----------------|-------|
| Accès (Art. 15) | Export des données depuis le profil | Immédiat |
| Rectification (Art. 16) | Modification depuis le profil | Immédiat |
| Effacement (Art. 17) | Suppression de compte avec confirmation | 30 jours max |
| Portabilité (Art. 20) | Export JSON/CSV des données | Immédiat |
| Opposition (Art. 21) | Désabonnement notifications | Immédiat |

### 5.2 Procédure de Suppression

1. L'utilisateur demande la suppression via son profil
2. Confirmation par email requise
3. Période de grâce de 14 jours (annulation possible)
4. Suppression définitive et irréversible après 30 jours
5. Logs d'audit conservés 1 an (obligation légale)

---

## 6. Sous-Traitants

### 6.1 Liste des Sous-Traitants

| Sous-traitant | Service | Localisation | DPA signé |
|---------------|---------|--------------|-----------|
| Neon Inc. | Base de données PostgreSQL | EU (Francfort) | ✅ Oui |
| Google Cloud | Stockage objets | EU | ✅ Oui |
| Stripe | Paiements | EU/US* | ✅ Oui |
| SendGrid (Twilio) | Emails transactionnels | US* | ✅ Oui |

*Transferts encadrés par les Clauses Contractuelles Types (CCT) de la Commission Européenne.

### 6.2 Garanties Contractuelles

Tous les sous-traitants ont signé un Data Processing Agreement (DPA) incluant :
- Clauses Contractuelles Types (CCT) pour les transferts hors UE
- Mesures techniques et organisationnelles appropriées
- Notification des violations dans les 48 heures
- Droit d'audit

---

## 7. Incidents et Violations

### 7.1 Procédure de Notification

En cas de violation de données personnelles :

1. **Détection** : Monitoring continu des accès et anomalies
2. **Évaluation** : Analyse de l'impact dans les 24 heures
3. **Notification CNIL** : Dans les 72 heures si risque pour les droits
4. **Notification utilisateurs** : Sans délai si risque élevé
5. **Documentation** : Registre des violations maintenu à jour

### 7.2 Contact DPO

Pour toute question relative à la protection des données :

- **Email** : dpo@koomy.app
- **Adresse** : [Adresse du siège social]

---

## 8. Audit et Certification

### 8.1 Audits Réguliers

- Audit de sécurité annuel par tiers indépendant
- Tests de pénétration semestriels
- Revue des accès trimestrielle
- Vérification des sauvegardes mensuelle

### 8.2 Certifications des Fournisseurs

| Fournisseur | Certifications |
|-------------|----------------|
| Neon | SOC 2 Type II, ISO 27001 |
| Google Cloud | ISO 27001, 27017, 27018, SOC 2/3 |
| Stripe | PCI-DSS Level 1, SOC 2 |

---

## 9. Historique des Modifications

| Date | Version | Modification |
|------|---------|--------------|
| 15/12/2024 | 1.0 | Création du document - Migration vers EU-Central-1 |

---

## 10. Annexes

### Annexe A : Schéma d'Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         UTILISATEURS                            │
│                    (Europe - Membres & Admins)                  │
└─────────────────────┬───────────────────────────────────────────┘
                      │ HTTPS/TLS 1.3
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                    APPLICATION KOOMY                            │
│                   (Frontend + API REST)                         │
└─────────────────────┬───────────────────────────────────────────┘
                      │
         ┌────────────┴────────────┐
         ▼                         ▼
┌─────────────────────┐   ┌─────────────────────┐
│   NEON POSTGRESQL   │   │  GOOGLE CLOUD       │
│   EU-Central-1      │   │  STORAGE (EU)       │
│   (Francfort, DE)   │   │                     │
│                     │   │  - Logos            │
│  - Comptes          │   │  - Photos profil    │
│  - Communautés      │   │  - Documents        │
│  - Adhésions        │   │                     │
│  - Transactions     │   │                     │
└─────────────────────┘   └─────────────────────┘
         │
         ▼
┌─────────────────────┐
│   SAUVEGARDES       │
│   (EU uniquement)   │
└─────────────────────┘
```

### Annexe B : Coordonnées

**Responsable du traitement :**  
Koomy SAS  
[Adresse]  
[SIRET]

**Délégué à la Protection des Données :**  
Email : dpo@koomy.app

**Autorité de contrôle :**  
CNIL - Commission Nationale de l'Informatique et des Libertés  
3 Place de Fontenoy, TSA 80715  
75334 Paris Cedex 07  
www.cnil.fr

---

*Document généré automatiquement. Dernière mise à jour : 15 décembre 2024*
