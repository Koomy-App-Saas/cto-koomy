# Feature : Articles → Assignation à plusieurs sections

**Date :** 11 janvier 2026  
**Auteur :** Agent Replit  
**Classification :** LOW RISK  
**Statut :** ANALYSE UNIQUEMENT — AUCUN CODE

---

## 1) Résumé de l'évolution

### Constat actuel

La table `newsArticles` possède une colonne `section` de type `text` (nullable) :

```
newsArticles.section: text | null
```

**Comportement actuel :**
- `section = null` → Article global (visible par tous)
- `section = "Jeunes"` → Article visible uniquement par les membres de la section "Jeunes"

**Limitation :** Un article ne peut être assigné qu'à UNE SEULE section.

### Objectif

Permettre d'assigner **un article à plusieurs sections** :
- 0 section → article global (comportement inchangé)
- 1+ sections → article visible par les membres de ces sections

### Patterns existants

Le codebase utilise déjà une table de liaison pour les tags d'articles :

```
articleTags (article_tags)
├── id: varchar(50) PK
├── articleId: FK → newsArticles.id
├── tagId: FK → tags.id
└── createdAt: timestamp
```

**→ Appliquer le même pattern pour les sections.**

---

## 2) Modification MINIMALE du modèle de données

### Nouvelle table : `articleSections`

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | varchar(50) | PK UUID auto-généré |
| `articleId` | varchar(50) | FK → newsArticles.id (NOT NULL) |
| `sectionId` | varchar(50) | FK → sections.id (NOT NULL) |
| `createdAt` | timestamp | Date création |

**Contrainte d'unicité :** `UNIQUE(articleId, sectionId)` — évite les doublons.

### Colonne existante `newsArticles.section`

| Option | Description | Recommandation |
|--------|-------------|----------------|
| A | Supprimer immédiatement | ❌ Breaking change |
| B | Conserver + déprécier | ✅ Rétro-compatible |
| C | Migrer puis supprimer V2 | ✅ Safe |

**Recommandation :** Option B puis C

1. **V1 :** Conserver `section` pour lecture legacy, écrire dans `articleSections`
2. **V2 :** Migration des données `section` → `articleSections`, puis suppression colonne

### Logique de résolution (V1 hybride)

```
POUR déterminer les sections d'un article :
  SI articleSections contient des entrées pour cet articleId
    ALORS utiliser articleSections
  SINON SI newsArticles.section IS NOT NULL
    ALORS utiliser newsArticles.section (legacy)
  SINON
    article global
```

---

## 3) Stratégie de rétro-compatibilité

### Phase 1 : Ajout table (backward compatible)

| Étape | Action | Impact |
|-------|--------|--------|
| 1 | Créer table `articleSections` | Aucun impact existant |
| 2 | Modifier création article (back-office) | Écrire dans `articleSections` au lieu de `section` |
| 3 | Modifier édition article | Idem |
| 4 | Modifier lecture articles | Résolution hybride (nouvelle table OU colonne legacy) |

### Phase 2 : Migration données (optionnelle V2)

| Étape | Action |
|-------|--------|
| 1 | Script migration : pour chaque article avec `section` non null, créer entrée `articleSections` |
| 2 | Vérifier 100% données migrées |
| 3 | Supprimer colonne `newsArticles.section` |

### Garantie zéro breaking change

- Les articles existants avec `section` rempli **continuent de fonctionner**
- La résolution hybride assure la compatibilité
- Aucune modification des routes API existantes (même signature)

---

## 4) Impact sur création d'article

### Actuel (back-office + API)

```
POST /api/communities/:id/news
Body: { title, summary, content, section?, scope, ... }
```

`section` = string nullable (nom de section)

### Évolution V1

```
POST /api/communities/:id/news
Body: { title, summary, content, sectionIds?, scope, ... }
```

`sectionIds` = string[] (tableau d'IDs de sections)

**Logique backend :**
1. Créer article dans `newsArticles` (sans remplir `section`)
2. Pour chaque `sectionId` fourni, insérer dans `articleSections`
3. Si `sectionIds` vide ou absent → article global

### Rétro-compatibilité API

| Paramètre reçu | Comportement |
|----------------|--------------|
| `sectionIds: ["uuid1", "uuid2"]` | Utiliser nouvelle logique |
| `section: "Jeunes"` (legacy) | Résoudre ID section par nom, insérer dans `articleSections` |
| Aucun des deux | Article global |

---

## 5) Impact sur édition d'article

### Actuel

```
PATCH /api/communities/:id/news/:articleId
Body: { section?, ... }
```

### Évolution V1

```
PATCH /api/communities/:id/news/:articleId
Body: { sectionIds?, ... }
```

**Logique backend :**
1. Supprimer toutes les entrées `articleSections` pour cet articleId
2. Insérer les nouvelles associations
3. Optionnel : vider `newsArticles.section` si migration progressive

### Comportement UI back-office

| Action | Résultat |
|--------|----------|
| Décocher toutes les sections | Article devient global |
| Cocher 1+ sections | Article restreint à ces sections |
| Éditer article legacy (avec `section`) | Migrer vers `articleSections` à l'enregistrement |

---

## 6) Impact sur affichage des articles

### Actuel (filtrage côté storage)

```typescript
// server/storage.ts - searchCommunityNews()
if (section) {
  conditions.push(eq(newsArticles.section, section));
}
```

### Évolution V1

```typescript
// Pseudo-code logique
if (section) {
  // Filtrer articles dont :
  // - articleSections contient une entrée avec cette sectionId
  // - OU newsArticles.section = sectionName (legacy)
}
```

### Règle de visibilité membre

Un article est visible par un membre si :

```
(article est global)
OU
(membre.sections ∩ article.sections ≠ ∅)
```

Où `article.sections` = résolution hybride (nouvelle table + legacy).

### Impact performance

| Aspect | Évaluation |
|--------|------------|
| JOIN supplémentaire | Négligeable (index sur articleId) |
| Nombre d'entrées | ~1-3 sections par article en moyenne |
| Requête mobile | Ajouter LEFT JOIN ou sous-requête |

---

## 7) Impact par surface

### Backend (server/)

| Fichier | Modification |
|---------|--------------|
| `shared/schema.ts` | Ajouter table `articleSections` + relations |
| `server/storage.ts` | Modifier `createNews`, `updateNews`, `searchCommunityNews` |
| `server/routes.ts` | Accepter `sectionIds[]` dans body, valider existence sections |

### Back-office web (client/src/pages/admin/)

| Composant | Modification |
|-----------|--------------|
| Formulaire article | Remplacer dropdown section par multi-select |
| Liste articles | Afficher badge(s) section(s) |
| Filtres articles | Inchangé (filtre par 1 section) |

### Back-office mobile (client/src/pages/mobile/admin/)

| Composant | Modification |
|-----------|--------------|
| Formulaire article | Multi-select sections (chips ou checkboxes) |
| Liste articles | Afficher sections (truncate si > 2) |

### App membre (mobile)

| Impact | Description |
|--------|-------------|
| Aucun changement UI | La logique de filtrage est côté API |
| Performance | Légère augmentation latence requête (~10ms) |

---

## 8) Risques évalués

| Risque | Probabilité | Impact | Mitigation |
|--------|-------------|--------|------------|
| Régression articles existants | Faible | Élevé | Résolution hybride garantit rétro-compat |
| Performance dégradée | Très faible | Moyen | Index sur `articleSections.articleId` |
| Confusion UX multi-select | Faible | Faible | Label clair "Sections concernées (optionnel)" |
| Migration données incomplète | Faible | Moyen | Script idempotent, dry-run avant prod |
| Breaking change API | Nul | - | Paramètre `sectionIds` additionnel, `section` accepté |

### Évaluation globale

| Critère | Valeur |
|---------|--------|
| Complexité | Faible |
| Risque prod | LOW |
| Effort estimé | 1-2 jours dev |
| Tests critiques | 5-10 scénarios |

---

## 9) Validation LOW RISK

### Checklist

| Critère | Statut |
|---------|--------|
| Pas de refonte système permissions | ✅ Aucun changement |
| Pas de refonte modèle utilisateur | ✅ Aucun changement |
| Pas de changement multi-tenant | ✅ Aucun changement |
| Pas de breaking change articles existants | ✅ Résolution hybride |
| Pattern existant réutilisé | ✅ Même pattern que `articleTags` |
| Rollback possible | ✅ Supprimer table, revenir à `section` |
| Impact isolé | ✅ Uniquement module articles |

### Conclusion

**Cette feature est confirmée LOW RISK.**

- Modification minimale : 1 table ajoutée
- Pattern éprouvé dans le codebase (`articleTags`)
- Rétro-compatibilité garantie par résolution hybride
- Aucun impact sur les autres modules
- Rollback simple

---

## 10) Prochaines étapes (hors scope)

1. Validation product owner
2. Création migration Drizzle
3. Implémentation storage + routes
4. Modification formulaires back-office
5. Tests unitaires + intégration
6. Déploiement sandbox
7. Rollout production

---

*Fin de l'analyse technique*
