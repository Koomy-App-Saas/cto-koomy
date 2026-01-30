# Audit Technique : Inscription Autonome (Join Link)

**Date :** 11 janvier 2026  
**Auteur :** Agent Replit  
**Version :** 1.3 (+ Email, Identité, Wallet, Marque Blanche & Distribution)  
**Statut :** Audit uniquement - AUCUN DÉVELOPPEMENT

---

## 1. Résumé Exécutif

Ce document analyse l'architecture existante de Koomy pour évaluer l'implémentation d'une fonctionnalité "Inscription autonome" (Join Link). Cette fonctionnalité permettrait aux clubs de partager un lien public brandé pour recruter de nouveaux membres.

### Deux modes envisagés :
1. **Club OUVERT** : Adhésion automatique. Paiement immédiat obligatoire si offre payante.
2. **Club FERMÉ** : Demande d'adhésion. Validation manuelle par l'admin, puis invitation à payer.

### Conclusion principale :
L'architecture actuelle est **partiellement compatible** avec cette fonctionnalité. Les principales adaptations concerneront :
- Ajout d'un statut "pending_approval" pour les demandes en mode fermé
- Création de routes publiques (non authentifiées) pour le formulaire d'inscription
- Extension du système de paiement existant (Stripe Connect) pour le flow "paiement avant activation"
- Configuration du mode (ouvert/fermé) dans la table `communities`

---

## 2. Cartographie de l'Existant

### 2.1 Schéma de données (shared/schema.ts)

#### Table principale : `userCommunityMemberships`
```
Fichier : shared/schema.ts (lignes 391-434)
```

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | varchar(50) | PK UUID auto-généré |
| `userId` | varchar(50) | FK vers users (nullable - pour cartes sans compte) |
| `accountId` | varchar(50) | FK vers accounts (compte Koomy lié) |
| `communityId` | varchar(50) | FK vers communities (REQUIRED) |
| `memberId` | text | Numéro adhérent (ex: UNSA-2024-8892) |
| `claimCode` | text | Code de réclamation 8 caractères (XXXX-XXXX) |
| `firstName`, `lastName` | text | Prénom/Nom |
| `email`, `phone` | text | Coordonnées |
| `role` | text | "member" \| "admin" \| "delegate" |
| `status` | enum | **"active" \| "expired" \| "suspended"** |
| `membershipPaymentStatus` | enum | **"free" \| "due" \| "paid"** |
| `membershipAmountDue` | integer | Montant à payer (cents) |
| `membershipPaidAt` | timestamp | Date du dernier paiement |
| `membershipValidUntil` | timestamp | Fin de validité |
| `membershipPlanId` | varchar(50) | FK vers membershipPlans |
| `claimedAt` | timestamp | Date de liaison au compte |

**Statuts actuels (enum `member_status`):**
- `active` : Membre actif
- `expired` : Adhésion expirée
- `suspended` : Membre suspendu

**⚠️ Manque : pas de statut "pending_approval" pour les demandes non validées.**

#### Table `membershipPlans` (offres d'adhésion)
```
Fichier : shared/schema.ts (lignes 663-678)
```

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | varchar(50) | PK |
| `communityId` | varchar(50) | FK communauté |
| `name` | text | Nom du plan (ex: "Adhésion Standard 2026") |
| `slug` | text | Identifiant URL |
| `amount` | integer | Prix en cents |
| `currency` | text | EUR par défaut |
| `membershipType` | enum | FIXED_PERIOD \| ROLLING_DURATION |
| `fixedPeriodType` | enum | CALENDAR_YEAR \| SEASON |
| `isActive` | boolean | Plan actif |

#### Table `communities` (configuration tenant)
```
Fichier : shared/schema.ts (lignes 198-289)
```

Colonnes pertinentes :
- `stripeConnectAccountId` : Compte Stripe Connect Express
- `paymentsEnabled` : Boolean (true si Connect vérifié)
- `platformFeePercent` : Commission Koomy (défaut 2%)
- `whiteLabel` : Boolean mode marque blanche
- `brandConfig` : JSONB (logo, couleurs, appName)
- `customDomain` : Sous-domaine personnalisé

**⚠️ Manque : colonnes pour configurer le mode inscription (ouvert/fermé, join link actif, URL).**

---

### 2.2 Routes API (server/routes.ts)

#### Création de membre actuelle
```
Route : POST /api/memberships
Fichier : server/routes.ts (lignes 2940-3230)
Authentification : REQUISE (accountId ou userId en session)
```

**Flow :**
1. Vérifie authentification (rejette si non authentifié, ligne 2947)
2. Force `role = "member"` (sécurité anti-escalade)
3. Génère `memberId` avec préfixe communauté
4. Valide champs via `insertMembershipSchema` (Zod)
5. Calcule `membershipPaymentStatus` / `membershipAmountDue` selon plan
6. Génère `claimCode` (8 caractères)
7. Appelle `storage.createMembership()`
8. Envoie email d'invitation avec claimCode

**⚠️ Cette route n'est PAS utilisable pour l'inscription autonome car elle requiert une authentification admin.**

#### Paiement adhésion
```
Route : POST /api/memberships/:membershipId/pay
Fichier : server/routes.ts (lignes 6970-7010)
```

**Flow :**
1. Récupère membership et account
2. Vérifie `membershipPaymentStatus !== "paid"`
3. Appelle `createMembershipPaymentSession()` (Stripe Checkout Connect)
4. Retourne `checkoutUrl`

---

### 2.3 Services de paiement (server/stripe.ts)

#### Création session paiement adhésion
```
Fonction : createMembershipPaymentSession()
Fichier : server/stripe.ts (lignes 239-332)
```

**Flow :**
1. Récupère membership + community
2. Vérifie `stripeConnectAccountId` existe
3. Crée `stripe.checkout.sessions.create()` mode "payment"
4. Configure `application_fee_amount` (commission Koomy)
5. Configure `transfer_data.destination` (compte Connect)
6. Metadata : `{ payment_reason: "membership", membershipId, communityId, accountId }`

#### Webhook Stripe
```
Route : POST /api/webhooks/stripe
Fichier : server/routes.ts (lignes 8270-8295)
Fichier handler : server/stripe.ts (lignes 334-414)
```

**Événements traités :**
- `checkout.session.completed` → `handleCheckoutCompleted()` → `handleMembershipPaymentCompleted()` (ligne 450)
- `payment_intent.succeeded` → `handlePaymentIntentSucceeded()` → `handleMembershipPayment()` (ligne 630)

**Mise à jour membership post-paiement :**
```typescript
await storage.updateMembership(membershipId, {
  membershipPaymentStatus: "paid",
  membershipPaidAt: new Date(),
  membershipPaymentProvider: "stripe",
  membershipPaymentReference: session.id,
  membershipAmountPaid: session.amount_total,
  membershipValidUntil,
});
```

---

### 2.4 Résolution Multi-tenant / Branding

#### Côté client
```
Fichier : client/src/contexts/WhiteLabelContext.tsx
```

**Mécanisme de résolution :**
1. Tente de charger `/wl.json` (embarqué dans build mobile/white-label)
2. Fallback API : `GET /api/whitelabel/by-host?host={hostname}`
3. Configure `apiBaseUrl`, `brandConfig`, `communityId`

#### Fichier wl.json (exemple)
```json
{
  "tenant": "unsalidlfrance",
  "communityId": "unsa-lidl-france",
  "brandName": "UNSA Lidl France",
  "primaryColor": "#E60012",
  "baseUrl": "https://unsalidlfrance.koomy.app",
  "apiBaseUrl": "https://api.koomy.app",
  "isWhiteLabel": true
}
```

#### Colonnes branding dans `communities`
- `brandConfig` (JSONB) : appName, brandColor, logoUrl, privacyPolicyUrl, termsUrl
- `brandingLogoPath`, `brandingPrimaryColor`, `brandingSecondaryColor`
- `customDomain` : ex "unsalidlfrance" → unsalidlfrance.koomy.app

---

### 2.5 Emails transactionnels

```
Fichier : server/services/mailer/sendBrandedEmail.ts
Fonction : sendMemberInviteEmail() (ligne 108)
```

**Template `invite_member` :**
- Variables : name, communityName, codeMembre, activationUrl
- Envoyé à la création de membership avec email

---

### 2.6 Protections de sécurité existantes

#### Rate limiting (server/index.ts, lignes 134-176)
```typescript
const authRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10, // 10 tentatives
  message: { error: "Trop de tentatives de connexion" }
});

const registrationRateLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 heure
  max: 5, // 5 inscriptions
  message: { error: "Trop de tentatives d'inscription" }
});

const apiRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100
});
```

#### Helmet (server/index.ts, ligne 96)
- CSP, X-Frame-Options, etc.

#### Validation Zod
- Tous les inputs validés via schemas `drizzle-zod`

#### Contraintes unicité DB
- Email : unique dans `accounts`, pas dans `userCommunityMemberships`
- Phone : non unique
- claimCode : unique
- memberId : unique par community (préfixe)

---

## 3. Flow Actuel : Création Membre

```
┌─────────────────────────────────────────────────────────────────┐
│                    CRÉATION MEMBRE (ADMIN)                      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  1. Admin connecté au back-office                               │
│     Session authentifiée (accountId ou userId)                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  2. POST /api/memberships                                       │
│     Body: { communityId, firstName, lastName, email,            │
│             membershipPlanId, section... }                      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  3. Validation Zod (insertMembershipSchema)                     │
│     - Force role = "member"                                     │
│     - Force isOwner = false                                     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  4. Génération memberId                                         │
│     - Préfixe communauté si configuré (ex: UNSA-001)            │
│     - Sinon: MBR-{timestamp}-{random}                           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  5. Calcul montant dû                                           │
│     - Si membershipPriceCustom → utilise prix custom            │
│     - Sinon → lookup membershipPlan.amount                      │
│     - membershipPaymentStatus = "free" | "due"                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  6. Calcul dates validité (FIXED_PERIOD / ROLLING_DURATION)     │
│     - membershipStartDate, membershipValidUntil                 │
│     - membershipSeasonLabel (ex: "2025-2026")                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  7. Génération claimCode (8 caractères XXXX-XXXX)               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  8. INSERT userCommunityMemberships                             │
│     - accountId = NULL (carte non liée)                         │
│     - claimedAt = NULL                                          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  9. Envoi email invite_member                                   │
│     - Contient claimCode + lien activation                      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  10. Membre reçoit email, télécharge app, saisit claimCode      │
│      → membership.accountId = account.id                        │
│      → membership.claimedAt = now()                             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  11. Si membershipPaymentStatus = "due"                         │
│      → Membre voit bannière "Payer adhésion"                    │
│      → POST /api/memberships/:id/pay → Stripe Checkout          │
│      → Webhook → membershipPaymentStatus = "paid"               │
└─────────────────────────────────────────────────────────────────┘
```

---

## 4. Flow Actuel : Paiement Stripe (Member → Community)

```
┌─────────────────────────────────────────────────────────────────┐
│                    PAIEMENT ADHÉSION                            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  1. Membre clique "Payer mon adhésion" dans l'app               │
│     POST /api/memberships/:membershipId/pay                     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  2. Backend vérifie :                                           │
│     - membershipPaymentStatus !== "paid"                        │
│     - community.stripeConnectAccountId existe                   │
│     - community.paymentsEnabled = true                          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  3. Création Stripe Checkout Session (mode: payment)            │
│     - line_items: [{ price_data: { unit_amount, product_data }}]│
│     - payment_intent_data.application_fee_amount (2% Koomy)     │
│     - payment_intent_data.transfer_data.destination (Connect)   │
│     - metadata: { payment_reason: "membership", membershipId }  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  4. Retour checkoutUrl → Membre redirigé vers Stripe            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  5. Paiement réussi → Stripe envoie webhook                     │
│     Event: checkout.session.completed                           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  6. POST /api/webhooks/stripe                                   │
│     handleCheckoutCompleted() → handleMembershipPaymentCompleted│
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  7. Mise à jour membership :                                    │
│     - membershipPaymentStatus = "paid"                          │
│     - membershipPaidAt = now()                                  │
│     - membershipPaymentProvider = "stripe"                      │
│     - membershipPaymentReference = session.id                   │
│     - membershipValidUntil = +1 an (si annual)                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  8. Transactions: INSERT avec feeKoomy, amountToCommunity       │
└─────────────────────────────────────────────────────────────────┘
```

---

## 5. Points de Vérité Multi-tenant + Branding

| Élément | Source | Fichier |
|---------|--------|---------|
| communityId tenant | wl.json (build) ou API /api/whitelabel/by-host | WhiteLabelContext.tsx |
| Logo | communities.brandingLogoPath ou brandConfig.logoUrl | DB + CDN |
| Couleur primaire | communities.brandingPrimaryColor ou brandConfig.brandColor | DB |
| Nom app | communities.brandConfig.appName ou name | DB |
| Domaine custom | communities.customDomain | DB |
| Résolution hostname | customDomain → community lookup | getCommunityByCustomDomain() |

---

## 6. Analyse des Risques Production / Zones Fragiles

### 6.1 Risques d'introduction d'un nouveau statut

**Impact potentiel du statut "pending_approval" :**

| Composant | Risque | Mitigation |
|-----------|--------|------------|
| App mobile - liste membres | Affichage incorrect des demandes | Filtrer par status !== "pending_approval" sauf vue admin |
| Compteur membres | Inclure ou pas dans memberCount? | Décision : NE PAS compter avant validation |
| Email invite_member | Ne pas envoyer si pending_approval | Condition explicite |
| Quota membres plan | Ne pas compter pending | checkMemberQuota() à modifier |
| Webhook Stripe | Ne pas traiter payment si pending sans validation | Vérifier workflow |

### 6.2 Risques route publique (non authentifiée)

| Menace | Risque | Protection recommandée |
|--------|--------|------------------------|
| Spam inscriptions | Épuisement quota, pollution DB | Rate limit strict (5/h/IP), honeypot, CAPTCHA |
| Bruteforce email | Harvesting, enumération | Pas de confirmation "email existe" |
| Injection SQL/XSS | Compromission | Validation Zod stricte (déjà en place) |
| Fichiers malveillants | Upload avatar? | Pas d'upload sur join link V1 |
| Faux paiements | Activation sans paiement réel | Activation UNIQUEMENT via webhook Stripe |

### 6.3 Risques Stripe Connect

| Situation | Impact | Gestion actuelle |
|-----------|--------|------------------|
| Community sans Connect | Paiement impossible | Erreur explicite "Community has not set up payment processing" |
| Connect non vérifié | paymentsEnabled = false | Vérifier avant création session |
| Paiement échoué | Membre non activé | membershipPaymentStatus reste "due" |
| Paiement abandonné | Session expirée | Pas de cleanup automatique (OK: membership pas créée si mode OUVERT) |

### 6.4 Zones fragiles identifiées

1. **server/routes.ts ligne 2947** : Rejet des requêtes non authentifiées → Créer route séparée publique
2. **storage.createMembership()** : Appelle checkMemberQuota() → Vérifier comportement avec pending
3. **Génération memberId** : Préfixe communauté → OK si communityId fourni publiquement
4. **Email invite_member** : Actuellement envoyé systématiquement → Conditionner au mode

---

## 7. Proposition de Design V1 (Conceptuelle)

### 7.1 Nouvelles colonnes `communities`

```
selfEnrollmentEnabled      BOOLEAN DEFAULT false
selfEnrollmentMode         ENUM('open', 'closed') DEFAULT 'open'
selfEnrollmentSlug         TEXT UNIQUE  -- pour URL /join/{slug}
selfEnrollmentPlans        JSONB  -- liste des membershipPlanIds autorisés
selfEnrollmentRequireEmail BOOLEAN DEFAULT true
selfEnrollmentRequirePhone BOOLEAN DEFAULT false
selfEnrollmentWelcomeText  TEXT  -- message personnalisé
```

### 7.2 Nouveau statut membre

```sql
ALTER TYPE member_status ADD VALUE 'pending_approval';
```

### 7.3 Nouvelles routes API

| Route | Méthode | Auth | Description |
|-------|---------|------|-------------|
| `/api/join/:slug` | GET | Non | Récupère config publique (branding, plans, mode) |
| `/api/join/:slug/submit` | POST | Non | Soumet demande d'inscription |
| `/api/communities/:id/pending-members` | GET | Admin | Liste demandes en attente |
| `/api/communities/:id/pending-members/:id/approve` | POST | Admin | Valide demande |
| `/api/communities/:id/pending-members/:id/reject` | POST | Admin | Refuse demande |
| `/api/join/pay/:token` | GET | Non | Page paiement post-validation |

### 7.4 Flow Mode OUVERT (adhésion automatique)

```
Visiteur ─────► GET /join/{slug} ─────► Page publique (branding, plans)
                       │
                       ▼
              Remplit formulaire (nom, email, plan)
                       │
                       ▼
              POST /join/{slug}/submit
                       │
                       ├── Plan gratuit ──► INSERT membership (status=active)
                       │                    ──► Email bienvenue + claimCode
                       │
                       └── Plan payant ──► Redirect Stripe Checkout
                                           ──► Webhook success
                                           ──► INSERT membership (status=active, paid)
                                           ──► Email bienvenue + claimCode
```

### 7.5 Flow Mode FERMÉ (validation manuelle)

```
Visiteur ─────► GET /join/{slug} ─────► Page publique (branding, plans)
                       │
                       ▼
              Remplit formulaire (nom, email, plan souhaité)
                       │
                       ▼
              POST /join/{slug}/submit
                       │
                       ▼
              INSERT membership (status=pending_approval, paymentStatus=free)
                       │
                       ├── Email au visiteur "Demande reçue"
                       └── Notif admin "Nouvelle demande"
                       
═══════════════════════════════════════════════════════════════

Admin ──────► Liste demandes en attente
                       │
                       ├── REJETER ──► DELETE membership ou status=suspended
                       │               ──► Email "Demande refusée"
                       │
                       └── VALIDER ──► status=active
                                       │
                                       ├── Plan gratuit ──► Email invitation + claimCode
                                       │
                                       └── Plan payant ──► membershipPaymentStatus=due
                                                          ──► Email "Payez pour activer"
                                                          ──► Lien paiement spécial
```

### 7.6 Page publique Join Link

**URL proposée :** `https://koomy.app/join/{slug}` ou `https://{customDomain}.koomy.app/join`

**Éléments UI :**
- Logo communauté (depuis brandConfig)
- Couleurs de marque (CSS variables)
- Nom communauté
- Message de bienvenue (selfEnrollmentWelcomeText)
- Formulaire : Civilité, Prénom, Nom, Email, (Phone si requis), Sélection plan
- Bouton "S'inscrire" / "Soumettre ma demande"
- Mentions RGPD (checkbox consentement)

---

## 8. Check-list Pré-implémentation

### 8.1 Configuration back-office à implémenter

- [ ] UI: Toggle "Activer inscription autonome"
- [ ] UI: Radio "Mode ouvert / Mode fermé"
- [ ] UI: Input slug personnalisé
- [ ] UI: Sélection plans autorisés (multi-select)
- [ ] UI: Champs requis (email obligatoire, phone optionnel)
- [ ] UI: Textarea message de bienvenue
- [ ] UI: Bouton "Copier lien d'inscription"
- [ ] UI: Vue "Demandes en attente" (si mode fermé)

### 8.2 Migrations DB (conceptuelles, additives)

- [ ] Ajouter valeur 'pending_approval' à enum member_status
- [ ] Ajouter colonnes selfEnrollment* à communities
- [ ] Index sur selfEnrollmentSlug (unique)

### 8.3 Routes à créer

- [ ] GET /api/join/:slug (public, rate limited)
- [ ] POST /api/join/:slug/submit (public, rate limited strict)
- [ ] GET /api/communities/:id/pending-members (admin auth)
- [ ] POST /api/communities/:id/pending-members/:id/approve (admin auth)
- [ ] POST /api/communities/:id/pending-members/:id/reject (admin auth)

### 8.4 Templates email à créer

- [ ] `enrollment_request_received` : Confirmation au visiteur
- [ ] `enrollment_request_notification` : Notif à l'admin
- [ ] `enrollment_approved` : Invitation après validation
- [ ] `enrollment_rejected` : Refus de demande
- [ ] `enrollment_pay_to_activate` : Invitation à payer (mode fermé + payant)

### 8.5 Tests critiques

- [ ] **Sécurité** : Rate limiting route publique (5/h/IP vérifié)
- [ ] **Sécurité** : Pas d'enumération email ("email existe déjà")
- [ ] **Sécurité** : Validation Zod stricte tous champs
- [ ] **Paiement** : Mode OUVERT + plan payant → paiement immédiat obligatoire
- [ ] **Paiement** : Mode FERMÉ → aucune collecte avant validation
- [ ] **Paiement** : Webhook Stripe → activation uniquement après succès
- [ ] **Multi-tenant** : Branding correct selon communityId/slug
- [ ] **Quota** : Pending non comptés dans quota membres
- [ ] **Email** : Templates brandés envoyés correctement
- [ ] **Rollback** : Suppression demande si paiement échoue (mode ouvert)

### 8.6 Feature flags suggérés

```typescript
// Rollout progressif
SELF_ENROLLMENT_ENABLED_COMMUNITIES: string[] // Liste communityIds beta
SELF_ENROLLMENT_CLOSED_MODE_ENABLED: boolean  // Activer mode fermé
SELF_ENROLLMENT_RATE_LIMIT_PER_HOUR: number   // Ajustable
```

### 8.7 Considérations RGPD

- [ ] Collecter consentement explicite (checkbox)
- [ ] Stocker date/heure consentement
- [ ] Lien politique de confidentialité obligatoire
- [ ] Droit de suppression : route existante OK
- [ ] Durée conservation données non-validées : 30 jours max, puis purge

---

## 9. Quota Membres — Analyse Détaillée

### 9.1 Où est calculé le quota aujourd'hui ?

```
Fichier : server/storage.ts
Fonction : checkMemberQuota() (lignes 528-583)
```

**Logique actuelle :**
```typescript
async checkMemberQuota(communityId: string): Promise<{
  canAdd: boolean;
  current: number;
  max: number | null;
  planName: string;
  hasFullAccess: boolean;
  isGrandCompte: boolean;
  alertThreshold?: number;
  usagePercent?: number;
}>
```

**Appel du quota :**
- À chaque création de membre via `storage.createMembership()` (ligne 758)
- Avant insertion DB, on vérifie `quota.canAdd`
- Si `canAdd = false`, on lance `MemberLimitReachedError`

### 9.2 Quels statuts sont comptés ?

**Source actuelle :** `community.memberCount` (colonne dénormalisée dans `communities`)

**Mise à jour :** `updateCommunityMemberCount()` appelée après chaque `createMembership()` :
```typescript
await this.updateCommunityMemberCount(insertMembership.communityId, quota.current + 1);
```

**⚠️ CONSTAT CRITIQUE :**
Le compteur `memberCount` est un **compteur simple** incrémenté à chaque `createMembership()`.
Il **NE DISTINGUE PAS** les statuts (`active`, `expired`, `suspended`).

**Comportement actuel :**
- Une adhésion avec `status = "active"` → comptée
- Une adhésion avec `status = "suspended"` → comptée
- Une adhésion avec `membershipPaymentStatus = "due"` → **COMPTÉE**

### 9.3 Conséquences pour les modes d'inscription

| Scénario | Comportement actuel | Risque |
|----------|---------------------|--------|
| Club OUVERT + gratuit | Quota consommé immédiatement | OK |
| Club OUVERT + payant | Quota consommé AVANT paiement confirmé | **PROBLÈME** : adhésion "due" bloque quota |
| Club FERMÉ | Quota consommé AVANT validation admin | **PROBLÈME** : demandes rejettées consomment quota |

### 9.4 Proposition conceptuelle

**Règle recommandée :**

| Mode | Statut créé | Moment consommation quota |
|------|-------------|---------------------------|
| OUVERT + gratuit | `active` | À la création |
| OUVERT + payant | NE PAS CRÉER adhésion avant paiement | Après webhook succès |
| FERMÉ + gratuit | `pending_approval` | Après validation admin |
| FERMÉ + payant | `pending_approval` | Après validation admin ET paiement |

**Implication technique :**
- Le compteur `memberCount` ne doit **PAS** inclure les `status = "pending_approval"`
- La fonction `createMembership()` doit conditionner l'incrément selon le statut
- Ou : différer l'insert DB jusqu'au moment d'activation

---

## 10. Doublons & Identité (Email / Téléphone)

### 10.1 Contraintes d'unicité actuelles

| Table | Colonne | Contrainte |
|-------|---------|------------|
| `accounts` | `email` | **UNIQUE** (contrainte DB) |
| `users` | `email` | **UNIQUE** (contrainte DB) |
| `userCommunityMemberships` | `email` | **AUCUNE CONTRAINTE** |
| `userCommunityMemberships` | `phone` | **AUCUNE CONTRAINTE** |
| `userCommunityMemberships` | `claimCode` | UNIQUE (quand défini) |
| `userCommunityMemberships` | `memberId` | Non-unique DB (unique par convention préfixe) |

### 10.2 Comportement actuel si email existe déjà

**Dans `accounts` (registration via app) :**
```
Fichier : server/routes.ts (ligne 1294-1296)
```
```typescript
const existingAccount = await storage.getAccountByEmail(email);
if (existingAccount) {
  return res.status(409).json({ error: "An account with this email already exists" });
}
```
→ **Bloque la création** avec message explicite.

**Dans `userCommunityMemberships` :**
Aucune vérification de doublon email. Plusieurs memberships peuvent avoir le même email.

### 10.3 Peut-on avoir plusieurs memberships avec le même email ?

**OUI.** C'est le comportement attendu :
- Un membre peut appartenir à plusieurs communautés
- Chaque membership = 1 carte dans 1 communauté
- Le lien avec `accounts` se fait via `accountId`, pas email

**Mais attention :** Au sein d'une MÊME communauté, un doublon email pourrait être problématique (2 cartes différentes pour la même personne).

### 10.4 Risques spécifiques avec formulaire public

| Risque | Description | Impact |
|--------|-------------|--------|
| Spam inscription | Création massive d'adhésions bidons | Pollution DB, quota atteint |
| Email harvesting | Tester si un email existe dans le système | Vie privée |
| Doublon même communauté | 2 inscriptions avec même email | Confusion admin |
| Comptes séparés | Inscription avec email sans compte existant | Impossible de lier carte |

### 10.5 Options conceptuelles possibles

**Option A : Bloquer si email existe dans la communauté**
- Vérifier `SELECT COUNT(*) FROM userCommunityMemberships WHERE communityId = ? AND email = ?`
- Message générique : "Cette adresse email est déjà utilisée"
- ⚠️ Permet l'énumération d'emails

**Option B : Fusionner automatiquement**
- Si email existe dans `accounts`, lier directement `accountId`
- Risque : quelqu'un peut "squatter" un email d'un autre
- Requiert validation email obligatoire

**Option C : Avertir sans bloquer**
- Créer la membership même si email existe
- Notifier l'admin : "Email déjà utilisé par membre X"
- Laisser l'admin décider

**Recommandation :** Option A avec message GÉNÉRIQUE (pas "cet email existe") :
> "Impossible de traiter cette inscription. Veuillez contacter le club."

---

## 11. Moment de Création des Artefacts Clés

### 11.1 Génération actuelle

| Artefact | Fichier | Moment | Fonction |
|----------|---------|--------|----------|
| `memberId` | server/routes.ts (ligne 51) | AVANT insert DB | `generateMemberId(communityId)` |
| `claimCode` | server/routes.ts (ligne 41) | AVANT insert DB | `generateClaimCode()` |

**Détail `generateMemberId()` :**
```typescript
async function generateMemberId(communityId: string): Promise<string> {
  const community = await storage.getCommunity(communityId);
  if (!community || !community.memberIdPrefix) {
    return `MBR-${Date.now().toString(36).toUpperCase()}-${random}`;
  }
  // Atomic increment via SQL UPDATE + RETURNING
  const result = await db.execute(sql`
    UPDATE communities 
    SET member_id_counter = member_id_counter + 1
    ...
  `);
  return `${prefix}-${paddedCounter}`;
}
```

**⚠️ PROBLÈME :** `memberId` avec compteur atomique = consomme le compteur même si membership jamais créée (échec paiement, refus, etc.)

### 11.2 Envoi email actuel

```
Fichier : server/routes.ts (lignes 3114-3127)
```

**Moment :** APRÈS insert DB réussi
```typescript
const membership = await storage.createMembership(payload);

if (validated.email) {
  const result = await sendMemberInviteEmail(
    validated.email,
    validated.displayName,
    community?.name,
    claimCode,
    { communityId }
  );
}
```

### 11.3 Emails problématiques si envoyés trop tôt

| Email | Problème si envoyé trop tôt |
|-------|----------------------------|
| `invite_member` (claimCode) | Membre peut tenter d'activer carte sans avoir payé |
| Email de bienvenue | Fausse promesse si paiement échoue |
| Confirmation inscription | OK si générique ("demande reçue") |

### 11.4 Proposition : bon moment par mode

**Club OUVERT + gratuit :**
1. Générer `memberId` ✓
2. Générer `claimCode` ✓
3. INSERT membership (status=active, paymentStatus=free) ✓
4. Envoyer `invite_member` avec claimCode ✓
5. Incrémenter quota ✓

**Club OUVERT + payant :**
1. Valider formulaire
2. **NE PAS** insérer membership
3. Créer Stripe Checkout Session avec metadata (prénom, nom, email, planId, communityId)
4. Rediriger vers Stripe
5. **Webhook succès :**
   - Générer `memberId`
   - Générer `claimCode`
   - INSERT membership (status=active, paymentStatus=paid)
   - Envoyer `invite_member`
   - Incrémenter quota

**Club FERMÉ (gratuit ou payant) :**
1. Générer `memberId` (ou identifiant temporaire)
2. **NE PAS** générer claimCode (pas encore membre)
3. INSERT membership (status=pending_approval, paymentStatus=free)
4. Envoyer email "Demande reçue" au visiteur
5. Notifier admin
6. **NE PAS** incrémenter quota
7. **Si admin valide :**
   - Générer claimCode
   - Mettre status=active (si gratuit) ou déclencher paiement (si payant)
   - Envoyer `invite_member`
   - Incrémenter quota

---

## 12. Paiement Immédiat (Club OUVERT Payant) — Compatibilité Existant

### 12.1 Logique actuelle `membershipPaymentStatus = "due"`

**Attribution :**
```
Fichier : server/routes.ts (lignes 3041-3073)
```
```typescript
let membershipPaymentStatus: "free" | "due" | "paid" = "free";
let membershipAmountDue = 0;

if (validated.membershipPriceCustom > 0) {
  membershipPaymentStatus = "due";
  membershipAmountDue = validated.membershipPriceCustom;
} else if (membershipPlanId && plan.amount > 0) {
  membershipPaymentStatus = "due";
  membershipAmountDue = plan.amount;
}
```

**État après création :** Membership existe avec `paymentStatus = "due"`, membre peut accéder à l'app mais voit bannière "Payer adhésion".

### 12.2 Est-ce compatible avec paiement immédiat ?

**NON pour le mode OUVERT payant.**

**Problème :** La logique actuelle suppose :
1. Admin crée le membre (en back-office)
2. Membre reçoit email avec claimCode
3. Membre active sa carte dans l'app
4. Membre voit qu'il doit payer
5. Membre paie quand il veut

**Ce qu'il faut pour OUVERT payant :**
1. Visiteur remplit formulaire
2. Visiteur paie IMMÉDIATEMENT (Stripe Checkout)
3. Si paiement réussi → création membre
4. Membre reçoit email avec claimCode
5. Membre active sa carte

### 12.3 Risques adhésion "due" sans paiement confirmé

| Risque | Conséquence |
|--------|-------------|
| Quota consommé | Limite membres atteinte par des "payeurs en attente" |
| Accès app sans paiement | Visiteur peut voir contenu (actualités, événements) |
| claimCode envoyé | Visiteur peut activer carte sans avoir payé |
| Données en base | Adhésions fantômes à nettoyer |

### 12.4 Clarification : avant/après paiement

| Moment | Ce qui doit exister | Ce qui ne doit pas exister |
|--------|---------------------|---------------------------|
| AVANT paiement (OUVERT payant) | Session Stripe avec metadata | Ligne `userCommunityMemberships` |
| APRÈS paiement confirmé (webhook) | Membership avec status=active, paymentStatus=paid | - |

**Metadata Stripe à stocker AVANT paiement :**
```typescript
{
  payment_reason: "self_enrollment",
  communityId: string,
  membershipPlanId: string,
  firstName: string,
  lastName: string,
  email: string,
  phone?: string,
  selfEnrollmentMode: "open"
}
```

---

## 13. Messages Utilisateur & UX Critique

### 13.1 Messages affichés aujourd'hui (paiement dû)

```
Fichier : client/src/components/PaymentBanner.tsx
```

| Élément | Texte actuel |
|---------|--------------|
| Titre | "Adhésion à finaliser" |
| Montant | "Montant : {amount}" |
| Bouton primaire | "Payer maintenant" |
| Bouton secondaire | "Plus tard" |
| Comportement dismiss | Masqué 24h puis réaffiché |

### 13.2 Messages manquants

| Situation | Message manquant | Criticité |
|-----------|------------------|-----------|
| Quota atteint (formulaire public) | "Les inscriptions sont temporairement fermées. Contactez le club." | **HAUTE** |
| Demande en attente (mode fermé) | "Votre demande a été transmise. Vous recevrez une réponse par email." | **HAUTE** |
| Demande refusée | "Votre demande d'adhésion n'a pas été acceptée." | **HAUTE** |
| Email déjà utilisé | "Cette inscription n'a pas pu aboutir. Contactez le club." | **MOYENNE** |
| Paiement abandonné | "Votre inscription n'a pas été finalisée. Recommencez." | **MOYENNE** |
| Paiement échoué | "Le paiement a échoué. Veuillez réessayer." | **HAUTE** |
| Inscription réussie (gratuit) | "Bienvenue ! Téléchargez l'app et activez votre carte avec ce code : XXXX-XXXX" | **HAUTE** |
| Inscription réussie (payant) | "Merci pour votre paiement ! Téléchargez l'app..." | **HAUTE** |

### 13.3 Points UX critiques (éviter support & litiges)

| Point | Recommandation |
|-------|----------------|
| Double inscription | Empêcher soumettre 2 fois le formulaire (disable button, loading state) |
| Timeout paiement | Informer que la session expire après 30 min |
| Email non reçu | Bouton "Renvoyer l'email" avec rate limit |
| Montant affiché | Toujours afficher TTC avec devise claire |
| Remboursement | Mentionner politique de remboursement avant paiement |
| Données personnelles | Case à cocher RGPD visible et obligatoire |
| Club non trouvé | "Ce lien n'est plus valide" (slug inexistant ou désactivé) |
| Mode maintenance | "Les inscriptions sont temporairement suspendues" |

---

## 14. Synthèse : Décisions Produit à Figer AVANT Implémentation

### 14.1 Éléments FIGÉS (confirmés)

| Décision | Statut |
|----------|--------|
| Deux modes exclusifs : OUVERT / FERMÉ | ✅ FIGÉ |
| Mode OUVERT payant = paiement immédiat obligatoire | ✅ FIGÉ |
| Mode FERMÉ = aucun paiement avant validation | ✅ FIGÉ |
| Formulaire public brandé au nom du club | ✅ FIGÉ |
| Quota consommé uniquement après activation | ✅ FIGÉ |
| Administrateur peut activer/désactiver le join link | ✅ FIGÉ |

### 14.2 Éléments nécessitant DÉCISION PRODUIT

| Question | Options | Recommandation |
|----------|---------|----------------|
| **Gestion doublon email même communauté** | A) Bloquer / B) Fusionner / C) Avertir admin | A) Bloquer avec message générique |
| **Doublon email cross-communautés** | A) Lier auto / B) Créer indépendant | B) Indépendant (comportement actuel) |
| **Génération memberId** | A) Avant paiement / B) Après webhook | B) Après webhook (évite trous compteur) |
| **Durée de vie demande FERMÉ** | A) Illimitée / B) 30 jours / C) Configurable | B) 30 jours avec purge auto |
| **Notification admin nouvelle demande** | A) Email / B) Push back-office / C) Les deux | A) Email (simple V1) |
| **Champs formulaire** | A) Fixe / B) Configurable par club | A) Fixe V1 (Civilité, Prénom, Nom, Email, [Phone]) |
| **Sélection section** | A) Obligatoire / B) Optionnelle / C) Masquée | C) Masquée V1 (simplifier UX) |
| **Gestion quota atteint** | A) Message + stop / B) Liste d'attente | A) Message + stop (V1) |
| **Email validation** | A) Optionnel / B) Obligatoire avant activation | B) Obligatoire (sécurité) |

### 14.3 Éléments FLEXIBLES en V1

| Élément | Comportement V1 suggéré | Évolution future possible |
|---------|------------------------|--------------------------|
| Personnalisation message accueil | Champ texte simple | Éditeur riche, images |
| Choix du plan | Liste tous les plans actifs | Filtrer par tag/section |
| Design page | Template standard brandé | Templates multiples |
| Rappel demande non traitée | Non | Email admin J+3, J+7 |
| Analytics inscriptions | Non | Dashboard conversions |
| CAPTCHA | Non (rate limit suffit) | Optionnel si abus |

### 14.4 Ambiguïtés NON LEVÉES (à clarifier)

| Question | Contexte | Impact |
|----------|----------|--------|
| **Que faire si visiteur a déjà un account Koomy ?** | Email existe dans `accounts` mais pas de membership dans cette communauté | Créer membership liée à account ? Demander connexion ? |
| **Validation email obligatoire pour mode OUVERT gratuit ?** | Actuellement envoi claimCode sans vérification | Risque : email erroné = carte inaccessible |
| **Peut-on changer de mode (OUVERT → FERMÉ) avec demandes en cours ?** | Club change d'avis | Que deviennent les demandes pending ? |
| **Remboursement si refus post-paiement (edge case FERMÉ payant) ?** | Théoriquement impossible mais race condition possible | Process remboursement manuel ? |

---

## Décisions Produit V1 (contrat)

### 0) Canal d'onboarding (choix club)
- OFFLINE (par défaut): création/import via back-office.
- ONLINE: activation d'un lien d'inscription public (join link).

### 1) Demande ≠ Adhésion
Une demande ne doit:
- ni consommer quota
- ni générer claimCode
- ni envoyer d'email d'activation

### 2) ONLINE + OUVERT + PAYANT
- ZÉRO création DB avant paiement
- Stripe = filtre d'entrée
- Activation uniquement après confirmation de paiement (webhook)

### 3) Quota
- Compteur consommé uniquement à l'activation réelle
- Jamais sur une demande
- Jamais avant paiement (ouvert payant)

### 4) ONLINE modes
- OUVERT: tout le monde peut s'inscrire (dans limite quota)
- FERMÉ: formulaire = demande, validation/refus, puis paiement si payant

### 5) Quota atteint (UX V1)
- Afficher: "Limite d'adhésions atteinte, contactez le club"
- (Option V1 recommandée) Bloquer toute nouvelle inscription/demande quand quota atteint.

---

## Identité & Email — Vision globale plateforme

- Koomy est une plateforme de **gestion d'adhésions** reposant sur un **socle wallet** au niveau technique.
- Un `account` représente une identité technique unique dans un **univers de distribution donné**.
- Un `account` peut regrouper :
  - plusieurs clubs
  - plusieurs adhésions
  - plusieurs adhérents dans un même club (ex : parent + enfants).
- Le concept de wallet est **structurel**, mais **peut être masqué à l'utilisateur final** selon le canal de distribution.

---

## Univers de distribution (notion clé)

Il existe deux univers de distribution distincts :

### 1) Univers Koomy assumé
- L'utilisateur sait explicitement qu'il est sur Koomy.
- Le concept de compte Koomy et de regroupement d'adhésions est compréhensible et acceptable.

### 2) Univers Marque blanche
- Koomy est volontairement masqué.
- L'utilisateur pense être **uniquement** dans l'application du club.
- Aucune référence à Koomy, au wallet ou à d'autres clubs ne doit être faite.

👉 Ces deux univers sont **volontairement étanches au niveau UX**, même s'ils reposent sur le même socle technique.

---

## Email existant lors du self-onboarding — RÈGLES OFFICIELLES

### Cas A — Email existant dans le MÊME univers de distribution

Si un utilisateur saisit un email qui existe déjà dans `accounts`
**dans le même univers de distribution** (Koomy → Koomy, ou Marque blanche → même marque blanche) :

1. Une **authentification est OBLIGATOIRE avant toute suite**
   (login / magic link / OTP).
2. Une fois authentifié :
   - la nouvelle adhésion / le nouvel adhérent est
     **rattaché(e) au même account existant**.
3. L'utilisateur reste STRICTEMENT dans le même univers UX
   (même app, même branding, même narration).

---

### Cas B — Email existant dans une MARQUE BLANCHE → self-onboarding dans Koomy assumé

Lorsque :
- un utilisateur possède déjà un compte dans une application marque blanche
- ET que cette marque blanche masque volontairement Koomy
- ET que l'utilisateur s'inscrit dans un club **distribué via l'app Koomy**
  (univers Koomy assumé)

ALORS :

- La plateforme autorise la **création d'un nouvel account Koomy**
  même si l'email existe déjà dans une marque blanche.
- Aucune authentification vers l'univers marque blanche ne doit être imposée.
- Aucune référence à la marque blanche existante ne doit être faite.
- L'utilisateur est considéré comme **nouvel utilisateur dans l'univers Koomy**.

👉 Cette exception est **volontaire, documentée et assumée**,
afin de respecter la séparation des univers de distribution.

---

## Paiement & Email existant (ONLINE + OUVERT + PAYANT)

- En mode ONLINE + OUVERT + PAYANT :
  - si une authentification est requise, elle doit TOUJOURS avoir lieu AVANT paiement.
  - aucun paiement ne peut être déclenché sans account identifié
    dans l'univers courant.
  - aucune création DB ne peut avoir lieu avant confirmation de paiement
    (webhook Stripe).
- Stripe reste le **seul filtre d'entrée** avant activation réelle.

---

## Marque blanche vs App Koomy — UX & narration

### Niveau plateforme (invisible)
- Tous les comptes et adhésions sont gérés par la plateforme Koomy.
- Le wallet existe toujours techniquement.

### UX Marque blanche
- Le concept de wallet n'est JAMAIS exposé.
- L'utilisateur a l'impression d'être uniquement dans l'app du club.
- En cas d'email existant (dans la même marque blanche),
  le message doit rester neutre, par exemple :
  > "Un compte existe déjà avec cet email. Connectez-vous pour continuer."
- Aucune mention de Koomy, multi-club ou autres adhésions.

### UX App Koomy
- Le concept de wallet est assumé.
- Les différentes adhésions peuvent être regroupées et visibles.

---

## Distribution dans l'app Koomy (règle stratégique)

- Tous les clubs existent techniquement dans la plateforme Koomy.
- Un club n'est visible dans l'app Koomy QUE s'il accepte explicitement
  d'être distribué via l'app Koomy.
- La distribution est un CHOIX BUSINESS du club.
- L'existence technique d'un account ou d'une adhésion
  n'implique AUCUNE visibilité dans l'app Koomy.

---

## Règle stricte de non-divulgation

- Il est STRICTEMENT interdit :
  - d'indiquer à un utilisateur marque blanche
    qu'il possède d'autres clubs ou adhésions ailleurs.
  - de révéler l'existence du wallet Koomy en marque blanche.
- La plateforme peut regrouper silencieusement des données
  sans jamais les exposer.

---

## Rappel des décisions produit déjà figées (référence)

- OFFLINE par défaut, ONLINE optionnel.
- ONLINE → OUVERT ou FERMÉ.
- Demande ≠ adhésion.
- ZÉRO création DB avant paiement en OUVERT payant.
- Quota consommé uniquement à l'activation réelle.
- Blocage du self-onboarding quand quota atteint (V1).

---

## Annexes

### A. Fichiers référencés

| Fichier | Rôle |
|---------|------|
| `shared/schema.ts` | Schéma Drizzle (tables, enums, types) |
| `server/routes.ts` | Routes API Express |
| `server/storage.ts` | Interface storage + implémentation |
| `server/stripe.ts` | Fonctions Stripe (checkout, webhooks) |
| `server/stripeConnect.ts` | Stripe Connect Express |
| `server/services/mailer/` | Emails transactionnels |
| `client/src/contexts/WhiteLabelContext.tsx` | Résolution multi-tenant frontend |
| `tenants/{slug}/wl.json` | Config white-label embarquée |

### B. Enums existants pertinents

```typescript
memberStatusEnum: ["active", "expired", "suspended"]
membershipPaymentStatusEnum: ["free", "due", "paid"]
contributionStatusEnum: ["up_to_date", "expired", "pending", "late"]
```

### C. Métadonnées Stripe existantes

```typescript
// Checkout Session metadata (membership payment)
{
  payment_reason: "membership",
  membershipId: string,
  communityId: string,
  accountId: string
}
```

---

*Fin du document d'audit*
