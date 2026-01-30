# Plan d'Implémentation V1 — Self-Enrollment (Join Link)

**Date :** 11 janvier 2026  
**Auteur :** Agent Replit  
**Version :** 1.0  
**Référence contractuelle :** `/docs/audit-self-enrollment.md` (v1.3)  
**Statut :** PLAN UNIQUEMENT — AUCUN CODE

---

## 1) Résumé V1 (1 page max)

### Objectif de V1

Permettre aux clubs d'activer un **lien d'inscription public** (join link) pour recruter de nouveaux membres en ligne, en complément du mode OFFLINE existant (création/import via back-office).

**Deux modes ONLINE exclusifs :**
- **OUVERT** : Inscription directe (dans limite quota). Paiement immédiat si plan payant.
- **FERMÉ** : Formulaire = demande. Validation/refus par admin, puis paiement si payant.

### Règles de paiement V1

| Canal | Moyen de paiement | Responsable |
|-------|-------------------|-------------|
| **ONLINE** (self-onboarding via /join) | **Stripe uniquement** | Automatisé |
| **OFFLINE** (back-office admin) | Libre (cash, chèque, virement, Stripe) | Club |

> **Décision produit :** Le self-onboarding ONLINE ne gère PAS le paiement cash/manuel. Le cash est un flux 100% OFFLINE géré par le club (encaissement externe, création/import membre via back-office).

### Hors périmètre V1

| Exclu | Raison |
|-------|--------|
| Liste d'attente (waitlist) | Complexité UX, V2 |
| Sélection de section dans le formulaire | Simplification UX V1 |
| Champs personnalisables par club | V2 |
| Analytics conversions join link | V2 |
| Rappels automatiques demandes non traitées | V2 |
| CAPTCHA | Rate limit suffisant V1 |
| Multi-plans dans un seul formulaire | V1 = 1 plan sélectionné par le visiteur |
| Paiement échelonné | V2 |
| **Paiement cash/manuel via /join** | **Exclu par décision produit** (flux OFFLINE uniquement) |

### Indépendance des chantiers

> Le chantier **"cycle de paiement SaaS + moyens de paiement"** (impayés, suspension, résiliation) est un chantier séparé et n'est pas une dépendance de V1 self-onboarding.
>
> V1 join link ne traite que :
> - **Gratuit** : Inscription directe
> - **Payant** : Stripe immédiat (mode OUVERT) ou Stripe après approval (mode FERMÉ)

### Hypothèses V1

1. Le club a déjà au moins un `membershipPlan` actif.
2. Le club a Stripe Connect configuré si mode payant souhaité.
3. Le slug communauté existe et est unique.
4. L'admin peut activer/désactiver le join link à tout moment.
5. Le formulaire est disponible en FR uniquement (EN V2).

---

## 2) Feature Flags (obligatoire)

### Flags globaux (plateforme)

| Flag | Portée | Par défaut | Protège |
|------|--------|------------|---------|
| `SELF_ENROLLMENT_GLOBAL_ENABLED` | Global | `false` | Kill switch plateforme entière |
| `SELF_ENROLLMENT_CLOSED_MODE_ENABLED` | Global | `false` | Activer mode FERMÉ (rollout progressif) |
| `SELF_ENROLLMENT_RATE_LIMIT_PER_HOUR` | Global | `10` | Limite soumissions par IP/heure |

### Flags par communauté (table `communities`)

| Colonne | Type | Par défaut | Description |
|---------|------|------------|-------------|
| `selfEnrollmentEnabled` | boolean | `false` | Join link activé pour ce club |
| `selfEnrollmentChannel` | enum | `"offline"` | `"offline"` \| `"online"` |
| `selfEnrollmentMode` | enum | `null` | `"open"` \| `"closed"` (si online) |
| `selfEnrollmentSlug` | text | `null` | Slug custom pour URL (optionnel, sinon community.slug) |
| `distributionInKoomyApp` | boolean | `false` | Club visible dans app Koomy (choix business) |

### Flags par app/univers

| Contexte | Comportement |
|----------|--------------|
| App Koomy | Wallet visible, regroupement adhésions possible |
| App Marque blanche | Wallet masqué, aucune référence Koomy ou autres clubs |

### Protection rollout

```
SI SELF_ENROLLMENT_GLOBAL_ENABLED = false → page /join retourne 404
SI community.selfEnrollmentEnabled = false → page /join/{slug} retourne "Inscriptions fermées"
SI SELF_ENROLLMENT_CLOSED_MODE_ENABLED = false ET community.selfEnrollmentMode = "closed" → fallback "open" ou erreur config
```

---

## 3) Modèle de Données (conceptuel, sans SQL)

### Rappel des règles contractuelles

| Règle | Implication technique |
|-------|----------------------|
| Demande ≠ adhésion | Nouvelle entité ou statut distinct |
| Quota consommé uniquement à activation réelle | `memberCount` NON incrémenté sur demande |
| ZÉRO DB avant paiement (OUVERT payant) | Données stockées dans Stripe metadata |
| Exception email marque blanche → Koomy | Contrainte unique email conditionnelle par univers |

### Option A : Nouvelle table `enrollment_requests` (RECOMMANDÉE)

**Avantages :**
- Séparation claire demande vs adhésion
- Pas d'impact sur `userCommunityMemberships`
- Historique des demandes (refusées, expirées)
- Quota non impacté par les demandes

**Nouvelle table `enrollment_requests` :**

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | varchar(50) | PK UUID |
| `communityId` | varchar(50) | FK communities |
| `membershipPlanId` | varchar(50) | FK membershipPlans |
| `status` | enum | `"pending"` \| `"approved"` \| `"rejected"` \| `"expired"` \| `"converted"` |
| `salutation` | text | Civilité |
| `firstName` | text | Prénom |
| `lastName` | text | Nom |
| `email` | text | Email (non unique) |
| `phone` | text | Téléphone (optionnel) |
| `enrollmentMode` | enum | `"open"` \| `"closed"` |
| `sourceApp` | enum | `"koomy"` \| `"whitelabel:{tenantId}"` |
| `consentGdprAt` | timestamp | Date consentement RGPD |
| `stripeCheckoutSessionId` | text | ID session Stripe (si paiement en cours) |
| `convertedMembershipId` | varchar(50) | FK membership créée après conversion |
| `rejectedAt` | timestamp | Date refus |
| `rejectedReason` | text | Motif refus (optionnel) |
| `expiresAt` | timestamp | Date expiration demande (30 jours) |
| `createdAt` | timestamp | Date création |
| `updatedAt` | timestamp | Date mise à jour |

**Nouvel enum `enrollment_request_status` :**
- `pending` : En attente validation (mode FERMÉ)
- `approved` : Validée par admin (mode FERMÉ), en attente paiement si payant
- `rejected` : Refusée par admin
- `expired` : Délai 30 jours dépassé
- `converted` : Transformée en membership active

### Option B : Statut `pending_approval` dans `userCommunityMemberships`

**Inconvénients :**
- Mélange demandes et adhésions
- Risque d'incrémenter quota par erreur
- Complexifie les requêtes existantes
- Pollution historique

**❌ NON RECOMMANDÉE**

### Option C : Pas de stockage DB avant paiement (OUVERT payant uniquement)

**Description :** Stocker toutes les données dans Stripe Checkout metadata, créer membership uniquement sur webhook succès.

**Avantages :**
- ZÉRO DB avant paiement respecté
- Pas de cleanup si paiement abandonné

**Inconvénients :**
- Limite 500 chars par clé metadata Stripe
- Pas d'historique tentatives échouées
- Mode FERMÉ nécessite quand même du stockage

**✅ COMPATIBLE avec Option A** : Utiliser pour mode OUVERT payant, table `enrollment_requests` pour mode FERMÉ.

### Décision recommandée : Option A + C hybride

| Mode | Stockage |
|------|----------|
| OUVERT + gratuit | INSERT direct `userCommunityMemberships` (status=active) |
| OUVERT + payant | Stripe metadata → webhook → INSERT `userCommunityMemberships` |
| FERMÉ + gratuit | INSERT `enrollment_requests` (status=pending) → validation → INSERT `userCommunityMemberships` |
| FERMÉ + payant | INSERT `enrollment_requests` → validation → Stripe → webhook → INSERT `userCommunityMemberships` |

### Gestion email existant — Impact technique

#### Contexte
La contrainte `UNIQUE(email)` existe sur `accounts` mais PAS sur `userCommunityMemberships`.

#### Problème Cas B (marque blanche → Koomy)
Si l'email existe dans une marque blanche, on doit pouvoir créer un NOUVEL account Koomy.

**Options :**

| Option | Description | Impact |
|--------|-------------|--------|
| A | Ajouter colonne `distributionUniverse` à `accounts` | Contrainte UNIQUE sur (email, distributionUniverse) |
| B | Table séparée `account_universes` | N:N accounts ↔ univers |
| C | Pas de contrainte DB, validation applicative | Risque doublons si bug |

**Recommandation :** Option A (contrainte composite) — À valider avec CTO.

---

## 4) Parcours & Flows (diagrammes texte)

### 4.1 OFFLINE (rappel — comportement actuel)

```
Admin → Back-office → "Ajouter membre"
    ├── Saisie manuelle formulaire
    │   ├── Champs : Civilité, Prénom, Nom, Email, Phone, Section, Plan
    │   ├── Génération memberId (atomique)
    │   ├── Génération claimCode
    │   ├── INSERT userCommunityMemberships (status=active, paymentStatus=free|due)
    │   ├── Incrémentation memberCount
    │   └── Envoi email invite_member (si email fourni)
    │
    └── Import CSV
        ├── Validation Zod par ligne
        ├── Mêmes étapes que saisie manuelle (batch)
        └── Rapport erreurs/succès
```

**⚠️ Impact V1 :** Aucun changement sur OFFLINE. Le flux existant reste intact.

**Moyens de paiement OFFLINE :**
Le club peut continuer à créer des membres avec paiement `due` (à régler) via le back-office. L'encaissement (cash, chèque, virement) se fait en dehors de Koomy. L'admin marque ensuite manuellement le paiement comme reçu. Ce flux reste strictement administrateur et n'est PAS accessible via /join.

---

### 4.2 ONLINE + OUVERT + GRATUIT

```
Visiteur → /join/{slug}
    │
    ├── [1] VÉRIFICATIONS PRÉLIMINAIRES
    │   ├── Community existe ? → Non → "Ce lien n'est plus valide"
    │   ├── selfEnrollmentEnabled = true ? → Non → "Inscriptions fermées"
    │   ├── selfEnrollmentChannel = "online" ? → Non → "Inscriptions fermées"
    │   └── Quota disponible ? → Non → "Limite atteinte, contactez le club"
    │
    ├── [2] AFFICHAGE FORMULAIRE
    │   ├── Branding club (logo, couleurs)
    │   ├── Liste plans actifs (gratuits uniquement ou tous)
    │   ├── Champs : Civilité*, Prénom*, Nom*, Email*, Phone
    │   └── Checkbox RGPD* (obligatoire)
    │
    ├── [3] SOUMISSION
    │   ├── Rate limit check (IP)
    │   ├── Validation Zod
    │   ├── Email existe dans même univers ?
    │   │   ├── Oui → Redirect login avec message
    │   │   │         "Un compte existe. Connectez-vous pour continuer."
    │   │   └── Non → Continuer
    │   ├── Re-check quota (race condition)
    │   └── Plan sélectionné = gratuit ? → Continuer
    │
    ├── [4] CRÉATION DIRECTE
    │   ├── Créer account (si email non existant dans univers)
    │   ├── Générer memberId (atomique)
    │   ├── Générer claimCode
    │   ├── INSERT userCommunityMemberships
    │   │   └── status=active, paymentStatus=free, accountId=account.id
    │   ├── Incrémenter memberCount
    │   └── Envoyer email "Bienvenue + claimCode"
    │
    └── [5] PAGE CONFIRMATION
        ├── "Bienvenue dans {clubName} !"
        ├── Afficher claimCode (XXXX-XXXX)
        ├── Boutons téléchargement app (iOS/Android)
        └── "Un email de confirmation vous a été envoyé."
```

**Erreurs possibles :**

| Erreur | Message utilisateur |
|--------|---------------------|
| Slug inexistant | "Ce lien n'est plus valide." |
| Inscriptions désactivées | "Les inscriptions en ligne ne sont pas disponibles pour ce club." |
| Quota atteint | "La limite d'adhésions est atteinte. Veuillez contacter le club." |
| Email existant même univers | "Un compte existe déjà avec cet email. Connectez-vous pour continuer." |
| Rate limit | "Trop de tentatives. Réessayez dans quelques minutes." |
| Erreur serveur | "Une erreur est survenue. Veuillez réessayer." |

---

### 4.3 ONLINE + OUVERT + PAYANT (Stripe uniquement)

> **Moyen de paiement :** Stripe exclusivement. Aucune option cash/manuel/virement.

```
Visiteur → /join/{slug}
    │
    ├── [1] VÉRIFICATIONS PRÉLIMINAIRES
    │   └── (identique OUVERT GRATUIT)
    │
    ├── [2] AFFICHAGE FORMULAIRE
    │   └── (identique, avec plans payants affichés + prix TTC)
    │   └── ⚠️ Aucune option "payer en espèces" ou "payer plus tard"
    │
    ├── [3] SOUMISSION
    │   ├── Validation Zod
    │   ├── Email existe dans même univers ?
    │   │   ├── Oui → AUTHENTIFICATION OBLIGATOIRE AVANT PAIEMENT
    │   │   │         Redirect login, puis retour au flow paiement
    │   │   └── Non → Continuer
    │   ├── Re-check quota
    │   └── Plan sélectionné = payant → Préparer Stripe (seul moyen)
    │
    ├── [4] CRÉATION STRIPE CHECKOUT SESSION
    │   ├── ⚠️ ZÉRO INSERT DB À CE STADE
    │   ├── Créer Checkout Session avec metadata :
    │   │   {
    │   │     payment_reason: "self_enrollment",
    │   │     communityId,
    │   │     membershipPlanId,
    │   │     firstName,
    │   │     lastName,
    │   │     email,
    │   │     phone,
    │   │     salutation,
    │   │     sourceApp: "koomy" | "whitelabel:{tenantId}",
    │   │     enrollmentMode: "open",
    │   │     consentGdprAt: ISO timestamp
    │   │   }
    │   └── Redirect vers Stripe Checkout
    │
    ├── [5] STRIPE CHECKOUT
    │   ├── Visiteur paie
    │   ├── Succès → Redirect success_url
    │   ├── Abandon → Redirect cancel_url ("Inscription non finalisée")
    │   └── Échec carte → Message Stripe natif
    │
    ├── [6] WEBHOOK checkout.session.completed
    │   ├── Vérifier signature webhook
    │   ├── Extraire metadata
    │   ├── Re-check quota (dernière vérification)
    │   │   └── Si quota atteint → Trigger remboursement auto + email excuse
    │   ├── Créer account (si email non existant dans univers)
    │   ├── Générer memberId
    │   ├── Générer claimCode
    │   ├── INSERT userCommunityMemberships
    │   │   └── status=active, paymentStatus=paid, paidAt=now
    │   ├── Incrémenter memberCount
    │   └── Envoyer email "Paiement confirmé + Bienvenue + claimCode"
    │
    └── [7] PAGE SUCCESS
        ├── "Merci pour votre paiement !"
        ├── Afficher claimCode
        └── Boutons téléchargement app
```

**Points critiques :**

| Point | Règle |
|-------|-------|
| Authentification | Si email existe → login AVANT paiement |
| Stockage | RIEN en DB avant webhook |
| Race condition quota | Double-check sur webhook, remboursement si dépassé |
| Session expiration | 30 min Stripe par défaut |

---

### 4.4 ONLINE + FERMÉ + GRATUIT

```
Visiteur → /join/{slug}
    │
    ├── [1] VÉRIFICATIONS PRÉLIMINAIRES
    │   └── (identique, mais selfEnrollmentMode = "closed")
    │
    ├── [2] AFFICHAGE FORMULAIRE
    │   ├── Titre : "Demande d'adhésion"
    │   ├── Mention : "Votre demande sera examinée par l'équipe du club."
    │   └── Champs identiques
    │
    ├── [3] SOUMISSION
    │   ├── Validation Zod
    │   ├── Email existe dans même univers ?
    │   │   ├── Oui → Redirect login
    │   │   └── Non → Continuer
    │   ├── ⚠️ PAS de check quota (demande ≠ adhésion)
    │   └── Continuer
    │
    ├── [4] CRÉATION DEMANDE
    │   ├── INSERT enrollment_requests
    │   │   └── status=pending, enrollmentMode=closed
    │   ├── ⚠️ PAS de claimCode
    │   ├── ⚠️ PAS d'incrément memberCount
    │   ├── Envoyer email visiteur "Demande reçue"
    │   └── Envoyer email/notif admin "Nouvelle demande"
    │
    └── [5] PAGE CONFIRMATION
        └── "Votre demande a été transmise. Vous recevrez une réponse par email."

---

Admin → Back-office → "Demandes d'adhésion"
    │
    ├── [A] LISTE DEMANDES
    │   ├── Filtres : pending, approved, rejected, expired
    │   └── Affichage : Nom, Email, Plan, Date, Actions
    │
    ├── [B] ACTION : APPROUVER
    │   ├── Check quota avant approval
    │   │   └── Quota atteint → "Impossible d'approuver, limite atteinte"
    │   ├── UPDATE enrollment_requests SET status=approved
    │   ├── Créer account (si nécessaire)
    │   ├── Générer memberId
    │   ├── Générer claimCode
    │   ├── INSERT userCommunityMemberships
    │   │   └── status=active, paymentStatus=free
    │   ├── UPDATE enrollment_requests SET status=converted, convertedMembershipId=...
    │   ├── Incrémenter memberCount
    │   └── Envoyer email "Bienvenue + claimCode"
    │
    └── [C] ACTION : REFUSER
        ├── UPDATE enrollment_requests SET status=rejected, rejectedAt=now
        ├── Optionnel : motif de refus
        └── Envoyer email "Demande non acceptée" (message neutre)
```

---

### 4.5 ONLINE + FERMÉ + PAYANT (Stripe uniquement)

> **Moyen de paiement :** Stripe exclusivement. L'invitation à payer envoyée après approval contient un lien Stripe Checkout.

```
Visiteur → /join/{slug}
    │
    ├── [1-4] IDENTIQUE À FERMÉ GRATUIT
    │   └── INSERT enrollment_requests (status=pending)
    │
    └── [5] PAGE CONFIRMATION
        └── "Votre demande sera examinée. Si elle est acceptée, vous recevrez une invitation à payer par carte."

---

Admin → Back-office → "Demandes d'adhésion"
    │
    ├── [B] ACTION : APPROUVER (plan payant)
    │   ├── Check quota
    │   ├── UPDATE enrollment_requests SET status=approved
    │   ├── ⚠️ PAS de création membership encore
    │   ├── Créer Stripe Payment Link ou envoyer email "Invitation à payer"
    │   │   └── Metadata : enrollmentRequestId, communityId, planId
    │   └── Visiteur reçoit email avec lien paiement
    │
    └── [WEBHOOK checkout.session.completed]
        ├── Récupérer enrollmentRequestId depuis metadata
        ├── Vérifier request.status = approved
        ├── Check quota (dernière vérification)
        ├── Créer account + membership (comme OUVERT payant)
        ├── UPDATE enrollment_requests SET status=converted
        ├── Incrémenter memberCount
        └── Envoyer email "Paiement confirmé + Bienvenue + claimCode"
```

---

## 5) Endpoints / Pages / Écrans à Prévoir (liste)

### Pages publiques (frontend)

| Surface | URL | Responsabilité |
|---------|-----|----------------|
| Page join | `/join/{slug}` | Formulaire inscription |
| Page success | `/join/{slug}/success` | Confirmation inscription réussie |
| Page cancel | `/join/{slug}/cancel` | Paiement abandonné |
| Page pending | `/join/{slug}/pending` | Demande en attente (mode FERMÉ) |
| Page error | `/join/{slug}/error` | Erreurs génériques |

### Back-office admin (web)

| Surface | Emplacement | Responsabilité |
|---------|-------------|----------------|
| Config join link | Paramètres communauté | Activer/désactiver, choisir mode |
| Liste demandes | Menu principal | Voir demandes pending/approved/rejected |
| Détail demande | Modal ou page | Infos visiteur, actions approve/reject |
| Action approve | Bouton | Valider demande (+ trigger paiement si payant) |
| Action reject | Bouton | Refuser demande (+ email) |
| Copier lien | Paramètres | Copier URL join link |

### Back-office admin (mobile)

| Surface | Responsabilité |
|---------|----------------|
| Toggle join link | Activer/désactiver |
| Badge demandes | Nombre demandes pending |
| Liste demandes | Même que web (responsive) |
| Actions approve/reject | Même que web |

### Emails transactionnels

| Email | Trigger | Destinataire |
|-------|---------|--------------|
| `enrollment_request_received` | Soumission mode FERMÉ | Visiteur |
| `enrollment_request_new` | Soumission mode FERMÉ | Admin(s) |
| `enrollment_approved_free` | Approval mode FERMÉ gratuit | Visiteur |
| `enrollment_approved_paid` | Approval mode FERMÉ payant | Visiteur (invitation payer) |
| `enrollment_rejected` | Refus mode FERMÉ | Visiteur |
| `enrollment_success` | Création membership (tous modes) | Visiteur |
| `enrollment_payment_confirmed` | Webhook succès paiement | Visiteur |
| `enrollment_quota_reached_refund` | Quota atteint post-paiement | Visiteur (excuse + remboursement) |

---

## 6) Compatibilité Marque Blanche vs App Koomy

### Tableau comparatif UX

| Élément | App Koomy | App Marque Blanche |
|---------|-----------|-------------------|
| Branding page /join | Logo Koomy + logo club | Logo club uniquement |
| Mention "Koomy" | Présente (footer, CGU) | ABSENTE |
| Wallet visible | Oui (si plusieurs adhésions) | NON |
| Autres clubs visibles | Oui (si distribution acceptée) | NON |
| Message email existant | "Compte Koomy existant" | "Compte existant" (neutre) |
| Regroupement adhésions | Visible dans app | Masqué |

### Comportement email existant

#### Cas A : Même univers de distribution

```
SI email existe dans accounts
   ET (
     (sourceApp = "koomy" ET univers courant = "koomy")
     OU
     (sourceApp = "whitelabel:X" ET univers courant = "whitelabel:X")
   )
ALORS
   → Authentification OBLIGATOIRE
   → Rattachement au même account
   → Message : "Un compte existe déjà avec cet email. Connectez-vous pour continuer."
```

#### Cas B : Marque blanche → Koomy

```
SI email existe dans accounts
   ET sourceApp = "whitelabel:X" (n'importe quelle marque blanche)
   ET univers courant = "koomy"
ALORS
   → AUTORISER création nouvel account Koomy
   → Aucune référence à la marque blanche
   → Utilisateur = nouvel utilisateur dans l'univers Koomy
```

### Implémentation technique (options)

| Option | Description | Complexité |
|--------|-------------|------------|
| A | Colonne `distributionUniverse` sur `accounts` + contrainte UNIQUE(email, distributionUniverse) | Moyenne |
| B | Vérification applicative avec tolérance doublons cross-univers | Faible |
| C | Table `account_distribution_contexts` (N:N) | Haute |

**Recommandation V1 :** Option B (validation applicative) — migration vers Option A en V2 si volume justifie.

### Règle de non-divulgation

| Interdit | Message alternatif |
|----------|-------------------|
| "Vous avez déjà un compte dans l'app X" | "Un compte existe déjà." |
| "Vos autres adhésions : ..." | (Ne pas afficher) |
| "Koomy" (en marque blanche) | (Ne jamais mentionner) |
| Logo Koomy (en marque blanche) | (Ne jamais afficher) |

---

## 7) Plan de Rollout (safe prod)

### Phase 1 : Sandbox interne (J-14 à J-7)

| Étape | Action | Critère succès |
|-------|--------|----------------|
| 1.1 | Déployer sur tenant sandbox (Port-Bouët FC) | Build réussi |
| 1.2 | Tests manuels tous les flows | 0 bug bloquant |
| 1.3 | Tests automatisés (unit + intégration) | 100% pass |
| 1.4 | Tests paiement Stripe test mode | Webhook OK |
| 1.5 | Tests quota (atteint, dépassé) | Comportement correct |
| 1.6 | Tests email (SendGrid sandbox) | Tous templates OK |

### Phase 2 : Pilote beta (J-7 à J0)

| Étape | Action | Critère succès |
|-------|--------|----------------|
| 2.1 | Sélectionner 3 clubs pilotes volontaires | Accord écrit |
| 2.2 | Activer flag par communauté | Pas d'erreurs 500 |
| 2.3 | Monitoring temps réel (logs, métriques) | < 1% erreurs |
| 2.4 | Support dédié pilotes | < 4h réponse |
| 2.5 | Collecter feedback UX | Documenter |

### Phase 3 : Rollout progressif (J0 à J+30)

| Semaine | Action |
|---------|--------|
| S1 | 10% communautés (nouveaux inscrits) |
| S2 | 25% communautés |
| S3 | 50% communautés |
| S4 | 100% (flag global = true) |

### Métriques à monitorer

| Métrique | Seuil alerte | Action |
|----------|--------------|--------|
| Taux erreur 500 | > 1% | Pause rollout |
| Taux abandon paiement | > 80% | Investigation UX |
| Taux conversion formulaire | < 20% | Investigation UX |
| Temps webhook Stripe | > 30s | Optimisation |
| Demandes pending > 7 jours | > 50% | Notification admin |

### Procédure rollback

```
1. Désactiver SELF_ENROLLMENT_GLOBAL_ENABLED = false
2. Toutes les pages /join retournent 404
3. Les demandes pending restent en DB (pas de perte)
4. Les memberships déjà créées restent actives
5. Analyse post-mortem
6. Correction
7. Réactivation progressive
```

---

## 8) Plan de Tests (obligatoire)

### Tests unitaires

| Fonction | Fichier | Couverture |
|----------|---------|------------|
| `checkMemberQuota()` | storage.test.ts | Quota normal, atteint, GRAND_COMPTE |
| `generateMemberId()` | routes.test.ts | Atomicité, format, unicité |
| `generateClaimCode()` | routes.test.ts | Format, unicité |
| Validation Zod enrollment | validation.test.ts | Champs requis, email format, RGPD |
| Résolution univers distribution | auth.test.ts | Koomy vs marque blanche |

### Tests intégration

| Scénario | Assertions |
|----------|------------|
| OUVERT gratuit - happy path | Account créé, membership active, email envoyé |
| OUVERT payant - Stripe success | Session créée, webhook reçu, membership active |
| OUVERT payant - Stripe abandon | Pas de création DB |
| FERMÉ gratuit - pending | Request créée, pas de membership |
| FERMÉ gratuit - approve | Membership créée, request converted |
| FERMÉ gratuit - reject | Request rejected, pas de membership |
| FERMÉ payant - approve + pay | Invitation envoyée, webhook → membership |
| Email existant même univers | Redirect login |
| Email existant cross-univers | Nouvel account autorisé |
| Quota atteint | Message erreur, pas de création |
| Quota atteint post-paiement | Remboursement auto |

### Tests E2E (scénarios)

| # | Scénario | Steps |
|---|----------|-------|
| E1 | Inscription OUVERT gratuit complète | Formulaire → Submit → Confirmation → Email reçu |
| E2 | Inscription OUVERT payant complète | Formulaire → Stripe → Paiement → Confirmation |
| E3 | Inscription FERMÉ → Approval → Activation | Formulaire → Pending → Admin approve → Email |
| E4 | Inscription FERMÉ → Refus | Formulaire → Pending → Admin reject → Email |
| E5 | Email existant → Login → Rattachement | Formulaire → Redirect login → Retour → Success |
| E6 | Quota atteint → Message erreur | Formulaire → Submit → "Limite atteinte" |
| E7 | Paiement abandonné → Pas de création | Formulaire → Stripe → Cancel → Rien créé |

### Tests Stripe webhook

| Test | Validation |
|------|------------|
| Signature invalide | Rejet 400 |
| Event checkout.session.completed | Création membership |
| Event checkout.session.expired | Cleanup (si applicable) |
| Metadata manquante | Erreur loggée, pas de crash |
| Doublon idempotency | Pas de double création |

### Tests quota

| Test | Comportement attendu |
|------|---------------------|
| Quota = max - 1 | Inscription OK |
| Quota = max | Message erreur |
| Quota dépassé entre formulaire et webhook | Remboursement + excuse |
| Demande FERMÉ ne consomme pas quota | memberCount inchangé |
| Approval consomme quota | memberCount +1 |

### Tests non-divulgation (marque blanche)

| Test | Assertion |
|------|-----------|
| Page /join en marque blanche | Aucun "Koomy" dans HTML |
| Email marque blanche | Aucun "Koomy" dans contenu |
| Erreur email existant | Message neutre sans mention wallet |
| App membre marque blanche | Pas de section "autres clubs" |

### Tests exclusion cash (non-régression)

> **Objectif :** Vérifier qu'aucune option de paiement cash/manuel n'est proposée ou traitée par le parcours /join.

| Test | Assertion |
|------|-----------|
| UI /join plan payant | Aucune option "Payer en espèces", "Payer plus tard", ou sélecteur de moyen de paiement |
| API POST /api/join (plan payant) | Endpoint n'accepte aucun paramètre `paymentMethod` autre que Stripe |
| API POST /api/join (plan payant) | Redirect vers Stripe Checkout obligatoire (pas d'alternative) |
| Webhook | Seuls les événements Stripe déclenchent la création de membership |
| UI /join tous modes | Pas de mention "paiement manuel", "cash", "chèque", "virement" |

---

## 9) Risques & Décisions à Trancher

### Top 10 risques production

| # | Risque | Probabilité | Impact | Mitigation |
|---|--------|-------------|--------|------------|
| 1 | Race condition quota (2 users simultanés) | Moyenne | Élevé | Double-check sur webhook + remboursement auto |
| 2 | Webhook Stripe non reçu | Faible | Critique | Retry Stripe + monitoring + alerte |
| 3 | Email non délivré (spam) | Moyenne | Moyen | SPF/DKIM/DMARC + monitoring SendGrid |
| 4 | Abus formulaire public (spam) | Moyenne | Moyen | Rate limit + potentiel CAPTCHA V2 |
| 5 | Confusion UX mode FERMÉ | Moyenne | Moyen | Messages clairs + preview admin |
| 6 | Remboursement manuel oublié | Faible | Élevé | Automatisation + dashboard |
| 7 | Quota memberId épuisé (compteur) | Très faible | Critique | Alertes à 90%, format extensible |
| 8 | Fuite email cross-univers | Faible | Critique | Tests non-divulgation + review code |
| 9 | Performances page /join | Faible | Moyen | Caching branding, CDN |
| 10 | Régression mode OFFLINE | Faible | Élevé | Tests non-régression, feature isolation |

### Décisions non tranchées

| Question | Options | Recommandation | À décider par |
|----------|---------|----------------|---------------|
| Contrainte email unique cross-univers | A) Contrainte DB / B) Applicatif | B (V1) → A (V2) | CTO |
| Durée de vie demande FERMÉ | 30 jours / configurable | 30 jours fixe V1 | Product |
| Notification admin (email vs push) | A) Email / B) Push / C) Les deux | A (email V1) | Product |
| Validation email obligatoire | A) Oui / B) Non | A (obligatoire) | Product |
| Langue formulaire | A) FR only / B) FR+EN | A (FR only V1) | Product |

### Recommandations CTO

1. **Privilégier isolation totale** : Nouvelle table `enrollment_requests` plutôt que statut dans memberships.
2. **Tester webhooks intensivement** : Environnement staging avec Stripe CLI local.
3. **Monitoring dès J1** : Alertes sur taux erreur, webhook latency, quota approaching.
4. **Feature flags granulaires** : Pouvoir désactiver par communauté sans impact global.
5. **Documentation runbook** : Procédures pour cas edge (remboursement manuel, purge demandes).
6. **Pas de refactoring quota** : Le compteur `memberCount` reste inchangé, la logique d'incrément est conditionnée au statut.

---

*Fin du plan d'implémentation V1*
