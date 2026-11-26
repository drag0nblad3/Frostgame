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
  Only `GameController` (with its helper `TurnFlow`) mutates `GameState`; it emits `GameEvent`s.
- `src/view/` — Godot nodes. Reads state, animates events, turns input into controller calls.
  Never changes `GameState` directly.
- Dependencies point view → core, never core → view.

## Table model
- Positions are `Vector2` **inches** on the table, origin bottom-left; 36"×36" default board.
- Bases are 1" round (`Figure.BASE_RADIUS = 0.5`). Contact = centres within 1.25" (`Contact`).
- Movement searches a 0.5" lattice (`MoveGrid`/`MovePlanner`, Dijkstra, rough terrain ×2).
- Terrain pieces are axis-aligned rectangles with a kind (`data/terrain.json`): blocks sight,
  blocks movement, cover (none/light/heavy), move multiplier, model height.
- One exposed standing surface per XY, including negative ground profiles, authored ramps, stairs and elevated tops. Overlapping floors and mid-wall standing require a separate surface graph.

## File map
| Path | What |
|---|---|
| `src/core/util/` | `Dice` (seedable d20, win odds), `MinHeap`, `JsonFile`, `Geom` (segment/rect clipping, distances) |
| `src/core/board/` | `TerrainKind`/`TerrainDb`, `TerrainPiece`, `Board` (size, pieces, cached standability and move cost, bot distance-field cache), `BoardLoader` (`data/boards/*.json`) |
| `src/core/figures/` | `WeaponDef`, `FigureDef` (stat line, role → phase), `FigureDb` (`data/figures.json`, `data/weapons.json`), `Figure` (live: position, health, activation bookkeeping, crossbow loaded) |
| `src/core/rules/contact.gd` | Base contact, enemies in contact, in-combat |
| `src/core/rules/movement/` | `MoveGrid` (open nodes, contact stops a move, step cost), `MovePlanner` (reach, distance field), `MoveReach` (costs, path), `MoveRules` (allowance: full then half; no moving out of combat) |
| `src/core/rules/combat/` | `LineOfSight` (blocking, cover at target, intervening), `Shooting` (range, legality, cover mods, resolve), `Melee` (support, opposed rolls, ties), `Damage` (total − Armour, natural 20 doubles) |
| `src/core/rules/turn/` | `Phase` (wizard → apprentice → soldier), `Initiative` (d20, reroll ties for first) |
| `src/core/state/` | `GameState`, `GameController` (actions: activate, move, fight, shoot, reload, end), `TurnFlow` (turns, phases, player order, victory), `GameEvent`, `ScenarioLoader` (`data/scenarios/*.json`) |
| `src/core/ai/` | `Bot` (plays one activation via the controller), `BotTargets` (charge spots, shooting spots, advance node) |
| `src/core/explain/` | `Explainer` (event → log line) |
| `src/view/` | `TableSpace` (inches ↔ world), `BoardView` (table + terrain blocks), `FigureView` (placeholder model + nameplate), `CameraRig` (orbit/pan/zoom, mouse + touch) |
| `src/view/battle/` | `battle_scene.gd` (composition root: scenario, controller, bot stepping), `EventPlayer` (event queue → tweens, log lines) |
| `src/view/hud/` | `BattleHud` (status, log, Step / Auto / New game) |
| `data/` | `figures.json`, `weapons.json`, `terrain.json`, `boards/*.json`, `scenarios/*.json` |
| `tests/` | `run_tests.gd` runner, `test_case.gd` base + fixtures, `LoadedDice` (scripted d20s), `unit/test_*.gd` (incl. `test_sim.gd`: whole bot-vs-bot games) |
| `tools/capture.gd` | Render the battle to PNG after N bot activations |
| `docs/` | `architecture.md`, `rules-coverage.md`, `PLANNING.md` |

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
