# Rules coverage

Everything below was coded from memory of Frostgrave 2nd edition and **needs checking
against the book**. "Verify" items are the specific interpretations to confirm.

## Implemented
| Area | What | Code | Verify |
|---|---|---|---|
| Stats | Wizard, apprentice, 11 soldier types | `data/figures.json` | All stat lines and costs (`"verify": true`) |
| Weapons | Hand weapon, dagger, two-handed, staff, unarmed, bow, crossbow | `data/weapons.json` | Modifiers, ranges; staff's −1 to damage taken |
| Turn | d20 initiative, ties for first rerolled; phases wizard → apprentice → soldier | `Initiative`, `Phase`, `TurnFlow` | Order of 3+ players after the winner |
| Actions | Two actions; one non-move action; second move at half Move | `MoveRules`, `GameController` | Half-Move second action and rounding |
| Movement | Free movement, rough terrain costs double, blocking terrain impassable, a move ends on contact | `MoveGrid`, `MovePlanner` | — |
| Combat contact | Can't move while in contact with an enemy | `MoveRules.can_move` | Leaving combat (free strike?) |
| Melee | Opposed d20 + Fight; higher deals total + weapon − Armour; +2 per supporting friend | `Melee` | Tie result (both wounded); support conditions |
| Shooting | d20 + Shoot vs d20 + Fight + cover; only shooter damages; range edge to edge | `Shooting` | Ties go to the target |
| Cover | Light +2 / heavy +4 within 1" of the target; +1 per intervening piece | `LineOfSight`, `Shooting.target_mod` | Exact cover and intervening rules |
| Line of sight | Ruins block; traced centre to centre; figures don't block | `LineOfSight` | Any-part-visible rule |
| Criticals | Natural 20 doubles damage | `Damage` | Critical hit rule |
| Crossbow | Must reload (uses the non-move action) after shooting | `GameController.reload` | Reload timing |
| Out of action | Health 0 removes the figure | `Damage.apply` | — |
| Victory | Last warband standing; draw after 12 turns | `TurnFlow` | Placeholder until scenarios/treasure |

## Not yet implemented
- Spellcasting (casting rolls, failure damage, empowering, schools, spell list)
- Wizard group activation (soldiers within 3"), creature phase, wandering monsters
- Treasure tokens, carrying treasure, exiting the table, scenarios
- Wounded state, push-back after melee, leaving combat, shooting into combat (random target)
- Elevation, climbing, falling, jumping; figures blocking line of sight
- Will rolls, morale / warband retreat
- Campaign: injuries and survival, experience and levels, treasure, base and hiring
