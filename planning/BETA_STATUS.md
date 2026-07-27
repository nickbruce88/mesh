# Mesh — Beta Status

_Snapshot: 2026-07-26 · App version **v40.83** · Live at **app.meshsports.co**_

This is the "where we are" doc. For the forward plan (App Store + moving off the single-file
app), see [ROADMAP_TO_PRODUCTION.md](ROADMAP_TO_PRODUCTION.md). For parked/post-beta ideas, see
[BACKLOG.md](BACKLOG.md).

---

## TL;DR
The beta product is **feature-complete and shipping**. It's a single-file PWA (`index.html`) on
Cloudflare Pages, backed by Supabase (auth, Postgres + RLS, storage, edge functions). Coaches,
players, and parents each have a working role. Real infrastructure — web push, custom SMTP,
per-program data isolation — is live. We are in **invite-only beta** and readying the first real
programs.

---

## Stack (as built today)
- **App:** one `index.html` (~24k lines: HTML + CSS + vanilla JS), no build step. Cloudflare Pages
  auto-deploys on push to `main`.
- **Marketing:** separate `mesh-marketing` repo → meshsports.co.
- **Backend:** Supabase project `zsjxauwwqyyhgxzgnfoj` — email/password auth, Postgres with Row
  Level Security, storage (avatars/logos/docs), edge functions (`sign-avatar`, `send-notification`).
- **Email:** custom SMTP via **Resend** (configured & working — confirmation / resend / recovery).
- **Push:** Web Push (RFC 8291 aes128gcm) for installed PWAs, opt-in per person per device.
- **Install:** add-to-home-screen PWA (iOS Safari + Android Chrome), with an in-app walkthrough.

## Roles live
- **Head coach / owner** — full program admin. **Assistant coach** — scoped access.
- **Player** — own profile, schedule, stats, documents, witnessed messaging.
- **Parent** — linked to their player, schedule, announcements, witnessed messaging.
- **Ownership transfer** — owner-minted one-time `OWN-` codes + operator-only
  `admin_transfer_ownership` for abrupt departures.

---

## What's done (feature areas, all shipped)
- **Onboarding** — coach signup (beta-gated) → program creation wizard (name, sport, colors, logo,
  hex color-code entry, team levels). Join flow for players/parents/assistants and ownership claim.
- **Roster** — CSV/xlsx import (forgiving; handles multi-position, `-`/`N/A`), manual add, edit,
  per-player team-level eligibility, resilient persistence (no lost writes on local-only players).
- **Depth chart** — per-level, order-stable; positions come only from the roster; per-level
  add/remove; drag-to-reorder players AND position tiles; customizable position vocabulary.
- **Practice planner** — simple + detailed views, drag-reorder, period edit-in-place, drills from
  the cell editor, practice start time + auto-timing, structured per-date persistence, Mesh outline
  + saved-plan templates.
- **Schedule/calendar** — list + calendar views, home/away/neutral, `.ics` import/export.
- **Messaging** — 1:1 and group threads, **auto-witnessed** coach↔player DMs (SafeSport-style),
  avatars/initials/group clusters, unread tracking (server-side) + nav badges, archive/delete
  (witnessed threads protected), closed-app push.
- **Announcements** — title + body, home-visibility duration, freshness/expiry/archive/history.
- **Attendance, Inventory (QR tags), Performance/stats** (grouped stat categories, leaderboards),
  **Documents**.
- **Guides & walkthroughs** — per-tab spotlight tours + the install walkthrough; server-tracked
  "seen" state.
- **Theming** — team colors/logo throughout, light/dark, contrast-safe.
- **Icons** — migrated emoji → Lucide line-icon sprite.
- **Legal** — TOS + Privacy live; beta is **13+ only** (COPPA-compliant by non-collection).

## Recent milestones (v40.6x–v40.83)
- Pre-rollout audit sweep (contrast, persistence, modal centering, consistency).
- Program ownership transfer / claim flow + operator admin transfer.
- Configurable per-program team levels (default Varsity/JV/Freshman), persisted per player.
- Depth-chart overhaul: roster-only positions, per-level, drag-reorder tiles + players.
- Header logo sizing/overlap fixes (desktop + mobile).
- Add-to-home-screen guide (in-app + marketing site).
- Signup now says "email already exists" instead of a phantom "check your email".

---

## Known constraints / open items (not beta-blocking)
- **Single-file architecture** — `index.html` is the whole app. Fine for beta velocity; the target
  is a real monorepo (see ROADMAP). This is the next big body of work.
- **No native app yet** — PWA only. App Store / Play Store presence is a roadmap item.
- **COPPA under-13 gate** — deliberately deferred; must be built before onboarding any under-13
  player. See [BACKLOG.md](BACKLOG.md) and [MESH_LEGAL_CHECKLIST.md](MESH_LEGAL_CHECKLIST.md).
- **No payments** — beta is free; Stripe is post-beta.
- **Guides depth** — some feature guides are first-pass; can be deepened.
- **All DB migrations are run by the founder** in the Supabase SQL editor (SQL files in `planning/`).

## Beta operations quick-reference
- **Verification/troubleshooting:** Resend SMTP is live. A "repeated signup" in Auth logs just means
  the email already has an account (Supabase won't re-send) — that's expected, not a bug.
- **Smoke test before onboarding a program:** [BETA_SMOKE_TEST.md](BETA_SMOKE_TEST.md).
- **Demo environment:** [demo-account.md](demo-account.md) (Northgate Prep Hawks, parked).
- **Reset test data:** `reset-testing-data.sql`.
