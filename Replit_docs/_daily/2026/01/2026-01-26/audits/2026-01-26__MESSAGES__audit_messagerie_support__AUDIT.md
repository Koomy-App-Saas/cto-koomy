# P2.5 - Audit Messagerie & Support

**Date**: 2026-01-26  
**Objectif**: Documenter l'état actuel de la messagerie et du support, identifier les gaps

## 1. Architecture Actuelle

### 1.1 Schéma DB - Messages

**Table `messages`** (ligne 812 shared/schema.ts):
| Champ | Type | Description |
|-------|------|-------------|
| `id` | varchar(50) | UUID auto-généré |
| `communityId` | varchar(50) | FK → communities |
| `conversationId` | varchar(50) | Identifiant de conversation |
| `senderMembershipId` | varchar(50) | FK → userCommunityMemberships |
| `senderType` | text | "member" \| "admin" |
| `content` | text | Contenu du message |
| `read` | boolean | Lu/non-lu |
| `createdAt` | timestamp | Date création |

**Observation**: Pas de relation directe avec les sections (sectionId manquant).

### 1.2 Schéma DB - Support Tickets

**Table `supportTickets`** (ligne 777):
| Champ | Type | Description |
|-------|------|-------------|
| `id` | varchar(50) | UUID |
| `userId` | varchar(50) | FK → users (admin créateur) |
| `communityId` | varchar(50) | FK → communities |
| `subject` | text | Sujet du ticket |
| `message` | text | Message initial |
| `status` | enum | open/in_progress/resolved/closed |
| `priority` | enum | low/medium/high/urgent |
| `assignedTo` | varchar(50) | FK → users (staff Koomy) |
| `assignedAt/resolvedAt` | timestamp | Dates gestion |

**Table `ticketResponses`** (ligne 793):
| Champ | Type | Description |
|-------|------|-------------|
| `ticketId` | varchar(50) | FK → supportTickets |
| `userId` | varchar(50) | FK → users |
| `message` | text | Réponse |
| `isInternal` | boolean | Note interne staff |

## 2. Endpoints Existants

### 2.1 Messages (member ↔ admin)

| Endpoint | Méthode | Auth | Description |
|----------|---------|------|-------------|
| `/api/communities/:id/conversations` | GET | Public | Liste conversations communauté |
| `/api/communities/:id/members/:mid/conversations` | GET | Public | Conversations d'un membre |
| `/api/communities/:id/messages/:convId` | GET | Public | Messages d'une conversation |
| `/api/messages` | POST | Firebase + **ADMIN_REQUIRED** | Créer message |
| `/api/messages/:id/read` | PATCH | Firebase | Marquer lu |

**PROBLÈME CRITIQUE**: `POST /api/messages` exige `isCommunityAdmin()` (ligne 7929).
→ **Les membres ne peuvent PAS envoyer de messages actuellement!**

### 2.2 Support Tickets

| Endpoint | Méthode | Auth | Description |
|----------|---------|------|-------------|
| `/api/tickets` | GET | Public | Tous les tickets |
| `/api/users/:userId/tickets` | GET | Public | Tickets d'un user |
| `/api/communities/:id/tickets` | GET | Public | Tickets d'une communauté |
| `/api/tickets` | POST | Public | Créer ticket |
| `/api/tickets/:id` | PATCH | Public | Modifier ticket |

**PROBLÈME**: Endpoints publics sans authentification!

## 3. Composants UI

### 3.1 Admin Backoffice

| Fichier | Description |
|---------|-------------|
| `client/src/pages/admin/Messages.tsx` | Interface messages admin ↔ membre |
| `client/src/pages/admin/Support.tsx` | Interface tickets support + FAQ |

### 3.2 Mobile (Membre)

| Fichier | Description |
|---------|-------------|
| `client/src/pages/mobile/Messages.tsx` | Interface messages membre ↔ admin |
| `client/src/pages/mobile/admin/Messages.tsx` | Messages admin mobile |

## 4. Gaps Identifiés

### 4.1 Sécurité (CRITIQUE)

| Gap | Sévérité | Impact |
|-----|----------|--------|
| POST /api/messages bloque les membres | CRITIQUE | Membres ne peuvent pas écrire |
| Endpoints tickets sans auth | HAUTE | Accès non autorisé possible |
| Endpoints GET conversations publics | MOYENNE | Exposition données |

### 4.2 Fonctionnel

| Gap | Description |
|-----|-------------|
| Pas de notifications | Aucune notification nouveau message |
| Pas de pièces jointes | Uniquement texte |
| Pas de recherche | Messages non recherchables |
| Pas d'archivage | Pas de soft-delete |

### 4.3 Support Koomy

| Gap | Description |
|-----|-------------|
| Pas de canal direct | Admin doit créer un ticket formel |
| Pas de chat en temps réel | Tickets = async |
| Réponses lentes | Pas de priorité auto |

## 5. Plan d'Action P2.5

### Phase 1: Corrections Critiques
1. ✅ Permettre aux membres d'envoyer des messages (modifier POST /api/messages)
2. ✅ Sécuriser endpoints tickets

### Phase 2: Canal Support Intégré
1. Créer endpoint `/api/support/chat` pour messages Koomy
2. Ajouter `supportCommunityId` dans configuration plateforme
3. UI widget support dans mobile + backoffice

### Phase 3: Améliorations (Future)
- Notifications push
- Pièces jointes
- Recherche messages

## 6. Décisions Techniques

### Envoi messages membres
Modifier la condition ligne 7929:
```typescript
// AVANT: Seuls admins
if (!isCommunityAdmin(callerMembership)) {
  return res.status(403).json({ error: "Admin privileges required" });
}

// APRÈS: Admins OU membres avec senderType="member"
const senderType = req.body.senderType;
if (senderType === "admin" && !isCommunityAdmin(callerMembership)) {
  return res.status(403).json({ error: "Admin privileges required for admin messages" });
}
// Membres peuvent envoyer avec senderType="member"
```

### Canal Support Koomy
- Utiliser la table `messages` existante avec `communityId="PLATFORM_SUPPORT"`
- conversationId = `support_${communityId}` pour grouper par club
- Admins Koomy visualisent via dashboard plateforme

## 7. Corrections Implémentées (2026-01-26)

### 7.1 POST /api/messages - Membres autorisés

**Fichier**: `server/routes.ts` lignes 7931-7949

**Logique implémentée**:
```typescript
// P2.5: Messaging access rules
// - Members can send messages with senderType="member" (to admins)
// - Admins can send messages with senderType="admin" (to members)
// - senderType is enforced based on caller role
const requestedSenderType = req.body.senderType || 'member';
const callerIsAdmin = isCommunityAdmin(callerMembership);

// Validate senderType matches caller privileges
if (requestedSenderType === 'admin' && !callerIsAdmin) {
  return res.status(403).json({ error: "Admin privileges required to send as admin" });
}

// Force correct senderType based on caller role
const enforcedSenderType = callerIsAdmin ? 'admin' : 'member';
```

**Sécurité**:
- senderType est TOUJOURS forcé selon le rôle réel de l'appelant
- Un membre ne peut pas usurper un admin (enforcedSenderType override)
- Authentification Firebase requise

### 7.2 Endpoints Tickets Sécurisés

**Fichier**: `server/routes.ts` lignes 7754-7885

| Endpoint | Nouvelle Auth | Règle |
|----------|---------------|-------|
| `GET /api/tickets` | Platform Admin | isAdminUser + userId requis |
| `GET /api/users/:id/tickets` | Owner only | userId === param.userId |
| `GET /api/communities/:id/tickets` | Community Admin | isCommunityAdmin(membership) |
| `POST /api/tickets` | Community Admin | isCommunityAdmin + communityId validé |
| `PATCH /api/tickets/:id` | Owner ou Platform Admin | isOwner: message/subject only, isPlatformAdmin: all fields |

### 7.3 Storage - getTicket ajouté

**Fichier**: `server/storage.ts` ligne 1401

```typescript
async getTicket(id: string): Promise<SupportTicket | null> {
  const [ticket] = await db.select().from(supportTickets).where(eq(supportTickets.id, id));
  return ticket || null;
}
```

## 8. Tests Ajoutés

**Fichier**: `client/src/features/messages/__tests__/messageAccessRules.test.ts`

15 tests couvrant:
- Sender Type Enforcement (6 tests)
  - member can send as member
  - member cannot send as admin
  - admin can send as admin
  - owner can send as admin
  - senderType enforcement based on role
- Ticket Access Rules (9 tests)
  - Platform admin all tickets access
  - User own tickets only
  - Community admin tickets access
  - Field update restrictions

## 9. Conformité

- [x] Membres peuvent envoyer messages (avec senderType="member" forcé)
- [x] Endpoints tickets sécurisés (auth + ownership)
- [x] Tests ajoutés (15 tests access rules)
- [x] Documentation mise à jour
- [ ] Canal support temps réel (future phase)
