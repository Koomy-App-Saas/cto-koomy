# Cartographie factuelle de la dette White-Label

**Date**: 2026-01-23  
**Phase**: 1 (A + D)  
**Méthode**: Recherche exhaustive repo (`\.whiteLabel|isWhiteLabel|white_label`)

---

## 1. Résumé quantitatif

| Zone | Fichiers | Occurrences | Super-flag zones |
|------|----------|-------------|------------------|
| server/ | 14 | 85+ | 4 |
| client/src/ | 15 | 70+ | 3 |
| shared/ | 1 | 7 | 1 |
| **TOTAL** | **30** | **162+** | **8** |

---

## 2. Schéma DB (shared/schema.ts)

| Colonne | Ligne | Type | Usage |
|---------|-------|------|-------|
| `accounts.is_white_label` | 239 | boolean | Flag compte (dette) |
| `communities.white_label` | 307 | boolean | Flag community (SUPER-FLAG) |
| `communities.white_label_tier` | 308 | enum | Niveau contrat WL |
| `communities.white_label_included_members` | 337 | integer | Quota WL |
| `communities.white_label_max_members_soft_limit` | 338 | integer | Soft limit WL |
| `communities.white_label_additional_fee_per_member_cents` | 339 | integer | Tarif additionnel |
| `white_label_tier_enum` | 43 | pgEnum | basic/standard/premium |

**Risque global schéma**: ÉLEVÉ (source de vérité de la dette)

---

## 3. Backend - Fichiers critiques

### 3.1 server/lib/authModeResolver.ts (SUPER-FLAG ZONE)

| Ligne | Pattern | Type usage | Risque |
|-------|---------|------------|--------|
| 12-13 | Commentaire invariant | Documentation | - |
| 39 | `isWhiteLabel: boolean` | Type | Faible |
| 98 | `whiteLabel: communities.whiteLabel` | Query select | Moyen |
| 118 | `whiteLabel: community.whiteLabel` | Read | Moyen |
| 143-188 | Logique auth mode | **BYPASS AUTH** | ÉLEVÉ |
| 235 | `result.isWhiteLabel` | Return | Moyen |
| 277-303 | `whiteLabel` checks | **MULTI-DIMENSION** | ÉLEVÉ |

**Type**: Auth + Bypass  
**Super-flag**: OUI (détermine Firebase vs Legacy)

### 3.2 server/lib/subscriptionGuards.ts (SUPER-FLAG ZONE)

| Ligne | Pattern | Type usage | Risque |
|-------|---------|------------|--------|
| 56 | `if (community.whiteLabel)` | **BYPASS BILLING** | ÉLEVÉ |
| 121 | `if (community.whiteLabel)` | **BYPASS SUBSCRIPTION** | ÉLEVÉ |
| 245 | `if (limits.isWhiteLabel)` | **BYPASS LIMITS** | ÉLEVÉ |
| 418 | `if (community.whiteLabel)` | **BYPASS GUARD** | ÉLEVÉ |

**Type**: Billing + Limits + Bypass  
**Super-flag**: OUI (bypass total subscription)

### 3.3 server/lib/usageLimitsGuards.ts (SUPER-FLAG ZONE)

| Ligne | Pattern | Type usage | Risque |
|-------|---------|------------|--------|
| 106 | `if (effectivePlan.isWhiteLabel)` | **BYPASS MEMBERS LIMIT** | ÉLEVÉ |
| 136 | `if (effectivePlan.isWhiteLabel)` | **BYPASS ADMINS LIMIT** | ÉLEVÉ |
| 155 | `if (effectivePlan.isWhiteLabel)` | **BYPASS CAPABILITIES** | ÉLEVÉ |

**Type**: Limits + Bypass  
**Super-flag**: OUI (bypass total limits)

### 3.4 server/lib/planLimits.ts

| Ligne | Pattern | Type usage | Risque |
|-------|---------|------------|--------|
| 15 | `isWhiteLabel: boolean` | Type | Faible |
| 162 | `isWhiteLabel: boolean` | Type | Faible |
| 169 | `whiteLabel: communities.whiteLabel` | Query select | Moyen |
| 196 | `isWhiteLabel: community.whiteLabel` | Return | Moyen |
| 240, 269 | idem | Return | Moyen |

**Type**: Data propagation  
**Super-flag**: NON (propage l'info)

### 3.5 server/lib/effectiveStateService.ts

| Ligne | Pattern | Type usage | Risque |
|-------|---------|------------|--------|
| 35 | `is_white_label: boolean` | Type | Faible |
| 58-145 | Multiple `isWhiteLabel` | **BYPASS CAPABILITIES** | ÉLEVÉ |

**Type**: Capabilities + State  
**Super-flag**: NON (consomme l'info)

### 3.6 server/lib/resolverGuard.ts

| Ligne | Pattern | Type usage | Risque |
|-------|---------|------------|--------|
| 39 | `whiteLabel: communities.whiteLabel` | Query | Moyen |
| 55 | `if (community.whiteLabel === true)` | Check | Moyen |

**Type**: Guard  
**Super-flag**: NON

### 3.7 server/routes.ts (SUPER-FLAG ZONE)

| Ligne | Pattern | Type usage | Risque |
|-------|---------|------------|--------|
| 572 | `if (community.whiteLabel)` | Billing bypass | ÉLEVÉ |
| 1549-1625 | WL subdomain detection | Routing | Moyen |
| 2338, 2890, 3042 | `eq(c.whiteLabel, false)` | Filter standard | Moyen |
| 2352, 2904, 3056 | `if (community.whiteLabel)` | **BYPASS** | ÉLEVÉ |
| 3927-3943 | WL config endpoint | Config | Moyen |
| 4361 | Filter public communities | Filter | Faible |
| 7105, 7224, 8153 | `if (!community.whiteLabel)` | Guard | Moyen |
| 11435, 11493 | Distribution logic | Distribution | Moyen |

**Type**: Multi-dimension (routing, bypass, filter, config)  
**Super-flag**: OUI (routes critiques)

### 3.8 server/services/mailer/branding.ts

| Ligne | Pattern | Type usage | Risque |
|-------|---------|------------|--------|
| 13 | `isWhiteLabel: boolean` | Type | Faible |
| 44 | `isWhiteLabel: false` | Default | Faible |
| 129 | `community.whiteLabel === true` | Check | Faible |
| 134-176 | WL branding logic | **BRANDING** | Faible |

**Type**: Branding (usage légitime WL)  
**Super-flag**: NON

### 3.9 server/services/mailer/sendBrandedEmail.ts

| Lignes | Pattern | Type usage | Risque |
|--------|---------|------------|--------|
| 60-600 (20+ occurrences) | `isWhiteLabel: branding.isWhiteLabel` | Email branding | Faible |

**Type**: Branding (usage légitime WL)  
**Super-flag**: NON

### 3.10 server/middlewares/enforceTenantAuth.ts

| Ligne | Pattern | Type usage | Risque |
|-------|---------|------------|--------|
| 64-74 | `isWhiteLabel` dans error | Auth error context | Moyen |
| 140-143 | `if (authModeResult.isWhiteLabel)` | Auth mode | Moyen |

**Type**: Auth  
**Super-flag**: NON

### 3.11 server/middlewares/enforceTenantContractAuth.ts

| Ligne | Pattern | Type usage | Risque |
|-------|---------|------------|--------|
| 117 | `isWhiteLabel: authMode.isWhiteLabel` | Context | Faible |

**Type**: Auth context  
**Super-flag**: NON

### 3.12 server/middlewares/attachAuthContext.ts

| Ligne | Pattern | Type usage | Risque |
|-------|---------|------------|--------|
| 127-141 | `isWhiteLabelAccount` check | Auth context | Moyen |

**Type**: Auth  
**Super-flag**: NON

---

## 4. Frontend - Fichiers critiques

### 4.1 client/src/contexts/WhiteLabelContext.tsx (SUPER-FLAG ZONE)

| Ligne | Pattern | Type usage | Risque |
|-------|---------|------------|--------|
| 41-270 | Tout le contexte | **PROVIDER CENTRAL** | ÉLEVÉ |

**Type**: Context provider  
**Super-flag**: OUI (source vérité frontend)

### 4.2 client/src/App.tsx

| Ligne | Pattern | Type usage | Risque |
|-------|---------|------------|--------|
| 87-234 | `isWhiteLabel` routing | **ROUTING** | ÉLEVÉ |

**Type**: Routing  
**Super-flag**: NON (consomme le context)

### 4.3 client/src/components/MobileAdminLayout.tsx

| Ligne | Pattern | Type usage | Risque |
|-------|---------|------------|--------|
| 123-364 | WL styling + display | **BRANDING** | Faible |

**Type**: Branding (usage légitime)  
**Super-flag**: NON

### 4.4 client/src/components/layouts/MobileLayout.tsx

| Ligne | Pattern | Type usage | Risque |
|-------|---------|------------|--------|
| 19-114 | WL styling + display | **BRANDING** | Faible |

**Type**: Branding (usage légitime)  
**Super-flag**: NON

### 4.5 client/src/pages/platform/SuperDashboard.tsx (SUPER-FLAG ZONE)

| Ligne | Pattern | Type usage | Risque |
|-------|---------|------------|--------|
| 1091 | `if (community.whiteLabel)` | Filter | Moyen |
| 1584-1810 | WL revenue/metrics | **UI WORDING** | Moyen |
| 2233-2281 | WL badges/buttons | **UI WORDING** | Moyen |
| 2469-2479 | "WHITE LABEL" label | **UI WORDING** | Moyen |
| 3599-3682 | WL modal | Config | Moyen |

**Type**: UI wording (dette UX)  
**Super-flag**: OUI (nomenclature "WL client")

### 4.6 client/src/pages/admin/Settings.tsx

| Ligne | Pattern | Type usage | Risque |
|-------|---------|------------|--------|
| Multiple | WL settings display | Config | Faible |

**Type**: Config display  
**Super-flag**: NON

### 4.7 client/src/pages/admin/Billing.tsx

| Ligne | Pattern | Type usage | Risque |
|-------|---------|------------|--------|
| Multiple | WL billing display | Billing | Faible |

**Type**: Billing display  
**Super-flag**: NON

---

## 5. Résumé Super-Flag Zones

| Zone | Fichier | Dimensions affectées | Priorité encapsulation |
|------|---------|---------------------|------------------------|
| SF-1 | `server/lib/authModeResolver.ts` | Auth | P1 |
| SF-2 | `server/lib/subscriptionGuards.ts` | Billing, Limits | P1 |
| SF-3 | `server/lib/usageLimitsGuards.ts` | Limits | P1 |
| SF-4 | `server/routes.ts` | Routing, Bypass, Filter | P2 |
| SF-5 | `client/src/contexts/WhiteLabelContext.tsx` | Frontend state | P2 |
| SF-6 | `client/src/pages/platform/SuperDashboard.tsx` | UI wording | P3 |

---

## 6. Classification par type d'usage

| Type | Fichiers | Occurrences | Action requise |
|------|----------|-------------|----------------|
| **Bypass** | 4 | 15+ | Encapsuler dans module central |
| **Auth** | 4 | 20+ | Encapsuler via authModeResolver |
| **Billing** | 2 | 5+ | Encapsuler via subscriptionGuards |
| **Limits** | 3 | 10+ | Encapsuler via planLimits |
| **Branding** | 4 | 40+ | Usage légitime, documenter |
| **UI wording** | 3 | 15+ | Phase D (abstraction sémantique) |
| **Config** | 3 | 10+ | Usage légitime, documenter |
| **Filter** | 2 | 5+ | Encapsuler si possible |

---

## 7. Zones à ne PAS modifier (usage légitime)

Les fichiers suivants utilisent WL pour son usage **légitime** (distribution/branding) :

- `server/services/mailer/branding.ts` — branding emails
- `server/services/mailer/sendBrandedEmail.ts` — emails brandés
- `client/src/components/MobileAdminLayout.tsx` — styling WL
- `client/src/components/layouts/MobileLayout.tsx` — styling WL
- `client/src/pages/mobile/*.tsx` — UX WL membres

Ces fichiers ne propagent pas la confusion "WL = type client".

---

**Fin de la cartographie.**
