# KOOMY — AUTH MIGRATION FIREBASE-ONLY: QA CHECKLIST EXPANDED

**Date**: 2026-01-24  
**Scope**: Admin/Backoffice  
**Tests**: 20 tests groupés par module  
**Environnement**: backoffice-sandbox.koomy.app

---

## MODULE A — AUTHENTIFICATION (5 tests)

### A1. Login email/password
| Prérequis | Steps | Expected logs | Expected API |
|-----------|-------|---------------|--------------|
| Compte admin existant | 1. Aller sur /login<br>2. Entrer email + password<br>3. Click "Se connecter" | Console: "[AUTH] Firebase signIn success"<br>Backend: "[AUTH] Token verified successfully for uid: xxx" | GET /api/auth/me → 200 |

**Log pattern vérifié** (`server/lib/firebaseAdmin.ts:93`):
```
[AUTH] Token verified successfully for uid: {firebase_uid}
```

### A2. Login mauvais password
| Prérequis | Steps | Expected logs | Expected API |
|-----------|-------|---------------|--------------|
| Compte admin existant | 1. Entrer email correct<br>2. Entrer mauvais password<br>3. Click "Se connecter" | Console: "auth/wrong-password" | Pas d'appel API |

**Expected UI**: Toast "Mot de passe incorrect"

### A3. Session persistence (F5)
| Prérequis | Steps | Expected logs | Expected API |
|-----------|-------|---------------|--------------|
| Logged in comme admin | 1. Refresh page (F5)<br>2. Attendre chargement | Console: "ensureFirebaseToken" | GET /api/auth/me → 200 |

**Expected UI**: Utilisateur reste connecté

### A4. Logout complet
| Prérequis | Steps | Expected logs | Expected API |
|-----------|-------|---------------|--------------|
| Logged in comme admin | 1. Click "Déconnexion"<br>2. Vérifier localStorage | Console: "Firebase signOut"<br>Storage: koomy_auth_token = undefined | Pas d'appel API |

**Expected UI**: Redirect vers /login

### A5. Token legacy rejeté
| Prérequis | Steps | Expected logs | Expected API |
|-----------|-------|---------------|--------------|
| Token legacy (33 chars) | 1. curl avec token legacy<br>2. Appeler route protégée | Backend: "Firebase auth required" | GET /api/communities/:id/sections → 401 |

**Expected response**: `{ code: "FIREBASE_AUTH_REQUIRED" }`

---

## MODULE B — SECTIONS (3 tests)

### B1. Lister sections
| Prérequis | Steps | Expected logs | Expected API |
|-----------|-------|---------------|--------------|
| Logged in + communityId | 1. Aller sur page Sections<br>2. Attendre chargement | Backend: "requireFirebaseOnly: verified" | GET /api/communities/:id/sections → 200 |

### B2. Créer section
| Prérequis | Steps | Expected logs | Expected API |
|-----------|-------|---------------|--------------|
| Logged in + communityId | 1. Click "Nouvelle section"<br>2. Remplir nom<br>3. Sauvegarder | Backend: log création | POST /api/communities/:id/sections → 201 |

### B3. Supprimer section
| Prérequis | Steps | Expected logs | Expected API |
|-----------|-------|---------------|--------------|
| Section existante | 1. Click supprimer<br>2. Confirmer | Backend: log suppression | DELETE /api/communities/:id/sections/:id → 200 |

---

## MODULE C — ÉVÉNEMENTS (3 tests)

### C1. Lister événements
| Prérequis | Steps | Expected logs | Expected API |
|-----------|-------|---------------|--------------|
| Logged in + communityId | 1. Aller sur page Événements | Backend: "requireFirebaseOnly: verified" | GET /api/communities/:id/events → 200 |

### C2. Créer événement
| Prérequis | Steps | Expected logs | Expected API |
|-----------|-------|---------------|--------------|
| Logged in + communityId | 1. Click "Nouvel événement"<br>2. Remplir titre + date<br>3. Sauvegarder | Backend: log création | POST /api/communities/:id/events → 201 |

### C3. Modifier événement
| Prérequis | Steps | Expected logs | Expected API |
|-----------|-------|---------------|--------------|
| Événement existant | 1. Click modifier<br>2. Changer titre<br>3. Sauvegarder | Backend: log modification | PATCH /api/communities/:id/events/:id → 200 |

---

## MODULE D — ACTUALITÉS (2 tests)

### D1. Créer actualité
| Prérequis | Steps | Expected logs | Expected API |
|-----------|-------|---------------|--------------|
| Logged in + communityId | 1. Aller sur Actualités<br>2. Click "Nouvelle"<br>3. Remplir titre + contenu<br>4. Publier | Backend: log création | POST /api/communities/:id/news → 201 |

### D2. Modifier actualité
| Prérequis | Steps | Expected logs | Expected API |
|-----------|-------|---------------|--------------|
| Actualité existante | 1. Click modifier<br>2. Changer contenu<br>3. Sauvegarder | Backend: log modification | PATCH /api/news/:id → 200 |

---

## MODULE E — MEMBRES (3 tests)

### E1. Lister membres
| Prérequis | Steps | Expected logs | Expected API |
|-----------|-------|---------------|--------------|
| Logged in + communityId | 1. Aller sur page Membres | Backend: verified | GET /api/memberships → 200 |

### E2. Créer membre
| Prérequis | Steps | Expected logs | Expected API |
|-----------|-------|---------------|--------------|
| Logged in + communityId | 1. Click "Ajouter membre"<br>2. Remplir email + nom<br>3. Créer | Backend: log création | POST /api/memberships → 201 |

### E3. Modifier membre
| Prérequis | Steps | Expected logs | Expected API |
|-----------|-------|---------------|--------------|
| Membre existant | 1. Click modifier<br>2. Changer infos<br>3. Sauvegarder | Backend: log modification | PATCH /api/memberships/:id → 200 |

---

## MODULE F — PARAMÈTRES (2 tests)

### F1. Branding
| Prérequis | Steps | Expected logs | Expected API |
|-----------|-------|---------------|--------------|
| Logged in + communityId | 1. Aller sur Paramètres > Branding<br>2. Modifier couleur<br>3. Sauvegarder | Backend: verified | PATCH /api/communities/:id/branding → 200 |

### F2. Self-enrollment settings
| Prérequis | Steps | Expected logs | Expected API |
|-----------|-------|---------------|--------------|
| Logged in + communityId | 1. Aller sur Self-enrollment<br>2. Modifier settings<br>3. Sauvegarder | Backend: verified | PATCH /api/communities/:id/self-enrollment/settings → 200 |

---

## MODULE G — EDGE CASES (2 tests)

### G1. Token expiré (auto-refresh)
| Prérequis | Steps | Expected logs | Expected API |
|-----------|-------|---------------|--------------|
| Token Firebase > 1h | 1. Attendre expiration<br>2. Faire une action | Console: "Token refreshed" | Appel avec nouveau token |

### G2. Déconnexion forcée (autre onglet)
| Prérequis | Steps | Expected logs | Expected API |
|-----------|-------|---------------|--------------|
| Logged in sur 2 onglets | 1. Logout sur onglet 1<br>2. Action sur onglet 2 | Onglet 2: redirect login | GET /api/auth/me → 401 |

---

## RÉCAPITULATIF

| Module | Tests | Priorité |
|--------|-------|----------|
| A. Authentification | 5 | 🔴 Critique |
| B. Sections | 3 | 🟡 Haute |
| C. Événements | 3 | 🟡 Haute |
| D. Actualités | 2 | 🟡 Haute |
| E. Membres | 3 | 🟡 Haute |
| F. Paramètres | 2 | 🟢 Moyenne |
| G. Edge cases | 2 | 🟢 Moyenne |
| **TOTAL** | **20** | |

---

## CRITÈRES DE SUCCÈS

✅ **PASS** si:
- Tous les tests du module A passent (authentification)
- 80%+ des tests modules B-E passent
- Pas de régression sur logout/session

❌ **FAIL** si:
- Login échoue
- Token legacy accepté sur route admin
- Session non persistée après F5
- 401/403 sur routes avec token Firebase valide

---

## COMMANDES DE TEST RAPIDE

```bash
# Test token legacy rejeté
curl -X GET "https://backoffice-sandbox.koomy.app/api/communities/xxx/sections" \
  -H "Authorization: Bearer fake-legacy-token" \
  -w "\n%{http_code}"
# Expected: 401

# Test Firebase token accepté
curl -X GET "https://backoffice-sandbox.koomy.app/api/communities/xxx/sections" \
  -H "Authorization: Bearer {FIREBASE_JWT}" \
  -w "\n%{http_code}"
# Expected: 200
```

---

**FIN DU RAPPORT QA_CHECKLIST_EXPANDED**
