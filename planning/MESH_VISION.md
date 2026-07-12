# Mesh Sports — Master Vision Document
_Last updated: Planning session July 2026_

---

## The One-Line Pitch
**"The parent communication app that actually works for coaches, not just parents."**

## The Problem
High school football coaches are juggling 5+ disconnected apps:
- GroupMe or Remind for parent communication
- Google Sheets for roster management
- Text message group chats for staff communication
- Separate apps for stats, schedules, and logistics

None of these tools were built for coaches. They were built for consumers and adapted. Coaches use them because there's nothing better — not because they love them.

## The Solution
Mesh replaces all of them with one platform built specifically for coaching operations.

**The hook:** A parent communication app that coaches actually benefit from — not just another place they have to post something.

**The retention:** Everything else a program needs lives in the same place. Roster management, depth charts, stats, schedules, attendance. Once a coach is in, switching costs become high.

## The Vision
The operating system for a high school sports program. Start with football. Grow to every sport. Start with individual coaches. Grow to schools and districts.

---

## Users & Roles

### Head Coach (The Buyer)
- Creates and owns the program
- Sets up roster, invites staff, sends parent invitations
- Does clerical/admin work primarily on desktop
- Monday morning use case: practice planning + sending team announcements
- **Must be able to go from signup → first parent announcement in under 10 minutes**

### Assistant Coaches (Daily Users)
- Use the app daily during season
- Log attendance, log stats, take player notes
- Primarily on mobile during practice and games
- Don't need to configure anything — just use what HC sets up

### Parents (Communication Audience)
- Almost exclusively on mobile
- Want: schedule logistics + coach announcements in one place
- Primary value: knowing what's happening with their kid's program
- **Word of mouth engine** — happy parents tell other parents, who tell coaches

### Players (Engagement Users)
- Exclusively on mobile
- Will use it voluntarily for: stats, communication from coaches
- Everything else will be lightly used — don't over-engineer the player experience
- Voluntary engagement if stats are good; mandatory if it's the only comms channel

---

## The Market

### Individual Coaches (B2C Entry Point)
- Head coaches pay monthly
- Acquired through: Twitter/X coaching communities, direct outreach to coaches and ADs, coaching clinics and state association conferences
- Price sensitive but will pay for real value
- **Key insight:** Coaches are already paying for 5 apps. Mesh can be cheaper than their current stack combined.

### Schools (B2B Growth)
- AD or head coach brings it to the school
- Multiple programs, multiple coaches under one account
- Higher contract value, longer sales cycle

### Districts (B2B Scale — The Real Money)
- One sale = every school, every sport in a district
- Could be 20-50 programs per district
- Requires more formal procurement process (IT, FERPA, SSO)
- Long-term target, not near-term focus

---

## Business Model

### Pricing Philosophy
- Beta is free (current phase)
- Launch with paid tiers immediately — no permanent free tier
- Coaches who sign up during beta convert to paid at launch

### Tier Structure (Draft)
| Tier | Price | Who It's For |
|------|-------|-------------|
| Coach | ~$29-49/month | Single coach, single program |
| Program | ~$79-99/month | Full staff, multiple coaches |
| School | Custom | Multiple programs, AD admin |
| District | Custom | Every school, every sport |

### Revenue Targets (Rough)
- 10 paying coaches @ $39/mo = $390/mo (proof of concept)
- 50 paying coaches @ $39/mo = $1,950/mo (ramen profitable)
- 5 schools @ $299/mo = $1,495/mo (meaningful revenue)
- 1 district @ $2,000/mo = real business

### Seasonality
- Casual programs: May–November (summer workouts through end of season)
- Serious programs: Year-round
- **Best time to sell:** Preseason (April–July) when coaches are planning
- **Best time to retain:** During season when they can't imagine switching

---

## Product Personality

### Feel
- Guided setup with smart defaults — coaches don't configure, they just use
- Minimal friction to first value — under 10 minutes from signup to useful
- Personalized — each program feels like THEIR app (team colors, logo, name)
- Powerful but not overwhelming — features are discoverable, not shoved in their face

### Design Principles
1. **Mobile first, always** — if it doesn't work great on a phone at a Friday night game, it doesn't ship
2. **Coach's time is precious** — every interaction should be faster than the alternative
3. **It's their app** — team colors, logos, customization create ownership
4. **Progressive disclosure** — show the simple thing first, reveal depth as needed

---

## The Three-Feature Pitch (The Core)

These three features justify the subscription. Everything else is supporting cast.

**1. Parent Communication**
"You're already paying for a parent communication app. Ours also manages your entire program."
Hook: Replaces GroupMe/ParentSquare. Value add: it's built for the coach, not just the parent.

**2. Roster Management**
"Your roster, player cards, depth chart — all in one place, on every coach's phone."
Hook: Replaces spreadsheets. Includes player profiles, contacts, depth chart.

**3. Practice Planning**
"Build your practice plan in half the time. Share it instantly. Have it on your phone on the field."
Hook: Replaces Google Sheets + printing. Drill library compounds over time — switching costs grow.

See MESH_PRACTICE_PLANNING.md for full practice planning spec.

---

## Feature Priority (What Actually Matters)

### Tier 1 — Why They Sign Up (The Hook)
- Parent communication (announcements with push notifications)
- Roster and contact management
- **Practice planning — this is the differentiator, not an afterthought**

### Tier 2 — Why They Stay (The Depth)
- Schedule management visible to all roles
- Depth chart
- Assistant coach tools (attendance, player notes)
- Drill library (part of practice planning, compounds over time)

### Tier 3 — Why They Evangelize (The Wow)
- MaxPreps integration (saves real time)
- Stats logging and approval
- Multi-coach collaboration on practice plans
- Print-ready practice plans

### Tier 4 — Future
- Play designer (the big one — native play drawing)
- Performance/training tracking
- Recruiting tools
- Video integration
- District/school admin dashboard

---

## Critical Things That Can't Be Skipped

### Legal
- **COPPA compliance** — players are minors, parental consent required for data collection
- **FERPA awareness** — student data, school records, need to understand implications
- **Data ownership policy** — who owns roster data when a coach leaves?
- **Data export** — coaches must be able to export their data (trust issue)
- TOS and Privacy Policy live before beta codes go out

### Technical Non-Negotiables
- **Offline support** — games happen in stadiums with bad cell service
- **Real push notifications** — web push for PWA, native push for mobile app
- **Multi-program data model** — design for it from day one even if UI doesn't expose it yet
- **Roster import** — CSV and Hudl export, coaches won't type 80 names
- **RLS on** — before any real coach uses it

### Acquisition
- How a new coach finds Mesh and gets access is currently unsolved
- Needs a self-serve signup flow that works without Nick's involvement
- Marketing site at meshsports.co needs to do the selling

---

## What Mesh Is NOT (Equally Important)

- Not a video platform (Hudl owns that)
- Not a recruiting platform (yet)
- Not a game-day live scoring app
- Not a social network for athletes
- Not trying to be everything on day one

---

## The Path

### Phase 1: Beta (Now → August 2026)
Polish current single-HTML app for 3 coaches during football season.
Goal: Prove the core loop. Get real feedback. Understand what matters in practice vs. theory.

### Phase 2: Real Build (August → December 2026)
Build proper architecture in parallel while beta runs:
- Expo mobile app (players + parents)
- Next.js web dashboard (coaches)
- Same Supabase backend

### Phase 3: Launch (Spring 2027)
Launch real app informed by full season of beta feedback.
Begin paid conversion. Expand coach network.

### Phase 4: Scale (2027+)
School and district sales. Multi-sport. Marketing investment.
Consider reinforcements (hire or co-founder) when solo can't keep up.

---

## Nick's North Star
_"I want to build this myself until I can't. When I can't, I bring in reinforcements."_

This is a business Nick owns and controls. Not a VC-funded rocket ship with a 5-year exit plan. A real product that solves a real problem for real coaches, built sustainably, that could become Nick's primary income.

