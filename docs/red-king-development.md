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
