# Multi-floor battlefields: implementation plan

## Implemented foundation

The opt-in `stacked_gatehouse` board defines three named surfaces, four solid
volumes and explicit staircase links. FloorLayout validates endpoints; LayeredGrid
and LayeredReach search layered nodes; LayeredSight tests vertical slab occlusion.
Figures and treasures have optional stable surface IDs in checkpoints. Figure-target
shooting and treasure pickup recognize explicitly assigned floors. Existing battles
still use their original exposed-surface movement. The gatehouse is an isolated mechanics lab accessible from the title screen,
not selectable for campaign play. It provides floor selection, upper deck cutaway,
explicit destination markers and a goal-directed route helper. The lab allows
ordinary movement and treasure pickup; it is not a full battle or AI opponent.

Current limitations: connections are atomic movement edges, not partial climbs;
floor surfaces and solids are separately authored; no general floor-aware AI,
magic or displacement is wired yet. Limited floor-specific input and rendering
are implemented in the isolated lab. GameController exposes
experimental layered_reach/move_on_floor methods which consume a normal move
action, persist the selected surface and emit a 3D movement path. Unsupported
reaction/magic cases are rejected, and legacy move_to cannot act on layered boards.

## Experimental battle integration

LayeredBattle builds two small rival groups with normal initiative, activations,
melee and shooting. The bot uses controller-validated floor routes, collects loot
on the correct level and extracts via authored ground edges. Same-floor pushback
and floor-aware drops are supported; falling from a ledge is still pending.
Teleport is explicitly targeted at a named surface and uses normal casting rolls,
optional empowerment, line of sight and exhaustion. Other spells and group
movement remain disabled for the experimental map. The battle core has an end-to-end simulation test and a dedicated title-screen
experimental skirmish with floor selection, activation, combat, collection,
extraction, Teleport empowerment and stepwise rival activations. The original
floor lab remains accessible from the skirmish toolbar. Campaign play remains
separate.

## Current boundary

A Board stores one exposed walking height at each horizontal coordinate. A bridge or
roof therefore replaces the underlying reachable surface rather than coexisting with
it. A figure currently stores horizontal position and elevation, but most destinations,
treasures, spell terrain, and path nodes are still two-dimensional.

## 1. Stable surfaces and transitions

Introduce an optional authored surface model without replacing the existing boards.
Each surface has a stable ID, footprint, height profile, walkable edges and optional
supporting structure. An explicit connection links two surface IDs at a position.
Ordinary stairs, ladders, climbs, drops and magical movement use typed connections.
Keep inches as the unit and preserve the existing half-inch movement lattice.
A multi-floor movement key consists of grid coordinate plus surface ID; two nodes
may share the same coordinate at different elevations. Do not connect overlapping
surfaces solely because their footprints overlap.

Terrain volume is separate from walking surface: walls, floor slabs and ceilings have
a base elevation and top elevation, with actual door/window openings. Use that
geometry for occupancy, line of sight and vertical clearance. Existing maps initially
retain their present exposed-surface adapter and saved battle compatibility.

## 2. Movement and occupants

Add surface IDs to figures, treasure and all position-bearing events; preserve old
snapshot loading with the exposed-surface fallback. Dijkstra and AI distance fields
use layered keys and explicit connection costs. Occupancy, melee, pushing, group
activation, interception, exits and treasure collection consider the selected surface
and physical vertical distance. Reuse existing climb and falling rules.

Rulebook p. 46 allows figures to stop partway up a climb; a vertical transition should
eventually support intermediate hanging positions rather than requiring one action
to reach the next floor. Running jumps, controlled falls and ladders need their own
legal transitions, with spell and creature exceptions. Do not silently give every
figure the ability to traverse ceilings or teleport through floors.

## 3. Combat and magic

Trace 3D rays between actual source and target elevations through volumes, with
floor apertures and doors as gaps. Range uses actual height difference. Confirm
cover, spell placement, summoned units, area effects, wizard eyes, pushback, bridges
and terrain destruction across floors. A destroyed supporting surface must cause
affected figures and treasure to fall to a valid lower surface. Add explicit rules
for what happens when a magical movement spell selects a different floor.

## 4. Interface and rendering

Floor selector (all / selected floor), cutaway upper floors and occluding roofs,
floor-specific reach highlights and targeting; use explicit visible surface hit
testing. Show the surface/floor in the inspector and the elevation in movement
previews. Provide a way to cycle overlapping selectable destinations. Do not infer
a destination's floor from its horizontal screen projection.

## 5. First integration fixture

Build a two-storey ruined gatehouse with an open underpass, a roof, a staircase,
an accessible lower room, and one treasure on each level. Acceptance tests:
- Two figures can occupy the same horizontal coordinates on different floors.
- No melee or treasure pickup through a floor slab.
- Stair and ladder costs work in both directions; routes cannot switch floors midair.
- Shooting across open atrium is legal; shooting through a solid floor is blocked.
- Bot reaches the correct level to retrieve each treasure.
- Save/load restores surface IDs, dynamic terrain and occupants.
- Floor destruction and falling resolve to the correct lower surface.
- Selecting and hiding an upper floor reveals lower legal destinations.
- Existing scenarios pass headless simulation and save/load tests unchanged.

Only after these tests pass should the full Silent Tower scenario use stacked
interiors, or the main campaign receive bridges over traversable streets. The
intermediate exposed-surface model remains supported for simple maps.
