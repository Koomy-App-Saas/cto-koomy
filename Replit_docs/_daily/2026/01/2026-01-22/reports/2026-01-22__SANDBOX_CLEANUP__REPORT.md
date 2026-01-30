# Sandbox Database Cleanup Report

**Date:** 2026-01-22
**Environment:** SANDBOX
**Status:** ✅ COMPLETED

---

## Résumé exécutif

Nettoyage intégral de la base sandbox après les tests Google Auth.
Toutes les données de test ont été supprimées, la communauté UNSA Lidl a été préservée intacte.

---

## Communauté préservée (LOCK)

| ID | Nom | Plan |
|----|-----|------|
| `2b129b86-3a39-4d19-a6fc-3d0cec067a79` | UNSA Lidl | whitelabel |

---

## Tables impactées et suppressions

| Table | Lignes supprimées |
|-------|-------------------|
| `member_tags` | 233 |
| `event_registrations` | 177 |
| `event_attendance` | 75 |
| `user_community_memberships` | 167 |
| `events` | 12 |
| `sections` | 13 |
| `tags` | 11 |
| `membership_plans` | 8 |
| `news_articles` | 9 |
| `communities` | 2 |
| `users` | 5 |
| `accounts` | 3 |
| **TOTAL** | **715** |

---

## Communautés supprimées

| ID | Nom | Plan |
|----|-----|------|
| `82590b15-9394-4cfe-b99a-8a3b8df1e701` | Club d'Échecs de Paris | free |
| `sandbox-portbouet-fc` | Port-Bouët FC | scale |

---

## Utilisateurs supprimés

| Email | Nom |
|-------|-----|
| `owner@portbouet-fc.sandbox` | Kouadio Yao |
| `admin@portbouet-fc.sandbox` | Aminata Koné |
| `coach@portbouet-fc.sandbox` | Ibrahim Diallo |
| `tresorier@portbouet-fc.sandbox` | Fatou Touré |
| `coach2@portbouet-fc.sandbox` | Moussa Camara |

---

## Comptes supprimés (mobile)

| Email | Nom |
|-------|-----|
| `t5admin-1768965461@sandbox.test` | Test Admin |
| `finaltest-1768965499@sandbox.test` | Final Test |
| `fulltest-1768965651@sandbox.test` | Full Test |

---

## État final de la sandbox

### Communautés (1)
- UNSA Lidl (`2b129b86-3a39-4d19-a6fc-3d0cec067a79`)

### Utilisateurs (9)
| Email | Rôle |
|-------|------|
| `platform@koomy.app` | platform_super_admin |
| `rites@koomy.app` | platform_super_admin |
| `admin@koomy.app` | admin |
| `superadmin@koomy.app` | admin |
| `mlaminesylla@yahoo.fr` | super_admin UNSA |
| `admin@unsa.org` | admin UNSA |
| `member@unsa.org` | member UNSA |
| `gestionnaire.lidl@lidl.fr` | gestionnaire UNSA |
| `admin.strasbourg@lidl.fr` | admin UNSA |

### Comptes mobiles (7)
- `marie.dupont@lidl.fr`
- `jean.martin@lidl.fr`
- `mlaminesylla@yahoo.fr`
- `testeur.google@koomy.app`
- `demo@koomy.app`
- `loic.jouan123@orange.fr`
- `ntoba51100@gmail.com`

### Memberships (19)
- Tous liés à UNSA Lidl

---

## Confirmation

> ✅ **UNSA Lidl intacte** - Aucune donnée UNSA supprimée  
> ✅ **Sandbox prête pour nouveaux tests** - Base nettoyée et cohérente  
> ✅ **SaaS Owner affiche une vue propre** - Une seule communauté visible  

---

## Ordre de suppression respecté

1. `member_tags` (FK → memberships)
2. `event_registrations` (FK → memberships)
3. `event_attendance` (FK → memberships)
4. `user_community_memberships` (FK → communities, users)
5. Autres tables dépendantes de communities
6. `communities`
7. `users` orphelins
8. `accounts` de test

---

## Environnement

- **Base:** Development (Sandbox)
- **Protection PROD:** ✅ Non impactée
- **Transactions:** Utilisées pour garantir l'intégrité
