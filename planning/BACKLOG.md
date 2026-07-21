# Mesh — Backlog / Parked Items
_Forward-looking items pulled out of the old session logs so they don't get lost.
Historical session-by-session notes were retired; git history is the record of what shipped._

---

## ⛔ Compliance gate — BUILD BEFORE ONBOARDING ANY UNDER-13 PLAYER (post-beta)
**Verifiable parental-consent gate (COPPA).** The live TOS + Privacy Policy state the beta is
**13+ only** and that we do **not** collect under-13 data. That is the ONLY thing keeping us out
of COPPA's verifiable-consent requirement right now — we're compliant by *not collecting*, not by
having a mechanism.

Before the app enables under-13 use (e.g. middle-school feeder programs), you MUST build:
- A real **verifiable parental-consent flow** (COPPA §6502) that runs BEFORE any personal info is
  collected from a child under 13 — coach-entered roster data counts as collection.
- COPPA **direct-notice** text to parents (what we collect, how it's used, their right to
  review/refuse/delete), lawyer-reviewed alongside the flow.
- Then update Privacy §5 / Terms §3 to remove the "13+ only during beta" limitation.

The Privacy Policy already *promises* this, so shipping under-13 support without it would
contradict our own live policy. Deferred deliberately by the founder; **not beta-blocking.**
(See also [MESH_LEGAL_CHECKLIST.md](MESH_LEGAL_CHECKLIST.md).)

---

## 📝 Post-beta feature ideas (not blocking)

### Equipment / QR
- **Batch / "print all tags."** QR tags print one item at a time today
  (`printItemTag` → single-label overlay → `window.print()`). A coach tagging 60 helmets prints 60
  times. Add a batch print sheet (all items, or all in a category).
- **"Bring your own QR" / attach an existing code to an item.** Today it's Mesh-generates-only:
  `generateItemId()` auto-assigns `MESH-<CAT>-###`, the ID isn't editable, and the scanner rejects
  anything that isn't a known Mesh ID. Coaches with already-barcoded gear can't register those
  codes. Would need an editable/secondary code field on the item + a scanner lookup that matches
  either the Mesh ID or a stored external code. (Intentional current behavior, not a bug.)

---

## 🌐 Marketing website
See [WEBSITE_CLEANUP.md](WEBSITE_CLEANUP.md) for the full meshsports.co improvement plan
(screenshots, park Playbook, verify beta lead capture, safety differentiator, etc.).

---

## 🔭 Guides / walkthroughs — deepen later
The feature-guide system (v40.17–v40.20) auto-launches a spotlight walkthrough per tab. The
Practice guide is the deep exemplar (opens real modals, spotlights each control). The other guides
are solid first passes — revisit any that feel shallow and give them the same depth/targeting.
