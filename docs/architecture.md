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

## Activation model (current)
Each figure gets two actions per activation. At most one is a non-move action (fight, shoot,
reload). A second move is at half Move. Figures in contact with an enemy can't move away.
Phases run wizard → apprentice → soldier; within a phase the initiative winner activates all
of their figures for that phase, then the next player.
