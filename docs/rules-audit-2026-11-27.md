# Rules fidelity audit — November 27, 2026

Source: user-supplied Frostgrave Second Edition (2020) and The Red King (2020). Printed page numbers. No source prose reproduced. This is a living checklist, not a certification. Earlier coverage notes are historical snapshots.

| Topic | Reference | Finding / action |
|---|---|---|
| Standard deployment | Core 39 | Fixed positions violate 3-inch edge depth; live roll-off, edge selection and manual/auto placement implemented, pending CI. |
| Library setup | Core 144 | Door-radius exception, 6 inches from chosen doorway implemented; review exits. |
| Corner starts | Red King 34,43,53 | Fire and Herded 6-inch radius; Bridge 4-inch radius. Circular zones in live draft; fixture loader still has old coordinates. |
| Veil start | Red King 29 | Adjacent to short edge; review model base assumptions. |
| Investigations / Ringworld / Mind | Red King 27,38,57 | Investigation edge roll now uses the existing tent entrances and escape corners follow chosen entry; Ringworld has wizard-centered formation and inter-warband separation. Mind fixed corner remains a legal automated selection; player corner choice outstanding. |
| Tower | Core 143 | Add actual supporting walls and valid elevated treasure positions; check route links and null-field rules. |
| Standard treasure placement | Core 38–39 | Five tokens; central at center or nearest practical point; two within 8 inches, spacing at least 6; last two more than 9 inches from edges and 6 from other tokens; vertical distance counts. Audit authored maps; player placement missing. |
| Terrain density | Core 38–39 | Ground sight generally about 12 inches; opening sight to opponents or central treasure discouraged. Audit actual rays. |
| Activation | Core 40–43 | Check movement-first group, early eligibility snapshots and exceptions. |
| Movement | Core 44–51 | Audit base measurements, fractions, rough ground, jumps, climbing, falling, forced combat and Run For It for both geometry providers. |
| Melee and damage | Core 52–56 | Compare support, ties, criticals, push decisions, multi-combat. |
| Shooting | Core 57–59, 220 | Added elevation-aware figure screening (+1 intervening / +2 contact cover) to ordinary physical rays. Center-ray terrain sight, full body occlusion, topology-specific screening, area attacks and exact terrain contact still require review. |
| Casting | Core 62–65, 221 | Audit apprentice modifier, empowering, failure bands, resistance, spells, duration, range, gear and creature exceptions. |
| Treasure | Core 68–71, 221 | Validate carrying, enemy exclusion, movement/fight penalties, exit and remaining-player recovery. |
| Game end | Core 71 | Removed arbitrary 12-turn cap from live expeditions; retained a configurable simulation guard. Existing recovery uses carried treasure and 15+ ground rolls for a lone survivor. Review scenario exceptions separately. |
| Warbands and equipment | Core 25–37 | Prior stat audit exists; verify all content, restrictions, costs. |
| Campaign | Core 72–87 | Audit injury, advancement, treasure, hiring, base, equipment and between-game spells. |
| Core scenarios | Core 140–168 | Twelve catalogue entries include custom maps; audit authored setups, special rules, XP and loot; remaining book scenarios not implemented. |
| Creatures | Core 177–197 | Audit encounters, targeting, actions, stats and traits. |
| Red King | Expansion 9–92 | Prior parity work does not establish source fidelity; audit reality cracks, campaign, scenarios, gear, spells, creatures and rewards. |


## Setup findings (source comparison)

- Core p.39: treasure separation is three-dimensional. The Tower's elevated inner pair, Sunken Streets' inner spacing and outer edge clearance, Library's inner radius, and the Bridge's ordinary placement were corrected. Authored treasure layouts are still automatic; independent player placement before the edge roll is not implemented.
- Core p.140: the well treasure must be equidistant between starting edges. The existing authored treasure location therefore requires east/west deployment.
- Core pp.142–151: mausoleum corner and door placement, museum statues, haunted huts, keep discs, and temple columns are scenario-specific, not generic treasure placement. The haunted-house roll ranges overlap at 17 in the printed book; retain the existing 7–16/17–20 interpretation. Worm and genie spawn position choices and disc landing choices remain automated approximations to review.
- Red King pp.27–28: tent entrances constrain entry, alarm and reinforcement rules are already represented, and post-shift escape edges must follow actual entry. Red King p.57: roll for priority, central 8-inch wizard placement, 3-inch follower radius, separation from previous warbands. Digital spacing uses conservative 7-inch center separation to leave 6 inches between 1-inch bases.
- Core pp.52–56: ordinary ties deal simultaneous damage and remain in contact. The existing tie withdrawal is restricted to the Slippery Boots item exception; do not remove it as a base-rule fix. Shooting into combat already randomizes participants, including allies.
- Core pp.38–39: opening sightline restriction is a terrain-design goal, not a hard range cap. More terrain-specific review is needed before asserting every deployment configuration meets this goal.

Status: preliminary core and scenario-setup audit only. Full spell-by-spell, bestiary, campaign, magic item, and Red King effect audit is outstanding. Prior passing tests validate the current implementation, not independent fidelity to every printed rule.
