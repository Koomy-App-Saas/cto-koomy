# Audits

Documents d'audit analysant l'état actuel d'un domaine fonctionnel ou technique.

## Convention de nommage

```
YYYY-MM-DD__DOMAIN__TOPIC__AUDIT.md
```

## Sous-dossiers par domaine

- `AUTH/` - Authentification, sessions, tokens
- `ROLES/` - Permissions, rôles, accès
- `PAYMENTS/` - Stripe, facturation, abonnements
- `ONBOARDING/` - Inscription, claim, activation
- `SECURITY/` - Vulnérabilités, conformité
- `WL/` - White-label, multi-tenant
- `OTHER/` - Autres domaines

## Exemples

```
2026-01-21__AUTH__admin_login_500__AUDIT.md
2026-01-19__ONBOARDING__self_enrollment_flow__AUDIT.md
```
