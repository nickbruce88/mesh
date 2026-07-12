# Mesh Sports — Build Order
_Last updated: Planning session July 2026_

---

## The Rule
One feature at a time. Fully working. Committed to git. Validated before moving on.
Never start step N+1 until step N is done and tested.

---

## Phase 1: Beta Polish (Current HTML App)
**Goal:** Ship to 3 coaches for football season. Get real feedback.
**Timeline:** 2-3 weeks
**Success:** 3 coaches actively using it through at least 4 weeks of season

### Remaining Beta Tasks
- [ ] Finish bug fixes from test checklist
- [ ] RLS turned ON for all tables
- [ ] Custom SMTP (emails from noreply@meshsports.co)
- [ ] TOS + Privacy Policy live at meshsports.co
- [ ] COPPA consent flow for player accounts
- [ ] Beta codes generated (3 codes)
- [ ] Basic web push notifications (even simple ones)
- [ ] meshsports.co landing page that explains what Mesh is

**Hard stop:** No new features. Fix and ship.

---

## Phase 2: Foundation (Monorepo + Auth)
**Goal:** Empty but properly structured app that can be built upon
**Timeline:** 2 weeks

### Step 1 — Monorepo Setup
- Initialize Turborepo monorepo
- Create `apps/web` (Next.js) and `apps/mobile` (Expo) shells
- Create `packages/supabase`, `packages/ui`, `packages/config`
- Connect to existing Supabase project
- Generate TypeScript types from existing schema
- Set up environment variables
- Deploy empty Next.js to Vercel
- Get Expo running on simulator

### Step 2 — Authentication
- Sign up flow (web + mobile)
- Sign in flow (web + mobile)
- Session persistence
- Password reset
- Role-based redirect after login (coach → coach UI, player → player UI)
- Beta code redemption on signup

### Step 3 — Program Creation (Head Coach Onboarding)
- Guided setup wizard (5 steps max):
  1. School name + sport
  2. Upload logo + pick team colors
  3. Add coaching staff
  4. Import roster (CSV or manual)
  5. Done — send your first announcement
- Smart defaults so steps are optional
- **Target: under 10 minutes from signup to first announcement**

---

## Phase 3: The Hook (Communication)
**Goal:** The thing that gets coaches in the door
**Timeline:** 3 weeks

### Step 4 — Announcements
- Coach posts announcement
- Audience selection (coaches / players / parents / all)
- Urgency levels (normal / important / urgent)
- Push notification fires to all recipients immediately
- Player sees it on home screen with unread badge
- Parent sees it on home screen with unread badge

### Step 5 — Push Notifications (Real)
- Expo push token registration on app launch
- Web push token registration on web
- Store tokens in `notification_tokens` table
- Supabase Edge Function: `send-notification`
- Triggered by: new announcement, stat approval, schedule change
- Works on iOS, Android, and web

### Step 6 — Schedule
- Coach creates and manages schedule
- All roles can view
- Push notification when schedule changes
- Calendar and list views
- Export to device calendar

---

## Phase 4: The Roster (The Pain Point)
**Goal:** The thing that makes them stay
**Timeline:** 3 weeks

### Step 7 — Roster Management
- Add players manually
- Import from CSV
- Import from Hudl roster export
- Player profiles (photo, position, jersey, grade, contact info)
- Parent linking (player → parent account)

### Step 8 — Contact Management
- Parent contact info accessible to coaches
- Emergency contacts
- Export roster as CSV (trust feature)
- Bulk messaging to parents

### Step 9 — Staff Management
- Invite assistant coaches
- Role permissions (who can do what)
- Staff directory

---

## Phase 5: Practice Planning (The Differentiator)
**Goal:** The feature that makes Mesh worth paying for
**Timeline:** 4 weeks
**Reference:** MESH_PRACTICE_PLANNING.md for full spec

### Step 10 — Practice Plan Builder
- Create practice plan with named periods
- Optional timing per period (supports both timed and sequenced coaches)
- Assign periods to unit (offense/defense/special teams/full team)
- Assign period owner (which coach is responsible)
- Publish to staff with push notification

### Step 11 — Drill Library
- Carry over from current app (already built, proven valuable)
- Organized by unit and position group
- Searchable and filterable
- Add drills from library OR free text into any period
- Shared across all coaches on staff

### Step 12 — Templates
- Save any plan as a template
- "Game Week Monday" template that repeats weekly
- Duplicate last week's plan and adjust
- Skeleton auto-populates, coach fills in this week's drills

### Step 13 — Mobile Practice View
- Clean, large-text view for phone on the field
- Filter toggle: "My periods only" vs "Full plan"
- Offline cached so it works in bad cell service
- Print to PDF (full plan, or by unit/coach)

---

## Phase 6: The Operations Layer
**Goal:** The depth that makes switching cost too high
**Timeline:** 3 weeks

### Step 14 — Attendance
- Coach takes attendance at practice/game
- QR code check-in option
- Attendance history per player
- Reports for coaches

### Step 16 — Player Notes
- Coaches add notes to player profiles
- Categories (academic, discipline, performance)
- Visible to coaching staff only
- Parent can see limited version

### Step 17 — Depth Chart
- Visual depth chart by position
- Varsity / JV / Freshman levels
- Drag to reorder
- Player view (read-only)

### Step 18 — Stats
- Coach logs game stats
- Player submits own stats (pending approval)
- MaxPreps import (pipe-delimited .txt)
- MaxPreps export
- Season leaderboards
- Player stats history

---

## Phase 7: Polish + Payments
**Goal:** Ready for paying customers
**Timeline:** 3 weeks

### Step 19 — Stripe Integration
- Subscription tiers (Coach, Program, School)
- Signup → payment flow
- Beta user → paid conversion flow
- Self-service plan management
- Webhook handling for payment events

### Step 20 — Marketing Site
- meshsports.co homepage
- Feature pages (for coaches, for players, for parents)
- Pricing page
- Sign up CTA
- Demo video embed

### Step 21 — App Store Submission
- iOS App Store submission
- Google Play Store submission
- App Store Optimization (screenshots, description)

---

## Phase 8: Scale Features (Post-Launch)
- Multi-sport support
- School admin dashboard
- District licensing
- Offline mode hardening
- SSO (Google/Microsoft for school districts)
- FERPA compliance documentation
- Play designer (the big one)
- Advanced analytics

---

## The CLAUDE.md File
This lives in the root of the repo. Every Claude Code session reads it first.

```markdown
# Mesh Sports — Claude Context

## What This Is
Mesh is a coaching operations platform for high school football.
Stack: Expo (mobile) + Next.js (web) + Supabase (backend)
Supabase project ref: zsjxauwwqyyhgxzgnfoj

## Current Phase
[UPDATE THIS EVERY SESSION]

## Key Decisions Already Made
- Mobile first, always
- Supabase is source of truth
- Multi-program data model from day one
- RLS on for all tables
- Push notifications via Expo Push Service + Web Push

## Files to Read First
- /MESH_VISION.md — product vision and user personas
- /MESH_ARCHITECTURE.md — technical decisions
- /MESH_BUILD_ORDER.md — what we're building and in what order

## Current Step
[UPDATE THIS EVERY SESSION]

## Do Not
- Add features not in the current step
- Skip writing tests for auth flows
- Use localStorage for anything sensitive
- Put service role key in client code
```

