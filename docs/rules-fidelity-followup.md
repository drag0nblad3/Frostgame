# Rules fidelity follow-up (2026-11-28)

This is a continuation of the November 27 audit, not certification of complete rulebook fidelity.

- Core 38–39: shared seeded placement with a legal near-centre anchor and 3D distances; live setup permits alternating human/AI token placement, then rolls for starting edges. Special scenario anchors are retained. Automatic setup remains available. Legal standing alone does not prove global reachability.
- Core 148–151: player chooses genie/worm spawn and Keep landing; may decline free temple treasure. Shared pending decision state and legal-position selection apply to both geometry systems. Genie delayed emergence when no legal position exists is a digital fallback.
- Core 51: shallow/deep water terrain, activation swimming roll, basic armour/shield/treasure modifiers, fight penalty, bow restrictions, movement/AI exemptions. Core soldier armour is mapped by figure identity; expansion/custom equipment combinations and all activation exceptions still need testing. No new authored water map in this change.
- Core 57–58: sample head and torso visibility and physical target contact for terrain cover. This is a geometric proxy, not animated mesh visibility. Special topology and exceptional spells need independent verification.
- Core 45–50: generated climb links on both long and short faces of layered walkable walls; heightfield arbitrary climbs, hanging combat and continuous movement remain incomplete.
- Core 70: deliberate creature pursuit no longer repeats a move when it has not reached combat; ordinary layered creature routine ends after attacking. Random movement and special creature traits need further parity tests.
- Core 85, 106: primary treasure table checked and all twenty rows tested; reserve selection already exists in BaseUpgradePanel and is used in campaign deployment. Individual magic-item subtables, injury tables, spell timings, and Red King conditional rules are not certified by this check.

Remaining: all-edge reachability/concealment across seeds, broader climbing/jump/swim validation, smaller-table/multiplayer deployment, reactive weapon choices, spell-by-spell and item-by-item comparisons, campaign subtables, and Red King scenario/Reality Crack exceptions. Keep pending CI results distinct from completed tests.

## Follow-up

- Sunken Streets (custom map): two shallow/deep pools, matching visual footprints, water status and swimming roll log, no water movement surcharge on elevated platforms. Other named maps unchanged.
- Core scenario choice records can be saved and restored when no suspended combat/cast/interception callback is pending; free collection eligibility shared by offer and execution. Floor-filtered markers prevent selecting a hidden floor.
- Partial sight fallback respects solid special portal/orb obstruction. Further expansion geometry and body cover cases remain open.
- Test runner logs individual test starts/failures to identify slow or hanging tests. Full suite not yet verified.

- Core pp.33,68,97,121: ordinary opposed melee offers a human combatant a weapon choice before dice, including defenders; AI compares eligible weapon effects. Encumbrance checks all surviving carried weapons. Enchanted bows/crossbows retain accuracy bonuses but ordinary ammunition is not a magical attack; enchanted ammunition is a separate option. Full weapon-specific Enchant Weapon targeting and magic-item exceptions remain to audit.

- Core pp.97,121: Enchant Weapon now declares one carried weapon before the casting roll. Separate weapon enchantments can coexist, switching weapons does not transfer effects, and Dispel/Spell Eater remove a chosen enchantment. Embed Enchantment records the actual weapon. Legacy boolean effects migrate to the previously selected weapon. AI/default API chooses a legal weapon automatically. Individual magical weapon bonus combinations still require review.
