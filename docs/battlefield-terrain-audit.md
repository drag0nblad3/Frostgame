# Battlefield art and terrain audit

References: Frostgrave Second Edition, p.38 and scenario setup pp.140–151; The Red King scenario setup pages cited below. This is an implementation audit of setup, not a transcription of the books or a complete rules compliance claim.

**Policy:** ordinary standard-game maps can use varied real terrain. Existing authored objectives, placement, hazards, exits, dimensions, and special rules remain unchanged unless a separately tested layout correction is required. Cosmetic inlay/relief has no gameplay collision and stays flush or inside existing terrain. Never put tall art-only props in traversable corridors. Ramps and stairs use the exact existing heightfield; marked treads do not add new step costs.

| Board / scenario | Setup requirement and protected areas | This pass |
|---|---|---|
| Frozen Ruins, Genie, Worm Hunts | Standard dense ruins, cover and generally short ground-level sightlines (core p.38, 146, 148). | Shared map gains two terrain profiles with connected ramps/stairs and additional real cover. All previous footprints and treasure/deployment coordinates retained. Does not guarantee every ground-level sightline is 12 inches or less. |
| Sunken Streets | Original standard-rules encounter; 2-inch depression and 1.5-inch raised side streets. | Visible tread/edge inlays using actual height. |
| Well of Dreams and Sorrows (p.140) | Central well, treasure off centre; surrounding ruins. | Temple relief and inlays only; leave well and treasure unchanged. |
| Mausoleum (p.142) | Approximately 6-inch central building, four corner treasures, door spawn positions. | Crypt ornament only. Existing solid central footprint is an approximation, not a true accessible interior; do not depict false entrances. |
| Silent Tower (p.143) | 10-inch, three-floor tower, two adjacent buildings and connecting walkways, summit treasure. | Preserve terrace and null-field footprints. Current campaign map is stepped exposed surfaces, not overlapping interiors; separate layered implementation exists. |
| Library (p.144) | Maze of climbable packed bookshelves, rough book piles, four door exits, frozen centre treasure. | Books and ledger rubble, inlaid floor details; no new shelves or blocked doorways. |
| Living Museum (p.145) | Four ruined walls around five statues in an X, adjacent treasures. | Relief/inlays, broken columns; unchanged statue positions and activation logic. |
| Haunted Houses (p.148) | Five huts around the central one, treasures and entrances inside. | Timber and floor fragments; keep all five entrances clear. |
| Keep (p.150) | Four 2–3-inch discs in cross, opposite discs about 12 inches apart. | Leave discs, teleports and approaches unchanged. |
| Complex Temple (p.151) | Six guardian columns in centre spaced approximately 3 inches apart. | Temple relief, carved masonry and column debris; preserve guardian contact points. |
| Red King: Squatter (p.24) | Three-room dwelling, central treasure screened from outside. | No geometry edits; sealed relief and debris. Existing interior LOS deserves separate explicit verification. |
| Investigations | Barbarian camp / investigation stations and escape routes. | No geometry edits; camp-themed ground and rubble. Setup page not independently confirmed in this pass. |
| Veil (p.29) | 24×36 table, accessible treasures and moving veil. | No change to escape routes, boundaries or heights. |
| Back into the Fire (p.34) | Ruined temple, open centre, edge terrain and four corner doors. | No central blockers; preserve portal and corner approach. |
| Demons and the Mad Man (p.36) | Standard ruins, Ryce at centre instead of central treasure. | No new obstacles or chase-route changes. |
| Mind of Kalamon Ryce (p.38) | 24×24 and explicitly no terrain. | Keep completely unobstructed, no additional on-table props. |
| Herded (p.43) | 30×36, centreline treasures and escape edge. | No new obstacles or changes to route and treasure alignment. |
| Planar Sinkhole (p.45) | 3-inch orb at centre, ring of treasures and nullmen. | No changed radius, positions or gravity geometry. |
| King of the Hill (p.48) | 6-inch central clearing; later planar pyramid. | No extra terrain in clearing or interference with scripted elevation. |
| Ethereal Tethers (p.50) | Five pylons in X, no starting treasures, later linked edges. | Keep all pylon bases and topology unchanged. |
| Bridge (p.53) | 30×36, 6-inch void with 4-inch bridge. | Do not fill void or add barriers to bridge. |
| Ringworld (p.56 onward) | Matched realities and jagged structures. | Existing solid geometry preserved; no new independent obstruction or side asymmetry. Exact setup page not independently confirmed. |
| Layered maps | Independent surface graph, legal stairs/climbs, visible floor selection. | The common BoardView now displays stacked solid volumes using the same architectural relief helper as exposed ruins, retaining independent cutaway visibility. |

The general rulebook guidance is a design target rather than an imposed artificial 12-inch sight cap. A fuller density and scenario-fidelity pass should sample actual ground-level rays, test all deployment zones and treasure access, and run balance simulations before modifying named scenarios. Existing layout approximations (especially the tower interiors and mausoleum) are not silently redesigned here.

## Scenario-specific exterior districts

The exterior now uses `data/exterior_profiles.json` to select near and distant silhouettes, asymmetric edge treatments and an outer-only ground material. All core and Red King scenario palettes have independent profiles: cemeteries, temple precincts, markets, a canal quarter, a glacial field, archive galleries, a hamlet, fortified walls, a barbarian encampment and distinct planar horizons. Exterior motifs are placed at least four inches beyond the playable rectangle, are purely visual, share the existing pre-baked/deferred district pipeline, and never mutate the Board or scenario state. The Veil and Herded scenes have distinct opposing horizons. The exterior material blends into the existing tactical boundary at the same world height; no floating tabletop or new rules terrain. Geometry/style changes invalidate both baked city and terrain bundles. Tests cover all palette IDs, deterministic plans, known motifs and off-table placement. Rendered previews are still needed to judge composition on a phone.
