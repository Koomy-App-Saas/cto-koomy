# Port-Bouët FC - Club de Démonstration Sandbox

## Pourquoi ce club existe

Port-Bouët FC est un club de football fictif créé exclusivement pour le **bac à sable Replit**. Il permet de :

- Tester toutes les fonctionnalités de Koomy dans un environnement réaliste
- Valider le système d'événements V2 (RSVP, payants, ciblage, présences)
- Démontrer les capacités de la plateforme aux prospects
- Former les équipes sur l'utilisation de l'interface

## ⚠️ CONTRAINTE DE SÉCURITÉ ABSOLUE

Ce club est **EXCLUSIVEMENT** pour le bac à sable et **NE DOIT JAMAIS** être poussé en production.

### Garde-fous implémentés

1. **Variables d'environnement requises** :
   - `KOOMY_ENV=sandbox`
   - `SEED_SANDBOX=true`

2. **Vérifications automatiques** :
   - Si `NODE_ENV=production` → Le seed refuse de s'exécuter
   - Si `KOOMY_ENV=production` → Le seed refuse de s'exécuter
   - Si `SEED_SANDBOX !== "true"` → Le seed refuse de s'exécuter

3. **ID unique** : Le club utilise l'ID `sandbox-portbouet-fc` qui ne devrait jamais exister en production

## Comment lancer le seed

```bash
# Dans le terminal Replit
KOOMY_ENV=sandbox SEED_SANDBOX=true tsx scripts/seed-sandbox-portbouet.ts
```

Le script est **idempotent** : il peut être relancé plusieurs fois sans créer de doublons.

## Identifiants Admin (Sandbox uniquement)

| Rôle | Email | Mot de passe |
|------|-------|--------------|
| Président (Owner) | owner@portbouet-fc.sandbox | Test@12345! |
| Secrétaire | admin@portbouet-fc.sandbox | Test@12345! |
| Coach Seniors A | coach@portbouet-fc.sandbox | Test@12345! |
| Trésorier | tresorier@portbouet-fc.sandbox | Test@12345! |
| Coach U13 | coach2@portbouet-fc.sandbox | Test@12345! |

## Données générées

### Sections (13)

| Code | Nom | Type |
|------|-----|------|
| U7 | U7 - Baby Foot | youth |
| U9 | U9 | youth |
| U11 | U11 | youth |
| U13 | U13 | youth |
| U15 | U15 | youth |
| U17 | U17 | youth |
| U20 | U20 | youth |
| SEN-A | Seniors A | senior |
| SEN-B | Seniors B | senior |
| FEM | Féminines | senior |
| VET | Vétérans | veteran |
| STAFF | Staff | staff |
| BUREAU | Bureau | admin |

### Tags (11)

- Nouveau (vert)
- Blessé (rouge)
- Gardien (bleu)
- Défenseur (violet)
- Milieu (orange)
- Attaquant (rose)
- Capitaine (jaune)
- Bénévole (turquoise)
- ArbitreClub (indigo)
- EnRetardCotisation (rouge foncé)
- ÀJourCotisation (vert foncé)

### Plans de cotisation (6)

| Plan | Montant | Cible |
|------|---------|-------|
| Licence Jeunes (U7-U17) | 30€ | Catégories jeunes |
| Licence U20 | 40€ | U20 |
| Licence Seniors | 60€ | Seniors A/B |
| Licence Féminines | 50€ | Équipe féminine |
| Licence Vétérans | 35€ | Vétérans |
| Staff/Bureau | 10€ | Encadrement |

### Membres (~133)

Répartition par section avec :
- Noms ivoiriens réalistes
- Téléphones au format ivoirien (+225)
- Emails fictifs (@sandbox.portbouet-fc.test)
- Statuts de cotisation variés (65% à jour, 25% en attente, 10% en retard)
- Tags de poste assignés (Gardien, Défenseur, Milieu, Attaquant)

### Événements V2 (12)

| Événement | Type | Payant | RSVP | Ciblage |
|-----------|------|--------|------|---------|
| Entraînement U13 | training | ❌ | REQUIRED | Section U13 |
| Match amical Seniors A | match | ❌ | OPTIONAL | Section SEN-A |
| Stage vacances U11 | stage | ✅ 10€ | REQUIRED | Section U11 |
| Tournoi Féminines | tournament | ✅ 5€ | REQUIRED | Section FEM |
| Réunion Bureau | meeting | ❌ | REQUIRED | Section BUREAU |
| Collecte équipement | other | ❌ | OPTIONAL | Tag Bénévole |
| Gala annuel | gala | ✅ 25€ | REQUIRED | Tous (capacité: 150) |
| Entraînement Vétérans | training | ❌ | OPTIONAL | Section VET |
| Tournoi U17 | tournament | ❌ | REQUIRED | Section U17 |
| Formation arbitrage | training | ❌ | REQUIRED | Tag ArbitreClub |
| Match de charité | match | ❌ | OPTIONAL | Tous |
| Stage gardiens | stage | ✅ 15€ | REQUIRED | Tag Gardien (capacité: 12) |

## Comment tester

### Ciblage d'événements

1. Connectez-vous en tant qu'admin (owner@portbouet-fc.sandbox)
2. Allez dans "Événements"
3. Créez un nouvel événement avec ciblage :
   - Choisir "Section" et sélectionner U13
   - Ou choisir "Tags" et sélectionner "Gardien"
4. Vérifiez que seuls les membres ciblés voient l'événement

### RSVP

1. Consultez les événements existants
2. Vérifiez les compteurs d'inscriptions (GOING, NOT_GOING, PENDING)
3. Testez le changement de statut via l'interface membre

### Événements payants

1. Les événements payants sont marqués avec un prix
2. Le flow de paiement utilise Stripe Checkout (mode test)
3. Les inscriptions payantes ont un statut de paiement distinct

### Scan de présence

1. Utilisez la fonctionnalité de scan QR
2. Consultez la liste des présents pour un événement
3. Vérifiez les enregistrements d'attendance générés

### Test des quotas (Plan PLUS)

1. Changez le plan du club de PRO à PLUS
2. Créez plus de 2 événements payants
3. Vérifiez que le quota est atteint et bloque la création

## Nettoyage

Pour supprimer toutes les données du club sandbox :

```sql
-- À exécuter avec précaution !
DELETE FROM event_attendance WHERE event_id IN (SELECT id FROM events WHERE community_id = 'sandbox-portbouet-fc');
DELETE FROM event_registrations WHERE event_id IN (SELECT id FROM events WHERE community_id = 'sandbox-portbouet-fc');
DELETE FROM events WHERE community_id = 'sandbox-portbouet-fc';
DELETE FROM member_tags WHERE membership_id IN (SELECT id FROM user_community_memberships WHERE community_id = 'sandbox-portbouet-fc');
DELETE FROM user_community_memberships WHERE community_id = 'sandbox-portbouet-fc';
DELETE FROM sections WHERE community_id = 'sandbox-portbouet-fc';
DELETE FROM tags WHERE community_id = 'sandbox-portbouet-fc';
DELETE FROM membership_plans WHERE community_id = 'sandbox-portbouet-fc';
DELETE FROM communities WHERE id = 'sandbox-portbouet-fc';
```

## Support

Pour toute question sur ce club de démonstration, contactez l'équipe technique Koomy.
