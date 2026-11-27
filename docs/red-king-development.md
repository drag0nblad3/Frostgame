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

## Slippery Boots

Self-withdrawal offers legal half-inch increments up to three inches on normal and layered boards, including tied melee. Tied combat never grants enemy displacement. If both figures qualify, the human reaction side has priority; declining passes the opportunity to the other figure. The existing straight retreat direction and layered lattice are retained. AI defenders use tied withdrawals when carrying treasure; other AI tactics retain normal displacement logic. Tie state is saved in checkpoints.

## Golden Fangs

Found in six-unit lots and traded one at a time; a stack of up to six occupies one caster equipment slot. The inventory supports splitting one fang off and merging stacks within the cap. Select the optional fang toggle during Animate Skull resolution; a successful cast spends one and gives the new skull +1 Fight, recorded in checkpoints. No fang is spent on a failed cast. The UI currently limits each caster to one stack and the AI does not explicitly toggle fangs.

## Extended Scroll

Optional 9-inch bridge placement on flat and layered maps; extended bridges collapse only on 1. The flat interface toggles span, and layered endpoint selection includes both six- and nine-inch spans when the scroll is available. A successful extended cast spends the once-per-battle effect. Length and expiration status persist in battle saves. AI still plans ordinary six-inch bridges.

## Ivory Hand

Push attacks gain +1 above the normal +10, and stopping against terrain or the table boundary before completing the push deals three damage. Campaign inventory can permanently attach the item to an eligible magic staff for 500gc; the graft persists on that staff with no extra slot. A destroyed staff or suppressed magic disables the graft. Push remains limited to the existing ordinary-board forced movement path; scenario-specific forced relocation and layered Push remain distinct.

## Staff of the Illusionist

Allows two temporary illusions across a warband, including prepared rituals from both casters; the wizard loses two Will while both exist. Fool’s Gold range becomes six inches for the staff bearer. Losing the wizard immediately removes the newest illusion deterministically on ordinary casualty/extraction and layered extraction paths; player selection and special scenario exits still need integration.

## Elemental wall and Brilliant Wand

The Ring of Elemental Fire marks conjured walls as elemental hazards. Entry into contact and activation in contact cause damage, with elemental resistance, absorption and null-field checks. Wall state survives checkpoints; ordinary-board movement paths are supported (layered Wall is not yet implemented). The Brilliant Wand has three rechargeable power points, adds two to both Word spells, and restricts their empowerment to the wand alone, without Health or other power sources. Tests cover the damage and resource limits.

## Campaign survival and ritual equipment

Lifelong Plant presents a pre-survival casualty picker after ordinary campaign battles, with an explicit skip choice; the selected non-wizard gains one to survival and the plant is removed on a natural twenty. The plant is unavailable in sealed Ragged vaults or mindscape resolution. Mystic Shears can be used once per preparation, by a wizard on a living eligible specialist, adding two to one pre-battle cast (including the initial Summoning Circle cast). A second roll records temporary starting Health loss or permanent Health loss on twenty. The ritual interface exposes the optional donor; the temporary penalty expires after the next battle.

## Potion Drinker Staff and Golden Bottle

The staff adds one weapon damage and accepts a sacrificed vault potion before battle. Its charge is consumed by the existing potion action paths and expires after the game, without consuming the staff or a separate equipment slot. The Golden Bottle can optionally receive a successful wizard Brew Potion ritual, generating two doses in one item; drinking tests Will TN4, with poison and no effect on failure. Doses persist through battle settlement. Both currently support battle-use potions only, not campaign-only doses, and follow the existing ordinary-board potion action restrictions.

## Core Run For It / Talisman of Speed

Adds the missing core first-action run: three inches regardless of movement penalties, avoiding enemy proximity and consuming the activation. Talisman optionally doubles the distance once per battle. Movement uses legal paths and ordinary terrain triggers, or the existing experimental floor graph. Deep-water swimming is not yet represented by terrain metadata; group activations, phasing, and unresolved layered scenario interactions are excluded. AI does not yet choose Run For It.

## Elemental absorption

Elemental damage is routed through a shared reducer for elemental shots, wall contact, scenario portals, reality attacks, creature contact and elemental weapon damage. The amulet removes one point, or may be armed/disarmed during activation to risk absorbing the next elemental hit (1–16 succeeds; 17+ destroys it and adds three damage). Pre-arming avoids interrupting synchronous multi-target damage; exact after-roll reaction timing remains pending. AI risks it against large lethal hits.

## Gutter Flail

A legal ordinary or layered movement into new melee contact offers an immediate optional free fight with the equipped flail. It does not spend an action, uses normal combat and displacement handling, and is checkpointed. Rival AI automatically takes a legal free attack. Existing contact at the beginning of the move does not trigger it; unresolved layered reactions and special movement modes remain excluded.

## Wraith Bow

Magic bow with +1 damage and an explicit once-per-game shot option through one terrain piece. Other blockers remain in effect; the bypassed piece contributes +1 target Fight. Fate combat carries the shot flag through rerolls, followed by a Will TN8 curse check. The special ray is restricted to ordinary non-wrapping boards; layered volume and reality-wrap sight are not yet integrated. When multiple pieces could be bypassed, the engine chooses the best legal line.

## Bracelet of Vigour

Adds eight to Health target tests via StatRoll.health_test and reduces the optional Wounded threshold to two. The optional core Wounded rule is disabled by default, selectable per campaign, and stored in checkpoints; existing stat, spell and combat paths using roll_penalty inherit the penalty. Raw special-purpose dice tables do not automatically receive the penalty.

## Enchanted Teetotum

Optional pre-armed reroll of the next random heading, with binding replacement and once-per-battle spend. The shared direction resolver is used by Blink, pain blink, and Red King random-heading effects. This is a timing approximation: a post-roll reaction UI and discrete direction/corner rolls remain to be migrated.

## Circlet of Defence

Permanent selection from the specified spell list through the inventory binding control; the wizard cannot cast that spell and starts at -2 Health. Targeted effects, reflected effects, area shots, direct destructive sphere and explosive rune attacks honor the immunity. The selection is required before equipping, including when discovered locked. Suppression disables the immunity and casting restriction during the affected period.

## Pulsing Gem

Four rechargeable power points are restricted to casting and resisting Blink. Optional casting toggles select six-inch movement and a binding direction reroll; each use of power or enhanced movement adds a persistent shooting defence penalty. Reroll is preselected during cast resolution rather than after seeing the direction, matching the current synchronous heading system.

## Mask of Death

Campaign equipment choice determines whether the wearer starts the battle masked. A contextual action toggles the mask, replacing a move when legal. Effective undead status now feeds healing, poison, wound, melee, spell, ward, and Red King scenario trait tests without permanently altering the figure definition. The wizard loses the usual survival modifier if the mask was worn at any time; the historical flag is checkpointed. AI does not proactively toggle the mask.

## Vampire Staff

Explicit donor and empowerment amount on ordinary cast and resistance resolution controls. Each point costs three donor Health, at most four, and respects the ordinary casting cap. Surviving donors desert: soldiers leave, animals and creatures become uncontrolled; their campaign roster entry and inventory are lost. Fatal sacrifices follow normal casualty handling. Temporary phantom figures, undead, constructs and other-plane targets are excluded. Layered casting UI does not yet expose the donor selector; AI does not elect sacrifices.

## Gloves of the Worm Rider

Uncontrolled giant worms exclude protected bearers from pursuit and deliberate combat; once-per-battle token placement rolls for a delayed worm arrival, with visible marker and save-safe pending state. A natural one lets the rival AI relocate the marker toward an unprotected member of the summoner’s warband. End-turn occupied placement uses a nearby legal fallback. A natural-one survival roll permanently prevents resurrection. Flat placement only; no AI voluntary summoning yet.

## Lantern of Holy Light

Free opening action creates persistent Glow and a moving ward; nearby undead/demons receive a forced next-action retreat, including figures in melee. The straight retreat respects terrain and movement cost. The bearer may schedule shuttering at the end of their turn rather than interrupt the end-turn phase, otherwise the lantern extinguishes on 1–3. Flat movement only, no layered lantern controls or exact end-turn reaction UI yet.

## Tiger Eye Ring

Wizard-only targeting extension: a blocked figure target can be reached if a genuinely visible sampled point lies within two inches and normal spell range and scenario boundaries allow it. Casting via this extension and moving an active Wizard Eye each cost a Will TN20 test or three damage. Eye movement follows the perimeter of its existing rectangular host, up to four inches once per turn. Direct spell shots use an intervening-terrain modifier for the extended sight. The current extension applies to figure targets, not every terrain/treasure placement check, and does not support layered or wrapped geometry. Eye movement between different connected hosts remains pending.

## Scroll Shield

Roll the carried shield spell in campaign preparation; the roll is retained for that battle, and deployment requires it. The wizard can choose available before/after rituals from the shield without needing to know the spell. In battle, any friendly spellcaster within two inches of an unengaged bearer can consume the writing as a scroll, including failed-cast insurance. The bearer starts at -1 Health. Settlement preserves unused after-game writing only until the next roll. Summoning Circle-specific ritual and layered campaign edge cases remain pending; the ordinary Summon Demon battle spell is still supported.

### Quiver of the Hunter
Enchant Weapon can create single-use enchanted ammunition; ordinary quivers carry one, Hunter quivers four. The player chooses a separate enchanted shot, replacing missile weapon bonuses with +1 Shoot and a magical attack. Caster quiver replaces the normal quiver slot. Ammunition is battle-local; additional expansion ammunition sources and campaign persistence are not implemented.

### Mantle of the Bear (or Leopard)
The item permanently binds to bear or snow leopard and can only be assigned to spellcasters. The supplement's specialist-to-standard companion benefit conflicts with the second-edition core Animal Companion rule, which already classifies animal companions as standard soldiers. A per-campaign opt-in compatibility option implements the supplement classification for bear/leopard; core remains the default. Roster checks prevent removal or transfer of a matching mantle if that makes a roster illegal; a loss can require roster correction before deployment.

## Campaign integration hardening

Deployment repairs crowded or obstructed Red King campaign starts within their starting zones, without moving fixed scenario figures; an impossible deployment is rejected. Prepared summons require an attending caster. Headquarters explains deployment blockers, including the mandatory wizard for Mindscape (ordinary games retain the core wounded-spellcaster absence rule). Sealed artefacts cannot be studied, and the shield's next-game roll closes the after-game preparation window. Settlement retains the battle if persistence fails.

### Ragged campaign continuity
Random recruitment is a visible preparation step after permanent summoning rituals and before deployment; returned wounded members above ten enter a deterministic reserve (casters first, then roster order). An eligible promotion retains the story, and a replacement wizard drawn from the current draft can continue the invasion with a new roster, zero spendable starting gold and no apprentice. The story stage and global artefact discovery history are retained; old personal possessions are discarded. Recruitment and story changes are persisted before departure.

### Shared equipment controls on layered maps
Layered spell selection exposes enchanted ammunition; firing uses the same shot validation as flat maps. Bottle Imp can spawn on an explicit legal floor node and creates the new figure with its correct surface and elevation before the spawn event. The layered cast and resistance panel now exposes Vampire Staff selection and empowerment, scroll insurance, amulet and Fate Stone reactions. Creature and warband bots can use enchanted shots. Other advanced floor-specific hazards and targeting still require separate migration.

### Integration regressions
Corrected typed empty reserve lists on ordinary campaigns, prevented a free-form expansion scenario from permanently activating story-only Ragged restrictions, retained at most one eligible book-supported Foulhorn during reconciliation, and kept ordinary treasure choices available if the unique artefact pool is exhausted. The latter fallback is a digital policy because the book does not specify what happens after every artefact has been discovered.


## Opt-in integrated playtest

All four workflows passed on the preceding branch revision. The registry now exposes the expansion as an opt-in playtest, not a claim of full printed-rule fidelity. The real pack configuration is used by scenario simulation rather than overriding its status. The rescue-only Mindscape is excluded from free-form campaign selection; an explicit skip forfeits the bonus encounter and continues into Act III, including when the wizard cannot attend. The skip is recorded separately from completed stages and survives save/load. Known approximations and unresolved interactions above remain documented; historical prototype/locked notes describe earlier development passes. Full human campaign playthrough, touch controls and exact rule fidelity remain unverified.

Added a campaign lifecycle regression with scripted outcomes: real registered pack, all twelve scenario definitions, deployment, settlement, treasure choices, Ryce rescue and Mindscape rewards, Act III restrictions, JSON save/load at every stage, finale and return to free-form skirmishes. This tests integration rather than tactical outcomes; the scenario simulation workflow remains separate.

### Pursuit intermissions and campaign progress
The optional Act II no-resupply interval (supplement p.38) is selectable when creating the storyline, off by default. Both pursuit intervals now suppress base income and the sarcophagus during settlement of the preceding chapter, then allow normal settlement after the chase ends. A legal pre-pursuit Inn/Kennel roster keeps its existing reserve arrangement while base benefits are disabled; this is a digital continuity policy to avoid locking an oversized roster with no permitted dismissals. Headquarters displays chapter number and finale outcome. Tests cover both optional paths, economy gates, capacity and restored base access.

The installed-catalog regression caught a second status gate in FigureDb that still refused playtest packs. Catalog loading now uses the same ContentProfile.playable policy as selection. Tests check every registered expansion figure in the actual enabled and core-only profiles, and both campaign lifecycle and scenario simulations fail explicitly on unavailable scenario creatures before constructing the battle.

### Campaign headquarters navigation
The campaign dialog is now divided into Expedition, Warband, Equipment, Rituals, Base, and Rules & chronicle. Pending reward decisions and in-progress battles return to the read-only/settlement overview. The expedition page places objectives, blockers, departure and contextual preparation shortcuts together. The chronicle tracks chapter status; base art labels inaccessible benefits, and stand-alone expansion briefings no longer assert generic treasure victory rules. Touch targets and bounded controls support smaller safe areas. Inventory smoke exercises section navigation; device rendering remains to be verified.

### Equipment and player guidance
The equipment page now displays original summaries for all 62 registered expansion gear entries, including random recruit weapons, and shows the selected item's availability. Recipient choices are checked against the existing assignment rules on a deep copy of the campaign. Shopping controls hide when supplies are inaccessible; the current item stays selected when possible. The field guide adds expansion-specific campaign and equipment topics only when enabled. The optional recruitment status toggle sits with recruitment on the Expedition page.

Equipment study now happens on the selected item rather than a separate catalogue; the result is shown immediately. Ragged-warband discards require confirmation. The expedition page opens when returning to headquarters and links to succession, required Scroll Shield preparation, new gear and the latest battle report. Pending reward settlement hides unrelated rule and reconciliation actions.

### Interactive end-turn decisions
The Mindscape 7/8 event permits selecting any remaining memory, a marked half-inch-grid destination up to four inches away, or declining. Secret Exchange (19) presents eligible warband figures after the rival has privately committed its selection. These decisions suspend end-turn flow until resolved, are represented by plain scenario checkpoint data, and resolve automatically in headless/watch mode. They do not introduce suspended callbacks. Other synchronous reactions retain the documented pre-arm approximation.

### Rival tactical pass
Rivals now consider Dazzling Cape to rescue vulnerable treasure carriers and casters, Talisman runs when ordinary movement cannot cover as much exit progress, Holy Lantern against nearby enemy demons/undead, Wraith Bow/enchanted ammunition when ordinary shots are blocked or ineffective, and Mindscape's additional non-move action. Objective scoring favors pylons, Key-Masters and melee capture of Ryce; target searches respect Ringworld planes. Spell scoring includes current reality modifiers and discounts spell-reflecting or antithetical targets. These are heuristics rather than a full strategic search; autonomous vampire sacrifices and layered specialist tactics remain deferred.

### Expansion art pass
All twelve encounters now have dedicated atmospheric palettes, moving from winter ruins through ember-lit camps into violet dimensional voids. Mindscape no longer receives decorative terrain scatter. Hrut variants have stronger weapon, armour, crest and wing silhouettes; the Herald and Key-Master have separate visual accents, and Ryce has an original non-combatant sculpture. Portal and sinkhole ground rings indicate their actual footprint while luminous geometry clarifies hazards from above. Added an opt-in expansion bestiary gallery to visual CI. These remain low-poly, batched geometry and static emissive materials, not new expensive real-time lights. The visual outputs require review on a device.

Veil of Unreality now offers the wizard player's choice to redirect the rival's nominated Fractured Reality target to another member (adds one to the roll). The rival commits the original target and extra veil advance before the choice. End-turn reinforcements and the next turn wait for the decision. Added regressions for Secret Exchange and Veil redirection; visual CI now captures four actual expansion battlefields as well as the bestiary. The rival still makes its own advance/bonus choices automatically.

### Explicit Mindscape survival choice
Settlement previews the actual first survival roll on a copied campaign and cloned RNG, including preceding casualty rolls. The human player may decline the optional reroll or reveal the second roll and choose either result; the dialog explains the adjusted outcome including Death Mask, Ring of Destiny and accessible sarcophagus. The actual settlement replays the chosen rolls and persists only on confirmation. Headless tests retain the automatic fallback. Secret of the Hrut can also be spent after the ordered storyline has returned to free-form encounters.
