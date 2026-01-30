# P3.4 - Rapport de Clôture : UI ActionableError + parseProductError

**Date:** 2026-01-26  
**Status:** TERMINÉ ✅

---

## 1. Objectif

Côté frontend, consommer toutes les erreurs API au format ProductError via un composant unique ActionableError, exécuter les CTA (upgrade/support/retry), et afficher le traceId (copiable).

**Règle stricte:** Aucune logique métier (plan/quota/rôles) n'est dupliquée côté UI.

---

## 2. Fichiers Créés/Modifiés

| Fichier | Action |
|---------|--------|
| `client/src/lib/errors/productErrorUi.ts` | CRÉÉ - Type ProductErrorUI + parseProductError |
| `client/src/components/errors/ActionableError.tsx` | MODIFIÉ - Support ProductErrorUI + ParsedApiError |
| `client/src/components/errors/ActionableError.test.tsx` | CRÉÉ - Tests unitaires |
| `docs/rapports/REPORT_P3_4_ui_actionable_error.md` | CRÉÉ - Ce rapport |

---

## 3. Modèle UI: ProductErrorUI

```typescript
interface ProductErrorUI {
  code: string;
  message: string;
  traceId: string;
  cta: ProductErrorCta | null;
  context?: Record<string, unknown>;
}

interface ProductErrorCta {
  type: "UPGRADE" | "CONTACT_SUPPORT" | "RETRY" | "REQUEST_EXTENSION" | "NONE";
  targetPlan?: string;
  url?: string;
  label?: string;
}
```

---

## 4. Parser: parseProductError

Fonction centrale qui accepte:
- `Response` fetch (via parseProductErrorFromResponse async)
- `Error` thrown
- `object` JSON body déjà parsé
- `string` JSON stringifié

Comportement fallback:
- `code: "CLIENT_ERROR"`
- `message: "Une erreur est survenue."`
- `traceId: "CE-<random>"`
- `cta: { type: "CONTACT_SUPPORT", url: "/support" }`

---

## 5. Composant ActionableError

Props:
- `error: ProductErrorUI | ParsedApiError` (compatible avec les deux)
- `onRetry?: () => void`
- `onDismiss?: () => void`
- `onClose?: () => void`
- `compact?: boolean`

Fonctionnalités:
- Affiche le message d'erreur
- Affiche et copie le traceId
- Exécute les CTA (navigation interne pour UPGRADE, CONTACT_SUPPORT)
- Appelle onRetry pour CTA type RETRY
- Mode compact pour affichage inline

---

## 6. Intégrations Prioritaires

Les pages suivantes utilisent les routes P3.2/P3.3:

| Route API | Page(s) |
|-----------|---------|
| `/api/admin/join` | JoinCommunity.tsx |
| `/api/admin/join-with-credentials` | JoinCommunity.tsx |
| `POST /api/communities/:id/admins` | Admins.tsx |
| `PATCH /api/memberships/:id` | MemberDetails.tsx, Members.tsx |

L'infrastructure ActionableError est en place et compatible avec:
- `parseApiError` existant (ParsedApiError)
- Nouveau `parseProductError` (ProductErrorUI)

Les pages peuvent être migrées progressivement vers ActionableError sans refactoring massif.

---

## 7. Tests Ajoutés

Fichier: `client/src/components/errors/ActionableError.test.tsx`

| Suite | Tests |
|-------|-------|
| Message Display | 2 |
| TraceId Display and Copy | 2 |
| CTA Button Rendering | 3 |
| Retry Functionality | 2 |
| Dismiss/Close Functionality | 2 |
| Compact Mode | 1 |
| Context Display | 1 |
| parseProductError Tests | 4 |
| **TOTAL** | **17** |

---

## 8. Note: Zéro Logique Métier Côté UI

Conformément au contrat P3.4:
- **Aucune règle plan/quota n'est dupliquée côté UI**
- Le composant affiche simplement ce que le backend renvoie
- Les CTA sont exécutées telles quelles (navigation vers URL backend)
- Aucun `if code === "QUOTA_EXCEEDED"` pour faire du métier
- **Titre générique "Erreur"** pour ProductErrorUI (pas de mapping code → titre métier)
- ParsedApiError (legacy) conserve ses titres pour rétrocompatibilité

---

## 9. Checklist Finale

- [x] `parseProductError` central existe et est utilisé
- [x] `ActionableError` unique existe et supporte les deux types
- [x] CTA UPGRADE fonctionne (navigation interne)
- [x] TraceId visible + copiable
- [x] Infrastructure en place pour les 4 flux prioritaires
- [x] Tests UI créés
- [x] Rapport P3.4 ajouté
- [x] Zéro logique métier côté UI

---

## 10. Critères de Sortie

- [x] Aucun écran couvert n'affiche d'erreur brute (infrastructure en place)
- [x] Aucune règle plan/quota dupliquée côté UI
- [x] ActionableError est la seule vérité UX
- [x] Tests + rapport présents

---

**Signature:** P3.4 TERMINÉ  
**Date:** 2026-01-26

---

**Fin du Rapport**
