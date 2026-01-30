# Rich Text Editor - Documentation

## Cause racine (Root Cause)

L'éditeur WYSIWYG avait plusieurs bugs critiques :

1. **Curseur instable** : L'utilisation de `dangerouslySetInnerHTML={{ __html: value }}` causait un re-render complet du contenu à chaque frappe, réinitialisant la position du curseur au début.

2. **Formatage non fonctionnel** : Les boutons de la toolbar perdaient le focus de l'éditeur avant d'exécuter la commande `execCommand`, ce qui empêchait le formatage de s'appliquer à la sélection.

3. **Listes incorrectes** : Le re-render constant interférait avec la création native des listes par le navigateur.

## Corrections apportées

### 1. Composant non-contrôlé
- Le contenu HTML n'est plus réinjecté via `dangerouslySetInnerHTML` à chaque changement d'état
- L'initialisation du contenu se fait une seule fois via `useEffect` avec un flag `isInitialized`
- Le composant utilise `suppressContentEditableWarning` pour éviter les warnings React

### 2. Préservation du focus
- Ajout de `onMouseDown={(e) => e.preventDefault()}` sur tous les boutons de la toolbar
- Cela empêche le navigateur de retirer le focus de l'éditeur lors du clic
- Le focus reste dans le contentEditable, préservant la sélection pour le formatage

### 3. Debounce des mises à jour
- Les appels à `onChange` sont maintenant debounced (300ms) pour éviter les re-renders inutiles
- Un appel immédiat est fait sur `onBlur` pour s'assurer que le contenu final est sauvegardé

### 4. Styles CSS explicites
- Ajout de styles CSS pour `b`, `strong`, `i`, `em`, `u` pour garantir le rendu visuel
- Correction des styles de listes avec `list-style-type` et marges appropriées

## Comment tester manuellement

### Test de formatage
1. Ouvrir l'éditeur d'articles dans le back-office
2. Taper du texte
3. Sélectionner une partie du texte
4. Cliquer sur Bold (B) - le texte doit devenir gras
5. Cliquer sur Italic (I) - le texte doit devenir italique
6. Cliquer sur Underline (U) - le texte doit être souligné
7. Vérifier que les raccourcis Ctrl+B, Ctrl+I, Ctrl+U fonctionnent

### Test du curseur
1. Taper un long paragraphe
2. Vérifier que le curseur reste à la position de frappe
3. Attendre quelques secondes (debounce)
4. Continuer à taper - le curseur ne doit pas se déplacer

### Test des listes
1. Cliquer sur le bouton liste à puces
2. Taper du texte et appuyer sur Entrée
3. Vérifier qu'un nouvel item de liste est créé (avec puce)
4. Le texte ne doit pas avoir de "." ajouté automatiquement

### Test de sauvegarde
1. Créer un article avec du formatage
2. Sauvegarder et recharger la page
3. Vérifier que le formatage est préservé

### Navigateurs testés
- Chrome (desktop)
- Brave (desktop)
- Mobile responsive (Chrome/Safari)
