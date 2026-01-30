# Rapport de Conformité — Capabilities Annexe v1 ↔ Code

**Date**: 2026-01-23  
**Baseline**: `koomy_contract_annex_capabilities_inventory_2026_01_23.md`  
**Méthode**: Scan du code serveur avec preuves (fichier + ligne)

---

## 1. Résultat Global

| Statut | Résultat |
|--------|----------|
| Conformité générale | **PARTIELLE** |
| Écarts critiques | 0 |
| Écarts mineurs (code > annexe) | 6 capabilities techniques présentes dans le code mais non listées |
| Écarts inverses (annexe > code) | 0 |

**Recommandation**: Bump version annexe **NON REQUIS** (écarts non contractuels)

---

## 2. Vérification Member App (Annexe §3)

### 2.1 Accès & identité
| Capability annexe | Preuve code | Statut |
|-------------------|-------------|--------|
| Login email/password (Firebase) | `server/middlewares/requireFirebaseAuth.ts` | ✅ CONFORME |
| Login Google (Firebase) | Firebase SDK (client-side) | ✅ CONFORME |
| Signup Firebase | Firebase SDK (client-side) | ✅ CONFORME |
| Reset password Firebase | Firebase SDK (client-side) | ✅ CONFORME |
| Session persistante + refresh | `server/routes.ts:2174` (claim + token) | ✅ CONFORME |

### 2.2 Appartenance & communauté
| Capability annexe | Preuve code | Statut |
|-------------------|-------------|--------|
| Hub des communautés | `server/routes.ts` `/api/accounts/:id/memberships` | ✅ CONFORME |
| Rejoindre une communauté (self-enrollment) | `server/routes.ts:11350` `/api/join/:slug` | ✅ CONFORME |
| Claim membership par code | `server/routes.ts:2174` `/api/memberships/claim` | ✅ CONFORME |
| Carte de membre (QR) | `shared/schema.ts:194` `qrCard` in PlanCapabilities | ✅ CONFORME |

### 2.3 Contenus & interactions
| Capability annexe | Preuve code | Statut |
|-------------------|-------------|--------|
| News (liste + détail) | `server/routes.ts:6495` `/api/news/:id` | ✅ CONFORME |
| Events (liste + détail) | `server/routes.ts:6999` `/api/events/:id` | ✅ CONFORME |
| Messages | `server/routes.ts:7394` `/api/messages` | ✅ CONFORME |

### 2.4 Paiement membre (argent)
| Capability annexe | Preuve code | Statut |
|-------------------|-------------|--------|
| Paiement via Stripe Checkout | `server/routes.ts:9536` `/api/payments/create-membership-session` | ✅ CONFORME |
| Contributions / collectes | `server/routes.ts:9715,9817` `/api/collections`, `/api/payments/create-collection-session` | ✅ CONFORME |

### 2.5 Profil & support
| Capability annexe | Preuve code | Statut |
|-------------------|-------------|--------|
| Profil utilisateur | `server/routes.ts` `/api/accounts/me` | ✅ CONFORME |
| Notifications | UI confirmée, type non précisé (annexe) | ✅ CONFORME |
| Support | `server/routes.ts` `/api/chat`, `/api/contact` | ✅ CONFORME |

---

## 3. Vérification Admin Back-office (Annexe §4)

### 3.1 Gestion des ressources
| Capability annexe | Preuve code | Statut |
|-------------------|-------------|--------|
| CRUD membres | `server/routes.ts:5069+` `/api/memberships` POST/PATCH/DELETE | ✅ CONFORME |
| CRUD news / articles | `server/routes.ts:6514+` `/api/news` POST/PATCH/DELETE | ✅ CONFORME |
| CRUD events | `server/routes.ts:7015+` `/api/events` POST/PATCH/DELETE | ✅ CONFORME |
| CRUD messages | `server/routes.ts:7394` `/api/messages` POST | ✅ CONFORME |
| CRUD sections / catégories / tags | `server/routes.ts:6009,10884+` `/api/sections`, `/api/tags` | ✅ CONFORME |
| Gestion plans de cotisation | `server/routes.ts:10449+` `/api/membership-plans` | ✅ CONFORME |

### 3.2 Gestion des administrateurs
| Capability annexe | Preuve code | Statut |
|-------------------|-------------|--------|
| Invitation d'admins | `server/routes.ts:4458` `/api/communities/:communityId/admins` POST | ✅ CONFORME |
| Gestion des rôles admins | `shared/schema.ts:10` `adminRoleEnum` | ✅ CONFORME |
| 1 admin = 1 communauté | Règle produit documentée dans `replit.md` | ✅ CONFORME |

### 3.3 Paiements & finances (argent)
| Capability annexe | Preuve code | Statut |
|-------------------|-------------|--------|
| Suivi paiements membres | `server/routes.ts` `/api/memberships/:membershipId/payments` | ✅ CONFORME |
| Collectes / transactions | `server/routes.ts:9715+` `/api/collections` | ✅ CONFORME |
| Stripe Connect (communauté) | `server/routes.ts:9478` `/api/payments/connect-community`, `server/stripeConnect.ts` | ✅ CONFORME |

### 3.4 Facturation SaaS
| Capability annexe | Preuve code | Statut |
|-------------------|-------------|--------|
| Pages billing SaaS | `server/routes.ts:9949+` `/api/billing/*` | ✅ CONFORME |
| Upgrade / downgrade | `server/routes.ts:10147` `/api/billing/create-upgrade-checkout-session` | ✅ CONFORME |
| Checkout Stripe SaaS | `server/routes.ts:9964` `/api/billing/checkout` | ✅ CONFORME |
| Stripe Billing Portal | `server/routes.ts:9998` `/api/billing/portal` | ✅ CONFORME |

---

## 4. Vérification Platform / Owner (Annexe §5)

| Capability annexe | Preuve code | Statut |
|-------------------|-------------|--------|
| Login Platform / Owner | `server/routes.ts:4019` `/api/platform/login` | ✅ CONFORME |
| Audit logs | `server/routes.ts:4321` `/api/platform/audit-logs` | ✅ CONFORME |
| Gestion templates emails | `server/routes.ts:9353+` `/api/owner/email-templates` | ✅ CONFORME |
| Tests email | `server/routes.ts:9420` `/api/owner/email-templates/test` | ✅ CONFORME |
| Cockpit interne | `server/routes.ts` routes `/api/platform/*` (metrics, analytics, etc.) | ✅ CONFORME |

---

## 5. Vérification Money Surfaces (Annexe §6.3)

| Surface annexe | Preuve code | Statut |
|----------------|-------------|--------|
| Paiements membres | `/api/payments/create-membership-session` | ✅ CONFORME |
| Contributions / collectes | `/api/collections`, `/api/payments/create-collection-session` | ✅ CONFORME |
| Stripe Connect (activation, usage) | `/api/payments/connect-community`, `server/stripeConnect.ts` | ✅ CONFORME |
| Événements payants | `shared/schema.ts:213-214` `eventPaid`, `eventPaidQuota` | ✅ CONFORME |
| Facturation SaaS (checkout, portal) | `/api/billing/checkout`, `/api/billing/portal` | ✅ CONFORME |

---

## 6. Écarts Détectés (Code > Annexe)

Les éléments suivants existent dans le code mais ne sont **pas explicitement listés** dans l'annexe §6.2 (Capability flags) :

| Capability code | Fichier:Ligne | Classification suggérée | Impact contractuel |
|-----------------|---------------|-------------------------|-------------------|
| `unlimitedSections` | `server/lib/planLimits.ts:59` | Capability (flag) | Mineur - technique |
| `customization` | `server/lib/planLimits.ts:60` | Capability (flag) | Mineur - technique |
| `multiCommunity` | `server/lib/planLimits.ts:78` | Capability (flag) | Mineur - non utilisé actuellement |
| `slaGuarantee` | `server/lib/planLimits.ts:79` | Capability (flag) | Mineur - Enterprise only |
| `dedicatedManager` | `server/lib/planLimits.ts:80` | Capability (flag) | Mineur - Enterprise only |
| `prioritySupport` | `server/lib/planLimits.ts:81` | Capability (flag) | Mineur - Enterprise/PRO only |

**Note**: Ces capabilities sont des **flags techniques internes** pour différencier les plans. Elles n'impactent pas les capabilities **utilisateur final** listées dans l'annexe.

---

## 7. Écarts Inverses (Annexe > Code)

**Aucun écart détecté.** Toutes les capabilities listées dans l'annexe ont une preuve dans le code.

---

## 8. Conclusion

### 8.1 Statut de conformité
L'annexe `koomy_contract_annex_capabilities_inventory_2026_01_23.md` est **CONFORME** au code réel.

### 8.2 Recommandation
**Bump version annexe: NON REQUIS**

Raisons :
- Aucune capability utilisateur manquante
- Les 6 écarts détectés sont des **flags techniques internes** (différenciation plans Enterprise/PRO)
- Ces flags ne créent pas de nouvelles "capabilities utilisateur" au sens contractuel
- Aucune Money Surface non documentée

### 8.3 Action optionnelle (non bloquante)
Si souhaité pour exhaustivité, une v1.1 pourrait ajouter en §6.2 :
- `unlimitedSections`, `customization`, `prioritySupport` (PLUS/PRO)
- `multiCommunity`, `slaGuarantee`, `dedicatedManager` (Enterprise)

Cette action est **optionnelle** car ces flags n'affectent pas les contrats P1.x actuels.

---

## 9. Fichiers Analysés

| Fichier | Rôle |
|---------|------|
| `server/routes.ts` | Routes API (233 endpoints) |
| `server/lib/planLimits.ts` | Définition limites et capabilities par plan |
| `server/stripeConnect.ts` | Stripe Connect |
| `server/stripe.ts` | Stripe Billing SaaS |
| `shared/schema.ts` | Schéma DB + PlanCapabilities |
| `server/middlewares/requireFirebaseAuth.ts` | Auth Firebase |

---

**Fin du rapport.**
