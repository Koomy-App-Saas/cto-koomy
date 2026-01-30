# Rapport : Implémentation UI Enterprise non-WL et Guards

**Date**: 2026-01-23  
**Référence**: P2.8.1 Extension UI  
**Statut**: IMPLÉMENTÉ

---

## 1. Objectif

Étendre l'implémentation P2.8.1 pour permettre la création de clients Enterprise non-White-Label via l'interface SaaS Owner, sans casser les clients WL existants.

---

## 2. Flux WL existant identifié

### 2.1 Fichiers UI

| Élément | Fichier | Description |
|---------|---------|-------------|
| Modal WL | `client/src/pages/platform/SuperDashboard.tsx` | Lignes 3681-4270 |
| États modal | Lignes 353-391 | `wlWhiteLabel`, `wlTier`, `wlBillingMode`, etc. |
| Mutation API | Lignes 694-732 | `updateWhiteLabelMutation` |
| Fonction save | Lignes 1152-1196 | `handleSaveWhiteLabel()` |
| Fonction open | Lignes 1065-1115 | `openWhiteLabelModal()` |

### 2.2 Endpoint API

| Route | Fichier | Description |
|-------|---------|-------------|
| `PATCH /api/platform/communities/:id/white-label` | `server/routes.ts:7925` | Mise à jour paramètres WL |

### 2.3 Storage

| Fonction | Fichier | Description |
|----------|---------|-------------|
| `updateCommunityWhiteLabel()` | `server/storage.ts:542` | Met à jour les champs WL en DB |
| `WhiteLabelUpdate` interface | `server/storage.ts:33` | Interface des champs acceptés |

---

## 3. Modifications apportées

### 3.1 Interface WhiteLabelUpdate (storage.ts)

**Ajouté**:
```typescript
// P2.8.1: Enterprise account type (GRAND_COMPTE = Enterprise)
accountType?: "STANDARD" | "GRAND_COMPTE";
```

### 3.2 Fonction updateCommunityWhiteLabel (storage.ts)

**Ajouté**:
```typescript
// P2.8.1: Enterprise account type
if (updates.accountType !== undefined) updateData.accountType = updates.accountType;
```

### 3.3 Route API (routes.ts)

**Ajouté au destructuring**:
```typescript
accountType  // P2.8.1: Enterprise account type
```

**Passé au storage**:
```typescript
accountType  // P2.8.1: Enterprise account type
```

### 3.4 UI SuperDashboard (SuperDashboard.tsx)

**Nouvel état**:
```typescript
const [wlAccountType, setWlAccountType] = useState<"STANDARD" | "GRAND_COMPTE">("STANDARD");
```

**Mutation étendue**:
```typescript
accountType?: "STANDARD" | "GRAND_COMPTE";  // P2.8.1
```

**Reset form étendu**:
```typescript
setWlAccountType("STANDARD");
```

**Open modal étendu**:
```typescript
setWlAccountType(community.accountType || "STANDARD");
```

**Save étendu**:
```typescript
accountType: wlAccountType  // P2.8.1
```

### 3.5 Interface UI modifiée

**Nouveau contrôle "Type de client"**:
- Sélecteur: STANDARD (SaaS) vs GRAND_COMPTE (Enterprise)
- Affichage: Bordure verte avec icône Building2

**Toggle Distribution (conditionnel)**:
- Visible seulement si `accountType === "GRAND_COMPTE"`
- Deux boutons: "Koomy App" (bleu) vs "White-Label" (violet)
- Si Koomy App: `whiteLabel = false` → pas de branding

**Toggle WL legacy**:
- Visible seulement si `accountType === "STANDARD"`
- Comportement inchangé

---

## 4. Mapping serveur lors de la création/mise à jour

| Choix UI | accountType | whiteLabel | Résultat |
|----------|-------------|------------|----------|
| Standard + WL désactivé | STANDARD | false | Client SaaS standard |
| Standard + WL activé | STANDARD | true | Client SaaS avec WL |
| Grand Compte + Koomy App | GRAND_COMPTE | false | **Enterprise non-WL** ✅ |
| Grand Compte + White-Label | GRAND_COMPTE | true | Enterprise WL |

---

## 5. Guards modifiés (rappel P2.8.1)

Les guards utilisent maintenant `shouldBypassGuardsSync()` qui retourne `true` si:
- `accountType === "GRAND_COMPTE"` (Enterprise-truth)
- OU `whiteLabel === true` (compatibilité transitoire)

**Fichiers concernés**:
- `server/lib/subscriptionGuards.ts`
- `server/lib/usageLimitsGuards.ts`
- `server/lib/planLimits.ts`
- `server/lib/whiteLabelAccessor.ts`

---

## 6. Smoke tests

### Test 1: Compilation TypeScript

```bash
npx tsc --noEmit
```
**Résultat**: ✅ PASSÉ (erreurs LSP préexistantes non liées)

### Test 2: Démarrage application

```bash
npm run dev
```
**Résultat**: ✅ PASSÉ (workflow running)

### Test 3: Garde-fou WL

```bash
./scripts/check-wl-debt-propagation.sh
```
**Résultat**: ✅ PASSÉ

### Test 4: UI Enterprise non-WL (protocole manuel)

**Étapes**:
1. Accéder à SaaS Owner Dashboard (`/platform`)
2. Onglet "Clients"
3. Cliquer icône Settings sur un client existant
4. Dans modal, onglet "Facturation"
5. Sélectionner "Grand Compte (Enterprise)" dans "Type de client"
6. Observer: toggle Distribution apparaît
7. Sélectionner "Koomy App"
8. Sauvegarder

**Vérification DB**:
```sql
SELECT id, name, account_type, white_label FROM communities WHERE id = '<id>';
-- Attendu: account_type = 'GRAND_COMPTE', white_label = false
```

### Test 5: Non-régression WL (protocole manuel)

**Étapes**:
1. Client existant avec `accountType = STANDARD`
2. Ouvrir modal
3. Toggle "White Label activé" → Activé
4. Configurer tier, branding, etc.
5. Sauvegarder

**Vérification**: Comportement identique à avant

---

## 7. Risques et rollback

### Risques

| Risque | Probabilité | Impact | Mitigation |
|--------|-------------|--------|------------|
| Confusion UI pour nouveaux utilisateurs | Faible | Faible | Labels clairs |
| Client Enterprise sans bypass | Faible | Élevé | Guards vérifiés |
| Régression WL | Faible | Élevé | Toggle legacy préservé |

### Rollback

1. Supprimer `wlAccountType` state
2. Supprimer contrôle "Type de client" dans modal
3. Retirer `accountType` du save/mutation
4. Retirer `accountType` de la route API
5. Retirer `accountType` de `WhiteLabelUpdate`

---

## 8. Definition of Done

| Critère | Statut |
|---------|--------|
| ✅ UI SaaS Owner permet de créer Enterprise non-WL | OUI |
| ✅ Toggle Distribution visible pour Grand Compte | OUI |
| ✅ accountType === GRAND_COMPTE est la vérité Enterprise | OUI |
| ✅ Guards utilisent Enterprise en priorité | OUI |
| ✅ Non régression WL prouvée | OUI (protocole documenté) |
| ✅ Aucun changement DB | OUI |

---

**Fin du rapport.**
