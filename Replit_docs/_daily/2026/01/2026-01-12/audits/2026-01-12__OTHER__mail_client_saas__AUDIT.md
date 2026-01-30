AUDIT — Emails Transactionnels Clients SaaS (Plateforme Koomy)
1. Inventaire des Emails Existants
Clé Email	Trigger	Existe	Template	Langue	Notes
welcome_community_admin	Création compte community (POST /api/communities)	✅ OUI	✅ OUI	FR	Contient code d'activation
owner_admin_credentials	Création owner depuis white-label	✅ OUI	✅ OUI	FR	Login + mot de passe
reset_password	Reset password request	✅ OUI	✅ OUI	FR	Lien de réinitialisation
verify_email	Vérification email platform	✅ OUI	✅ OUI	FR	Code vérification
Emails NON Implémentés (Lifecycle SaaS)
Clé Email	Trigger	Existe	Template	Notes
E01 - Subscription started	invoice.payment_succeeded (1er)	❌ NON	❌ NON	Bienvenue + confirmation abonnement
E02 - Payment success (recurring)	invoice.payment_succeeded	❌ NON	❌ NON	Récurrence mensuelle/annuelle
E03 - Invoice available	invoice.created	❌ NON	❌ NON	Lien facture Stripe
E04 - Payment failed (IMPAYE_1)	transitionSaasStatus → IMPAYE_1	❌ NON	❌ NON	J+0 - Alerte paiement échoué
E05 - Reminder J+7	Daily job + statut IMPAYE_1	❌ NON	❌ NON	Rappel délai de grâce
E06 - Warning IMPAYE_2	transitionSaasStatus → IMPAYE_2	❌ NON	❌ NON	J+15 - Avertissement suspension
E07 - Suspension imminent J+25	Daily job + statut IMPAYE_2	❌ NON	❌ NON	Dernière chance avant suspension
E08 - Account suspended	transitionSaasStatus → SUSPENDU	❌ NON	❌ NON	J+30 - Compte gelé
E09 - Pre-termination warning	Daily job + statut SUSPENDU J+50	❌ NON	❌ NON	10 jours avant résiliation
E10 - Account terminated	transitionSaasStatus → RESILIE	❌ NON	❌ NON	J+60 - Contrat terminé
E11 - Reactivation success	transitionSaasStatus IMPAYE → ACTIVE	❌ NON	❌ NON	Paiement régularisé
E12 - Self-cancellation confirm	Annulation volontaire	❌ NON	❌ NON	Confirmation fin période
E13 - Plan upgrade/downgrade	Changement de plan	❌ NON	❌ NON	Nouvelle cotisation
2. Analyse des Lacunes
🔴 P0 — Emails Critiques (Business-blocking)
Email	Risque si absent	Impact
E04 - Payment failed	Client ne sait pas que son paiement a échoué	100% des impayés ignorés
E08 - Suspension	Accès bloqué sans explication	Support tickets massifs
E10 - Résiliation	Terminaison sans préavis	Litige juridique potentiel
E11 - Réactivation	Client ne sait pas que son accès est rétabli	Confusion, support tickets
🟠 P1 — Emails Importants (UX dégradée)
Email	Risque si absent	Impact
E01 - Subscription started	Pas de confirmation onboarding	UX incomplète
E06 - Warning IMPAYE_2	Escalade sans avertissement clair	Frustration client
E07 - Suspension imminent	Dernière chance non communiquée	Perte évitable
E09 - Pre-termination	Pas de dernier recours	Résiliations évitables
🟢 P2 — Nice-to-have
Email	Bénéfice
E02 - Payment success recurring	Tranquillité d'esprit
E03 - Invoice available	Comptabilité facilitée
E05 - Reminder J+7	Relance douce
E12 - Self-cancellation	Confirmation administrative
E13 - Plan change	Transparence tarification
3. Matrice Email Recommandée (Target)
Phase 1 — P0 Critiques (immédiat)
ID	Email Type	Trigger	Quand Envoyé
E04	saas_payment_failed	Webhook invoice.payment_failed + transition IMPAYE_1	Immédiat après échec paiement
E08	saas_account_suspended	transitionSaasStatus → SUSPENDU	J+30 d'impayé
E10	saas_account_terminated	transitionSaasStatus → RESILIE	J+60 d'impayé
E11	saas_reactivation_success	transitionSaasStatus → ACTIVE depuis IMPAYE/SUSPENDU	Immédiat après régularisation
Phase 2 — P1 Important
ID	Email Type	Trigger	Quand Envoyé
E01	saas_subscription_started	1er invoice.payment_succeeded	Onboarding confirmé
E06	saas_warning_impaye2	transitionSaasStatus → IMPAYE_2	J+15 d'impayé
E07	saas_suspension_imminent	Daily job, IMPAYE_2 + J+25	5j avant suspension
E09	saas_termination_imminent	Daily job, SUSPENDU + J+50	10j avant résiliation
Phase 3 — P2 Nice-to-have
ID	Email Type	Trigger	Quand Envoyé
E02	saas_payment_success	invoice.payment_succeeded (récurrent)	Chaque facturation
E03	saas_invoice_available	invoice.created	Facture générée
E05	saas_reminder_j7	Daily job, IMPAYE_1 + J+7	Rappel doux
E12	saas_cancellation_confirmed	Annulation volontaire	Confirmation fin
E13	saas_plan_changed	Changement de plan	Nouvelle facturation
4. Infrastructure Existante
✅ Déjà en place
Table subscription_emails_sent : Tracking anti-duplicata (communityId, emailType, sentAt, relatedUnpaidSince)
Table subscription_status_audit : Historique complet des transitions
Fonction transitionSaasStatus() : Point d'accroche pour déclencher emails
Pattern sendTransactionalEmail() : Infrastructure d'envoi avec branding
Daily job concept : Référencé dans le code mais non implémenté
SendGrid configuré : Intégration active
🔧 À Implémenter
Nouveaux EmailTypes dans emailTypes.ts
Templates email dans template.ts
Fonctions send* dans sendBrandedEmail.ts
Wiring dans stripe.ts (webhooks) et daily job
Daily job scheduler pour emails temporels (J+7, J+25, J+50)
Recording dans subscription_emails_sent pour éviter doublons
5. Contraintes Techniques
Contrainte	Détail
White-label	Templates doivent utiliser resolveEmailBranding() - pas de "Koomy" hardcodé
Langue	FR uniquement pour l'instant
Anti-duplicata	Utiliser subscription_emails_sent + relatedUnpaidSince comme clé
Ton	Non-technique, rassurant, orienté action
CTA	Lien vers portail de paiement Stripe toujours présent pour impayés
6. Conclusion & Prochaines Étapes
État Actuel
1 seul email SaaS existe : welcome_community_admin (activation compte)
13 emails manquants pour couvrir le cycle de vie complet
4 emails P0 critiques à implémenter en priorité absolue
Recommandation
Phase 1 (P0) : Implémenter E04, E08, E10, E11 — Bloque le risque support/juridique
Phase 2 (P1) : Implémenter E01, E06, E07, E09 — Améliore l'UX et la rétention
Phase 3 (P2) : Implémenter E02, E03, E05, E12, E13 — Polish final
Effort Estimé
Phase 1 : ~2-3h (4 emails + wiring webhooks)
Phase 2 : ~3-4h (4 emails + daily job scheduler)
Phase 3 : ~2h (5 emails simples)