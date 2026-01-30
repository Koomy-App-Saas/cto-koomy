# RAPPORT AS-BUILT : Tags disponibles sur tous les plans avec quotas

**Date** : 25 janvier 2026  
**Statut** : Implémenté  
**Auteur** : Agent Replit  

---

## 1. Résumé Exécutif

Suite à l'audit des rôles, privilèges, quotas et plan-gating, la fonctionnalité **Tags** a été modifiée pour passer d'un modèle "bloqué par plan" à un modèle **"disponible sur tous les plans avec quotas"**.

**Avant** : Tags uniquement disponibles sur certains plans (gating binaire)  
**Après** : Tags disponibles sur TOUS les plans, avec limites de quota par plan

---

## 2. Quotas par Plan

| Plan | Limite maxTags | Upgrade Path |
|------|----------------|--------------|
| FREE | 10 | BILLING (vers Plus) |
| PLUS | 50 | BILLING (vers Pro) |
| PRO | 200 | BILLING (vers Enterprise) |
| ENTERPRISE | 700 | SUPPORT (contrat) |
| WHITELABEL | 700 | SUPPORT (contrat) |

---

## 3. Modifications Backend

### 3.1 `server/lib/planLimits.ts`

Ajout de la limite `maxTags` dans `PLAN_LIMITS_MAP` :

```typescript
export const PLAN_LIMITS_MAP: Record<string, PlanLimits> = {
  free: { maxMembers: 20, maxAdmins: 1, maxEvents: 5, maxNews: 10, maxTags: 10 },
  plus: { maxMembers: 100, maxAdmins: 3, maxEvents: 20, maxNews: 30, maxTags: 50 },
  pro: { maxMembers: 500, maxAdmins: 10, maxEvents: 100, maxNews: 100, maxTags: 200 },
  enterprise: { maxMembers: null, maxAdmins: null, maxEvents: null, maxNews: null, maxTags: 700 },
  whitelabel: { maxMembers: null, maxAdmins: null, maxEvents: null, maxNews: null, maxTags: 700 },
};
```

Extension du type `LimitKey` :

```typescript
export type LimitKey = "maxMembers" | "maxAdmins" | "maxEvents" | "maxNews" | "maxTags";
```

### 3.2 `server/lib/usageLimitsGuards.ts`

Ajout de la fonction `getTagCount()` :

```typescript
export async function getTagCount(communityId: string): Promise<number> {
  const [result] = await db
    .select({ count: count() })
    .from(tags)
    .where(eq(tags.communityId, communityId));
  return result?.count || 0;
}
```

Extension de `getCurrentUsage()` :

```typescript
case "maxTags":
  return getTagCount(communityId);
```

**Correction du bypass Enterprise/WL dans `checkLimit()`** :

Le bypass P2.8.1 pour Enterprise/WhiteLabel a été ajusté pour n'appliquer le bypass QUE si la limite est `null` (vraiment illimitée). Si une limite a une valeur explicite non-null (ex: `maxTags=700`), elle est appliquée :

```typescript
// P2.8.1: Bypass applies ONLY if the limit is null (truly unlimited)
// If limit has an explicit non-null value (e.g., maxTags=700), enforce it
if ((effectivePlan.isEnterprise || effectivePlan.isWhiteLabel) && maxValue === null) {
  return { allowed: true };
}
```

### 3.3 `server/routes.ts` - POST `/api/communities/:id/tags`

Ajout de la vérification de quota avec réponse HTTP 402 structurée :

```typescript
const limitResult = await checkLimit(communityId, "maxTags");
if (!limitResult.allowed) {
  return res.status(402).json({
    error: "Quota de tags atteint pour votre offre",
    code: "PLAN_QUOTA_REACHED",
    feature: "TAGS",
    quota: limitResult.max,
    current: currentCount,
    plan: effectivePlan.planId.toUpperCase(),
    upgradePath: isEnterprise ? "SUPPORT" : "BILLING"
  });
}
```

---

## 4. Modifications Frontend

### 4.1 `client/src/components/FeatureGateModal.tsx` (NOUVEAU)

Composant générique réutilisable pour afficher les erreurs de quota :

**Fonctionnalités** :
- Affichage visuel du quota atteint (barre de progression)
- Icône contextuelle par feature (Tags, Members, Events, etc.)
- CTA adapté au plan : "Voir les offres" (BILLING) ou "Contacter le support" (SUPPORT)
- Conformité a11y avec `aria-describedby`

**Props** :
```typescript
interface FeatureGateModalProps {
  isOpen: boolean;
  onClose: () => void;
  quotaError: PlanQuotaError | null;
}
```

**Exports utilitaires** :
- `isPlanQuotaError(error)` : Type guard pour détecter les erreurs de quota
- `useFeatureGate()` : Hook pour gérer les erreurs API

### 4.2 `client/src/pages/admin/Tags.tsx`

Intégration du FeatureGateModal :

```typescript
import { FeatureGateModal, type PlanQuotaError, isPlanQuotaError } from "@/components/FeatureGateModal";

// State
const [quotaError, setQuotaError] = useState<PlanQuotaError | null>(null);

// Dans onError du createMutation
if (isPlanQuotaError(error)) {
  setIsCreateOpen(false);
  setQuotaError(error);
  return;
}

// Render
<FeatureGateModal
  isOpen={!!quotaError}
  onClose={() => setQuotaError(null)}
  quotaError={quotaError}
/>
```

---

## 5. Contrat API

### Erreur 402 - Quota Atteint

```json
{
  "error": "Quota de tags atteint pour votre offre",
  "code": "PLAN_QUOTA_REACHED",
  "feature": "TAGS",
  "quota": 10,
  "current": 10,
  "plan": "FREE",
  "upgradePath": "BILLING"
}
```

| Champ | Type | Description |
|-------|------|-------------|
| `code` | `"PLAN_QUOTA_REACHED"` | Code machine pour détection |
| `feature` | string | Feature concernée (TAGS, MEMBERS, etc.) |
| `quota` | number | Limite du plan actuel |
| `current` | number | Utilisation actuelle |
| `plan` | string | Nom du plan (uppercase) |
| `upgradePath` | `"BILLING" \| "SUPPORT"` | CTA approprié |

---

## 6. Accessibilité (a11y)

Le composant FeatureGateModal respecte les guidelines WCAG :

- `aria-describedby="feature-gate-description"` sur le DialogContent
- `id="feature-gate-description"` sur le DialogDescription
- Boutons avec `data-testid` pour les tests automatisés
- Focus trap géré par Radix UI Dialog

---

## 7. Réutilisabilité

Le pattern implémenté est **générique** et peut être appliqué à d'autres features :

```typescript
// Exemple pour MEMBERS
const limitResult = await checkLimit(communityId, "maxMembers");
if (!limitResult.allowed) {
  return res.status(402).json({
    code: "PLAN_QUOTA_REACHED",
    feature: "MEMBERS",
    // ...
  });
}
```

Les icônes et labels sont déjà configurés dans FeatureGateModal pour :
- TAGS, MEMBERS, EVENTS, NEWS, MESSAGING, ANALYTICS, ADMINS

---

## 8. Tests Recommandés

1. **Free plan** : Créer 10 tags, vérifier modal au 11ème
2. **Plus plan** : Créer 50 tags, vérifier modal au 51ème
3. **Enterprise** : Vérifier CTA "Contacter le support" au lieu de "Voir les offres"
4. **Downgrade** : Vérifier comportement si quota dépassé après downgrade (lecture seule, pas de création)

---

## 9. Fichiers Modifiés

| Fichier | Action |
|---------|--------|
| `server/lib/planLimits.ts` | Modifié (ajout maxTags) |
| `server/lib/usageLimitsGuards.ts` | Modifié (getTagCount, getCurrentUsage) |
| `server/routes.ts` | Modifié (quota check sur POST tags) |
| `client/src/components/FeatureGateModal.tsx` | **Créé** |
| `client/src/pages/admin/Tags.tsx` | Modifié (intégration modal) |

---

## 10. Prochaines Étapes (Optionnelles)

- [ ] Appliquer le même pattern à maxMembers (GAP-001)
- [ ] Appliquer le même pattern à maxAdmins
- [ ] Afficher l'utilisation quota dans le header de chaque section
- [ ] Ajouter endpoint GET `/api/communities/:id/quota-usage` pour dashboard
