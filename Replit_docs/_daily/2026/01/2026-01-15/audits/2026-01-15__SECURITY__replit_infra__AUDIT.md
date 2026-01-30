# AUDIT INFRASTRUCTURE REPLIT – KOOMY

**Date :** 16 Janvier 2026  
**Auteur :** Agent Replit  
**Contexte :** Diagnostic de la mise en veille du serveur en production

---

## A) DIAGNOSTIC "PROD: WORKSPACE VS DEPLOYMENT"

### 1. Type de déploiement actuel

**Configuration détectée dans `.replit` :**

```toml
[deployment]
deploymentTarget = "autoscale"
build = ["npm", "run", "build"]
run = ["npm", "run", "start"]
```

| Question | Réponse |
|----------|---------|
| **Type de prod** | **Autoscale Deployment** (pas Workspace Run) |
| **Workspace Run** | Utilisé uniquement en développement (`npm run dev`) |
| **Reserved VM** | Non configuré |

### 2. URLs de production

| Type | URL |
|------|-----|
| **Domaine Replit** | `https://koomy-app-saas.replit.app` (ou similaire) |
| **Domaine personnalisé** | `https://koomy.app` (si configuré dans Deployments) |
| **API endpoint** | `https://api.koomy.app` ou même domaine avec `/api/*` |

### 3. Configuration Deployments

La section `[deployment]` dans `.replit` configure :
- **Build command** : `npm run build`
- **Run command** : `npm run start`
- **Port mapping** : 5000 → 80 (HTTP)

---

## B) VEILLE / DISPONIBILITÉ

### 4. Pourquoi le serveur se met en veille

**Cause exacte : Autoscale "scale-to-zero"**

> Avec les déploiements Autoscale, votre application se met en veille après **15 minutes d'inactivité**. Elle ne tourne que lorsqu'elle sert activement des requêtes.

**Conséquences :**
- Cold start de 2-5 secondes à la première requête après veille
- Webhooks Stripe peuvent timeout si le serveur dort
- Sessions en mémoire perdues (mais vous utilisez PostgreSQL + connect-pg-simple, donc OK)

### 5. Si Workspace Run (développement)

| Comportement | Détail |
|--------------|--------|
| Mise en veille | Après ~30 minutes d'inactivité du navigateur |
| Empêcher la veille | Impossible de façon fiable |
| Usage recommandé | Développement uniquement, jamais pour la prod |

### 6. Si Deployment Autoscale (actuel)

| Propriété | Valeur |
|-----------|--------|
| Always-on | **NON** – scale-to-zero après 15 min |
| Cold start | 2-5 secondes |
| Scaling | Automatique selon trafic |
| Redémarrage | Automatique après crash |

### 7. Si Reserved VM (recommandé pour SaaS)

| Propriété | Valeur |
|-----------|--------|
| Always-on | **OUI** – VM dédiée 24/7 |
| Cold start | Aucun |
| Scaling | Manuel (choix de la taille VM) |
| Redémarrage | Automatique après crash |
| Idéal pour | Webhooks, bots, jobs background |

---

## C) ROBUSTESSE PROD – RECOMMANDATIONS

### Configuration recommandée pour Koomy SaaS

| Critère | Recommandation |
|---------|----------------|
| **Type de déploiement** | **Reserved VM** |
| **Raison** | Webhooks Stripe (paiements) nécessitent un serveur toujours disponible |
| **Taille VM** | 1 vCPU / 4GB RAM (Dedicated) pour commencer |
| **Backup** | PostgreSQL Neon a ses propres backups |

### Modification à faire dans `.replit`

```toml
[deployment]
deploymentTarget = "reserved-vm"  # Changer de "autoscale"
build = ["npm", "run", "build"]
run = ["npm", "run", "start"]
```

### Healthcheck / Monitoring

| Outil | Configuration |
|-------|---------------|
| **Healthcheck endpoint** | Créer `GET /api/health` retournant `{ status: "ok" }` |
| **Replit Monitoring** | Dashboard Deployments → Logs, CPU, RAM |
| **Externe (optionnel)** | UptimeRobot, Better Uptime, Pingdom |

### Stratégie de redémarrage

| Scénario | Comportement |
|----------|--------------|
| Crash applicatif | Redémarrage automatique par Replit |
| Déploiement | Zero-downtime avec nouvelle instance |
| Pic de trafic (Reserved VM) | Pas de scaling auto – dimensionner suffisamment |
| Pic de trafic (Autoscale) | Scaling auto jusqu'à max instances |

---

## D) COÛT & RISQUES

### 8. Estimation des coûts mensuels

#### Autoscale (actuel)

| Charge | Coût estimé |
|--------|-------------|
| MVP (faible trafic) | ~$5-15/mois |
| Croissance (trafic moyen) | ~$20-50/mois |
| Grande échelle | ~$100-300/mois |

*Avantage : Pas de coût si 0 trafic*  
*Inconvénient : Cold starts, webhooks risqués*

#### Reserved VM (recommandé)

| Configuration | Coût mensuel |
|---------------|--------------|
| Shared 0.5 vCPU / 2GB | ~$7/mois |
| Dedicated 1 vCPU / 4GB | ~$25/mois |
| Dedicated 2 vCPU / 8GB | ~$50/mois |
| Dedicated 4 vCPU / 16GB | ~$100/mois |

*Avantage : Always-on, pas de cold start*  
*Inconvénient : Coût fixe même si 0 trafic*

#### Coûts annexes Replit

| Service | Coût |
|---------|------|
| Domaine personnalisé | Inclus |
| SSL/TLS | Inclus |
| PostgreSQL (Neon) | Inclus dans quota, puis usage |
| Object Storage | Inclus dans quota, puis usage |
| Replit Core | $20/mois (inclut $10 crédits) |

### 9. Risques de rester sur Replit

| Risque | Niveau | Détail |
|--------|--------|--------|
| **Vendor lock-in** | Moyen | Intégrations Replit (Object Storage, Auth) spécifiques |
| **Scalabilité** | Faible | Autoscale gère bien, Reserved VM limité à 4 vCPU max |
| **Incidents plateforme** | Faible | Replit mature mais moins que AWS/GCP |
| **Cold starts** | Élevé (Autoscale) | Problématique pour webhooks |
| **Coût à grande échelle** | Moyen | Peut devenir plus cher que Railway/Fly |
| **Personnalisation infra** | Élevé | Pas d'accès SSH, pas de Docker custom |
| **Egress/bandwidth** | Inconnu | Pas de détail clair sur les limites |

---

## E) OPTION "INDÉPENDANCE" – PLAN DE SORTIE

### 10. Migration vers Railway/Fly/Render

#### Étapes de migration

| # | Étape | Durée |
|---|-------|-------|
| 1 | Exporter variables d'environnement | 1h |
| 2 | Créer Dockerfile ou config Railway/Fly | 2-4h |
| 3 | Provisionner PostgreSQL externe (Neon direct, Supabase) | 1h |
| 4 | Migrer Object Storage vers S3/R2 | 2-4h |
| 5 | Déployer sur nouvelle plateforme | 1-2h |
| 6 | Tester webhooks Stripe en staging | 2h |
| 7 | Migrer DNS (TTL bas d'abord) | 24-48h propagation |
| 8 | Basculer Stripe webhooks vers nouvelle URL | 5 min |
| 9 | Monitoring post-migration | 1 semaine |

#### Pièges à éviter

| Piège | Solution |
|-------|----------|
| **Env vars Replit** | Exporter TOUTES les variables (view_env_vars) |
| **Object Storage paths** | Migrer vers S3-compatible, adapter les URLs |
| **Neon PostgreSQL** | Peut être gardé tel quel (externe à Replit) |
| **Stripe webhooks** | Changer l'endpoint APRÈS migration, pas avant |
| **DNS propagation** | TTL à 300s 24h avant migration |
| **SendGrid/integrations** | Reconfigurer les API keys côté nouvelle plateforme |

#### Downtime évitable ?

| Stratégie | Downtime |
|-----------|----------|
| Migration à chaud (DNS switch) | ~5-15 minutes |
| Migration avec maintenance planifiée | 30-60 min (plus sûr) |
| Blue-green deployment | Quasi-zéro downtime |

#### Comparatif plateformes alternatives

| Plateforme | Coût MVP | Always-on | Docker | Facilité |
|------------|----------|-----------|--------|----------|
| **Railway** | ~$5/mois | Oui | Oui | ⭐⭐⭐⭐ |
| **Fly.io** | ~$5/mois | Oui | Oui | ⭐⭐⭐ |
| **Render** | ~$7/mois | Oui | Oui | ⭐⭐⭐⭐ |
| **Replit Reserved VM** | ~$25/mois | Oui | Non | ⭐⭐⭐⭐⭐ |

---

## CONCLUSION

### Diagnostic

| Élément | Constat |
|---------|---------|
| Type actuel | Autoscale Deployment |
| Problème | Scale-to-zero après 15 min → cold starts → webhooks risqués |
| Solution immédiate | Passer en Reserved VM |

### Recommandation finale

## ✅ GO REPLIT RESERVED VM

**Justification :**

1. **Changement minimal** : Une ligne dans `.replit` (`deploymentTarget = "reserved-vm"`)
2. **Always-on garanti** : Pas de cold start, webhooks Stripe fiables
3. **Coût raisonnable** : ~$25/mois pour 1 vCPU / 4GB (suffisant pour MVP/croissance)
4. **Pas de migration** : Garder PostgreSQL Neon, Object Storage, intégrations
5. **Monitoring intégré** : Dashboard Replit Deployments

### Action immédiate

1. Modifier `.replit` : `deploymentTarget = "reserved-vm"`
2. Re-déployer via l'interface Replit Deployments
3. Vérifier que les webhooks Stripe fonctionnent sans timeout

### Quand envisager la sortie Replit ?

- Si coûts > $200/mois (économies possibles sur Railway/Fly)
- Si besoin de Docker custom / infrastructure spécifique
- Si scaling horizontal massif nécessaire (>4 vCPU)

---

*Rapport généré le 16 Janvier 2026*
