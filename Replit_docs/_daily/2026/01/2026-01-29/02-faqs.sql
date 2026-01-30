-- ============================================
-- TABLE: faqs (6 rows)
-- ============================================
INSERT INTO faqs (id, question, answer, category, target_role) VALUES
('376a83dd-19dc-434a-9bf0-890c8cfc7dbe', 'How do I access my digital membership card?', 'Your digital membership card is available in the ''Membership'' section of the mobile app. It includes a QR code that can be scanned for verification.', 'Membership', 'member'),
('5d975ea5-0c8c-4fb2-99cd-1d156bc2c311', 'How do I add new members to my community?', 'Navigate to the Members section in the admin portal, click ''Add Member'', and fill in their details. They will receive an invitation email to set up their account.', 'Member Management', 'admin'),
('6b62a380-c9af-48e2-a8af-f43c05b13886', 'How can I update my contribution status?', 'Contact your community administrator or use the payment section in your profile to update contribution information.', 'Contributions', 'member'),
('72bd7e5d-b472-4cd4-a737-938e0cb1db6e', 'Can I publish news to specific sections only?', 'Yes! When creating news, select ''Local'' scope and choose the target section. Only members of that section will see the article.', 'Content Management', 'admin'),
('86bc5f65-261c-47c2-be1c-f71611bcf648', 'How do I upgrade my community''s subscription plan?', 'Go to Settings > Subscription in your admin portal. Select the desired plan and complete the payment process.', 'Billing', 'admin'),
('8bf7ffaa-4b51-4dfd-a70b-d15f3ae40471', 'How do I contact my community administrators?', 'Use the Messages tab in the app to send direct messages to administrators or delegates in your community.', 'Support', 'member');
