# Déploiement du site public Koomy sur Replit

## Vue d'ensemble

Ce document décrit comment déployer le site public Koomy (pages marketing) sur Replit Deployments en remplacement de Vercel.

## Architecture actuelle

- **Frontend**: React 19 + Vite (SPA)
- **Backend**: Express.js avec Node.js
- **Base de données**: PostgreSQL (Neon)
- **Pages du site public**: Toutes les routes `/website/*` (home, pricing, features, support, contact, FAQ, blog, etc.)

Le serveur Express sert à la fois :
- L'API backend (`/api/*`)
- Les fichiers statiques du frontend (build Vite)
- Le fallback SPA vers `index.html` pour toutes les routes non-API

## Type de déploiement

**Replit Deployments - Production (Web Service)**

Ce n'est PAS un déploiement statique car l'application nécessite le serveur Express pour :
- Servir l'API backend
- Gérer les routes SPA avec fallback
- Connexion à la base de données

## Commandes npm

```json
{
  "build": "tsx script/build.ts",
  "start": "NODE_ENV=production node dist/index.cjs"
}
```

### Configuration Replit Deployments

- **Build Command**: `npm install && npm run build`
- **Run Command**: `npm run start`
- **Port**: 5000 (automatiquement détecté)

## Variables d'environnement requises

Les variables suivantes doivent être configurées dans les secrets Replit (onglet "Secrets") :

| Variable | Description | Obligatoire |
|----------|-------------|-------------|
| `DATABASE_URL` | URL de connexion PostgreSQL Neon | Oui |
| `SENDGRID_API_KEY` | Clé API SendGrid pour les emails | Oui |
| `STRIPE_SECRET_KEY` | Clé secrète Stripe | Oui |
| `STRIPE_WEBHOOK_SECRET` | Secret webhook Stripe | Oui |
| `OPENAI_API_KEY` | Clé API OpenAI (chat widget) | Optionnel |

**Note**: Les variables `PGHOST`, `PGUSER`, `PGPASSWORD`, `PGDATABASE`, `PGPORT` sont automatiquement configurées par Replit si vous utilisez leur base de données intégrée.

## Étapes de déploiement

### 1. Tester en local sur Replit

Avant tout changement DNS, vérifiez que l'application fonctionne :

1. Cliquez sur "Deploy" dans le panneau Replit
2. Sélectionnez "Production"
3. Configurez les commandes build/start
4. Lancez le déploiement
5. Testez l'URL Replit générée (ex: `votre-app.replit.app`)

### 2. Vérifier les routes du site public

Testez ces URLs sur le déploiement Replit (avant DNS) :

- `/website` - Page d'accueil
- `/website/pricing` - Tarifs
- `/website/features` - Fonctionnalités
- `/website/support` - Support & FAQ
- `/website/contact` - Contact
- `/website/faq` - FAQ
- `/website/blog` - Blog

**Important**: Testez le refresh direct sur chaque page pour vérifier le fallback SPA.

### 3. Configurer le domaine personnalisé

#### Ajouter www.koomy.app (étape 1 - recommandé en premier)

1. Dans Replit, allez dans "Deployments" > votre déploiement
2. Cliquez sur "Custom Domains"
3. Ajoutez `www.koomy.app`
4. Replit vous donnera un enregistrement CNAME cible

#### Configurer le DNS pour www

Dans votre gestionnaire DNS (Cloudflare, etc.) :

```
Type: CNAME
Nom: www
Cible: [valeur fournie par Replit]
TTL: 300 (ou Auto)
Proxy: Désactivé (si Cloudflare)
```

Attendez la propagation DNS (5-30 minutes).

### 4. Configurer le domaine apex (koomy.app)

Après avoir vérifié que www fonctionne :

1. Ajoutez `koomy.app` dans les domaines personnalisés Replit
2. Configurez le DNS :

**Option A - ALIAS/ANAME (recommandé si supporté)**
```
Type: ALIAS ou ANAME
Nom: @ (ou vide)
Cible: [valeur fournie par Replit]
```

**Option B - Enregistrements A (si ALIAS non supporté)**
```
Type: A
Nom: @ (ou vide)
Valeur: [IP fournie par Replit]
```

### 5. Configurer la redirection canonique

Pour éviter le contenu dupliqué et améliorer le SEO, choisissez une URL canonique.

**Recommandation**: Rediriger `www.koomy.app` → `koomy.app` (apex comme principal)

#### Option 1: Via Replit (si disponible)
Configurez la redirection dans les paramètres du domaine Replit.

#### Option 2: Via Cloudflare
Créez une règle de redirection :
- Si URL correspond à `www.koomy.app/*`
- Rediriger vers `https://koomy.app/$1`
- Code: 301 (permanent)

#### Option 3: Via Express (fallback)
Ajouter dans `server/index.ts` avant les routes :

```typescript
app.use((req, res, next) => {
  if (req.hostname === 'www.koomy.app') {
    return res.redirect(301, `https://koomy.app${req.originalUrl}`);
  }
  next();
});
```

## Stratégie de bascule DNS (minimiser le downtime)

### Chronologie recommandée

1. **J-1**: Réduire le TTL DNS à 300 secondes sur Vercel
2. **J0 - 09:00**: Déployer sur Replit, tester l'URL Replit
3. **J0 - 10:00**: Ajouter www.koomy.app sur Replit, mettre à jour le CNAME
4. **J0 - 10:30**: Vérifier que www fonctionne sur Replit
5. **J0 - 11:00**: Ajouter koomy.app sur Replit, mettre à jour le DNS apex
6. **J0 - 11:30**: Vérifier que l'apex fonctionne
7. **J0 - 12:00**: Configurer la redirection canonique
8. **J+1**: Remonter le TTL DNS à 3600+ secondes
9. **J+7**: Supprimer le déploiement Vercel

### En cas de problème

Si un problème survient après la bascule DNS :
1. Remettez les DNS vers Vercel (TTL court = propagation rapide)
2. Diagnostiquez le problème sur Replit
3. Réessayez quand résolu

## HTTPS

Replit gère automatiquement les certificats SSL/TLS via Let's Encrypt. Aucune configuration manuelle n'est nécessaire.

## Vérifications post-déploiement

- [ ] Toutes les pages `/website/*` chargent correctement
- [ ] Le refresh direct fonctionne sur chaque page
- [ ] Le formulaire de contact fonctionne
- [ ] Le chat widget fonctionne
- [ ] Les APIs backend répondent (`/api/...`)
- [ ] HTTPS actif sur tous les domaines
- [ ] Redirection canonique fonctionne
- [ ] Performance acceptable (< 3s de chargement initial)

## Support

En cas de problème avec le déploiement Replit :
- Documentation Replit: https://docs.replit.com/hosting/deployments
- Support Replit: support@replit.com
