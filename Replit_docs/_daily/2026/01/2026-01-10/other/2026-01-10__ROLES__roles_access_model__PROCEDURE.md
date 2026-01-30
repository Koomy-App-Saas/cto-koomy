# 🧭 KOOMY — Roles & Access Model

## 1. Objectif du document

Ce document définit **le modèle officiel de rôles, responsabilités et accès** dans l’écosystème **Koomy**.

Objectifs :
- Garantir une **clarté absolue des responsabilités**
- Éviter toute dérive de permissions
- Sécuriser la facturation, les données et les actions sensibles
- Préparer l’arrivée d’équipes sans dette organisationnelle

> ⚠️ Un rôle flou est une faille de sécurité.

---

## 2. Principes fondateurs

1. **Un compte = un rôle principal**
2. **Un admin = un seul club**
3. **Pas de multi-club implicite**
4. **Les rôles techniques ≠ rôles métier**
5. **Les permissions sont explicites, jamais déduites**

Tout ce qui n’est pas explicitement autorisé est interdit.

---

## 3. Typologie des rôles

### 3.1 Super Admin Platform (Koomy)

**Rôle :** Fondateur / CTO

**Périmètre :** Plateforme Koomy entière

**Accès :**
- Gestion des environnements (PROD / SANDBOX)
- Accès DB (lecture / écriture encadrée)
- Configuration Stripe globale
- Accès aux logs, audits, incidents
- Activation / suspension de clubs

**Restrictions :**
- N’utilise jamais l’interface club
- N’intervient pas dans la gestion quotidienne des clubs

---

### 3.2 Admin Club

**Rôle :** Responsable d’un club / organisation

**Principe clé :**
> **1 admin = 1 club = 1 back-office**

**Accès :**
- Backoffice du club
- Gestion des membres
- Gestion des événements
- Paramétrage du club

**Restrictions :**
- ❌ Aucun accès à d’autres clubs
- ❌ Aucun accès plateforme
- ❌ Aucun accès à la facturation globale Koomy

➡️ Pour gérer un autre club, un **autre compte email est requis**.

---

### 3.3 Membre / Utilisateur

**Rôle :** Utilisateur final

**Accès :**
- Wallet Koomy
- Consultation de ses cartes d’adhésion
- Accès aux événements du club

**Restrictions :**
- Aucun accès admin
- Aucune visibilité sur d’autres membres

---

### 3.4 Comptes techniques (internes)

**Rôle :** Outils / intégrations

Exemples :
- Webhooks Stripe
- CRON
- Scripts internes

**Accès :**
- Limité par token
- Permissions minimales

**Restrictions :**
- Pas de login interactif
- Pas d’accès UI

---

## 4. Cas spécifique : Applications en marque blanche

Pour les apps **white-label** :

- ❌ Aucun accès multi-club
- ❌ Aucun wallet global
- ❌ Aucun hub de clubs

Le comportement est **monoclub par design**.

---

## 5. Gestion des permissions

### 5.1 Modèle

- Permissions définies par rôle
- Pas d’héritage implicite
- Pas de permissions dynamiques non traçables

---

### 5.2 Actions sensibles

Actions nécessitant validation explicite :
- Suppression massive
- Suspension de club
- Actions de facturation
- Exécution de scripts

---

## 6. Authentification & sessions

- Session liée à un **contexte unique** (club ou plateforme)
- Pas de changement de contexte implicite
- Déconnexion obligatoire pour changer de rôle

---

## 7. Anti-patterns interdits

- ❌ Admin qui bascule entre clubs
- ❌ Permissions accordées “temporairement” sans trace
- ❌ Comptes partagés
- ❌ Rôles techniques utilisés par des humains

---

## 8. Audit & traçabilité

Chaque action sensible doit être :
- loggée
- attribuée à un rôle clair
- horodatée

---

## 9. Évolution des rôles

Toute création ou modification de rôle :
- nécessite validation CTO
- doit être documentée
- doit respecter ce modèle

---

## 10. Principe fondateur

> **La simplicité des rôles protège la plateforme.**

Un modèle strict aujourd’hui évite :
- des refontes coûteuses
- des failles futures
- des conflits de responsabilité

