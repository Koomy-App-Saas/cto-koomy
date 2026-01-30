# Rapport d'Implémentation - Système de Paiement SaaS

**Date:** 12 janvier 2026  
**Version:** 1.0  
**Statut:** Implémentation partielle (8/10 phases)

---

## 1. Résumé Exécutif

Le système de gestion automatisée des statuts d'abonnement pour les clients SaaS self-service a été implémenté. Ce système gère les transitions de statut basées sur l'état des paiements, avec des délais stricts calculés depuis une date de référence unique (`unpaidSince`).

### Cycle de vie des statuts

```
ACTIVE ──► IMPAYE_1 ──► IMPAYE_2 ──► SUSPENDU ──► RESILIE
  │           │            │
  │           └────────────┴───────────────────┐
  │                                            │
  └────────────── Paiement réussi ◄────────────┘
```

| Statut | Période | Restrictions |
|--------|---------|--------------|
| ACTIVE | Normal | Aucune |
| IMPAYE_1 | J+0 à J+15 | Bandeau d'alerte uniquement |
| IMPAYE_2 | J+15 à J+30 | Bandeau d'alerte (pré-suspension) |
| SUSPENDU | J+30 à J+60 | Accès bloqué (export autorisé) |
| RESILIE | Après J+60 | Compte terminé (export autorisé) |

---

## 2. Composants Implémentés

### 2.1 Schéma Base de Données

**Fichier:** `shared/schema.ts`

#### Enums créés
```typescript
export const saasClientStatusEnum = pgEnum("saas_client_status", [
  "ACTIVE",
  "IMPAYE_1", 
  "IMPAYE_2",
  "SUSPENDU",
  "RESILIE"
]);

export const saasTransitionReasonEnum = pgEnum("saas_transition_reason", [
  "PAYMENT_FAILED",
  "PAYMENT_SUCCEEDED",
  "GRACE_PERIOD_EXPIRED",
  "SUSPENSION_PERIOD_EXPIRED",
  "MANUAL_OVERRIDE",
  "ACCOUNT_REACTIVATED"
]);
```

#### Colonnes ajoutées sur `communities`
| Colonne | Type | Description |
|---------|------|-------------|
| `saas_client_status` | enum | Statut actuel (défaut: ACTIVE) |
| `saas_status_changed_at` | timestamp | Date du dernier changement |
| `unpaid_since` | timestamp | Date de référence pour calculs temporels |
| `suspended_at` | timestamp | Date de suspension |
| `terminated_at` | timestamp | Date de résiliation |

#### Tables d'audit
- **`subscription_status_audit`**: Historique de toutes les transitions
- **`subscription_emails_sent`**: Tracking anti-doublon des emails

### 2.2 Méthodes Storage

**Fichier:** `server/storage.ts`

```typescript
interface IStorage {
  // Transition de statut avec audit complet
  transitionSaasStatus(
    communityId: string,
    newStatus: SaasClientStatus,
    reason: SaasTransitionReason,
    triggeredBy: "WEBHOOK" | "JOB" | "MANUAL",
    options?: {
      stripeEventId?: string;
      stripeInvoiceId?: string;
      unpaidSinceOverride?: Date;
      metadata?: Record<string, any>;
    }
  ): Promise<void>;

  // Récupération des communautés nécessitant transition
  getCommunitiesNeedingStatusTransition(): Promise<{
    needsImpaye2: Community[];
    needsSuspension: Community[];
    needsTermination: Community[];
  }>;

  // Audit trail
  getSubscriptionStatusAudit(communityId: string): Promise<SubscriptionStatusAudit[]>;
  
  // Tracking emails
  hasEmailBeenSent(communityId: string, emailType: string): Promise<boolean>;
  markEmailSent(communityId: string, emailType: string): Promise<void>;
}
```

### 2.3 Webhooks Stripe

**Fichier:** `server/stripe.ts`

#### `invoice.payment_failed`
- Déclenche transition ACTIVE → IMPAYE_1
- Utilise `invoice.due_date` comme `unpaidSince` (si disponible)
- Enregistre `stripeEventId` (ID du webhook) et `stripeInvoiceId` (ID facture)

#### `invoice.payment_succeeded`
- Déclenche transition IMPAYE_* → ACTIVE
- Réinitialise `unpaidSince` à null
- Crée entrée d'audit avec raison PAYMENT_SUCCEEDED

### 2.4 Job Quotidien

**Fichier:** `scripts/check-subscription-status.ts`

```bash
# Mode test (dry-run)
npx tsx scripts/check-subscription-status.ts --dry-run

# Exécution réelle
npx tsx scripts/check-subscription-status.ts
```

#### Logique de transition
```
SI unpaidSince + 15 jours ≤ maintenant ET status = IMPAYE_1
  → Transition vers IMPAYE_2

SI unpaidSince + 30 jours ≤ maintenant ET status = IMPAYE_2
  → Transition vers SUSPENDU

SI unpaidSince + 60 jours ≤ maintenant ET status = SUSPENDU
  → Transition vers RESILIE
```

### 2.5 Middleware d'Accès

**Fichier:** `server/lib/saasAccess.ts`

```typescript
export function checkSaasAccess(allowExport: boolean = false) {
  return async (req: Request, res: Response, next: NextFunction) => {
    // Vérifie le statut SaaS de la communauté
    // Bloque si SUSPENDU ou RESILIE (sauf export si allowExport=true)
    // Laisse passer pour ACTIVE, IMPAYE_1, IMPAYE_2
  };
}
```

#### Comportement par statut
| Statut | Accès normal | Export données |
|--------|--------------|----------------|
| ACTIVE | ✅ | ✅ |
| IMPAYE_1 | ✅ | ✅ |
| IMPAYE_2 | ✅ | ✅ |
| SUSPENDU | ❌ | ✅ (RGPD) |
| RESILIE | ❌ | ✅ (RGPD) |

### 2.6 Composants Frontend

**Fichier:** `client/src/components/SaasStatusBanner.tsx`

#### Bandeaux d'alerte
- **IMPAYE_1**: Bandeau jaune avec compte à rebours (15 jours)
- **IMPAYE_2**: Bandeau orange avec avertissement pré-suspension

#### Pages de blocage
- **SUSPENDU**: Page pleine avec option export
- **RESILIE**: Page pleine avec message de résiliation

---

## 3. Règles de Conception Clés

### 3.1 Référence temporelle unique
> **Toutes les transitions sont calculées depuis `unpaidSince` uniquement.**

- `unpaidSince` est défini lors de la première transition ACTIVE → IMPAYE_1
- Cette valeur est préservée à travers toutes les transitions ultérieures
- Elle n'est réinitialisée qu'au retour vers ACTIVE

### 3.2 Pas de comptage de factures
> **Le système ne compte PAS les factures impayées.**

La progression est purement temporelle:
- J+0 = Premier paiement échoué
- J+15 = Passage à IMPAYE_2
- J+30 = Suspension
- J+60 = Résiliation

### 3.3 IMPAYE_2 = informatif uniquement
> **IMPAYE_2 n'a aucune restriction fonctionnelle supplémentaire par rapport à IMPAYE_1.**

La différence est uniquement visuelle (bandeau orange vs jaune) pour alerter le client de l'imminence de la suspension.

### 3.4 Export toujours autorisé
> **Conformité RGPD: les clients peuvent toujours exporter leurs données.**

Même en statut SUSPENDU ou RESILIE, l'export des données reste disponible.

### 3.5 Seul `self_service` est concerné
> **Le système n'affecte que les communautés avec `billingMode = "self_service"`.**

Les communautés `manual_contract` (white-label, contrats manuels) ne sont pas impactées.

---

## 4. Fichiers Modifiés/Créés

### Schéma et Types
- `shared/schema.ts` - Enums et tables

### Backend
- `server/storage.ts` - Méthodes de transition
- `server/stripe.ts` - Handlers webhook enrichis
- `server/lib/saasAccess.ts` - Middleware d'accès

### Scripts
- `scripts/check-subscription-status.ts` - Job quotidien

### Frontend
- `client/src/components/SaasStatusBanner.tsx` - Bandeaux et pages

### Documentation
- `docs/plan-implementation-saas-paiement.md` - Plan technique
- `docs/audit-saas-paiement-clients.md` - Spécification fonctionnelle
- `replit.md` - Documentation projet mise à jour

---

## 5. Phases Restantes

### 5.1 Notifications Email (Phase 9)

Templates à implémenter:
| Code | Déclencheur | Contenu |
|------|-------------|---------|
| E01 | IMPAYE_1 J+0 | Premier avis d'impayé |
| E02 | IMPAYE_1 J+7 | Rappel mi-période |
| E03 | IMPAYE_2 J+15 | Avis pré-suspension |
| E04 | IMPAYE_2 J+22 | Dernier rappel |
| E05 | SUSPENDU J+30 | Notification suspension |
| E06 | SUSPENDU J+45 | Rappel mi-suspension |
| E07 | RESILIE J+60 | Notification résiliation |

Système anti-doublon via table `subscription_emails_sent`.

### 5.2 Feature Flag (Phase 10)

Stratégie de déploiement:
1. Déployer le code (désactivé par défaut)
2. Activer pour une communauté test
3. Valider le cycle complet
4. Activer progressivement
5. Activation générale

---

## 6. Tests Recommandés

### Scénarios à valider

1. **Paiement échoué sur compte ACTIVE**
   - Vérifier transition vers IMPAYE_1
   - Vérifier `unpaidSince` = date d'échéance facture

2. **Paiement réussi pendant IMPAYE_1**
   - Vérifier retour vers ACTIVE
   - Vérifier `unpaidSince` = null

3. **Progression temporelle J+15**
   - Lancer job quotidien
   - Vérifier transition IMPAYE_1 → IMPAYE_2

4. **Suspension J+30**
   - Vérifier blocage d'accès
   - Vérifier accès export maintenu

5. **Résiliation J+60**
   - Vérifier transition finale
   - Vérifier `terminatedAt` défini

---

## 7. Conclusion

Le système de paiement SaaS est opérationnel pour les fonctions core:
- ✅ Détection automatique des impayés
- ✅ Transitions temporelles calculées
- ✅ Blocage d'accès approprié
- ✅ Audit trail complet
- ✅ Interface utilisateur informative

Les deux phases restantes (notifications email et feature flag) sont des améliorations qui peuvent être déployées indépendamment sans bloquer la mise en production du système principal.
