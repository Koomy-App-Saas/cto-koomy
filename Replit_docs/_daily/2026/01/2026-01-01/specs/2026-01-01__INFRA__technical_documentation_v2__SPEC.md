# Koomy - Technical Documentation

## Product Overview

**Koomy** is a multi-tenant SaaS platform designed for community management (unions, clubs, associations). The platform provides digital tools for member management, communication, and administrative operations.

### Target Users
- **Associations & Clubs** - Sports clubs, hobby groups, cultural associations
- **Unions & Syndicates** - Professional unions, worker organizations
- **Non-Profit Organizations** - Charitable organizations, volunteer groups
- **Enterprise Clients (Grands Comptes)** - Large federations with contractual agreements

---

## Architecture

### Technology Stack

| Layer | Technology |
|-------|------------|
| Frontend | React 19, TypeScript, Tailwind CSS, Wouter (routing) |
| State Management | TanStack React Query |
| Backend | Express.js, Node.js |
| Database | PostgreSQL (Neon) |
| ORM | Drizzle ORM |
| Validation | Zod |
| UI Components | Radix UI, shadcn/ui |
| Internationalization | react-i18next |
| Payments | Stripe Billing + Stripe Connect Express |
| Email | SendGrid |

### Multi-Tenant Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     KOOMY PLATFORM                          │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │ Community A │  │ Community B │  │ Community C │  ...    │
│  │  (Tenant)   │  │  (Tenant)   │  │  (Tenant)   │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
├─────────────────────────────────────────────────────────────┤
│                   Shared Database                           │
│            (Data isolated by community_id)                  │
└─────────────────────────────────────────────────────────────┘
```

---

## Design System (Koomy Identity)

### Brand Colors

| Color | Hex | HSL | Usage |
|-------|-----|-----|-------|
| Primary (Sky Blue) | `#44A8FF` | 207 100% 63% | Main brand color, buttons, links |
| Primary Light | `#5AB8FF` | - | Hover states |
| Primary Dark | `#2B9AFF` | - | Active states |
| Background Soft | `#E8F4FF` | - | Page backgrounds |

### Typography

- **Primary Font**: Nunito (rounded, friendly)
- **Fallback**: Inter, sans-serif

### Design Principles

- Soft, rounded corners (16-20px radius)
- Subtle gradients and glows
- Clean white cards with soft shadows
- Accessible, modern, friendly aesthetic

### CSS Utility Classes

| Class | Purpose |
|-------|---------|
| `.koomy-gradient` | Primary gradient background |
| `.koomy-glow` | Soft blue glow effect |
| `.koomy-card` | White card with soft shadow |
| `.koomy-btn` | Primary button style |

---

## Internationalization (i18n)

### Supported Languages

| Language | Code | Default |
|----------|------|---------|
| French | `fr` | Yes |
| English | `en` | No |

### Implementation

- **Library**: react-i18next
- **Translation Files**: `client/src/i18n/locales/{lang}.json`
- **Language Switcher**: Located in public website header (globe icon)
- **State Management**: Language stored in memory (no URL prefix)

### Translated Sections

| Section | Coverage |
|---------|----------|
| Navigation | Full |
| Home Page | Full |
| Pricing Page | Full (including plan names/descriptions/features) |
| Contact Page | Full |
| FAQ Page | Full |
| Login Modal | Full |
| Footer | Full |

---

## User Roles & Permissions

### Platform Level (SaaS Owner)

| Role | Global Role Value | Permissions |
|------|-------------------|-------------|
| **Platform Super Admin** | `platform_super_admin` | Full platform access, manage all tenants, grant VIP access, security audit |
| **Platform Support** | `platform_support` | View/manage support tickets, limited tenant access |

### Community Level (Tenant)

| Role | Permissions |
|------|-------------|
| **Super Admin** | Full community access, manage other admins |
| **Admin** | Manage members, content, events |
| **Delegate** | Mobile admin app, QR scanner, messaging |
| **Member** | Mobile app access, view content, messaging |

---

## Authentication Model (Three-Tier System)

### 1. Accounts Table (Mobile App Users)

- Public Koomy users who access the mobile app
- Email/password authentication with bcrypt hashing
- Can be members of multiple communities

### 2. Users Table (Back-Office Admins)

- Community administrators
- Login via `/api/admin/login`
- Can have `globalRole` for platform-level access

### 3. Membership Claiming System

- Admins create member cards with auto-generated 8-character `claimCode`
- Users claim membership by entering the code in the mobile app
- Links account to community membership

### Platform Admin Security (Added Dec 2024)

- **Session Management**: 2-hour session expiry with mandatory renewal
- **Single Active Session**: New login revokes all existing sessions
- **IP Restriction**: France-only access via CloudFlare CF-IPCountry header
- **Email Domain**: Platform admins must use @koomy.app email
- **Rate Limiting**: 5 failed attempts = 15-minute lockout
- **Audit Logging**: All actions tracked in `platform_audit_logs`

### Authentication Routes

| Portal | Endpoint | Returns |
|--------|----------|---------|
| Mobile App | `/api/accounts/register` | Account + memberships |
| Mobile App | `/api/accounts/login` | Account + memberships |
| Mobile App | `/api/memberships/claim` | Claimed membership |
| Web Admin | `/api/admin/login` | User + memberships |
| Platform Admin | `/api/platform/login` | User with globalRole + session token |
| Platform Admin | `/api/platform/validate-session` | Session validity |
| Platform Admin | `/api/platform/renew-session` | New session token |

### Demo Credentials

| Portal | Email | Password |
|--------|-------|----------|
| Platform Admin | `platform@koomy.app` | `Admin2025!` |
| Community Admin | `admin@koomy.app` | `Admin2025!` |

---

## Application Portals

### 1. Commercial Public Website (`/website`)

**Purpose:** Marketing and user acquisition (bilingual FR/EN)

| Page | Route | Description |
|------|-------|-------------|
| Home | `/website` | Landing page with hero, features, CTA |
| Pricing | `/website/pricing` | Subscription plans comparison |
| FAQ | `/website/faq` | Frequently asked questions |
| Contact | `/website/contact` | Contact form with request types |
| Signup | `/website/signup` | New organization registration |

### 2. Mobile Member App (`/app`)

**Purpose:** Member-facing mobile application

| Screen | Route | Description |
|--------|-------|-------------|
| Login | `/app/login` | Email/password authentication |
| Community Hub | `/app/hub` | List of user's communities |
| Home | `/app/:communityId/home` | Community dashboard |
| Membership Card | `/app/:communityId/card` | Digital QR code card |
| News Feed | `/app/:communityId/news` | Community articles |
| News Detail | `/app/:communityId/news/:articleId` | Article detail page |
| Events | `/app/:communityId/events` | Events list |
| Event Detail | `/app/:communityId/events/:eventId` | Event detail page |
| Messages | `/app/:communityId/messages` | Member-admin messaging |
| Profile | `/app/:communityId/profile` | User profile management |
| Payment | `/app/:communityId/payment` | Contribution payments |
| Support | `/app/:communityId/support` | Help & FAQs |

### 3. Mobile Admin/Delegate App - Koomy Pro (`/app/:communityId/admin`)

**Purpose:** Field administrators and delegates (full feature parity with back-office)

| Screen | Route | Description |
|--------|-------|-------------|
| Admin Home | `/app/:communityId/admin` | Admin dashboard |
| QR Scanner | `/app/:communityId/admin/scanner` | Member verification |
| Messages | `/app/:communityId/admin/messages` | Member communications |
| Tags | `/app/:communityId/admin/tags` | Tags & segmentation |
| Fundraising | `/app/:communityId/admin/fundraising` | Collection campaigns |
| Events | `/app/:communityId/admin/events` | Event management |
| Members | `/app/:communityId/admin/members` | Member management |

### 4. Web Admin Back-Office (`/admin`)

**Purpose:** Full administrative control for organization managers

| Screen | Route | Description |
|--------|-------|-------------|
| Dashboard | `/admin/dashboard` | Overview metrics & KPIs |
| Members | `/admin/members` | Member database management |
| Member Details | `/admin/members/:id` | Individual member profile |
| News | `/admin/news` | Create/manage articles |
| Events | `/admin/events` | Event management |
| Event Details | `/admin/events/:id` | Single event view |
| Messages | `/admin/messages` | Communication center |
| Admins | `/admin/admins` | Admin role management |
| Sections | `/admin/sections` | Regional/local divisions |
| Payments | `/admin/payments` | Payment & contribution management |
| Support | `/admin/support` | Ticket management |

### 5. SaaS Owner Portal (`/platform`)

**Purpose:** Platform-wide management for Koomy operators

| Screen | Route | Description |
|--------|-------|-------------|
| Super Dashboard | `/platform/dashboard` | Platform metrics, MRR, clients, health monitoring |

**Key Features:**
- MRR/ARR tracking with revenue analytics
- Client (tenant) overview with subscription status
- VIP badge system for communities with full access
- White Label configuration (branding, contracts, billing)
- Grand Compte management (enterprise clients)
- Platform admin management with role assignment
- Audit logs viewer
- Platform Health tab with metrics, gauges, and trends

---

## Subscription Plans

### Plan Codes & Pricing

| Code | Name | Max Members | Monthly | Yearly | Target |
|------|------|-------------|---------|--------|--------|
| `STARTER_FREE` | Free Starter | 50 | €0 | €0 | Small clubs starting out |
| `COMMUNAUTE_STANDARD` | Communauté Standard | 1,000 | €9.90 | €99 | Growing associations |
| `COMMUNAUTE_PRO` | Communauté Pro | 5,000 | €29 | €290 | Large organizations |
| `ENTREPRISE_CUSTOM` | Grand Compte | Unlimited | Custom | Custom | Federations |
| `WHITE_LABEL` | White Label | Unlimited | - | €4,900 | Branded platform |

### Plan Features

| Feature | Starter | Standard | Pro | Enterprise | White Label |
|---------|---------|----------|-----|------------|-------------|
| Digital membership cards | ✓ | ✓ | ✓ | ✓ | ✓ |
| News feed | ✓ | ✓ | ✓ | ✓ | ✓ |
| Basic events | ✓ | ✓ | ✓ | ✓ | ✓ |
| Email support | ✓ | ✓ | ✓ | ✓ | ✓ |
| QR code cards | - | ✓ | ✓ | ✓ | ✓ |
| Dues management | - | ✓ | ✓ | ✓ | ✓ |
| Member-admin messaging | - | ✓ | ✓ | ✓ | ✓ |
| Priority support | - | ✓ | ✓ | ✓ | ✓ |
| **Paid Events** | - | ✓ (2/month) | ✓ | ✓ | ✓ |
| **Tags & Segmentation** | - | - | ✓ | ✓ | ✓ |
| **Fundraising Campaigns** | - | - | ✓ | ✓ | ✓ |
| Multi-admin with roles | - | - | ✓ | ✓ | ✓ |
| Unlimited sections | - | - | ✓ | ✓ | ✓ |
| Advanced analytics | - | - | ✓ | ✓ | ✓ |
| API integrations | - | - | ✓ | ✓ | ✓ |
| 24/7 support | - | - | ✓ | ✓ | ✓ |
| Dedicated success manager | - | - | - | ✓ | ✓ |
| Custom integrations | - | - | - | ✓ | ✓ |
| Guaranteed SLA | - | - | - | ✓ | ✓ |
| Custom branding | - | - | - | - | ✓ |
| Custom domain | - | - | - | - | ✓ |

### Member Quota Enforcement

- `storage.createMembership()` checks plan limits before creating new members
- `storage.changeCommunityPlan()` prevents downgrade when member count exceeds new plan limit
- API route `GET /api/communities/:id/quota` returns current usage vs limit
- **Grand Comptes**: Use `contractMemberLimit` instead of plan.maxMembers

---

## Account Types (Added Dec 2024)

### STANDARD vs GRAND_COMPTE

| Aspect | STANDARD | GRAND_COMPTE |
|--------|----------|--------------|
| Billing | Self-service via Stripe | Manual contract |
| Member Limits | Based on plan.maxMembers | Based on contractMemberLimit |
| Feature Access | Based on plan | Full access to all features |
| Visual Indicator | Plan badge | GC badge (emerald) |

### Grand Compte Configuration

| Field | Type | Description |
|-------|------|-------------|
| `accountType` | ENUM | STANDARD or GRAND_COMPTE |
| `contractMemberLimit` | INTEGER | Contractual member limit |
| `contractMemberAlertThreshold` | INTEGER | Alert at X% of limit |
| `distributionChannels` | JSONB | { whiteLabelApp, koomyWallet } |

### Capability Logic

```typescript
// Full feature access granted if:
// 1. Community has GRAND_COMPTE accountType, OR
// 2. Community has whiteLabel enabled, OR
// 3. Community has VIP full access, OR
// 4. Plan is COMMUNAUTE_PRO, ENTREPRISE_CUSTOM, or WHITE_LABEL
```

---

## Full Access VIP System (Platform Admin Only)

Allows SaaS owner to grant free unlimited access to specific communities for promotional/VIP purposes.

### Database Fields (Communities Table)

| Column | Type | Description |
|--------|------|-------------|
| `fullAccessGrantedAt` | TIMESTAMP | When access was granted |
| `fullAccessExpiresAt` | TIMESTAMP | When access expires (null = forever) |
| `fullAccessReason` | TEXT | Reason for granting |
| `fullAccessGrantedBy` | VARCHAR FK | Admin who granted access |

### Storage Methods

| Method | Description |
|--------|-------------|
| `hasActiveFullAccess(communityId)` | Check if community has active VIP status |
| `grantFullAccess(communityId, grantedBy, reason, expiresAt?)` | Grant VIP access |
| `revokeFullAccess(communityId, revokedBy)` | Revoke VIP access |
| `getCommunitiesWithFullAccess()` | List all VIP communities |

---

## White Label Feature (Added Dec 2024)

### Purpose

Support custom branding and manual contract billing for enterprise communities.

### Configuration Options

| Field | Type | Description |
|-------|------|-------------|
| `whiteLabel` | BOOLEAN | Enable white-label mode |
| `whiteLabelTier` | ENUM | basic, standard, premium |
| `billingMode` | ENUM | self_service, manual_contract |
| `setupFeeAmountCents` | INTEGER | One-time setup fee |
| `maintenanceAmountYearCents` | INTEGER | Annual maintenance fee |
| `maintenanceNextBillingDate` | DATE | Next billing date |
| `maintenanceStatus` | ENUM | active, pending, late, stopped |
| `brandConfig` | JSONB | Custom branding configuration |

### Brand Config Structure

```json
{
  "appName": "Custom App Name",
  "brandColor": "#6366f1",
  "logoUrl": "https://...",
  "appIconUrl": "https://...",
  "emailFromName": "Custom Name",
  "emailFromAddress": "noreply@custom.com",
  "replyTo": "support@custom.com",
  "showPoweredBy": true
}
```

### Member Quotas for White Label

| Field | Description |
|-------|-------------|
| `whiteLabelIncludedMembers` | Members included in base contract |
| `whiteLabelMaxMembersSoftLimit` | Soft limit before additional fees |
| `whiteLabelAdditionalFeePerMemberCents` | Fee per member above soft limit |

---

## Economic Model (Added Dec 2024)

### Stripe Integration Structure

| Type | Purpose | Stripe Product |
|------|---------|----------------|
| SaaS Subscriptions | Communities pay Koomy | Stripe Billing |
| Community Payments | Members pay communities | Stripe Connect Express |

### Database Schema for Payments

#### Communities (Payment Fields)

| Column | Type | Description |
|--------|------|-------------|
| `stripeConnectAccountId` | TEXT | Stripe Connect account ID |
| `paymentsEnabled` | BOOLEAN | Payments activated |
| `platformFeePercent` | INTEGER | Koomy fee (default 2%) |
| `maxMembersAllowed` | INTEGER | Member limit |

#### Transactions Table

| Column | Type | Description |
|--------|------|-------------|
| `type` | ENUM | subscription, membership, collection |
| `status` | ENUM | pending, succeeded, failed, refunded |
| `amountTotalCents` | INTEGER | Total amount |
| `amountFeeKoomyCents` | INTEGER | Platform fee |
| `amountToCommunity` | INTEGER | Net to community |
| `stripePaymentIntentId` | TEXT | Stripe reference |

#### Collections Table (Fundraising)

| Column | Type | Description |
|--------|------|-------------|
| `title` | TEXT | Campaign name |
| `amountCents` | INTEGER | Suggested amount |
| `targetAmountCents` | INTEGER | Goal amount |
| `allowCustomAmount` | BOOLEAN | Allow custom donations |
| `status` | ENUM | open, closed, canceled |

---

## Platform Security (Added Dec 2024)

### Session Management

| Feature | Implementation |
|---------|----------------|
| Session Duration | 2 hours (mandatory renewal) |
| Session Storage | `platform_sessions` table |
| Single Session | New login revokes all existing |
| Token Validation | Required for all platform API calls |

### Audit Logging

All admin actions tracked in `platform_audit_logs`:

| Action | Description |
|--------|-------------|
| `login` | Successful login |
| `logout` | Manual logout |
| `session_expired` | Session timeout |
| `session_renewed` | Session renewal |
| `create_user` | New user created |
| `update_user` | User modified |
| `delete_user` | User deleted |
| `update_role` | Role changed |
| `create_community` | New community |
| `update_community` | Community modified |
| `delete_community` | Community deleted |
| `update_plan` | Plan changed |
| `update_settings` | Settings modified |
| `access_denied` | Unauthorized access attempt |
| `ip_blocked` | Non-France IP blocked |

### IP Whitelist

- Access restricted to France via CloudFlare `CF-IPCountry` header
- Fallback to `x-geoip-country` and `x-country-code` headers
- Local/dev IPs allowed (127.0.0.1, ::1, 192.168.*, 10.*)
- Blocked attempts logged as `ip_blocked`

### Account Security

| Feature | Implementation |
|---------|----------------|
| Email Domain | @koomy.app required for platform admins |
| Email Verification | 24-hour token expiry |
| Rate Limiting | 5 failed attempts = 15-min lockout |
| Owner Protection | isPlatformOwner cannot be deleted/demoted |

---

## Membership Plans (Formules d'Adhésion) - Added Jan 2026

### Purpose

Manage membership formulas with automatic date calculation for subscriptions.

### Plan Types

| Type | Description | Required Fields |
|------|-------------|-----------------|
| `FIXED_PERIOD` | Fixed period (calendar year or season) | `fixedPeriodType` |
| `ROLLING_DURATION` | Rolling duration from enrollment | `rollingDurationMonths` |

### Fixed Period Subtypes

| Value | Period | Calculated Dates |
|-------|--------|------------------|
| `CALENDAR_YEAR` | Calendar year | Jan 1 - Dec 31 |
| `SEASON` | Sports season | Sep 1 - Jul 31 |

### Automatic Date Calculation

When creating a membership with a plan:

| Type | membershipStartDate | membershipValidUntil | membershipSeasonLabel |
|------|---------------------|---------------------|----------------------|
| SEASON | Sep 1 of current season | Jul 31 following year | "2025–2026" |
| CALENDAR_YEAR | Jan 1 of current year | Dec 31 of year | null |
| ROLLING_DURATION | Creation date | Date + X months | null |

### Database Schema

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID PK | Plan ID |
| `communityId` | UUID FK | Parent community |
| `name` | TEXT | Plan name |
| `membershipType` | ENUM | FIXED_PERIOD, ROLLING_DURATION |
| `fixedPeriodType` | ENUM | CALENDAR_YEAR, SEASON (nullable) |
| `rollingDurationMonths` | INTEGER | Duration in months (nullable) |
| `price` | INTEGER | Price in cents |
| `isActive` | BOOLEAN | Active status |

### API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/communities/:id/membership-plans` | List membership plans |
| POST | `/api/communities/:id/membership-plans` | Create membership plan |
| GET | `/api/membership-plans/:id` | Get plan details |
| PATCH | `/api/membership-plans/:id` | Update plan |
| DELETE | `/api/membership-plans/:id` | Delete plan |

---

## Events V2 System - Added Jan 2026

### Purpose

Enhanced event management with RSVP, paid events, capacity control, and targeting.

### Event Status Flow

```
DRAFT → PUBLISHED → CANCELLED
```

### RSVP Modes

| Mode | Description |
|------|-------------|
| `NONE` | No RSVP, information only |
| `OPTIONAL` | Members can optionally RSVP |
| `REQUIRED` | RSVP required to attend |

### Visibility Modes

| Mode | Description |
|------|-------------|
| `ALL` | Visible to all members |
| `SECTION` | Visible only to specific sections |
| `TAGS` | Visible only to members with specific tags |

### Paid Events

| Plan | Capability | Monthly Quota |
|------|------------|---------------|
| FREE | eventPaid=false | N/A |
| PLUS | eventPaid=true | 2/month |
| PRO | eventPaid=true | Unlimited |
| GRAND_COMPTE | eventPaid=true | Unlimited |

### Database Tables

#### Event Registrations

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID PK | Registration ID |
| `eventId` | UUID FK | Event reference |
| `membershipId` | UUID FK | Member reference |
| `rsvpStatus` | ENUM | yes, no, maybe |
| `paymentStatus` | ENUM | pending, paid, refunded |
| `registeredAt` | TIMESTAMP | Registration time |

#### Event Attendance

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID PK | Attendance ID |
| `eventId` | UUID FK | Event reference |
| `membershipId` | UUID FK | Member reference |
| `checkedInAt` | TIMESTAMP | Check-in time |
| `source` | ENUM | qr_scan, manual |

### Event Fields (V2 additions)

| Column | Type | Description |
|--------|------|-------------|
| `status` | ENUM | DRAFT, PUBLISHED, CANCELLED |
| `rsvpMode` | ENUM | NONE, OPTIONAL, REQUIRED |
| `visibilityMode` | ENUM | ALL, SECTION, TAGS |
| `isPaid` | BOOLEAN | Paid event flag |
| `priceCents` | INTEGER | Event price |
| `capacity` | INTEGER | Max attendees |
| `rsvpDeadline` | TIMESTAMP | RSVP deadline |
| `targetSections` | UUID[] | Target section IDs |
| `targetTags` | UUID[] | Target tag IDs |

---

## Tags & Segmentation System (Added Dec 2024)

### Purpose

Organize members with tags for targeted communication and promotions.

### Database Schema

#### Tags Table

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Tag ID |
| `communityId` | UUID FK | Parent community |
| `name` | TEXT | Tag name |
| `color` | TEXT | Tag color (hex) |
| `description` | TEXT | Tag description |
| `isAutomatic` | BOOLEAN | System-generated tag |
| `criteria` | JSONB | Auto-assignment rules |

#### Member Tags Table

| Column | Type | Description |
|--------|------|-------------|
| `membershipId` | UUID FK | Member reference |
| `tagId` | UUID FK | Tag reference |
| `assignedAt` | TIMESTAMP | Assignment date |
| `assignedBy` | UUID FK | Admin who assigned |

### API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/communities/:id/tags` | List tags |
| POST | `/api/communities/:id/tags` | Create tag |
| PATCH | `/api/tags/:id` | Update tag |
| DELETE | `/api/tags/:id` | Delete tag |
| POST | `/api/memberships/:id/tags` | Assign tags to member |
| DELETE | `/api/memberships/:id/tags/:tagId` | Remove tag from member |

---

## Platform Health Monitoring (Added Dec 2024)

### Dashboard Components

| Component | Description |
|-----------|-------------|
| Daily Metrics | Active communities, new signups, revenue |
| Health Gauges | System performance indicators |
| 30-Day Trends | Visual trend charts |
| Predictive Projections | AI-assisted forecasting |

### Metrics Tracked

- Active communities count
- Daily active users
- New signups per day
- Daily revenue
- API response times
- Error rates
- Database performance

---

## Database Schema

### Core Tables

#### `plans`
| Column | Type | Description |
|--------|------|-------------|
| id | SERIAL PK | Auto-increment ID |
| code | VARCHAR(50) UNIQUE | Plan identifier |
| name | TEXT | Display name |
| description | TEXT | Plan description |
| max_members | INTEGER | Member limit (null = unlimited) |
| price_monthly | INTEGER | Monthly price in cents |
| price_yearly | INTEGER | Yearly price in cents |
| features | JSONB | Feature list array |
| is_popular | BOOLEAN | Featured plan flag |
| is_public | BOOLEAN | Show on public pricing page |
| is_custom | BOOLEAN | Requires custom quote |
| is_white_label | BOOLEAN | White label plan |
| sort_order | INTEGER | Display order |

#### `communities`
| Column | Type | Description |
|--------|------|-------------|
| id | VARCHAR(50) PK | UUID |
| name | TEXT | Organization name |
| logo | TEXT | Logo URL |
| primary_color | TEXT | HSL color value |
| secondary_color | TEXT | HSL color value |
| description | TEXT | Organization description |
| member_count | INTEGER | Cached member count |
| plan_id | INTEGER FK | Reference to plans |
| billing_status | ENUM | active, past_due, canceled, trialing |
| trial_ends_at | TIMESTAMP | Trial expiration |
| account_type | ENUM | STANDARD, GRAND_COMPTE |
| contract_member_limit | INTEGER | Contractual limit (Grand Compte) |
| stripe_customer_id | TEXT | Stripe customer ID |
| stripe_subscription_id | TEXT | Stripe subscription ID |
| stripe_connect_account_id | TEXT | Stripe Connect ID |
| payments_enabled | BOOLEAN | Payments active |
| platform_fee_percent | INTEGER | Platform fee (default 2%) |
| white_label | BOOLEAN | White-label enabled |
| white_label_tier | ENUM | basic, standard, premium |
| billing_mode | ENUM | self_service, manual_contract |
| brand_config | JSONB | Custom branding |
| full_access_granted_at | TIMESTAMP | VIP access start |
| full_access_expires_at | TIMESTAMP | VIP access end |
| full_access_reason | TEXT | VIP reason |
| full_access_granted_by | VARCHAR FK | Admin who granted VIP |
| created_at | TIMESTAMP | Creation date |

#### `platform_sessions`
| Column | Type | Description |
|--------|------|-------------|
| id | UUID PK | Session ID |
| user_id | UUID FK | Admin user reference |
| token | TEXT UNIQUE | Session token |
| ip_address | TEXT | Login IP |
| user_agent | TEXT | Browser info |
| expires_at | TIMESTAMP | Expiration time |
| revoked_at | TIMESTAMP | Revocation time |
| created_at | TIMESTAMP | Creation time |

#### `platform_audit_logs`
| Column | Type | Description |
|--------|------|-------------|
| id | UUID PK | Log ID |
| user_id | UUID FK | Acting admin |
| action | ENUM | Action type |
| target_type | TEXT | Target entity type |
| target_id | TEXT | Target entity ID |
| details | JSONB | Additional details |
| ip_address | TEXT | Request IP |
| user_agent | TEXT | Browser info |
| country_code | TEXT | Geo location |
| success | BOOLEAN | Action success |
| error_message | TEXT | Error if failed |
| created_at | TIMESTAMP | Log timestamp |

---

## API Endpoints

### Authentication

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/accounts/register` | Mobile user registration |
| POST | `/api/accounts/login` | Mobile user login |
| POST | `/api/admin/login` | Web admin login |
| POST | `/api/platform/login` | Platform admin login |
| POST | `/api/platform/validate-session` | Validate session token |
| POST | `/api/platform/renew-session` | Renew session |
| POST | `/api/platform/logout` | Platform logout |
| POST | `/api/memberships/claim` | Claim membership with code |

### Plans & Billing

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/plans` | List all plans |
| GET | `/api/plans/:id` | Get plan by ID |
| GET | `/api/communities/:id/quota` | Check member quota |
| PATCH | `/api/communities/:id/plan` | Change community plan |

### Platform Admin

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/platform/communities/:id/full-access` | Grant VIP access |
| DELETE | `/api/platform/communities/:id/full-access` | Revoke VIP access |
| PATCH | `/api/platform/communities/:id/white-label` | Update white-label |
| GET | `/api/platform/communities/:id/details` | Get community details |
| GET | `/api/platform/audit-logs` | Get audit logs |
| GET | `/api/platform/metrics` | Get platform metrics |
| GET | `/api/platform/health` | Get health metrics |

### Membership Plans

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/communities/:id/membership-plans` | List membership plans |
| POST | `/api/communities/:id/membership-plans` | Create membership plan |
| PATCH | `/api/membership-plans/:id` | Update membership plan |
| DELETE | `/api/membership-plans/:id` | Delete membership plan |

### Tags

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/communities/:id/tags` | List tags |
| POST | `/api/communities/:id/tags` | Create tag |
| PATCH | `/api/tags/:id` | Update tag |
| DELETE | `/api/tags/:id` | Delete tag |

### Collections (Fundraising)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/communities/:id/collections` | List collections |
| POST | `/api/communities/:id/collections` | Create collection |
| PATCH | `/api/collections/:id` | Update collection |
| DELETE | `/api/collections/:id` | Delete collection |

---

## Security Considerations

### Authentication
- Email/password login with bcrypt hashing
- Session-based authentication with 2-hour expiry
- Role-based access control (RBAC)
- Platform admin routes protected by session validation

### Data Isolation
- All queries filtered by `community_id`
- Users can only access communities they belong to
- Admin actions scoped to authorized communities

### Platform Security
- IP restriction to France (CloudFlare headers)
- Full audit trail for all admin actions
- Rate limiting on login attempts
- Single active session enforcement

### Best Practices
- Password hashing with bcrypt
- HTTPS enforcement
- Input validation with Zod schemas
- SQL injection prevention via Drizzle ORM
- Secrets stored in environment variables

---

## File Structure

```
├── client/
│   ├── src/
│   │   ├── components/
│   │   │   ├── layouts/
│   │   │   │   ├── AdminLayout.tsx
│   │   │   │   └── MobileLayout.tsx
│   │   │   └── ui/
│   │   ├── contexts/
│   │   │   └── AuthContext.tsx
│   │   ├── hooks/
│   │   │   └── useApi.ts
│   │   ├── i18n/
│   │   │   ├── config.ts
│   │   │   └── locales/
│   │   │       ├── fr.json
│   │   │       └── en.json
│   │   ├── lib/
│   │   │   ├── api.ts
│   │   │   └── queryClient.ts
│   │   └── pages/
│   │       ├── admin/
│   │       ├── mobile/
│   │       │   ├── admin/
│   │       │   │   ├── Tags.tsx
│   │       │   │   ├── Events.tsx
│   │       │   │   └── Fundraising.tsx
│   │       │   └── ...
│   │       ├── platform/
│   │       │   └── SuperDashboard.tsx
│   │       └── website/
│   │           ├── Layout.tsx
│   │           ├── Home.tsx
│   │           ├── Pricing.tsx
│   │           ├── Contact.tsx
│   │           └── FAQ.tsx
│   └── index.html
├── docs/
│   ├── KOOMY_TECHNICAL_DOCUMENTATION.md
│   ├── enterprise-accounts.md
│   └── plan-limits.md
├── server/
│   ├── db.ts
│   ├── index.ts
│   ├── routes.ts
│   ├── seed.ts
│   └── storage.ts
├── shared/
│   └── schema.ts
├── attached_assets/
│   └── (community collage image for homepage)
└── package.json
```

---

## Deployment

### Environment Variables

| Variable | Description |
|----------|-------------|
| DATABASE_URL | PostgreSQL connection string |
| PGHOST | Database host |
| PGPORT | Database port |
| PGUSER | Database user |
| PGPASSWORD | Database password |
| PGDATABASE | Database name |
| STRIPE_SECRET_KEY | Stripe API key |
| STRIPE_WEBHOOK_SECRET | Stripe webhook secret |
| SENDGRID_API_KEY | SendGrid API key |

### Build Commands

```bash
# Development
npm run dev

# Database push
npm run db:push

# Production build
npm run build

# Start production
npm run start
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 0.1.0 | 2025-11-30 | Initial prototype - Full frontend with mock data |
| 0.2.0 | 2025-11-30 | PostgreSQL integration, API routes, real authentication |
| 0.3.0 | 2025-12-01 | Three-tier authentication (accounts/users/platform admins), membership claiming |
| 0.4.0 | 2025-12-01 | Subscription plans system with 5 canonical plans, member quota enforcement |
| 0.5.0 | 2025-12-01 | Full Access VIP system for platform admins, security hardening |
| 0.6.0 | 2025-12-02 | Internationalization (i18n) - French/English support for public website |
| 0.6.1 | 2025-12-02 | Complete translations for Pricing, Contact, FAQ pages including plan content |
| 0.7.0 | 2025-12-XX | Economic Model - Stripe Billing + Connect integration, transactions tracking |
| 0.8.0 | 2025-12-XX | White Label feature - Custom branding, manual contracts, tiered pricing |
| 0.9.0 | 2025-12-XX | Platform Security - Sessions, audit logs, IP restrictions, rate limiting |
| 0.10.0 | 2025-12-XX | Promotions & Tags systems - Full CRUD with capability checks |
| 0.11.0 | 2025-12-XX | Mobile Admin App (Koomy Pro) - Feature parity with back-office |
| 0.12.0 | 2025-12-20 | Enterprise Accounts (Grand Compte) - Contractual limits, full feature access |

---

*Document generated for Koomy SaaS Platform*
*Last updated: December 21, 2024 at 14:30 UTC*
