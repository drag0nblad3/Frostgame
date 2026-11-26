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

## First named scenario

- The Mausoleum (p. 142): selectable in the battle toolbar for the next skirmish or campaign battle, six initial skeletons and six treasure tokens without a central treasure, one additional skeleton at a randomly selected door after every Creature phase. Fixed token/deployment locations and solid central building approximate the tabletop setup. If the doorway is occupied, spawn on the nearest free node within 1.5 inches; optional pickup encounters disabled. 

## Summoning and temporary allegiance

- pp. 32, 69, 112, 116, 125, 130, 133: four point-target summons and five control spells implemented; creature placement, per-caster/warband limits, demon tiers and natural-one miscast, release actions, Mind Control resistance after activation, temporary soldier-phase allegiance and color changes. Four new bestiary records. Deployment uses existing half-inch lattice; Will resistance and release timing are simplified (Mind Control end-turn voluntary cancellation and empowerment pending). Campaign survival follows original allegiance. Before-battle Raise Zombie remains pending; no creature item slots. 

## Dynamic terrain spells

- pp. 122, 126, 134: Fog, Mud and Wall use point targets. Fog obstructs sight, Mud creates circular rough ground, Wall creates a climbable obstruction. Dynamic terrain invalidates path caches, expires through turn rolls and updates the 3D board. Wall and Fog use two axis-aligned orientations; placement excludes some terrain overlaps and uses 1-inch markers. Fog expiry is processed at the end-turn boundary. Wall removal can cause falling damage. Mind Lock now breaks and prevents Mind Control. 

## Magical movement

- pp. 114, 125, 130, 133–134: Teleport and Leap use selectable legal destinations; Leap has reduced range with treasure and a sampled arc for obstacle clearance. Both exhaust remaining actions this turn, including later group actions. Blink and Push move along a direction with legal landing and falling checks; Transpose selects two figures and checks enemy resistance before swapping. Resistance is automatic for enemies, waived for allies in Blink; no resistance empowerment yet. Forced movement uses quarter-inch samples; leap arc is a fixed approximation and vertical-only movement is not supported.

## Counter-magic

- pp. 65, 119, 131: Dispel and Spell Eater select one ongoing figure, control, terrain or Call Storm effect through a contextual effect selector. Spell Eater costs one additional Health on casting attempt. Canceling control restores original allegiance, not removing the summon. Terrain cancellation uses the existing terrain-removal/fall path. Global spell attribution and future effect types still need extensions; Will-roll empowerment remains pending.

## Rune hazards and planar attacks

- pp. 121, 127: Explosive Rune is a visible persistent marker within 4 inches, max three per caster. Ordinary movement checks every path node for a trigger; the blast resolves at that node and movement continues if the mover survives. Original allegiance determines triggering; the blast affects all nearby figures. Dispel/Spell Eater can remove runes, and orphaned runes roll to expire. Voluntary end-turn cancellation is pending; magically moved figures and pushbacks check their landing only. Planar Tear uses a selected point, area resistance and increased damage to demons. Both use exposed-surface point targeting; vertical walls are not yet valid rune locations.

## Illusion effects

- pp. 124–125, 134: Invisibility prevents targeted shots/spells and enemy entry into contact; casting, entering melee and collecting/dropping treasure reveal the figure. True Sight dispels nearby invisibility/phantoms and grants nearby allies detection. Illusionary Soldier currently summons a revealed illusory Thug (one per warband), able to engage/support but not inflict combat damage or collect treasure; any damage removes it. Models are translucent and labeled. Selection of other soldier types and pre-game casting are pending. True Sight creature-trait radius and some indirect area/forced-contact edge cases remain approximate.

## Immediate resistance empowerment

- p. 65: Blinding Light, Petrify, Steal Health, control spells, Blink and Transpose use a shared Will resistance resolver. Human spellcasters with a failed non-natural-1 roll may spend Health before the spell resolves, with no result cap; natural 1/20 are automatic. AI spends at most two Health to succeed and avoids lethal spending. The battle pauses across rival activations, and a two-target Transpose can request sequential resistance. Ongoing-effect expiration tests and other area/instant resistance spells still use automatic tests. Optional refusal to roll before rolling is not yet exposed.

## Time manipulation

- pp. 45, 61, 121, 133–134: Fast Act queues an unactivated ally or uncontrolled creature after ordinary activations on the caster's side; creatures still use creature AI. Time Store requires the first action of a normal two-action activation and stores an extra action for a later full activation, with two non-movement actions possible provided one movement slot remains. Time Walk gives the wizard one separate activation in Apprentice and Soldier phases; prior movement retains half-rate subsequent moves and consecutive-turn casts cost 8 Health. Stored actions currently cannot be used in groups or Time Walk bonus activations; Time Walk is restricted to Wizard phase. AI does not yet plan around these spells.

## Potion inventory and consumables

- pp. 26, 29–30, 66, 86–93: all 28 potion identities/prices in the catalog; loot rolls identify individual potions including greater table rolls. Campaign vault supports purchase of implemented potions, sale, and assignment with caster/soldier capacity, reserving a slot for the starting staff. Nine potion effects execute in battle, including healing, strength, toughness, speed, invisibility, clearsight, iron mind, chameleon and restoration. Standard apothecary starts each battle with a healing potion; controller supports administering it to adjacent allies, but UI currently offers self-use only. Consumed potions are removed from campaign inventory on settlement. Item loss currently assumes all items on out-of-action figures are lost; survival-specific item recovery and full equipment/scroll rules remain pending. Unimplemented potions are labeled in the vault.

## Magic equipment vault

- pp. 74–75, 97–101: all 20 arms/armour and 20 magic-item table records identified from treasure, with prices and implemented effects marked. Twenty weapon/armour entries and five passive items affect weapon rolls/damage, Will, Armour, Move, arrow protection, falling or elemental damage. Currently only matching standard weapon types are assignable (including caster staves); additional mundane loadout choices, magic dagger's free slot, two-handed caster slot costs and inactive alternative weapon selection are pending. Slot limits, same-type restrictions, sale and persistent ownership apply. Unused gear survives ordinary wounds; death and caster Close Call remove it. Elemental absorption applies to Elemental Bolt/Ball; other elemental effects and active-use items pending.

Inventory follow-up: renamed the UI owner selector to avoid a native Node property clash, added a headless campaign inventory/deployment smoke test, corrected two greater potion sale prices, exposed apothecary recipient selection and basic AI self-healing. 

## Scrolls

- pp. 65–66, 95, 104: treasure scrolls identify a spell, cost 250gc to buy and sell for 30gc; caster-only one-slot assignment. Unknown implemented spells use scrolls automatically at result 14 without empowerment; known spells can consume a matching scroll after a failed roll, suppressing failure damage. Scroll casts do not award XP. Out-of-game scrolls and AI insurance choice remain pending; special spell edge cases are subject to further verification.

## Weapon destruction

- p. 118: Decay selects one visible mundane weapon, never natural/unarmed weapons or magic/enhanced weapons. Destroyed weapons remain unavailable for the battle; a figure falls back to another standard melee weapon or unarmed combat. Ranged destruction disables shooting and reloading. Original definitions and campaign equipment are unchanged so mundane weapons are restored on deployment. Weapon choice outside destruction, caster mundane customization and duplicate weapons are pending.

## Power items

- pp. 64–65, 102: staffs of power (1/2/3), ring and wand of power (1), and orb of power (6) add an empowerment pool shared by casting and supported Will resistance. Empowerment consumes rechargeable power first, then orb charges, then Health; the UI displays both costs. Staff/ring/wand charges reset between battles; orb remaining power persists and a depleted orb is removed. Automatic source priority is a digital simplification; choosing a specific resource to spend remains pending.

## Campaign rituals

- pp. 81, 87, 110, 112, 114, 121, 126, 130, 135: eight out-of-game options (Brew Potion, Familiar, Animal Companion, Animate Construct, Raise Zombie, Absorb Knowledge, Write Scroll, Miraculous Cure). Per-caster attempts persist in save and reset after battle; preparation closes post-game attempts. Lesser potions free, greater ingredients paid before rolling with wizard-only -4; no empowerment/failure damage. Familiar adds 2 Health for next battle. Permanent animals and constructs count against soldier limits; bear added from p.179. Prepared zombie is temporary. Cure supports recently dead, injured and resting members. Out-of-game scroll casting, exact postgame step order, familiar destruction midbattle, resurrection item recovery, other rituals and construct equipment remain pending.

## Persistent injuries

- pp. 77–79: named injury table with repeated-result limits, persistent split-stat modifiers for Move/Fight/Shoot/Will, starting Health loss, Smashed Jaw early/group activation caps, Lost Eye shooting defence penalty, and optional paid Niggling Injury treatment with apothecary discounts. The printed table overlaps on roll 6; assigned 6 to Crushed Arm. Lost Toes is stored but its Move Roll penalty awaits Move tests. Double Lost Eye blocks wizard deployment pending a cure; blind apprentices retire on starting the next battle. Legacy anonymous injuries remain count-only until cured. Starting Health deficits do not alter advancement caps. 

Wizard creation recognizes campaign rituals separately from battle spells; group selection respects the injured leader's activation limit. The supported unique spell total is 61 (54 battle spells plus seven campaign-only spells, with Raise Zombie shared).
