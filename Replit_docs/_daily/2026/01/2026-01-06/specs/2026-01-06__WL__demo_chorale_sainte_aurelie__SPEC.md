# Scénario 03 – Chorale Sainte-Aurélie Strasbourg
## Rapport de données de test Sandbox

**Date de génération**: 18 janvier 2026  
**Script source**: `scripts/seed-sandbox-chorale-sainte-aurelie.ts`

---

## 1. Organisation

| Propriété | Valeur |
|-----------|--------|
| **Tenant ID** | `sbx_chorale_sainte_aurelie` |
| **Nom** | Chorale Sainte-Aurélie Strasbourg |
| **Slug** | `sbx_chorale_sainte_aurelie` |
| **Type** | Association culturelle / Musique |
| **Ville** | Strasbourg (Centre) |
| **Pays** | France |
| **Couleur principale** | `#6A1B9A` (violet) |
| **Couleur secondaire** | `#F5C542` (doré) |
| **Statut abonnement** | ACTIVE |

---

## 2. Comptes Administrateurs (2)

| Prénom | Nom | Email | Mot de passe | Rôle | Fonction |
|--------|-----|-------|--------------|------|----------|
| Élodie | Schmitt | `admin+chorale.aurelie@koomy-sandbox.local` | `SandboxDemo2024!` | `support_admin` | Présidente Chorale |
| Pierre | Vogel | `staff+chorale.aurelie@koomy-sandbox.local` | `SandboxDemo2024!` | `content_admin` | Responsable événements |

> **NO NEW ROLES CREATED** - Seuls les rôles existants sont utilisés.

---

## 3. Plans d'Adhésion (3)

| Nom du plan | Prix | Durée | Description |
|-------------|------|-------|-------------|
| Adhésion Choriste 2025/2026 | 45,00 € | 12 mois | Adhésion annuelle pour les choristes actifs |
| Adhésion Étudiant | 25,00 € | 12 mois | Tarif réduit pour étudiants et moins de 26 ans |
| Soutien / Donateur | 80,00 € | 12 mois | Contribution de soutien pour les mécènes et donateurs |

---

## 4. Comptes Membres (24)

### Distribution des statuts de cotisation
- **À jour (up_to_date)**: 16 membres
- **En attente (pending)**: 5 membres  
- **En retard (late)**: 3 membres

### Liste complète des membres

| # | Email | Mot de passe | Plan | Statut cotisation |
|---|-------|--------------|------|-------------------|
| 01 | `member+chorale01@koomy-sandbox.local` | `SandboxDemo2024!` | Adhésion Choriste 2025/2026 | `up_to_date` |
| 02 | `member+chorale02@koomy-sandbox.local` | `SandboxDemo2024!` | Adhésion Choriste 2025/2026 | `up_to_date` |
| 03 | `member+chorale03@koomy-sandbox.local` | `SandboxDemo2024!` | Adhésion Choriste 2025/2026 | `up_to_date` |
| 04 | `member+chorale04@koomy-sandbox.local` | `SandboxDemo2024!` | Adhésion Choriste 2025/2026 | `up_to_date` |
| 05 | `member+chorale05@koomy-sandbox.local` | `SandboxDemo2024!` | Adhésion Choriste 2025/2026 | `up_to_date` |
| 06 | `member+chorale06@koomy-sandbox.local` | `SandboxDemo2024!` | Adhésion Choriste 2025/2026 | `up_to_date` |
| 07 | `member+chorale07@koomy-sandbox.local` | `SandboxDemo2024!` | Adhésion Choriste 2025/2026 | `up_to_date` |
| 08 | `member+chorale08@koomy-sandbox.local` | `SandboxDemo2024!` | Adhésion Choriste 2025/2026 | `up_to_date` |
| 09 | `member+chorale09@koomy-sandbox.local` | `SandboxDemo2024!` | Adhésion Choriste 2025/2026 | `up_to_date` |
| 10 | `member+chorale10@koomy-sandbox.local` | `SandboxDemo2024!` | Adhésion Choriste 2025/2026 | `up_to_date` |
| 11 | `member+chorale11@koomy-sandbox.local` | `SandboxDemo2024!` | Adhésion Choriste 2025/2026 | `up_to_date` |
| 12 | `member+chorale12@koomy-sandbox.local` | `SandboxDemo2024!` | Adhésion Choriste 2025/2026 | `up_to_date` |
| 13 | `member+chorale13@koomy-sandbox.local` | `SandboxDemo2024!` | Adhésion Choriste 2025/2026 | `up_to_date` |
| 14 | `member+chorale14@koomy-sandbox.local` | `SandboxDemo2024!` | Soutien / Donateur | `up_to_date` |
| 15 | `member+chorale15@koomy-sandbox.local` | `SandboxDemo2024!` | Soutien / Donateur | `up_to_date` |
| 16 | `member+chorale16@koomy-sandbox.local` | `SandboxDemo2024!` | Soutien / Donateur | `up_to_date` |
| 17 | `member+chorale17@koomy-sandbox.local` | `SandboxDemo2024!` | Adhésion Étudiant | `pending` |
| 18 | `member+chorale18@koomy-sandbox.local` | `SandboxDemo2024!` | Adhésion Étudiant | `pending` |
| 19 | `member+chorale19@koomy-sandbox.local` | `SandboxDemo2024!` | Adhésion Étudiant | `pending` |
| 20 | `member+chorale20@koomy-sandbox.local` | `SandboxDemo2024!` | Adhésion Étudiant | `pending` |
| 21 | `member+chorale21@koomy-sandbox.local` | `SandboxDemo2024!` | Adhésion Étudiant | `pending` |
| 22 | `member+chorale22@koomy-sandbox.local` | `SandboxDemo2024!` | Adhésion Choriste 2025/2026 | `late` |
| 23 | `member+chorale23@koomy-sandbox.local` | `SandboxDemo2024!` | Adhésion Choriste 2025/2026 | `late` |
| 24 | `member+chorale24@koomy-sandbox.local` | `SandboxDemo2024!` | Adhésion Choriste 2025/2026 | `late` |

> **Note**: Les prénoms et noms des membres sont générés à partir de listes de prénoms/noms alsaciens typiques.

---

## 5. Événements (8)

### Répétitions (4) - 50% des membres inscrits

| Titre | Type | Lieu | Date relative | RSVP | Capacité |
|-------|------|------|---------------|------|----------|
| Répétition hebdomadaire – Semaine 1 | rehearsal | Salle paroissiale Sainte-Aurélie | J-21 (passé) | OPTIONAL | 40 |
| Répétition hebdomadaire – Semaine 2 | rehearsal | Salle paroissiale Sainte-Aurélie | J-14 (passé) | OPTIONAL | 40 |
| Répétition hebdomadaire – Semaine 3 | rehearsal | Salle paroissiale Sainte-Aurélie | J+7 | OPTIONAL | 40 |
| Répétition hebdomadaire – Semaine 4 | rehearsal | Salle paroissiale Sainte-Aurélie | J+14 | OPTIONAL | 40 |

### Concerts et événements (4) - 30% des membres inscrits

| Titre | Type | Lieu | Date relative | RSVP | Capacité | Payant |
|-------|------|------|---------------|------|----------|--------|
| Concert d'hiver – Strasbourg | concert | Église Sainte-Aurélie | J+30 | REQUIRED | 150 | Oui |
| Concert solidaire – Maison de quartier | concert | Maison de quartier Elsau | J-7 (passé) | REQUIRED | 80 | Non |
| Répétition générale – Concert d'hiver | concert | Église Sainte-Aurélie | J+28 | REQUIRED | 50 | Non |
| Afterwork Chorale – Accueil nouveaux | social | Brasserie Au Canon, Strasbourg | J+10 | OPTIONAL | 30 | Non |

### Statistiques inscriptions
- **Répétitions**: 50% des membres inscrits automatiquement (~12 membres/répétition)
- **Concerts/événements**: 30% des membres inscrits automatiquement (~7 membres/événement)

---

## 6. Articles / Actualités (6)

| Titre | Catégorie | Date publication | Auteur |
|-------|-----------|------------------|--------|
| Bienvenue à la Chorale Sainte-Aurélie ! | Vie associative | J-30 | Élodie Schmitt |
| Planning du mois | Informations | J-25 | Pierre Vogel |
| Règles de participation aux répétitions | Vie associative | J-20 | Élodie Schmitt |
| Comment accéder à sa carte membre | Informations | J-15 | Élodie Schmitt |
| Programme du concert d'hiver | Événements | J-7 | Pierre Vogel |
| Appel aux bénévoles – Logistique concert | Vie associative | J-3 | Pierre Vogel |

---

## 7. Récapitulatif des accès

### Pour tester le backoffice admin
```
URL: backoffice-sandbox.koomy.app
Email: admin+chorale.aurelie@koomy-sandbox.local
Mot de passe: SandboxDemo2024!
```

### Pour tester le wallet membre (choriste actif)
```
URL: sandbox.koomy.app
Email: member+chorale01@koomy-sandbox.local
Mot de passe: SandboxDemo2024!
```

### Pour tester un membre étudiant en attente
```
URL: sandbox.koomy.app
Email: member+chorale17@koomy-sandbox.local
Mot de passe: SandboxDemo2024!
```

### Pour tester un membre en retard de paiement
```
URL: sandbox.koomy.app
Email: member+chorale22@koomy-sandbox.local
Mot de passe: SandboxDemo2024!
```

---

## 8. Exécution du script

```bash
# Variables requises
export KOOMY_ENV=sandbox
export SEED_SANDBOX=true

# Exécution
npx tsx scripts/seed-sandbox-chorale-sainte-aurelie.ts
```

### Protections sandbox
Le script vérifie obligatoirement :
1. `NODE_ENV` ≠ production
2. `APP_ENV` ≠ production  
3. `KOOMY_ENV` = sandbox (obligatoire)
4. `SEED_SANDBOX` = true (obligatoire)
5. `DATABASE_URL` ne contient pas de patterns production
6. L'identité de la base de données au runtime

---

## 9. Notes techniques

- **Idempotence**: Le script peut être exécuté plusieurs fois sans créer de doublons (upsert sur slug/email, matching titre+date pour événements/articles)
- **Rôles admin**: Utilise uniquement les rôles existants (`support_admin`, `content_admin`) - **NO NEW ROLES CREATED**
- **Module notifications**: Absent du schéma, étape ignorée
- **Validation finale**: Le script vérifie automatiquement que exactement 2 admins ont été créés et qu'aucun nouveau rôle n'a été ajouté
- **Cartes wallet**: Les membres sont automatiquement liés au tenant et bénéficient de la carte standard selon le mécanisme existant

---

## 10. Résumé final

| Élément | Quantité |
|---------|----------|
| Tenant | 1 (`sbx_chorale_sainte_aurelie`) |
| Admins | 2 |
| Membres | 24 |
| Plans d'adhésion | 3 |
| Événements | 8 (4 répétitions + 4 concerts) |
| Articles | 6 |
| Nouveaux rôles créés | **0** |

---

*Généré automatiquement - Koomy Sandbox Environment*
