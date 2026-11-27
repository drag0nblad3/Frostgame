# Architecture

```
data/*.json ──► loaders ──► GameState ◄── GameController ◄── Bot / (later) player input
                                 │              │
                                 │         GameEvent signal
                                 ▼              ▼
                           view reads ◄── EventPlayer (tweens, log) ── BattleHud
```

- **Core (`src/core/`)** is plain `RefCounted` code with no scene tree, so it runs headless in
  tests and could run on a server later. `GameController` is the single writer of
  `GameState`; `TurnFlow` handles turn/phase/player order and victory on its behalf.
- **Events.** Every change is announced as a `GameEvent` (`turn_start`, `phase`, `activate`,
  `move`, `fight`, `shoot`, `reload`, `damage`, `out_of_action`, `end_activation`,
  `game_over`). The view queues them and animates one at a time, so rules resolve instantly
  while the table catches up.
- **Dice.** One seeded `Dice` per game. Tests use `LoadedDice` to script d20 results.
- **Movement.** Free movement in inches, searched on a 0.5" lattice with Dijkstra. Terrain
  answers on the quarter-inch lattice are cached on the `Board`; the bot's distance fields
  are cached per target node.
- **Bot.** `Bot.play_activation` picks a figure and plays it out through controller calls
  only. `BotTargets` holds the read-only choices (charge spots, shooting spots, advancing).
  In the battle scene, `BotRunner` plays the activation on a `WorkerThreadPool` task and
  buffers its events until it finishes, so the table keeps drawing while the bot thinks.

## Rule hooks
Core rules (`src/core/rules/`) don't name expansion classes. They ask `RuleHooks`, and each
content set registers callables in one installer (`RedKingHooks.install()`, listed in
`RuleHooks._install()`). Hooks run in registration order.

| Hook | Arguments | Asked with | Meaning |
|---|---|---|---|
| `objective_figure` | figure | `any` | An objective, not a combatant: no fighting, support or ordinary shots |
| `no_support` | figure | `any` | Never lends fight support |
| `fight_bonus` | figure, enemy | `total` | Extra Fight against that enemy |
| `melee_armour` | attacker, target | `first` | Armour to use instead of the target's own |
| `melee_damage_bonus` | winner, loser | `total` | Extra melee damage |
| `range` | shooter, target | `first` | Range override (float), e.g. across reality cracks |
| `shoot_modifier` | shooter | `total` | Shooting roll modifier |
| `sight` | board, from, to, observer | `first` | `LineOfSight.Result` override |
| `treasure_no_slowdown` | figure | `any` | Carrying treasure costs no movement |
| `treasure_light_slowdown` | figure | `any` | Carrying treasure costs 1" instead of half Move |
| `treasure_guarded` | state, token | `any` | Token can't be picked up yet |
| `cannot_carry_treasure` | state, figure | `any` | Figure may never pick up treasure |
| `equipment_command` | controller, key, args | `first` | Execute expansion-owned equipment choice; null means unhandled |
| `group_blocked` | state, figure | `any` | Figure can't join a group activation |
| `forced_move_void` | controller, figure, from, to | `any` | A push was resolved by a void (figure fell or stopped) |
| `forced_move_blocked` | controller, figure, to | `any` | A forced move was resolved by a hazard at the destination |
| `forced_contact` | controller, figure, from, to | `run` | Side effects of a forced move's path |
| `forced_path_void` | controller, point | `any` | A forced path may end over this void |

Combat, movement, sight, treasure and turn rules use hooks only. These still call Red King
classes directly and should move to hooks when next touched: `rules/magic/`, `rules/equipment/`,
`rules/creatures/creature_effects.gd`, `rules/combat/forced_relocation.gd`,
`rules/treasure/treasure_actions.gd`, `rules/movement/run_for_it.gd`, the `Controller*`
helpers and the campaign code.

## Activation model (current)
Each figure gets two actions per activation. At most one is a non-move action (fight, shoot,
reload). A second move is at half Move. Figures in contact with an enemy can't move away.
Phases run wizard → apprentice → soldier; within a phase the initiative winner activates all
of their figures for that phase, then the next player.


## Shared structural foundations

- `BattleAction` dispatches common legal commands for bots and players; attack previews
  use the same situational defence query as shooting resolution. Migrate additional
  movement, spell, equipment and expansion decisions incrementally, leaving legality
  in the controller. Previewing must never consume actions or dice.
- `BattleEquipmentAction` exposes stable equipment commands and shared point
  queries for both geometry providers. Point payloads must be Vector2 on ordinary
  boards or Vector3i (including support index) on layered boards; invalid geometry
  is rejected before consumption. Equipment commands are recorded for replay.
  Expansion-owned actions are dispatched by the `equipment_command` hook.
- `BattlePresentation` classifies action/consequence/movement/context beats;
  `BattleCameraDirector` optionally frames visible participants and yields to manual
  camera input. The command screen exposes Normal, Fast and Cinematic playback.
  Animation remains separate from rule state; true overlapping sequences and instant
  skip require further work.
- `BattleSpace` is the shared geometry facade. Existing route providers remain
  underneath it; migrate spatial call sites without changing scenario overrides.
- `TerrainAssembly` expands reusable local rectangular kits in order, with optional
  integer `quarter_turns` about the local origin before translation. Entrances and ramp
  profiles rotate with the rectangles. Haunted Houses is the initial migrated board.
- `FloorAssembly` expands local multi-floor kits into the same canonical layout
  consumed by movement, line of sight, scenario logic, rendering and checkpoints.
  Author `floor_kits` as named dictionaries of surfaces, solids, links, climbs and
  optional null regions. Instantiate with `floor_assemblies` entries containing
  `kit`, `origin`, required `prefix`, optional `quarter_turns` and optional
  `elevation`. Local surface and climb IDs are prefixed; external supports
  (e.g. street) retain their IDs. Link endpoints transform with the geometry.
  An empty prefix preserves the original IDs when migrating an authored map.
  Keep scenario-level metadata (exit/spawn surfaces, tower region) in the base
  floor layout; explicit cross-instance connections also belong there.
  Static solids are rendered by floor artwork; temporary/dynamic walls continue
  to use TerrainPiece and their existing rules. Rotations are quarter turns only.
  Silent Tower and the two layered prototypes use this format.
- `ExpeditionStage` derives the campaign stage from save data. A separate per-slot
  `CampaignBattleCheckpoint` is written at safe turn/phase boundaries and resumed
  explicitly through Battle Commands. Manual saves are unaffected; existing campaign
  fingerprint and content-profile validation also apply to automatic recovery. It
  is not a checkpoint during deployment or a pending roll.
- `WorkshopUI` supplies shared command buttons, section cards and stat cards. Other
  dossier, item and spell components should migrate as touched.
- `BattleRecord` stores accepted commands, RNG boundaries and event ranges. The
  checkpoint history is backward-compatible with saves lacking command records.
  `BattleReplay.verify` re-executes supported commands from a compatible checkpoint
  and detects missing history, unsupported commands, RNG and event divergence.
  It is an audit/testing facility, not a complete player-facing replay viewer.
  Expansion-specific decisions and other unrecorded transitions still need migration.


### Spell command boundary

`BattleSpellAction` accepts plain payloads for placement, displacement,
treasure spells, bridge endpoints, counter choices and cast/resist reactions.
The same command selects the existing geometry-specific validator from the
board, and rejects incorrectly typed or out-of-range floor indices before
spending resources. Input and the bot use this boundary; targeted spells
retain the existing `BattleAction` path. Accepted decisions can be replayed
from a safe checkpoint. Intermediate Shatterstar declarations and some
special expansion choices still need explicit recording; this is not yet a
complete replay of arbitrary battles.


### Event presentation and turn review

`BattlePresentation.batch_size` permits up to four consecutive independent
damage, healing or magic-impact events on distinct figures to animate
together. All other event types and repeated figure IDs are barriers.
`EventPlayer` tracks every outstanding animation tween before it permits
the next beat or unlocks input; it combines outcome text for each batch.
Damage and new healing events carry recorded remaining Health for the
corresponding health bar update.

The Battle Journal includes a read-only timeline with event stepping,
turn jumps, scrubbing and timed playback. The scene builds its text from
recorded events only when no bot or animation is active; otherwise the
recent journal remains accessible. It does not replay 3D positions, reroll
dice, or change game state. Historical labels may reflect a figure's
current name or allegiance; older healing events lack event-time Health.


### Historical battlefield frames

Interactive battles opt in to `BattleFrame`, a bounded presentation history
of the latest 256 completed action boundaries, plus idle scene boundaries.
Each frame preserves positions, surface IDs, heights, Health, active figure,
ground treasure, terrain footprints and floor outlines. The data is plain
and optional in existing version-one saves; older saves still load.
Headless simulations and deterministic replay verification do not capture
frames unless explicitly enabled. There is no second simulation or RNG use.

Journal review associates an event with the latest frame at or before that
event. A frame can be missing for old events, or represent the preceding
completed action rather than a mid-action instant. The tactical map labels
this distinction and permits floor filtering. It is a schematic, not a
full historical 3D scene: solid volumes, boundary effects and moving props
are not reconstructed in detail. Existing event text remains available
when no frame exists.


### Expansion command and lifecycle boundaries

`BattleScenarioAction` records explicit choices with plain payloads and
dispatches the `scenario_command` hook. Red King implements exchange,
sinkhole, veil, memory, ring switching/escape, central escape, convergence,
hunt placement, hill seams and shifted ruins in `RedKingCommands`.
Bot ring travel, magical shortcuts and boosted movement use recorded
commands too. Specific treasure drops retain the selected token in the
record, with legacy commands defaulting to the carried primary treasure.

`potion_source_allowed` and `potion_consume` are optional hooks for
expansion-provided potion sources and outcomes. A null result means the
core uses its normal behavior; false is an explicit restriction or failed
special consumption. `RedKingPotionHooks` implements reservoirs and
enchanted vials; ordinary potions require no expansion-specific code.

The ordered lifecycle hooks `battle_prepare`, `turn_priority`,
`before_phase`, `turn_end` and `turn_end_resume` preserve existing
Red King processing order and reaction pause points. Scenario victory
policies and automatic creature decisions are not yet fully migrated.
Replay remains a partial command audit rather than a guarantee that
every autonomous decision can be reconstructed from an initial seed.
