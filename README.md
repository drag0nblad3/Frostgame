# Frostgame

A Frostgrave (2nd edition) skirmish simulator for Android phones, built with Godot 4.
Fully automated rules on a 3D table; campaign play to follow. Personal project — Frostgrave
belongs to Osprey Games and Joseph A. McCullough, and no rulebook text is included.

![Bot vs bot game](docs/screenshot.png)

**Status:** milestone 1 — core rules engine (movement, melee, shooting, cover, turns and
phases) with unit tests, and a simple 3D board where the computer plays both warbands.

## Run it
1. Install [Godot 4.5+](https://godotengine.org/download) (standard build, not .NET).
2. Open `project.godot` and press Play.
3. **Step** plays one activation, **Auto** plays on its own, **New game** restarts.
   - Mouse: left-drag orbit, right-drag pan, wheel zoom.
   - Touch: one-finger orbit, two-finger pan, pinch zoom.

## Tests
```sh
godot --headless --import
godot --headless -s tests/run_tests.gd
```

See `CLAUDE.md` for the file map, `docs/rules-coverage.md` for what's implemented and what
still needs checking against the book, and `docs/PLANNING.md` for the roadmap.
