# AUDIT P-FIN.6 — Bug Stripe Connect Onboarding

**Date**: 2026-01-26  
**Statut**: ✅ Audit complété  
**Priorité**: BLOCKING

---

## 1. Résumé Exécutif

Le bouton "Configurer Stripe Connect" dans le Back Office Finances redirige vers des URLs inexistantes après le flow Stripe, causant un 404 et une expérience utilisateur cassée.

---

## 2. Composants Identifiés

### 2.1 Frontend - Bouton "Connecter à Stripe"
- **Fichier**: `client/src/pages/admin/Finances.tsx`
- **Ligne**: ~358 (data-testid="button-connect-stripe")
- **Action**: Appelle `handleConnectStripe()` → mutation `connectStripeMutation`
- **Endpoint appelé**: `POST /api/payments/connect-community`

### 2.2 Backend - Endpoint Connect
- **Fichier**: `server/routes.ts` (ligne 10349)
- **Route**: `POST /api/payments/connect-community`
- **Module importé**: `server/stripeConnect.ts` → `setupConnectForCommunity()`
- **Retour**: `{ url: onboardingUrl, accountId }`

### 2.3 Génération des URLs
- **Fichier**: `server/stripe.ts` (ligne 91)
- **Fonction**: `getStripeConnectUrls()`
- **URLs générées**:
  - Refresh: `${baseUrl}/payments/connect/refresh`
  - Return: `${baseUrl}/payments/connect/success`

### 2.4 BaseUrl selon environnement
- **Sandbox**: `https://backoffice-sandbox.koomy.app`
- **Production**: `https://backoffice.koomy.app`

---

## 3. Cause Racine Identifiée

### ❌ Routes Frontend MANQUANTES

**Problème**: Les URLs de callback Stripe Connect pointent vers des routes qui n'existent pas dans le frontend.

**Fichier**: `client/src/App.tsx`

**Routes existantes billing**:
```tsx
<Route path="/billing/return" component={BillingReturn} />
<Route path="/admin/billing/success" component={BillingSuccess} />
<Route path="/admin/billing/cancel" component={BillingCancel} />
```

**Routes Connect MANQUANTES**:
```tsx
// ❌ Ces routes n'existent PAS:
<Route path="/payments/connect/refresh" component={???} />
<Route path="/payments/connect/success" component={???} />
```

---

## 4. Flow Actuel (Cassé)

```
1. Admin clique "Configurer" dans /admin/finances
   ↓
2. Frontend POST /api/payments/connect-community
   ↓
3. Backend crée compte Stripe Connect Express (OK)
   ↓
4. Backend génère accountLink avec:
   - refresh_url: https://backoffice.koomy.app/payments/connect/refresh
   - return_url: https://backoffice.koomy.app/payments/connect/success
   ↓
5. Frontend redirige vers URL Stripe (OK)
   ↓
6. User complète flow Stripe
   ↓
7. Stripe redirige vers return_url
   ↓
8. ❌ 404 - Route n'existe pas dans App.tsx
```

---

## 5. Vérifications Effectuées

| Check | Résultat |
|-------|----------|
| Endpoint backend accessible | ✅ OK |
| Stripe key configuration | ✅ (clés présentes en secrets) |
| Connect Express activé | ✅ (code utilise type: 'express') |
| AccountLink création | ✅ (code correct dans stripeConnect.ts) |
| URLs return/refresh | ❌ Routes frontend inexistantes |
| Composant de retour | ❌ N'existe pas |

---

## 6. Solution Requise

### Phase 1 Fix (Minimal)

1. **Créer page de callback Connect** : `client/src/pages/admin/ConnectReturn.tsx`
   - Gérer `?success=1` → afficher succès
   - Gérer `?refresh=1` → bouton pour relancer onboarding

2. **Ajouter routes** dans `App.tsx`:
   ```tsx
   <Route path="/payments/connect/success" component={ConnectReturn} />
   <Route path="/payments/connect/refresh" component={ConnectReturn} />
   ```

3. **Endpoint status Connect** : `GET /api/connect/status`
   - Retourne `{ chargesEnabled, payoutsEnabled, detailsSubmitted }`

---

## 7. Hypothèse Confirmée

> **Le bug est un oubli d'implémentation des routes frontend de callback.**
> 
> Le backend génère correctement l'accountLink Stripe, mais les URLs de retour pointent vers des routes React qui n'ont jamais été créées.

---

## 8. Prochaine Étape

Procéder au fix P-FIN.6 Phase 1 selon le prompt fourni.

---

*Fin de l'audit*
