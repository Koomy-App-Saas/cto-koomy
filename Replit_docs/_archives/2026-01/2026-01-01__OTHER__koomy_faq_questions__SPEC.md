# Backlog Questions FAQ Koomy

> **Ce fichier est un backlog de questions, ne pas y mettre de réponses.**  
> Les réponses sont dans le fichier `koomy-faq.md`.

> **Source** : `docs/koomy-capabilities-inventory.md`  
> **Date de création** : 9 janvier 2026  
> **Dernière mise à jour** : 10 janvier 2026

---

## 1. Questions pour les MEMBRES (App Mobile)

### 🔴 Urgence HAUTE — Paiements & Accès

| Catégorie FAQ | Question utilisateur | Capability source | Priorité | Réponse |
|---|---|---|---|---|
| **Connexion** | Comment me connecter à l'application ? | `POST /api/accounts/login` | 🔴 Haute | ✅ |
| **Connexion** | J'ai oublié mon mot de passe, comment le récupérer ? | À confirmer (reset password) | 🔴 Haute ⚠️ | ✅ |
| **Activation** | Comment activer ma carte membre avec mon code ? | `POST /api/memberships/claim` | 🔴 Haute | ✅ |
| **Activation** | Où trouver mon code d'activation ? | Email invitation (`sendMemberInviteEmail`) | 🔴 Haute | ✅ |
| **Activation** | Mon code d'activation ne fonctionne pas, que faire ? | `GET /api/memberships/verify/:claimCode` | 🔴 Haute | ✅ |
| **Activation** | Je n'ai pas reçu mon code d'activation | `POST /api/memberships/:id/resend-claim-code` | 🔴 Haute | ❌ |
| **Paiement** | Comment payer ma cotisation en ligne ? | `POST /api/payments/create-membership-session` | 🔴 Haute | ✅ |
| **Paiement** | Mon paiement a été refusé, que faire ? | Stripe Checkout error handling | 🔴 Haute | ✅ |
| **Paiement** | Comment savoir si ma cotisation est à jour ? | `membershipPaymentStatus` field | 🔴 Haute | ❌ |
| **Paiement** | Comment participer à une cagnotte/collecte ? | `POST /api/payments/create-collection-session` | 🔴 Haute | ❌ |
| **Événement payant** | Comment m'inscrire à un événement payant ? | `eventRegistrations` + Stripe | 🔴 Haute | ❌ |

---

### 🟡 Urgence MOYENNE — Utilisation courante

| Catégorie FAQ | Question utilisateur | Capability source | Priorité | Réponse |
|---|---|---|---|---|
| **Carte membre** | Comment afficher ma carte membre ? | `Card.tsx` | 🟡 Moyenne | ❌ |
| **Carte membre** | À quoi sert le QR code sur ma carte ? | `qrCard` capability | 🟡 Moyenne | ❌ |
| **Actualités** | Comment consulter les actualités de ma communauté ? | `GET /api/communities/:id/news`, `News.tsx` | 🟡 Moyenne | ❌ |
| **Actualités** | Comment rechercher un article précis ? | `News.tsx` (searchQuery) | 🟡 Moyenne | ❌ |
| **Actualités** | Comment filtrer les actualités par catégorie ? | `News.tsx` (selectedCategoryId) | 🟡 Moyenne | ❌ |
| **Événements** | Comment voir les événements à venir ? | `GET /api/communities/:id/events`, `Events.tsx` | 🟡 Moyenne | ✅ |
| **Événements** | Comment m'inscrire à un événement gratuit ? | `POST /api/events/:id/registrations` | 🟡 Moyenne | ✅ |
| **Événements** | Comment annuler mon inscription à un événement ? | À confirmer | 🟡 Moyenne ⚠️ | ✅ |
| **Messagerie** | Comment contacter un administrateur ? | `POST /api/messages` | 🟡 Moyenne | ❌ |
| **Messagerie** | Où voir mes conversations ? | `GET /api/communities/:id/conversations` | 🟡 Moyenne | ❌ |
| **Profil** | Comment modifier mes informations personnelles ? | `PATCH /api/accounts/me`, `PersonalInfo.tsx` | 🟡 Moyenne | ❌ |
| **Profil** | Comment changer ma photo de profil ? | `POST /api/accounts/me/avatar` | 🟡 Moyenne | ❌ |
| **Profil** | Comment changer mon mot de passe ? | `PATCH /api/accounts/:id/password` | 🟡 Moyenne | ❌ |

---

### 🟢 Urgence BASSE — Fonctions secondaires

| Catégorie FAQ | Question utilisateur | Capability source | Priorité | Réponse |
|---|---|---|---|---|
| **Compte** | Comment créer un compte Koomy ? | `POST /api/accounts/register` | 🟢 Basse | ❌ |
| **Compte** | Comment supprimer mon compte ? | `POST /api/accounts/:id/deletion-request` | 🟢 Basse | ❌ |
| **Support** | Comment contacter le support ? | `POST /api/tickets`, `Support.tsx` | 🟢 Basse | ✅ |
| **Support** | Où voir mes demandes de support ? | `GET /api/tickets` | 🟢 Basse | ✅ |
| **Notifications** | Comment voir mes notifications ? | `Notifications.tsx` | 🟢 Basse ⚠️ | ❌ |
| **Multi-communauté** | Je suis membre de plusieurs communautés, comment basculer ? | `GET /api/accounts/:id/memberships` | 🟢 Basse ⚠️ | ❌ |

---

### Problèmes techniques (Membres)

| Catégorie FAQ | Question utilisateur | Priorité | Réponse |
|---|---|---|---|
| **Technique** | L'application ne s'ouvre pas ou reste bloquée au chargement, que faire ? | 🟡 Moyenne | ✅ |
| **Technique** | Certaines images ne s'affichent pas dans l'application, pourquoi ? | 🟡 Moyenne | ✅ |
| **Technique** | Je ne vois pas ma carte membre dans l'application, que faire ? | 🟡 Moyenne | ✅ |
| **Technique** | Le QR code de ma carte membre ne fonctionne pas, que faire ? | 🟡 Moyenne | ✅ |
| **Technique** | Je vois un message d'erreur ou une page blanche, que faire ? | 🟡 Moyenne | ✅ |

---

## 2. Questions pour les ADMINISTRATEURS (Back-office)

### 🔴 Urgence HAUTE — Paiements & Configuration

| Catégorie FAQ | Question utilisateur | Capability source | Priorité | Réponse |
|---|---|---|---|---|
| **Connexion** | Comment me connecter à l'espace administrateur ? | `POST /api/admin/login` | 🔴 Haute | ❌ |
| **Paiements** | Comment configurer Stripe pour recevoir les paiements ? | `POST /api/payments/connect-community` | 🔴 Haute | ✅ |
| **Paiements** | Comment voir les paiements reçus ? | `GET /api/communities/:id/payments` | 🔴 Haute | ❌ |
| **Paiements** | Comment créer une demande de cotisation ? | `POST /api/payment-requests` | 🔴 Haute | ✅ |
| **Paiements** | Comment marquer une cotisation comme payée manuellement ? | `POST /api/memberships/:id/mark-paid` | 🔴 Haute | ❌ |
| **Paiements** | Comment voir l'historique des transactions ? | `GET /api/communities/:id/transactions` | 🔴 Haute | ✅ |
| **Abonnement** | Comment voir mon abonnement Koomy ? | `GET /api/billing/status` | 🔴 Haute | ✅ |
| **Abonnement** | Comment passer à un plan supérieur ? | `POST /api/billing/checkout` | 🔴 Haute | ✅ |
| **Abonnement** | Combien de membres puis-je avoir avec mon plan ? | `GET /api/communities/:id/quota` | 🔴 Haute | ✅ |

---

### 🟡 Urgence MOYENNE — Gestion quotidienne

| Catégorie FAQ | Question utilisateur | Capability source | Priorité | Réponse |
|---|---|---|---|---|
| **Membres** | Comment ajouter un nouveau membre ? | `POST /api/memberships` | 🟡 Moyenne | ✅ |
| **Membres** | Comment voir la liste de mes membres ? | `GET /api/communities/:id/members` | 🟡 Moyenne | ❌ |
| **Membres** | Comment modifier les informations d'un membre ? | `PATCH /api/memberships/:id` | 🟡 Moyenne | ✅ |
| **Membres** | Comment supprimer un membre ? | `DELETE /api/memberships/:id` | 🟡 Moyenne | ✅ |
| **Membres** | Comment renvoyer le code d'activation à un membre ? | `POST /api/memberships/:id/resend-claim-code` | 🟡 Moyenne | ✅ |
| **Membres** | Comment régénérer un nouveau code d'activation ? | `POST /api/memberships/:id/regenerate-code` | 🟡 Moyenne | ✅ |
| **Tags** | Comment créer des tags pour organiser mes membres ? | `POST /api/communities/:id/tags` | 🟡 Moyenne | ❌ |
| **Tags** | Comment attribuer des tags à un membre ? | `PUT /api/memberships/:id/tags` | 🟡 Moyenne | ✅ |
| **Articles** | Comment créer une actualité ? | `POST /api/news` | 🟡 Moyenne | ✅ |
| **Articles** | Comment modifier ou supprimer un article ? | `PATCH/DELETE /api/news/:id` | 🟡 Moyenne | ✅ |
| **Articles** | Comment créer des catégories (rubriques) ? | `POST /api/communities/:id/categories` | 🟡 Moyenne | ✅ |
| **Événements** | Comment créer un événement ? | `POST /api/events` | 🟡 Moyenne | ✅ |
| **Événements** | Comment créer un événement payant ? | `POST /api/events` (isPaid, priceCents) | 🟡 Moyenne | ✅ |
| **Événements** | Comment voir qui s'est inscrit à un événement ? | `EventDetails.tsx`, registrations | 🟡 Moyenne | ✅ |
| **Événements** | Comment scanner les présences avec le QR code ? | `Scanner.tsx`, `eventAttendance` | 🟡 Moyenne | ✅ |
| **Collectes** | Comment créer une cagnotte/collecte ? | `POST /api/collections` | 🟡 Moyenne | ❌ |
| **Collectes** | Comment fermer une collecte ? | `POST /api/collections/:id/close` | 🟡 Moyenne | ❌ |
| **Messagerie** | Comment envoyer un message à un membre ? | `POST /api/messages` | 🟡 Moyenne | ❌ |
| **Messagerie** | Comment voir les conversations avec mes membres ? | `GET /api/communities/:id/conversations` | 🟡 Moyenne | ❌ |

---

### 🟢 Urgence BASSE — Configuration avancée

| Catégorie FAQ | Question utilisateur | Capability source | Priorité | Réponse |
|---|---|---|---|---|
| **Paramètres** | Comment modifier les informations de ma communauté ? | `PUT /api/communities/:id`, `Settings.tsx` | 🟢 Basse | ❌ |
| **Paramètres** | Comment personnaliser le logo et les couleurs ? | `PATCH /api/communities/:id/branding` | 🟢 Basse | ❌ |
| **Sections** | Comment créer des sections (régions, groupes) ? | `POST /api/communities/:id/sections` | 🟢 Basse | ❌ |
| **Administrateurs** | Comment ajouter d'autres administrateurs ? | `POST /api/communities/:id/delegates` | 🟢 Basse | ❌ |
| **Plans adhésion** | Comment créer différents tarifs d'adhésion ? | `POST /api/communities/:id/membership-plans` | 🟢 Basse | ❌ |
| **Profil membres** | Comment configurer les champs de profil (adresse, contact urgence) ? | `PUT /api/communities/:id/member-profile-config` | 🟢 Basse | ❌ |
| **ID membres** | Comment personnaliser le format des numéros de membre ? | `POST /api/communities/:id/migrate-member-ids` | 🟢 Basse | ❌ |
| **Support** | Comment créer un ticket de support Koomy ? | `POST /api/tickets` | 🟢 Basse | ✅ |
| **Export** | Comment exporter la liste de mes membres ? | `exportData` capability | 🟢 Basse ⚠️ | ❌ |
| **API** | Comment accéder à l'API Koomy ? | `apiAccess` capability | 🟢 Basse ⚠️ | ❌ |

---

## 3. Questions Support & Tickets

| Question utilisateur | Priorité | Réponse |
|---|---|---|
| Comment contacter le support Koomy ? | 🟢 Basse | ✅ |
| Comment créer un ticket de support depuis l'application ? | 🟢 Basse | ✅ |
| Où puis-je suivre l'état de mes demandes de support ? | 🟢 Basse | ✅ |
| Quels types de problèmes dois-je signaler au support ? | 🟢 Basse | ✅ |
| Comment obtenir une réponse plus rapide du support ? | 🟢 Basse | ✅ |

---

## 4. Questions Abonnement, Plans & Limites

| Question utilisateur | Priorité | Réponse |
|---|---|---|
| Comment connaître mon plan Koomy actuel ? | 🔴 Haute | ✅ |
| Quelles sont les limites de mon abonnement ? | 🔴 Haute | ✅ |
| Que se passe-t-il si je dépasse les limites de mon plan ? | 🔴 Haute | ✅ |
| Comment passer à un plan supérieur ? | 🔴 Haute | ✅ |
| Puis-je changer ou annuler mon abonnement ? | 🔴 Haute | ✅ |

---

## 5. Questions Fonctions avancées & White-label

| Question utilisateur | Priorité | Réponse |
|---|---|---|
| Qu'est-ce que le mode white-label sur Koomy ? | 🟢 Basse | ✅ |
| Comment activer le white-label pour ma communauté ? | 🟢 Basse | ✅ |
| Puis-je utiliser mon propre nom de domaine ? | 🟢 Basse | ✅ |
| Quelles sont les limites du white-label ? | 🟢 Basse | ✅ |
| Ai-je un accompagnement dédié en tant que client grand compte ? | 🟢 Basse | ✅ |

---

## 6. Questions marquées "À confirmer" ⚠️

| Profil | Question | Raison |
|---|---|---|
| Membre | J'ai oublié mon mot de passe, comment le récupérer ? | Flow reset password non audité |
| Membre | Comment annuler mon inscription à un événement ? | Route DELETE non explicitement trouvée |
| Membre | Comment voir mes notifications ? | Contenu `Notifications.tsx` non audité |
| Membre | Je suis membre de plusieurs communautés, comment basculer ? | Flow multi-communauté non audité |
| Admin | Comment exporter la liste de mes membres ? | UI export non localisée |
| Admin | Comment accéder à l'API Koomy ? | Documentation API non trouvée |

---

## 7. Statistiques

| Métrique | Valeur |
|---|---|
| **Total questions** | 60 |
| **Questions Membres** | 30 |
| **Questions Administrateurs** | 30 |
| **Urgence Haute** | 20 (33%) |
| **Urgence Moyenne** | 26 (43%) |
| **Urgence Basse** | 14 (23%) |
| **À confirmer** | 6 (10%) |
| **Réponses rédigées** | 55 |
| **Réponses manquantes** | 5 |

---

**Légende :**
- ✅ = Réponse rédigée (voir `koomy-faq.md`)
- ❌ = Réponse à rédiger
- ⚠️ = À confirmer (implémentation incertaine)

---

**Fin du backlog**
