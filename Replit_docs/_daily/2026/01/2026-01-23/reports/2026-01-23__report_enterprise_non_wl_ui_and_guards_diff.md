# Rapport : Diff technique UI Enterprise non-WL

**Date**: 2026-01-23  
**Référence**: P2.8.1 Extension UI

---

## 1. Fichiers modifiés

| Fichier | Ajouts | Modifications | Type |
|---------|--------|---------------|------|
| `server/storage.ts` | +3 lignes | 0 | Interface + storage |
| `server/routes.ts` | +2 lignes | 0 | API route |
| `client/src/pages/platform/SuperDashboard.tsx` | +55 lignes | 5 fonctions | UI modal |

**Total**: 3 fichiers, ~60 lignes

---

## 2. Détail par fichier

### 2.1 server/storage.ts

**Interface WhiteLabelUpdate (+1 ligne)**:
```typescript
// L62
accountType?: "STANDARD" | "GRAND_COMPTE";
```

**Fonction updateCommunityWhiteLabel (+2 lignes)**:
```typescript
// L573-574
if (updates.accountType !== undefined) updateData.accountType = updates.accountType;
```

### 2.2 server/routes.ts

**Destructuring body (+1 ligne)**:
```typescript
// L7956
accountType  // P2.8.1: Enterprise account type
```

**Appel storage (+1 ligne)**:
```typescript
// L7986
accountType
```

### 2.3 client/src/pages/platform/SuperDashboard.tsx

**Nouvel état (+1 ligne)**:
```typescript
// L360
const [wlAccountType, setWlAccountType] = useState<"STANDARD" | "GRAND_COMPTE">("STANDARD");
```

**Type mutation (+1 ligne)**:
```typescript
// L714
accountType?: "STANDARD" | "GRAND_COMPTE";
```

**Reset form (+1 ligne)**:
```typescript
// L1037
setWlAccountType("STANDARD");
```

**Open modal (+1 ligne)**:
```typescript
// L1068
setWlAccountType(community.accountType || "STANDARD");
```

**Save (+1 ligne)**:
```typescript
// L1194
accountType: wlAccountType
```

**UI modal (+50 lignes)**:
```tsx
// L3712-3791
{/* P2.8.1: Account Type Selection */}
<div className="...border-emerald-200...">
  <Select value={wlAccountType} onValueChange={...}>
    <SelectItem value="STANDARD">Standard (SaaS)</SelectItem>
    <SelectItem value="GRAND_COMPTE">Grand Compte (Enterprise)</SelectItem>
  </Select>
</div>

{/* Distribution toggle - Grand Compte only */}
{wlAccountType === "GRAND_COMPTE" && (
  <div className="...border-purple-200...">
    <Button onClick={() => setWlWhiteLabel(false)}>Koomy App</Button>
    <Button onClick={() => setWlWhiteLabel(true)}>White-Label</Button>
  </div>
)}

{/* Legacy WL toggle - Standard only */}
{wlAccountType === "STANDARD" && (
  <div>
    <Button onClick={() => setWlWhiteLabel(!wlWhiteLabel)}>
      {wlWhiteLabel ? "Activé" : "Désactivé"}
    </Button>
  </div>
)}
```

---

## 3. Rollback minimal

```bash
# Annuler toutes les modifications
git checkout HEAD~1 -- \
  server/storage.ts \
  server/routes.ts \
  client/src/pages/platform/SuperDashboard.tsx
```

**Impact rollback**:
- UI perd le sélecteur "Type de client"
- API perd la capacité de modifier accountType via WL endpoint
- Clients Enterprise non-WL ne peuvent plus être créés via UI

---

## 4. Tests de validation

```bash
# Compilation
npx tsc --noEmit

# Garde-fou WL
./scripts/check-wl-debt-propagation.sh

# Démarrage
npm run dev
```

---

**Fin du rapport diff.**
