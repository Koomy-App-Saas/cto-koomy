# SaaS Status Daily Job - Configuration Cron

## Endpoint

```
POST /api/internal/cron/saas-status
Header: x-cron-secret: <CRON_SECRET>
```

## Ce que fait ce job

Le job quotidien effectue les transitions automatiques de statut SaaS:

| Transition | Délai | Email envoyé |
|------------|-------|--------------|
| IMPAYE_1 → IMPAYE_2 | J+15 | warning_impaye2 |
| IMPAYE_2 → SUSPENDU | J+30 | account_suspended |
| SUSPENDU → RESILIE | J+60 | account_terminated |

Emails d'avertissement préventifs:
- J+27: `suspension_imminent` (3j avant suspension)
- J+57: `termination_imminent` (3j avant résiliation)

## Configuration Railway Cron

### 1. Variables d'environnement

Ajouter dans Railway:
```
CRON_SECRET=<valeur_identique_à_replit>
```

### 2. Configuration du Cron Job

Dans Railway Settings > Cron Jobs:

**Schedule:**
```
0 1 * * *
```
(Exécution à 01:00 UTC = 02:00 Europe/Paris)

**Command:**
```bash
curl -X POST https://api.koomy.app/api/internal/cron/saas-status \
  -H "x-cron-secret: $CRON_SECRET" \
  -H "Content-Type: application/json" \
  --fail-with-body \
  --max-time 120
```

### 3. Monitoring

Le endpoint retourne:
```json
{
  "ok": true,
  "startedAt": "2025-01-12T01:00:00.000Z",
  "durationMs": 1234,
  "transitionsCount": 5,
  "transitionsSample": [...]
}
```

Codes de retour:
- `200`: Job exécuté avec succès
- `401`: Secret invalide
- `409`: Job déjà en cours (protection anti double-run)
- `500`: Erreur interne
- `503`: CRON_SECRET non configuré

## Test manuel

```bash
curl -X POST https://api.koomy.app/api/internal/cron/saas-status \
  -H "x-cron-secret: YOUR_SECRET" \
  -H "Content-Type: application/json"
```

## Sécurité

- Le secret doit être identique entre Replit et Railway
- L'endpoint n'est pas accessible sans le header `x-cron-secret`
- Un **verrou distribué via table DB** (`cron_locks`) empêche les exécutions concurrentes même en multi-instance (Railway replicas)
- Lock ID: `8675309` (arbitraire, unique pour ce job)
- Timeout auto: 10 minutes - si le lock n'est pas libéré, il expire automatiquement
- Table créée automatiquement au premier appel si inexistante
