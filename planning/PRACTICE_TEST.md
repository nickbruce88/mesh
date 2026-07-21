# Mesh — Practice Plan Test Checklist (v40.08 → v40.13)
_Test on the LIVE app (app.meshsports.co), signed in as a **coach**. Most of this is the practice
plan rework — the big one is that plans now **survive a reload** (they used to vanish)._

Bring any failure back with **what you did + what you saw**.

---

## ⚠️ 0. FIRST — did the SQL get re-run?
Simple-mode saving depends on the updated `save_practice_day` in `planning/phase3e-practice-days.sql`.
If you re-ran that file in the Supabase SQL editor after I asked, you're good. **If you're not sure,
re-run it now** (it's `create or replace`, safe to re-run, no data loss). Without it, **simple-mode
plans silently won't save** (detailed grid is unaffected).

---

## 1. Persistence — detailed grid (the headline fix)
- [ ] Open Practice → pick a day → build a plan: add a few periods (a team period, a water break, an Indy group)
- [ ] Rename a **cell** (tap a group cell → change its name → Save changes)
- [ ] Add a **note** to a period and a **drill** to a cell
- [ ] Recolor a full-width period row (tap the period → color swatches → pick blue/amber/etc.)
- [ ] Set the **practice start time** (top of the grid)
- [ ] **Fully close and reopen the app** (or hard-reload) → return to that day
  - ✅ Expect: everything comes back **identical** — periods, times, cell names, note dot, drill 🎯, row color, start time
  - 🚩 Red flag: blank grid, missing note/drill, wrong times, lost colors

## 2. Persistence — simple mode
- [ ] Switch a **different** day to **Simple** mode
- [ ] Add a block, edit a block (name/time/duration/tag/focus), delete a block
- [ ] **Reload the app** → that day returns in Simple mode with your blocks
  - 🚩 Red flag: day comes back blank or as a detailed grid

## 3. Mode switching (no ghosting)
- [ ] Take a day that's **detailed**, switch it to **simple** → reload → it stays **simple** (no old grid underneath)
- [ ] Take a **simple** day, switch it to **detailed** → reload → it stays **detailed** (no old blocks)

## 4. Multi-coach shared (if you have a 2nd coach account)
- [ ] Coach A builds/edits a day → Coach B opens the same day → sees the same plan
  - (give it a couple seconds + a reload; saves are debounced ~1s)

## 5. Week handling
- [ ] Build a plan on **this week's** Tuesday
- [ ] Go to **next week** → its Tuesday is **blank** (weeks are independent — same weekday, different date)
- [ ] Come back to this week → Tuesday still has your plan

---

## 6. The practice UI changes (v40.08–v40.10)
- [ ] **One "Save changes" button** in the cell/period editor commits name + drill + note together (no separate "Insert into cell" / "Save note" buttons)
- [ ] **Create a drill from a cell:** in a cell editor, make a brand-new drill → it attaches to the cell **and** shows up in the drill dropdown **without** closing/reopening it
- [ ] **Drill wording:** the add-drill form field reads **"How to run it"** (a real how-to description), not "what it works on"
- [ ] **Row colors:** full-width team/break rows can be recolored; default is still fine — goal was to break up the "sea of green"
- [ ] **Move up / Move down** on a period (open the period → Move buttons) reorders reliably **on your phone** (drag-and-drop isn't needed); times re-flow after the move

---

## 7. Regression — normal editing still smooth
- [ ] Add / delete periods; times recompute from the start time
- [ ] Reorder by **drag** on desktop still works
- [ ] Print / export the plan still looks right
- [ ] Position-group editor (coach names / colors per column) still applies

---

## Notes / findings
_(role + what you did + what you saw)_
