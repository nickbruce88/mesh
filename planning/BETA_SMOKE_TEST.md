# Mesh — Pre-Beta Smoke Test Checklist
_Created 2026-07-16. Test against the LIVE app (app.meshsports.co), signed in as each role._

⚠️ = something we specifically fixed in the audit → highest regression risk. Hit these hardest.
A failing ⚠️ item = a regression in something already fixed. A failing non-⚠️ item = likely a new find.
Bring any failure back with **role + what you saw**.

Throughout, watch for three mobile failure modes: (a) blank where desktop has content,
(b) page scrolls sideways, (c) buttons too small/overlapping to tap.

---

## 📱 PHONE

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
- [ ] Post an announcement → appears
- [ ] ⚠️ Messaging — send a message; confirm push notification arrives on the phone
- [ ] Enter/approve a stat

### Player
- [ ] Log in → home renders
- [ ] ⚠️ My Schedule — list + calendar, correct Home/Away labels
- [ ] My stats load
- [ ] Announcements visible
- [ ] Messaging send/receive + push
- [ ] Documents open
- [ ] ⚠️ Notification settings — only the Messages toggle remains (dead practice/games/roster toggles gone)

### Parent
- [ ] Log in → Home shows "This week" events immediately (⚠️ used to be empty until you navigated)
- [ ] ⚠️ My Player pulls real data (jersey `#22`, position, stats) — not blank, not placeholder
- [ ] ⚠️ Schedule list + calendar, correct labels
- [ ] Documents open
- [ ] Messaging + push
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
