# Scénario 02 - APER Robertsau
## Rapport de données de test Sandbox

**Date de génération**: 18 janvier 2026  
**Script source**: `scripts/seed-sandbox-aper-robertsau.ts`

---

## 1. Organisation

| Propriété | Valeur |
|-----------|--------|
| **Tenant ID** | `sbx_aper_robertsau` |
| **Nom** | Association des Parents d'Élèves Robertsau |
| **Slug** | `sbx_aper_robertsau` |
| **Type** | Association de parents d'élèves |
| **Ville** | Strasbourg |
| **Pays** | France |
| **Couleur principale** | `#2E6FBA` (bleu) |
| **Couleur secondaire** | `#F2B705` (jaune/or) |
| **Statut abonnement** | ACTIVE |

---

## 2. Comptes Administrateurs (2)

| Prénom | Nom | Email | Mot de passe | Rôle | Fonction |
|--------|-----|-------|--------------|------|----------|
| Claire | Meyer | `admin+aper.robertsau@koomy-sandbox.local` | `SandboxDemo2024!` | `support_admin` | Présidente APER |
| Hakim | Benali | `staff+aper.robertsau@koomy-sandbox.local` | `SandboxDemo2024!` | `content_admin` | Responsable événements |

---

## 3. Plans d'Adhésion (3)

| Nom du plan | Prix | Durée | Description |
|-------------|------|-------|-------------|
| Adhésion 2025/2026 | 12,00 € | 12 mois | Adhésion annuelle standard pour les familles |
| Adhésion Solidaire | 5,00 € | 12 mois | Tarif réduit pour familles en difficulté |
| Soutien / Don | 25,00 € | 12 mois | Contribution de soutien pour les actions de l'association |

---

## 4. Comptes Membres (18)

### Distribution des statuts de cotisation
- **À jour (up_to_date)**: 10 membres
- **En attente (pending)**: 5 membres  
- **En retard (late)**: 3 membres

### Liste complète des membres

| # | Email | Mot de passe | Plan | Statut cotisation |
|---|-------|--------------|------|-------------------|
| 01 | `member+aper01@koomy-sandbox.local` | `SandboxDemo2024!` | Adhésion 2025/2026 | `up_to_date` |
| 02 | `member+aper02@koomy-sandbox.local` | `SandboxDemo2024!` | Adhésion 2025/2026 | `up_to_date` |
| 03 | `member+aper03@koomy-sandbox.local` | `SandboxDemo2024!` | Adhésion 2025/2026 | `up_to_date` |
| 04 | `member+aper04@koomy-sandbox.local` | `SandboxDemo2024!` | Adhésion 2025/2026 | `up_to_date` |
| 05 | `member+aper05@koomy-sandbox.local` | `SandboxDemo2024!` | Adhésion 2025/2026 | `up_to_date` |
| 06 | `member+aper06@koomy-sandbox.local` | `SandboxDemo2024!` | Adhésion 2025/2026 | `up_to_date` |
| 07 | `member+aper07@koomy-sandbox.local` | `SandboxDemo2024!` | Adhésion 2025/2026 | `up_to_date` |
| 08 | `member+aper08@koomy-sandbox.local` | `SandboxDemo2024!` | Adhésion 2025/2026 | `up_to_date` |
| 09 | `member+aper09@koomy-sandbox.local` | `SandboxDemo2024!` | Adhésion 2025/2026 | `up_to_date` |
| 10 | `member+aper10@koomy-sandbox.local` | `SandboxDemo2024!` | Adhésion 2025/2026 | `up_to_date` |
| 11 | `member+aper11@koomy-sandbox.local` | `SandboxDemo2024!` | Adhésion Solidaire | `pending` |
| 12 | `member+aper12@koomy-sandbox.local` | `SandboxDemo2024!` | Adhésion Solidaire | `pending` |
| 13 | `member+aper13@koomy-sandbox.local` | `SandboxDemo2024!` | Adhésion Solidaire | `pending` |
| 14 | `member+aper14@koomy-sandbox.local` | `SandboxDemo2024!` | Adhésion Solidaire | `pending` |
| 15 | `member+aper15@koomy-sandbox.local` | `SandboxDemo2024!` | Adhésion Solidaire | `pending` |
| 16 | `member+aper16@koomy-sandbox.local` | `SandboxDemo2024!` | Adhésion 2025/2026 | `late` |
| 17 | `member+aper17@koomy-sandbox.local` | `SandboxDemo2024!` | Adhésion 2025/2026 | `late` |
| 18 | `member+aper18@koomy-sandbox.local` | `SandboxDemo2024!` | Adhésion 2025/2026 | `late` |

> **Note**: Les prénoms et noms des membres sont générés aléatoirement à l'exécution du script à partir de listes de prénoms/noms alsaciens typiques.

---

## 5. Événements (4)

*Dates calculées par rapport à la date d'exécution du script*

| Titre | Type | Lieu | Date relative | Statut | RSVP | Capacité | Payant |
|-------|------|------|---------------|--------|------|----------|--------|
| Réunion de rentrée des parents | meeting | Salle polyvalente, École Robertsau | J-14 (passé) | PUBLISHED | OPTIONAL | 80 | Non |
| Fête de l'école - Kermesse | gathering | Cour de l'école | J+7 | DRAFT | REQUIRED | 200 | Oui |
| Atelier lecture parents-enfants | workshop | Bibliothèque municipale | J+21 | DRAFT | REQUIRED | 25 | Non |
| Conférence Bien-être à l'école | conference | Amphithéâtre collège | J+5 | DRAFT | OPTIONAL | 100 | Non |

### Inscriptions aux événements
- Événements passés : 40% des membres inscrits automatiquement
- Événements futurs : 20% des membres inscrits automatiquement

---

## 6. Articles / Actualités (5)

*Dates calculées par rapport à la date d'exécution du script*

| Titre | Catégorie | Date publication | Statut |
|-------|-----------|------------------|--------|
| Bienvenue sur l'espace APER Robertsau ! | Vie associative | J-30 | published |
| Calendrier des événements 2025-2026 | Vie scolaire | J-25 | published |
| Guide d'utilisation de votre carte de membre | Informations | J-20 | published |
| Contacts et permanences de l'association | Vie associative | J-15 | published |
| Compte-rendu de la réunion de rentrée | Vie scolaire | J-7 | published |

---

## 7. Récapitulatif des accès

### Pour tester le backoffice admin
```
URL: backoffice-sandbox.koomy.app
Email: admin+aper.robertsau@koomy-sandbox.local
Mot de passe: SandboxDemo2024!
```

### Pour tester le wallet membre
```
URL: sandbox.koomy.app
Email: member+aper01@koomy-sandbox.local
Mot de passe: SandboxDemo2024!
```

### Pour tester un membre en retard de paiement
```
URL: sandbox.koomy.app
Email: member+aper16@koomy-sandbox.local
Mot de passe: SandboxDemo2024!
```

---

## 8. Exécution du script

```bash
# Variables requises
export KOOMY_ENV=sandbox
export SEED_SANDBOX=true

# Exécution
npx tsx scripts/seed-sandbox-aper-robertsau.ts
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
- **Rôles admin**: Utilise uniquement les rôles existants (`support_admin`, `content_admin`) - pas de `super_admin` conformément à la spécification
- **Module notifications**: Absent du schéma, étape ignorée
- **Validation finale**: Le script vérifie automatiquement que exactement 2 admins ont été créés et qu'aucun nouveau rôle n'a été ajouté

---

*Généré automatiquement - Koomy Sandbox Environment*
