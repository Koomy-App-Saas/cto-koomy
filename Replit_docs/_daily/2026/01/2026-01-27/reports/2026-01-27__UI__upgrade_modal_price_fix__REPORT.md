# UI — Upgrade Required Modal + Price Input Fix

## Resume

1. Modal "Fonctionnalité Premium" affichée lors d'erreurs 403 avec `upgradeRequired: true`
2. Champ prix corrigé pour saisie clavier fluide

---

## 1) Upgrade Required Modal

### Fonctionnement
- Détection automatique des erreurs API avec `upgradeRequired: true`
- Modal globale via React Context (disponible dans toute l'app)
- Affiche le plan actuel et CTA vers `/admin/billing`

### Fichiers créés
| Fichier | Description |
|---------|-------------|
| `client/src/components/UpgradeRequiredDialog.tsx` | Composant modal |
| `client/src/contexts/UpgradeRequiredContext.tsx` | Context + helper `isUpgradeRequiredError` |

### Fichiers modifiés
| Fichier | Changement |
|---------|------------|
| `client/src/App.tsx` | Ajout `UpgradeRequiredProvider` |
| `client/src/pages/admin/Events.tsx` | Hook + handling erreur mutation |

### Usage dans d'autres composants
```typescript
import { useUpgradeRequired, isUpgradeRequiredError } from "@/contexts/UpgradeRequiredContext";

const { showUpgradeRequired } = useUpgradeRequired();

// Dans onError de mutation:
const upgradeData = isUpgradeRequiredError(error);
if (upgradeData) {
  showUpgradeRequired(upgradeData);
  return;
}
```

---

## 2) Fix Champ Prix

### Problème
`type="number"` forçait l'usage des flèches stepper, bloquait la saisie libre.

### Solution
- Changé en `type="text"` + `inputMode="decimal"`
- Filtrage regex pour n'accepter que chiffres, point, virgule
- Conversion virgule → point automatique
- Formatage à 2 décimales sur `onBlur`

### Fichiers modifiés
| Fichier | Changement |
|---------|------------|
| `client/src/pages/admin/Events.tsx` | 2 inputs prix (création + édition) |

---

## Tests manuels

| Test | Résultat |
|------|----------|
| Compte Free → événement payant → modal apparaît | À tester |
| CTA "Voir les offres" → navigate /admin/billing | À tester |
| Champ prix → taper "25" au clavier | OK |
| Champ prix → effacer et retaper | OK |
| Molette souris ne change pas le prix | OK (type=text) |
| Compte Payant → événement payant fonctionne | À tester |

---

## Requêtes SQL de vérification (OBLIGATOIRE)

```sql
-- Vérifier plan Free existe
SELECT id, code, name FROM plans WHERE id = 'free' OR code ILIKE '%FREE%';

-- Vérifier communauté et son plan
SELECT id, name, plan_id FROM communities WHERE id = '83f058b3-4b77-4cf3-91b4-2e0918f92fc4';

-- Vérifier tables subscriptions
SELECT table_name
FROM information_schema.tables
WHERE table_schema='public' AND table_name IN ('subscriptions','community_subscriptions');
```

---

FIN
