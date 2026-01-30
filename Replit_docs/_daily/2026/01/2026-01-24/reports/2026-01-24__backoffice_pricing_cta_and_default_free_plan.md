# Rapport: CTA Pricing Backoffice + Plan FREE par défaut

**Date**: 2026-01-24  
**Auteur**: Agent Replit  
**Commit**: (voir dernier commit)

---

## Objectif

Ajouter un rappel marketing (CTA) pour renvoyer vers le site public pricing, et garantir que toute communauté créée via le backoffice a un plan FREE par défaut.

## Fichiers modifiés

| Fichier | Modification |
|---------|-------------|
| `client/src/pages/admin/Login.tsx` | Section "Plans flexibles" rendue cliquable avec lien vers pricing + import `isSandboxEnvironment` et `ExternalLink` |

## Fichiers vérifiés (sans modification requise)

| Fichier | Raison |
|---------|--------|
| `server/routes.ts` (ligne 3253, 3429-3431) | Le backend assigne déjà `planId: 'free'` par défaut si aucun plan n'est fourni |

---

## Implémentation

La section "Plans flexibles" existante (sous l'image collage, colonne gauche) a été modifiée :

**Avant** : `<div>` statique
**Après** : `<a>` cliquable avec effets hover

```tsx
<a
  href={isSandboxEnvironment() 
    ? "https://sitepublic-sandbox.koomy.app/pricing" 
    : "https://koomy.app/pricing"}
  target="_blank"
  rel="noopener noreferrer"
  className="block bg-white/10 rounded-xl p-4 backdrop-blur-sm hover:bg-white/20 transition-colors cursor-pointer group"
>
  <div className="flex items-center gap-2 mb-1">
    <Shield />
    <span>Plans flexibles</span>
    <ExternalLink className="opacity-0 group-hover:opacity-100" />
  </div>
  <p>Gratuit pour démarrer, puis à partir de 9€/mois</p>
</a>
```

---

## Logique URL sandbox/prod

La fonction `isSandboxEnvironment()` de `@/lib/envGuard` détecte automatiquement l'environnement basé sur le hostname.

| Environnement | URL Pricing |
|--------------|-------------|
| Sandbox | `https://sitepublic-sandbox.koomy.app/pricing` |
| Production | `https://koomy.app/pricing` |

---

## Design

- **Emplacement** : Colonne gauche, sous l'image collage hero
- **Style** : Conserve le design existant (bg-white/10, rounded-xl, backdrop-blur)
- **Hover** : bg-white/20 + icône ExternalLink apparaît + texte plus lumineux
- **Cohérence** : S'intègre naturellement avec le reste de la section marketing

---

## Plan FREE par défaut (Backend)

Le backend (`server/routes.ts`) assigne automatiquement le plan FREE si aucun plan n'est fourni:

```typescript
// Ligne 3427-3431
const validPlans = ["free", "plus", "pro"];
const planId = validPlans.includes(requestedPlanId?.toLowerCase()) 
  ? requestedPlanId.toLowerCase() 
  : "free";  // ← Fallback automatique sur FREE
```

---

## Check-list Tests

### Section "Plans flexibles"
- [x] Visible sur desktop et mobile (colonne gauche)
- [x] Cliquable → redirection vers page pricing (nouvelle fenêtre)
- [x] URL sandbox correcte en environnement sandbox
- [x] Icône ExternalLink apparaît au hover
- [x] Effet hover cohérent avec le design

### Création communauté depuis backoffice
- [x] Communauté créée avec `planId: 'free'` par défaut
- [x] Aucune erreur "plan manquant"
- [x] `subscriptionStatus: 'trialing'` avec trial 14 jours

### Non régression
- [x] Bandeaux existants (trial, sandbox) non modifiés
- [x] Flux de connexion/invitation inchangé
- [x] Flux site public inchangé

---

## Définition de Done

| Critère | Status |
|---------|--------|
| Section "Plans flexibles" cliquable | ✅ |
| Clic renvoie vers pricing correct (sandbox/prod) | ✅ |
| Design cohérent avec la section existante | ✅ |
| Création via backoffice sans plan → FREE par défaut | ✅ (déjà en place) |
| Aucune modification des bandeaux existants | ✅ |
| Rapport livré | ✅ |

---

## Notes techniques

- **Pas de nouveau fichier config** : réutilisation de `isSandboxEnvironment()` existant
- **Pas de nouvelle dépendance** : ExternalLink déjà dans lucide-react
- **Approche minimaliste** : modification d'un élément existant plutôt que création d'un nouveau
