# CONTRAT FINAL — IDENTITE & ONBOARDING KOOMY
**Version figee — janvier 2026**

Ce document definit de maniere **definitive et non interpretable** les regles d'identite, d'authentification et d'onboarding dans Koomy, en distinguant strictement :
- les communautes **standard (self-service)**,
- les clients **White-Label / Grand Compte (WL)**,
- la **SaaS Owner Platform**.

Aucune implementation ne doit s'en ecarter sans mise a jour explicite de ce contrat.

---

## 1. Principes fondamentaux (invariants globaux)

1. Koomy est une plateforme **multi-tenant** avec **plusieurs modes d'authentification**.
2. **Firebase Auth n'est PAS universel** dans Koomy.
3. Le mode d'authentification depend **du type de communaute (tenant)**.
4. Aucun flux WL ne doit dependre de Firebase, directement ou indirectement.
5. Toute ambiguite entre "standard" et "WL" est consideree comme un **bug d'architecture**.

---

## 2. Typologie des parcours (separation stricte)

### 2.1 SaaS Owner Platform (KOOMY interne)
- Role: operateur de la plateforme
- Authentification: **LEGACY KOOMY uniquement**
- Firebase: ❌ **INTERDIT**
- Responsabilites:
  - creation des clients WL
  - configuration des contrats WL
  - provisioning des communautes WL
- Hors scope:
  - onboarding self-service
  - `/api/admin/register`

---

### 2.2 Communautes STANDARD (Self-Service)

#### a) Acteurs
- Admin communaute standard
- Membres communaute standard

#### b) Authentification
- **Firebase Auth obligatoire**
  - provider possible: `firebase:google`
  - provider possible: `firebase:password`
- Legacy KOOMY: ❌ interdit

#### c) Onboarding
- Entree: **site public**
- Endpoint: `/api/admin/register`
- Creation automatique:
  - account
  - user
  - community
  - lien OWNER
  - etat de souscription

#### d) Modele economique
- Essai gratuit: **14 jours**
- Carte bancaire: ❌ non demandee a l'inscription
- Stripe: ❌ non declenche a l'inscription
- Statut initial: `subscription_status = trialing`

---

### 2.3 Clients WHITE-LABEL / GRAND COMPTE (WL)

> ⚠️ **CETTE SECTION EST CRITIQUE ET PRIORITAIRE**

#### a) Acteurs
- Client WL (entite B2B)
- Admins WL
- Membres WL

#### b) Authentification (regle absolue)
- **Firebase Auth = STRICTEMENT INTERDIT**
- Admins WL: **LEGACY KOOMY uniquement**
- Membres WL: **LEGACY KOOMY uniquement**
- Aucun compte WL (admin ou membre) ne doit posseder ou dependre d'un `firebase_uid`.

👉 Cette regle est confirmee par la realite production actuelle (client WL en prod).

---

#### c) Onboarding WL
- **Jamais via site public**
- **Jamais via `/api/admin/register`**
- Creation exclusivement depuis:
  - SaaS Owner Platform
  - action manuelle / contractuelle

#### d) Creation cote DB (contrat)
Lors de la creation d'un client WL:

1. Creation d'un **account WL**
   - type: `white_label`
   - email B2B de reference

2. Creation d'une ou plusieurs **communautes WL**
   - `is_white_label = true`
   - liees a l'account WL

3. Creation des **admins WL**
   - auth legacy
   - roles explicites

4. Membres WL
   - auth legacy
   - jamais Firebase

---

#### e) Modele economique WL
- ❌ Pas de trial self-service
- ❌ Pas de Stripe Checkout
- ❌ Pas d'inscription libre
- Contrat B2B:
  - setup fee
  - maintenance annuelle
  - volume membres inclus
- Stripe (si utilise):
  - hors onboarding
  - facturation contractuelle

---

## 3. Invariant technique cle (non negociable)

```
IF community.is_white_label = true
THEN auth_mode = LEGACY_ONLY
AND firebase_auth = FORBIDDEN

IF community.is_white_label = false
THEN auth_mode = FIREBASE_ONLY
```

Il ne doit exister aucun fallback, aucune detection implicite, aucune exception silencieuse.

---

## 4. Interdictions explicites (anti-patterns)

Il est formellement interdit :

- d'utiliser `/api/admin/register` pour un client WL
- de creer un user WL avec `firebase_uid`
- d'autoriser Firebase Auth sur une communaute WL
- de melanger WL et self-service dans un meme flow
- d'ajouter une feature d'auth sans audit d'impact contractuel

---

## 5. Consequences sur l'architecture applicative

- L'app / backoffice doit etre tenant-aware
- Le mode d'auth est determine par:
  - le tenant
  - le domaine
  - ou la config community
- L'ecran de login doit s'adapter:
  - Standard → Firebase
  - WL → Legacy KOOMY

---

## 6. Regle de gouvernance (process)

A partir de ce document:

Toute nouvelle feature touchant:
- auth
- onboarding
- identity
- register

doit obligatoirement passer par:
1. audit d'impact
2. mise a jour de ce contrat
3. plan d'implementation
4. seulement ensuite du code

---

## 7. Statut du document

- ✅ Aligne avec la production actuelle (client WL)
- ✅ Aligne avec la sandbox
- ✅ Non ambigu
- ✅ Fige les responsabilites

🔒 **Document de reference**
