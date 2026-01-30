# Audit Emails — Self-Enrollment / Paiement

**Date :** 2026-01-12  
**Scope :** Impact des features self-onboarding, inscription en ligne (/join), modes OPEN/CLOSED, paiements Stripe, marque blanche  
**Statut :** AUDIT UNIQUEMENT — AUCUNE MODIFICATION DE CODE

---

## A) Inventaire des emails transactionnels

### Tableau récapitulatif

| EmailType | Fichier source | Déclencheur | Destinataire | Canal | Conditions |
|-----------|---------------|-------------|--------------|-------|------------|
| `welcome_community_admin` | `server/services/mailer/sendBrandedEmail.ts:23` | Création compte admin SaaS | Admin | Email | Création communauté |
| `invite_member` | `server/services/mailer/sendBrandedEmail.ts:108` | `POST /api/memberships` (création manuelle), `PATCH /api/memberships/:id/resend-invite` | Adhérent | Email | Email présent, création/renvoi code |
| `reset_password` | `server/services/mailer/sendBrandedEmail.ts:52` | Reset password flow | Admin/Adhérent | Email | Demande reset |
| `verify_email` | `server/services/mailer/sendBrandedEmail.ts:80` | Création compte, vérification | Admin/Adhérent | Email | Email non vérifié |
| `owner_admin_credentials` | `server/services/mailer/sendBrandedEmail.ts:138` | Création admin propriétaire | Admin | Email | Création via plateforme |
| `new_event` | `server/services/mailer/emailTypes.ts:7` | Publication événement | Adhérents | Email (template DB) | Événement publié |
| `new_collection` | `server/services/mailer/emailTypes.ts:8` | Nouvelle collecte | Adhérents | Email (template DB) | Collecte créée |
| `collection_contribution_thanks` | `server/services/mailer/emailTypes.ts:9` | Contribution reçue | Donateur | Email (template DB) | Contribution confirmée |
| `message_to_admin` | `server/services/mailer/emailTypes.ts:10` | Message adhérent→admin | Admin | Email (template DB) | Message envoyé |
| `invite_delegate` | `server/services/mailer/emailTypes.ts:3` | Invitation délégué | Délégué | Email (template DB) | Délégué invité |

### Déclencheurs identifiés dans routes.ts

| Ligne | Email | Route/Action |
|-------|-------|--------------|
| 1317 | `sendVerificationEmail` | `POST /api/accounts/register` — vérification email compte |
| 2111 | `sendWelcomeEmail` | `POST /api/register-saas` — bienvenue admin SaaS |
| 3158 | `sendMemberInviteEmail` | `POST /api/memberships` — création adhérent manuelle |
| 3303 | `sendMemberInviteEmail` | `PATCH /api/memberships/:id/resend-invite` — renvoi code |
| 3417 | `sendMemberInviteEmail` | (autre contexte création membre) |
| 5632 | `sendAdminCredentialsEmail` | Création admin propriétaire |
| 6256, 6343 | `sendPlatformVerificationEmail` | Vérification admin plateforme |

---

## B) Vérifications produit (checklist)

### 1. Self-onboarding CLOSED

| Vérification | Statut | Commentaire |
|--------------|--------|-------------|
| Email "Demande reçue" (confirmation au visiteur) | ⚠️ **MANQUANT** | Aucun email envoyé à l'inscrit après soumission via /join en mode CLOSED |
| Email "Demande approuvée" | ⚠️ **MANQUANT** | Le code répond `message: "Demande approuvée"` mais aucun `sendEmail` |
| Email "Demande refusée" | ⚠️ **MANQUANT** | Le code répond `message: "Demande refusée"` mais aucun `sendEmail` |
| Aucune mention paiement cash dans /join | ✅ OK | /join ne propose que Stripe (ONLINE channel) |

**Routes concernées :**
- `POST /api/join/:slug` (ligne ~8575) — soumission demande
- `POST /api/communities/:communityId/enrollment-requests/:requestId/approve` (ligne ~8730)
- `POST /api/communities/:communityId/enrollment-requests/:requestId/reject` (ligne ~8780)

### 2. Self-onboarding OPEN

| Vérification | Statut | Commentaire |
|--------------|--------|-------------|
| Formule gratuite : email bienvenue/activation | ⚠️ **MANQUANT** | Mode OPEN+FREE auto-approve mais pas d'email de confirmation |
| Formule payante : email "paiement requis" | ⚠️ **MANQUANT** | Mode OPEN+PAID auto-approve mais aucun email d'invitation à payer (Phase 5) |

**Note :** Le message interne dit "Vous recevrez un email de confirmation" mais aucun email n'est effectivement envoyé.

### 3. Paiement (règles strictes)

| Vérification | Statut | Commentaire |
|--------------|--------|-------------|
| /join = Stripe uniquement | ✅ OK | `selfEnrollmentChannel !== "ONLINE"` bloque le /join pour OFFLINE |
| Cash/chèque/virement = création manuelle only | ✅ OK | `paymentOption: "paid_offline"` géré dans `POST /api/memberships` |
| CLOSED+PAID : invitation à payer après validation | ⚠️ **MANQUANT** | Logique d'approbation ne déclenche pas d'email invitation Stripe |
| Email avec lien Stripe checkout | ⚠️ **À CRÉER** | Nécessite Phase 5 : intégration Stripe Checkout |
| Arrêt relances après paiement confirmé | ⚠️ **À VÉRIFIER** | Dépend de `membershipPaymentStatus = "paid"` — non testé end-to-end |

### 4. Marque blanche / non-divulgation

| Vérification | Statut | Commentaire |
|--------------|--------|-------------|
| Emails ne mentionnent pas "wallet Koomy" | ✅ OK | Templates utilisent `branding.productName` |
| Emails ne mentionnent pas autres clubs | ✅ OK | Isolation par `communityId` dans branding |
| Emails restent neutres | ✅ OK | Templates brandés via `resolveEmailBranding()` |
| Logo/couleur marque blanche appliqués | ✅ OK | `EmailBranding` contient `logoUrl`, `primaryColor` |

**Architecture branding :**
- `server/services/mailer/branding.ts` : `resolveEmailBranding()`
- Tous les emails passent par `sendTransactionalEmail()` avec metadata `isWhiteLabel`

### 5. Unicité multi-canal (app + email)

| Vérification | Statut | Commentaire |
|--------------|--------|-------------|
| Email "invitation à payer" existe | ⚠️ **MANQUANT** | Aucun template `payment_request` ou `payment_invitation` |
| Référence unique paiement (session/id) | ⚠️ **À CRÉER** | `enrollmentRequests.id` existe, mais pas de `paymentSessionId` |
| Paiement confirmé éteint relances | ⚠️ **PARTIEL** | `membershipPaymentStatus = "paid"` existe mais logique relance non implémentée |

---

## C) Risques & manquants

### Emails manquants (à créer)

| Priorité | EmailType proposé | Déclencheur | Description |
|----------|-------------------|-------------|-------------|
| **P0** | `enrollment_request_received` | `POST /api/join/:slug` (CLOSED) | Confirmation au visiteur que sa demande est bien reçue |
| **P0** | `enrollment_request_approved` | `approve` route (CLOSED) | Notification d'approbation + instructions suivantes |
| **P0** | `enrollment_request_rejected` | `reject` route (CLOSED) | Notification de refus (avec raison optionnelle) |
| **P0** | `enrollment_welcome_free` | `POST /api/join/:slug` (OPEN+FREE) | Bienvenue immédiate + code d'activation app |
| **P1** | `payment_invitation` | Approbation CLOSED+PAID ou OPEN+PAID | Lien Stripe Checkout + référence unique |
| **P1** | `payment_confirmed` | Webhook Stripe `checkout.session.completed` | Confirmation paiement + adhésion active |
| **P2** | `payment_reminder` | Job quotidien (J+3, J+7, J+14) | Relance paiement si `membershipPaymentStatus = "due"` |

### Emails existants à vérifier

| EmailType | Risque | Action recommandée |
|-----------|--------|-------------------|
| `invite_member` | Wording dit "Invitation à rejoindre" — peut être confus si envoyé post-approbation | Clarifier : est-ce une invitation ou une confirmation d'adhésion ? |

### Emails OK (aucune action)

- `welcome_community_admin` — non impacté par self-enrollment
- `reset_password` — non impacté
- `verify_email` — non impacté
- `owner_admin_credentials` — non impacté
- `new_event`, `new_collection`, `collection_contribution_thanks`, `message_to_admin` — non impactés

---

## D) Conclusion

### Résumé

| Catégorie | Statut |
|-----------|--------|
| Emails existants OK | 9/10 (wording `invite_member` à clarifier) |
| Emails marque blanche | ✅ Conformes |
| Emails paiement cash/virement | ✅ Non proposés dans /join |
| Emails self-enrollment CLOSED | ⚠️ **0/3 créés** |
| Emails self-enrollment OPEN | ⚠️ **0/2 créés** |
| Emails paiement Stripe | ⚠️ **0/3 créés** (Phase 5) |

### Corrections à faire (sans les implémenter)

1. **Phase immédiate (P0)** — Avant mise en production du /join :
   - Créer `enrollment_request_received`
   - Créer `enrollment_request_approved`
   - Créer `enrollment_request_rejected`
   - Créer `enrollment_welcome_free`

2. **Phase 5 (P1)** — Intégration Stripe Checkout :
   - Créer `payment_invitation` avec lien Stripe + référence unique
   - Créer `payment_confirmed` via webhook Stripe
   - Implémenter arrêt relances sur `membershipPaymentStatus = "paid"`

3. **Phase 6 (P2)** — Optimisation :
   - Créer `payment_reminder` avec job quotidien
   - Revoir wording `invite_member` pour distinguer invitation/confirmation

### Ordre d'implémentation recommandé

1. `enrollment_request_received` + `enrollment_request_approved` + `enrollment_request_rejected`
2. `enrollment_welcome_free`
3. Stripe Checkout integration + `payment_invitation`
4. Webhook Stripe + `payment_confirmed`
5. `payment_reminder` job

---

**FIN DE L'AUDIT — AUCUN CODE MODIFIÉ**
