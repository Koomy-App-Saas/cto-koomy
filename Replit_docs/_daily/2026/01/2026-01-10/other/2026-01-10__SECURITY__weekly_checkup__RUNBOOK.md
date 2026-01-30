# 🛡️ KOOMY — Weekly Security Checkup Procedure

## 1. Objectif du document

Ce document définit **la procédure officielle de contrôle de sécurité hebdomadaire** pour la plateforme **Koomy**.

Objectifs :
- Avoir une **vision claire et récurrente de l’état de sécurité**
- Détecter tôt les dérives ou signaux faibles
- Structurer les échanges avec un **agent ChatGPT RSS / Cyber**
- Produire un **rapport archivable**, comparable dans le temps

> ⚠️ La sécurité n’est pas un état, c’est une vérification continue.

---

## 2. Fréquence et responsabilité

- **Fréquence** : hebdomadaire (idéalement même jour, même heure)
- **Responsable** : Fondateur / CTO
- **Durée cible** : 20–30 minutes

---

## 3. Périmètre du contrôle

Le checkup couvre uniquement :
- **Infrastructure exposée**
- **Configuration Cloudflare**
- **Trafic, règles et anomalies**
- **Aucune analyse de code profonde** (hors scope)

---

## 4. Sources à fournir à l’agent ChatGPT

À chaque checkup, tu dois fournir **exactement ces éléments**.

### 4.1 Cloudflare — Security Overview

- Screenshot ou export :
  - Threats blocked
  - Requests served
  - Countries
  - Bots

---

### 4.2 Cloudflare — Security Rules

- Liste complète des règles actives
- Ordre d’exécution
- Règles récemment modifiées

---

### 4.3 Cloudflare — Firewall Events

- Événements bloqués (24h / 7j)
- Pays
- User-agents suspects
- Endpoints ciblés

---

### 4.4 Infrastructure

- Liste des domaines exposés (PROD + SANDBOX)
- Confirmation : aucun domaine sandbox ne pointe vers prod

---

### 4.5 Backend

- État des webhooks (Stripe, email)
- Erreurs 4xx / 5xx notables

---

## 5. Prompt standard à utiliser (OBLIGATOIRE)

À copier-coller **sans modification** dans ton projet ChatGPT RSS.

```txt
RÔLE : Tu es expert en cybersécurité SaaS et Cloudflare.

CONTEXTE :
Koomy est une plateforme SaaS multi-tenant avec paiements Stripe.
Ce checkup est un audit hebdomadaire de sécurité (non intrusif).

TÂCHE :
1. Analyser les éléments fournis
2. Identifier :
   - risques
   - anomalies
   - signaux faibles
3. Classer chaque point par criticité :
   - INFO
   - WARNING
   - CRITICAL
4. Dire explicitement :
   - ce qui est OK
   - ce qui doit être amélioré
5. Proposer des recommandations concrètes (si nécessaire)

CONTRAINTES :
- Ne proposer AUCUN changement automatique
- Ne supposer aucune information absente
- Être factuel, concis et structuré

FORMAT DE SORTIE :
Un rapport structuré prêt à être archivé.
```

---

## 6. Structure du rapport attendu

Le rapport généré doit respecter ce format.

### 6.1 Résumé exécutif

- Niveau de sécurité global : 🟢 / 🟠 / 🔴
- Évolution par rapport au dernier checkup

---

### 6.2 Points conformes

- Liste des éléments jugés sains

---

### 6.3 Alertes et risques

Pour chaque point :
- Description
- Impact potentiel
- Niveau de criticité

---

### 6.4 Recommandations

- Actions proposées
- Priorisation

---

### 6.5 Conclusion

- Verdict global
- Prochaine action éventuelle

---

## 7. Archivage

Chaque rapport doit être :
- daté
- stocké en `.md`
- versionné si possible

Convention recommandée :

```txt
security-checkup-YYYY-MM-DD.md
```

---

## 8. Règles absolues

- ❌ Aucun changement en prod le jour même sans analyse
- ❌ Aucun audit improvisé
- ✅ Une seule source de vérité par checkup

---

## 9. Principe fondateur

> **Ce qui est vérifié régulièrement ne dégénère pas.**

La sécurité Koomy repose sur :
- la constance
- la traçabilité
- la lucidité

Pas sur la paranoïa.

