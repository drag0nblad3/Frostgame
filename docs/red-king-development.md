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
