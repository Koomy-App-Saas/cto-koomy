# Audit Global : Mapping Plans ↔ Features ↔ Limites

**Date** : 2026-01-29  
**Domaine** : FEATURES / BILLING / LIMITS  
**Type** : AUDIT  
**Priorité** : P0 — Structurant

---

## Contexte

Koomy est un SaaS multi-tenant avec :
- Plusieurs plans : `free`, `growth`, `scale`, `enterprise`, `whitelabel`
- Un système de features (capabilities)
- Un système de limites / quotas
- Une UI dépendant de ce mapping

**Décision business** : La différenciation se fait par limites, commissions et conditions — pas par blocage fonctionnel brutal.

---

## 1. Inventaire Global des Features (Capabilities)

### 1.1 Source de vérité : Interface `PlanCapabilities`

**Fichier** : `shared/schema.ts` (lignes 210-238)

```typescript
export interface PlanCapabilities {
  qrCard?: boolean;           // QR code sur cartes membres
  dues?: boolean;             // Cotisations/membership fees
  messaging?: boolean;        // Messagerie membres/admins
  events?: boolean;           // Événements avec inscriptions
  analytics?: boolean;        // Statistiques de base
  advancedAnalytics?: boolean; // Analytics avancées
  exportData?: boolean;       // Export de données
  apiAccess?: boolean;        // Accès API
  multiAdmin?: boolean;       // Multi-admins avec rôles
  unlimitedSections?: boolean; // Sections/régions illimitées
  customization?: boolean;    // Personnalisation avancée
  multiCommunity?: boolean;   // Multi-communautés
  slaGuarantee?: boolean;     // SLA garanti
  dedicatedManager?: boolean; // Manager de succès dédié
  prioritySupport?: boolean;  // Support prioritaire
  support24x7?: boolean;      // Support 24/7
  customDomain?: boolean;     // Domaine personnalisé (white-label)
  whiteLabeling?: boolean;    // Branding marque blanche
  eventRsvp?: boolean;        // Inscriptions événements/RSVP
  eventPaid?: boolean;        // Événements payants
  eventPaidQuota?: number | null;  // Quota événements payants/mois
  eventTargeting?: boolean;   // Ciblage événements par section/tags
  eventCapacity?: boolean;    // Limites de capacité événements
  eventDeadline?: boolean;    // Date limite inscription
  eventStats?: boolean;       // Statistiques événements
  eventWaitlist?: boolean;    // Liste d'attente (Grand Compte)
  eventApproval?: boolean;    // Approbation manuelle inscriptions
}
```

### 1.2 Liste exhaustive des features

| ID Canonique | Nom Fonctionnel | Description | Type |
|--------------|-----------------|-------------|------|
| `qrCard` | Carte QR Code | QR code sur les cartes membres digitales | boolean |
| `dues` | Cotisations | Gestion des cotisations / membership fees | boolean |
| `messaging` | Messagerie | Communication membres ↔ admins | boolean |
| `events` | Événements | Création et gestion d'événements | boolean |
| `analytics` | Statistiques | Statistiques de base de la communauté | boolean |
| `advancedAnalytics` | Analytics Avancées | Tableaux de bord et métriques avancés | boolean |
| `exportData` | Export Données | Export des données (membres, stats) | boolean |
| `apiAccess` | Accès API | Accès à l'API REST | boolean |
| `multiAdmin` | Multi-Admin | Plusieurs admins avec rôles différenciés | boolean |
| `unlimitedSections` | Sections Illimitées | Nombre illimité de sections/régions | boolean |
| `customization` | Personnalisation | Personnalisation avancée (couleurs, branding) | boolean |
| `multiCommunity` | Multi-Communautés | Gestion de plusieurs communautés | boolean |
| `slaGuarantee` | SLA Garanti | Garantie de niveau de service | boolean |
| `dedicatedManager` | Manager Dédié | Accompagnement par un responsable dédié | boolean |
| `prioritySupport` | Support Prioritaire | Support prioritaire | boolean |
| `support24x7` | Support 24/7 | Support disponible 24h/24, 7j/7 | boolean |
| `customDomain` | Domaine Personnalisé | Sous-domaine ou domaine custom (WL) | boolean |
| `whiteLabeling` | Marque Blanche | Branding complet en marque blanche | boolean |
| `eventRsvp` | Inscriptions Événements | RSVP et inscriptions aux événements | boolean |
| `eventPaid` | Événements Payants | Possibilité de créer des événements payants | boolean |
| `eventPaidQuota` | Quota Événements Payants | Nombre max d'événements payants/mois | number/null |
| `eventTargeting` | Ciblage Événements | Ciblage par section/tags | boolean |
| `eventCapacity` | Capacité Événements | Gestion des limites de places | boolean |
| `eventDeadline` | Date Limite RSVP | Date limite pour s'inscrire | boolean |
| `eventStats` | Stats Événements | Statistiques des événements | boolean |
| `eventWaitlist` | Liste d'attente | File d'attente pour événements complets | boolean |
| `eventApproval` | Approbation Manuelle | Validation manuelle des inscriptions | boolean |

---

## 2. Sources de Définition

### 2.1 Où sont définies les features ?

| Source | Fichier | Type | Pilotable SQL |
|--------|---------|------|---------------|
| **Table `plans`** | DB | `plans.capabilities` (JSONB) | ✅ OUI |
| **DEFAULT_CAPABILITIES** | `server/lib/planLimits.ts:43-125` | Hardcodé (fallback) | ❌ NON |
| **KOOMY_PLANS** | `shared/plans.ts:24+` | Hardcodé (config frontend) | ❌ NON |

### 2.2 Priorité de résolution (runtime)

```
1. plans.capabilities (DB)          ← Source prioritaire
2. DEFAULT_CAPABILITIES (code)      ← Fallback si DB vide/erreur
```

**Fonction** : `getPlanCapabilities(planId)` dans `server/lib/planLimits.ts:244-265`

### 2.3 Structure des capabilities en DB

**Table** : `plans`  
**Colonne** : `capabilities` (JSONB)

Exemple actuel en DB (plan `growth`) :
```json
{
  "admins": {"max": 3},
  "members": {"max": 100},
  "support": "priority",
  "features": {
    "tags": false,
    "qrCard": true,
    "analytics": "basic",
    "messaging": true,
    "dataExport": false,
    "cotisations": true,
    "integrations": false,
    "targetedContent": false,
    "eventRegistration": true,
    "sectionsUnlimited": false
  }
}
```

**⚠️ ATTENTION** : Le format JSONB en DB diffère du format `PlanCapabilities` TypeScript. Le code gère cette différence via des alias (ex: `cotisations` → `dues`).

---

## 3. Où sont consommées les features ?

### 3.1 Backend Guards

**Fichier** : `server/lib/usageLimitsGuards.ts`

| Fonction | Usage |
|----------|-------|
| `checkCapability(communityId, capabilityKey)` | Vérifie si une capability est active |
| `requireCapability(getCommunityId, capabilityKey)` | Middleware Express bloquant |
| `hasCapability(capabilities, key)` | Helper pour vérifier une capability |

**Fichier** : `server/lib/planLimits.ts`

| Fonction | Usage |
|----------|-------|
| `getPlanCapabilities(planId)` | Récupère les capabilities d'un plan |
| `getEffectivePlan(communityId)` | Récupère plan effectif avec capabilities |
| `hasCapability(capabilities, key)` | Vérifie présence d'une capability |

### 3.2 Bypass Enterprise/WhiteLabel

Les plans `enterprise` et `whitelabel` ont un **bypass automatique** :

```typescript
// server/lib/usageLimitsGuards.ts:150-153
if (effectivePlan.isEnterprise || effectivePlan.isWhiteLabel) {
  return { allowed: true };
}
```

### 3.3 Frontend

Le frontend n'accède **pas directement** aux capabilities. Il consomme :
- Les limites via `/api/community/:id/limits`
- Les erreurs `CAPABILITY_NOT_ALLOWED` retournées par le backend

---

## 4. Mapping Plan → Features

### 4.1 Plans existants en DB

| ID DB | Nom Commercial | Code |
|-------|----------------|------|
| `free` | Free Starter | FREE |
| `growth` | Communauté Plus | PLUS |
| `scale` | Communauté Pro | PRO |
| `enterprise` | Grand Compte | GRAND_COMPTE |
| `whitelabel` | Koomy White Label | - |

### 4.2 Matrice Features par Plan

| Feature | free | growth | scale | enterprise | whitelabel |
|---------|------|--------|-------|------------|------------|
| `qrCard` | ❌ | ✅ | ✅ | ✅ | ✅ |
| `dues` | ❌ | ✅ | ✅ | ✅ | ✅ |
| `messaging` | ❌ | ✅ | ✅ | ✅ | ✅ |
| `events` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `analytics` | ❌ | ✅ (basic) | ✅ | ✅ | ✅ |
| `advancedAnalytics` | ❌ | ❌ | ✅ | ✅ | ✅ |
| `exportData` | ❌ | ❌ | ✅ | ✅ | ✅ |
| `apiAccess` | ❌ | ❌ | ✅ | ✅ | ✅ |
| `multiAdmin` | ❌ | ❌ | ✅ | ✅ | ✅ |
| `unlimitedSections` | ❌ | ❌ | ✅ | ✅ | ✅ |
| `customization` | ❌ | ❌ | ✅ | ✅ | ✅ |
| `multiCommunity` | ❌ | ❌ | ❌ | ✅ | ✅ |
| `slaGuarantee` | ❌ | ❌ | ❌ | ✅ | ✅ |
| `dedicatedManager` | ❌ | ❌ | ❌ | ✅ | ✅ |
| `prioritySupport` | ❌ | ✅ | ✅ | ✅ | ✅ |
| `support24x7` | ❌ | ❌ | ❌ | ✅ | ✅ |
| `customDomain` | ❌ | ❌ | ❌ | ❌ | ✅ |
| `whiteLabeling` | ❌ | ❌ | ❌ | ❌ | ✅ |
| `eventRsvp` | ❌ | ✅ | ✅ | ✅ | ✅ |
| `eventPaid` | ❌ | ✅ | ✅ | ✅ | ✅ |
| `eventPaidQuota` | 0 | 2 | null | null | null |
| `eventTargeting` | ❌ | ❌ | ✅ | ✅ | ✅ |
| `eventCapacity` | ❌ | ❌ | ✅ | ✅ | ✅ |
| `eventDeadline` | ❌ | ❌ | ✅ | ✅ | ✅ |
| `eventStats` | ❌ | ❌ | ✅ | ✅ | ✅ |
| `eventWaitlist` | ❌ | ❌ | ❌ | ✅ | ✅ |
| `eventApproval` | ❌ | ❌ | ❌ | ✅ | ✅ |

---

## 5. Mapping Features → Limites

### 5.1 Limites numériques (Quotas)

**Source** : Table `plans` + `DEFAULT_LIMITS` (fallback)

| Limite | Clé | free | growth | scale | enterprise | whitelabel |
|--------|-----|------|--------|-------|------------|------------|
| Max Membres | `maxMembers` | 20 | 100 | 250 | null (∞) | null (∞) |
| Max Admins | `maxAdmins` | 1 | 2 | 5 | 7 | 7 |
| Max Tags | `maxTags` | 10 | 50 | 200 | 700 | 700 |

### 5.2 Où sont définies les limites ?

| Source | Fichier | Pilotable SQL |
|--------|---------|---------------|
| Table `plans.max_members` | DB | ✅ OUI |
| Table `plans.max_admins` | DB | ✅ OUI |
| Table `plans.max_tags` | DB | ✅ OUI (vide actuellement) |
| `DEFAULT_LIMITS` | `server/lib/planLimits.ts:35-41` | ❌ NON |

### 5.3 Priorité de résolution des limites

```
1. community.contractAdminLimit    ← Override contractuel (Grand Compte)
2. community.maxAdminsDefault      ← Override communauté
3. community.maxMembersAllowed     ← Override communauté
4. plans.max_* (DB)                ← Limites du plan
5. DEFAULT_LIMITS (code)           ← Fallback
```

**Fonction** : `getEffectivePlan(communityId)` dans `server/lib/planLimits.ts:268-326`

### 5.4 Enforcement des limites

**Fichier** : `server/lib/usageLimitsGuards.ts`

| Fonction | Usage |
|----------|-------|
| `checkLimit(communityId, limitKey)` | Vérifie si limite atteinte |
| `requireWithinLimit(getCommunityId, limitKey)` | Middleware bloquant |
| `getCurrentUsage(communityId, limitKey)` | Compte l'usage actuel |

**Limites supportées** : `maxMembers`, `maxAdmins`, `maxTags`

---

## 6. Capacité de Pilotage par SQL

### 6.1 Tables manipulables

| Table | Opérations sûres | Clés primaires |
|-------|------------------|----------------|
| `plans` | UPDATE | `id` (varchar) |
| `communities` | UPDATE | `id` (varchar) |

### 6.2 Activer/Désactiver une capability par SQL

**Table** : `plans`  
**Colonne** : `capabilities` (JSONB)

```sql
-- Activer une capability pour un plan
UPDATE plans 
SET capabilities = jsonb_set(capabilities, '{dues}', 'true')
WHERE id = 'free';

-- Désactiver une capability pour un plan
UPDATE plans 
SET capabilities = jsonb_set(capabilities, '{exportData}', 'false')
WHERE id = 'growth';
```

**⚠️ ATTENTION** : Le format JSONB en DB utilise parfois des clés différentes :
- Code utilise `dues` → DB peut avoir `cotisations`
- Le code gère l'alias dans `hasCapability()` (ligne 421)

### 6.3 Modifier une limite par SQL

```sql
-- Modifier max_members pour un plan
UPDATE plans SET max_members = 150 WHERE id = 'growth';

-- Modifier max_admins pour un plan
UPDATE plans SET max_admins = 4 WHERE id = 'growth';
```

### 6.4 Override pour une communauté spécifique

```sql
-- Override limite membres pour une communauté
UPDATE communities 
SET max_members_allowed = 500 
WHERE id = '<community_id>';

-- Override limite admins (contrat Grand Compte)
UPDATE communities 
SET contract_admin_limit = 20 
WHERE id = '<community_id>';
```

### 6.5 Ce qui NE DOIT PAS être touché sans code

| Élément | Raison |
|---------|--------|
| `DEFAULT_LIMITS` | Fallback hardcodé, nécessite déploiement |
| `DEFAULT_CAPABILITIES` | Fallback hardcodé, nécessite déploiement |
| `KOOMY_PLANS` | Config frontend, nécessite déploiement |
| `PlanCapabilities` interface | Contrat TypeScript |

---

## 7. Résumé : Source de vérité par domaine

| Domaine | Source de vérité | Pilotable SQL |
|---------|------------------|---------------|
| **Features (capabilities)** | `plans.capabilities` (JSONB) | ✅ OUI |
| **Limites membres** | `plans.max_members` | ✅ OUI |
| **Limites admins** | `plans.max_admins` | ✅ OUI |
| **Limites tags** | `DEFAULT_LIMITS.maxTags` | ❌ NON (code) |
| **Override communauté** | `communities.max_*` | ✅ OUI |
| **Features métadata (UI)** | `plans.features` (array strings) | ✅ OUI |

---

## 8. Problèmes identifiés

### 8.1 Incohérence format capabilities

Le format JSONB en DB (ex: `{"features": {"cotisations": true}}`) diffère du format TypeScript `PlanCapabilities` (ex: `{dues: true}`).

**Impact** : Le code doit gérer des aliases (`cotisations` → `dues`).

**Recommandation** : Harmoniser le format DB avec le format TypeScript.

### 8.2 `max_tags` absent en DB

La colonne `max_tags` est vide pour tous les plans en DB. La valeur vient uniquement de `DEFAULT_LIMITS`.

**Impact** : Non pilotable par SQL actuellement.

**Recommandation** : Peupler `plans.max_tags` en DB.

### 8.3 Mismatch IDs plans (CORRIGÉ)

Les IDs `plus`/`pro` dans le code ont été corrigés vers `growth`/`scale` (fix P0 du 2026-01-29).

---

## 9. Instructions opérationnelles

### Pour activer/désactiver une feature :

1. **Si la feature existe en DB** (`plans.capabilities`) :
   - Modifier via SQL UPDATE sur `plans.capabilities`
   - Effet immédiat, pas de déploiement requis

2. **Si la feature n'existe qu'en code** (`DEFAULT_CAPABILITIES`) :
   - Modifier le code dans `server/lib/planLimits.ts`
   - Nécessite un déploiement

### Pour modifier une limite :

1. **Limite globale du plan** :
   - Modifier `plans.max_members` ou `plans.max_admins`
   - Effet immédiat

2. **Override pour une communauté** :
   - Modifier `communities.max_members_allowed` ou `communities.contract_admin_limit`
   - Effet immédiat

---

## 10. Fichiers de référence

| Fichier | Contenu |
|---------|---------|
| `shared/schema.ts:210-238` | Interface `PlanCapabilities` |
| `shared/plans.ts` | Config `KOOMY_PLANS` (frontend/seed) |
| `server/lib/planLimits.ts` | `DEFAULT_LIMITS`, `DEFAULT_CAPABILITIES`, fonctions de résolution |
| `server/lib/usageLimitsGuards.ts` | Middlewares d'enforcement |
| DB `plans` | Table source de vérité |
| DB `communities` | Overrides par communauté |
