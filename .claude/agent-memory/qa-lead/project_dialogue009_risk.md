---
name: DIALOGUE-009 AccessKit Risk
description: DIALOGUE-009 (Accessibility/AccessKit) has HIGH engine knowledge risk — post-LLM-cutoff API in Godot 4.5+, requires real device test and lead sign-off before marking Done.
type: project
---

DIALOGUE-009 (Accessibility — AccessKit Screen Reader Support) is classified Integration but elevated to BLOCKING for the Done gate.

AccessKit was introduced in Godot 4.5 (HIGH risk per VERSION.md). The LLM's training data predates this. Headless automated testing cannot verify screen reader announcements.

Required before Done:
- Real device test with TalkBack (Android) or VoiceOver (iOS) enabled
- All 5 manual checklist items completed and documented
- Lead programmer or accessibility lead sign-off in production/qa/evidence/dialogue-accessibility.md

**Why:** Standard Integration test path (headless GdUnit4) cannot exercise AccessKit. Marking Done without device verification would leave the accessibility feature unvalidated. This was flagged in ADR-0008 as MEDIUM engine knowledge risk at story authoring time.

**How to apply:** Do not accept DIALOGUE-009 as Done without the evidence file and lead sign-off. Flag it as blocked at sprint review if evidence is missing.
