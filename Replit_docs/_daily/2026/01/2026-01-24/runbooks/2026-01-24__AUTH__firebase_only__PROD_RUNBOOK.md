# KOOMY — Firebase-Only Auth Migration PROD RUNBOOK

**Date**: 2026-01-24
**Version**: 1.0
**Durée totale estimée**: 45 minutes

---

## 1. Préflight Checklist

### 1.1 Accès requis

| Ressource | Accès requis | Responsable |
|-----------|--------------|-------------|
| Firebase Console (prod) | Admin | DevOps |
| Railway Dashboard | Admin | DevOps |
| Git repo | Push access | Dev |
| Sandbox validé | QA passé | QA |

### 1.2 Vérifications préalables

- [ ] QA sandbox 12/12 scénarios passés
- [ ] Aucune erreur 401/403 non expliquée en sandbox
- [ ] Compte admin Firebase prod existe et peut se connecter
- [ ] `VITE_FIREBASE_API_KEY` configuré en production
- [ ] Backup base de données récent (< 24h)

### 1.3 Communication

- [ ] Informer l'équipe du déploiement
- [ ] Préparer message maintenance si nécessaire
- [ ] Avoir contacts d'urgence disponibles

---

## 2. Déploiement

### 2.1 Tag Git

```bash
# Vérifier le status
git status

# Créer le tag
git tag -a v2026.01.24-firebase-only -m "Firebase-only auth migration"

# Push le tag
git push origin v2026.01.24-firebase-only
```

**Durée**: 2 minutes

### 2.2 Deploy Railway

1. Aller sur Railway Dashboard
2. Sélectionner le projet Koomy PROD
3. Déclencher un nouveau déploiement
4. Attendre la fin du build

**Durée**: 5-10 minutes

### 2.3 Vérification déploiement

```bash
# Vérifier la version
curl https://api.koomy.app/api/version

# Vérifier le health
curl https://api.koomy.app/health
```

**Attendu**: Status 200, version correspondante

---

## 3. Post-Deploy Checks

### 3.1 Smoke Tests (obligatoires)

| Test | Commande/Action | Attendu | Durée |
|------|-----------------|---------|-------|
| Health | `curl /health` | 200 OK | 30s |
| Version | `curl /api/version` | Version correcte | 30s |
| Admin login | UI backoffice.koomy.app | Connexion réussie | 2 min |
| CRUD section | Créer/modifier/supprimer | 200 OK | 3 min |
| CRUD event | Créer/modifier/supprimer | 200 OK | 3 min |
| CRUD news | Créer/modifier/supprimer | 200 OK | 3 min |

**Durée totale**: 15 minutes

### 3.2 Validation endpoint legacy

```bash
curl -X POST https://api.koomy.app/api/admin/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"test"}'
```

**Attendu**: 
```json
{
  "error": "Cet endpoint n'est plus disponible. Utilisez Firebase Authentication.",
  "code": "LEGACY_LOGIN_DISABLED"
}
```
Status: **410 Gone**

---

## 4. Monitoring (48h)

### 4.1 Logs à surveiller

| Pattern | Signification | Action si détecté |
|---------|---------------|-------------------|
| `FIREBASE_AUTH_REQUIRED` | Token non-Firebase rejeté | OK - comportement attendu |
| `401` + `authType=legacy` | Client legacy détecté | Investiguer le client |
| `tokenLength=33` | Token legacy envoyé | Identifier le client |
| `LEGACY_ENDPOINT_DISABLED` | Appel /api/admin/login | Identifier le client |

### 4.2 Alertes

Configurer alertes si:
- Taux d'erreur 401 > 5% sur 5 min
- Taux d'erreur 500 > 1% sur 5 min

### 4.3 Dashboard

Vérifier quotidiennement:
- Nombre de connexions réussies
- Nombre de 401/403
- Temps de réponse /api/auth/me

---

## 5. Rollback

### 5.1 Critères de rollback

| Critère | Seuil | Action |
|---------|-------|--------|
| Taux erreur 5xx | > 5% pendant 10 min | Rollback immédiat |
| Connexions admin impossibles | > 30 min | Rollback |
| Données corrompues | Tout cas | Rollback + investigate |

### 5.2 Procédure Railway Rollback

1. Aller sur Railway Dashboard
2. Onglet "Deployments"
3. Trouver le déploiement précédent (avant migration)
4. Cliquer "Rollback to this deployment"
5. Confirmer

**Durée**: 5 minutes

### 5.3 Procédure Git Rollback

```bash
# Identifier le commit avant migration
git log --oneline -10

# Revert les commits de migration
git revert HEAD~4..HEAD

# Push
git push origin main
```

**Durée**: 5 minutes

### 5.4 Actions post-rollback

1. [ ] Informer l'équipe
2. [ ] Créer incident report
3. [ ] Analyser les logs
4. [ ] Planifier correction

---

## 6. Timeline Résumé

| Étape | Durée | Cumul |
|-------|-------|-------|
| Préflight | 10 min | 10 min |
| Tag Git | 2 min | 12 min |
| Deploy Railway | 10 min | 22 min |
| Smoke tests | 15 min | 37 min |
| Validation legacy | 3 min | 40 min |
| Buffer | 5 min | 45 min |

**Durée totale**: ~45 minutes

---

## 7. Contacts d'urgence

| Rôle | Contact | Disponibilité |
|------|---------|---------------|
| DevOps Lead | [À compléter] | 24/7 |
| Product Owner | [À compléter] | Heures bureau |
| Firebase Admin | [À compléter] | Heures bureau |

---

## 8. Checklist Finale

### Avant déploiement
- [ ] QA sandbox validé
- [ ] Équipe informée
- [ ] Backup vérifié

### Pendant déploiement
- [ ] Tag créé et pushé
- [ ] Railway deploy déclenché
- [ ] Build réussi

### Après déploiement
- [ ] Smoke tests passés
- [ ] Endpoint legacy retourne 410
- [ ] Monitoring actif

### J+1
- [ ] Aucune alerte critique
- [ ] Connexions admin normales
- [ ] Pas de plaintes utilisateurs

---

**FIN DU RUNBOOK PROD**
