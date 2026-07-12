# Mesh Sports — Beta Launch Checklist
_Last updated: Planning session July 2026_

The single thing standing between you and putting this in front of real coaches.
Do not add features. Complete this list and ship.

---

## 🔴 Blockers — Cannot Ship Without These

### Security
- [ ] RLS turned ON for programs table
- [ ] RLS turned ON for players table
- [ ] RLS turned ON for attendance table
- [ ] RLS turned ON for inventory table
- [ ] RLS turned ON for game_stats table
- [ ] RLS turned ON for announcements (when moved to own table)
- [ ] Verify RLS policies work correctly for each role after turning on

### Legal
- [ ] TOS page live at meshsports.co/terms
- [ ] Privacy Policy live at meshsports.co/privacy
- [ ] COPPA parental consent flow for player signups
- [ ] Coach must accept TOS on signup

### Email
- [ ] Custom SMTP configured (Resend or SendGrid)
- [ ] Auth emails come from noreply@meshsports.co
- [ ] Supabase Site URL set to https://meshsports.co
- [ ] Email confirmation links redirect correctly

### Beta Codes
- [ ] 3 beta codes generated in database
- [ ] Beta code screen functional (MESH-DEV-LOCAL bypass still works for dev)
- [ ] Each code tied to a specific coach/program name

---

## 🟡 Should Fix — High Priority

### Bugs (From Test Checklist)
- [ ] All remaining bugs from v39 test checklist resolved
- [ ] Player stat submission working end to end
- [ ] Announcement notifications working for player/parent
- [ ] No duplicate stats showing anywhere

### Core Experience
- [ ] Coach can complete full onboarding in under 15 minutes
- [ ] Player can join program and see their info in under 5 minutes
- [ ] Parent can join and see announcements in under 5 minutes
- [ ] App loads in under 3 seconds on average phone connection

---

## 🟢 Nice to Have — Post-Beta-Launch

- [ ] Basic web push notifications
- [ ] meshsports.co landing page explains what Mesh is
- [ ] Demo video or screenshots on landing page
- [ ] Feedback mechanism for beta coaches (even just an email link)

---

## Beta Coach Criteria
Choose coaches who:
- You can reach directly and who will give honest feedback
- Are running real programs with real players this season
- Will actually use it, not just say they will
- Represent different program sizes if possible
- Won't be embarrassed if something breaks (they know it's beta)

**Target:** 1 head coach you know well (control), 1-2 others for perspective

---

## What to Tell Beta Coaches
"Mesh is a coaching operations platform I'm building. It's in beta — meaning it works but it's not perfect yet. I need real coaches using it during a real season to tell me what's working and what's not. It's completely free during beta. All I ask is that you actually use it and give me feedback."

---

## Feedback Collection During Beta
Set up a simple system before you hand out codes:
- Monthly 30-minute call with each coach
- Simple form they can fill out anytime (Google Form is fine)
- Direct text/call line for urgent issues

Questions to ask every month:
1. What did you use most this month?
2. What frustrated you?
3. What do your players/parents say about it?
4. What's missing that you wish was there?
5. Would you pay for this? What would you pay?

---

## Success Criteria for Beta
After the full football season (November):
- [ ] All 3 coaches used it for at least 80% of the season
- [ ] At least 1 coach says "I'd pay for this"
- [ ] You have a clear list of the top 5 things to fix/add
- [ ] You understand which features actually get used vs. which don't
- [ ] At least 1 coach refers another coach

