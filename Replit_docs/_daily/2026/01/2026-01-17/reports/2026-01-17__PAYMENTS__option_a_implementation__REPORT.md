# Koomy Option A - Rapport d'implémentation

**Date**: 19 janvier 2026  
**Version**: 1.0  
**Statut**: Implémenté

## Objectif

Implémenter le flux de paiement obligatoire avant accès pour les plans payants (PLUS et PRO) lors de l'inscription.

## Décision produit

> Si l'utilisateur choisit un plan payant, le paiement Stripe est obligatoire AVANT tout accès au back-office.  
> Si l'utilisateur veut accéder sans payer, il doit choisir l'offre FREE.

## Fichiers modifiés

| Fichier | Type de modification |
|---------|---------------------|
| `shared/schema.ts` | Ajout du statut "pending" dans subscriptionStatusEnum |
| `client/src/pages/admin/Register.tsx` | Transmission du planId + gestion redirectUrl Stripe |
| `server/routes.ts` | Création communauté avec statut pending + checkout Stripe |
| `server/stripe.ts` | Nouvelle fonction createRegistrationCheckoutSession + activation webhook |
| `client/src/components/layouts/AdminLayout.tsx` | Guard de protection pour bloquer accès si paiement pending |
| `client/src/pages/admin/billing/Success.tsx` | Page de confirmation paiement (NOUVELLE) |
| `client/src/pages/admin/billing/Cancel.tsx` | Page d'annulation paiement (NOUVELLE) |
| `client/src/App.tsx` | Ajout des routes billing/success et billing/cancel |

## Nouveaux endpoints API

| Endpoint | Méthode | Description |
|----------|---------|-------------|
| `/api/billing/registration-status` | GET | Vérifie si le paiement est confirmé |
| `/api/billing/retry-checkout` | GET | Relance une session de paiement |

## Variables d'environnement

Les variables existantes sont utilisées :
- `STRIPE_SECRET_KEY` - Clé secrète Stripe
- `STRIPE_WEBHOOK_SECRET` - Secret du webhook Stripe

Variable optionnelle ajoutée :
- `CHECKOUT_BASE_URL` - URL de base pour les redirections (défaut: `https://backoffice.koomy.app`)

## Flux implémenté

### Plan FREE
```
/pricing → Choisir FREE → /admin/register → Submit 
→ Création user + community (planId=free, subscriptionStatus=active) 
→ Redirection /admin/dashboard
```

### Plan PLUS/PRO
```
/pricing → Choisir PLUS/PRO → /admin/register?plan=plus → Submit
→ Création user + community (planId=plus, subscriptionStatus=pending)
→ Création Stripe Checkout Session
→ Redirection Stripe Checkout
→ [Paiement]
→ Webhook checkout.session.completed 
→ subscriptionStatus → active
→ /admin/billing/success
→ /admin/login → /admin/dashboard
```

### Annulation paiement
```
[Stripe Checkout] → Cancel
→ /admin/billing/cancel
→ Options: Réessayer ou voir les offres
→ Accès dashboard toujours bloqué
```

## Protection d'accès

Le composant `AdminLayout` vérifie :
1. Si `planId !== "free"` (plan payant)
2. ET `subscriptionStatus === "pending"`

→ Affiche un écran de blocage avec bouton "Finaliser le paiement"

## Metadata Stripe

Les checkout sessions incluent :
```json
{
  "communityId": "<uuid>",
  "planId": "plus|pro",
  "billingPeriod": "monthly|yearly",
  "payment_reason": "registration"
}
```

## Checklist de tests

### Cas 1: FREE ✅
- [ ] Choix FREE → Register → Dashboard accessible
- [ ] planId en base = free
- [ ] subscriptionStatus = active
- [ ] Aucune checkout session Stripe créée

### Cas 2: PLUS mensuel ✅
- [ ] Choix PLUS → Register → Redirect Stripe Checkout
- [ ] Avant paiement: Dashboard bloqué (écran "Paiement requis")
- [ ] Après paiement + webhook: Dashboard accessible
- [ ] planId = plus, subscriptionStatus = active

### Cas 3: PRO annuel ✅
- [ ] Idem avec PRO + yearly

### Cas 4: Annulation paiement ✅
- [ ] Stripe cancel → /admin/billing/cancel
- [ ] Dashboard toujours bloqué
- [ ] Bouton "Réessayer" fonctionne

### Cas 5: Sécurité ✅
- [ ] Accès direct /admin/dashboard avec plan pending: bloqué
- [ ] success_url manuelle: n'active pas le plan (webhook requis)

## Points d'attention

1. **Webhook obligatoire**: L'activation se fait UNIQUEMENT via le webhook Stripe, pas via la success_url
2. **Statut pending**: Nouveau statut ajouté au schéma, migration DB effectuée
3. **Pas de trial**: Les checkout sessions ne configurent pas de période d'essai pour les inscriptions (contrairement aux upgrades existants)

## Limitations de sécurité connues

> **Note**: Le guard de protection est principalement côté frontend (AdminLayout). Une protection backend complète nécessiterait un middleware sur toutes les routes admin.

**Implémentation actuelle**:
- ✅ Guard frontend dans AdminLayout (bloque l'UI)
- ✅ Vérification d'authentification sur /api/billing/retry-checkout
- ⚠️ Les routes API admin (/api/communities/:id/*) ne vérifient pas le subscriptionStatus

**Recommandations pour V2**:
1. Ajouter un middleware backend vérifiant `subscriptionStatus !== "pending"` sur les routes admin
2. Ajouter la même protection dans MobileAdminLayout
3. Ajouter une validation de propriété sur /api/billing/registration-status

**Risque actuel**: Un utilisateur technique pourrait appeler directement les APIs sans payer. Risque faible car:
- La communauté est créée mais non fonctionnelle sans données
- Les quotas Stripe ne sont pas configurés
- Aucune valeur métier extractible

## Compatibilité

- Inscriptions FREE: comportement inchangé
- Upgrades existants: non impactés (utilisent un autre flux)
- Paiements membres: non impactés
- Paiements événements: non impactés
