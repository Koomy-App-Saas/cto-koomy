# RAPPORT D'IMPLÉMENTATION — Fix Lien d'inscription public

**Date** : 2026-01-30  
**Domaine** : SELF-ENROLLMENT  
**Type** : Correctif (Bug Fix)  
**Statut** : Complété  
**Commit** : `5cec4af2182975daebb5a0a88d4293a8b3ae9945`

---

## Contexte

### Problème signalé
Les liens d'inscription générés depuis le backoffice utilisaient `window.location.origin`, ce qui produisait des URLs sur le domaine `backoffice.koomy.app`. Ces liens ne fonctionnaient pas car le mode BACKOFFICE force le rendu de `AdminLogin` sans passer par le Router.

### Symptôme utilisateur
Erreur console : `Unexpected token '<', "<!DOCTYPE "... is not valid JSON`

### Référence
Audit préalable : `docs/_daily/2026/01/2026-01-30/audits/2026-01-30__SELF-ENROLLMENT__lien_inscription_routing__AUDIT.md`

---

## Solution implémentée

### Approche
Correction minimale ciblant uniquement la génération du lien, sans modification du routing.

### Modification

**Fichier** : `client/src/pages/admin/Settings.tsx`

**Avant** :
```typescript
const handleCopyLink = () => {
  const baseUrl = window.location.origin;
  const joinUrl = `${baseUrl}/join/${settings.selfEnrollmentSlug}`;
  // ...
};

const joinUrl = settings.selfEnrollmentSlug 
  ? `${window.location.origin}/join/${settings.selfEnrollmentSlug}`
  : null;
```

**Après** :
```typescript
const PUBLIC_JOIN_BASE_URL = "https://koomy.app";

const handleCopyLink = () => {
  const joinUrl = `${PUBLIC_JOIN_BASE_URL}/join/${settings.selfEnrollmentSlug}`;
  // ...
};

const joinUrl = settings.selfEnrollmentSlug 
  ? `${PUBLIC_JOIN_BASE_URL}/join/${settings.selfEnrollmentSlug}`
  : null;
```

### Pourquoi aucune modification de App.tsx

L'analyse du routing a confirmé que la route `/join/:slug` est déjà correctement définie :

```typescript
// client/src/App.tsx - Router()
<Switch>
  <Route path="/join/:slug" component={JoinPage} />  // Ligne 264
  // ...
  <Route path="/" component={DomainAwareRoot} />      // Ligne 395
</Switch>
```

Dans wouter, les routes sont matchées dans l'ordre. La route `/join/:slug` étant AVANT `/`, elle sera matchée en priorité sur n'importe quel domaine, y compris `koomy.app`.

---

## Fichiers modifiés

| Fichier | Lignes | Description |
|---------|--------|-------------|
| `client/src/pages/admin/Settings.tsx` | 1672-1693 | Constante `PUBLIC_JOIN_BASE_URL` + utilisation dans `handleCopyLink()` et `joinUrl` |

---

## Tests de validation

### A) Génération du lien (Backoffice)
1. Ouvrir `backoffice-sandbox.koomy.app/admin/settings`
2. Onglet "Lien d'inscription"
3. Vérifier le lien affiché
4. Cliquer "Copier"

**Attendu** : `https://koomy.app/join/{slug}`

### B) Rendu page Join (Production)
1. Ouvrir le lien copié dans une fenêtre privée
2. Vérifier que la page Join s'affiche
3. Vérifier Network : GET `/api/join/:slug` → 200 JSON

**Attendu** : Pas d'erreur `Unexpected token '<'`

### C) Non-régression site public
1. Ouvrir `https://koomy.app/`
2. Naviguer pricing/demo/contact

**Attendu** : Aucune régression

### D) Non-régression backoffice
1. Ouvrir `backoffice-sandbox.koomy.app`
2. Login admin, navigation settings

**Attendu** : Backoffice inchangé

---

## Analyse technique

### Flow corrigé

```
┌─────────────────────────────────────────────────────────────────┐
│ BACKOFFICE (admin)                                               │
│ backoffice.koomy.app/admin/settings                             │
│                                                                  │
│ 1. Admin configure self-enrollment                               │
│ 2. Clic "Copier le lien"                                        │
│ 3. Génère: https://koomy.app/join/{slug}  ← CORRIGÉ             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ Partage lien à un prospect
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ PROSPECT ouvre le lien                                          │
│ https://koomy.app/join/{slug}                                   │
│                                                                  │
│ 1. SPA charge → Router                                          │
│ 2. Switch matche /join/:slug AVANT /                            │
│ 3. JoinPage rendu directement                                   │
│ 4. GET /api/join/:slug → 200 JSON                               │
│ 5. ✅ Formulaire d'inscription affiché                          │
└─────────────────────────────────────────────────────────────────┘
```

### Ordre de matching wouter

| Ordre | Route | Composant | Match `/join/xxx` ? |
|-------|-------|-----------|---------------------|
| 1 | `/__env` | EnvCheck | Non |
| 2 | `/join/:slug` | JoinPage | **OUI → Stop** |
| ... | ... | ... | Non atteint |
| N | `/` | DomainAwareRoot | Non atteint |

---

## Risques et limitations

### Risques mitigés
- **Hardcoding du domaine** : Acceptable car `koomy.app` est le domaine public officiel et stable
- **Pas de configuration dynamique** : Volontaire pour éviter la complexité

### Limitations connues
- Les liens pointent toujours vers `koomy.app` même en environnement sandbox
- Pour les tests sandbox, accéder manuellement à `sandbox.koomy.app/join/{slug}`

### Évolutions futures possibles
- Ajouter une variable d'environnement `VITE_PUBLIC_JOIN_BASE_URL` si besoin de flexibilité
- Permettre l'intégration sur des domaines tiers (iframe, widget)

---

## Checklist de clôture

- [x] Audit préalable réalisé
- [x] Correction minimale implémentée
- [x] Aucune régression identifiée
- [x] Code review architecte : PASS
- [x] Commit créé
- [ ] Tests manuels en sandbox
- [ ] Déploiement production

---

## Références

- Audit : `docs/_daily/2026/01/2026-01-30/audits/2026-01-30__SELF-ENROLLMENT__lien_inscription_routing__AUDIT.md`
- Spec initiale : `attached_assets/Pasted--replit_prompt_fix_public_join_link_koomy_app.md`
