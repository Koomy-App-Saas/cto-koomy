# RAPPORT ENFORCEMENT GAPS — GESTION DES ADMINS

**Date** : 25 janvier 2026  
**Statut** : Observation factuelle uniquement  
**Périmètre** : API, Middlewares, Guards, Routes, Plans, Jobs  

---

## 1. Règles Définies VS Règles Appliquées

### 1.1 Tableau Récapitulatif

| Règle | Définie | Enforced | Quand | Fichier |
|-------|---------|----------|-------|---------|
| maxAdmins par plan | OUI | **NON** | Jamais | `planLimits.ts:26-31` |
| Owner non supprimable | OUI | OUI | Request-time | `storage.ts:1028` |
| Création admin = OWNER only | OUI | OUI | Request-time | `routes.ts:4641` |
| Promotion admin conditionnée | PARTIEL | **NON** | - | - |
| Révocation admin | OUI | OUI | Request-time | `storage.ts:1028-1034` |

### 1.2 Détail : maxAdmins

**Définition** (`server/lib/planLimits.ts:26-31`) :
```typescript
const DEFAULT_LIMITS = {
  free: { maxMembers: 50, maxAdmins: 1, maxTags: 10 },
  plus: { maxMembers: 500, maxAdmins: 3, maxTags: 50 },
  pro: { maxMembers: 5000, maxAdmins: 10, maxTags: 200 },
  enterprise: { maxMembers: null, maxAdmins: null, maxTags: 700 },
  whitelabel: { maxMembers: null, maxAdmins: null, maxTags: 700 },
};
```

**État de l'enforcement** :

| Point de vérification | Statut |
|-----------------------|--------|
| `checkLimit("maxAdmins")` appelé sur POST admins | **NON** |
| `checkAdminQuota()` fonction | **N'EXISTE PAS** |
| Erreur 402 si quota dépassé | **NON** |
| Vérification async/cron | **NON** |

**Constat** : La règle `maxAdmins` est définie mais **jamais appliquée**.

### 1.3 Détail : Owner non supprimable

**Définition** (`server/storage.ts:80-86`) :
```typescript
export class OwnerAdminDeletionError extends Error {
  constructor() {
    super(`L'administrateur propriétaire de la communauté ne peut pas être supprimé.`);
    this.name = "OwnerAdminDeletionError";
  }
}
```

**Enforcement** (`server/storage.ts:1027-1030`) :
```typescript
if (membership?.isOwner) {
  throw new OwnerAdminDeletionError();
}
```

**Statut** : ENFORCED à request-time dans `deleteMembership()`.

### 1.4 Détail : Création admin = OWNER only

**Enforcement** (`server/routes.ts:4641-4652`) :
```typescript
if (!isOwner(callerMembership)) {
  return res.status(403).json({ 
    error: "Seul le propriétaire peut créer des administrateurs", 
    code: "OWNER_REQUIRED",
    traceId 
  });
}
```

**Statut** : ENFORCED à request-time via guard `requireOwner`.

---

## 2. Points d'Entrée Non Protégés

### 2.1 Endpoints de Création/Promotion Admin

| Endpoint | Guards | maxAdmins vérifié | Risque |
|----------|--------|-------------------|--------|
| `POST /api/communities/:id/admins` | `requireMembership`, `requireOwner` | **NON** | Création illimitée |
| `POST /api/admin/register-community` | Aucun guard quota | **NON** | 1er admin (owner) - OK |
| `POST /api/admin/join` | `requireFirebaseAuth` | **NON** | Bypass possible |
| `POST /api/admin/join-with-credentials` | Aucun guard quota | **NON** | Bypass possible |
| `POST /api/communities/:id/delegates` | Aucun guard spécifique | **NON** | Delegate neutralisé mais compté |
| `POST /api/platform/communities/:id/create-owner-admin` | `verifyPlatformAdmin` | **NON** | Platform only - acceptable |

### 2.2 Endpoint Principal : POST /api/communities/:id/admins

**Fichier** : `server/routes.ts:4586-4790`

**Guards appliqués** :
- `requireMembership("communityId")` ✓
- `requireOwner` ✓
- `requireFirebaseOnly` ✓

**Guards manquants** :
- `checkLimit("maxAdmins")` ❌
- `checkAdminQuota()` ❌

**Code** (lignes 4656-4777) :
```typescript
// Validate request body
const { email, firstName, lastName, adminRole, ... } = req.body;
// ... validations ...

// MANQUANT: Vérification quota admin ici

// Create the admin membership
const membership = await storage.createMembership({
  role: 'admin',
  ...
});
```

### 2.3 Risques de Bypass

| Scénario | Vecteur | Impact |
|----------|---------|--------|
| OWNER crée admins sans limite | POST /admins sans quota check | Quota plan ignoré |
| Admin rejoint via invitation | POST /admin/join | Pas de vérification quota |
| Delegate créé puis compté | POST /delegates | Inflate le compteur admin |
| Platform crée owner-admin | POST /create-owner-admin | Acceptable (admin platform) |

---

## 3. Rattachement aux Plans

### 3.1 Stockage de la Limite

| Élément | Localisation | Valeur |
|---------|--------------|--------|
| Définition par défaut | `planLimits.ts:26-31` | free:1, plus:3, pro:10, enterprise:null |
| Table plans (DB) | `plans.maxAdmins` | Nullable, hérité du schéma |
| Récupération runtime | `getEffectivePlan()` | Inclut `maxAdmins` |

### 3.2 Consultation lors des Actions Critiques

| Action | Limite consultée | Limite appliquée |
|--------|------------------|------------------|
| POST /admins (création) | **NON** | **NON** |
| POST /admin/join | **NON** | **NON** |
| PATCH plan (upgrade/downgrade) | **NON** pour admins | **NON** |
| enforceCommunityPlanLimits() | **NON** - membres seulement | **NON** |

### 3.3 Fonction `checkMemberQuota`

**Fichier** : `server/storage.ts:667-710`

```typescript
async checkMemberQuota(communityId: string): Promise<...> {
  // Vérifie maxMembers, pas maxAdmins
  const max = isGrandCompte 
    ? (community.contractMemberLimit ?? null)
    : plan.maxMembers;  // <-- maxMembers, pas maxAdmins
}
```

**Constat** : La fonction vérifie uniquement `maxMembers`. Aucune fonction `checkAdminQuota` n'existe.

### 3.4 Appel dans createMembership

**Fichier** : `server/storage.ts:820-825`

```typescript
async createMembership(insertMembership: InsertMembership): Promise<...> {
  // Check member quota before creating
  const quota = await this.checkMemberQuota(insertMembership.communityId);
  if (!quota.canAdd) {
    throw new MemberLimitReachedError(quota.current, quota.max!, quota.planName);
  }
  // ...
}
```

**Constat** : Le quota membres est vérifié mais :
- Ne filtre pas par rôle (compte tous les memberships)
- Ne vérifie pas le quota admin séparément

---

## 4. Suspension / Downgrade / Dépassement

### 4.1 Plan Change (Upgrade/Downgrade)

**Fichier** : `server/routes.ts:5000-5020`

```typescript
// Allow downgrades and same-plan changes (handled by storage with quota validation)
// Enforce plan limits after plan change (may freeze or unfreeze members)
const { enforceCommunityPlanLimits } = await import("./lib/subscriptionGuards");
const enforcement = await enforceCommunityPlanLimits(req.params.id);
```

**Constat** : `enforceCommunityPlanLimits()` ne gère que les membres, pas les admins.

### 4.2 Fonction enforceCommunityPlanLimits

**Fichier** : `server/lib/subscriptionGuards.ts:243-320`

```typescript
export async function enforceCommunityPlanLimits(communityId: string): Promise<EnforcementResult> {
  // ...
  const maxMembers = limits.maxMembers;  // <-- membres seulement
  // ...
  const members = await db.select()
    .from(userCommunityMemberships)
    .where(
      and(
        eq(userCommunityMemberships.communityId, communityId),
        eq(userCommunityMemberships.role, "member")  // <-- exclut admins
      )
    );
}
```

**Constat** : La fonction freeze/unfreeze uniquement les `role="member"`, jamais les admins.

### 4.3 Contrôle Post-Facto (Cron/Jobs)

| Job | Fichier | Vérifie admins |
|-----|---------|----------------|
| `runSaasStatusTransitions` | `saasStatusJob.ts` | **NON** - statuts paiement uniquement |
| `runPurgeJob` | `purgeService.ts` | **NON** - purge données après résiliation |
| Trial expiry check | `subscriptionGuards.ts:41` | **NON** - membres seulement |

**Constat** : Aucun job/cron ne vérifie le dépassement de quota admin.

### 4.4 Que Devient un Admin en Trop ?

**Situation** : Community sur plan FREE avec 3 admins (limite = 1).

| Mécanisme | Existe | Comportement |
|-----------|--------|--------------|
| Freeze automatique | **NON** | Admins restent actifs |
| Alerte admin | **NON** | Pas de notification |
| Blocage création | **NON** | Création continue |
| Downgrade bloqué | **NON** | Downgrade autorisé sans check admin |

**Résultat** : Les admins en excès restent pleinement fonctionnels.

---

## 5. Dette & Risques Produit

### 5.1 Incohérences

| ID | Description | Impact |
|----|-------------|--------|
| GAP-ADMIN-01 | `maxAdmins` défini mais jamais enforced | Monétisation impossible |
| GAP-ADMIN-02 | `getAdminCount()` compte les delegates neutralisés | Métriques faussées |
| GAP-ADMIN-03 | `checkMemberQuota` ne filtre pas par rôle | Peut compter admins comme membres |
| GAP-ADMIN-04 | `enforceCommunityPlanLimits` ignore admins | Pas de freeze admin possible |
| GAP-ADMIN-05 | Downgrade plan sans check admin quota | Dépassement silencieux |

### 5.2 Logiques Dupliquées

| Logique | Fichiers | Divergence |
|---------|----------|------------|
| `isOwner()` | `routes.ts:141`, `guards.ts:60` | Légère (isOwner vs isOwnerRole) |
| `isBackofficeAdmin()` | `routes.ts:150` | vs `isAdminRole()` dans `guards.ts:66` |
| Comptage admins | `usageLimitsGuards.ts:49` | Inclut delegates neutralisés |

### 5.3 Règles Implicites Non Documentées

| Règle | Comportement actuel | Documentée |
|-------|---------------------|------------|
| 1 admin = 1 club | Non enforced techniquement | OUI (replit.md) |
| Delegate = admin pour comptage | Inclus dans getAdminCount | NON |
| Owner compte comme admin | Compté séparément (isOwner flag) | NON |
| Platform admin bypass | Peut créer owner-admin sans limite | NON |

### 5.4 Comportements Dangereux pour le Business

| Risque | Probabilité | Impact Business |
|--------|-------------|-----------------|
| Plan FREE avec admins illimités | HAUTE | Perte de revenu upgrade |
| Downgrade sans réduction admins | HAUTE | Dépassement permanent |
| Pas de notification quota | HAUTE | Aucune incitation upgrade |
| Delegate compté mais neutralisé | MOYENNE | Confusion utilisateur |

---

## 6. Synthèse Exécutive

### Points Bloquants pour Monétisation

1. **maxAdmins non enforced** — Le différenciateur tarifaire n°1 (FREE=1, PLUS=3, PRO=10) n'est pas appliqué
2. **Pas de blocage à la création** — Un OWNER peut créer des admins sans limite
3. **Pas de contrôle post-facto** — Aucun job ne détecte les dépassements
4. **Pas de freeze admin** — Seuls les membres peuvent être suspendus par quota

### Actions Techniques Requises (Observation)

Pour enforcement complet, il faudrait :
1. Appeler `checkLimit("maxAdmins")` dans POST `/api/communities/:id/admins`
2. Créer fonction `checkAdminQuota()` séparée de `checkMemberQuota()`
3. Ajouter enforcementPlanLimits pour admins (ou refuser création)
4. Exclure delegates de `getAdminCount()` (cohérence neutralisation)
5. Vérifier quota admin lors de POST `/admin/join`
6. Ajouter job périodique pour détecter dépassements post-downgrade

### Comparaison Members vs Admins

| Aspect | Members | Admins |
|--------|---------|--------|
| Quota défini | OUI | OUI |
| Quota enforced à création | OUI | **NON** |
| Erreur 402 si quota dépassé | OUI | **NON** |
| Freeze/suspend si quota dépassé | OUI | **NON** |
| Job de vérification périodique | OUI (trial) | **NON** |

---

## 7. Annexes

### A. Fichiers Analysés

| Fichier | Raison |
|---------|--------|
| `server/lib/planLimits.ts` | Définition maxAdmins |
| `server/lib/usageLimitsGuards.ts` | getAdminCount, checkLimit |
| `server/lib/subscriptionGuards.ts` | enforceCommunityPlanLimits |
| `server/storage.ts` | checkMemberQuota, createMembership |
| `server/routes.ts` | Endpoints création admin |
| `server/services/saasStatusJob.ts` | Jobs périodiques |
| `server/middlewares/guards.ts` | Guards admin |

### B. Endpoints Admin Identifiés

| Endpoint | Méthode | Purpose |
|----------|---------|---------|
| `/api/communities/:id/admins` | POST | Création admin |
| `/api/admin/login` | POST | Login admin |
| `/api/admin/join` | POST | Join via Firebase |
| `/api/admin/join-with-credentials` | POST | Join legacy (WL) |
| `/api/admin/register-community` | POST | Création community + owner |
| `/api/platform/communities/:id/create-owner-admin` | POST | Platform crée owner |
| `/api/memberships/:id` | DELETE | Suppression (protège owner) |

### C. Fonctions Clés

| Fonction | Fichier | Rôle |
|----------|---------|------|
| `getAdminCount()` | usageLimitsGuards.ts:49 | Compte admins + delegates |
| `checkLimit()` | usageLimitsGuards.ts:110 | Vérifie limite (non appelé pour admins) |
| `checkMemberQuota()` | storage.ts:667 | Vérifie quota membres uniquement |
| `enforceCommunityPlanLimits()` | subscriptionGuards.ts:243 | Freeze membres (pas admins) |
| `isWithinAdminLimit()` | planLimits.ts:221 | Helper non utilisé |

---

**Fin du rapport — Observation uniquement, aucune recommandation produit**
