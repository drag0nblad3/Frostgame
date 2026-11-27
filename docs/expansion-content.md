# Optional rulebook content

Core Frostgrave 2e is always available. Each of the eight warband slots stores its own enabled pack IDs in a separate versioned content JSON file; existing saves without it use core only. New packs default off. Changes apply from Home, before entering an encounter. A battle snapshot records its exact selection, and can resume only with that selection. Changing packs does not delete checkpoints; restore the former selection to resume.

## Register an implemented book

Add an entry under `packs` in `data/expansions.json`. Use a stable slug, a display name, a short original description and an optional `requires` array of other pack slugs. A pack owns newly added IDs, not replacement versions of existing core IDs.

Example (illustrative only; not an installed pack):

```json
{
  "example_book": {
    "name": "Example expansion",
    "description": "Additional expeditions and equipment.",
    "requires": [],
    "content": {
      "scenarios": ["example_expedition"],
      "figures": ["example_soldier"],
      "spells": ["example_spell"],
      "potions": ["example_potion"],
      "magic_equipment": ["gear_example"],
      "base_resources": ["example_upgrade"],
      "rules": ["example_optional_rule"]
    },
    "briefings": {
      "example_expedition": ["Example Expedition", "Short original summary.", "Original scenario rule explanation."]
    }
  }
}
```

Put definitions in the corresponding existing JSON catalogs and scenario/board files. Add the actual rule implementation, original explanations, model support and tests before registering the pack. Keep all definitions resolvable for checkpoint validation and historical references. The selection gate applies when choosing scenarios, new recruits, spells, purchases, and base upgrades. Additional categories recognized by the profile are `weapons`, `schools`, `boards`, `terrain`, and `bases`; when implementing a pack, gate its new creation paths explicitly (including scripted scenario spawns, spell effects, random encounter/loot tables, rituals, and alternate campaigns). Base tables are not automatically extended by catalog additions. Do not add optional entries to core scenario data or hardcoded core reward tables. A pack that requires a new dependency should declare it in `requires`.

Optional mechanics must test `state.content_profile.rule("example_optional_rule")` or `ContentProfile.from_campaign(data).rule(...)`. Unregistered optional rules return false. General `allows(category,id)` returns true for unowned core IDs. Multi-book ownership requires all owning packs.

Disabling a pack scans the saved draft and campaign for references to its content IDs, including historical members, and refuses changes that could break those records. Campaign-rule packs cannot be removed after the first completed battle, pending a pack-specific migration. No destructive automatic replacement is performed. Pack migration, revised core rules, and actual expansion-specific systems need individual implementation when the books are supplied.

Tests: add pack fixtures for each new catalog and rule gate; check enabled/disabled saves, deterministic core outcomes, saved battle resume, and dependencies.

A pack may declare `status: development` while being built. The dialog displays it disabled, profile validation refuses it, and its owned content is excluded even if a manually edited save requests it. Change to `ready` only after all exposed content is verified.


A pack may also declare `status: playtest` to expose a playable but not fully validated implementation. It is selectable per save, defaults off, and has the same dependency and save safety checks as a ready pack. The dialog marks it Playtest. The Red King uses this status while its remaining digital approximations and advanced edge cases are reviewed. The rescue-linked Mindscape is available in the ordered story or as a standalone skirmish, not an ordinary campaign mission.
