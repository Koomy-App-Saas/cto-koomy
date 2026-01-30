# AUDIT — Lien d'inscription (Self-Enrollment)

**Date** : 2026-01-30  
**Domaine** : SELF-ENROLLMENT  
**Type** : Audit fonctionnel (NO FIX)  
**Statut** : Diagnostic complet

---

## Contexte

Dans le backoffice, un admin génère un lien d'inscription (self-enrollment). En ouvrant le lien, la console affiche :

```
Unexpected token '<', "<!DOCTYPE "... is not valid JSON
```

Cet audit identifie la cause sans appliquer de correction.

---

## 1. Cartographie de la Feature

### 1.1 Génération du lien (Backoffice)

| Élément | Valeur |
|---------|--------|
| Route écran | `/admin/settings` → Onglet "Lien d'inscription" |
| Fichier | `client/src/pages/admin/Settings.tsx` |
| Composant | `SelfEnrollmentSettings` (lignes 1600-1900) |

**Code de génération** :

```typescript
// Settings.tsx - lignes 1670-1676
const handleCopyLink = () => {
  const baseUrl = window.location.origin;  // ← PROBLÈME ICI
  const joinUrl = `${baseUrl}/join/${settings.selfEnrollmentSlug}`;
  navigator.clipboard.writeText(joinUrl);
};

// Affichage du lien (lignes 1687-1688)
const joinUrl = settings.selfEnrollmentSlug 
  ? `${window.location.origin}/join/${settings.selfEnrollmentSlug}`
  : null;
```

### 1.2 Format du lien généré

```
https://backoffice.koomy.app/join/{selfEnrollmentSlug}
```

**Exemple** : `https://backoffice.koomy.app/join/mon-club-2024`

**Paramètres** :
- `selfEnrollmentSlug` : slug unique configuré par l'admin, stocké dans `communities.self_enrollment_slug`

### 1.3 Points d'entrée Backend

| Endpoint | Méthode | Description | Auth |
|----------|---------|-------------|------|
| `/api/join/:slug` | GET | Récupère infos communauté + plans éligibles | Public |
| `/api/join/:slug` | POST | Soumet une demande d'inscription | Public |

**Fichier** : `server/routes.ts` (lignes 13552-13820)

**Payload GET** :

```typescript
{
  community: {
    id: string,
    name: string,
    logo: string | null,
    primaryColor: string | null,
    selfEnrollmentMode: "OPEN" | "CLOSED",
    selfEnrollmentSectionsEnabled: boolean,
    selfEnrollmentRequiredFields: string[],
    whiteLabel: boolean
  },
  eligiblePlans: [{
    id: string,
    name: string,
    amount: number | null,
    billingType: string,
    membershipType: string
  }],
  sections: [{ id: string, name: string }],
  quotaAvailable: boolean,
  quotaMessage: string | null
}
```

### 1.4 Comportement attendu

- Page **PUBLIQUE** (pas d'authentification requise)
- Affiche formulaire d'inscription avec :
  - Champs obligatoires (email, nom, prénom)
  - Sélection de formule d'adhésion
  - Sélection de section (optionnel)
  - Consentements RGPD
- Selon le mode :
  - `OPEN` : Membre créé directement
  - `CLOSED` : Demande créée, en attente d'approbation admin

---

## 2. Domaines et Routing

### 2.1 Pourquoi backoffice.koomy.app est utilisé

**Source** : `Settings.tsx` ligne 1670

```typescript
const baseUrl = window.location.origin;
```

L'admin est connecté sur `backoffice.koomy.app`, donc `window.location.origin` retourne ce domaine.

### 2.2 Le lien devrait-il être public ?

**OUI.** Le lien d'inscription est destiné aux futurs membres qui n'ont pas accès au backoffice.

### 2.3 Domaines officiels

**Source** : `client/src/lib/appModeResolver.ts`

| Domaine | Mode | Description |
|---------|------|-------------|
| `koomy.app` | SITE_PUBLIC | Site commercial |
| `app.koomy.app` | WALLET | App membre (wallet) |
| `backoffice.koomy.app` | BACKOFFICE | Backoffice admin |
| `app-pro.koomy.app` | CLUB_MOBILE | App mobile admin |
| `owner.koomy.app` | OWNER | Plateforme owner |

### 2.4 Contraintes techniques

| Contrainte | Impact |
|------------|--------|
| **Host-based mode resolver** | `DomainAwareRoot` force le rendu selon le hostname |
| **Forced modes** | Les domaines connus retournent directement un composant sans passer par le Router |
| **Route `/join/:slug`** | Définie dans `App.tsx` ligne 257, mais jamais atteinte pour les forced modes |

---

## 3. Diagnostic de l'erreur

### 3.1 Cause racine identifiée

**Fichier** : `client/src/App.tsx` lignes 175-245

```typescript
function DomainAwareRoot() {
  const appModeResult = resolveAppMode();
  const { mode, isForcedMode } = appModeResult;

  if (isForcedMode) {
    switch (mode) {
      case "BACKOFFICE":
        return <AdminLogin />;  // ← Retourne DIRECTEMENT, sans Router
      // ...
    }
  }
  // ...
}
```

**Flux problématique** :

1. Utilisateur ouvre `backoffice.koomy.app/join/xxx`
2. SPA charge → `DomainAwareRoot` s'exécute
3. `resolveAppMode()` détecte hostname = `backoffice.koomy.app`
4. Mode = `BACKOFFICE` (forced mode)
5. Retourne `<AdminLogin />` **SANS passer par le Router**
6. La route `/join/:slug` (ligne 257) n'est **JAMAIS matchée**
7. `JoinPage` n'est **JAMAIS rendu**

### 3.2 Source de l'erreur JSON

L'erreur "Unexpected token '<'" provient de :

1. Un composant parent (AuthContext, AdminLogin, etc.) effectue un fetch API
2. Le serveur retourne du HTML (index.html, page 404, ou redirection)
3. Le code exécute `.json()` sur une réponse HTML

**Hypothèses probables** :
- AuthContext tente de vérifier la session et reçoit une redirection HTML
- Un intercepteur global fait un fetch vers une URL qui n'existe pas

### 3.3 Vérification recommandée (Network tab)

Pour confirmer, ouvrir DevTools > Network sur `backoffice.koomy.app/join/xxx` et chercher :

| Critère | Valeur attendue (bug) |
|---------|----------------------|
| URL requête | Probablement `/api/...` ou autre |
| Status code | 200 (mais content HTML) ou 302/404 |
| Content-Type | `text/html` au lieu de `application/json` |
| Body | `<!DOCTYPE html>...` |

---

## 4. Schéma du flow (bugué)

```
┌─────────────────────────────────────────────────────────────────┐
│ BACKOFFICE (admin)                                               │
│ backoffice.koomy.app/admin/settings                             │
│                                                                  │
│ 1. Admin configure self-enrollment                               │
│ 2. Clic "Copier le lien"                                        │
│ 3. Génère: backoffice.koomy.app/join/{slug}                     │
│    ↳ window.location.origin = backoffice.koomy.app              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ Partage lien à un prospect
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ PROSPECT ouvre le lien                                          │
│ backoffice.koomy.app/join/{slug}                                │
│                                                                  │
│ 1. SPA charge → DomainAwareRoot                                 │
│ 2. hostname = backoffice.koomy.app                              │
│ 3. resolveAppMode() → Mode = BACKOFFICE (forced)                │
│ 4. return <AdminLogin /> ← PAS le Router !                      │
│ 5. Route /join/:slug JAMAIS matchée                             │
│ 6. JoinPage JAMAIS rendu                                        │
│ 7. ❌ Erreur JSON (fetch context/autre)                         │
└─────────────────────────────────────────────────────────────────┘
```

---

## 5. Fichiers impliqués

### Frontend

| Fichier | Rôle | Lignes clés |
|---------|------|-------------|
| `client/src/pages/admin/Settings.tsx` | Génération du lien | 1670-1688 |
| `client/src/pages/JoinPage.tsx` | Page d'inscription publique | 1-461 |
| `client/src/App.tsx` | Router + DomainAwareRoot | 175-257 |
| `client/src/lib/appModeResolver.ts` | Résolution du mode par hostname | 80-150 |

### Backend

| Fichier | Rôle | Lignes clés |
|---------|------|-------------|
| `server/routes.ts` | Endpoints `/api/join/:slug` | 13552-13820 |
| `shared/schema.ts` | Champ `selfEnrollmentSlug` | 397-403 |

---

## 6. Recommandations (non implémentées)

### A. Rendre le lien public sur koomy.app

**Option 1 : Générer le lien sur le site commercial**

```typescript
// Settings.tsx - modification proposée
const PUBLIC_JOIN_BASE_URL = "https://koomy.app";
const joinUrl = `${PUBLIC_JOIN_BASE_URL}/join/${settings.selfEnrollmentSlug}`;
```

**Implications** :
- Ajouter la route `/join/:slug` au mode `SITE_PUBLIC`
- Ou exclure `/join/*` des forced modes dans `DomainAwareRoot`

**Option 2 : Utiliser app.koomy.app**

```typescript
const PUBLIC_JOIN_BASE_URL = "https://app.koomy.app";
```

Plus cohérent car l'inscription est liée à l'app membre.

**Modification requise dans App.tsx** :

```typescript
// Dans DomainAwareRoot, avant le switch des forced modes
const pathname = window.location.pathname;
if (pathname.startsWith("/join/")) {
  return <Router />;  // Laisser le Router gérer /join/*
}
```

### B. Permettre intégration future sur site externe

| Principe | Description |
|----------|-------------|
| **URL configurable** | Permettre à l'admin de définir un domaine personnalisé pour le lien |
| **Iframe-friendly** | S'assurer que les headers permettent l'embed (`X-Frame-Options: ALLOW-FROM`) |
| **CORS** | Configurer `/api/join/*` pour accepter les origines tierces |
| **Widget JS** | Proposer un script à intégrer sur le site externe |

---

## 7. Conclusion

| Élément | Valeur |
|---------|--------|
| **Cause racine** | Le lien utilise `window.location.origin` (backoffice.koomy.app), mais ce domaine force le mode BACKOFFICE qui bypass le Router |
| **Conséquence** | La route `/join/:slug` n'est jamais matchée, `JoinPage` n'est jamais rendu |
| **Erreur JSON** | Provient d'un fetch (contexte Auth ou autre) qui reçoit du HTML |
| **Correction recommandée** | Générer le lien sur un domaine public (koomy.app ou app.koomy.app) et s'assurer que ce domaine route vers `JoinPage` |

---

## Annexes

### A. Endpoints Self-Enrollment complets

| Endpoint | Méthode | Auth | Description |
|----------|---------|------|-------------|
| `/api/join/:slug` | GET | Public | Page d'inscription |
| `/api/join/:slug` | POST | Public | Soumettre inscription |
| `/api/communities/:id/self-enrollment/settings` | GET | Admin | Lire config |
| `/api/communities/:id/self-enrollment/settings` | PATCH | Admin | Modifier config |
| `/api/communities/:id/self-enrollment/generate-slug` | POST | Admin | Générer nouveau slug |
| `/api/communities/:id/enrollment-requests` | GET | Admin | Liste demandes |
| `/api/communities/:id/enrollment-requests/:id/approve` | POST | Admin | Approuver |
| `/api/communities/:id/enrollment-requests/:id/reject` | POST | Admin | Rejeter |

### B. Schéma DB

```sql
-- Table communities (extrait)
self_enrollment_enabled       BOOLEAN DEFAULT false
self_enrollment_channel       ENUM('OFFLINE', 'ONLINE') DEFAULT 'OFFLINE'
self_enrollment_mode          ENUM('OPEN', 'CLOSED') DEFAULT 'OPEN'
self_enrollment_slug          TEXT UNIQUE
self_enrollment_eligible_plans JSONB  -- string[]
self_enrollment_required_fields JSONB -- string[]
self_enrollment_sections_enabled BOOLEAN DEFAULT false
```
