# Mesh — Roadmap to Production (App Store + real codebase)

_Drafted 2026-07-26. The forward plan for taking Mesh from a single-file beta PWA to native
apps on a maintainable codebase. Companion to [MESH_ARCHITECTURE.md](MESH_ARCHITECTURE.md)
(the target architecture) and [BETA_STATUS.md](BETA_STATUS.md) (where we are now)._

> **Guiding rule (from the architecture doc):** the current `index.html` app stays **live and
> stable for beta coaches** through the entire migration. No downtime. `index.html` is the spec —
> every feature in it maps to a component in the new app. Supabase (schema, RLS, edge functions)
> carries over unchanged.

---

## Phase 0 — Decisions to lock first (these gate everything)

**D1. Native strategy — how do we get into the App Store / Play Store?**
Three viable paths:

| Path | What it is | Pros | Cons |
|------|-----------|------|------|
| **A. Wrap the PWA** | Capacitor (or TWA/PWABuilder) around today's `index.html` | Fastest to stores; one codebase; near-zero rework | Still a 24k-line single file; **Apple 4.2 "minimum functionality"** risk for wrappers; harder to maintain long-term |
| **B. Full rewrite** | Expo/React Native mobile + Next.js web, per the architecture doc | Real native apps; maintainable; the intended destination | Months of work for a solo founder; slowest to stores |
| **C. Phased (recommended)** | Build the monorepo foundation now, port feature-by-feature to Expo, keep the PWA live until native reaches parity | Destination-correct without a big-bang cutover; beta never breaks | Requires discipline to run two surfaces briefly |

**Recommendation: Path C.** Go native properly (the product is mature enough to deserve it), but
incrementally — not a throwaway wrapper, not a risky big-bang rewrite. Optionally ship an interim
Capacitor wrapper *only if* store presence is urgent before the rewrite lands (accept the 4.2 risk).

**D2. Rewrite fresh vs. split the single file.** Recommend **rewrite fresh in the monorepo** using
`index.html` as the spec, rather than mechanically splitting the HTML. The vanilla-JS patterns
won't port cleanly to React; a clean re-implementation against the same Supabase backend is faster
and cleaner than untangling the monolith.

**D3. Who builds it & cadence.** Solo founder + Claude Code. Implies: prioritize ruthlessly, port
the highest-value flows first, keep each step shippable.

---

## Phase 1 — Foundation & codebase restructure

Do these regardless of D1 — they pay off immediately and are prerequisites for native.

1. **Adopt the Supabase CLI + versioned migrations.** Today every schema change is a loose SQL file
   in `planning/` run by hand. Move to `supabase/migrations/` under the CLI so the DB is
   reproducible, reviewable, and deployable. Back-fill the existing schema as a baseline migration.
2. **Generate TypeScript types from the schema** (`supabase gen types`) into a shared package — one
   source of truth for the data model across web + mobile.
3. **Stand up the monorepo** (Turborepo) per the architecture doc: `apps/web` (Next.js),
   `apps/mobile` (Expo), `packages/{ui,supabase,config}`.
4. **Extract the design system** — colors, typography, spacing, the Lucide icon set — into
   `packages/config`/`packages/ui` so web and mobile share one look.
5. **Port order (highest value first), using `index.html` as the spec:** auth/onboarding → roster →
   depth chart → practice planner → schedule → messaging (+witness) → announcements → attendance →
   inventory → performance → documents.

## Phase 2 — App Store / Play Store readiness

1. **Developer accounts:** Apple Developer Program ($99/yr), Google Play Console ($25 one-time).
2. **Build/submit pipeline:** EAS Build + EAS Submit (Expo). EAS Update for OTA JS updates.
3. **Native push:** APNs (iOS) + FCM (Android) via Expo Push; migrate off the PWA Web Push path for
   native users (Web Push stays for the PWA).
4. **Deep links / universal links** for the email-confirmation and invite/join + ownership-claim
   flows so they open the app, not a browser.
5. **Store listings:** app icons, screenshots per device class, descriptions, keywords.
6. **Privacy & data safety (extra scrutiny — kids' data):** Apple Privacy Nutrition Labels, Google
   Data Safety form, age rating. **If listing in a kids category or enabling under-13 use, the COPPA
   verifiable-parental-consent gate (see [BACKLOG.md](BACKLOG.md)) becomes a hard blocker.** Keep the
   "13+ only" posture until that flow exists.
7. **Apple review risks to pre-empt:** 4.2 minimum functionality (a real native app with push/camera
   clears this; a thin wrapper is riskier); demo account for reviewers; account-deletion in-app
   (Apple requires it if you support account creation).

## Phase 3 — Business & operations

1. **Payments:** Stripe Billing + Customer Portal, webhooks → Supabase account status. Grandfather
   beta coaches (per the live pricing promise).
2. **Migrate beta coaches** from the PWA to native once at parity — no data migration needed (same
   Supabase backend), just get them to install the store build.
3. **Observability:** error monitoring (e.g. Sentry), basic product analytics, uptime.
4. **Harden:** confirm RLS on every table, service-role only in edge functions, data-export for
   coaches, account deletion.

---

## Immediate next steps (small, concrete)
- [ ] **Decide D1** (native strategy) — recommend Path C. Everything else keys off this.
- [ ] Set up the **Supabase CLI + migrations baseline** (valuable on any path).
- [ ] **Generate TS types** from the schema.
- [ ] Scaffold the **Turborepo skeleton** (`apps/`, `packages/`) with the shared Supabase client.
- [ ] Register **Apple + Google developer accounts** (lead time on approval, so start early).

## Open questions for the founder
- How urgent is store presence vs. code quality? (Drives whether we do an interim wrapper.)
- Target launch window / how many beta programs before we commit to the rewrite?
- Native scope on day one — all three roles, or coach-first with player/parent following?
- Are we enabling under-13 (middle-school/youth) at launch? If yes → COPPA flow is now on the
  critical path, not parked.
