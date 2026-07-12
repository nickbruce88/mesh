# Mesh Sports — Architecture Document
_Last updated: Planning session July 2026_

---

## Guiding Principle
Build for where Mesh needs to be in 2 years, not just where it is today.
Every decision should support: mobile-first, multi-program, multi-sport, real notifications, school/district scale.

---

## The Stack

### Frontend — Two Apps

#### 1. Mobile App (Expo / React Native)
**Who:** Players, parents, coaches on the go
**Why Expo:**
- Real iOS and Android apps from one codebase
- Real push notifications (the thing we can't fake in a browser)
- Installable on phone home screen — not "open a browser"
- Offline support built in
- React Native components feel native, not like a website

**Key capabilities:**
- Push notifications via Expo Push Notification Service
- Offline-first data with sync on reconnect
- Camera access (profile photos, QR scanning)
- Biometric auth (Face ID, fingerprint)

#### 2. Web Dashboard (Next.js 14, App Router)
**Who:** Head coaches doing admin/clerical work on desktop
**Why Next.js:**
- Server-side rendering = fast initial load
- File-based routing keeps code organized
- Best ecosystem for data-heavy admin interfaces
- Marketing site lives here too (meshsports.co)
- SEO-friendly for coach discovery

**Key capabilities:**
- Full roster management
- Bulk operations (import CSV, mass announcements)
- Analytics and reporting (future)
- Admin/AD dashboard (future)

---

### Backend — Keep Everything We Have

#### Supabase (Primary Backend)
- **Auth:** Email/password, magic links, future: Google/Microsoft SSO
- **Database:** PostgreSQL with Row Level Security
- **Real-time:** Supabase subscriptions for live updates
- **Storage:** Profile photos, documents, play images
- **Edge Functions:** Server-side logic (sign-avatar, future: notifications)

**Nothing changes here. This is the most valuable thing built so far.**

#### Cloudflare R2
- Video storage (future)
- Keep as-is

---

### Notifications — The Thing That Changes Everything

#### Current (Broken)
In-memory JavaScript. Disappears on refresh. Doesn't work across sessions.

#### Real Solution
```
Coach posts announcement
  → Supabase Edge Function triggers
  → Queries: who should receive this? (audience + program members)
  → Sends to Expo Push Service for mobile users
  → Sends Web Push for PWA users
  → Player/parent phone buzzes within seconds
```

**Services:**
- Expo Push Notification Service (free, handles iOS + Android)
- Web Push API (browser standard, free)
- Supabase Edge Function as the trigger point

---

### Payments
- **Stripe** — industry standard, best documentation, easy integration
- Stripe Billing for subscriptions
- Stripe Customer Portal for self-service plan changes
- Webhooks → Supabase to update account status

---

### Hosting
| App | Host | Why |
|-----|------|-----|
| Next.js web | Vercel | Best Next.js support, free tier generous |
| Expo mobile | EAS (Expo App Services) | OTA updates, App Store submissions |
| Supabase | Supabase Cloud | Already there |
| R2 | Cloudflare | Already there |

---

## Repository Structure

```
mesh/                           # Monorepo root
├── apps/
│   ├── web/                    # Next.js coach dashboard + marketing site
│   │   ├── app/                # App Router pages
│   │   │   ├── (marketing)/    # meshsports.co landing pages
│   │   │   ├── (auth)/         # Sign in, sign up, onboarding
│   │   │   └── (dashboard)/    # Authenticated coach interface
│   │   └── components/
│   └── mobile/                 # Expo React Native
│       ├── app/                # Expo Router pages
│       │   ├── (auth)/
│       │   ├── (coach)/        # Coach mobile view
│       │   ├── (player)/       # Player view
│       │   └── (parent)/       # Parent view
│       └── components/
├── packages/
│   ├── ui/                     # Shared components (Button, Card, Avatar...)
│   ├── supabase/               # Shared DB client + TypeScript types
│   │   ├── client.ts
│   │   └── types.ts            # Auto-generated from schema
│   └── config/                 # Shared constants
│       ├── sports.ts           # Sport definitions, stat categories
│       └── theme.ts            # Colors, fonts, spacing
├── supabase/
│   ├── migrations/             # Every DB change as a migration file
│   ├── functions/              # Edge functions
│   │   ├── sign-avatar/        # Already built
│   │   ├── send-notification/  # New — push notification trigger
│   │   └── stripe-webhook/     # New — payment events
│   └── seed.sql                # Test data for development
├── CLAUDE.md                   # What Claude Code reads every session
└── turbo.json                  # Monorepo build config
```

---

## Data Model (Key Decisions)

### Multi-Program From Day One
Every table has `program_id`. A user can be a member of multiple programs.
The `program_members` table is the junction — one user, many programs, different roles in each.

```sql
users                    -- Supabase Auth users
programs                 -- Each football program
program_members          -- user ↔ program with role
players                  -- Player profiles (linked to user + program)
announcements            -- Posts by coaches to audience groups
notification_tokens      -- Expo push tokens per user per device
schedules                -- Games and events
attendance               -- Per-player per-event
game_stats               -- Player stats per game
performance              -- Training data
```

### Notification Architecture
```sql
notification_tokens (
  id, user_id, token, platform (ios/android/web), created_at
)
-- When a user installs the app, their push token is stored here
-- Edge function queries this table to know where to send notifications
```

---

## What Carries Over (Nothing Is Wasted)

| Current Asset | Status | Migration Path |
|--------------|--------|----------------|
| Supabase schema | ✅ Keep | Already in production |
| RLS policies | ✅ Keep | Already written, just need ON |
| Edge functions | ✅ Keep | sign-avatar already deployed |
| Business logic | ✅ Port | Stat dedup, MaxPreps mapping, etc. |
| Design system | ✅ Port | Colors, typography into shared package |
| Current HTML app | ✅ Keep running | Beta reference + spec document |

---

## Current App → New App Migration Path

The single HTML file is the spec. Every feature in it maps to a component in the new app.
Build order ensures the most important things are done first.

**Rule:** The current app stays live and functional for beta coaches throughout the migration.
They never experience downtime. When the new app is ready, they get migrated over.

---

## Security Decisions

- RLS on for all tables before any real user data enters
- Service role key only in Edge Functions, never in client code
- Push notification tokens stored server-side only
- Stripe webhooks verified with signing secret
- COPPA: parental consent flow before any player under 18 creates an account
- Data export: coaches can download their program data as CSV at any time

---

## What We're NOT Building (Yet)
- Native video player / film room (Hudl's territory)
- Live game scoring (ESPN's territory)
- Recruiting platform (different product entirely)
- AI play calling suggestions (fun idea, not near-term)
- Social features / athlete profiles for recruiting (phase 4+)

