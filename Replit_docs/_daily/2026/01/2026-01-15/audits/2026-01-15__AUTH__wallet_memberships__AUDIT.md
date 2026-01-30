# Audit Produit & Tech — Wallet de Memberships

**Date :** 16 janvier 2026  
**Auteur :** Agent Koomy  
**Statut :** Audit terminé

---

## Résumé Exécutif

Koomy dispose déjà d'une architecture "wallet" fonctionnelle avec une page Hub listant toutes les cartes d'adhésion. Cependant, la perception "wallet" n'est pas optimale pour plusieurs raisons : navigation parfois directe vers un club unique, absence de mini-cartes visuelles type Apple/Google Wallet, et manque d'accès rapide au Hub depuis les pages internes.

---

## A) Session & Contexte

### 1) Redirection après login

| Scénario | Redirection |
|----------|-------------|
| White-label (1 club forcé) | `/app/${communityId}/home` |
| 0 membership | `/app/add-card` |
| 1 membership | `/app/${communityId}/home` (directement) |
| 2+ memberships | `/app/hub` (liste des cartes) |

**Fichiers :** `client/src/pages/mobile/Login.tsx` (lignes 65-73), `client/src/pages/mobile/WhiteLabelLogin.tsx`

**Observation :** L'utilisateur avec 1 seule carte ne voit jamais le Hub. Il est directement redirigé vers la home du club, ce qui masque la logique "wallet".

### 2) Session conservée

| Donnée | Persistée | Clé localStorage |
|--------|-----------|------------------|
| Account (utilisateur) | Oui | `koomy_account` |
| Current membership | Oui | `koomy_membership` |
| Current community | Dérivée | (via membership) |

**Fichier :** `client/src/contexts/AuthContext.tsx`

Le `currentMembership` est persisté et restauré au rechargement. La sélection se fait via `selectMembership(membershipId)` ou `selectCommunity(communityId)`.

### 3) Comportements spécifiques

| Action | Comportement |
|--------|--------------|
| Logout / Login | Session effacée, redirection selon logique ci-dessus |
| Fermeture app | Restauration via localStorage/Preferences |
| Ajout nouvelle carte | Redirection vers `/app/${communityId}/home` du nouveau club |

---

## B) Liste des Cartes / Adhésions

### 4) Page Hub existante

**Oui, elle existe :**

| Attribut | Valeur |
|----------|--------|
| Route | `/app/hub` |
| Composant | `client/src/pages/mobile/CommunityHub.tsx` |
| Titre | "Mes Cartes" |
| Contenu | Liste des memberships avec logo club, nom, statut, badges (Admin, Actif/Expiré) |

**Fonctionnalités actuelles :**
- Affichage de toutes les cartes de l'utilisateur
- Badge "Admin" si administrateur
- Badge "Actif" / "Expiré" selon statut
- Badge "Non liée" si membership sans accountId
- Bouton "Ajouter une carte" (CTA dashed)
- Clic sur une carte → `selectMembership()` + navigation vers home

### 5) Accès manuel au Hub

**Moyen actuel :** Aucun bouton explicite depuis les pages internes (Home, Card, Profile).

L'utilisateur doit :
- Se déconnecter et se reconnecter avec 2+ cartes
- Ou modifier l'URL manuellement

**Constat :** Manque un bouton "Mes cartes" ou "Changer de club" accessible depuis le menu ou le header.

---

## C) Navigation Multi-Club

### 6) Changement de club

Actuellement, l'utilisateur doit :
1. Aller sur `/app/hub` (si accessible)
2. Cliquer sur une autre carte

Il n'y a pas de sélecteur de club dans le header ou la navigation mobile.

### 7) Notion "Changer de carte" dans l'UI

**Non explicite.** Le Hub affiche "Mes Cartes" mais il n'y a pas de libellé "Changer de carte" ou "Wallet" visible.

---

## D) Perception Wallet (UX)

### 8) Compréhension utilisateur

| Élément | État |
|---------|------|
| Titre "Mes Cartes" | Présent sur Hub |
| Icônes type wallet | Non |
| Mini-cartes visuelles | Non (liste simple avec logo) |
| Accès rapide depuis app | Non |

**Constat :** L'utilisateur avec 1 carte ne perçoit pas qu'il est dans un "wallet". L'utilisateur multi-cartes voit la liste mais sans styling "wallet".

### 9) Faisabilité mini-cartes

**Techniquement simple :**
- Les données sont disponibles : `membership.community.logo`, `membership.community.name`, `membership.status`, `membership.memberId`
- Le composant `CommunityHub.tsx` peut être stylé pour afficher des cartes empilées
- Inspiration : Google Wallet / Apple Wallet avec cartes inclinées ou empilées

---

## État Actuel — Ce Qui Existe

| Fonctionnalité | Statut | Fichier |
|----------------|--------|---------|
| Page Hub "Mes Cartes" | ✅ Existe | `CommunityHub.tsx` |
| Persistence du membership sélectionné | ✅ Existe | `AuthContext.tsx` |
| `selectMembership()` / `selectCommunity()` | ✅ Existe | `AuthContext.tsx` |
| Navigation vers Hub (2+ cartes) | ✅ Existe | `Login.tsx` |
| Ajout de carte | ✅ Existe | `AddCard.tsx` |

---

## Ce Qui Manque pour une Vraie Logique "Wallet"

| Manque | Impact | Priorité |
|--------|--------|----------|
| Accès au Hub depuis l'app (bouton/menu) | L'utilisateur ne peut pas changer de carte | Haute |
| Redirection Hub même avec 1 carte | L'utilisateur mono-carte ignore le wallet | Moyenne |
| Styling "mini-cartes" type wallet | Perception wallet faible | Basse |
| Libellé "Wallet" ou "Mes Cartes" visible | Renforce le mental model | Basse |

---

## Recommandations

### Court Terme (UI/Navigation légère)

**1. Ajouter un bouton "Mes Cartes" dans le header ou menu**

| Où | Comment |
|----|---------|
| `MobileLayout.tsx` | Ajouter icône wallet/cartes dans le header (visible si 2+ cartes) |
| Ou | Ajouter dans la bottom nav un item "Cartes" |

**Fichiers impactés :** `client/src/components/layouts/MobileLayout.tsx`

**2. Toujours rediriger vers le Hub après login**

Même avec 1 carte, afficher le Hub pour renforcer le mental model "wallet". L'utilisateur clique sur sa carte pour entrer.

**Fichiers impactés :** `client/src/pages/mobile/Login.tsx` (ligne 67-72)

**3. Ajouter un menu contextuel "Changer de carte"**

Dans le header de `MobileLayout`, afficher le logo du club actuel avec dropdown pour changer de carte (si 2+).

**Fichiers impactés :** `client/src/components/layouts/MobileLayout.tsx`

### Moyen Terme (Mini-cartes / Wallet visuel)

**4. Refonte visuelle du Hub en mode "Wallet"**

Remplacer la liste actuelle par des mini-cartes empilées :
- Carte en avant = club actif
- Cartes derrière = autres clubs
- Animation de swipe ou tap pour changer

**Inspiration :** Google Wallet, Apple Wallet, Stocard

**Fichiers impactés :** `client/src/pages/mobile/CommunityHub.tsx`

**5. Composant `MembershipCard` réutilisable**

Créer un composant stylé affichant :
- Logo club (gauche)
- Nom club (centre)
- Statut badge (droite)
- Couleur de fond personnalisée par club

**Fichiers à créer :** `client/src/components/MembershipCard.tsx`

---

## Liste des Fichiers/Routes Impactés

| Fichier | Modification suggérée |
|---------|----------------------|
| `client/src/pages/mobile/Login.tsx` | Forcer redirection Hub même avec 1 carte |
| `client/src/pages/mobile/CommunityHub.tsx` | Styling mini-cartes, animation wallet |
| `client/src/components/layouts/MobileLayout.tsx` | Bouton "Mes Cartes" / sélecteur de club |
| `client/src/contexts/AuthContext.tsx` | Aucun changement requis |
| `client/src/components/MembershipCard.tsx` | À créer (moyen terme) |

---

## Conclusion

Koomy possède les fondations techniques d'un wallet (Hub, persistence, multi-membership). Les améliorations prioritaires sont :

1. **Accès au Hub depuis l'app** (navigation)
2. **Redirection Hub systématique** (onboarding)
3. **Styling wallet visuel** (perception)

Ces modifications sont réalisables sans refonte massive et renforceront significativement la perception "wallet de cartes" auprès des utilisateurs.
