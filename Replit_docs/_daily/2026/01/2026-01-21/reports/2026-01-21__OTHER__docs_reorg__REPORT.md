# Rapport de Réorganisation Documentaire

**Date**: 2026-01-21  
**Domaine**: OTHER  
**Type**: REPORT

---

## Résumé Exécutif

Réorganisation complète de la documentation Koomy selon une nouvelle arborescence normalisée et une convention de nommage stricte.

| Métrique | Valeur |
|----------|--------|
| Fichiers originaux | 96 |
| Fichiers après réorg | 109 (96 + 10 README + 1 _INDEX + 1 DOC_GOVERNANCE + 1 rapport) |
| Dossiers originaux | 18 |
| Dossiers après réorg | 29 |
| Fichiers perdus | 0 |

---

## Arborescence Finale

```
docs/
├── _INDEX.md                    # Table des matières
├── audits/
│   ├── README.md
│   └── 2026-01/
│       ├── AUTH/      (3 fichiers)
│       ├── ONBOARDING/ (4 fichiers)
│       ├── OTHER/     (5 fichiers)
│       ├── PAYMENTS/  (6 fichiers)
│       ├── ROLES/     (5 fichiers)
│       ├── SECURITY/  (2 fichiers)
│       └── WL/        (2 fichiers)
├── reports/
│   ├── README.md
│   └── 2026-01/       (14 fichiers)
├── decisions/
│   ├── README.md
│   └── 2026-01/       (vide - à peupler)
├── incidents/
│   ├── README.md
│   └── 2026-01/       (5 fichiers)
├── implementation/
│   ├── README.md
│   └── 2026-01/       (18 fichiers)
├── procedures/
│   ├── README.md
│   └── 2026-01/       (14 fichiers)
├── security/
│   ├── README.md
│   ├── audits/        (1 fichier)
│   ├── policies/      (vide)
│   └── reports/       (vide)
├── contracts/
│   ├── README.md
│   ├── DOC_GOVERNANCE.md
│   └── (4 fichiers légaux)
├── snapshots/
│   ├── README.md
│   └── 2026-01/       (10 fichiers)
└── archives/
    ├── README.md
    └── 2026-01/       (4 fichiers + 2 JSON)
```

---

## Table des Déplacements

### Audits

| Ancien chemin | Nouveau chemin |
|---------------|----------------|
| docs/audits/ADMIN_LOGIN_500_FIX_REPORT.md | docs/audits/2026-01/AUTH/2026-01-20__AUTH__admin_login_500_fix__REPORT.md |
| docs/audits/AUDIT_LOGIN_MODAL.md | docs/audits/2026-01/AUTH/2026-01-15__AUTH__login_modal__AUDIT.md |
| docs/audits/AUDIT_WALLET_MEMBERSHIPS.md | docs/audits/2026-01/AUTH/2026-01-15__AUTH__wallet_memberships__AUDIT.md |
| docs/audits/BACKOFFICE_ROLE_SIMPLIFICATION_REPORT.md | docs/audits/2026-01/ROLES/2026-01-20__ROLES__backoffice_role_simplification__REPORT.md |
| docs/audits/ROLE_PRIVILEGES_AUDIT.md | docs/audits/2026-01/ROLES/2026-01-18__ROLES__privileges__AUDIT.md |
| docs/audits/ADMIN_SECTION_SCOPE_HARDENING_REPORT.md | docs/audits/2026-01/ROLES/2026-01-19__ROLES__admin_section_scope_hardening__REPORT.md |
| docs/audits/MATRIX_ENDPOINTS_SCOPES.md | docs/audits/2026-01/ROLES/2026-01-18__ROLES__endpoints_scopes_matrix__AUDIT.md |
| docs/audits/SECURITY_ROLE_NORMALIZATION_REPORT.md | docs/audits/2026-01/ROLES/2026-01-19__ROLES__security_normalization__REPORT.md |
| docs/audits/MEMBERSHIP_PLANS_500_FIX_REPORT.md | docs/audits/2026-01/PAYMENTS/2026-01-20__PAYMENTS__membership_plans_500_fix__REPORT.md |
| docs/audits/OWNER_MEMBERSHIP_FIX_REPORT.md | docs/audits/2026-01/PAYMENTS/2026-01-19__PAYMENTS__owner_membership_fix__REPORT.md |
| docs/audits/audit-adhesion-membres.md | docs/audits/2026-01/PAYMENTS/2026-01-10__PAYMENTS__adhesion_membres__AUDIT.md |
| docs/audits/audit-onboarding-cotisations-et-carte-bancaire.md | docs/audits/2026-01/PAYMENTS/2026-01-10__PAYMENTS__onboarding_cotisations__AUDIT.md |
| docs/audits/audit-parcours-plan-payant.md | docs/audits/2026-01/PAYMENTS/2026-01-12__PAYMENTS__parcours_plan_payant__AUDIT.md |
| docs/audits/audit-self-enrollment.md | docs/audits/2026-01/ONBOARDING/2026-01-10__ONBOARDING__self_enrollment__AUDIT.md |
| docs/audits/audit-emails-self-enrollment.md | docs/audits/2026-01/ONBOARDING/2026-01-10__ONBOARDING__emails_self_enrollment__AUDIT.md |
| docs/audits/SELF_ONBOARDING_PRESENCE_AUDIT.md | docs/audits/2026-01/ONBOARDING/2026-01-19__ONBOARDING__self_onboarding_presence__AUDIT.md |
| docs/audits/audit-parcours-acquisition-website.md | docs/audits/2026-01/ONBOARDING/2026-01-12__ONBOARDING__parcours_acquisition__AUDIT.md |
| docs/audits/security-audit-replit.md | docs/audits/2026-01/SECURITY/2026-01-15__SECURITY__replit_audit__AUDIT.md |
| docs/audits/AUDIT_REPLIT_INFRA.md | docs/audits/2026-01/SECURITY/2026-01-15__SECURITY__replit_infra__AUDIT.md |
| docs/audits/AUDIT_LORPESIKOOMYADMIN.md | docs/audits/2026-01/WL/2026-01-15__WL__lorpesikoomyadmin__AUDIT.md |
| docs/audits/AUDIT — Emails Transactionnels Clients SaaS.md | docs/audits/2026-01/OTHER/2026-01-12__OTHER__emails_transactionnels_saas__AUDIT.md |
| docs/audits/audit-mail-client-saas.md | docs/audits/2026-01/OTHER/2026-01-12__OTHER__mail_client_saas__AUDIT.md |
| docs/audits/audit-saas-clients-impayés.md | docs/audits/2026-01/OTHER/2026-01-14__OTHER__saas_clients_impayes__AUDIT.md |
| docs/audits/KOOMY_AUDIT_PLAN_VS_CAPACITY.md | docs/audits/2026-01/OTHER/2026-01-15__OTHER__plan_vs_capacity__AUDIT.md |
| docs/audits/TEST_CONTRACT_REPORT.md | docs/audits/2026-01/OTHER/2026-01-21__OTHER__test_contract__REPORT.md |
| docs/Questions/AUDIT_CODE_ADHESION.md | docs/audits/2026-01/PAYMENTS/2026-01-15__PAYMENTS__code_adhesion__AUDIT.md |
| docs/Démo/SANDBOX_WL_AUDIT_REPORT.md | docs/audits/2026-01/WL/2026-01-08__WL__sandbox_audit__AUDIT.md |

### Reports

| Ancien chemin | Nouveau chemin |
|---------------|----------------|
| docs/rapports/12-01_COMMIT_REPORT.md | docs/reports/2026-01/2026-01-12__OTHER__commit_report__REPORT.md |
| docs/rapports/bilan-implementation-self-onboarding-v1.md | docs/reports/2026-01/2026-01-15__ONBOARDING__self_onboarding_bilan__REPORT.md |
| docs/rapports/rapport-implementation-saas-paiement.md | docs/reports/2026-01/2026-01-14__PAYMENTS__saas_paiement_implementation__REPORT.md |
| docs/rapports/REPORT_LOGIN_MODAL_V1_1.md | docs/reports/2026-01/2026-01-16__AUTH__login_modal_v1_1__REPORT.md |
| docs/rapports/REPORT_STRIPE_ENV_FIX.md | docs/reports/2026-01/2026-01-17__PAYMENTS__stripe_env_fix__REPORT.md |
| docs/rapports/SELF_ONBOARDING_UI_PHASE4_REPORT.md | docs/reports/2026-01/2026-01-18__ONBOARDING__ui_phase4__REPORT.md |
| docs/rapports/STRIPE_WEBHOOK_FIX_REPORT.md | docs/reports/2026-01/2026-01-17__PAYMENTS__stripe_webhook_fix__REPORT.md |
| docs/debug/BUILD_PROOF.md | docs/reports/2026-01/2026-01-14__INFRA__build_proof__REPORT.md |
| docs/debug/BUILD_PROOF_PAGES_REDIRECTS.md | docs/reports/2026-01/2026-01-14__INFRA__build_proof_pages_redirects__REPORT.md |
| docs/Testing/stripe-connect-fix.md | docs/reports/2026-01/2026-01-16__PAYMENTS__stripe_connect_fix__REPORT.md |
| docs/Démo/SANDBOX_UNSA_NEUTRALIZATION_REPORT.md | docs/reports/2026-01/2026-01-08__WL__sandbox_unsa_neutralization__REPORT.md |
| docs/Démo/SANDBOX_WL_PHASE1_2_REPORT.md | docs/reports/2026-01/2026-01-09__WL__sandbox_phase1_2__REPORT.md |
| docs/architecture/POST_MIGRATION_RESERVED_VM_VALIDATION.md | docs/reports/2026-01/2026-01-05__INFRA__post_migration_vm_validation__REPORT.md |

### Implementation

| Ancien chemin | Nouveau chemin |
|---------------|----------------|
| docs/implementation/INVENTAIRE_NETTOYAGE.md | docs/implementation/2026-01/2026-01-10__OTHER__inventaire_nettoyage__SPEC.md |
| docs/implementation/KOOMY_BILLING_PERIOD_CHOICE_REPORT.md | docs/implementation/2026-01/2026-01-15__PAYMENTS__billing_period_choice__REPORT.md |
| docs/implementation/KOOMY_GENERIC_PAID_UPGRADE_IMPLEMENTATION.md | docs/implementation/2026-01/2026-01-16__PAYMENTS__generic_paid_upgrade__PLAN.md |
| docs/implementation/KOOMY_OPTION_A_IMPLEMENTATION_REPORT.md | docs/implementation/2026-01/2026-01-17__PAYMENTS__option_a_implementation__REPORT.md |
| docs/implementation/KOOMY_OPTION_A_UPGRADE_IMPLEMENTATION.md | docs/implementation/2026-01/2026-01-17__PAYMENTS__option_a_upgrade__PLAN.md |
| docs/implementation/RAPPORT_IMPLEMENTATION_CODE_ACTIVATION_V2.md | docs/implementation/2026-01/2026-01-18__ONBOARDING__code_activation_v2__REPORT.md |
| docs/implementation/rapport-implementation-onboarding-simplifie.md | docs/implementation/2026-01/2026-01-15__ONBOARDING__onboarding_simplifie__REPORT.md |
| docs/implementation/rapport-implementation-parcours-acquisition.md | docs/implementation/2026-01/2026-01-14__ONBOARDING__parcours_acquisition__REPORT.md |
| docs/plans/DEPLOYMENT.md | docs/implementation/2026-01/2026-01-08__INFRA__deployment__PLAN.md |
| docs/plans/PLAN_CTA_DEMO.md | docs/implementation/2026-01/2026-01-12__UI__cta_demo__PLAN.md |
| docs/plans/plan-implementation-saas-paiement.md | docs/implementation/2026-01/2026-01-13__PAYMENTS__saas_paiement__PLAN.md |
| docs/plans/plan-limits.md | docs/implementation/2026-01/2026-01-10__OTHER__plan_limits__SPEC.md |
| docs/plans/plan-self-enrollment-v1.md | docs/implementation/2026-01/2026-01-12__ONBOARDING__self_enrollment_v1__PLAN.md |
| docs/features/enterprise-accounts.md | docs/implementation/2026-01/2026-01-05__OTHER__enterprise_accounts__SPEC.md |
| docs/features/feature-articles-multi-sections.md | docs/implementation/2026-01/2026-01-10__UI__articles_multi_sections__SPEC.md |
| docs/features/FONCTIONNALITES_INCOMPLETES.md | docs/implementation/2026-01/2026-01-15__OTHER__fonctionnalites_incompletes__SPEC.md |
| docs/features/remove-promotion-banner.md | docs/implementation/2026-01/2026-01-08__UI__remove_promotion_banner__SPEC.md |
| docs/features/rich-text-editor.md | docs/implementation/2026-01/2026-01-08__UI__rich_text_editor__SPEC.md |

### Procedures

| Ancien chemin | Nouveau chemin |
|---------------|----------------|
| docs/guides/ANDROID_BUILD_GUIDE.md | docs/procedures/2026-01/2026-01-10__INFRA__android_build__PROCEDURE.md |
| docs/guides/CRON_SAAS_STATUS.md | docs/procedures/2026-01/2026-01-12__INFRA__cron_saas_status__PROCEDURE.md |
| docs/guides/DEPLOY_PUBLIC_SITE_REPLIT.md | docs/procedures/2026-01/2026-01-10__INFRA__deploy_public_site_replit__PROCEDURE.md |
| docs/guides/railway-env-vars.md | docs/procedures/2026-01/2026-01-08__INFRA__railway_env_vars__PROCEDURE.md |
| docs/guides/README_MOBILE.md | docs/procedures/2026-01/2026-01-10__INFRA__readme_mobile__PROCEDURE.md |
| docs/guides/store-release.md | docs/procedures/2026-01/2026-01-10__INFRA__store_release__PROCEDURE.md |
| docs/debug/PRE_PUSH_CHECK.md | docs/procedures/2026-01/2026-01-12__INFRA__pre_push_check__CHECKLIST.md |

### Incidents

| Ancien chemin | Nouveau chemin |
|---------------|----------------|
| docs/debug/ANDROID_AUTH_PERSISTENCE_REPORT.md | docs/incidents/2026-01/2026-01-15__AUTH__android_auth_persistence__INCIDENT.md |
| docs/debug/ANDROID_LOGIN_404_ROOTCAUSE.md | docs/incidents/2026-01/2026-01-15__AUTH__android_login_404_rootcause__INCIDENT.md |
| docs/debug/ANDROID_LOGIN_DEBUG_REPORT.md | docs/incidents/2026-01/2026-01-15__AUTH__android_login_debug__INCIDENT.md |
| docs/debug/AUTH_ANDROID_404_REPORT.md | docs/incidents/2026-01/2026-01-15__AUTH__android_404__INCIDENT.md |
| docs/debug/CORS_MOBILE.md | docs/incidents/2026-01/2026-01-14__INFRA__cors_mobile__INCIDENT.md |

### Snapshots

| Ancien chemin | Nouveau chemin |
|---------------|----------------|
| docs/architecture/API_KOOMY_REFERENCE.md | docs/snapshots/2026-01/2026-01-01__DATA__api_koomy_reference__SPEC.md |
| docs/architecture/architecture.md | docs/snapshots/2026-01/2026-01-01__INFRA__architecture__SPEC.md |
| docs/architecture/KOOMY_ANALYSE_CAPACITE.md | docs/snapshots/2026-01/2026-01-01__OTHER__analyse_capacite__SPEC.md |
| docs/architecture/koomy-capabilities-inventory.md | docs/snapshots/2026-01/2026-01-01__OTHER__capabilities_inventory__SPEC.md |
| docs/architecture/Koomy - Technical Documentation.md | docs/snapshots/2026-01/2026-01-01__INFRA__technical_documentation__SPEC.md |
| docs/architecture/KOOMY_TECHNICAL_DOCUMENTATION.md | docs/snapshots/2026-01/2026-01-01__INFRA__technical_documentation_v2__SPEC.md |
| docs/brand/KOOMY_DESIGN_SYSTEM_V1.md | docs/snapshots/2026-01/2026-01-01__UI__design_system_v1__SPEC.md |
| docs/Démo/sandbox-port-bouet-fc.md | docs/snapshots/2026-01/2026-01-06__WL__demo_port_bouet_fc__SPEC.md |
| docs/Démo/sandbox-scenario-02-aper-robertsau.md | docs/snapshots/2026-01/2026-01-06__WL__demo_aper_robertsau__SPEC.md |
| docs/Démo/sandbox-scenario-03-chorale-sainte-aurelie.md | docs/snapshots/2026-01/2026-01-06__WL__demo_chorale_sainte_aurelie__SPEC.md |

### Archives

| Ancien chemin | Nouveau chemin |
|---------------|----------------|
| docs/features/sandbox-port-bouet-fc.md | docs/archives/2026-01/2026-01-10__WL__sandbox_port_bouet_fc__SPEC.md |
| docs/faq/koomy-faq.md | docs/archives/2026-01/2026-01-01__OTHER__koomy_faq__SPEC.md |
| docs/faq/koomy-faq-questions.md | docs/archives/2026-01/2026-01-01__OTHER__koomy_faq_questions__SPEC.md |
| docs/unsa-lidl/cleanup-strasbourg.md | docs/archives/2026-01/2026-01-05__WL__unsa_lidl_cleanup_strasbourg__SPEC.md |

### Contracts

| Ancien chemin | Nouveau chemin |
|---------------|----------------|
| docs/legal/addendum-adhesion-decisions.md | docs/contracts/2026-01-10__OTHER__addendum_adhesion_decisions__SPEC.md |
| docs/legal/addendum-saas-clients-cgv.md | docs/contracts/2026-01-10__OTHER__addendum_saas_clients_cgv__SPEC.md |
| docs/legal/cgv-base-travail.md | docs/contracts/2026-01-01__OTHER__cgv_base_travail__SPEC.md |
| docs/legal/conformite-hebergement-donnees.md | docs/contracts/2026-01-05__SECURITY__conformite_hebergement_donnees__SPEC.md |

### Security

| Ancien chemin | Nouveau chemin |
|---------------|----------------|
| docs/Sécurité/Vulnérabilités critiques Node.md | docs/security/audits/2026-01-15__SECURITY__vulnerabilites_critiques_node__AUDIT.md |

---

## Cas Ambigus

| Fichier | Décision | Raison |
|---------|----------|--------|
| Architecture docs | → snapshots/ | Documents de référence historique, pas d'audits actifs |
| FAQ docs | → archives/ | Documents de support obsolètes |
| Démo scenarios | → snapshots/ | Scenarios de test figés |
| Dates inférées (2026-01-01) | date_inferred | Date exacte non disponible, mois courant utilisé |

---

## Dossiers Supprimés (vides)

- docs/architecture
- docs/rapports
- docs/debug
- docs/guides
- docs/plans
- docs/features
- docs/faq
- docs/legal
- docs/brand
- docs/Démo
- docs/Sécurité
- docs/Testing
- docs/Questions
- docs/unsa-lidl
- docs/Procédures

---

## Documents Créés

| Fichier | Type |
|---------|------|
| docs/_INDEX.md | Table des matières |
| docs/audits/README.md | Guide dossier |
| docs/reports/README.md | Guide dossier |
| docs/decisions/README.md | Guide dossier |
| docs/incidents/README.md | Guide dossier |
| docs/implementation/README.md | Guide dossier |
| docs/procedures/README.md | Guide dossier |
| docs/security/README.md | Guide dossier |
| docs/contracts/README.md | Guide dossier |
| docs/snapshots/README.md | Guide dossier |
| docs/archives/README.md | Guide dossier |
| docs/contracts/DOC_GOVERNANCE.md | Gouvernance documentaire |

---

## Risques / Points à Valider

1. **Liens internes**: Les documents ne contenaient pas de liens internes significatifs à mettre à jour.
2. **Dates inférées**: 10 fichiers ont une date du 2026-01-01 inférée faute de date claire dans le nom.
3. **Procédures**: Tous les 7 fichiers du dossier Procédures ont été déplacés avec succès.

---

## Prochaines Étapes

1. Formaliser les premières décisions ADR dans decisions/
2. Remplir les dossiers security/policies/ et security/reports/
3. Mettre à jour _INDEX.md lors de chaque nouveau document structurant

---

**Rapport généré automatiquement**  
**Trace ID**: DOCS-REORG-2026-01-21
