# Dark Olympus — Claude Code Game Studios

Narrative RPG / dating sim / poker combat game. Greek mythology setting with fallen gods.
Migrated from React Native to Godot 4.6 — see `docs/GAME_DESIGN_DOCUMENT.md` for full spec.

## Technology Stack

- **Engine**: Godot 4.6
- **Language**: GDScript
- **Build System**: SCons (engine), Godot Export Templates
- **Asset Pipeline**: Godot Import System + custom resource pipeline
- **Version Control**: Git
- **Viewport**: 430×932 (portrait mobile)
- **Renderer**: Mobile
- **Platforms**: Android, iOS, Web (HTML5)

> **IMPORTANT**: Read `docs/GAME_DESIGN_DOCUMENT.md` before implementing anything.
> It contains the complete game design, all systems, story, migration status, and TODO list.
> The RN source at `C:\Users\walte\Documents\dark-olympus-rn` has the original TypeScript
> implementations to reference when porting systems.

## Project Structure

@.claude/docs/directory-structure.md

## Engine Version Reference

@docs/engine-reference/godot/VERSION.md

## Technical Preferences

@.claude/docs/technical-preferences.md

## Coordination Rules

@.claude/docs/coordination-rules.md

## Collaboration Protocol

**User-driven collaboration, not autonomous execution.**
Every task follows: **Question -> Options -> Decision -> Draft -> Approval**

- Agents MUST ask "May I write this to [filepath]?" before using Write/Edit tools
- Agents MUST show drafts or summaries before requesting approval
- Multi-file changes require explicit approval for the full changeset
- No commits without user instruction

See `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md` for full protocol and examples.

> **First session?** If the project has no engine configured and no game concept,
> run `/start` to begin the guided onboarding flow.

## Coding Standards

@.claude/docs/coding-standards.md

## Context Management

@.claude/docs/context-management.md
