class_name MagicBot
extends RefCounted
## Rank legal casts by tactical payoff and risk; never assume a declaration resolved.


static func plan(c: GameController, f: Figure) -> Dictionary:
	var best := {}
	var best_value := 1.5
	for id: String in c._magic.available_spells(f):
		if id not in MagicTactics.ATTACKS + MagicTactics.HINDERS + MagicTactics.BUFFS + ["heal", "true_sight"] and not SummonActions.CONTROL.has(id):
			continue
		for t in c.state.figures:
			if not t.in_play():
				continue
			var score := MagicTactics.value(c, f, t, id)
			if score > best_value and c.can_cast(id, t.id):
				best_value = score
				best = {"spell": id, "target": t.id, "score": score}
	for id: String in ["raise_zombie", "summon_demon", "animate_skull"]:
		if not c._magic.available_spell(f, id):
			continue
		var score := (5.5 if id == "summon_demon" else 4.0) * MagicTactics.probability(c, f, id)
		if score <= best_value:
			continue
		var points := c._magic.placement_points(id, true)
		if not points.is_empty():
			best_value = score
			best = {"spell": id, "at": points[0], "score": score}
	return best


static func play(c: GameController, f: Figure) -> bool:
	if f.def.role not in ["wizard", "apprentice"] or not c.can_act():
		return false
	var chosen := plan(c, f)
	if chosen.is_empty():
		return false
	var id: String = chosen["spell"]
	if c.state.spellbooks.get(f.side, {}).has(id) and int(c.state.spellbooks[f.side][id]) >= 10 and f.next_cast_gear == "":
		if not GearActions.arm(c, "gear_gloves_casting"):
			GearActions.arm(c, "gear_wand_light")
	var declared := c._magic.start_at(id, chosen["at"]) if chosen.has("at") else c.start_cast(id, chosen["target"])
	if not declared:
		return false
	if not c.awaiting_reaction():
		resolve(c)
	return true


static func resolve(c: GameController) -> bool:
	var p := c.state.pending_cast
	if p.is_empty():
		return false
	var f := c.state.figure(p["caster"])
	var needed := maxi(0, int(p["tn"]) - int(p["total"]))
	var budget := PowerPool.available(f) + mini(2, maxi(0, f.health - 2))
	if not p.get("scroll", false) and needed > budget and int(p["raw"]) <= 8:
		if c._magic.reroll_fate():
			needed = maxi(0, int(p["tn"]) - int(p["total"]))
	if c._magic.can_insure() and (needed > mini(budget, c.cast_max_empowerment()) or (p["id"] == "summon_demon" and p["raw"] == 1)):
		return c._magic.insure()
	return c.finish_cast(needed if needed <= mini(budget, c.cast_max_empowerment()) else 0)
