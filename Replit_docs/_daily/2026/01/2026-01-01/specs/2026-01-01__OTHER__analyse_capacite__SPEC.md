# Analyse de Capacité et Scalabilité - Koomy

*Document généré le 3 décembre 2024, mis à jour le 9 janvier 2026*

---

## 1. État Actuel du Projet

### 1.1 Hébergement Replit

| Paramètre | Valeur |
|-----------|--------|
| **Type de déploiement** | Autoscale |
| **Runtime** | Node.js 20 |
| **Modules installés** | nodejs-20, web, postgresql-16 |
| **Port principal** | 5000 (exposé sur 80) |

**Ressources disponibles (Autoscale Replit) :**
- CPU : Variable selon la charge (0.5 à 4 vCPU possible)
- RAM : Variable (2 GB à 16 GB selon config)
- Facturation : Compute Units (1 RAM Second = 2 units, 1 CPU Second = 18 units)

**Limites connues Replit :**
- Cold start possible si inactivité prolongée
- Pas de garantie de disponibilité 100% sur les plans gratuits
- Limite de connexions WebSocket par instance
- Timeout de requête HTTP par défaut : 60 secondes

### 1.2 Stack Serveur

| Composant | Technologie | Version |
|-----------|-------------|---------|
| **Framework** | Express.js | 4.21.2 |
| **Serveur HTTP** | Node.js natif (createServer) | - |
| **TypeScript Runtime** | tsx | 4.20.5 |
| **Build Tool** | Vite / esbuild | 7.1.9 / 0.25.0 |

**Configuration actuelle :**
- **Middleware** : express.json(), express.urlencoded()
- **Sessions** : express-session avec memorystore (en dev) / connect-pg-simple (prod)
- **Logging** : Console avec timestamps
- **Routes API** : ~116 endpoints
- **Lignes de code routes** : ~2920 lignes
- **Appels storage/requête** : ~148 appels dans routes.ts

### 1.3 Base de Données

| Paramètre | Valeur |
|-----------|--------|
| **Type** | PostgreSQL 16 |
| **Hébergeur** | Neon (serverless) |
| **ORM** | Drizzle ORM 0.39.1 |
| **Connexion** | Pool via `@neondatabase/serverless` |
| **WebSocket** | Activé (pour les requêtes serverless) |

**Configuration du pool actuelle :**
```typescript
export const pool = new Pool({ connectionString: process.env.DATABASE_URL });
```

⚠️ **Point d'attention** : Aucune configuration explicite du pool (pas de `max`, `min`, `idleTimeoutMillis`). Neon utilise des valeurs par défaut.

**Limites Neon (plan gratuit/basique) :**
- Connexions simultanées : ~100 (autoscaling)
- Compute : 0.25-1 CU avec autosuspend
- Storage : 0.5-10 GB selon plan
- Branches : limitées selon plan

### 1.4 Dépendances Critiques

| Service | Usage | Latence typique |
|---------|-------|-----------------|
| **Stripe** | Paiements SaaS + Connect Express | 200-500ms par appel API |
| **SendGrid** | Envoi d'emails | 100-300ms par email |
| **OpenAI** | Génération de contenu | 500ms-5s selon modèle |
| **Neon PostgreSQL** | Persistance données | 10-50ms par requête |
| **Object Storage (GCS)** | Fichiers/médias | 50-200ms |

**Webhooks configurés :**
- Stripe webhooks (via `STRIPE_WEBHOOK_SECRET`)
- Potentiellement latence si file d'attente saturée

---

## 2. Estimation de Capacité

### 2.1 Métriques Théoriques

**Requêtes par seconde (RPS) estimées :**

| Scénario | RPS Backend | Facteur limitant |
|----------|-------------|------------------|
| Lecture simple (GET) | 50-100 RPS | CPU/DB connections |
| Écriture DB | 20-40 RPS | Latence DB write |
| Appel Stripe | 5-10 RPS | Rate limit Stripe |
| Envoi email | 2-5 RPS | Rate limit SendGrid |

### 2.2 Utilisateurs Simultanés

| Type d'activité | Estimation | Notes |
|-----------------|------------|-------|
| **Navigation passive** | 200-500 utilisateurs | Lecture seule, peu d'écriture |
| **Activité normale** | 100-200 utilisateurs | Quelques paiements/événements |
| **Pic d'activité** | 50-100 utilisateurs | Scans QR massifs, paiements |

### 2.3 Utilisateurs Totaux (Comptes)

| Palier | Comptes | Configuration requise |
|--------|---------|----------------------|
| **Confort** | < 5 000 | Configuration actuelle OK |
| **Limite douce** | 5 000 - 20 000 | Optimisations recommandées |
| **Limite dure** | > 20 000 | Migration infrastructure |

### 2.4 Distinction Charge Normale vs Pic

**Charge normale (usage quotidien typique) :**
- 10-50 utilisateurs actifs simultanés
- Consultation d'actualités, événements, profils
- 1-5 paiements par heure
- 0-2 scans QR par minute

**Charge pic (événement, fin de mois, campagne) :**
- 100+ utilisateurs simultanés sur quelques minutes
- Scans QR massifs (entrée événement)
- Vague de paiements (cotisations)
- Webhooks Stripe en rafale

---

## 3. Paliers de Croissance

### Palier 1 : Jusqu'à 500 utilisateurs actifs/jour

**Statut : ✅ OK sur Replit tel quel**

| Métrique | Valeur |
|----------|--------|
| Utilisateurs actifs/jour | < 500 |
| Utilisateurs simultanés | < 50 |
| Communautés actives | < 20 |
| Transactions/mois | < 500 |

**Risques :**
- Cold start occasionnel (3-5 secondes)
- Latence légèrement élevée sur certaines requêtes

**Actions préventives :**
- Surveiller les temps de réponse
- Éviter les requêtes N+1

---

### Palier 2 : 500 à 2 000 utilisateurs actifs/jour

**Statut : ⚠️ Optimisations légères nécessaires**

| Métrique | Valeur |
|----------|--------|
| Utilisateurs actifs/jour | 500 - 2 000 |
| Utilisateurs simultanés | 50 - 150 |
| Communautés actives | 20 - 100 |
| Transactions/mois | 500 - 2 000 |

**Risques émergents :**
- Saturation connexions DB pendant les pics
- Temps de réponse > 1 seconde sur requêtes complexes
- Memory pressure sur l'instance Node.js
- Files d'attente webhooks

**Optimisations recommandées :**

1. **Configuration pool DB :**
```typescript
export const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 20,
  min: 2,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});
```

2. **Caching applicatif :**
   - Mettre en cache les données communautés (5-15 min TTL)
   - Mettre en cache les plans/tarifs (1h TTL)
   - Utiliser `stale-while-revalidate` côté client

3. **Optimisation requêtes :**
   - Ajouter des index DB sur les colonnes fréquemment filtrées
   - Paginer toutes les listes (membres, transactions)
   - Limiter les JSON renvoyés aux champs nécessaires

4. **Monitoring basique :**
   - Logger les temps de réponse > 500ms
   - Alerter sur les erreurs 500

---

### Palier 3 : Plus de 2 000 utilisateurs actifs/jour

**Statut : 🔴 Migration infrastructure recommandée**

| Métrique | Valeur |
|----------|--------|
| Utilisateurs actifs/jour | > 2 000 |
| Utilisateurs simultanés | > 150 |
| Communautés actives | > 100 |
| Transactions/mois | > 2 000 |

**Risques critiques :**
- Timeouts réguliers (502/504)
- Erreurs 500 pendant les pics
- Perte de webhooks Stripe
- Déconnexions WebSocket
- Coûts Replit Autoscale élevés

**Goulots d'étranglement principaux :**

| Goulot | Impact | Priorité |
|--------|--------|----------|
| Connexions DB Neon | Requêtes en attente, timeouts | 🔴 Critique |
| RAM Node.js | OOM, crash process | 🔴 Critique |
| CPU Replit | Latence, cold starts fréquents | 🟠 Élevé |
| Stripe rate limits | Échecs paiements | 🟠 Élevé |
| SendGrid quotas | Emails non envoyés | 🟡 Moyen |

**Évolutions recommandées :**

1. **Infrastructure :**
   - Migrer vers un VPS dédié (Render, Railway, Fly.io, AWS ECS)
   - Utiliser Neon Pro ou PostgreSQL managé (RDS, Cloud SQL)
   - Séparer le worker de webhooks du serveur HTTP

2. **Architecture :**
   - Ajouter Redis pour le caching et les sessions
   - Implémenter une queue pour les emails (BullMQ, SQS)
   - Mettre en place un CDN pour les assets statiques

3. **Scaling horizontal :**
   - Load balancer devant plusieurs instances
   - Sessions persistantes dans Redis (pas memorystore)
   - DB read replicas pour les requêtes lecture

---

## 4. Plan de Monitoring Minimal

### 4.1 Logging Temps de Réponse

Le projet inclut déjà un middleware de logging basique. Amélioration suggérée :

```typescript
// server/index.ts - Amélioration du middleware existant
app.use((req, res, next) => {
  const start = Date.now();
  
  res.on("finish", () => {
    const duration = Date.now() - start;
    const level = duration > 1000 ? "SLOW" : duration > 500 ? "WARN" : "INFO";
    
    if (req.path.startsWith("/api")) {
      console.log(JSON.stringify({
        timestamp: new Date().toISOString(),
        level,
        method: req.method,
        path: req.path,
        status: res.statusCode,
        duration,
        userAgent: req.get('user-agent')?.substring(0, 50)
      }));
    }
  });
  
  next();
});
```

### 4.2 Suivi Requêtes par Minute/Heure

```typescript
// server/monitoring.ts - Compteur simple
const requestCounts: Record<string, number> = {};
const errorCounts: Record<string, number> = {};

export function trackRequest(path: string, statusCode: number) {
  const minute = new Date().toISOString().substring(0, 16); // "2024-12-03T14:30"
  const key = `${minute}`;
  
  requestCounts[key] = (requestCounts[key] || 0) + 1;
  
  if (statusCode >= 500) {
    errorCounts[key] = (errorCounts[key] || 0) + 1;
  }
  
  // Cleanup old entries (garder 1h de données)
  const oneHourAgo = new Date(Date.now() - 3600000).toISOString().substring(0, 16);
  Object.keys(requestCounts).forEach(k => {
    if (k < oneHourAgo) delete requestCounts[k];
  });
}

export function getStats() {
  return {
    requestsLastHour: Object.values(requestCounts).reduce((a, b) => a + b, 0),
    errorsLastHour: Object.values(errorCounts).reduce((a, b) => a + b, 0),
    requestsPerMinute: requestCounts,
    errorRate: /* calcul */ 
  };
}
```

### 4.3 Signaux d'Alerte à Surveiller

| Signal | Seuil d'alerte | Action |
|--------|----------------|--------|
| Temps de réponse moyen | > 500ms | Investiguer requêtes lentes |
| Temps de réponse P95 | > 2000ms | Optimisation urgente |
| Taux d'erreur 5xx | > 1% | Vérifier logs, DB, services |
| Connexions DB actives | > 80% du pool | Augmenter pool ou optimiser |
| Mémoire utilisée | > 80% | Redémarrage ou scaling |
| Webhooks en échec | > 5/heure | Vérifier Stripe dashboard |

### 4.4 Endpoint de Health Check

```typescript
// Ajouter dans server/routes.ts
app.get("/api/health", async (req, res) => {
  try {
    // Test connexion DB
    await db.execute(sql`SELECT 1`);
    
    res.json({
      status: "healthy",
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      memory: process.memoryUsage(),
      // Ajouter stats si implémenté
    });
  } catch (error) {
    res.status(503).json({
      status: "unhealthy",
      error: "Database connection failed"
    });
  }
});
```

---

## 5. Résumé Concret pour Décision

### État Actuel

> **Dans l'état actuel, Koomy peut raisonnablement supporter environ 50 à 100 utilisateurs simultanés et 500 utilisateurs actifs par jour.**

### Seuils de Transition

| Indicateur | Seuil | Action |
|------------|-------|--------|
| Utilisateurs actifs/jour | > 500 | Implémenter caching + pool DB |
| Utilisateurs simultanés | > 100 | Surveiller, préparer migration |
| Transactions/mois | > 1 000 | S'assurer des marges Stripe/SendGrid |
| Utilisateurs actifs/jour | > 2 000 | **Migrer vers infra dédiée** |

### Recommandations Immédiates (Palier 1 → 2)

1. **Court terme (cette semaine) :**
   - Configurer le pool de connexions DB avec des limites explicites
   - Ajouter un endpoint `/api/health`

2. **Moyen terme (ce mois) :**
   - Implémenter un cache simple pour les données communautés
   - Ajouter des index DB sur les requêtes fréquentes
   - Mettre en place un logging structuré (JSON)

3. **Préparation migration (si croissance) :**
   - Documenter l'architecture pour faciliter la migration
   - Identifier un hébergeur cible (Render, Fly.io, Railway)
   - Prévoir Redis pour sessions/cache distribué

### Coûts Estimés par Palier

| Palier | Infra | Coût mensuel estimé |
|--------|-------|---------------------|
| Palier 1 | Replit Autoscale | ~10-30€/mois |
| Palier 2 | Replit Autoscale optimisé | ~30-80€/mois |
| Palier 3 | VPS dédié + DB managée | ~80-200€/mois |

---

## Annexes

### A. Métriques Actuelles du Projet

| Métrique | Valeur |
|----------|--------|
| Routes API | 116 |
| Lignes code routes | 2920 |
| Lignes code storage | 1562 |
| Appels DB par requête (moy.) | ~1-3 |
| Dépendances npm | 91 |

### B. Technologies Utilisées

- **Frontend** : React 19, Vite, TailwindCSS, shadcn/ui
- **Backend** : Express.js, TypeScript, Drizzle ORM
- **Database** : PostgreSQL 16 (Neon Serverless)
- **Paiements** : Stripe (Billing + Connect Express)
- **Emails** : SendGrid
- **Stockage** : Google Cloud Storage

### C. Points d'Amélioration Identifiés

1. Pas de configuration explicite du pool DB
2. Sessions en mémoire en dev (memorystore)
3. Pas de cache applicatif
4. Logging basique (console.log)
5. Pas de health check endpoint
6. Pas de rate limiting sur les API
7. Pas de queue pour les tâches asynchrones (emails, webhooks)

---

*Ce document est basé sur l'analyse du code source et des configurations de l'environnement Replit. Les estimations sont indicatives et dépendent de nombreux facteurs (usage réel, types de requêtes, distribution temporelle de la charge).*
