# Mesh — Session Handoff
_Last updated: 2026-07-15 (session 3). Read this first when resuming._

## SESSION 3b (2026-07-15) — Parent Home events + Playbook removal → v39.60
User-requested after v39.59 went live and My Player was confirmed pulling real data.
- **Playbook REMOVED from the parent role** (More-menu item). Parents don't need it. It was never in the
  parent desktop sidebar, so the menu item was the only entry point.
- **Parent Home now has "This week" + "Coming up"** (`renderParentHome`): "This week" = today → end of the
  current week (Sunday); "Coming up" = everything after, capped at 5 with a "View all N upcoming events ›"
  link into the Schedule tab. Both read the real `SCHEDULE`. New helpers: `schedLocLabel`, `schedEventName`,
  `parentEventRow`.
- **PRE-EXISTING BUG FIXED — `g.home` doesn't exist.** SCHEDULE entries carry **`homeAway`**
  ('home'|'away'|'neutral'|null), NOT `home`. `renderRoleSchedule` read `g.home` → always undefined →
  **every event in the player AND parent schedule list was labelled "Away"** with a gray pill. Now uses
  `schedLocLabel`/`schedEventName` (which also handle `neutral`, and title-only non-game events that
  have no opponent). `updateNextGame` (coach) always used `homeAway` correctly.
- **PRE-EXISTING BUG FIXED — parent desktop sidebar rendered nothing.** `buildDesktopSidebar`'s click
  handler routed parent `more` items through the COACH's `showMoreSection` (same bug class as the
  `showTab` one in v39.59). "My Player" looked for `more-myplayer` (doesn't exist); "Documents" targeted
  the coach's `more-docs` inside a hidden tab. Added a `role === 'parent'` branch → `showParentSection`,
  and changed the parent sidebar config `more: 'docs'` → `'documents'` to match `parent-section-documents`.
- Verified in-browser with injected SCHEDULE data: banner/this-week/coming-up bucket correctly, past games
  excluded, TODAY pill, practice rows (no homeAway) render with no pill, cap + "View all 6" link works,
  Home/Away/Neutral now all correct in the schedule list, desktop sidebar sections activate.

**⚠️ SEPARATE PRE-EXISTING BUG — NOT fixed, needs a decision:** `exportCalendar()` (the 📅 Export button on
the parent AND player/coach schedule) iterates **`SEASON_EVENTS`, which is a hardcoded EMPTY array**
(~5834). So Export produces an empty .ics for every role. It should almost certainly iterate `SCHEDULE`.
It also reads `evt.home` (same nonexistent field as above) and hardcodes "Kickoff: 7:00 PM" / 2024 in the
calendar name. Left alone to avoid scope creep — flag to the user.

## SESSION 3 (2026-07-15) — Parent demo-data cleanup → v39.59
The PARKED parent cleanup is **DONE (client-side)** but **needs SQL + a live test**.
**⚠️ RUN THIS FIRST: `planning/parent-cleanup.sql`** (adds `get_my_player()` SECURITY DEFINER RPC).
Until it's run, parent → More → My Player shows "No player linked to your account yet" (it degrades
gracefully — verified — but shows no real player).

**Decision taken (user):** full wire-to-real-data, not a cosmetic pass.
- **Home** — `renderParentHome()`: greeting from `_sessionUser`, team+season sub from `obProgram.teamName`,
  next game computed from real `SCHEDULE` (hidden entirely when none). Fake "vs Emmett Oct 18" GONE.
- **Schedule** — fake season GONE. `renderPlayerSchedule` generalized to **`renderRoleSchedule(role)`**;
  new **`setSchedView(role,view,btn)`** (the toggle previously called a function that DIDN'T EXIST →
  ReferenceError, so the view never switched). `setPlayerSchedView` is now a thin alias.
- **My Player** — `renderParentMyPlayer()` renders the REAL linked player via `get_my_player()`
  (name/jersey/pos/year/height/weight + **real GPA** + **real disciplinary_status** badge).
  Cached in `_parentPlayer` via `loadParentPlayer(force)`.
- **Preseason Checklist** — REMOVED (section + menu item). User: it's a document-center thing
  (a coach uploads the form), not a first-class feature.
- **Position coach** card — REMOVED (no schema for it; see Future work below).
- `openParentDirectThread` demo — was already scrubbed in an earlier session (now aliases `openParentNewMsg`).

**Two PRE-EXISTING bugs found & fixed while doing this (neither caused by the cleanup):**
1. **Duplicate element IDs**: `player-sched-title`/`player-sched-sub` existed in BOTH the parent tab
   (first in document order) and the player tab. `getElementById` returns the first match, so
   **`renderPlayerSchedule` had been writing the PLAYER's title into the hidden PARENT tab** — the
   player's own schedule header never updated. Parent's are now `parent-sched-title`/`parent-sched-sub`.
   Verified with sentinel values: each role's render now writes only to its own element.
2. **Desktop parent More tab rendered nothing**: `showTab` desktop branch called `showMoreSection('myplayer')`,
   which targets the COACH's `more-*` ids (`more-myplayer` doesn't exist) and also hid the coach's
   `more-menu`. Now routes to `showParentSection('myplayer')`.

**⚠️ NAMING TRAP (cost a real bug this session):** a coach-side **`renderSchedule()` already exists**
(~19596, argless). Naming the new one `renderSchedule(role)` silently clobbered it — same scope, function
declarations, last wins. Hence **`renderRoleSchedule`**. `node --check` does NOT catch this; grep for
`function <name>` before adding any top-level function to this file.

**Privacy decision (deliberate):** `get_my_player()` returns a strict WHITELIST. It does **NOT** return
`notes_data` (private coach notes about the player), `discipline_data` (incident log), `academic_data`, or
parent contact PII. The disciplinary **status badge** is exposed; the **incident log is not**. Don't widen
this without a product decision — see the header comment in `parent-cleanup.sql`.
Also dropped the invented "✅ Academic eligibility: Eligible" row — there is no eligibility column and
deriving it from `gpa >= 2.0` would be inventing a business rule. Real GPA is shown instead.

**Verified in-browser (file:// + dev role-switcher, no auth):** v39.59 in DOM; parent Home/Schedule/
My Player all render honest empty states with zero console errors (only the expected `get_my_player`
error since the SQL isn't run); `setSchedView` no longer throws; desktop More activates the section;
player schedule unaffected. **NOT yet verified with real parent auth + data — do that after the SQL.**

**Future work surfaced (user idea, NOT built):** assign assistant coaches to a **position group + age
level**, which would give "Position coach" a real data source and could drive the depth-chart column
headers (`Coach Waite` is still hardcoded at ~2768). Also: `get_my_player()` returns ALL linked players
(a guardian can have several) but the UI renders only the first — add a switcher if that comes up.

## Where we are in one paragraph
Single-file app `index.html`, deployed to app.meshsports.co via Cloudflare Pages, Supabase project
`zsjxauwwqyyhgxzgnfoj`. Approved 3-phase foundation build (plan:
`C:\Users\NickB\.claude\plans\imperative-sleeping-cupcake.md`). **ALL THREE PHASES DONE & VERIFIED LIVE
(v39.58).** Phase 1 (parent persistence), Phase 2 (assistant-coach join + Staff Access permissions), Phase 3
(secure threads/participants messaging + RLS + witnessed DMs + real-time + notifications). **Phase 3b
(post-scope, user-requested) also DONE & live:** hide/archive threads + server-side notification prefs +
per-thread mute. Git works — Claude commits/pushes to `main`; Cloudflare auto-deploys. Deploy consent:
**ask before each push** (see [[mesh-deploy-versioning]]).
**LIKELY NEXT:** run `planning/parent-cleanup.sql`, then live-test the parent role at v39.59 (see SESSION 3).

## ~~PARKED: Parent demo-data cleanup~~ → DONE in session 3 (v39.59), pending SQL + live test.
See the SESSION 3 section at the top. The old worst-first list below is kept for reference only —
items 1–5 are all addressed.

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
2. **Assistant-coach join flow + Staff Access permissions** — ✅ DONE & VERIFIED live (v39.43–v39.47).
   Assistant joins via coach code, persists, reloads into coach UI; head coach grants per-feature edit
   via Settings → Staff Access; assistant can add players (persists) when granted roster access.
3. **Messaging schema + RLS + witnessed DM** — ✅ DONE & VERIFIED live. Step 1 (schema+client, v39.48–55),
   Step 2 (migrated legacy msgs — 0 unmigrated), Step 3 (RLS ENABLED — messages/message_threads/
   thread_participants; read/write iff participant or broadcast-to-my-role). All SQL parts in
   `planning/phase3-messaging.sql` were run; realtime publication (PART 1b) added; edge fn redeployed.
3b. **Hide/archive + notifications (post-scope, user-requested)** — ✅ DONE & live (v39.56–58).
   SQL: `planning/phase3b-notifications.sql` (RAN): thread_hides, thread_mutes, notification_prefs +
   RPCs (hide_thread/unhide_thread, set_thread_mute, set/get_notification_prefs); list_my_threads now
   returns `muted`+`archived`. Edge fn `send-notification` REDEPLOYED to skip muted/category-disabled
   recipients (client sends category+thread_id). Features: archive (hide-for-me; auto-archive >6mo quiet;
   new message un-archives) via 🗄️ in thread header + "Archived (N)" toggle in the list; per-thread mute
   🔔/🔕; category prefs (Notification settings) now persist server-side and gate bell + push.
   Key fixes found while testing 3b: un-archive on new message needed a client list refresh (v39.57);
   bell was suppressed because close functions didn't reset `currentThread` (v39.58 — closeThread/
   closePlayerThread/closeParentThread now null it).

## Phase 3 — Messaging — status & how to run
SQL in `planning/phase3-messaging.sql`, labeled parts. **RAN: PART 1** (schema + RPCs) **and PART 1b**
(realtime: added messages + message_threads to supabase_realtime publication). **Edge function
`send-notification` REDEPLOYED** to honor `target_user_ids` (per-recipient DM push). **NOT YET RUN:**
PART 2 (migrate legacy messages) ← do next, PART 3 (enable RLS + policies) ← last.
Schema: message_threads(id,program_id,created_by,kind,subject,audience_roles[],created_at),
thread_participants(thread_id,user_id,role,is_witness), messages += thread_id + sender_id.
kind = 'broadcast' (role-scoped via audience_roles) | 'dm' | 'witnessed_dm' (explicit participants).
RPCs (all SECURITY DEFINER): my_program_id/my_role/is_thread_participant, list_program_directory,
ensure_broadcast_thread, create_thread, list_my_threads, thread_members, thread_participant_ids.
Client (index.html): thread identity = thread UUID (was group_name); sender = auth uid (sender_id).
loadThreadList/renderThreadList (list_my_threads) per role on Messages open; openThread loads by thread_id
into a role-aware overlay (coach `#msg-thread-overlay`, player `#player-msg-thread-overlay`, parent
`#parent-msg-thread-overlay` — each role has its OWN overlay); sendThreadMsg writes thread_id+sender_id +
targeted push. Compose via create_thread: coach New Group (directory picker), player New Message =
witnessed_dm (coach+witness), parent New Message = dm to a coach. Real-time via a program-wide msglist
channel (all roles) + per-thread channel. In-app bell (addNotif) on incoming messages in MY threads.
Removed: THREAD_DATA/STAFF_MEMBERS/PARENT_MEMBERS/openOrCreateQuickThread/playerKnownThreads.
Step-1 fixes along the way: parent Messages tab made uniform (v39.49/.50); real-time (v39.51, needs PART 1b);
sender name showed "Me" → prefer `_sessionUser.name` (v39.52); notifications bell+push (v39.53); notif-click
left the full-screen notif-overlay open (froze nav) + header avatar stuck on "CW" on reload (v39.54);
player thread back button collapsed the overlay to display:block (v39.55).
**Enforcement note:** RLS OFF until Step 3 — privacy NOT yet server-enforced (realtime currently sees all
program messages; bell/list are gated client-side by `_threads` = list_my_threads = my participant/audience
threads, which is correct now AND under RLS).
**KNOWN PUSH CAVEAT:** web push only reaches devices that granted notification permission + have a
`notification_tokens` row; iOS needs the PWA installed to home screen. In-app bell works regardless.
**STEP 2 (do now):** uncomment & run PART 2 in `phase3-messaging.sql` (creates a broadcast thread per
distinct program_id+group_name and backfills messages.thread_id). Then verify old messages still show.
**STEP 3 (after):** uncomment & run PART 3 (enable RLS + policies). Re-verify: a non-participant cannot read
a thread; realtime still delivers (Supabase realtime respects RLS — policies must be correct).

## Latest deployed version: v39.58 (all pushed to main, live)
Bugs fixed while verifying Phase 2 (both were PRE-EXISTING, not from the permissions work):
- v39.46: `applyPermissionState` referenced undefined `DAY_INFO` → threw in launchApp during session
  restore → aborted launchApp BEFORE roster/schedule loaded (hit ALL coaches on reload once
  applyPermissionState was wired into launchApp). Guarded with `typeof` + try/catch backstop.
- v39.47: `saveAddPlayerManual` referenced undeclared `unit` → ReferenceError → manual "+ Player" add
  silently did nothing. Now derives unit from position. (Head coaches dodged it via CSV import.)
players-table RLS does NOT block assistant inserts (add-player persists) — no RLS change was needed.

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

## Phase 2b — Staff Access (per-coach, per-feature edit permissions) — v39.44, this session
Assistant coaches now default to view-only EXCEPT edit on Attendance, Inventory, Performance, Messages,
Drill Library. Head coach can grant/revoke edit on ANY of 12 features per coach, via Settings → Staff Access.
**REQUIRES SQL:** run `planning/phase2b-staff-access.sql` in Supabase (adds `profiles.permissions jsonb` +
3 SECURITY DEFINER RPCs: `set_coach_permissions`, `list_program_coaches`, `get_my_permissions`, all guarded
so only the program owner can grant). Until it's run, Staff Access won't load and grants won't save (client
falls back to role defaults + toasts on write attempts — no crash).
Client model (all in `index.html`, ~line 9958 region):
- `COACH_FEATURES` (12: roster, practice, schedule, depth, inventory, attendance, performance, drills,
  playbook, docs, messages, announcements), `ASSISTANT_DEFAULT_EDIT` = [attendance,inventory,performance,
  messages,drills]. `canEdit(feature)` (head coach & non-coach roles → always true), `requireEdit(feature)`
  (guards + toasts), `defaultAssistantPerms()`, `effectiveCoachPerms()`.
- `launchApp` loads the assistant's perms via `get_my_permissions` and computes `isHeadCoach` from
  `programs.owner_id === uid`.
- `applyPermissionState()` rewritten: hides any `[data-edit="<feature>"]` control (via `.perm-hidden`
  `!important`) the coach can't edit, plus the practice-tab specifics. Called on every coach showTab /
  showMoreSection.
- Enforcement = **38 `requireEdit` guards** on mutating handlers + **21 `data-edit` button tags**. Practice
  gates converted from `isHeadCoach` → `canEdit('practice')`.
- Staff Access UI: `openStaffAccess`/`renderStaffAccessBody`/`toggleStaffPerm`/`saveStaffAccess`
  (profile menu item `#pmi-staff-access`, head-coach-only).
- Also fixed: first-session sidebar name/initials (joinGoToApp seeds `_sessionUser`).
**Enforcement is CLIENT-SIDE only** (honest UI + blocked writes/toasts). TRUE security = RLS, which is
Phase 3. A determined assistant could still hit the DB directly until then.
**TEST after SQL + deploy (footer v39.44):**
1. Head coach → Settings (avatar) → Staff Access → see the assistant → toggle e.g. Roster ON → Save access.
2. Assistant reloads → can now add players; toggle OFF + save → assistant reload → "+ Player" hidden,
   and any edit attempt toasts "🔒 View only…".
3. Confirm defaults: fresh assistant can edit Attendance/Inventory/Performance/Messages/Drills, nothing else.
Static verification done this session: `node --check` passes; all feature keys valid; no new dup functions.

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
