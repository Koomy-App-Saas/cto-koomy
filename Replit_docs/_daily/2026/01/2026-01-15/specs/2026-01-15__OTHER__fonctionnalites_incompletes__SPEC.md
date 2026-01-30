# Koomy - Fonctionnalités Incomplètes et Pages Manquantes

Ce document recense l'ensemble des fonctionnalités créées mais non fonctionnelles, ainsi que les pages menant à des erreurs 404 dans les différentes applications de Koomy.

**Dernière mise à jour : 20 décembre 2024**

---

## 1. Application Mobile Membres (`/app/*`)

### Pages manquantes (404) - RÉSOLU ✅

| Route | Description | Statut |
|-------|-------------|--------|
| `/app/:communityId/news/:articleId` | Page de détail d'un article d'actualité | ✅ Créé - NewsDetail.tsx |
| `/app/:communityId/events` | Liste des événements | ✅ Créé - Events.tsx |
| `/app/:communityId/events/:eventId` | Détail d'un événement | ✅ Créé - EventDetail.tsx |

### Fonctionnalités UI créées mais non fonctionnelles

| Page | Élément | Problème |
|------|---------|----------|
| **News.tsx** | Cartes d'actualités | ✅ Résolu - Navigation vers le détail fonctionnelle |
| **Home.tsx** | Cartes d'actualités récentes | ✅ Résolu - Navigation vers le détail fonctionnelle |
| **Home.tsx** | Section "Prochain Événement" | ✅ Résolu - Lien vers le détail + lien "Tous les événements" |
| **Messages.tsx** | Messagerie | Utilise des données mock (`MOCK_MESSAGES`), pas connectée au backend |
| **Support.tsx** | Création de ticket | Toast de confirmation mais pas de sauvegarde réelle en base de données |
| **Support.tsx** | FAQ | Utilise des données mock (`MOCK_FAQS`) |
| **Profile.tsx** | "Informations personnelles" | Clic possible mais aucune page de modification |
| **Profile.tsx** | "Notifications" | Clic possible mais aucune page de paramètres |
| **Profile.tsx** | "Sécurité et confidentialité" | Clic possible mais aucune page de paramètres |
| **Profile.tsx** | Bouton édition photo profil | Bouton affiché mais non fonctionnel |

---

## 2. Application Mobile Admin (`/app/:communityId/admin/*`)

### Fonctionnalités UI créées mais non fonctionnelles

| Page | Élément | Problème |
|------|---------|----------|
| **Scanner.tsx** | Scanner QR Code | Simulation uniquement (timeout de 3s puis affichage mock). Pas de vraie caméra ni lecture QR |
| **Home.tsx** | Statistiques (Messages, Présence) | Affichage de valeurs en dur ("0", "--") |
| **Messages.tsx** | Messagerie admin | Utilise des données mock, pas connectée au backend |

### Fonctionnalités implémentées ✅

| Page | Élément | Statut |
|------|---------|--------|
| **Tags.tsx** | Gestion des tags et segments | ✅ Fonctionnel - CRUD complet avec API backend |
| **Fundraising.tsx** | Gestion des collectes | ✅ Fonctionnel - CRUD complet avec API backend |

---

## 3. Back-Office Web Admin (`/admin/*`)

### Pages manquantes (404)

| Route | Description | Action requise |
|-------|-------------|----------------|
| `/admin/news/:articleId` | Édition d'un article spécifique | À créer |
| `/admin/settings` | Paramètres de la communauté | À créer |

### Fonctionnalités UI créées mais non fonctionnelles

| Page | Élément | Problème |
|------|---------|----------|
| **Dashboard.tsx** | Statistiques | Valeurs en dur (12,389 adhérents, 24 actualités, etc.) |
| **Dashboard.tsx** | "Nouvel Adhérent" (modal) | Formulaire affiché mais soumission non implémentée |
| **Dashboard.tsx** | "Rapport Mensuel" | Bouton sans action |
| **Dashboard.tsx** | Graphiques | Données mock statiques |
| **News.tsx** | Éditeur de texte riche | Placeholder "Éditeur de texte riche (WYSIWYG)" - pas d'éditeur réel |
| **News.tsx** | Création d'actualité | Modal avec formulaire mais pas de sauvegarde en base |
| **News.tsx** | Boutons Aperçu/Edit/Supprimer | Affichés mais non fonctionnels |
| **Events.tsx** | Création d'événement | Modal avec formulaire mais pas de sauvegarde en base |
| **Events.tsx** | Bouton "Scanner" sur les cartes | Navigation vers scanner mobile, pas adapté au desktop |
| **Members.tsx** | Actions sur les membres | Selon implémentation |
| **Messages.tsx** | Messagerie admin | Selon implémentation |
| **Admins.tsx** | Gestion des administrateurs | Selon implémentation |
| **Sections.tsx** | Gestion des sections | Selon implémentation |
| **Support.tsx** | Gestion des tickets | Selon implémentation |
| **Payments.tsx** | Gestion des paiements | Selon implémentation |

---

## 4. Portail Super Admin SaaS (`/platform/*`)

### Fonctionnalités implémentées ✅

| Page | Élément | Statut |
|------|---------|--------|
| **SuperDashboard.tsx** | Liste des communautés | ✅ Fonctionnel - Données réelles depuis la base |
| **SuperDashboard.tsx** | Création de client | ✅ Fonctionnel - Sauvegarde en base |
| **SuperDashboard.tsx** | Gestion des plans | ✅ Fonctionnel - CRUD complet |
| **SuperDashboard.tsx** | Full Access VIP | ✅ Fonctionnel - Attribution et gestion du statut VIP |
| **SuperDashboard.tsx** | White Label | ✅ Fonctionnel - Configuration complète (facturation, contrats, branding) |
| **SuperDashboard.tsx** | Badges GC/WL | ✅ Fonctionnel - Badge emerald pour Grands Comptes, violet pour White-Label |
| **SuperDashboard.tsx** | Création d'admin plateforme | ✅ Fonctionnel - Avec validation email @koomy.app |
| **SuperDashboard.tsx** | Logs d'audit | ✅ Fonctionnel - Traçabilité des actions admin |
| **SuperDashboard.tsx** | Platform Health | ✅ Fonctionnel - Métriques temps réel, jauges, tendances 30 jours |

### Fonctionnalités UI créées mais non fonctionnelles

| Page | Élément | Problème |
|------|---------|----------|
| **SuperDashboard.tsx** | Tickets support | Utilise `MOCK_TICKETS` - à connecter au backend |

---

## 5. Site Web Commercial (`/website/*`)

### Pages manquantes (404)

| Route | Description | Action requise |
|-------|-------------|----------------|
| `/website/support` | Centre d'aide | Lien présent dans le footer mais page inexistante |
| `/website/blog` | Blog | Lien présent dans le footer (# href) |
| `/website/privacy` | Confidentialité | Lien présent dans le footer (# href) |
| `/website/terms` | CGU | Lien présent dans le footer (# href) - à créer avec du texte standard adapté à l'Europe |
| `/website/legal` | Mentions légales | Lien présent dans le footer (# href) - à créer avec du texte standard adapté à l'Europe |
| `/website/contact` | Contact | Page non créée - formulaire nom/mail/entité/téléphone avec code pays, crée un ticket commercial |
| `/website/demo` | Demande de démo | Page non créée - la demande de démo mène au formulaire de contact |

### Fonctionnalités UI créées mais non fonctionnelles

| Page | Élément | Problème |
|------|---------|----------|
| **Home.tsx** | Bouton "App Store" | Lien visuel mais pas de vraie URL |
| **Home.tsx** | Bouton "Google Play" | Lien visuel mais pas de vraie URL |
| **Pricing.tsx** | Boutons "Commencer" | Redirigent vers `/website/signup` qui redirige vers admin |
| **Layout.tsx** | Liens réseaux sociaux (Twitter, LinkedIn, Instagram) | Liens `#` sans URL réelle |

---

## 6. Données Mock à Remplacer par des Vraies Données

### Fichiers concernés

| Fichier | Données mock | Impact |
|---------|--------------|--------|
| `client/src/lib/mockData.ts` | MOCK_USER, MOCK_NEWS, MOCK_EVENTS, MOCK_MESSAGES, MOCK_MEMBERS, SECTIONS | Utilisées dans certaines pages mobile et back-office |
| `client/src/lib/mockSupportData.ts` | MOCK_FAQS, MOCK_TICKETS | Support mobile et admin |

### Données maintenant réelles ✅

| Fonctionnalité | Statut |
|----------------|--------|
| Communautés (SuperDashboard) | ✅ Base de données PostgreSQL |
| Plans tarifaires | ✅ Base de données PostgreSQL |
| Utilisateurs plateforme | ✅ Base de données PostgreSQL |
| Promotions | ✅ Base de données PostgreSQL |
| Tags et segments | ✅ Base de données PostgreSQL |
| Collectes (Fundraising) | ✅ Base de données PostgreSQL |
| Sessions admin plateforme | ✅ Base de données PostgreSQL |
| Logs d'audit | ✅ Base de données PostgreSQL |

---

## 7. Priorités Recommandées

### Haute priorité (Fonctionnalités essentielles)

1. ~~**Page de détail d'article**~~ ✅ Résolu
2. **Création réelle d'actualités** - Le back-office ne sauvegarde pas les articles
3. **Création réelle d'événements** - Le back-office ne sauvegarde pas les événements
4. **Scanner QR réel** - Fonctionnalité clé pour les délégués

### Moyenne priorité (Amélioration UX)

5. **Messagerie connectée au backend** - Actuellement mock
6. ~~**Page événements mobile**~~ ✅ Résolu
7. **Modification du profil utilisateur** - Paramètres personnels

### Basse priorité (Pages institutionnelles)

8. **Pages légales du site web** - CGU, Mentions légales, Confidentialité
9. **Blog et Centre d'aide** - Contenu marketing
10. **Liens réseaux sociaux** - URLs à définir

---

## 8. Fonctionnalités Complètes et Opérationnelles

### Système Économique ✅

- **Stripe Billing** : Abonnements SaaS pour les communautés
- **Stripe Connect Express** : Paiements membres vers communautés
- **Transactions** : Suivi unifié (subscriptions, memberships, collections)
- **Frais plateforme** : 2% configurable par communauté

### White Label ✅

- **Configuration complète** : Tier (basic/standard/premium), mode facturation
- **Branding** : Nom app, couleur, logo, icône, emails personnalisés
- **Contrats manuels** : Frais setup, maintenance annuelle, facturation
- **Quotas membres** : Limites incluses, soft limit, frais additionnels

### Sécurité Plateforme ✅

- **Sessions** : Expiration 2h, renouvellement obligatoire, session unique par utilisateur
- **Audit logs** : Traçabilité complète des actions admin (login, logout, CRUD, etc.)
- **Restriction IP** : Accès limité à la France (header CloudFlare CF-IPCountry)
- **Validation email** : Domaine @koomy.app obligatoire pour admins plateforme
- **Rate limiting** : 5 tentatives échouées = blocage 15 min

### Grands Comptes (Enterprise) ✅

- **Type de compte** : STANDARD vs GRAND_COMPTE
- **Limites contractuelles** : contractMemberLimit remplace plan.maxMembers
- **Accès fonctionnalités** : Promotions, tags, collectes sans restriction de plan
- **Indicateurs visuels** : Badge GC (emerald) dans SuperDashboard
- **Distribution** : Champs préparés pour WHITE_LABEL_APP et KOOMY_WALLET

---

*Document mis à jour le 20 décembre 2024*
