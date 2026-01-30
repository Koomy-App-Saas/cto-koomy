# KOOMY — Smoke Tests MANUELS post-Option C

**Date**: 2026-01-22  
**Version**: 1.0  
**Environnement cible**: Sandbox

---

## A) STANDARD (Site Public)

### URL de test
`sitepublic-sandbox.koomy.app/register?plan=pro`

### Étapes
1. [ ] Ouvrir l'URL d'inscription
2. [ ] S'inscrire via Firebase (email/password OU Google)
3. [ ] Vérifier la redirection post-inscription

### Vérifications
| Check | Attendu | Résultat |
|-------|---------|----------|
| Redirection | OK vers dashboard | [ ] PASS [ ] FAIL |
| Community créée | Visible dans dashboard | [ ] PASS [ ] FAIL |
| Dashboard accessible | Pas d'erreur 403/500 | [ ] PASS [ ] FAIL |
| Subscription status | `trialing` | [ ] PASS [ ] FAIL |
| Trial affiché | ~14 jours restants | [ ] PASS [ ] FAIL |
| Demande CB | Aucune | [ ] PASS [ ] FAIL |
| Checkout Stripe | Aucun | [ ] PASS [ ] FAIL |

---

## B) White-Label (WL)

### Prérequis
- Host WL sandbox configuré (ex: `wl-sandbox.koomy.app`)

### Étapes
1. [ ] Ouvrir le host WL sandbox
2. [ ] Tenter login Google/Firebase
3. [ ] Tenter login legacy admin WL

### Vérifications
| Check | Attendu | Résultat |
|-------|---------|----------|
| Login Firebase | 403 / "Non autorisé" | [ ] PASS [ ] FAIL |
| Login Google | 403 / "Non autorisé" | [ ] PASS [ ] FAIL |
| Login Legacy admin | Accès OK | [ ] PASS [ ] FAIL |
| Dashboard WL | Fonctionnel | [ ] PASS [ ] FAIL |

---

## C) SaaS Owner Platform

### URL de test
`saasowner-sandbox.koomy.app`

### Étapes
1. [ ] Login legacy SaaS Owner
2. [ ] Accéder à la liste des communities
3. [ ] Accéder aux metrics platform

### Vérifications
| Check | Attendu | Résultat |
|-------|---------|----------|
| Login legacy | OK | [ ] PASS [ ] FAIL |
| Liste communities | Visible | [ ] PASS [ ] FAIL |
| Metrics platform | Accessible | [ ] PASS [ ] FAIL |
| Community STANDARD récente | Remonte dans liste | [ ] PASS [ ] FAIL |
| Actions self-service WL | Absentes | [ ] PASS [ ] FAIL |

---

## D) Anti-régression

### Étapes
1. [ ] Créer nouvelle inscription STANDARD (nouvel email)
2. [ ] Vérifier la création user + community
3. [ ] Vérifier les logs

### Vérifications
| Check | Attendu | Résultat |
|-------|---------|----------|
| User créé | Avec community liée | [ ] PASS [ ] FAIL |
| Pas de "user orphelin" | User a au moins 1 membership | [ ] PASS [ ] FAIL |
| Logs Railway/console | Aucune erreur 500 | [ ] PASS [ ] FAIL |
| Identity créée | Row dans `user_identities` | [ ] PASS [ ] FAIL |

---

## Résumé exécution

**Date d'exécution**: ____________________  
**Opérateur**: ____________________

| Section | PASS | FAIL | N/A |
|---------|------|------|-----|
| A) STANDARD | [ ] | [ ] | [ ] |
| B) WL | [ ] | [ ] | [ ] |
| C) SaaS Owner | [ ] | [ ] | [ ] |
| D) Anti-régression | [ ] | [ ] | [ ] |

**Commentaires**:
```
_______________________________________________
_______________________________________________
_______________________________________________
```

---

## Références

- Contrat: `docs/architecture/CONTRAT_IDENTITE_ONBOARDING_2026-01.md`
- Tests automatisés: `npx tsx scripts/contract-tests/runner.ts`
- Rapport Option C: `docs/reports/2026-01-22__REPORT__contract_tests_option_c.md`
