# Frostgame — agent guide

Frostgrave (2nd edition) skirmish simulator for Android phones, with automated rules.
Godot 4.5+, typed GDScript. Battle first; campaign layer (experience, levels, base, treasure) later.
Stargrave is planned as a second content set on the same engine.

## Working efficiently (read this first)
- **Don't read the whole repo.** Use the file map below, open only the files a change touches.
- One class per file, `class_name` = PascalCase of the file name. Target < 150 lines per file;
  split before a file passes ~200.
- New rule = new file under `src/core/rules/<area>/` + a test in `tests/unit/test_<area>.gd`
  + a line in `docs/rules-coverage.md`. Don't grow existing rule files sideways.
- Expansion and scenario rules live under `src/core/scenarios/<set>/` and reach core rules
  through `RuleHooks`. Combat, movement, sight, treasure and turn rules already do; magic,
  equipment and creature files still call Red King classes. Don't add new direct calls, and
  move old ones to hooks when you touch them.
- Bot speed is guarded by `test_bot_budget.gd`. If a change needs more movement-search work,
  raise the budget on purpose and say why.
- Content (figures, weapons, terrain, boards, scenarios) is JSON in `data/`, never hard-coded.
- Prefer `Edit` over rewriting files. Keep comments short; `##` doc comment on each class.

## Rules source and IP
- Rules were coded from memory of Frostgrave 2e; **every stat line and rule is unverified**
  until checked against the book. Figure entries carry `"verify": true` until checked.
- Mark interpretations with `# TODO(rules): ...` and list them in `docs/rules-coverage.md`.
- Never paste rulebook text, spell descriptions or flavour. Log/explanation text is our own words.
- Personal project: the Frostgrave name and rules belong to Osprey Games / Joseph A. McCullough.

## Layers (strict)
- `src/core/` — pure rules. `RefCounted` only, **no Nodes, no rendering, no input**.
  Only `GameController` and the helpers it owns (`TurnFlow`, `Controller*`, `*Actions`) mutate
  `GameState`; it emits `GameEvent`s.
- `src/view/` — Godot nodes. Reads state, animates events, turns input into controller calls.
  Never changes `GameState` directly. Never read state while `BotRunner.busy()` (a bot is
  playing on a worker thread); `EventPlayer.idle()` is false then.
- Dependencies point view → core, never core → view.

## Table model
- Positions are `Vector2` **inches** on the table, origin bottom-left; 36"×36" default board.
- Bases are 1" round (`Figure.BASE_RADIUS = 0.5`). Contact = centres within 1.25" (`Contact`).
- Movement searches a 0.5" lattice (`MoveGrid`/`MovePlanner`, Dijkstra, rough terrain ×2).
- Terrain pieces are axis-aligned rectangles with a kind (`data/terrain.json`): blocks sight,
  blocks movement, cover (none/light/heavy), move multiplier, model height.
- Boards support either exposed standing profiles (including ramps, stairs and negative ground) or explicit overlapping floor surfaces, solids and climb links. Both use the shared BattleScene, action controller and route-search engine. Only geometry providers and their typed route nodes differ; gameplay rules should be shared.

## File map
| Path | What |
|---|---|
| `src/core/util/` | `Dice` (seedable d20), `MinHeap`, `JsonFile`, `Geom`, `EventDeck`, `ContentProfile` (which expansions a save allows) |
| `src/core/board/` | `TerrainKind`/`TerrainDb`, `TerrainPiece`, `Board` (pieces, flat lattice caches, distance-field cache), `BoardLoader`, `BoardTopology` (wrapped/linked edges), `BattleBoundary`, floor surfaces |
| `src/core/figures/` | `WeaponDef`, `FigureDef`, `FigureDb`, `Figure` (live state), magic equipment, power pools, `WarbandDraft` |
| `src/core/rules/` | Pure rules by area: `movement/` (`MoveGrid`, `MovePlanner`, `MoveRules`, `RunForIt`), `combat/` (`LineOfSight`, `Shooting`, `Melee`, `Damage`, displacement), `magic/` (`SpellActions` and its helpers `SpellAvailability`, `SpellResolution`, `SpellEffects`, `SpellUpkeep`; summons, terrain, counter and word magic), `equipment/` (gear, potions, weapons), `treasure/`, `creatures/`, `turn/` |
| `src/core/rules/rule_hooks.gd` | `RuleHooks`: named extension points. Core rules ask hooks; expansions register (see `docs/architecture.md`) |
| `src/core/scenarios/` | Core scenario rules (columns, genie, null, objectives, sites); `red_king/` holds the Red King expansion and `RedKingHooks` |
| `src/core/layered/` | Multi-floor boards: movement, leaps, bridges, magic, loot, checkpoints |
| `src/core/state/` | `GameState`, `GameController` (public API; bodies in `ControllerMovement`, `ControllerCombat`, `ControllerActivation`), `TurnFlow`, `GameEvent`, `ScenarioLoader`, battle snapshots |
| `src/core/ai/` | `Bot` (one activation via the controller), `BotTargets`, treasure/magic/creature/scenario bots |
| `src/core/campaign/` | Between-game campaign: progress, inventory, injuries, base, rituals, Red King campaign |
| `src/core/explain/` | `Explainer` (event → log line) |
| `src/view/` | `TableSpace`, `BoardView`, `FigureView`, `CameraRig`, procedural miniatures (`MiniatureFactory`, `MiniatureBatch`, `MiniatureSurface`) and scenery |
| `src/view/battle/` | `BattleScene` (composition root; campaign and training flow in `BattleCampaignFlow`, `BattleTraining`), `BotRunner` (bot on a worker thread), `EventPlayer`, `BattleInput` (+ `BattleInputMenu`, `…Activation`, `…Preview`, `…ActionPreview`, `…ReactionPreview`, `…Actions`, `…SpellActions`, `…Tap`) |
| `src/view/hud/` | `BattleHud` (labels from `data/action_labels.json`), dialogs, panels, campaign screens |
| `data/` | `figures.json`, `weapons.json`, `terrain.json`, `action_labels.json`, `boards/*.json`, `scenarios/*.json` |
| `tests/` | `run_tests.gd` runner, `test_case.gd` base + fixtures, `LoadedDice`, `unit/test_*.gd` (incl. `test_sim.gd` whole bot games, `test_bot_budget.gd` bot speed budget), `*_smoke.gd` scene smoke runs |
| `tools/` | `capture.gd` and friends: render scenes to PNG |
| `docs/` | `architecture.md`, `rules-coverage.md`, `PLANNING.md`, expansion notes |

## Commands
```sh
godot --headless --import                      # once per fresh clone (class cache)
godot --headless -s tests/run_tests.gd         # all tests; append `-- melee` to filter
godot --headless --quit-after 60               # smoke-run main scene, catches script errors
xvfb-run -a godot --rendering-method gl_compatibility --resolution 1280x720 \
  -s tools/capture.gd -- /tmp/shot.png 20      # screenshot after 20 activations
```
Run tests + smoke run before every commit. CI runs both (`.github/workflows/ci.yml`).
No Android APK build unless the user asks.

## Conventions
- Randomness only via the controller's `Dice` (seeded games replay identically).
- Bot code reads state and calls the controller; it never edits figures directly.
- Use Godot 4.5 APIs; no C#.
