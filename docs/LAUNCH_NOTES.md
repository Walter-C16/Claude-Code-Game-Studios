# Dark Olympus — Chapter 1 Vertical Slice

## Status

**Feature-complete Chapter 1 playable end-to-end.**

Built in Godot 4.6, targeting mobile (430×932 portrait), Web (HTML5), and Windows Desktop.

## What's In Chapter 1

- **Prologue** — Crashed hero from another world wakes in Sardis forest
- **Tutorial combat** — Pistol-powered poker combat against forest monsters
- **Crash rescue cutscene** — Artemis saves the unconscious protagonist
- **Artemis's House** — Exposition, the Great Root tree, the deal
- **The Tavern** — Village legend, elder's concerns, Hippolyta rumor
- **Tree Temple Blessing** — Priestess blesses the pistol with green energy ammo
- **The Mountains** — Artemis backstory (daughter of Zeus), waterfall, cave
- **Mountain combat** — Mountain beast encounter
- **Village Under Attack** — Hippolyta vs cyclops, join the fight
- **Hippolyta's Challenge** — First man ever to defeat her in single combat
- **Village Report** — Dark crystal intelligence from scouts
- **Night Siege Boss** — Gaia Spirit boss fight at the ruins
- **The Tree Temple Revelation** — Priestess reveals the three fragments of Gaia

## Systems (21/21 complete)

**Foundation**: GameStore, SettingsStore, EventBus, Localization, SaveManager, SceneManager, AudioManager
**Core**: CompanionRegistry, EnemyRegistry, CombatSystem, DialogueRunner, DeckManager
**Feature**: RomanceSocial, StoryFlow, BlessingSystem, Camp, Intimacy, Equipment, Exploration
**Alpha**: AbyssMode (roguelike endgame), Gallery, Achievements

## Known Placeholders

- **Art**: Companion portraits and backgrounds are colored placeholders. Use `docs/art-generation-guide.md` with ComfyUI to generate real assets.
- **Audio**: All BGM/SFX are 1-second silent .ogg stubs. Replace with real tracks.
- **Localization**: English only. Spanish + Japanese localization would need translator pass.

## Build Targets

- **Windows Desktop** (primary) — see `src/export_presets.cfg.template`
- **Web HTML5** — playable in browser via itch.io embed
- **Android** (future) — export preset not yet configured

## Test Coverage

- **641 automated tests** covering all gameplay formulas, save/load, state machines
- CI: GitHub Actions runs tests on every push to main
- All tests passing as of launch

## Known Issues

- Audio files are silent placeholders (no actual music/SFX)
- Companion portraits are placeholder colored rects
- Intimacy CG images are placeholder colored rects
- Tests produce 295 orphan warnings (tween cleanup — non-blocking)

## Next Steps (Post-Launch)

- Replace placeholder art via ComfyUI per `art-generation-guide.md`
- Generate BGM and SFX (Suno / Udio / commissioned)
- External playtesting
- Balance tuning based on playtest feedback
- Chapter 2 content (Thebes, Atenea, second Gaia fragment)
- Chapter 3 content (Underworld, Nyx, final fragment)
- Spanish localization

## Running the Game

1. Install Godot 4.6
2. Open `src/project.godot`
3. Press F5 to run
4. Click **New Game**

## Running Tests

```bash
cd src
godot --headless -d -s addons/gdunit4/bin/GdUnitCmdTool.gd -a tests/ --ignoreHeadlessMode
```
