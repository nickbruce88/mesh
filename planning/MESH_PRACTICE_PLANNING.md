# Mesh Sports — Practice Planning Feature Spec
_Last updated: Planning session July 2026_

---

## Why This Is The Differentiator

Every coach makes a practice plan. Right now they're doing it in Google Sheets, printing it, 
and carrying paper on the field. Google Sheets is flexible but dumb — it doesn't know your 
staff, your positions, your drills, or your schedule.

Mesh knows all of that. That's the advantage.

**The pitch to a coach:**
"You're already building your practice plan in Google Sheets. What if it took half the time, 
lived on your phone during practice, auto-populated from last week's skeleton, let your 
coordinators fill in their own sections, and printed perfectly — all in one place?"

---

## The Three Types of Coaches We're Serving

### The Scripter (Detail-Oriented)
- Plans every minute of practice
- Scripts every rep in every period
- Wants timestamps on everything
- Probably the HC or OC at a serious program
- Currently uses Google Sheets with 20 columns

### The Period Coach (Structured but Flexible)
- Defines periods (Indy, Group, Team) but doesn't always time them
- Knows the sequence, leaves drill details to position coaches
- Most common head coach style
- Currently uses a printed template he fills in by hand

### The Delegator (Big Picture)
- Sets the vision: "45 minutes of offense, 30 defense, 15 special teams"
- Leaves everything else to coordinators
- Checks the plan but didn't build it
- Currently relies on a coordinator to send him a Google Doc

**Mesh needs to serve all three without forcing any of them into a box.**

---

## The Data Structure

### Practice Plan
```
practice_plan {
  id
  program_id
  date
  name              -- "Monday Week 3 - Game Prep"
  type              -- "game_week" | "bowl_prep" | "spring" | "summer" | "scrimmage"
  template_id       -- if created from a template
  status            -- "draft" | "published" | "completed"
  created_by        -- coach user_id
  notes             -- HC's overall notes for the day
  created_at
  updated_at
}
```

### Practice Period (the building block)
```
practice_period {
  id
  plan_id
  order             -- sequence within the plan
  name              -- "OL Individual" | "Team Offense" | "Special Teams" etc.
  start_time        -- optional (null = not timed, just sequenced)
  duration_minutes  -- optional
  unit              -- "offense" | "defense" | "special_teams" | "full_team" | "conditioning"
  owner_id          -- which coach owns this period (optional)
  location          -- "Field 1" | "Weight Room" | "Meeting Room" etc.
  notes             -- free text
  drills            -- array of drill references + free text
}
```

### Practice Period Drill
```
period_drill {
  id
  period_id
  order
  type              -- "saved_drill" | "free_text"
  drill_id          -- if saved_drill
  custom_text       -- if free_text
  duration_minutes  -- optional
  reps              -- optional
  notes
}
```

### Practice Template
```
practice_template {
  id
  program_id
  name              -- "Game Week Monday" | "Tuesday Script" | "Spring Install"
  periods           -- the skeleton (periods without drill content)
  created_by
}
```

### Drill Library (already exists in current app — carry over)
```
drill {
  id
  program_id
  name
  description
  unit              -- "offense" | "defense" | "special_teams" | "conditioning"
  position_groups   -- which positions are involved
  duration_default  -- suggested default duration
  notes
  tags              -- searchable
}
```

---

## The User Experience

### Building a Plan (Desktop — Head Coach)

**Step 1: Start from template or scratch**
- "Create new practice plan"
- Choose: Start from template | Duplicate last week | Build from scratch
- Template shows the skeleton (periods) without drill content
- Duplicate last week copies everything — coach just edits what changes

**Step 2: Set the skeleton**
- Add/remove/reorder periods
- Name each period ("OL Individual", "Team 7-on-7", etc.)
- Optionally set start time and duration
- Assign each period to a unit (offense/defense/special teams/full team)
- Assign a position coach as owner of that period (optional)

**Step 3: Fill in the drills**
- Within each period, add drills from the library OR type free text
- Drill library is searchable and filterable by unit/position group
- Drag to reorder drills within a period
- Each drill can have: duration, reps, notes
- Position coaches can fill in their own periods if assigned

**Step 4: Publish**
- Head coach reviews the full plan
- Hits "Publish to staff"
- All coaching staff get a push notification: "Practice plan for [date] is live"
- Plan is now viewable by all staff

### Viewing a Plan (Mobile — During Practice)

**The phone view is the most important screen in this feature.**

- Clean, large text — readable in sunlight
- Current period highlighted based on time
- Swipe between periods
- Filter toggle: "My periods only" vs "Full plan"
- Each period shows: name, time, drills in order, notes
- Cannot edit in this view (or limited editing for HC only)
- Countdown timer to next period (optional, coach can enable)

### The Filter System (Position Coach View)
A defensive line coach should be able to:
- Toggle "Show my periods only"
- See only periods where their unit is active OR they are the assigned owner
- This is their practice, on their phone, showing only what they need

### Printing
- "Print plan" generates a clean PDF
- Options:
  - Full plan (everyone gets this)
  - By unit (offense section, defense section)
  - By coach (each coach's periods only)
- Formatted for 8.5x11, readable, professional
- Looks like something you'd be proud to hand a coach
- This replaces the Google Sheet printout

---

## The Drill Library

**Already exists in the current app — this is one of the best features.**

Carry over and expand:
- Coaches build their library over time
- Organized by unit and position group
- Searchable
- Shared across the staff (everyone can use HC's drills)
- Can add notes, diagrams (future: actual play designer diagrams)
- Templates can reference library drills so next week auto-populates

**The compounding value:** The longer a coach uses Mesh, the better their drill library gets. 
After 2 seasons, they have 200 drills saved and tagged. Switching to a competitor means losing 
all of that. This is retention built into the product.

---

## Templates — The Key to Habit Formation

This is how Mesh becomes part of the weekly routine:

**"Game Week" template:**
- Period 1: Special Teams Install (15 min)
- Period 2: OL/DL Individual (20 min)
- Period 3: Skill Individual (20 min)
- Period 4: Group (15 min)
- Period 5: Team Offense (25 min)
- Period 6: Team Defense (20 min)
- Period 7: Conditioning (10 min)

Coach creates this template once. Every Monday during the season, they open Mesh, 
hit "New plan from Game Week template," and just fill in this week's drills. 
The skeleton is already there. What took 45 minutes in Google Sheets takes 10.

**That is the differentiator.**

---

## Collaborative Planning

When the head coach assigns a period to a position coach:
- That coach gets a notification: "Coach Bruce assigned you the OL Individual period for Monday"
- They can open the plan, go to their period, and fill in drills from their section of the library
- HC sees when each section is filled in
- HC can still edit any section

This mirrors how real programs work — HC sets the vision, coordinators execute.

---

## What Google Sheets Can't Do (Our Advantages)

| Feature | Google Sheets | Mesh |
|---------|--------------|------|
| Mobile view during practice | Painful | Built for it |
| Filter to my periods only | Manual hide/show | One tap |
| Drill library integration | Copy/paste | Click to add |
| Duplicate last week | Copy sheet, rename | One button |
| Staff push notification when published | Email manually | Automatic |
| Print by coach/unit | Complex formatting | One tap |
| Time-aware current period highlight | Can't | Yes |
| Offline access during practice | Requires data | Cached |

---

## Build Priority Within Practice Planning

### MVP (Must have at launch)
1. Create practice plan with periods
2. Add drills from library + free text to each period
3. Duplicate from template / last week
4. Publish to staff with push notification
5. Mobile view with filter by coach
6. Print to PDF (full plan)

### V2 (After beta feedback)
7. Time-aware period highlighting during practice
8. Collaborative period ownership by coordinator
9. Print by unit / by coach
10. Plan history and analytics (what drills do we run most?)

### V3 (Future)
11. Link practice periods to playbook plays
12. Link drills to game film clips (Hudl integration)
13. Auto-suggest drills based on opponent tendencies
14. Practice plan analytics across the season

---

## The Three-Feature Pitch — Revised

Now that I understand practice planning fully, here's the refined pitch:

**1. Parent Communication**
"You're already paying for a parent communication app. Ours also manages your entire program."

**2. Roster Management**
"Your roster, player cards, depth chart — all in one place, on your phone, for every coach on staff."

**3. Practice Planning**
"Build your practice plan in half the time, share it instantly with your staff, and have it on your phone on the field. Your drill library grows every week. After two seasons, switching means starting over."

**This is the holy trinity that justifies the subscription price.**

