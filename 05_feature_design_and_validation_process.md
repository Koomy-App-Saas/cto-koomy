# 05 — Feature Design & Validation Process (KOOMY)

## 🎯 Objectif du document

Ce document définit **le cadre obligatoire de conception, d’évaluation et de validation de toute feature chez KOOMY**.

Une règle centrale :

> **Toute feature est un projet à part entière.**

Il n’existe **aucune petite feature**.
Chaque ajout ou modification peut impacter :
- la base de données
- l’infrastructure
- la sécurité
- les clients existants
- la dette technique
- la capacité de montée en charge

---

## 🧠 Principe fondamental

Une feature n’est **jamais** évaluée sur sa faisabilité technique seule.

Elle est évaluée sur :
- sa **valeur produit**
- son **impact systémique**
- son **coût long terme**
- sa **compatibilité avec la vision KOOMY**

> **Ce qui n’est pas pensé comme un projet devient une dette.**

---

## 🧱 Pré‑requis absolus avant toute implémentation

Aucune feature ne peut être développée sans :

- 📄 Un document de cadrage (.md)
- 📊 Une analyse d’impact
- 🧾 Une validation explicite

👉 Sans ces éléments, **le développement est interdit**.

---

## 1️⃣ Identification de la feature

Le document de cadrage doit répondre factuellement à :

- Quel problème utilisateur est résolu ?
- Pour quel type de client ? (standard, enterprise, WL)
- Est‑ce une création ou une modification ?
- Quelle feature existante est impactée ?

👉 Si le problème n’est pas clair, la feature est rejetée.

---

## 2️⃣ Évaluation de la valeur ajoutée

Chaque feature doit être évaluée selon au moins **un** des axes suivants :

- Augmentation de la valeur perçue
- Réduction d’un point de friction majeur
- Déblocage commercial
- Sécurisation du produit
- Scalabilité ou stabilité

👉 Une feature sans valeur mesurable est refusée.

---

## 3️⃣ Analyse d’impact systémique (obligatoire)

### 🔹 Produit & UX
- Parcours impactés
- Effets de bord possibles
- Cohérence Web / Mobile

### 🔹 Backend & API
- Nouvelles routes ou modifications
- Règles métier affectées
- Performance et latence

### 🔹 Base de données
- Schémas impactés
- Migrations nécessaires
- Rétro‑compatibilité

### 🔹 Infrastructure
- CDN
- stockage
- quotas
- coûts

### 🔹 Sécurité & conformité
- Permissions
- RGPD
- exposition des données

👉 Toute zone non analysée invalide la feature.

---

## 4️⃣ Contrat d’impact

Un **contrat d’impact** doit être formalisé :

- Ce qui change
- Ce qui ne change pas
- Ce qui pourrait casser
- Ce qui est garanti

Ce contrat protège :
- les clients existants
- la stabilité globale

---

## 5️⃣ Options de mise en œuvre

Toujours proposer :

- **Option A — Minimal viable**
- **Option B — Implémentation propre**
- **Option C — Version scalable**

Avec pour chaque option :
- complexité
- risques
- dette créée ou évitée

---

## 6️⃣ Validation

- La validation est **explicite**
- Aucun lancement implicite
- En cas de fatigue du décideur → report

---

## 7️⃣ Implémentation contrôlée

- Scope strict
- Aucun ajout hors cadrage
- Logs et métriques si nécessaire

---

## 8️⃣ Vérification post‑feature

- Tests fonctionnels ciblés
- Vérification des scénarios existants
- Absence de régression

---

## 9️⃣ Documentation obligatoire

Chaque feature validée génère :

- 1 document de cadrage
- 1 analyse d’impact
- 1 note d’architecture si nécessaire
- 1 entrée dans le journal

---

## 🚫 Interdictions formelles

Il est interdit de :

- Ajouter une feature "vite fait"
- Modifier un comportement sans contrat
- Coder avant validation
- Livrer sans documentation

---

## ✅ Statut

Ce document est :
- 📁 Archivé à la racine du repo
- 🔒 Opposable à ChatGPT
- 🧭 Référence unique pour toute évolution produit KOOMY

---

> **Chez KOOMY, une feature bien pensée coûte moins cher que dix correctifs.**

