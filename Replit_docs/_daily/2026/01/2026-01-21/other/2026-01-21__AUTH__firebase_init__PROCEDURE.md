# KOOMY — AUTH
## Initialisation Firebase Auth côté Front (Sandbox) — Procédure

**Date :** 2026-01-21  
**Domain :** AUTH  
**Doc Type :** PROCEDURE  
**Scope :** Frontend uniquement (Cloudflare Pages)  
**Environnement :** Sandbox  
**Phase :** AUTH — Phase 1 (préparation)

---

## Objectif

Initialiser Firebase Auth côté frontend sandbox, de manière propre, centralisée et réutilisable, sans effet visible pour l'utilisateur.

---

## État actuel

| Élément | Statut |
|---------|--------|
| Module `firebase.ts` créé | ✅ |
| Package Firebase installé | ⏳ En attente |
| Variables VITE_FIREBASE_* configurées | ⏳ En attente |

---

## Fichier créé

**Chemin :** `client/src/lib/firebase.ts`

Ce module expose :
- `getFirebaseAuth()` : obtenir l'instance Auth (lazy init)
- `getFirebaseApp()` : obtenir l'instance App (lazy init)
- `firebaseAuth` / `app` : exports directs

---

## Variables d'environnement requises

Les variables suivantes doivent être configurées dans Cloudflare Pages (sandbox) :

| Variable | Exemple |
|----------|---------|
| `VITE_FIREBASE_API_KEY` | `AIzaSy...` |
| `VITE_FIREBASE_AUTH_DOMAIN` | `koomy-sandbox.firebaseapp.com` |
| `VITE_FIREBASE_PROJECT_ID` | `koomy-sandbox` |
| `VITE_FIREBASE_STORAGE_BUCKET` | `koomy-sandbox.appspot.com` |
| `VITE_FIREBASE_MESSAGING_SENDER_ID` | `123456789` |
| `VITE_FIREBASE_APP_ID` | `1:123456789:web:abc123` |

---

## Installation requise

Le package Firebase doit être installé :

```bash
npm install firebase
```

**Note :** L'installation via le packager Replit a échoué en raison d'une erreur de configuration `.replit`. L'installation doit être effectuée manuellement ou après correction du fichier `.replit`.

---

## Tests de validation

1. Déployer sandbox (Cloudflare Pages rebuild)
2. Charger n'importe quelle page publique
3. Vérifier dans la console :
   - Présence du log `[AUTH] Firebase initialized`
   - Aucune erreur Firebase
   - Aucune modification UX

---

## Retrait des logs temporaires

Après validation de la Phase AUTH, supprimer le log temporaire dans `firebase.ts` :

```typescript
// TEMP DEBUG - À supprimer après validation Phase AUTH
console.info("[AUTH] Firebase initialized", {
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
});
```

---

## Mini-log

| Date | Action |
|------|--------|
| 2026-01-21 | Création module `client/src/lib/firebase.ts` |
| 2026-01-21 | Package Firebase non installé (erreur packager) |
