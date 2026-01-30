# KOOMY — DB-SAFE MODE

## Post-migration Verification (MANDATORY)

### Objectif
À partir de maintenant, toute PR qui touche au schéma DB (tables / colonnes / enums / index / contraintes) doit livrer :
1) SQL migration exact (copiable)
2) SQL de vérification d'existence (copiable)
3) SQL test minimal (copiable)
4) Rollback SQL (si possible)

Sans ça, le rapport est invalide.

---

## 1) Rapport obligatoire
À la fin de chaque implémentation DB-impactante, produire un rapport dans :
`/docs/_daily/YYYY/MM/YYYY-MM-DD/reports/YYYY-MM-DD__DB__<description>__REPORT.md`

Le rapport doit contenir exactement ces sections :

### A) Database Changes Summary
- Tables created: YES/NO (liste)
- Columns added: YES/NO (liste)
- Enums created/updated: YES/NO (liste)
- Index/constraints added: YES/NO (liste)
- Backward compatible: YES/NO (explication courte)

### B) SQL Migration (Exact)
Inclure le SQL exact utilisé (drizzle ou manuel). Copiable tel quel.

### C) SQL Verification (Existence)
Fournir les requêtes SQL pour vérifier :
1. existence des tables
2. existence des colonnes
3. existence des enums (si utilisés)
4. defaults & nullable (si critique)

Les requêtes doivent être ciblées sur les objets modifiés uniquement.

### D) SQL Minimal Runtime Test
Fournir 1 à 3 requêtes simples qui prouvent que les endpoints principaux ne planteront pas (ex: SELECT sur colonnes nouvellement créées).

### E) Rollback SQL (If Possible)
Fournir le rollback SQL (DROP COLUMN/TYPE/INDEX), ou indiquer explicitement pourquoi impossible.

---

## 2) Templates SQL à utiliser

### Tables existence
```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema='public'
  AND table_name IN ('<table1>','<table2>');
```

### Columns existence
```sql
SELECT table_name, column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema='public'
  AND table_name='<table>'
  AND column_name IN ('<col1>','<col2>');
```

### Enum existence (Postgres)
```sql
SELECT typname
FROM pg_type
WHERE typname = '<enum_name>';
```

### Enum values
```sql
SELECT e.enumlabel
FROM pg_type t
JOIN pg_enum e ON t.oid = e.enumtypid
WHERE t.typname = '<enum_name>'
ORDER BY e.enumsortorder;
```

---

## 3) Acceptance Gate (NO EXCEPTION)

- Si une colonne manque en DB → fournir SQL ALTER TABLE exact à exécuter manuellement.
- Si une table manque → fournir CREATE TABLE exact.
- Si un enum manque → fournir CREATE TYPE exact.
- **Tant que la vérification n'est pas fournie → ne pas dire "terminé".**
