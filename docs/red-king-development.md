# The Red King — expansion development

Source: user-supplied 2020 second-edition supplement. Do not commit the PDF or its illustrations. Use original descriptions and implement mechanics in code.

The registry and 12-stage campaign manifest are established; the pack remains locked until implementation. No playable scenario, creature, treasure or campaign effect is advertised yet.

## Shared engine investments

- Seeded event decks and checkpoint-safe per-scenario data (implemented).
- Scenario lifecycle hooks for activation, movement, damage, initiative, end turn, loot and survival.
- Dynamic line barriers with independent movement, sight and exit constraints; visible and saved.
- Forced relocation with deterministic collision resolution, falling and carried treasure rules.
- Map topology graph supporting portals, wrap edges, mirrored spaces, and explicit distance/visibility rules.
- Campaign sequence, branching, rule overrides, reward selection and random recruitment. Keep the Red King-specific restrictions local.
- Creature behaviors and targetable objectives; don't assume every neutral creature behaves identically.

## Work sequence

1. Bestiary: validate stat lines and implement traits and transformations; create distinct model variants.
2. Act I: ruined house, investigation deck, optional asymmetric escape. Verify each scenario's victory and reward rules.
3. Act II: portal hazards, NPC capture, optional solo encounter.
4. Act III: temporary supply restrictions and replacement recruitment, moving veil, sinkhole, changing terrain and topology, final dual-plane encounter.
5. Optional reality events, treasure and unique artefacts. Test each effect and acquisition path separately; never enable partial random tables.
6. Full campaign simulations, save/resume, mobile rendering and disabled-pack regression checks.

Book references: reality events pp. 9–18; campaign restrictions and recruit tables pp. 18–22; scenarios pp. 24–60; treasure pp. 64–85; bestiary pp. 86–92.

## Bestiary and boundaries pass

Eleven creature definitions checked against the supplied bestiary stat blocks (pp. 86–91), with pack-gated loading. Implemented movement-only perception, poison immunity and mundane missile damage cap; existing compatible traits are reused. Sense Magic contact with invisible targets, Pain-Blink, combustion, elemental blast, aura/automatic damage, reflection, immunity variants and other special traits remain pending. Generic boundary segments now affect standard movement and LOS, invalidate path caches, and survive checkpoints; topology helper is not yet integrated into path search, and no boundary rendering or layered-surface support is claimed.

## Creature effects and rendered boundaries

Added lifecycle hooks for Pain-Blink, aura of pain, automatic damage, combustion, elemental resistance, weapon melt and suicide attack. Direct spell targeting and magical projectile immunities are partially implemented; full anti-magic equipment suppression, spell reflection, special elemental blast and blood-marked Will modifiers remain open. Pain-Blink uses 20 evenly spaced headings and the nearest legal half-inch landing within six inches of the intended destination; non-walkable roofs and explicit layered floors need a dedicated landing policy. Aura tests currently use immediate unempowered rolls. Boundaries load from board JSON and render with low-cost strips and translucent veils; dynamic updates use the terrain refresh path. Forced displacement and magical landing now respect movement boundaries, but full wrapping, crossing-specific effects and layered boundary rules remain open.

## Act I / The Squatter

Added a hidden development scenario and a three-room house with two outside entrances and offset inner doors. Implements the troll's dormant state and scent pursuit, central-room Will gate with persistent success and per-turn failure, six corner reinforcements and treasure-seeking berserkers, and supplemental XP events. Uses a fixed authored two-player layout and core treasure/reward system. Magic relocation into the room, exact door placement, full group/reaction interaction, and visual verification remain to be checked. Pack is still locked.

Added blood-marked resistance and unarmed damage handling, Sense Magic movement contact/reveal, a first Herald elemental blast AI path, and suppression of passive and activated magic-equipment bonuses during combat with Nullmen. Broader item-use paths and full reflection, including area spells, still require dedicated tests and implementation.

## Act I / Investigations

Hidden scenario prototype: authored two-player camp, seven searchable offerings (represented by typed objective markers, not collectible treasure until revealed), seeded without-replacement deck, bonus gold and Will-test traps, alarm triggers, six reinforcement turns, and independent escape edges after turn three. Markers transform into treasure, and the battle HUD reports alarms and exits. Save fields retain card order, marker states and route choices. Digital adaptations: rectilinear open tent footprint, fixed placements, basic AI, unempowered trap tests, and extended victory flow to allow evacuation after the shift (ends when all warband figures leave or are eliminated, or at the turn limit). Multi-player layouts, precise tent art, broader objective rules and full campaign verification remain pending. Expansion stays locked.

## Act I / The Veil of Unreality

Hidden asymmetric scenario prototype: 24x36 map, three normal treasures, lethal receding veil, phase-specific arrivals for six opposing units, respawns at uncovered edges, reduced treasure movement penalty, single exit edge, and Fractured Reality effects. Opposing target and extra withdrawal use automatic choices; target reassignment UI, selectable adversary control, exact respawn placement, safe AI routing, dangerous-path warnings, and campaign restrictions between Investigations and the optional Veil remain pending. Fixed map and scripted deployment are digital adaptations. The expansion remains locked.

## Act II / Back Into the Fire

Hidden prototype: same-edge corner deployment with initial invisibility, six berserkers around the central locked artefact, three impassable circular portals with elemental contact damage and height-independent sight obstruction, seven Hrut arrival opportunities on turns 2–8, four corner exit zones, and modified experience. Fixed temple layout and AI-selected emergence positions are digital adaptations. Artefact-table choice, voluntary invisibility dismissal UI, complete contact-path coverage (including leap trajectories), exact corner doorway geometry, and campaign integration are still pending. Pack remains locked.

## Act II / The Demons and the Mad Man

Hidden scenario prototype with fleeing, melee-only capture NPC; hidden rescue marker revealed on knockout; temporary player-controlled Hrut hunting parties; recurring opposite-edge rotation and resettable occurrence clock; rescue eligibility flag and capped Hrut XP. The scenario provides only Ryce's Armour; the digital prototype uses Fight 0, Health 1 and no retaliation damage. End-turn reality occurrence uses fresh per-side d20 checks, with automatic priority-ordered hunter corner choice and fixed 20-direction wandering. Legal landing adjustment can separate combatants when rotated into blocked terrain. Climbing fidelity, optional manual deployment, all secondary spell interactions, and using campaign artefact/rescue flags to select linked scenarios still need integration and validation. Pack remains locked.

## Act II / In the Mind of Kalamon Ryce

Hidden solo prototype: 24x24 empty board, wizard only, three starting mindshrikes, eight memories in a six-inch grid, three actions with one movement and at most two other actions, distance-ordered creature activations, automatic path-contact collection, eight-turn cap, seeded ten-card event and reward decks, and separate injury-free campaign settlement. The 7/8 event-card treasure relocation is automatically chosen rather than manually targeted. Treasure/artefact rolls, Secret of the Hrut and survival reroll are recorded as unspent entitlements, not yet wired into future encounters or reward tables. Additional spell-action edge cases, full solo AI, mindscape visuals and linked campaign selection still require verification. Pack remains locked.

## Act III / Herded Like Cattle!

Hidden two-player chase prototype: 30x36 board, same-edge corner deployment, five centreline treasures, four Hrut warriors and one Longhammer with three off-board reserve creatures. The veil advances 2–6 inches according to its d20 table, deals unavoidable six damage on partial contact, removes fully engulfed figures, moves surviving contacts forward, and recycles defeated/unused Hrut on 17+. Uses a 12-inch sight limit, reduced treasure movement penalty, south-only evacuation and additional exit XP. Fixed layout, closest legal landing around blocked terrain, and loss of inaccessible ground treasure are digital adaptations. Forced combat push and all layered movement interactions still need review.

## Ragged Warbands infrastructure

Entering an Act III campaign encounter isolates the saved warband: paid hiring, dismissal, base access, buying/selling and paid treatment are blocked. Knocked-out soldiers rolling 1–8 are marked separated (not dead), retain their items and cannot deploy. Random recruitment fills the available persistent roster to ten, ignores normal specialist limits, and rerolls types from unavailable books. The pre-existing vault is sealed; new loot must be assigned or explicitly discarded before another battle. XP/level progression and grimoire learning remain available. Optional recruit-status rolls, Act III start-before-preparation workflow, lost-wizard replacement, final roster reconciliation, revival interactions, and full campaign sequencing remain pending. Pack is locked.

## Act III / Planar Sinkhole

Hidden scenario: 36x36 battlefield, central three-inch anti-magic orb, six treasures and six Nullmen. Circular movement and sight obstruction, contact damage and spell cancellation, three proximity casting penalties, one-inch gravitational pull and loss of engulfed loose treasure, reduced Telekinesis range, 17+ Nullman recycling, and per-caster proximity/combat XP. Gravity currently resolves closest figures first and stops at blocking terrain or occupied landings. Optional Fight/Will resistance is implemented as an engine call but no human choice prompt is connected; the end-turn default is to accept displacement. Exact continuous collision handling and magical movement edge cases need further verification. The orb uses a low-cost dark sphere and violet rings. Pack remains locked.

## Act III / King of the Hill

Hidden prototype: Herald and four Stingers, five treasures, central objective protected while the Herald is adjacent, priority-triggered persistent X-shaped reality crack, observer-side summit sight exception, second-move and attack-damage Move tests, six-inch downhill displacement, Will tests for dropped treasure, airborne immunity, stationary Herald AI with return-to-centre and push-back behavior, and revised XP cap. Flat tabletop projection with visible seams is used rather than deforming the existing geometry; the player's seam displacement choice is resolved automatically to a nearest legal half-inch point. Random treasure drops use a legal fallback; full movement/fall reaction coverage and physical pyramid visuals remain pending. Pack stays locked.

## Act III / Ethereal Tethers

Hidden scenario prototype: five stationary destructible objectives, ten berserkers, magical-only ranged targeting, no pylon retaliation, hidden treasure IDs revealed on destruction, +20 gold per recovered token, +50 XP per destroyed pylon, and no normal treasure XP. Each surviving pylon rolls for Hrut arrivals. Turn two creates three strips, diagonal-independent sight boundaries and directed movement-graph edges, with destination-centre arrival and remaining movement. Edge links and objective state persist in checkpoints. All pylon destruction restores ordinary topology and exits. The edge graph currently covers standard grid movement and reverse AI distance fields; phasing/burrowing edge traversal, blocked arrival fallback, all area/direct spell interactions, and precise seam contact cases need additional review. Edge crossing uses a half-inch budget at the source, consistent with standard exit movement. Pack remains locked.

## Act III / The Bridge

Hidden prototype based on Red King pp.53–54: 30x36 battlefield with two nontraversable void regions flanking a four-inch central bridge, ten initial Hrut, same-edge corner deployment, moving diagonal veil generated by two d6 rolls every end turn, random side displacement, Hrut sight/movement exemptions and Plane Walk movement exemption, Warrior arrivals on 5/6, bridge-only exits, reduced treasure Move penalty and evacuation XP in place of treasure XP. Void regions persist in checkpoints and are checked in normal pathfinding, Leap and phased movement. Forced moves into the void roll TN16 with a legal last-safe landing on success. The visuals use dark masks over the existing flat ground and glowing lips, not a physically cut-out chasm. The closest legal lattice landing replaces exact continuous displacement; arbitrary forced relocation, teleport and rare interaction paths need further review. Pack stays locked.

## Act III / Ringworld of the Red King

Hidden finale prototype: two mirrored realities share one terrain layout, with independent figure contact, occupancy, treasure and sight; outside sight is limited to 18 inches. Standard movement graph wraps short edges at matching coordinates. Explicit switch and escape buttons, Key-Master random movement and combat, Hrut plane changes and reinforcement table, central treasure and finale XP cap, and permanent losses on destruction of all four Key-Masters. Fixed two-player deployment replaces priority placement; the initial view labels inside/outside on one shared board rather than providing a selectable layer filter. Special artefact exchange, full campaign completion/reconciliation, terrain-spell plane separation, wrapping sight, phasing wrap, cross-plane item/area effect audit and sacrificial AI strategy remain pending. Pack remains locked.

## Ordered storyline integration

The Red King can be explicitly selected when the pack is available; the ordinary campaign is unchanged. The stage cursor and completed encounter IDs persist in the campaign save. Optional Veil is chosen at campaign creation, the solo mindscape is skipped unless Ryce was rescued, and Act III restrictions begin during the intermission before Herded Like Cattle. The campaign picker no longer allows out-of-order battles in story mode. The Veil intermission blocks paid transactions and base benefits; manual setup/ritual edge cases and the optional stricter Act II intermission require review. Story remains hidden until the pack is ready.

## Red King reward tables

All 38 ordinary reward entries and 20 artefacts are indexed with table order, prices and unlock targets. One exchange per scenario is offered at treasure settlement, including central +2 selection after rolling, and the Fire/Ringworld artefact options. The optional mindscape reward cards now draw from the tables. Artefact identity is unique within this local campaign's recorded discoveries; study can be attempted once per game, and locked sale value is halved. Passive item powers wired in this pass: Cloak of Tattered Shadows, Mask of Many Faces, Blood Beetle, Bronze Star of the Apprentice and Ice-Crystal Pin. Mindguard Shield is staged pending resistance-specific validation. Remaining item powers, special compatibility, rival artefact uniqueness, exhausted artefact pool behavior and selectable study empowerment require further implementation; incomplete effects are labeled and cannot be equipped. Pack remains locked.

## Optional Reality Cracks

All twenty table entries now have initial engine implementations, triggered once per battle via the printed priority thresholds. Lifecycle and effects are saved in checkpoints; a campaign checkbox opts in only on standard flat maps and The Squatter so that the later bespoke Red King geometry is not overwritten. The two exchange effects, convergence and terrain displacement currently choose automatically rather than opening manual or secret selections. Gravity ignores rough/climb/treasure costs and uses straight routes; the extra movement budget for falls and several unusual jump paths still need review. Sphere supports wrapped sight and ordinary movement on both axes; forced and phased wrapping remain incomplete. Cross uses isolated quadrants, fixed 12-inch perpendicular sight and movement barriers; Enneahedron has crossing-permitted sight seams and prohibited endpoints. Terrain portal/hoof use dynamic circular obstacles, existing light portal/orb graphics and legal relocation fallbacks. Item null-wave suppression and all direct/area effect interactions require further audit. Pack remains locked.

## Deployment and item fidelity pass

Moved obstructing ruins inward on Planar Sinkhole and King of the Hill after seed-17 simulations identified illegal starting placements. Added Feather Blade slot reduction, Armring of Strength and Surefoot Boots target-number bonuses (not combat or movement increases), Icon of the Sun melee damage/energy-drain immunity, and Burning Icon Banish resistance modifier. These effects use the existing anti-magic suppression paths. Armring and boots are connected to the current expansion-specific stat tests; other core stat-test paths need an audit. Remaining item powers and interactive scenario choices still prevent declaring the pack complete.

## Mindscape reward integration

A persistent opt-in checkbox spends the Secret of the Hrut in the selected next story encounter; melee and mundane shooting defence use its matchup-specific Fight bonus, and settlement consumes it only when the battle is completed. The flag survives checkpointing. The next wizard survival check automatically uses the better numerical roll if the first outcome is not full recovery; it does not reroll a full recovery. A manual choice between outcomes remains a UI refinement. Recovery of the Fire artefact is now passed into the Mad Man deployment, and locked intermissions suppress the telescope. Sinkhole ruins retain clearance around the treasure markers as well as starting positions.

## Additional equipment and artefacts

Implemented Soulchill Blade, Sword of Woe and Sword of Elemental Fire with battle-local counters, plus Ring of Destiny campaign XP and survival penalty, Hypnotic Puppet initial resistance penalty and miscast damage, Lightning Brooch elemental resistance and equipment restrictions, and Sticky Finger Gloves ordinary end-of-game recovery. Mindguard Shield now modifies recurring spell resistance, Banish and Destroy Undead; Hrut matchup defence also applies to spell shots. Sticky Finger Gloves are intentionally limited to ordinary treasure recovery, not mandatory scenario-specific losses. Lightning Brooch checks permanent equipment and innate resistance at assignment; unusual temporary effects need review. All mechanics still use the expansion gate.

## Equipment-granted creature traits

Ring of Levitation applies the existing levitate movement discounts on flat and layered maps with the required Will penalty; no new fall immunity is granted. Mind Lock Collar uses an animal-only equipment exception and grants immunity to Mind Control and Suggestion rather than the extra Will from the actual spell. Construct Spikes permanently attach to constructs, use the existing charging Horns mechanic, and cannot be detached or discarded while attached. The vault lists animals and constructs as special-equipment recipients when the pack is enabled. Distinct generic magic items may share a caster loadout within ordinary slot limits; duplicate identities and conflicting weapon/armour types remain blocked.

## Warband equipment and recruitment

Amulet of Charisma raises the specialist ceiling without adding roster places; the Inn reserve calculation respects the increased ceiling, and voluntary removal is blocked if it leaves an illegal roster. Book of Wisdom discounts one eligible monk/mystic warrior when those soldier types are available from a future pack. Book of the Foulhorn is vault-only and permits one permanent specialist foulhorn for 200gc; its pregame brawl uses seeded battle dice and damages a random other deployed campaign member. Creature Mask redirects an uncontrolled creature to an unmasked melee target, tracking its cumulative Will cost only on a committed redirected fight. Permanent construct grafts are lost rather than recovered to the vault on dismissal. Campaign deployment checks the specialist ceiling and loads enabled figure catalogs for reserve calculations.

Golden Incunabula now has a one-time spell binding in the inventory, preserved in the campaign and battle loadout; only an apprentice can equip it, and the matching spell receives +1 on both ritual and battle casting rolls. Animal companions remain standard soldiers under the second edition core rule; the Mantle remains pending an explicit compatibility decision because its printed benefit assumes specialist companions.

## Active summoning equipment

Bottle Imp adds a contextual equipment action and legal placement preview; it consumes the bottle, allows melee use, and creates an independent uncontrolled imp on the same plane. The current implementation uses the flat-board placement interface; layered placement is not yet exposed. Skull Staff expands the wizard’s skull/zombie limits, supplies the Strong damage trait through a checkpoint-safe battle counter, and applies the casting bonus and cumulative-summon penalty. Prepared zombies remember their original caster and Strong status. Power pool charges now honor all anti-magic suppression sources.

## Enchanted crafting supplies

Wax and vials now award six charges, trade individually at the prose-rule prices (30gc/10gc), and are vault supplies rather than carried equipment. Ritual UI lets players opt in before casting; failure spends no material. Waxed scrolls resolve at 15. Enchanted vials roll once upon use in battle or campaign: 19–20 retains an ordinary potion. Enhanced copies are selected first when otherwise identical consumables coexist. Settlement persists the remaining enchanted count, including a retained potion whose enchantment was spent. Sealed vault supplies are inaccessible during Ragged Warbands.

## Dazzling Cape

One optional move out of combat per battle, with original melee opponents excluded from forced-combat interception and all other normal terrain, action, movement and reaction checks intact. Available from Equipment on ordinary boards and via a dedicated escape control on the supported layered movement path. Layered movement retains its existing restrictions on unresolved scenario and reaction systems; rivals do not yet deliberately spend the cape.
