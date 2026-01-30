# Rapport: Quotas Administrateurs Bornés et Surchargeables

**Date**: 2026-01-25  
**Auteur**: Agent Replit  
**Version**: 1.0  
**Statut**: Implémenté

---

## 1. Contexte

L'audit `REPORT_admins_enforcement_gaps.md` (GAP-ADMIN-01) a identifié une faille critique:
- **maxAdmins** était défini dans KOOMY_PLANS mais **jamais appliqué** sur les endpoints de création d'admin
- Les plans PLUS/PRO/ENTERPRISE avaient `maxAdmins: null` (illimité), créant un risque d'abus

## 2. Décisions Architecturales

### 2.1 Règle P0: Quotas Admins Numériques

**Décision**: Tous les quotas `maxAdmins` sont désormais des valeurs numériques bornées (jamais `null`/unlimited).

| Plan | maxAdmins Avant | maxAdmins Après |
|------|-----------------|-----------------|
| FREE | 1 | **1** |
| PLUS | null | **2** |
| PRO | null | **5** |
| ENTERPRISE | null | **7** |

**Justification**: 
- Les administrateurs ont un accès privilégié aux données sensibles
- Un quota illimité d'admins présente un risque de sécurité et de gouvernance
- Valeurs choisies selon les besoins typiques de chaque tier

### 2.2 Override Contractuel: `contractAdminLimit`

Un nouveau champ `contractAdminLimit` (nullable integer) permet au SaaS Owner de surcharger le quota par défaut pour des besoins contractuels spécifiques.

**Comportement**:
- Si `contractAdminLimit IS NULL` → utilise la valeur du plan
- Si `contractAdminLimit` est défini → utilise cette valeur (extension ou restriction)

## 3. Modifications Techniques

### 3.1 Fichiers Modifiés

| Fichier | Modification |
|---------|--------------|
| `shared/plans.ts` | maxAdmins numériques: FREE:1, PLUS:2, PRO:5, ENTERPRISE:7 |
| `server/lib/planLimits.ts` | DEFAULT_LIMITS aligné + getEffectivePlan() avec contractAdminLimit |
| `server/index.ts` | Boot guard validant la cohérence KOOMY_PLANS ↔ DEFAULT_LIMITS |
| `shared/schema.ts` | Ajout champ `contractAdminLimit` sur communities |
| `server/routes.ts` | Appel `checkLimit("maxAdmins")` sur POST /admins |
| `server/tests/plan-limits-alignment.test.ts` | Tests mis à jour avec valeurs numériques |

### 3.2 API Enforcement

**Endpoint**: `POST /api/communities/:communityId/admins`

**Nouveau comportement**:
```typescript
const adminQuotaCheck = await checkLimit(communityId, "maxAdmins");
if (!adminQuotaCheck.allowed) {
  return res.status(403).json({
    error: "Quota d'administrateurs atteint...",
    code: "PLAN_ADMIN_QUOTA_EXCEEDED",
    current: adminQuotaCheck.current,
    max: adminQuotaCheck.max,
    planId: adminQuotaCheck.planId
  });
}
```

### 3.3 getEffectivePlan() Enhancement

```typescript
// Override maxAdmins if community has contractual admin limit
if (community.contractAdminLimit !== null && community.contractAdminLimit !== undefined) {
  planLimits.maxAdmins = community.contractAdminLimit;
}
```

## 4. Tests

```
▶ Plan Limits Alignment
  ✔ FREE plan limits match between KOOMY_PLANS and DEFAULT_LIMITS
  ✔ PLUS plan limits match between KOOMY_PLANS and DEFAULT_LIMITS
  ✔ PRO plan limits match between KOOMY_PLANS and DEFAULT_LIMITS
  ✔ ENTERPRISE plan limits match between KOOMY_PLANS and DEFAULT_LIMITS
  ✔ maxTags limits are defined for all plans

ℹ tests 5
ℹ pass 5
ℹ fail 0
```

## 5. Éléments Restants (P2)

| ID | Description | Priorité |
|----|-------------|----------|
| UI-SAAS-01 | Interface SaaS Owner pour configurer contractAdminLimit | P2 |
| UI-ADMIN-01 | Désactiver bouton "Ajouter admin" si quota atteint | P2 |
| UI-ADMIN-02 | Afficher jauge admins (X/Y) dans le backoffice | P2 |

## 6. Schéma de Flux

```
+------------------+     +--------------------+     +------------------+
| POST /admins     | --> | checkLimit         | --> | Allowed?         |
| (Owner only)     |     | ("maxAdmins")      |     | Yes: Continue    |
+------------------+     +--------------------+     | No: 403 QUOTA    |
                                                    +------------------+
                                |
                                v
                    +------------------------+
                    | getEffectivePlan()     |
                    | 1. Get plan defaults   |
                    | 2. Apply override if   |
                    |    contractAdminLimit  |
                    +------------------------+
```

## 7. Conclusion

L'implémentation ferme la faille GAP-ADMIN-01:
- ✅ Quotas admins bornés pour tous les plans
- ✅ Enforcement API sur création d'admin
- ✅ Override contractuel disponible pour SaaS Owner
- ✅ Boot-time guard garantissant la cohérence des valeurs
- ✅ Tests automatisés validant l'alignement
