# Mesh — Session Handoff
_Last updated: 2026-07-12 (session 2). Read this first when resuming._

## Where we are in one paragraph
We set out to "test and fix the player role" (single-file app `index.html`, deployed to
app.meshsports.co via Cloudflare Pages, Supabase project `zsjxauwwqyyhgxzgnfoj`). That surfaced that
**messaging is unfinished and the server-side member directory doesn't exist**, so we pivoted to a
3-phase foundation build (see the approved plan at
`C:\Users\NickB\.claude\plans\imperative-sleeping-cupcake.md`). **Phase 1 (parent persistence) is
DONE and VERIFIED live** (v39.42 is deployed; a fresh parent join persists across refresh — which
proves `get_my_profile()` RPC exists & works, since the boot path only trusts Supabase, not
localStorage). **Now starting Phase 2 (assistant-coach join flow).** Git is installed & working —
Claude commits/pushes to `main` directly (Cloudflare auto-deploys from main push).

## PARKED (do NOT forget — user explicitly flagged): Parent demo-data cleanup
Deferred to stay in the 3-phase scope, but the user wants it done. The parent role persists correctly
but is still full of fake content (GPA 3.8, "vs Emmett Huskies · Tonight!", "Coach Williams").
Full worst-first list is in the "PARENT DEMO-DATA CLEANUP" section below. Revisit after Phase 2/3.

## Deploy / git (NEW as of 2026-07-12)
- Git was just installed so Claude can **commit + push to `main` directly** in future sessions
  (git was NOT on this shell's PATH, so nothing was committed this session — a fresh window will have it).
- Static site: `index.html` **is** the app. No build step, no CI. Deploy = push to the Cloudflare-connected
  repo (user confirms exact mechanism).
- **Version bump on every change:** two spots in `index.html` — the footer text (`Mesh vXX.XX`, ~line 5316)
  and `const APP_VERSION` (~line 5327). Keep them in sync.
- `sw.js` is **push-notifications only** (no fetch/cache handler) — it does NOT cache the page. Stale
  versions after deploy are just Cloudflare/browser cache, not the service worker.
- User is manually deploying v39.41→v39.42 this time to re-sync. From next session, Claude commits/pushes.

## The 3-phase plan (user-approved scope — nothing beyond these three)
1. **Parent server-side persistence** — ✅ DONE & VERIFIED live (v39.42).
2. **Assistant-coach join flow** — ✅ CODE DONE in v39.43 (this session); NEEDS DEPLOY + TEST (see below).
3. **Messaging schema + proper RLS** ← NEXT (then, later, the witnessed private-DM UI once real members exist)
Witnessed-DM UI is **deferred** until real members (2nd coach / parents) exist.

## Phase 2 — Assistant-coach join (v39.43, this session) — what changed & how to test
**No new SQL required** — reuses the existing `create_profile(user_id, user_program_id, user_role, user_name)`
RPC (head coach passes `'head_coach'`; assistant passes `'coach'`). Phase 1's `resolveUserSession`
profiles-fallback already resolves `role='coach'` and launches the coach UI — untouched.
Client changes in `index.html`:
- New join step `join-step-3-coach` (~2475) — name + optional title, button → `submitCoachProfile()`.
- `verifyJoinCode` (~9256): coach-detected codes now auto-route to account creation (was dead-ending
  at the player/parent role-picker). Coach detection already worked (`coach_code`→'coach', ~9148).
- `submitJoinAccount` (~9326): routes coach → `join-step-3-coach` after account creation.
- `submitCoachProfile()` (~9465): calls `create_profile` with `user_role:'coach'`; sets `isHeadCoach=false`.
- `launchApp` (~20386): now selects `owner_id` and sets **`isHeadCoach = (owner_id === my uid)`** for the
  coach UI — this is what makes a reloaded assistant view-only and the head coach full-edit. Calls
  `applyPermissionState()` after buildNav. (Permission model `isHeadCoach`/`applyPermissionState` already
  existed, previously only driven by the manual `switchSubRole` dev toggle.)
- Locked-banner (~9915) de-hardcoded ("Coach Williams" → `obProgram.coachName || 'the head coach'`).
**TEST after deploy (footer must read v39.43):**
1. As head coach, get the **coach code** (home tab join code / Settings). On a 2nd browser/incognito,
   Join → enter coach code → should skip role-picker → create account → name/title → "Join staff".
2. Assistant lands in coach UI; practice/script **edit buttons hidden + "View only" banner** shows.
3. Reload as the assistant → still lands in coach UI, still view-only (proves `profiles` resolve +
   ownership check). Supabase: `select id,role,name from profiles where role='coach';` shows the row.
4. Head coach reload → still full edit (isHeadCoach true; they own the program).
**Possible gotcha:** if the coach join errors, check for a CHECK constraint on `profiles.role` that
excludes `'coach'` (only `head_coach`/`parent` seen so far). Fix = drop/loosen the constraint. Watch the
console for `[Join] create_profile (coach) error`.

## What changed in `index.html` this session (all local, in v39.42)
**Performance tab (player) — done:**
- `setPlayerPerfTab` (~14108): Training toggle now calls `renderPlayerPerfMine()` (was `renderMyInfoPage()`).
- `showTab` player/performance (~5596): renders Game Stats on entry via `setPlayerPerfTab('game')` + loads
  `PERF_DATA` in background (was leaving Game Stats blank).

**Phase 1 parent persistence — done, needs deploy + test:**
- Parent player dropdown (~9187–9236): query `select id,name,pos`; `option.value = player id`, name in
  `dataset.name`. PLAYERS fallback uses `db_id||id`.
- `submitParentProfile` (~9420): now `async`; calls `db.rpc('register_parent', {p_user_id,p_program_id,
  p_name,p_player_id})` with UUID-guarded ids; keeps localStorage + success screen; toasts on error.
- `resolveUserSession` (~8850): added a 3rd fallback after players/programs — reads the caller's own
  profile via `db.rpc('get_my_profile')` (SECURITY DEFINER, because `profiles` has RLS) → loads program →
  `launchApp(role, {name,role}, prog.id)`. Fixes parent reload/sign-in; pre-wires assistant coaches.

## SQL state (Supabase dashboard)
- ✅ RAN by user: `parent_links` table + `register_parent(p_user_id,p_program_id,p_name,p_player_id)` RPC.
- ⚠️ VERIFY was run: `get_my_profile()` RPC (returns caller's profile via `auth.uid()`, SECURITY DEFINER).
  Exact SQL for all three is in the plan file / session log. Re-supply if unsure.

## Immediate next steps (do these first on resume)
1. **User deploys v39.42.** Confirm the live footer reads v39.42.
2. Confirm `get_my_profile()` SQL was run.
3. **Fresh parent join** (the earlier test parent has no profiles/parent_links row — register_parent code
   wasn't live when they tested; re-joining upserts and backfills).
4. Re-test: reload lands in parent view; sign-in works (no "account not found").
5. Diagnostic: `select id,program_id,role,name from profiles order by role;` and `select * from parent_links;`
   — confirm the parent rows exist.
6. If still failing after deploy: capture the console `[Session] get_my_profile error` line and the
   `profiles` columns (`select column_name,is_nullable,column_default from information_schema.columns
   where table_name='profiles';`) — likely a NOT NULL column register_parent doesn't set.

## Known-good root-cause note
"Account not found" + failed reload were almost certainly because **the new client code was never
deployed** (register_parent never ran → no profile row), NOT necessarily RLS. The `get_my_profile`
fix is in place regardless and is correct if `profiles` SELECT is RLS-blocked. Confirm after deploy.

## Next chunk after Phase 1 persistence verifies: PARENT DEMO-DATA CLEANUP
The parent role is **mostly static hardcoded HTML** — `showTab` has NO parent render hooks for home/schedule.
Only Announcements (`renderAnnouncements('parent')`, list at ~4071) and Documents
(`renderSharedDocs('parents')`, ~4197) are real. Seed arrays (`SCHEDULE`,`ANNOUNCEMENTS`,`PLAYERS`,
`THREAD_DATA`,`PARENT_MEMBERS`) are already empty. Egregious fake content, worst first:
1. **Schedule tab** (~4025–4046): full fake season (`vs. Caldwell W 28–14`…`vs. Emmett Huskies · Tonight!`).
   Toggle calls `setSchedView` which **doesn't exist** → never clears. Fix: wire to real `SCHEDULE`
   (reuse `renderPlayerSchedule` pattern) + real toggle.
2. **More → "My Player"** (~4111–4169): fake `#22`, `Wide Receiver`, **GPA 3.8**, `34 rec/487 yds/5 TD`,
   `Coach Reed`, `Coach Waite`. Should render the parent's REAL linked player via `parent_links → players`.
3. **Home tab** (~3982–4004): `Hi, Family`, fake next-game (`vs Emmett`), fake announcements (`Coach
   Williams`), fake "This week". `parent-home-name`/`parent-home-sub` ids never populated by JS.
4. **Checklist** (~4183–4187): fake "Concussion Waiver Signed · Verified by Coach Williams".
5. **`openParentDirectThread`** (~12235): dead code with `Coach Williams`/`Marcus away jersey` demo — scrub.

**Open decision for user:** full "wire to real data" cleanup (recommended — makes parent role usable) vs a
faster first pass to clean empty states, wiring real rendering later.

## Deferred follow-ups (not in the 3-phase scope; noted)
- `renderMyInfoPage` season totals (~17778/17786) may string-concat stat values (missing `parseFloat`).
- Dead demo fns `renderPlayerStanding` (~17912), `renderPlayerGroup` (~17977) — no callers; delete.
- `players` column drift: inserts use `num`/`pos`; coach-edit update (~15710) writes `number`/`position*` —
  confirm real columns before Phase 3 stats work.

## Gotchas for whoever edits `index.html`
- It's ~18,500 lines, single file. **Giant data-URL lines around 9483–9485 blow the Read token limit** —
  read with `offset`/`limit` and avoid that range.
- There's a **dev role-switcher** (`.role-tab` at ~2489); real login (`login('player')`, ~9416) actually
  drives auth by clicking `.role-tab:nth-child(3)`. Fragile but works — don't remove the switcher.
- Messaging today = flat `messages` table keyed by a free-text `group_name` string; no participants,
  no sender-uid; privacy decided client-side. RLS written but not globally ON.
