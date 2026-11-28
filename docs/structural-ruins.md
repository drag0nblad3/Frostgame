# Structural ruin kits

A `pieces` entry can specify `ruin_kit`, `rect: [x,y,w,h]`, and optional `quarter_turns` instead of a single terrain kind. Shared normalized kits live in `data/ruin_kits.json`. They expand in authored order to the same TerrainPiece objects used by normal and layered boards. Heights are existing ruin (4), broken wall (2.75), hut wall (2), low wall (1), and rough debris (0.4). Missing walls have no collision volume, not fake painted doors. Low walls use the existing rough/cover rules. Quarter turns rotate the normalized layout before fitting into the rectangle.

Initial conversions: Frozen Ruins (five main buildings), Sunken Streets (four corner buildings), The Keep (six peripheral buildings). All stay within original obstacle rectangles. Other scenario landmarks and ground profiles are unchanged. This is an initial structural conversion, not full polygonal or arbitrary-angle architecture. Multi-story openings and overhead arches require separately authored floor solids and are future work. Existing saved battles retain their serialized terrain.

Validation: deterministic footprint/rotation, traversable interior and sight through a real breach, blocking wall, and map integration tests. Also run existing deployment and objective checks and review visual previews before merging.

Second conversion: four outer ruins each in Dreams Well, Genie in the Bottle, Worm Hunts, Living Museum, Mausoleum and the Red King Squatter. Keep special central structures, exits, hazards, objective locations and authored terrain extent unchanged. 39 converted buildings across nine boards in total.
