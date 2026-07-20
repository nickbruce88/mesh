# Mesh — Pre-Beta Smoke Test Checklist
_Created 2026-07-16. Test against the LIVE app (app.meshsports.co), signed in as each role._

⚠️ = something we specifically fixed in the audit → highest regression risk. Hit these hardest.
A failing ⚠️ item = a regression in something already fixed. A failing non-⚠️ item = likely a new find.
Bring any failure back with **role + what you saw**.

Throughout, watch for three mobile failure modes: (a) blank where desktop has content,
(b) page scrolls sideways, (c) buttons too small/overlapping to tap.

---

## 📱 PHONE

### 🔔 FIRST — turn on notifications (every tester, every device, one time)
Push is opt-in per person per device — enabling it as one user does NOT enable it for anyone else.
Do this before the messaging/announcement push checks below. Works the same for coach, player, and parent.
- [ ] **iPhone only:** in **Safari**, open the app → **Share** → **Add to Home Screen** → **Add**, then open Mesh from the new Home Screen icon (push does NOT work from a Safari tab; needs iOS 16.4+)
- [ ] Tap the **🔔 bell** (top-right) → **Turn on notifications** → **Allow** on the browser/OS prompt
- [ ] Fully close the app, have someone send you a message → confirm the notification banner arrives
- [ ] Tap the notification → it opens the app to that conversation

### Coach
- [ ] Log in → coach home renders; nothing blank or cut off
- [ ] ⚠️ Equipment/QR scanner — open, allow camera, scan a code (top mobile risk; camera is the one enabled device permission)
- [ ] Roster loads; open a player
- [ ] ⚠️ Edit a player and Save — change name/jersey/position; confirm it persists after reload (was the save-nothing "lying write")
- [ ] ⚠️ Jersey shows as `#22`, not `##22` or `#undefined`
- [ ] ⚠️ Schedule — List/Calendar toggle both work; default is Calendar; Home/Away/Neutral labels correct (not all "Away")
- [ ] ⚠️ Add a note to a player → reload → note shows YOUR name, not the literal word "Coach"
- [ ] ⚠️ Change a disciplinary status → it sticks; auto-note attributed to you
- [ ] Take attendance; save; reload to confirm
- [ ] ⚠️ Roster importer — upload a real CSV/xlsx; confirm it's forgiving and players land correctly
- [ ] Post an announcement → appears; pick a "show on home for" duration; older ones sit under "Past announcements"
- [ ] ⚠️ Messaging — send/receive; with notifications enabled (above), closed-app push arrives
- [ ] ⚠️ Unread — a message that arrives while closed shows an unread dot + Messages nav badge on login; opening the thread clears both (and stays read on your other devices)
- [ ] Enter/approve a stat

### Player
- [ ] Log in → home renders
- [ ] ⚠️ My Schedule — list + calendar, correct Home/Away labels
- [ ] My stats load
- [ ] Announcements visible
- [ ] ⚠️ Messaging — send/receive; closed-app push (after enabling above); unread dot + Messages badge on login, clear on open
- [ ] Documents open
- [ ] ⚠️ Notification settings — only the Messages toggle remains (dead practice/games/roster toggles gone)

### Parent
- [ ] Log in → Home shows "This week" events immediately (⚠️ used to be empty until you navigated)
- [ ] ⚠️ My Player pulls real data (jersey `#22`, position, stats) — not blank, not placeholder
- [ ] ⚠️ Schedule list + calendar, correct labels
- [ ] Documents open
- [ ] ⚠️ Messaging — send/receive; closed-app push (after enabling above); unread dot + Messages badge on login, clear on open
- [ ] Confirm NO Playbook anywhere in the parent role (removed)

---

## 🖥️ DESKTOP
Desktop has its own navigation code path (the left sidebar), which had real bugs — not redundant with phone.
Focus on the sidebar for every role.

### Coach
- [ ] Sidebar: every item (roster, schedule, attendance, announcements, messaging, stats, inventory, documents, more-menu) navigates and renders
- [ ] ⚠️ All coach items above (player save, jersey `#`, schedule labels, note attribution, discipline, importer, messaging) — desktop path
- [ ] ⚠️ QR scanner via webcam (if used on desktop)
- [ ] `.ics` / calendar export + import round-trips

### Player
- [ ] Sidebar items all navigate and render
- [ ] Schedule / stats / announcements / documents / messaging all load
- [ ] ⚠️ Notification settings show only Messages

### Parent
- [ ] ⚠️ EVERY desktop sidebar item renders something — this role's sidebar used to render nothing (wrongly routed through coach handlers). Click each: Home, My Player, Schedule, Documents, Messaging.
- [ ] ⚠️ "My Player" and "Documents" specifically (the two broken targets)
- [ ] ⚠️ Home "This week" events populate on first load
- [ ] No Playbook present

---

## Notes / findings
_(jot results here as you go — role + what you saw)_
