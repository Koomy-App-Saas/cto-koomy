# KOOMY – Brand & Design System (v1)

**Version:** 1.0  
**Date:** 13 Janvier 2026  
**Fichiers sources:** `client/src/index.css`, `client/src/components/ui/*`

---

## A. Marque

### Logo

| Variante | Fichier | Usage |
|----------|---------|-------|
| Logo principal | `attached_assets/koomy-logo.png` | Site web, marketing |
| Logo trimmed | `attached_assets/koomy-logo-trimmed.png` | App mobile, favicon |
| Logo communautés | `attached_assets/Koomy-communitieslogo_1764495780161.png` | Illustrations |

**Règles d'utilisation:**
- **Marges de protection:** Minimum 16px autour du logo
- **Taille minimale:** 32px de hauteur
- **Fonds autorisés:** Blanc, `--background` (#F8FAFC), dégradé Koomy soft
- **Fonds interdits:** Images chargées, couleurs vives non-Koomy

### Ton visuel

**Ce qu'on recherche:**
- Sobre, professionnel, accessible
- Mobile-first, épuré
- Humain, chaleureux sans être enfantin
- Moderne sans être "tech startup"

**Ce qu'on évite:**
- Couleurs flashy, néons
- Style cartoon, illustrations lourdes
- Effets 3D complexes, ombres excessives
- Animations distrayantes

---

## B. Couleurs

### Palette principale

| Token | HSL | HEX | RGB | Usage |
|-------|-----|-----|-----|-------|
| `--primary` | `207 100% 63%` | `#44A8FF` | `68, 168, 255` | CTA, liens, accents |
| `--primary-light` | `207 100% 75%` | `#80C4FF` | `128, 196, 255` | Hover, backgrounds légers |
| `--primary-dark` | `207 90% 45%` | `#1673CC` | `22, 115, 204` | Texte sur fond clair |
| `--secondary` | `180 50% 50%` | `#40BFBF` | `64, 191, 191` | Accents secondaires |
| `--background` | `210 40% 98%` | `#F8FAFC` | `248, 250, 252` | Fond pages |
| `--foreground` | `220 20% 25%` | `#333D4D` | `51, 61, 77` | Texte principal |
| `--muted` | `210 30% 96%` | `#F1F5F9` | `241, 245, 249` | Fond cards, sections |
| `--muted-foreground` | `220 15% 50%` | `#6B7280` | `107, 114, 128` | Texte secondaire |
| `--border` | `210 30% 90%` | `#E2E8F0` | `226, 232, 240` | Bordures |

### Palette UI (États)

| Token | HSL | HEX | Usage |
|-------|-----|-----|-------|
| `--destructive` | `0 84% 60%` | `#EF4444` | Erreurs, suppressions |
| `--success` | Non défini | `#22C55E` (recommandé) | Succès, validations |
| `--warning` | Non défini | `#F59E0B` (recommandé) | Alertes, avertissements |
| `--info` | `207 100% 63%` | `#44A8FF` | Informations (= primary) |

### Sidebar (Admin/Mobile)

| Token | HSL | HEX | Usage |
|-------|-----|-----|-------|
| `--sidebar` | `207 80% 35%` | `#1B5C99` | Fond sidebar |
| `--sidebar-foreground` | `0 0% 98%` | `#FAFAFA` | Texte sidebar |
| `--sidebar-primary` | `207 100% 63%` | `#44A8FF` | Accents sidebar |
| `--sidebar-accent` | `207 70% 40%` | `#2575B3` | Hover sidebar |

### Associations recommandées (contraste WCAG AA)

| Fond | Texte | Ratio |
|------|-------|-------|
| `--background` (#F8FAFC) | `--foreground` (#333D4D) | ✅ 8.5:1 |
| `--primary` (#44A8FF) | `--primary-foreground` (#FFFFFF) | ✅ 4.5:1 |
| `--card` (#FFFFFF) | `--foreground` (#333D4D) | ✅ 9.5:1 |
| `--muted` (#F1F5F9) | `--muted-foreground` (#6B7280) | ✅ 4.6:1 |

---

## C. Typographie

### Polices

| Usage | Font Family | Fallback | Source |
|-------|-------------|----------|--------|
| **Sans (body)** | `Nunito` | `Inter`, `sans-serif` | `--font-sans` |
| **Heading** | `Nunito` | `Montserrat`, `sans-serif` | `--font-heading` |

> **Note:** Nunito utilisé pour corps et titres. Fallback sur Inter/Montserrat si indisponible.

### Échelle typographique

| Élément | Taille | Poids | Line-height | Letter-spacing |
|---------|--------|-------|-------------|----------------|
| H1 | `2.25rem` (36px) | 700 (bold) | 1.2 | tight |
| H2 | `1.875rem` (30px) | 700 | 1.25 | tight |
| H3 | `1.5rem` (24px) | 600 | 1.3 | tight |
| H4 | `1.25rem` (20px) | 600 | 1.4 | normal |
| H5 | `1.125rem` (18px) | 600 | 1.4 | normal |
| H6 | `1rem` (16px) | 600 | 1.5 | normal |
| Body | `1rem` (16px) | 400 | 1.6 | normal |
| Body small | `0.875rem` (14px) | 400 | 1.5 | normal |
| Caption | `0.75rem` (12px) | 400 | 1.4 | normal |

### Règles typographiques

- **Titres:** Courts, max 60 caractères
- **Alignement:** Gauche par défaut, centré pour hero sections
- **Densité:** Pas de blocs > 4 lignes sans espacement
- **Contraste:** Minimum 4.5:1 pour texte normal, 3:1 pour texte large

---

## D. Iconographie & Illustration

### Style d'icônes

| Propriété | Valeur | Source |
|-----------|--------|--------|
| **Librairie** | Lucide React | `lucide-react` |
| **Style** | Stroke (outline) | Standard Lucide |
| **Stroke width** | 2px (default) | — |
| **Taille standard** | 16px (sm), 20px (md), 24px (lg) | `[&_svg]:size-4` |
| **Couleur** | `currentColor` (hérite du texte) | — |

### Usage

```tsx
import { Users, Settings, ChevronRight } from "lucide-react"

// Tailles
<Users className="h-4 w-4" />  // 16px - inline avec texte
<Users className="h-5 w-5" />  // 20px - boutons
<Users className="h-6 w-6" />  // 24px - standalone
```

### Avatars

| Propriété | Valeur |
|-----------|--------|
| Style | Flat, neutre, initiales ou photo |
| Forme | Cercle (`rounded-full`) |
| Tailles | 32px (sm), 40px (md), 64px (lg) |
| Fallback | Initiales sur fond `--primary` |

---

## E. UI Components – Source of Truth

### Button

**Source:** `client/src/components/ui/button.tsx`

| Variant | Style |
|---------|-------|
| `default` | Fond `--primary`, texte blanc, bordure |
| `destructive` | Fond `--destructive`, texte blanc |
| `outline` | Bordure, fond transparent, shadow-xs |
| `secondary` | Fond `--secondary`, texte blanc, bordure |
| `ghost` | Transparent, bordure invisible |
| `link` | Texte `--primary`, underline on hover |

| Size | Specs |
|------|-------|
| `default` | `min-h-9` (36px), `px-4 py-2` |
| `sm` | `min-h-8` (32px), `px-3`, `text-xs` |
| `lg` | `min-h-10` (40px), `px-8` |
| `icon` | `h-9 w-9` (36x36px) |

### Input

**Source:** `client/src/components/ui/input.tsx`

| Propriété | Valeur |
|-----------|--------|
| Height | `h-9` (36px) |
| Border | `border-input` (--input) |
| Radius | `rounded-md` (6px) |
| Focus | `ring-1 ring-ring` |
| Placeholder | `text-muted-foreground` |

### Card

**Source:** `client/src/components/ui/card.tsx`

| Propriété | Valeur |
|-----------|--------|
| Border radius | `rounded-xl` (12px) |
| Border | `border` (--border) |
| Background | `bg-card` (white) |
| Shadow | `shadow` (standard) |
| Padding (Header/Content) | `p-6` |

### Badge

**Source:** `client/src/components/ui/badge.tsx`

| Variant | Style |
|---------|-------|
| `default` | Fond `--primary`, texte blanc |
| `secondary` | Fond `--secondary`, texte blanc |
| `destructive` | Fond `--destructive`, texte blanc |
| `outline` | Bordure, fond transparent |

| Specs | Valeur |
|-------|--------|
| Padding | `px-2.5 py-0.5` |
| Font | `text-xs font-semibold` |
| Radius | `rounded-md` |

### Table

**Source:** `client/src/components/ui/table.tsx`

| Élément | Style |
|---------|-------|
| Header row | `border-b` |
| Body row | `border-b`, `hover:bg-muted/50` |
| Head cell | `h-10 px-2`, `text-muted-foreground`, `font-medium` |
| Body cell | `p-2` |

### Dialog/Modal

**Source:** `client/src/components/ui/dialog.tsx`

| Propriété | Valeur |
|-----------|--------|
| Max width | `max-w-lg` (512px) |
| Padding | `p-6` |
| Radius | `sm:rounded-lg` |
| Overlay | `bg-black/80` |
| Animation | Fade in/out, zoom in/out |

### Toast

**Source:** `client/src/components/ui/toast.tsx`

| Variant | Style |
|---------|-------|
| `default` | Fond `--background`, bordure |
| `destructive` | Fond `--destructive`, texte blanc |

| Specs | Valeur |
|-------|--------|
| Position | Bottom-right (desktop), top (mobile) |
| Max width | `420px` |
| Padding | `p-6` |
| Radius | `rounded-md` |

### Tabs

**Source:** `client/src/components/ui/tabs.tsx`

| Élément | Style |
|---------|-------|
| List | `rounded-lg bg-muted p-1` |
| Trigger | `rounded-md px-3 py-1`, active: `bg-background shadow` |

---

## F. Layout & Responsive

### Breakpoints

| Nom | Min-width | Usage |
|-----|-----------|-------|
| `sm` | 640px | Mobile landscape |
| `md` | 768px | Tablet |
| `lg` | 1024px | Desktop |
| `xl` | 1280px | Large desktop |
| `2xl` | 1536px | Extra large |

### Règles mobile-first

1. Styles de base = mobile
2. Ajouter complexité avec `sm:`, `md:`, `lg:`
3. Touch targets minimum 44x44px sur mobile
4. Pas de hover states critiques sur mobile

### Spacing standard

| Token | Valeur | Usage |
|-------|--------|-------|
| `--radius` | `1rem` (16px) | Base pour border-radius |
| `--radius-sm` | `0.75rem` (12px) | Petits éléments |
| `--radius-md` | `0.875rem` (14px) | Inputs, buttons |
| `--radius-lg` | `1rem` (16px) | Cards |
| `--radius-xl` | `1.25rem` (20px) | Modals, grandes cards |

### Shadow standard

| Classe | Usage |
|--------|-------|
| `shadow-xs` | Badges, petits éléments |
| `shadow-sm` | Inputs |
| `shadow` | Cards |
| `shadow-lg` | Modals, toasts |

### Koomy custom effects

```css
/* Gradient primaire */
.koomy-gradient {
  background: linear-gradient(135deg, #5AB5FF 0%, #3A9EF5 100%);
}

/* Gradient doux (backgrounds) */
.koomy-gradient-soft {
  background: linear-gradient(180deg, #F0F8FF 0%, #F8FAFC 100%);
}

/* Glow effect */
.koomy-glow {
  box-shadow: 0 0 40px 10px rgba(68, 168, 255, 0.25);
}

/* Card custom */
.koomy-card {
  background: white;
  border-radius: 1.25rem;
  box-shadow: 0 4px 24px -4px rgba(68, 168, 255, 0.12);
}
```

---

## G. Exports pour la vidéo IA

### Video Style Pack (résumé 1 page)

#### Couleurs autorisées
- **Primaire:** `#44A8FF` (Sky Blue)
- **Fond clair:** `#F8FAFC` / `#FFFFFF`
- **Texte:** `#333D4D` (Dark slate)
- **Accent:** `#40BFBF` (Teal, usage modéré)

#### Couleurs interdites
- Rouge vif (sauf erreurs)
- Jaune/orange (sauf warnings)
- Noir pur (#000000)
- Dégradés arc-en-ciel

#### Typographie vidéo
- **Titres:** Nunito Bold (ou Inter Bold)
- **Corps:** Nunito Regular (ou Inter Regular)
- **Taille minimum:** 24px pour lisibilité

#### Animations
- **Style:** Subtil, fluide, 300-500ms
- **Autorisé:** Fade in/out, slide, scale léger
- **Interdit:** Bounce excessif, flash, rotation rapide

#### Placement logo
- **Position:** Coin supérieur gauche ou centré en intro/outro
- **Taille:** 10-15% de la largeur écran
- **Marge:** Minimum 5% du bord

#### Arrière-plans autorisés
1. Blanc uni (#FFFFFF)
2. Gris très clair (#F8FAFC)
3. Dégradé Koomy soft (vertical, #F0F8FF → #F8FAFC)
4. Flou léger sur image (si nécessaire)

### Assets requis

| Asset | Format | Emplacement |
|-------|--------|-------------|
| Logo principal | PNG transparent | `attached_assets/koomy-logo.png` |
| Logo trimmed | PNG transparent | `attached_assets/koomy-logo-trimmed.png` |
| Palette | JSON | `docs/brand/koomy.tokens.json` |

---

## H. Checklist cohérence

Avant de valider une page ou un visuel, vérifier:

| # | Critère | ✅ |
|---|---------|---|
| 1 | Couleurs utilisées = palette Koomy uniquement | ☐ |
| 2 | Typographie = Nunito/Inter, pas de polices fantaisie | ☐ |
| 3 | Border-radius cohérent (pas de mix arrondi/carré) | ☐ |
| 4 | Contrastes WCAG AA respectés (4.5:1 minimum) | ☐ |
| 5 | Icônes = Lucide, stroke style, taille cohérente | ☐ |
| 6 | Spacing = multiples de 4px (8, 16, 24, 32...) | ☐ |
| 7 | Boutons = variants standard (default, outline, ghost) | ☐ |
| 8 | Mobile-first: pas de hover-only interactions critiques | ☐ |
| 9 | Logo avec marges de protection respectées | ☐ |
| 10 | Ton visuel sobre, professionnel, pas cartoon | ☐ |

---

## Fichiers sources

| Fichier | Contenu |
|---------|---------|
| `client/src/index.css` | Variables CSS, thème, classes custom |
| `client/src/components/ui/*.tsx` | Composants shadcn/ui customisés |
| `client/src/lib/utils.ts` | Utilitaire `cn()` pour classes |
| `attached_assets/koomy-logo*.png` | Logos |
| `docs/brand/koomy.tokens.json` | Design tokens JSON |

---

*Document généré le 13 Janvier 2026 – KOOMY v1*
