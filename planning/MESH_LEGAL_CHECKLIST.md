# Mesh Sports — Legal & Compliance Checklist
_Last updated: Planning session July 2026_

---

## ⚠️ Do Not Ship Beta Without These

### COPPA (Children's Online Privacy Protection Act)
Federal law. Players are minors. Non-negotiable.

- [ ] Privacy Policy explicitly addresses collection of data from users under 13
- [ ] Parental consent flow: player under 18 cannot complete signup without parent email
- [ ] Parent receives email: "Your child [name] is signing up for Mesh at [school]. Click to approve."
- [ ] Player account is inactive until parent approves
- [ ] What data we collect from minors is listed explicitly in Privacy Policy
- [ ] Minors cannot be opted into marketing communications
- [ ] Data deletion: parent can request deletion of their child's data

### Terms of Service
- [ ] TOS page live at meshsports.co/terms
- [ ] Coach must accept TOS on signup (checkbox, logged in DB)
- [ ] Beta agreement language: acknowledges product is in development
- [ ] Data ownership clause: coach owns their program data
- [ ] Data portability clause: coach can export their data at any time
- [ ] Account termination clause: what happens to data when they leave

### Privacy Policy
- [ ] Privacy Policy live at meshsports.co/privacy
- [ ] What data is collected (roster, contact info, stats, usage)
- [ ] How data is used (operating the service, no selling to third parties)
- [ ] Who data is shared with (Supabase, Stripe, Expo — list all processors)
- [ ] Data retention policy (how long we keep data after account deletion)
- [ ] COPPA section (minors)
- [ ] Contact email for privacy requests

### Recommended: Get a lawyer to review both documents
This is $200-500 and absolutely worth it before real coaches put real student data in.

---

## Important But Can Wait Until Post-Beta

### FERPA (Family Educational Rights and Privacy Act)
Applies when schools/districts buy Mesh institutionally.
- Educational records protection
- Requires a data processing agreement with schools
- Schools are responsible for FERPA compliance, but Mesh needs to support it
- Action: When you get your first school-level customer, get a FERPA DPA template

### Data Breach Response Plan
- What do you do if Supabase gets breached?
- Who do you notify? (affected users, potentially state attorney general)
- How quickly? (most states require 72 hours)
- Action: Write a simple 1-page breach response plan before launch

### Business Entity
- Mesh Sports LLC is registered with Idaho SOS ✅
- Make sure all revenue goes through the LLC
- Get a business bank account if you don't have one
- Separate personal and business finances from day one

---

## Trademark
- USPTO application filed Feb 2025 (Class 041, Mesh Studios LLC)
- Status: Live application
- Action: Consult trademark attorney before formal registration
- Note: Different entity (Mesh Studios LLC vs Mesh Sports LLC) — clarify this

---

## Data Architecture Decisions With Legal Implications

### What Coaches Own
- Their program configuration
- Their roster (names, contact info, jersey numbers)
- Their announcements and schedule
- Their stats and attendance records

### What Mesh Owns
- Platform infrastructure
- Aggregate anonymized analytics (can use to improve product)
- Usage data (cannot sell or share)

### Data Deletion Flow
When a coach deletes their account:
1. Give them 30 days to export data
2. After 30 days, hard delete all program data
3. Auth record deleted from Supabase
4. Exception: anything legally required to retain

### Student Data Specifically
- Player roster data is sensitive — treat it like PHI
- Never use student data for advertising or marketing
- Never share with third parties without explicit consent
- Supabase stores data in US (important for some schools)

