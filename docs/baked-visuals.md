# Build-time visual assets

The procedural sculpt and scenery code remains the source of truth. The build
runner converts it into compressed binary Godot PackedScenes under
`assets/baked/`, which is ignored in git. The Android export runs this step
before packaging; CI also generates a standalone asset artifact without an APK.

Run locally (after importing the project, with a real graphics driver):
```sh
godot --headless --import
godot --rendering-method gl_compatibility -s tools/bake_visuals.gd
godot --headless --import
```
On Linux without a display, use `xvfb-run -a` and software GL. Append
`-- smoke` for a tiny sample. Remove the generated directory before rebaking
after changing visual source or data.

Coverage: core and enabled expansion scenario outskirts for all three quality
settings, the cinematic title city, standard deployments at Balanced, default
skirmish deployment at all settings, and neutral creatures at all settings.
Indoor/training city generation is skipped. Exact model matching includes
identity, equipment, school, side color, armour, traits, and detail level.
Nonmatching custom models and missing assets use procedural generation.
The packed scenes preserve independent joint nodes and immutable mesh resources;
invisibility still applies per-instance material overrides.

These are render resources, not game states. Terrain collision, movement,
objectives, spells and saves continue to use live board data. On-board terrain
and unusual custom equipment are still generated at runtime. GPU shader
compilation and mesh uploads can still cause first-use latency.
