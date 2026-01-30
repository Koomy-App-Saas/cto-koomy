# PLAN D'INTÉGRATION – CTA "Réserver une démo"

**Date :** 14 Janvier 2026  
**Statut :** IMPLÉMENTÉ ✅  
**Lien cible :** `https://calendar.app.google/UpPZuRhRtGgqZCTE7`

---

## 1. Analyse de l'existant

| Page | Structure actuelle | CTA existants |
|------|-------------------|---------------|
| **Home** | Hero + Features + Stats + CTA section | "Créer ma communauté", "Télécharger l'app" |
| **Features** | Hero + Modules détaillés + FAQ | Liens vers inscription |
| **Pricing** | Plans + Comparatif + FAQ | "Commencer" par plan |
| **Contact** | Formulaire de contact | Envoi formulaire |
| **FAQ** | Questions/réponses | Liens internes |
| **Layout (Header/Footer)** | Navigation + Connexion | Connexion, liens pages |

---

## 2. Emplacements proposés

### A. **Header (global)** – Non recommandé

> Risque de saturation visuelle. Le header contient déjà : logo, 4 liens nav, toggle langue, bouton connexion.

### B. **Home – Hero section** – Recommandé (variante secondaire)

| Position | À côté du CTA secondaire actuel ("Télécharger l'app") |
|----------|-------------------------------------------------------|
| Type | Bouton tertiaire (ghost ou link) |
| Texte | "Réserver une démo" |
| Justification | Visiteur en phase découverte, option discrète |

### C. **Home – Section finale (avant footer)** – Recommandé

| Position | Nouvelle section CTA dédiée |
|----------|----------------------------|
| Type | Encart sobre avec titre + texte + bouton |
| Texte encart | "Besoin d'une présentation personnalisée ?" |
| Texte bouton | "Planifier un échange" |
| Justification | Fin de parcours = moment de décision |

### D. **Pricing – Sous le comparatif** – Recommandé

| Position | Après les cards de plans, avant FAQ |
|----------|-------------------------------------|
| Type | Encart discret (card légère) |
| Texte | "Des questions sur l'offre adaptée ? Échangeons." |
| Bouton | "Réserver une démo" |
| Justification | Visiteur hésite entre plans = besoin d'accompagnement |

### E. **Features – Fin de section** – Recommandé

| Position | Après les modules, avant FAQ |
|----------|------------------------------|
| Type | Encart similaire à Pricing |
| Texte | "Envie de voir Koomy en action ?" |
| Bouton | "Découvrir en démo" |

### F. **Contact – Alternative au formulaire** – Optionnel

| Position | À droite ou sous le formulaire |
|----------|--------------------------------|
| Type | Lien textuel discret |
| Texte | "Préférez un échange direct ? Réservez un créneau" |
| Justification | Alternative pour prospect pressé |

### G. **Footer (global)** – Recommandé

| Position | Section "Produit" ou nouvelle ligne |
|----------|-------------------------------------|
| Type | Lien textuel simple |
| Texte | "Réserver une démo" |
| Justification | Présent partout, non intrusif |

---

## 3. Variantes de wording

| Contexte | Wording proposé | Ton |
|----------|-----------------|-----|
| Hero (découverte) | "Réserver une démo" | Direct |
| Pricing (hésitation) | "Planifier un échange" | Accompagnement |
| Features (curiosité) | "Découvrir en démo" | Invitation |
| Contact (alternative) | "Préférez un créneau direct ?" | Pratique |
| Footer (standard) | "Demander une présentation" | Neutre |

**Texte d'accroche recommandé pour les encarts :**

> "15 minutes pour découvrir comment Koomy peut s'adapter à votre communauté. Sans engagement."

---

## 4. Spécifications techniques

| Propriété | Valeur |
|-----------|--------|
| **Comportement clic** | `target="_blank"` + `rel="noopener noreferrer"` |
| **URL** | `https://calendar.app.google/UpPZuRhRtGgqZCTE7` |
| **Tracking (préparation)** | `data-testid="cta-demo-{location}"` |
| **Style bouton** | `variant="outline"` ou `variant="ghost"` selon contexte |
| **Icône** | `Calendar` (Lucide) – optionnel |

### Responsive

| Viewport | Comportement |
|----------|--------------|
| Desktop | Bouton inline, encarts en 2 colonnes |
| Mobile | Bouton full-width, encarts empilés |

---

## 5. Fréquence d'apparition

| Page | Nombre de CTA démo |
|------|--------------------|
| Home | 2 (hero + section finale) |
| Pricing | 1 (après plans) |
| Features | 1 (après modules) |
| Contact | 1 (lien discret) |
| Footer | 1 (lien permanent) |

**Total : 6 points de contact, tous contextuels**

---

## 6. Impacts UX

### Positifs

- Offre une porte d'entrée humaine (pas que du self-service)
- Rassure les prospects B2B (contact direct possible)
- Non intrusif (jamais en popup, jamais répété agressivement)
- Cohérent avec le positionnement "SaaS mature"

### Risques

- Si trop de CTA : dilution du message principal (inscription)
- Google Calendar externe : rupture d'expérience (mitigé par nouvel onglet)
- Pas de tracking GA4 initial : difficulté à mesurer conversion

### Mitigation

- CTA démo toujours **secondaire** par rapport à l'inscription
- Design discret (outline/ghost, pas primary)
- Prévoir `data-testid` pour tracking futur

---

## 7. Résumé du plan

| Localisation | Type | Texte CTA | Priorité |
|--------------|------|-----------|----------|
| Home – Hero | Bouton ghost | "Réserver une démo" | P1 |
| Home – Section finale | Encart + bouton | "Planifier un échange" | P1 |
| Pricing – Après plans | Encart léger | "Réserver une démo" | P1 |
| Features – Fin section | Encart léger | "Découvrir en démo" | P2 |
| Contact – Sous formulaire | Lien texte | "Préférez un créneau ?" | P2 |
| Footer – Section Produit | Lien texte | "Réserver une démo" | P1 |

---

## 8. Prochaines étapes (en attente de validation)

1. Validation du plan
2. Création des traductions i18n (fr/en)
3. Implémentation des 6 points d'intégration
4. Test visuel desktop/mobile
5. Commit avec documentation

---

**Aucun code ne sera écrit avant validation explicite de ce plan.**
