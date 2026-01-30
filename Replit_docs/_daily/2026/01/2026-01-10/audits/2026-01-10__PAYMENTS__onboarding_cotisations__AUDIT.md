# Audit Technique - Onboarding: Cotisations & Carte Bancaire

**Date**: 19 janvier 2026  
**Statut**: Audit (pas d'implémentation)  
**Version**: 1.0

---

## PARTIE 1: Audit Étape "Paramètres d'adhésion"

### A) Localisation de l'étape dans l'onboarding

| Élément | Détail |
|---------|--------|
| **Fichier principal** | `client/src/pages/admin/Register.tsx` |
| **Lignes concernées** | 670-810 (rendu step 3), 247-251 (sidebar step 3) |
| **Composant** | Intégré dans `AdminRegister` (pas de composant séparé) |

#### Logique du stepper

```typescript
// Ligne 52: état local du step
const [step, setStep] = useState(1);

// Lignes 129-135: navigation entre steps
const handleNextStep = () => {
  if (step === 1 && validateStep1()) {
    setStep(2);
  } else if (step === 2 && validateStep2()) {
    setStep(3);
  }
};
```

**Structure des 3 étapes actuelles**:
| Step | Titre | Contenu |
|------|-------|---------|
| 1 | "Créer votre compte" | Prénom, Nom, Email, Téléphone, Mot de passe |
| 2 | "Votre communauté" | Nom, Type, Catégorie, Description, Adresse, Logo |
| 3 | "Paramètres d'adhésion" | Message d'accueil, Toggle cotisations, Montant, Devise, Période |

#### État local modifié par l'écran cotisations

```typescript
// Lignes 86-90 dans formData
membershipFeeEnabled: false,   // boolean
membershipFeeAmount: "",       // string (converti en cents)
currency: "EUR",               // string
billingPeriod: "yearly"        // string
```

---

### B) Caractéristiques de l'étape

| Question | Réponse |
|----------|---------|
| **Bloquante ?** | ❌ NON - L'étape est affichée mais on peut soumettre avec `membershipFeeEnabled: false` |
| **Skippable ?** | ❌ NON - Pas de bouton "Ignorer", mais le toggle est optionnel |
| **Conditionnelle ?** | ❌ NON - Toujours affichée comme step 3 |

**Note**: Le contenu des cotisations est affiché conditionnellement uniquement si le toggle est activé:
```typescript
// Ligne 708
{formData.membershipFeeEnabled && (
  // Affiche montant, devise, période
)}
```

---

### C) APIs appelées lors de la validation

| Élément | Détail |
|---------|--------|
| **Endpoint** | `POST /api/admin/register` |
| **Fichier backend** | `server/routes.ts` ligne 2191 |

**Payload envoyé** (lignes 142-165):
```typescript
{
  // Step 1 - Compte
  firstName, lastName, email, phone, password,
  
  // Step 2 - Communauté  
  communityName, communityType, communityTypeOther, category, description,
  address, city, postalCode, country, contactEmail, contactPhone, logo,
  
  // Step 3 - Cotisations
  welcomeMessage,
  membershipFeeEnabled,      // boolean
  membershipFeeAmount,       // number (cents) ou null
  currency,                  // string
  billingPeriod              // string
}
```

**Conséquences en DB**:
- Création user dans table `users`
- Création community dans table `communities` avec champs:
  - `membershipFeeEnabled` (boolean)
  - `membershipFeeAmount` (integer, nullable)
  - `currency` (varchar)
  - `billingPeriod` (varchar)
  - `welcomeMessage` (text, nullable)
- Création membership avec role `super_admin`

**⚠️ Aucun appel Stripe à l'inscription** - Le customer Stripe n'est créé que plus tard lors de l'activation d'une souscription.

---

## PARTIE 2: Plan d'Implémentation - Retrait Étape Cotisations

### Étapes proposées (7 étapes)

#### Étape 1: Modifier le stepper (2 étapes au lieu de 3)

**Fichier**: `client/src/pages/admin/Register.tsx`

- Supprimer le rendu de l'étape 3 dans la sidebar (lignes 247-251)
- Modifier les progress bars (3 → 2 barres, lignes 271-273)
- Modifier les titres conditionnels (ligne 276)

#### Étape 2: Modifier la navigation

**Fichier**: `client/src/pages/admin/Register.tsx`

- Step 2 devient l'étape finale → soumettre au lieu de `setStep(3)`
- Modifier `handleNextStep()` pour déclencher `handleSubmit()` après step 2

#### Étape 3: Déplacer le message d'accueil (optionnel)

Le "Message d'accueil" peut être:
- **Option A**: Conservé dans step 2 (fin du formulaire communauté)
- **Option B**: Supprimé et ajouté dans Settings plus tard

**Recommandation**: Option A (garder dans step 2)

#### Étape 4: Supprimer les champs cotisations du formData initial

Retirer:
```typescript
membershipFeeEnabled: false,
membershipFeeAmount: "",
billingPeriod: "yearly"
```

Garder `currency: "EUR"` car utilisé ailleurs.

#### Étape 5: Modifier le payload API

Envoyer des valeurs par défaut:
```typescript
membershipFeeEnabled: false,
membershipFeeAmount: null,
currency: "EUR",
billingPeriod: "yearly"
```

#### Étape 6: Vérifier l'accès backoffice existant

**Pages existantes pour configurer les cotisations**:

| Page | Route | Fichier |
|------|-------|---------|
| Finances | `/admin/finances` | `client/src/pages/admin/Finances.tsx` |
| Settings | `/admin/settings` | `client/src/pages/admin/Settings.tsx` |
| Payments | `/admin/payments` | `client/src/pages/admin/Payments.tsx` |

**Recommandation**: Les cotisations sont déjà configurables via `/admin/settings` ou `/admin/finances`. Aucune nouvelle page nécessaire.

#### Étape 7: Tests manuels

Voir checklist ci-dessous.

---

### Checklist de Tests Manuels

- [ ] Register (free) → onboarding 2 étapes → accès dashboard OK
- [ ] Création communauté sans logo → OK
- [ ] Création communauté avec logo → OK
- [ ] Message d'accueil optionnel → OK
- [ ] Accès `/admin/settings` → section cotisations accessible
- [ ] Pas de régression sur `/admin/login`
- [ ] Pas de régression sur `/website/pricing`
- [ ] Backend: communauté créée avec `membershipFeeEnabled: false`

---

## PARTIE 3: Audit Carte Bancaire à 0€

### A) État actuel Stripe / Paiement

| Question | Réponse |
|----------|---------|
| **Stripe initialisé à l'inscription ?** | ❌ NON |
| **Customer Stripe créé à l'inscription ?** | ❌ NON |
| **SetupIntent existant ?** | ❌ NON à l'inscription |
| **Sauvegarde moyen de paiement ?** | ❌ NON à l'inscription |

**Moment où Stripe intervient actuellement**:
- Customer Stripe créé lors de la première souscription (via `createSubscription` dans `server/stripe.ts` ligne 63-73)
- Aucune interaction Stripe pendant l'onboarding initial

**Code actuel** (`server/stripe.ts` lignes 63-73):
```typescript
let customerId = community.stripeCustomerId;
if (!customerId) {
  const customer = await stripe.customers.create({
    email: community.contactEmail || '',
    name: community.name,
    metadata: { communityId: community.id }
  });
  customerId = customer.id;
  await storage.updateCommunity(community.id, {
    stripeCustomerId: customerId,
  });
}
```

---

### B) Faisabilité technique "CB obligatoire à 0€"

#### Est-ce possible techniquement ?

✅ **OUI** - Via Stripe SetupIntent

**Mécanisme**:
1. Créer un `SetupIntent` (pas de paiement, juste vérification)
2. Collecter la carte via Stripe Elements
3. Sauvegarder le `PaymentMethod` attaché au customer
4. Aucun prélèvement déclenché

**Code type**:
```typescript
// Backend: créer SetupIntent
const setupIntent = await stripe.setupIntents.create({
  customer: customerId,
  payment_method_types: ['card'],
  usage: 'off_session', // pour pouvoir débiter plus tard
});

// Frontend: collecter via Stripe Elements
const { error } = await stripe.confirmCardSetup(clientSecret, {
  payment_method: { card: cardElement }
});
```

#### Où insérer cette étape ?

| Option | Placement | Avantages | Inconvénients |
|--------|-----------|-----------|---------------|
| A | Fin onboarding (step 3) | Flow linéaire | Friction avant 1er accès |
| B | Juste avant dashboard | Onboarding terminé, CB = portail | UX confuse |
| C | Post-onboarding, bloquant | Dashboard visible mais actions bloquées | Complexe à implémenter |

**Recommandation**: Option A (step 3 dédié CB)

---

### C) Impacts produit

#### Avantages

| Avantage | Impact |
|----------|--------|
| Filtrage comptes non sérieux | ✅ Élevé |
| Réduction spam/abus | ✅ Élevé |
| Signal de confiance | ✅ Moyen |
| Prêt pour upsell | ✅ Élevé (CB déjà enregistrée) |

#### Risques

| Risque | Impact | Mitigation |
|--------|--------|------------|
| Friction excessive | ⚠️ Élevé | Communication claire "0€ prélevé" |
| Associations peu bancarisées | ⚠️ Moyen | Alternative: vérification email renforcée |
| Support accru | ⚠️ Moyen | FAQ + explication contextuelle |
| Taux conversion en baisse | ⚠️ Élevé (estimé -15-30%) | A/B test recommandé |

#### Impact estimé sur conversion

| Scénario | Taux conversion estimé |
|----------|------------------------|
| Actuel (sans CB) | Baseline 100% |
| CB obligatoire | -20% à -35% |
| CB skippable | -5% à -10% |

---

## PARTIE 4: 3 Scénarios Proposés

### Option 1: CB Obligatoire dès l'inscription (0€)

**Flow**:
```
Step 1: Compte → Step 2: Communauté → Step 3: Carte Bancaire → Dashboard
```

**Implémentation**:
1. Créer customer Stripe à la fin du step 2
2. Créer SetupIntent
3. Afficher Stripe Elements (CardElement)
4. Valider la carte avant accès dashboard
5. Stocker `stripeCustomerId` + `defaultPaymentMethod`

**Avantages**:
- Filtrage maximal
- CB prête pour facturation future
- Flow linéaire simple

**Inconvénients**:
- Friction maximale
- Baisse conversion estimée: -25%
- Support: "Pourquoi ma CB si c'est gratuit ?"

**Condition si refus**: Aucun accès, compte non créé

---

### Option 2: CB Demandée mais Skippable

**Flow**:
```
Step 1: Compte → Step 2: Communauté → Step 3: CB (optionnel) → Dashboard
                                        ↳ "Ajouter plus tard" →
```

**Implémentation**:
1. Afficher étape CB avec bouton "Ajouter plus tard"
2. Si skip: accès dashboard avec bandeau persistant
3. Bloquer certaines actions sans CB:
   - Activer cotisations membres
   - Créer événements payants
   - Upgrade de plan

**Avantages**:
- Moins de friction
- Conversion préservée
- Rappel visible

**Inconvénients**:
- Moins de filtrage anti-abus
- Logique conditionnelle complexe
- UX "nag screen" désagréable

**Actions bloquées sans CB**:
- Activation paiements membres
- Événements payants
- Souscription plan payant

---

### Option 3: Pas de CB à l'inscription (V1 actuel)

**Flow actuel**:
```
Step 1: Compte → Step 2: Communauté → Dashboard
```

**Alternatives anti-abus**:

| Mesure | Complexité | Efficacité |
|--------|------------|------------|
| Vérification email obligatoire | ✅ Faible | ⚠️ Moyenne |
| Cloudflare Turnstile (captcha invisible) | ✅ Faible | ✅ Élevée |
| Rate limiting IP | ✅ Faible | ⚠️ Moyenne |
| Validation domaine email | ⚠️ Moyenne | ⚠️ Moyenne |
| Téléphone SMS OTP | ⚠️ Élevée | ✅ Élevée |

**À partir de quand demander la CB**:
- Avant d'activer les cotisations membres
- Avant de créer un événement payant
- Avant de passer à un plan payant

**Avantages**:
- Friction minimale
- Conversion maximale
- Implémentation simple (déjà en place)

**Inconvénients**:
- Pas de filtrage initial
- Comptes "fantômes" possibles
- CB demandée plus tard = friction différée

---

## PARTIE 5: Recommandation

### Recommandation: Option 3 + Mesures anti-abus

**Justification**:
1. **Conversion prioritaire** en phase de lancement
2. **Friction reportée** au moment où l'utilisateur a une intention d'achat
3. **Mesures anti-abus** légères mais efficaces

**Mesures à implémenter**:
1. ✅ Vérification email (déjà en place ou à activer)
2. ✅ Rate limiting (déjà en place via `express-rate-limit`)
3. 🆕 Cloudflare Turnstile (captcha invisible, facile à ajouter)

**CB demandée au moment de**:
- Upgrade vers plan payant
- Activation des paiements membres
- Premier événement payant

---

## PARTIE 6: Plan d'Implémentation Théorique par Option

### Option 1: CB Obligatoire

| Étape | Description | Effort |
|-------|-------------|--------|
| 1 | Créer composant `StripeCardStep.tsx` | Moyen |
| 2 | Intégrer Stripe Elements (CardElement) | Moyen |
| 3 | API `POST /api/setup-intent` | Faible |
| 4 | Confirmer SetupIntent + stocker PaymentMethod | Moyen |
| 5 | Modifier Register.tsx (step 3 = CB) | Faible |
| 6 | Tests E2E Stripe | Élevé |

**Dépendances Stripe**: `@stripe/stripe-js`, `@stripe/react-stripe-js`

**Points de vigilance**:
- RGPD: Consentement explicite pour stockage CB
- PCI DSS: Ne jamais stocker les numéros de carte côté serveur
- UX: Message clair "Aucun prélèvement, vérification uniquement"

### Option 2: CB Skippable

| Étape | Description | Effort |
|-------|-------------|--------|
| 1-4 | Idem Option 1 | - |
| 5 | Ajouter bouton "Ajouter plus tard" | Faible |
| 6 | Créer bannière persistante sans CB | Faible |
| 7 | Logique blocage actions sans CB | Moyen |
| 8 | Tests conditionnels | Moyen |

### Option 3: Pas de CB + Anti-abus

| Étape | Description | Effort |
|-------|-------------|--------|
| 1 | Retirer step cotisations (voir Partie 2) | Faible |
| 2 | Vérifier rate limiting actif | Faible |
| 3 | Ajouter Cloudflare Turnstile | Faible |
| 4 | CB demandée lors activation paiements | Moyen |

---

## Checklist de Tests (toutes options)

- [ ] Inscription sans CB → succès
- [ ] Inscription avec CB valide → succès
- [ ] Inscription avec CB invalide → erreur claire
- [ ] CB 3D Secure → flow géré
- [ ] Annulation step CB → comportement attendu
- [ ] Customer Stripe créé correctement
- [ ] PaymentMethod attaché au customer
- [ ] Pas de double facturation
- [ ] RGPD: Données carte non stockées côté serveur

---

## ⚠️ IMPORTANT

**Aucune implémentation sans validation explicite.**

Ce document est un audit et des propositions. L'implémentation nécessite:
1. Validation du choix d'option par le produit
2. Validation des changements backend
3. Tests en environnement sandbox Stripe
