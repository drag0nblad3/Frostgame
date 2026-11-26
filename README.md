# Frostgame

A Frostgrave (2nd edition) skirmish simulator for Android phones, built with Godot 4.
Fully automated rules on a 3D table; campaign play to follow. Personal project — Frostgrave
belongs to Osprey Games and Joseph A. McCullough, and no rulebook text is included.

![Bot vs bot game](docs/screenshot.png)

**Status:** milestone 2 — playable human-vs-bot treasure skirmish, with movement and combat, optional bot-vs-bot observation, and automated rules tests. Magic and campaign play are still in development.

## Run it
1. Install [Godot 4.5+](https://godotengine.org/download) (standard build, not .NET).
2. Open `project.godot` and press Play.
3. You control the blue Elementalist warband. Tap a marked figure to activate it, choose an enabled action, and tap a marked destination or target. Reload and End execute directly. The rival plays automatically.
   - Move marks reachable ground. Fight and Shoot mark legal enemies. Collect, Drop and Exit mark their legal positions.
   - Watch switches to bot-vs-bot play between activations; Step and Auto are available there. New game restarts.
   - Mouse: click to select, left-drag orbit, right-drag pan, wheel zoom.
   - Touch: tap to select, one-finger drag orbit, two-finger pan, pinch zoom.

## Tests
```sh
godot --headless --import
godot --headless -s tests/run_tests.gd
```

See `CLAUDE.md` for the file map, `docs/rules-coverage.md` for what's implemented and what
still needs checking against the book, and `docs/PLANNING.md` for the roadmap.
