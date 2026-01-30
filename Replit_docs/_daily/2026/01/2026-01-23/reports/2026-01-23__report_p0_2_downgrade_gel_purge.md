# Rapport P0.2 — Downgrade / Gel / Purge

**Date**: 2026-01-23  
**Statut**: ✅ Implémenté  
**Auteur**: Agent Replit

---

## 1. Résumé Exécutif

Ce rapport documente l'implémentation du système de downgrade, gel et purge automatique des communautés en défaut de paiement.

**Fonctionnalités livrées:**
1. **Downgrade/Gel**: Réutilisation du guard billing P0.1 (`requireBillingInGoodStanding`)
2. **Planification purge**: Ajout des champs `purge_scheduled_at`, `purge_status`, `purge_executed_at` au schema
3. **Job purge**: Suppression automatique à J+90 des données DB + Object Storage
4. **Annulation purge**: Réactivation annule la purge planifiée

---

## 2. Cartographie Code (Réalité)

### 2.1 Subscription Status
- **Table**: `communities`
- **Colonne**: `subscription_status` (enum: trialing, active, past_due, canceled)
- **Mise à jour**: `server/stripe.ts` (webhooks Stripe)

### 2.2 SaaS Client Status
- **Table**: `communities`
- **Colonne**: `saas_client_status` (enum: ACTIVE, IMPAYE_1, IMPAYE_2, SUSPENDU, RESILIE)
- **Job quotidien**: `server/services/saasStatusJob.ts`

### 2.3 Tables Tenant-Scoped
| Table | Clé Étrangère |
|-------|---------------|
| user_community_memberships | community_id |
| sections | community_id |
| enrollment_requests | community_id |
| community_member_profile_config | community_id |
| news_articles | community_id |
| events | community_id |
| event_registrations | event_id → events.community_id |
| event_attendance | event_id → events.community_id |
| community_monthly_usage | community_id |
| support_tickets | community_id |
| ticket_responses | ticket_id → support_tickets.community_id |
| messages | community_id |
| membership_fees | community_id |
| membership_plans | community_id |
| payment_requests | community_id |
| payments | community_id |
| collections | community_id |
| transactions | community_id |
| categories | community_id |
| tags | community_id |
| member_tags | membership_id → user_community_memberships.community_id |
| article_tags | article_id → news_articles.community_id |
| article_sections | article_id → news_articles.community_id |
| subscription_status_audit | community_id |
| subscription_emails_sent | community_id |

---

## 3. Downgrade/Gel (Endpoints Protégés)

### Guard utilisé
```typescript
// server/lib/subscriptionGuards.ts
export const BILLING_BLOCKED_STATUSES = ["past_due", "canceled"];
export const BILLING_ALLOWED_STATUSES = ["trialing", "active"];

export function requireBillingInGoodStanding(options?: { allowMissingCommunityId?: boolean }) {
  // Retourne HTTP 402 avec codes:
  // - BILLING_PAST_DUE: paiement en retard
  // - BILLING_CANCELED: abonnement annulé
}
```

### Endpoints protégés
| Endpoint | Action |
|----------|--------|
| POST /api/events | Création événement |
| POST /api/news | Création actualité |
| POST /api/communities/:id/news | Création actualité communauté |
| POST /api/collections | Création collecte |

### Endpoints NON bloqués
- GET /api/billing/status
- POST /api/billing/create-checkout-session
- POST /api/billing/create-portal-session
- GET /api/communities/:id (lecture)

---

## 4. Planification Purge (Structure DB)

### Choix d'architecture
Ajout de colonnes sur la table `communities` (cohérent avec le pattern existant pour `suspendedAt`, `terminatedAt`).

### Nouveaux champs
```sql
-- Enum créé
CREATE TYPE purge_status AS ENUM ('scheduled', 'canceled_by_reactivation', 'executed');

-- Colonnes ajoutées
ALTER TABLE communities ADD COLUMN purge_scheduled_at TIMESTAMP;
ALTER TABLE communities ADD COLUMN purge_status purge_status;
ALTER TABLE communities ADD COLUMN purge_executed_at TIMESTAMP;
```

### Drizzle Schema
```typescript
// shared/schema.ts
export const purgeStatusEnum = pgEnum("purge_status", [
  "scheduled",
  "canceled_by_reactivation",
  "executed"
]);

// Dans communities table:
purgeScheduledAt: timestamp("purge_scheduled_at"),
purgeStatus: purgeStatusEnum("purge_status"),
purgeExecutedAt: timestamp("purge_executed_at"),
```

---

## 5. Job Purge (Algorithme + Ordre)

### Fichier: `server/services/purgeService.ts`

### Intégration dans le job quotidien
Le job de purge est intégré dans `saasStatusJob.ts` et s'exécute automatiquement lors du job quotidien SaaS:
```typescript
// Dans runSaasStatusTransitions():
const purgeResults = await runPurgeJob();
for (const purgeResult of purgeResults) {
  logPurgeExecuted(purgeResult);
}
```

### Algorithme
1. Sélectionner communautés où `purge_status = 'scheduled' AND purge_scheduled_at <= NOW()`
2. Pour chaque communauté:
   a. Supprimer Object Storage (public + private)
   b. Supprimer données DB dans l'ordre des dépendances
   c. Logger le résultat

### Ordre de suppression (FK-safe)
```
1. member_tags
2. article_tags, article_sections
3. event_attendance, event_registrations
4. ticket_responses
5. subscription_emails_sent
6. subscription_status_audit
7. community_monthly_usage
8. transactions
9. payments
10. payment_requests
11. collections
12. membership_fees
13. membership_plans
14. messages
15. support_tickets
16. events
17. news_articles
18. enrollment_requests
19. user_community_memberships
20. tags
21. categories
22. sections
23. community_member_profile_config
24. communities (dernier)
```

### Intégration SaaS Job
```typescript
// server/services/saasStatusJob.ts
// Lors de la transition SUSPENDU → RESILIE:
await schedulePurge(community.id);
logPurgeScheduled(community.id, purgeDate);
```

---

## 6. Storage Purge (Object Storage)

### Chemins supprimés
- `public/communities/{communityId}/*`
- `.private/communities/{communityId}/*`

### Implémentation
```typescript
async function deleteCommunityObjectStorage(communityId: string): Promise<boolean> {
  const { Client } = await import("@replit/object-storage");
  const client = new Client();
  
  // Liste et supprime tous les objets
  const publicObjects = await client.list({ prefix: `public/communities/${communityId}` });
  for (const obj of publicObjects.objects || []) {
    await client.delete(obj.key);
  }
  // Idem pour .private/
}
```

---

## 7. Annulation Purge (Réactivation)

### Points d'annulation
1. **Checkout completed** (stripe webhook):
   ```typescript
   if (previousStatus === "canceled" && previousCommunity?.purgeStatus === "scheduled") {
     await cancelPurge(communityId);
     logPurgeCanceled(communityId, "reactivation_via_checkout");
   }
   ```

2. **Payment succeeded** (stripe webhook):
   ```typescript
   if (currentStatus === "RESILIE" && community?.purgeStatus === "scheduled") {
     await cancelPurge(communityId);
     logPurgeCanceled(communityId, "reactivation_via_payment_succeeded");
   }
   ```

### Fonction cancelPurge
```typescript
export async function cancelPurge(communityId: string): Promise<void> {
  await db.update(communities)
    .set({
      purgeScheduledAt: null,
      purgeStatus: "canceled_by_reactivation",
    })
    .where(eq(communities.id, communityId));
}
```

---

## 8. Tests

### Fichier: `server/tests/purge-service.test.ts`

### Exécution
```bash
npx tsx server/tests/purge-service.test.ts
```

### Résultat (17 tests ✅)
```
📋 P0.2 Purge Service Contract Tests
  ✅ should have exactly 3 valid statuses
  ✅ should include 'scheduled' status
  ✅ should include 'canceled_by_reactivation' status
  ✅ should include 'executed' status
  ✅ should calculate purge date 90 days after cancellation
  ✅ should respect the 90-day delay constant
  ✅ RESILIE → ACTIVE: should cancel purge
  ✅ SUSPENDU → ACTIVE: should NOT cancel purge
  ... (17 tests total)
```

### Couverture
- Enum purge_status (3 valeurs)
- Calcul date purge (J+90)
- Annulation sur réactivation
- Tables tenant-scoped
- Intégration SaaS → subscription status

---

## 9. Différences Prompt vs Code

| Prompt | Réalité Code | Correction |
|--------|--------------|------------|
| "subscription_status devient canceled" | `saasClientStatus` devient `RESILIE` | Mapping maintenu: RESILIE = canceled |
| Table séparée `communityPurge` | Colonnes sur `communities` | Cohérent avec pattern existant |
| Job purge séparé | Intégré dans `saasStatusJob.ts` | Évite duplication |

---

## 10. Risques / Suites

### Risques identifiés
1. **Données orphelines**: Tables avec FK sans `onDelete: cascade` sont supprimées manuellement
2. **Object Storage**: Échec silencieux si bucket introuvable (log mais continue)
3. **Transactions**: Pas de rollback global si échec partiel

### Suites P1
1. **Limites d'usage**: Quotas mensuels (événements payants, membres)
2. **Email J+83**: Avertissement 7 jours avant purge
3. **Export données**: Permettre export avant purge

---

## 11. Timeline SaaS Complète

```
J+0  : ACTIVE → IMPAYE_1 (paiement échoué)
J+15 : IMPAYE_1 → IMPAYE_2 (délai grâce expiré)
J+27 : Email "suspension imminente"
J+30 : IMPAYE_2 → SUSPENDU (compte gelé)
J+57 : Email "résiliation imminente"
J+60 : SUSPENDU → RESILIE (contrat terminé) + purge planifiée à J+90
J+90 : Purge exécutée (30 jours après RESILIE, 90 jours après premier impayé)
```

---

## 12. Fichiers Modifiés

| Fichier | Changement |
|---------|------------|
| `shared/schema.ts` | +purgeStatusEnum, +3 colonnes purge |
| `server/services/purgeService.ts` | Nouveau fichier |
| `server/services/saasStatusJob.ts` | +import purgeService, +schedulePurge |
| `server/stripe.ts` | +import cancelPurge, +logique réactivation |
| `server/tests/purge-service.test.ts` | Nouveau fichier |

---

**Fin du rapport P0.2**
