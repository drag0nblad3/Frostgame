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

## Second Edition audit — milestone 2 foundation

Source: Joseph A. McCullough, Frostgrave Second Edition (2020), printed page numbers. Original PDF stays outside this public repository.

| Area | Status | Reference |
|---|---|---|
| Starting stats and prices | Verified and corrected; all 15 soldier types in data, specialist metadata; inventory and apothecary rules pending | 25–31 |
| Weapon modifiers/ranges | Verified; inventory restrictions pending | 33–37 |
| Crossbow reload | Can replace movement; cannot reload in combat | 34, 52 |
| Combat support | Net bonus cancels opposing support, maximum +6; total roll bonus capped at +10 for current warband figures | 44, 53 |
| Criticals | Optional, default off; auto-win and +5 extra damage when enabled; creature immunity pending | 55 |
| Shooting | Hasty-shot and large-target modifiers added; cover, intervening figures and combat targeting still approximate or missing | 57–59 |
| Stat and casting rolls | Pure arithmetic and tests added; no live spell actions or spell effects yet | 29, 44, 62–65 |

Next: treasure objective and extraction; selection of eligible early-phase soldiers and true group activation; push-back choices; player input; live spell effects and creature phase. Earlier table is the pre-audit baseline, superseded where this section differs.

## Treasure skirmish (second development pass)

- Pages 38–39, 49, 68, 71: fixed five-token scenario, pickup/contact/enemy exclusion, carrying penalties, drop, death drop, extraction as a movement action, secured/lost status, non-campaign scoring and remaining-warband recovery rolls implemented. Gold boxes, carrier attachment, score display and objective-first bot added. Original combat-only scenario remains for regression tests.
- Digital approximations: fixed hand-authored token positions; base/token radii and half-inch grid; retreat requires enough movement to cross the edge; 12-turn safety limit retained (unresolved treasure is not scored at timeout). Bot exit heuristic may stall at terrain. No random encounter rolls, Run For It, forced combat, or vertical distance yet. No manual player input yet.

## Interactive skirmish

- Human side 0 and automatic rival; legal activation/target previews and contextual Move, Fight, Shoot, Reload, Collect, Drop, Exit and End commands. The same controller validates both bot and human actions; view only emits intents.
- Explicit movement and retreat previews use the current lattice; tap hit testing uses projected figure locations and a flat table ray. Phone gesture/layout checks still required on a physical device. Watch mode retained for debugging.

## Early phase activation

- Pages 40–43: wizard and apprentice may each activate up to three unactivated soldiers within three inches and line of sight at phase start; the caster may act before or after those soldiers. Human can pass optional soldiers after caster activates, leaving them eligible for later phases. Bot automatically takes eligible early activations. Edge-to-edge range and existing flat center-ray LOS used. No group movement-first mode yet; creature phase and additional activation effects pending.

## Group activation

- Page 43: before any individual activates in an early phase, choose caster and one to three eligible soldiers. Move each member (or skip), then perform one second action per surviving member in any order. Movement substitutes (reload, drop) are unavailable during the movement pass. Only selected members act early; unused soldiers remain eligible in later phases. Human group declaration UI and regression tests added; AI still uses ordinary individual early activations. Flat movement and contact approximations remain.

## Combat displacement

- pp. 47, 53: unique melee winner can stay or move either combatant one inch away (blocked by terrain/figures; self-withdrawal prohibited if engaged with another enemy). Acting human winner chooses; defending winners currently default to stay. Automatic interception is an engine option, not yet enabled in the shipped scenario; reactive choice and elevation are pending.

## Creature phase

- pp. 69–70, 176–177: neutral creature phase after soldiers, descending current Health, separate allegiance, basic visible-target or random movement AI. First pickup can spawn from a curated encounter pool at a random edge. Stats for initial bestiary entries based on pp. 180–191; trait effects and full encounter tables remain incomplete. Treasure scenario opts into automatic interceptions and encounters.

## Live magic — initial spell set

- pp. 62–65, 114–132: declare spell/target, roll, choose Health empowerment, resolve damage/success. Eleven live effects: Elemental Bolt, Bone Dart, Elemental Shield, Heal, Shield, Fleet Feet, Strength, Glow, Mind Lock, Combat Awareness, Steal Health. Scenario uses provisional known spell lists and adjusted casting numbers; wizard/apprentice share list. Human empowerment UI and basic heal/attack AI. Shot spells currently exclude combat targets; spell resistance empowerment, allegiance change from allied Steal Health, spell cancellation, terrain and summoning effects are not yet implemented. Armour/Move/Fight and shield effects are live.

## Starting warband creation

- pp. 17–32: school relationship table (all ten), eight starting spell slots with home/aligned/neutral constraints, casting-number adjustments, wizard name, optional apprentice, 400gc budget, eight soldier/four specialist limits. Warband editor deploys the custom blue warband in a fresh battle. Catalog contains thirty initial spell records (three per school, eleven functional; pending entries visibly marked and excluded from casting). This is not yet a complete spell catalog, and no campaign persistence or starting equipment customization is implemented.

## Integration refinements

- pp. 36, 57–59, 65, 197: permanent warband Armour cap 15 (core rules), Glow correctly increases attack total, hasty-shot modifier on spell attacks, random targeting among connected melee participants for mundane and single-target spell shots. AI avoids uncertain friendly-fire shots where possible. Strong and Powerful creature melee traits are functional. Roster dialog construction and deployment smoke coverage added. Existing flat line of sight and cover approximations remain.

## Ongoing magic and poison

- pp. 60, 118, 120, 124, 131: Slow, Curse, Furious Quill, Enchant Armour, Elemental Ball and Destroy Undead now execute. Ongoing effects modify live stats and rolls, with automatic resistance rolls at their specified timing. Poison reduces activations to one action, cannot stack, is cured by actual healing, and does not affect undead/constructs/demons. Elemental Ball uses connected melee expansion, but the existing flat LOS/cover model does not yet fully account for intervening figures. Resistance empowerment and armour-equipment distinctions remain partial.

## Human defensive reactions

- pp. 47, 53: human guards can now accept or decline an interception during an AI move. Declining preserves the path and searches for other guards; accepting interrupts movement and moves the guard to contact. Human defenders who win melee can choose displacement before the rival activation continues. The watch mode retains automatic AI decisions. Interception is evaluated at half-inch path nodes; AI policies and reaction animation remain preliminary.

## Campaign prototype

- pp. 73–75, 82–85: explicit campaign mode, local versioned save, persistent warband roster with stable member IDs, soldier/caster survival outcomes and missed games, treasure gold and unresolved loot categories, experience from participation/spellcasts/creatures/treasure, 300 XP cap, one known-spell improvement per game (100 XP, minimum TN5). Report and next skirmish UI. Wizard survival +1 automatically applied; permanent injury rolls, medical treatment, loot identification, central treasure reroll, recruitment/level-stat advancement, wizard succession and active battle saves are pending. A dead wizard ends this prototype campaign.

## Elevation foundation

- pp. 46, 50, 57: optional walkable platform and tower surfaces; movement planner charges vertical climbing distance, rejects cross-height base contacts, and shooting uses 3D range and a height-sensitive ray. Combat push down a ledge causes falling damage. This is a single exposed-surface heightfield, not a multilayer navigation mesh. Partial climbs, run-up jumps, deliberate falls and floor interiors remain pending.

The default Frozen Ruins board now includes a two-inch raised platform and a four-inch tower. Figure, movement, targeting and treasure markers use surface elevation. Picking uses the nearest exposed surface, and movement animations follow the heightfield. Group range and treasure proximity now account for height. Rendered geometry and movement remain block-based prototypes.

## Complete spell metadata and additional effects

- All 80 core spell names, schools and base casting numbers from the spell reference (pp. 112–135, 202–217) are available in wizard creation; pending spells remain explicitly unavailable in battle. Nine additional effects: Banish, Call Storm, Scatter Shot, Destructive Sphere, Blinding Light, Petrify, Poison Dart, Enchant Weapon and Elemental Hammer. Weapon spells use a single equipped weapon choice (missile weapon preferred when present); ammunition choices and magic-attack immunity are not yet modelled. Area attacks and resistance use current approximations. 

## Campaign management

- pp. 75, 83–85, 96, 103, 106: recruits and dismissals with soldier/specialist caps and level-priced apprentice; wounded caster treatment including debt and apothecary discount; one stat increase per game, wizard/apprentice bonuses applied to copies of definitions; grimoire identification and learning using the random spell table; three initial functional bases (brewery, laboratory, treasury). Other bases, detailed permanent injuries, spell learning/improvement ordering, item identities and loadouts remain pending. Existing version-1 campaign saves use defaults for added fields.
