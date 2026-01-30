# Rapport P1 : Quotas Admins SaaS Owner Platform

**Date :** 2026-01-26  
**Auteur :** Koomy Agent  
**Statut :** ✅ Implémenté

---

## 1. Objectif

Permettre au SaaS Owner Platform de configurer des quotas d'administrateurs personnalisés par communauté, avec :
- **Default override** : valeur par défaut configurable (nullable, max 200)
- **Contract override** : surcharge contractuelle prioritaire (peut dépasser 200)
- **Résolution centralisée** via `resolveCommunityLimits()`

## 2. Architecture Technique

### 2.1 Nouveaux Champs Database

```sql
ALTER TABLE communities ADD COLUMN max_admins_default INTEGER;
ALTER TABLE communities ADD COLUMN max_admins_override INTEGER;
```

- `max_admins_default` : Valeur par défaut SaaS-configurable (nullable)
- `max_admins_override` : Override contractuel prioritaire (nullable)

### 2.2 Logique de Résolution (3-tier priority)

```
contractAdminLimit (override) > maxAdminsDefault (custom) > plan default (KOOMY_PLANS)
```

Implémentée dans `server/lib/planLimits.ts` :

```typescript
export function resolveCommunityLimits(
  community: { planId: string; maxAdminsDefault?: number | null; contractAdminLimit?: number | null },
  currentAdminCount?: number
): ResolvedLimits {
  const planDef = KOOMY_PLANS[planId];
  const planDefault = DEFAULT_LIMITS[planId]?.maxAdmins ?? 1;
  
  // Priority: override > default > plan
  let effectiveMaxAdmins = planDefault;
  let source: "override" | "default" | "plan_default" = "plan_default";
  
  if (contractAdminLimit !== null && contractAdminLimit !== undefined) {
    effectiveMaxAdmins = contractAdminLimit;
    source = "override";
  } else if (maxAdminsDefault !== null && maxAdminsDefault !== undefined) {
    effectiveMaxAdmins = maxAdminsDefault;
    source = "default";
  }
  
  return { effectiveMaxAdmins, source, planMaxAdmins: planDefault, currentAdminCount };
}
```

### 2.3 API Endpoints

#### GET `/api/platform/communities/:id/quota-limits`

Retourne les quotas actuels avec résolution :

```json
{
  "communityId": "uuid",
  "planId": "plus",
  "maxAdminsDefault": null,
  "contractAdminLimit": 10,
  "effectiveMaxAdmins": 10,
  "maxAdminsSource": "override",
  "planMaxAdmins": 2,
  "currentAdminCount": 3
}
```

#### PATCH `/api/platform/communities/:id/quota-limits`

Met à jour les quotas avec audit log :

```json
{
  "maxAdminsDefault": 5,
  "maxAdminsOverride": null,
  "reason": "Extension contrat client XYZ"
}
```

Validation :
- `maxAdminsDefault` : nullable, max 200
- `maxAdminsOverride` : nullable, peut dépasser 200 (warning loggé)

### 2.4 Audit Log

Chaque modification est enregistrée dans `platform_audit_logs` :

```json
{
  "action": "update_quota_limits",
  "entityType": "community",
  "entityId": "community-uuid",
  "changes": {
    "before": { "maxAdminsDefault": null, "maxAdminsOverride": null, "effective": 2 },
    "after": { "maxAdminsDefault": 5, "maxAdminsOverride": null, "effective": 5, "source": "default" }
  },
  "reason": "Extension contrat client XYZ"
}
```

## 3. Interface SaaS Owner Platform

### 3.1 Onglet "Quotas" ajouté

Dans le modal White-Label/Community, nouvel onglet `quotas` :

- **Vue récapitulative** : admins actuels / limite effective, source (badge)
- **Champs éditables** :
  - Max admins (default) : input number, placeholder dynamique
  - Max admins (override contractuel) : input number
  - Raison de modification : input text pour audit trail
- **Bouton sauvegarde** avec feedback toast

### 3.2 UX

- Indicateur visuel rouge si quota atteint
- Badge source : "Override contractuel" / "Valeur par défaut" / "Plan par défaut"
- Chargement async avec spinner

## 4. Enforcement

L'endpoint `POST /api/communities/:communityId/admins` vérifie maintenant :

```typescript
const limits = resolveCommunityLimits(community, currentAdminCount);
if (currentAdminCount >= limits.effectiveMaxAdmins) {
  return res.status(403).json({
    error: "PLAN_ADMIN_QUOTA_EXCEEDED",
    message: `Limite de ${limits.effectiveMaxAdmins} administrateurs atteinte`,
    current: currentAdminCount,
    limit: limits.effectiveMaxAdmins
  });
}
```

## 5. Tests

5/5 tests de cohérence plan-limits passent :

```
✔ FREE plan limits match between KOOMY_PLANS and DEFAULT_LIMITS
✔ PLUS plan limits match between KOOMY_PLANS and DEFAULT_LIMITS
✔ PRO plan limits match between KOOMY_PLANS and DEFAULT_LIMITS
✔ ENTERPRISE plan limits match between KOOMY_PLANS and DEFAULT_LIMITS
✔ maxTags limits are defined for all plans
```

Boot-time guard dans `server/index.ts` vérifie la cohérence au démarrage.

## 6. Fichiers Modifiés

| Fichier | Changement |
|---------|------------|
| `shared/schema.ts` | Ajout colonnes `maxAdminsDefault`, `contractAdminLimit` |
| `server/lib/planLimits.ts` | Ajout `resolveCommunityLimits()` |
| `server/routes.ts` | GET/PATCH quota-limits endpoints |
| `client/src/pages/platform/SuperDashboard.tsx` | Onglet Quotas UI |

## 7. Ajouts P1 (2026-01-26)

### 7.1 Endpoint `/api/health/db`

Nouveau endpoint pour vérifier l'alignement DB ↔ code :

```json
GET /api/health/db

{
  "ok": true,
  "schema": {
    "communities": {
      "max_admins_default": true,
      "contract_admin_limit": true,
      "contract_member_limit": true
    },
    "plans": {
      "max_admins": true
    }
  },
  "sourceOfTruth": {
    "plansTable": "plans"
  },
  "message": "All required columns present",
  "timestamp": "..."
}
```

Si colonnes manquantes : `ok: false`, liste `missing`, et message avec instructions.

### 7.2 SQL Fallback File

Fichier : `docs/db/FALLBACK_SQL_add_admin_quota_columns.sql`

Contient les requêtes `ALTER TABLE ... ADD COLUMN IF NOT EXISTS` pour restaurer les colonnes en urgence si `npm run db:push` échoue.

### 7.3 Boot-time Schema Guard

Dans `server/index.ts`, fonction `validateDatabaseSchema()` :
- Vérifie l'existence des colonnes requises au démarrage
- Bloque le serveur si colonnes manquantes avec message clair
- Référence le fichier SQL fallback dans les logs d'erreur

### 7.4 Plan-level maxAdmins Editing

L'endpoint `PUT /api/platform/plans/:id` supporte maintenant :
- `maxAdmins` dans le body (optionnel)
- Validation : entier entre 1 et 50
- Audit logging des modifications

UI dans SuperDashboard → Plans → Modal d'édition → nouveau champ "Limite admins".

## 8. Prochaines Étapes (P2)

- [ ] Admin backoffice : jauge quota admins (X/Y) + bouton "Ajouter admin" désactivé si quota atteint
- [ ] Extension à d'autres quotas (maxMembers, maxEvents, etc.)
- [ ] Historique des modifications quotas (timeline)

---

**Fin du rapport P1**
