# 🔍 KOOMY — AUDIT PARCOURS PLAN PAYANT

**Date:** 19 Janvier 2026  
**Type:** READ-ONLY (aucune modification de code)  
**Gravité:** ⚠️ **CRITIQUE**

---

## 1. Résumé Exécutif

Le paiement n'est **jamais exigé** lors de l'inscription avec un plan payant. Le club est créé avec un plan FREE malgré la sélection d'un plan payant, et l'accès au back-office est immédiat et complet.

### Cause Racine Identifiée
Le paramètre `planId` sélectionné par l'utilisateur n'est **jamais transmis au backend**. Le backend force systématiquement `planId: "free"`.

---

## 2. Parcours Réel Utilisateur (Factuel)

### Étape 1: Sélection du Plan (Website)
| Élément | Détail |
|---------|--------|
| **Page** | `/pricing` |
| **Action** | Clic sur "Choisir Plus" (12€/mois) |
| **Résultat** | Redirection vers `/admin/register?plan=plus` |
| **Plan affiché** | ✓ "Plus" visible dans l'URL et l'UI |

### Étape 2: Inscription (Register.tsx)
| Élément | Détail |
|---------|--------|
| **URL** | `/admin/register?plan=plus` |
| **UI affichée** | Badge "Plan sélectionné: Plus (12€/mois)" |
| **Variable `selectedPlan`** | ✓ Correctement parsé depuis l'URL |
| **Formulaire** | 2 étapes: Compte → Communauté |

### Étape 3: Soumission (handleSubmit)
| Élément | Détail |
|---------|--------|
| **API appelée** | `POST /api/admin/register` |
| **Payload envoyé** | ❌ **`planId` ABSENT du payload** |
| **Payload réel** | `{ firstName, lastName, email, ..., membershipFeeEnabled: false, currency: "EUR" }` |

**Extrait du code (Register.tsx lignes 123-146):**
```typescript
const response = await apiPost('/api/admin/register', {
  firstName: formData.firstName,
  lastName: formData.lastName,
  // ... autres champs
  membershipFeeEnabled: false,
  currency: "EUR",
  billingPeriod: "yearly"
  // ❌ AUCUN planId envoyé!
});
```

### Étape 4: Traitement Backend (routes.ts)
| Élément | Détail |
|---------|--------|
| **Endpoint** | `/api/admin/register` (ligne 2191) |
| **planId appliqué** | ❌ **Forcé à "free" (ligne 2244)** |
| **Stripe checkout** | ❌ **Non déclenché** |
| **Redirection Stripe** | ❌ **Aucune** |

**Extrait du code (routes.ts lignes 2226-2248):**
```typescript
const community = await storage.createCommunity({
  name: communityName,
  // ... autres champs
  planId: "free",  // ❌ TOUJOURS "free" quel que soit le plan sélectionné
  subscriptionStatus: "active",  // ❌ Active immédiatement sans paiement
});
```

### Étape 5: Post-Inscription
| Élément | Détail |
|---------|--------|
| **Redirection** | `/admin/dashboard` |
| **Accès back-office** | ✓ Complet |
| **Plan affiché** | "Free" (pas "Plus") |
| **Paiement requis** | ❌ Jamais |

---

## 3. Analyse Logique Métier

### 3.1 Où le Paiement Est Supposé Être Déclenché

L'endpoint Stripe existe : `POST /api/payments/create-koomy-subscription-session` (routes.ts ligne 7045)

```typescript
app.post("/api/payments/create-koomy-subscription-session", async (req, res) => {
  const { communityId, billingPlan, billingPeriod } = req.body;
  // ... crée une session Stripe Checkout
});
```

**Cet endpoint n'est JAMAIS appelé dans le flux d'inscription.**

### 3.2 Pourquoi le Paiement N'Est Pas Déclenché

| Point de Défaillance | Explication |
|---------------------|-------------|
| **Frontend** | `selectedPlan` est affiché mais JAMAIS envoyé au backend |
| **Backend** | Force `planId: "free"` sans condition |
| **Post-inscription** | Redirection directe vers dashboard sans étape de paiement |
| **Webhook Stripe** | N'est jamais déclenché car aucune session créée |

### 3.3 Classification du Problème

| Caractéristique | Statut |
|-----------------|--------|
| Paiement optionnel | ❌ Non (devrait être obligatoire) |
| Paiement différé | ❌ Non (aucun mécanisme prévu) |
| Paiement mal conditionné | ❌ Non (jamais conditionné) |
| **Paiement contourné par défaut** | ✅ **OUI** |

---

## 4. États & Statuts

### 4.1 Schéma de Base (shared/schema.ts)

```typescript
// Ligne 7: Statut d'abonnement
subscriptionStatusEnum: ["active", "past_due", "canceled"]

// Ligne 173: Statut de facturation
billingStatusEnum: ["trialing", "active", "past_due", "canceled", "unpaid"]

// Ligne 79-85: Statut SaaS client
saasClientStatusEnum: [
  "ACTIVE",      // Compte opérationnel
  "IMPAYE_1",    // J+0 à J+15
  "IMPAYE_2",    // J+15 à J+30
  "SUSPENDU",    // J+30 à J+60
  "RESILIE"      // À partir de J+60
]
```

### 4.2 Statuts Appliqués Lors de l'Inscription

| Champ | Valeur Appliquée | Attendue |
|-------|-----------------|----------|
| `planId` | `"free"` | Plan sélectionné (plus/pro) |
| `subscriptionStatus` | `"active"` | `"pending"` ou via Stripe |
| `billingStatus` | `"active"` (default) | `"pending"` ou `"trialing"` |
| `saasClientStatus` | `"ACTIVE"` (default) | Devrait dépendre du paiement |
| `stripeCustomerId` | `null` | Créé lors du checkout |
| `stripeSubscriptionId` | `null` | Créé lors du paiement |

### 4.3 Statut `PENDING_PAYMENT` Manquant

❌ **Aucun statut `PENDING_PAYMENT` n'existe dans le schéma.**

Le système passe directement de "inscription" à "ACTIVE" sans état intermédiaire de paiement.

---

## 5. Stripe & Billing

### 5.1 Infrastructure Stripe Existante

| Composant | Statut | Fichier |
|-----------|--------|---------|
| Client Stripe | ✓ Configuré | `server/stripe.ts` |
| `createKoomySubscriptionSession` | ✓ Implémenté | `server/stripe.ts` L40+ |
| Endpoint création session | ✓ Existe | `routes.ts` L7045 |
| Price IDs configurés | ✓ Via env vars | `STRIPE_PRICE_*` |
| Webhook handler | ✓ Existe | `routes.ts` (à vérifier) |

### 5.2 Flux Stripe Attendu vs Réel

**Flux Attendu:**
```
Register → API → Create Checkout Session → Redirect Stripe → 
Paiement → Webhook → Update Plan → Dashboard
```

**Flux Réel:**
```
Register → API → Create Community (FREE) → Dashboard
```

### 5.3 Checkout Session Non Créée

L'appel à `createKoomySubscriptionSession` n'est **jamais effectué** dans `/api/admin/register`.

### 5.4 Activation du Club Sans Paiement

Le club est activé immédiatement avec:
- `subscriptionStatus: "active"` 
- `billingStatus: "active"` (par défaut)
- Aucune dépendance au webhook Stripe

---

## 6. Écart Attendu vs Réel

| Étape | Comportement Attendu | Comportement Réel | Écart |
|-------|---------------------|-------------------|-------|
| Sélection plan payant | Plan transmis au backend | Plan affiché mais non transmis | **CRITIQUE** |
| Inscription | planId = plan sélectionné | planId = "free" forcé | **CRITIQUE** |
| Post-inscription | Redirection Stripe Checkout | Redirection Dashboard | **CRITIQUE** |
| Paiement | Obligatoire avant accès | Jamais requis | **CRITIQUE** |
| Statut abonnement | "pending" jusqu'au paiement | "active" immédiatement | **ÉLEVÉ** |
| Création Stripe Customer | Lors de l'inscription | Jamais créé | **ÉLEVÉ** |
| Webhook Stripe | Déclenche activation | Non utilisé pour activation | **ÉLEVÉ** |
| Accès back-office | Après paiement confirmé | Immédiat et complet | **CRITIQUE** |

---

## 7. Gravité & Risques

### Classification: ⚠️ **CRITIQUE**

### Risques Business
| Risque | Impact |
|--------|--------|
| **Perte de revenus** | 100% des inscriptions plans payants sont gratuites |
| **Modèle SaaS compromis** | Aucune monétisation possible |
| **Abus potentiel** | Utilisation illimitée sans paiement |

### Risques Juridiques
| Risque | Impact |
|--------|--------|
| **Promesse non tenue** | Affichage "12€/mois" sans facturation |
| **Absence de CGV** | Service fourni sans contrat de paiement |
| **Comptabilité** | Aucune trace de CA généré |

### Risques Techniques
| Risque | Impact |
|--------|--------|
| **Données incohérentes** | Plans affichés ≠ plans en base |
| **Stripe désynchronisé** | Aucun customer/subscription créé |
| **Quotas non respectés** | Plan "free" appliqué avec limites 20 membres |

---

## 8. Points de Correction Requis (Liste Factuelle)

> ⚠️ **RAPPEL: Cet audit est READ-ONLY. Aucune correction n'a été appliquée.**

### Frontend (Register.tsx)
1. Transmettre `planId` ou `selectedPlan.code` dans le payload API
2. Gérer la redirection vers Stripe après inscription si plan payant

### Backend (routes.ts /api/admin/register)
1. Récupérer `planId` du payload
2. Si plan payant: créer session Stripe et retourner URL de redirection
3. Si plan gratuit: comportement actuel OK
4. Ne pas activer `subscriptionStatus: "active"` avant paiement confirmé

### Schéma (shared/schema.ts)
1. Considérer ajout d'un statut `PENDING_PAYMENT` dans `subscriptionStatusEnum`

### Webhook Stripe
1. Vérifier que `checkout.session.completed` active le plan correctement

---

## 9. Diagramme du Flux Défaillant

```
┌─────────────────────────────────────────────────────────────────┐
│                     PARCOURS ACTUEL (DÉFAILLANT)                │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  /pricing                    /admin/register?plan=plus          │
│  ┌─────────┐                ┌─────────────────────┐             │
│  │  Plan   │ ─── CTA ───▶   │   Register Form     │             │
│  │  Plus   │                │   ✓ Shows "Plus"    │             │
│  │ 12€/mois│                │   ❌ Never sends ID │             │
│  └─────────┘                └──────────┬──────────┘             │
│                                        │                        │
│                                        ▼                        │
│                             POST /api/admin/register            │
│                             ┌─────────────────────┐             │
│                             │ payload: {          │             │
│                             │   name, email, ...  │             │
│                             │   ❌ NO planId      │             │
│                             │ }                   │             │
│                             └──────────┬──────────┘             │
│                                        │                        │
│                                        ▼                        │
│                             Backend Forces planId: "free"       │
│                             subscriptionStatus: "active"        │
│                                        │                        │
│                                        ▼                        │
│                             ┌─────────────────────┐             │
│                             │    /admin/dashboard │◀── Accès    │
│                             │    Plan: FREE       │    complet  │
│                             │    ❌ No payment    │    GRATUIT  │
│                             └─────────────────────┘             │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │           STRIPE CHECKOUT ❌ JAMAIS DÉCLENCHÉ              ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

---

## 10. Conclusion

Le parcours d'inscription avec plan payant est **totalement non-fonctionnel**. Le système permet à n'importe quel utilisateur d'accéder au back-office avec un plan FREE, quelle que soit sa sélection initiale.

**Impact immédiat:** Toutes les inscriptions depuis le lancement sont gratuites, même pour les plans payants.

**Action requise:** Correction urgente du flux d'inscription pour intégrer Stripe Checkout avant l'activation du compte.

---

*Audit généré par Agent Replit - READ-ONLY*
