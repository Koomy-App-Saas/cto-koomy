# 07 — Source of Truth & Documentation Architecture (KOOMY)

## 🎯 Objectif du document

Ce document définit :

1) **Les sources de vérité officielles de KOOMY**
2) **La hiérarchie entre ces sources**
3) **La structure documentaire du repo**
4) **La règle “où chercher quoi” selon le problème**

But : éliminer la confusion, empêcher les approximations, et garantir que toute décision repose sur des éléments vérifiables.

---

## 🧠 Principe fondamental

> **Une décision KOOMY n’est valide que si sa source de vérité est explicitement citée.**

Sans source citée :
- la décision est bloquée
- la correction est interdite
- la feature est rejetée

---

## 🏛️ Hiérarchie des sources de vérité

### Niveau 0 — Réalité observée (preuves)
- Logs frontend (console + network)
- Logs backend (requêtes/réponses/erreurs)
- Requêtes SQL et résultats
- Config Cloudflare (pages, rules, R2, CDN)

✅ Ce niveau est toujours prioritaire : on ne conteste pas une preuve.

---

### Niveau 1 — Données persistées (état du système)
- Base de données (Neon/Postgres)
- Stockage fichiers (Cloudflare R2)
- Variables d’environnement (Railway, Cloudflare)

✅ Ce niveau décrit ce que le système est réellement.

---

### Niveau 2 — Code source (intention implémentée)
- Repo GitHub (branches officielles)
- Code Replit (workspace, PR)

✅ Ce niveau décrit ce que le système est censé faire.

---

### Niveau 3 — Contrats & décisions
- Contrats produit (billing, onboarding, quotas)
- ADR / décisions d’architecture
- Process officiels (docs 02→06)

✅ Ce niveau fixe la doctrine et les règles.

---

### Niveau 4 — Notes et analyses (support)
- Audits Replit
- Rapports d’implémentation
- Journaux daily

✅ Ce niveau aide, mais ne remplace jamais une preuve.

---

## 🧭 Règle de résolution en cas de conflit

Si deux sources se contredisent :

1) Les **preuves** priment (N0)
2) Ensuite les **données persistées** (N1)
3) Ensuite le **code** (N2)
4) Ensuite les **contrats** (N3)
5) Enfin les **rapports** (N4)

👉 Une contradiction doit déclencher une RCA (document 04).

---

## 🗂️ Architecture documentaire du repo

### 📁 Racine
- `02__chatgpt_personality_and_exigence_level.md`
- `03__decision_and_trust_contract.md`
- `04__bug_and_incident_management_process_rca_first.md`
- `05__feature_design_and_validation_process.md`
- `06__environment_and_promotion_strategy.md`
- `07__source_of_truth_and_documentation_architecture.md`

Ces documents sont la **doctrine KOOMY**.

---

### 📁 /replit/
Dossier réservé aux documents produits par Replit.

Structure recommandée :

- `/replit/audits/YYYY-MM/`
- `/replit/reports/YYYY-MM/`
- `/replit/contracts/YYYY-MM/`
- `/replit/daily/YYYY-MM/`

Règles :
- un document = un sujet
- nommage stable
- aucune suppression

---

### 📁 /ops/
Documents opérationnels (production, incidents, runbooks).

- `/ops/incidents/YYYY-MM/`
- `/ops/runbooks/`
- `/ops/release/YYYY-MM/`

---

### 📁 /architecture/
- architecture actuelle
- architecture cible
- schémas

---

## 🧩 “Où chercher quoi” (guide par type de problème)

### 🔥 Bug fonctionnel UI
Chercher dans l’ordre :
1) Console + Network (N0)
2) Logs backend liés au traceId (N0)
3) Données DB concernées (N1)
4) Code front + API wrapper (N2)
5) Contrat produit lié (N3)

---

### 🧾 Bug billing / quotas / plan
1) Contrats produit (N3)
2) DB (subscription/quota) (N1)
3) API routes billing (N2)
4) Logs Stripe/webhooks (N0)
5) Audits Replit existants (N4)

---

### 🖼️ Bug image / CDN / stockage
1) URL exacte + réponse CDN (N0)
2) Cloudflare R2 (bucket/object public) (N1)
3) Resolver d’URL côté front (N2)
4) Variables CDN/namespace (N1)
5) Rules Cloudflare (N0/N1)

---

### 🔐 Bug auth / roles
1) Logs auth (front + back) (N0)
2) DB user_identities/users (N1)
3) Config Firebase/JWT (N1)
4) Code guards/permissions (N2)
5) Contrat identité & onboarding (N3)

---

## 🧾 Règles de production documentaire

Pour tout travail (bug ou feature) :

- Chaque décision cite au moins 1 source N0/N1/N2
- Chaque correction produit :
  - 1 RCA (si bug)
  - 1 rapport d’implémentation
  - 1 entrée journal

---

## ✅ Statut

Ce document est :
- 📁 Archivé à la racine du repo
- 🔒 Opposable à ChatGPT
- 🧭 Référence unique “où chercher quoi” chez KOOMY

---

> **Chez KOOMY, une réponse sans source est une réponse interdite.**

