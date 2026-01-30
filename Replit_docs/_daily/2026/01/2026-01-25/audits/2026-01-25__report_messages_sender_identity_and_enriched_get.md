# Audit Report: Messages Sender Identity & Enriched GET

**Date**: 2026-01-25
**Status**: Implemented

## Overview

This report documents the implementation of the messaging sender identity contract for the Koomy platform, ensuring every message has an identifiable author and the UI can display the sender's current name.

## Contract Requirements

### Non-Negotiable Rules
1. `messages.senderMembershipId` **MUST NOT be null** for any API-created message
2. If caller has no membership for the community: return **403** with code `MEMBERSHIP_REQUIRED`
3. UI displays **current** member name (no snapshot)

## Changes Implemented

### A) POST /api/messages - Enforce senderMembershipId

**File:** `server/routes.ts`

#### Before
```typescript
const validated = insertMessageSchema.parse(req.body);
const message = await storage.createMessage(validated);
```

#### After
```typescript
// CONTRACT: Caller must have a membership in the community
if (!callerMembership) {
  return res.status(403).json({ error: "Membership required", code: "MEMBERSHIP_REQUIRED" });
}

// V1 HARDENING: canManageMessages permission frozen - only OWNER/ADMIN can manage messages
if (!isCommunityAdmin(callerMembership)) {
  return res.status(403).json({ error: "Admin privileges required", code: "ADMIN_REQUIRED" });
}

const validated = insertMessageSchema.parse(req.body);

// CONTRACT: Always persist senderMembershipId from authenticated caller
const messageData = {
  ...validated,
  senderMembershipId: callerMembership.id
};

// Debug logging (gated by KOOMY_AUTH_DEBUG)
if (process.env.KOOMY_AUTH_DEBUG === '1') {
  console.log(`[MSG_AUTHOR ${traceId}]`, {
    senderMembershipId: callerMembership.id,
    senderType: validated.senderType,
    communityId,
    conversationId: validated.conversationId
  });
}

const message = await storage.createMessage(messageData);
```

### B) GET Messages - Sender Enrichment

**File:** `server/storage.ts`

Added new method `getCommunityMessagesWithSenders()` that:
1. Fetches all messages for the conversation
2. Collects unique `senderMembershipId` values
3. Fetches current membership data (firstName, lastName, displayName, role)
4. Returns enriched messages with `sender` object

**Response Shape:**
```json
{
  "id": "...",
  "communityId": "...",
  "conversationId": "...",
  "senderMembershipId": "...",
  "senderType": "admin",
  "content": "...",
  "sender": {
    "membershipId": "...",
    "memberId": "OWNER-XXXX",
    "firstName": "...",
    "lastName": "...",
    "displayName": "First Last",
    "role": "admin"
  }
}
```

**File:** `server/routes.ts`

Updated GET route to use the enriched method:
```typescript
const messages = await storage.getCommunityMessagesWithSenders(communityId, conversationId);
```

### C) Frontend - Sender Display

**Files:**
- `client/src/pages/admin/Messages.tsx`
- `client/src/pages/mobile/admin/Messages.tsx`

Added:
- `MessageWithSender` interface with full sender object
- Sender name display above message content
- "Vous" label when message is from current user
- Admin badge (styled tag) when `senderType === "admin"`

## Files Modified

| File | Change |
|------|--------|
| `server/routes.ts` | POST /api/messages enforces senderMembershipId, GET uses enriched method |
| `server/storage.ts` | Added `getCommunityMessagesWithSenders()` method |
| `client/src/pages/admin/Messages.tsx` | Display sender name + Admin badge |
| `client/src/pages/mobile/admin/Messages.tsx` | Display sender name + Admin badge |

## Manual Validation Steps

### 1. Test POST /api/messages with senderMembershipId

```bash
# Set debug mode
export KOOMY_AUTH_DEBUG=1

# Login as admin on backoffice-sandbox.koomy.app
# Open Messagerie
# Select a member conversation
# Send a message

# Expected:
# - Network: POST /api/messages → 201
# - Response body includes: senderMembershipId (non-null UUID)
# - Server logs show: [MSG_AUTHOR] senderMembershipId=...
```

### 2. Test GET messages enrichment

```bash
# After sending a message, reload the conversation
# Inspect Network tab: GET /api/communities/:id/messages/:convId

# Expected response shape:
# - Each message has `sender` object
# - sender.displayName is non-empty
# - sender.role matches membership role
```

### 3. Test UI display

- Message bubbles show sender name (or "Vous" for own messages)
- Admin messages show "Admin" badge
- Names reflect current membership data (not snapshot)

### 4. Negative test: Missing membership

```bash
# Authenticated user without membership in target community
# POST /api/messages with that communityId

# Expected:
# - Status: 403
# - Body: { "error": "Membership required", "code": "MEMBERSHIP_REQUIRED" }
```

## Security Considerations

1. **senderMembershipId is server-side enforced** - Client cannot spoof sender identity
2. **Membership validation before create** - 403 if no valid membership
3. **Admin check preserved** - Only OWNER/ADMIN roles can send messages

## Backward Compatibility

- Existing messages with `senderMembershipId = null` will have `sender: null` in response
- UI gracefully handles missing sender (no name displayed, no crash)
- Schema column remains nullable for legacy data
