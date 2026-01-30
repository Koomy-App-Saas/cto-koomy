# SANDBOX White-Label Audit Report

**Date**: 2026-01-18  
**Scope**: Audit READ-ONLY de la sandbox pour cartographier UNSA/Lidl  
**Objectif**: Préparer le host `demo-wl.koomy.app`

---

## Résumé Exécutif

### Risques Identifiés

| Niveau | Risque | Description |
|--------|--------|-------------|
| **CRITIQUE** | PII réelles | 19 membres UNSA Lidl avec emails personnels réels (gmail, orange, yahoo, lidl.fr) et vrais noms |
| **ÉLEVÉ** | Code hardcodé | 13 fichiers contiennent des références UNSA/Lidl hardcodées |
| **ÉLEVÉ** | Pages légales dédiées | 3 fichiers légaux spécifiques UNSA Lidl (Terms, Privacy, Delete Account) |
| **MOYEN** | Custom domain | `unsalidlfrance` configuré comme custom_domain |
| **MOYEN** | Assets brandés | 3 logos/icons UNSA Lidl stockés dans Object Storage |
| **FAIBLE** | Stripe non connecté | Aucun compte Stripe Connect lié (pas de risque de paiement live) |

### Next Steps Recommandés

1. **URGENT**: Anonymiser ou purger les données PII réelles du tenant UNSA Lidl
2. **Option A (Recommandée)**: Archiver UNSA Lidl et créer un nouveau tenant WL de démo propre
3. **Option B**: Remodeler UNSA Lidl en remplaçant toutes les PII par des données fictives
4. Nettoyer les références hardcodées dans le code
5. Créer le host `demo-wl.koomy.app` avec un tenant de démo générique

---

## 1. Tenants Présents en Sandbox

| ID | Nom | Type | White-Label | Custom Domain | Statut | Plan |
|----|-----|------|-------------|---------------|--------|------|
| `2b129b86-3a39-4d19-a6fc-3d0cec067a79` | **UNSA Lidl** | union | **Oui** (premium) | `unsalidlfrance` | active | whitelabel |
| `sandbox-portbouet-fc` | Port-Bouët FC | - | Non | - | active | starter |
| `82590b15-9394-4cfe-b99a-8a3b8df1e701` | Club d'Échecs de Paris | - | Non | - | active | - |

### Tenant Suspect: UNSA Lidl

| Attribut | Valeur |
|----------|--------|
| **Tenant ID** | `2b129b86-3a39-4d19-a6fc-3d0cec067a79` |
| **Nom** | UNSA Lidl |
| **Type** | union (syndicat) |
| **Catégorie** | professionnel |
| **Créé le** | 2025-11-30 12:10:17 |
| **Account Type** | GRAND_COMPTE |
| **Billing Mode** | manual_contract |
| **White-Label Tier** | premium |
| **Member ID Prefix** | UNSALIDL |
| **Member ID Counter** | 89 |
| **Max Members Allowed** | 2000 |
| **Web App URL** | https://unsalidlfrance.koomy.app |
| **Android Store URL** | https://play.google.com/store/apps/details?id=app.koomy.unsalidl |
| **Full Access Granted** | 2025-12-18 (Contrat Grand Compte White Label) |

---

## 2. Domaines / Hosts / Sous-domaines

### Mapping Host → Tenant

Le système utilise le champ `custom_domain` dans la table `communities` pour mapper les hosts.

| Custom Domain | Tenant | Web App URL | Conflit demo-wl? |
|---------------|--------|-------------|------------------|
| `unsalidlfrance` | UNSA Lidl | https://unsalidlfrance.koomy.app | Non |
| *(aucun)* | Port-Bouët FC | - | Non |
| *(aucun)* | Club d'Échecs | - | Non |

**Conflit `demo-wl.koomy.app`**: Aucun conflit détecté. Ce host n'existe pas encore.

---

## 3. Comptes Admins

### Admins UNSA Lidl (1)

| Email | Rôle | Admin Role | Display Name |
|-------|------|------------|--------------|
| `mlaminesylla@yahoo.fr` | super_admin | super_admin | Mohamed Sylla |

> ⚠️ **ALERTE PII**: Email `@yahoo.fr` = email personnel réel (pas @koomy-sandbox.local)

### Admins Autres Tenants (3)

| Email | Rôle | Tenant |
|-------|------|--------|
| `owner@portbouet-fc.sandbox` | super_admin | Port-Bouët FC |
| `admin@portbouet-fc.sandbox` | content_admin | Port-Bouët FC |
| `tresorier@portbouet-fc.sandbox` | finance_admin | Port-Bouët FC |

> ✅ Ces emails sont de type sandbox (`.sandbox`)

---

## 4. Membres & Risques PII

### Distribution par Tenant

| Tenant | Membres | Domaines Email Distincts |
|--------|---------|--------------------------|
| UNSA Lidl | 19 | 9 |
| Port-Bouët FC | 148 | 2 |
| Club d'Échecs | 1 | 1 |

### UNSA Lidl - Distribution Emails

| Domaine | Nombre | Type |
|---------|--------|------|
| `gmail.com` | 9 | **Personnel** |
| `orange.fr` | 2 | **Personnel** |
| `hotmail.com` | 1 | **Personnel** |
| `hotmail.fr` | 1 | **Personnel** |
| `yahoo.fr` | 1 | **Personnel** |
| `live.fr` | 1 | **Personnel** |
| `lidl.fr` | 1 | **Professionnel** |
| `koomy.app` | 1 | Test |
| `orange.f` (typo) | 1 | **Personnel** |
| *(null)* | 1 | Invalide |

### UNSA Lidl - Échantillon Membres (PII RÉELLES)

| Email | Nom Complet | Téléphone |
|-------|-------------|-----------|
| `Jamyson.bordey@gmail.com` | Jamyson BORDEY | - |
| `Jose.Braz@lidl.fr` | José BRAZ | - |
| `bintou.mamodali24@gmail.com` | Bintou Momad'Ali | - |
| `celyv@live.fr` | Celine ROBLOT | - |
| `dufourcet.sandrine@orange.fr` | Sandrine DUFFOURCET | - |
| `karima.chamsy10@gmail.com` | Karima KADDAR | - |
| `rachguercif@gmail.com` | Rachid Chiguer | - |
| ... | ... | ... |

> ⛔ **CRITIQUE**: Ces données sont des PII réelles (vrais noms, vrais emails personnels). Elles doivent être anonymisées ou purgées avant toute démonstration.

---

## 5. Paiements / Stripe

### Configuration Stripe

| Élément | État |
|---------|------|
| STRIPE_SECRET_KEY | Non défini (vide) |
| STRIPE_WEBHOOK_SECRET | Défini |
| Mode | Indéterminé (pas de clé) |

### UNSA Lidl - IDs Stripe

| Champ | Valeur |
|-------|--------|
| `stripe_connect_account_id` | *(null)* |
| `stripe_customer_id` | *(null)* |
| `stripe_subscription_id` | *(null)* |

> ✅ Aucun compte Stripe Connect lié. Pas de risque de paiement live.

### Transactions

- Table `transactions`: Vide ou inexistante
- Table `payments`: 0 enregistrements

---

## 6. Emails & Templates

### Configuration

| Élément | État |
|---------|------|
| Provider | SendGrid (configuré) |
| Table `email_templates` | Vide ou inexistante |

### Brand Config UNSA Lidl

```json
{
  "appName": "Unsa idl",
  "emailFromName": "UNSA Lidl France",
  "emailFromAddress": "support@koomy.app",
  "replyTo": "ritesmassamba@gmail.com"
}
```

> ⚠️ `replyTo` contient un email personnel réel (`ritesmassamba@gmail.com`)

---

## 7. Assets (Logos/Images)

### UNSA Lidl Assets

| Type | Chemin |
|------|--------|
| Logo principal | `/objects/public/logos/8164ea19-59ed-4394-8cea-05cfce316d42.png` |
| Brand logo WL | `/objects/public/white-label/65d5ff48-a23f-4ada-8fde-9fb3a11faaf9.png` |
| App icon | `/objects/public/white-label/930a7d3d-b90f-4d9f-a1a3-51b935eb4040.png` |

Ces assets sont stockés dans R2/Object Storage (`/objects/public/`).

---

## 8. Contenu UNSA Lidl

### Événements (3)

1. Assemblée Générale 2024
2. test Venet
3. Négociations de Salaires, Primes et autres avantages NAO

### Articles (6)

1. Bienvenue sur Unsa Lidl x Koomy
2. À Chanteloup-les-Vignes, une équipe unie et engagée !
3. Résultats du sondage UNSA Lidl
4. 𝐂𝐞 𝐬𝐨𝐧𝐝𝐚𝐠𝐞 𝐞𝐬𝐭 𝐮𝐧 𝐚𝐜𝐭𝐞 𝐜𝐨𝐥𝐥𝐞𝐜𝐭𝐢𝐟.
5. Réunion du CSE Central au siège de Lidl France
6. Première journée de NAO 2025

### Plans d'adhésion (1)

- 1 plan actif

---

## 9. Références Hardcodées dans le Code

### Fichiers contenant "UNSA" ou "Lidl"

| Fichier | Description |
|---------|-------------|
| `server/seed.ts` | Script de seed |
| `server/routes.ts` | Routes API |
| `client/src/lib/mockSupportData.ts` | Données mock |
| `client/src/lib/mockData.ts` | Données mock |
| `client/src/pages/mobile/Card.tsx` | Composant mobile |
| `client/src/pages/admin/EventDetails.tsx` | Admin événements |
| `client/src/pages/website/Blog.tsx` | Blog |
| `client/src/pages/Landing.tsx` | Landing page |
| `client/src/api/config.ts` | Configuration API |
| `client/src/App.tsx` | Routes principales |

### Pages Légales Dédiées UNSA Lidl

| Fichier | Taille |
|---------|--------|
| `client/src/pages/legal/UnsaLidlPrivacy.tsx` | 15.5 KB |
| `client/src/pages/legal/UnsaLidlTerms.tsx` | 18.5 KB |
| `client/src/pages/legal/UnsaLidlDeleteAccount.tsx` | 7.9 KB |

---

## 10. Cloudflare / Config Externe

> **Non auditable depuis le code.** Aucune configuration Cloudflare n'est stockée dans le repository.

---

## 11. Recommandations

### Option A: Archiver UNSA Lidl + Créer Nouveau Tenant WL (RECOMMANDÉE)

**Avantages**:
- Conservation de l'historique pour référence
- Nouveau tenant propre sans risque PII
- Facilité de maintenance

**Actions**:
1. Marquer UNSA Lidl comme `archived` ou `disabled`
2. Créer un nouveau tenant `demo-wl` avec données fictives
3. Configurer le host `demo-wl.koomy.app`
4. Nettoyer les références hardcodées dans le code

### Option B: Remodeler UNSA Lidl en Démo Générique

**Avantages**:
- Réutilisation des assets existants
- Moins de création de données

**Inconvénients**:
- Risque de traces PII oubliées
- Historique Git contaminé

---

## 12. Checklist de Nettoyage (À NE PAS EXÉCUTER)

- [ ] Anonymiser/purger les 19 membres UNSA Lidl (emails, noms)
- [ ] Remplacer l'email admin `mlaminesylla@yahoo.fr` par un email sandbox
- [ ] Remplacer le replyTo `ritesmassamba@gmail.com` dans brand_config
- [ ] Supprimer ou renommer les 3 pages légales UNSA Lidl
- [ ] Nettoyer les références hardcodées dans les 13 fichiers
- [ ] Supprimer/archiver les 6 articles mentionnant UNSA/Lidl
- [ ] Supprimer/archiver les 3 événements
- [ ] Créer le host `demo-wl.koomy.app` avec mapping approprié
- [ ] Tester le routing WL avec le nouveau tenant

---

## Confirmation Finale

```
Chemin du fichier généré: SANDBOX_WL_AUDIT_REPORT.md
Nombre de tenants analysés: 3
Nombre de hosts/custom_domains trouvés: 1 (unsalidlfrance)
Confirmation: READ ONLY, no data modified
```

---

*Rapport généré automatiquement - Agent Koomy*
