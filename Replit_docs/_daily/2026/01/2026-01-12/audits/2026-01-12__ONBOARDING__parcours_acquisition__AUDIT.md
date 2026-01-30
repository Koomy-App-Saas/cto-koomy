# Audit Technique - Parcours Acquisition Site Public Koomy

**Date**: 19 janvier 2026  
**Objectif**: Corriger le parcours d'acquisition pour que "Commencer" → Plans → Signup (pas directement Login)

---

## Contexte

Aujourd'hui, quand on clique sur le CTA principal "Commencer", on est envoyé directement vers la page de connexion du backoffice (`/admin/dashboard`).

Ce comportement est mauvais pour l'acquisition: un visiteur qui veut démarrer doit d'abord comprendre les offres, choisir un plan, puis créer un compte.

### Parcours cible (V1 standard SaaS)

```
Landing (site public) 
    → CTA "Commencer" 
    → Page Plans/Pricing 
    → Choix d'un plan 
    → Page Signup (création de compte)
    → Login reste accessible en secondaire ("Déjà un compte ? Se connecter")
```

---

## A) CTA "Commencer" sur le site public

| Élément | Détail |
|---------|--------|
| **Fichier principal** | `client/src/pages/website/Home.tsx` |
| **Lignes** | 26-30 (Hero CTA), 161-165 (Footer CTA) |
| **Handler** | `<Link href="/website/signup">` |
| **Destination actuelle** | `/website/signup` |
| **Autres fichiers** | `Layout.tsx` (lignes 112, 153, 242), `Features.tsx` (lignes 84, 338) |

**Texte i18n** : `t('home.hero.cta')` → "Commencer gratuitement" (`client/src/i18n/locales/fr.json` ligne 34)

### Fichiers impactés

```
client/src/pages/website/Home.tsx       → 2 occurrences
client/src/pages/website/Layout.tsx     → 3 occurrences  
client/src/pages/website/Features.tsx   → 2 occurrences
```

---

## B) Page "Plans/Pricing"

| Élément | Détail |
|---------|--------|
| **Existe ?** | ✅ OUI |
| **Route** | `/website/pricing` |
| **Fichier** | `client/src/pages/website/Pricing.tsx` |
| **Routing** | `App.tsx` ligne 229 |
| **CTAs des plans** | Chaque plan a un `ctaLink` personnalisé (ligne 188) défini dans `shared/plans.ts` |

### Structure des plans

Les plans sont définis dans `shared/plans.ts` avec:
- `id`: identifiant unique
- `code`: code du plan (FREE, PLUS, PRO, GRAND_COMPTE)
- `ctaLink`: lien du bouton CTA
- `ctaText`: texte du bouton

---

## C) Page "Signup" (création de compte)

| Élément | Détail |
|---------|--------|
| **Route actuelle** | `/website/signup` |
| **Comportement** | ⚠️ **MOCK** - Redirection directe vers `/admin/dashboard` |
| **Code** | `App.tsx` lignes 242-248 |
| **Vraie page Register** | `/admin/register` → `AdminRegister.tsx` (814 lignes, formulaire complet multi-étapes) |
| **Login** | `/admin/login` → `AdminLogin.tsx` |

### Code problématique actuel

```tsx
// App.tsx lignes 242-248 - LE PROBLÈME
<Route path="/website/signup">
  {() => {
    window.location.href = "/admin/dashboard";  // ❌ Saute directement au dashboard!
    return null; 
  }}
</Route>
```

### Page Register existante

`/admin/register` (`AdminRegister.tsx`) est une vraie page d'inscription avec:
- Formulaire multi-étapes (4 étapes)
- Création compte admin + communauté
- Validation des champs
- Upload logo
- Configuration cotisations

---

## D) Routing global

| Élément | Détail |
|---------|--------|
| **Framework** | `wouter` (pas React Router) |
| **Config principale** | `client/src/App.tsx` fonction `Router()` lignes 218-328 |
| **Structure routes** | `/website/*` (site public), `/admin/*` (backoffice), `/app/*` (mobile) |

### Arborescence des routes

```
/website              → WebsiteHome
/website/pricing      → WebsitePricing  
/website/signup       → Mock redirect (à corriger)
/website/faq          → WebsiteFAQ
/website/contact      → WebsiteContact
...

/admin/login          → AdminLogin
/admin/register       → AdminRegister (vraie inscription)
/admin/dashboard      → AdminDashboard
...
```

---

## Plan d'Implémentation

### Étape 1: Modifier le CTA principal → vers `/website/pricing`

**Fichiers à modifier:**
- `client/src/pages/website/Home.tsx`
- `client/src/pages/website/Layout.tsx`
- `client/src/pages/website/Features.tsx`

**Changement:** `href="/website/signup"` → `href="/website/pricing"`

**Impact:** ~8 occurrences

---

### Étape 2: Ajouter le passage du plan sélectionné vers signup

**Fichier:** `shared/plans.ts`

**Changement:** Modifier les `ctaLink` des plans pour pointer vers `/admin/register?plan={planCode}`

**Exemple:**
```typescript
ctaLink: "/admin/register?plan=free"
ctaLink: "/admin/register?plan=plus"
ctaLink: "/admin/register?plan=pro"
```

---

### Étape 3: Modifier `/admin/register` pour lire le query param

**Fichier:** `client/src/pages/admin/Register.tsx`

**Changement:** Récupérer `?plan=xxx` via `useSearch()` de wouter et pré-sélectionner le plan

**Impact minimal:** Juste afficher le plan choisi, pas de changement métier

---

### Étape 4: Garder le lien Login en secondaire

**Fichier:** `client/src/pages/admin/Register.tsx`

**Vérifier:** Le lien "Déjà un compte ? Se connecter" existe déjà en bas du formulaire

**Aucune modification nécessaire** si déjà présent

---

### Étape 5: Supprimer ou rediriger le mock `/website/signup`

**Fichier:** `App.tsx` lignes 242-248

**Options:**
- **Option A:** Supprimer la route (404 naturel)
- **Option B:** Rediriger vers `/website/pricing` (fallback propre)

---

## Checklist de Tests Manuels

- [ ] Cliquer "Commencer" sur la Home → arrive sur `/website/pricing`
- [ ] Sur Pricing, cliquer "Choisir" sur un plan → arrive sur `/admin/register?plan=xxx`
- [ ] Le formulaire Register affiche le plan pré-sélectionné
- [ ] Lien "Déjà un compte ?" visible et fonctionnel → `/admin/login`
- [ ] Navigation existante admin/mobile non cassée
- [ ] Accès direct à `/admin/register` (sans param) fonctionne toujours
- [ ] Plan Grand Compte → "Nous contacter" fonctionne

---

## Points de Décision à Valider

| # | Question | Options | Décision |
|---|----------|---------|----------|
| 1 | **Route finale signup** | `/admin/register` (existante) ou créer `/website/register` (nouvelle) ? | À valider |
| 2 | **Format du param plan** | `?plan=free` / `?plan=plus` / `?plan=pro` / `?plan=grand_compte` | À valider |
| 3 | **Fallback si déjà connecté** | Rediriger vers `/admin/dashboard` ? Afficher message ? | À valider |
| 4 | **CTA pricing pour Grand Compte** | Garder "Nous contacter" ou unifier vers signup ? | À valider |
| 5 | **Supprimer `/website/signup`** | Supprimer (404) ou rediriger vers `/website/pricing` ? | À valider |

---

## Critères de Validation (GO/NO-GO)

✅ "Commencer" n'amène plus jamais en premier sur `/login`  
✅ On passe par Plans → Signup  
✅ Zéro changement backend  
✅ Zéro régression navigation/auth existante
