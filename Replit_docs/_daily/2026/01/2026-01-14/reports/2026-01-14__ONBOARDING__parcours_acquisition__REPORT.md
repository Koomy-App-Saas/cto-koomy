# Rapport Post-Implémentation - Parcours Acquisition Site Public

**Date**: 19 janvier 2026  
**Statut**: ✅ Implémenté  
**Version**: 1.1

---

## Résumé

Le parcours d'acquisition du site public Koomy a été corrigé pour suivre le standard SaaS :

```
Landing (site public) → CTA "Commencer" → Page Pricing → Choix plan → Signup
```

Le Hero a été simplifié pour concentrer l'utilisateur sur une seule action.

---

## 1. Fichiers Modifiés

### 1.1 CTAs "Commencer" → `/website/pricing`

| Fichier | Modification |
|---------|--------------|
| `client/src/pages/website/Home.tsx` | `href="/website/signup"` → `href="/website/pricing"` (2 occurrences) |
| `client/src/pages/website/Layout.tsx` | `href="/website/signup"` → `href="/website/pricing"` (3 occurrences) |
| `client/src/pages/website/Features.tsx` | `href="/website/signup"` → `href="/website/pricing"` (2 occurrences) |

**Total**: 7 occurrences modifiées

---

### 1.2 Plans avec query param

| Fichier | Modification |
|---------|--------------|
| `shared/plans.ts` | `ctaLink: "/admin/register"` → `ctaLink: "/admin/register?plan=free"` |

**Détail des ctaLinks finaux**:

| Plan | ctaLink |
|------|---------|
| FREE | `/admin/register?plan=free` |
| PLUS | `/admin/register?plan=plus` |
| PRO | `/admin/register?plan=pro` |
| GRAND_COMPTE | `/website/contact` (inchangé) |

---

### 1.3 Register.tsx - Lecture du query param + Redirect

| Fichier | Modification |
|---------|--------------|
| `client/src/pages/admin/Register.tsx` | Ajout imports + logique query param |

**Imports ajoutés**:
- `useSearch` (wouter)
- `useEffect` (react)
- `PLAN_CODES`, `PlanCode` (shared/schema)
- `getPlanByCode` (shared/plans)

**Nouvelles fonctionnalités**:

```typescript
// Lecture du query param
const searchString = useSearch();
const planParam = new URLSearchParams(searchString).get("plan")?.toUpperCase() as PlanCode | null;
const selectedPlan = planParam && Object.values(PLAN_CODES).includes(planParam) 
  ? getPlanByCode(planParam) 
  : null;

// Redirect si déjà connecté
useEffect(() => {
  if (user) {
    setLocation("/admin/dashboard");
  }
}, [user, setLocation]);
```

**Affichage du plan sélectionné** (Step 1 uniquement):
- Badge bleu avec nom du plan
- Prix affiché (€/mois ou "Gratuit")

---

### 1.4 Fallback `/website/signup`

| Fichier | Modification |
|---------|--------------|
| `client/src/App.tsx` | `window.location.href = "/admin/dashboard"` → `window.location.href = "/website/pricing"` |

---

### 1.5 Simplification Hero

| Fichier | Modification |
|---------|--------------|
| `client/src/i18n/locales/fr.json` | `"cta": "Commencer gratuitement"` → `"cta": "Commencer"` |
| `client/src/i18n/locales/en.json` | `"cta": "Start for free"` → `"cta": "Get started"` |
| `client/src/pages/website/Home.tsx` | Suppression CTA "Télécharger l'app" |
| `client/src/pages/website/Home.tsx` | Suppression mentions "Pas de carte requise" / "Annulation facile" |

**Éléments supprimés du Hero**:
- Bouton secondaire "Télécharger l'app"
- Bouton "Demander une démo"
- Mention "Pas de carte requise"
- Mention "Annulation facile"

**Résultat**: Un Hero épuré avec uniquement :
- Titre + sous-titre
- Un seul CTA : "Commencer"

---

## 2. Comportement Final

| Action | Résultat |
|--------|----------|
| Clic "Commencer" (Hero) | → `/website/pricing` |
| Clic "Commencer" (Footer, Features) | → `/website/pricing` |
| Clic "Choisir" sur plan FREE | → `/admin/register?plan=free` |
| Clic "Choisir" sur plan PLUS | → `/admin/register?plan=plus` |
| Clic "Choisir" sur plan PRO | → `/admin/register?plan=pro` |
| Clic "Nous contacter" (Grand Compte) | → `/website/contact` |
| Accès direct `/website/signup` | → Redirect `/website/pricing` |
| Accès `/admin/register` sans param | → Formulaire normal |
| Accès `/admin/register?plan=plus` | → Formulaire avec badge "Plan sélectionné: Plus (12€/mois)" |
| User déjà connecté sur `/admin/register` | → Redirect `/admin/dashboard` |

---

## 3. Checklist de Validation

- [x] Landing: clic "Commencer" → `/website/pricing`
- [x] Pricing: clic "Choisir" (FREE) → `/admin/register?plan=free`
- [x] Register: le plan est visible/pré-sélectionné (step 1)
- [x] Register: si user connecté → redirect `/admin/dashboard`
- [x] Pricing: "Grand Compte" → "Nous contacter" inchangé
- [x] `/website/signup` → redirige vers `/website/pricing`
- [x] Hero simplifié: un seul CTA "Commencer"
- [x] Aucun impact sur `/admin/login`
- [x] Aucun impact sur routes mobile `/app/*`
- [x] Pas de modification backend

---

## 4. Points Techniques

### Framework de routing
- **Wouter** (pas React Router)
- Hook `useSearch()` pour lire les query params
- Hook `useLocation()` pour la navigation

### Validation du plan
- Le param `?plan=xxx` est converti en majuscules
- Vérifié contre `PLAN_CODES` enum
- Si invalide → `selectedPlan = null` (comportement par défaut)

### UX du badge plan
- Affiché uniquement au Step 1 du formulaire
- Couleurs: fond bleu-50, texte bleu-700
- Prix en bleu-500 ou vert-600 (gratuit)

---

## 5. Aucune Régression

| Élément | Statut |
|---------|--------|
| Navigation admin | ✅ Inchangée |
| Auth flow | ✅ Inchangé |
| Routes mobile | ✅ Inchangées |
| Backend API | ✅ Aucune modification |
| Stripe/Paiements | ✅ Non impacté |
| i18n autres clés | ✅ Inchangées |

---

## 6. Commits

| Commit | Description |
|--------|-------------|
| `07feda7` | Update website signup flow to redirect to pricing page |
| `0ccc419` | Simplify the main call to action and remove app download button |
| `4f7c5c6` | Remove redundant text from public website homepage hero section |
