# 📅 Documents Journaliers (_daily)

Ce dossier contient tous les documents **datés** de l'organisation.

## Structure

```
_daily/
└── YYYY/
    └── MM/
        └── YYYY-MM-DD/
            ├── audits/
            ├── reports/
            ├── contracts/
            ├── decisions/
            └── prompts/
```

## Règles de classement

1. **Tout document daté** doit être placé dans le dossier correspondant à sa date
2. La date est extraite du nom du fichier (format `YYYY-MM-DD__...`)
3. Les sous-dossiers internes (`audits/`, `reports/`, etc.) sont créés selon le type de document

## Accès rapide

Pour trouver un document :
- Par date : naviguer vers `YYYY/MM/YYYY-MM-DD/`
- Par type : utiliser la recherche avec le préfixe (ex: `__AUDIT`, `__REPORT`)

## Synchronisation

Ce dossier est conçu pour être synchronisé quotidiennement avec une archive locale.
