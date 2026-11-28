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
			var score := MagicTactics.value(c, f, t, id)*BotPreference.spell_appeal(f,id)
			if score > best_value and BattleAction.legal(c,"cast",t.id,id):
				best_value = score
				best = {"spell": id, "target": t.id, "score": score}
	for id: String in ["raise_zombie", "summon_demon", "animate_skull"]:
		if not c._magic.available_spell(f, id):
			continue
		var score := (5.5 if id == "summon_demon" else 4.0) * MagicTactics.probability(c, f, id)
		if score <= best_value:
			continue
		if c.state.board.floor_layout.is_empty():
			var points:=c._magic.placement_points(id,true)
			if not points.is_empty():
				best_value=score
				best={"spell":id,"at":points[0],"score":score}
		else:
			var points:=SpellAvailability.floor_placement_points(c._magic,id,true)
			if not points.is_empty():
				best_value=score
				best={"spell":id,"node":points[0],"score":score}
	return best


static func play(c: GameController, f: Figure) -> bool:
	if f.def.role not in ["wizard", "apprentice"] or not c.can_act():
		return false
	var chosen := plan(c, f)
	if chosen.is_empty():
		return false
	var id: String = chosen["spell"]
	if c.state.spellbooks.get(f.side, {}).has(id) and int(c.state.spellbooks[f.side][id]) >= 10 and f.next_cast_gear == "":
		if not BattleEquipmentAction.execute(c,"arm",{"id":"gear_gloves_casting"}):
			BattleEquipmentAction.execute(c,"arm",{"id":"gear_wand_light"})
	var declared := BattleSpellAction.execute(c,"place",{"spell":id,"at":chosen["node"]}) if chosen.has("node") else (BattleSpellAction.execute(c,"place",{"spell":id,"at":chosen["at"]}) if chosen.has("at") else BattleAction.execute(c,"cast",chosen["target"],id))
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
	var id := str(p["id"])
	var budget := PowerPool.available(f,id)+(0 if PowerPool.words_only(f,id) else mini(2,maxi(0,f.health-2)))
	if not p.get("scroll", false) and needed > budget and int(p["raw"]) <= 8:
		if BattleSpellAction.execute(c,"cast_fate"):
			needed = maxi(0, int(p["tn"]) - int(p["total"]))
	if c._magic.can_insure() and (needed > mini(budget, c.cast_max_empowerment()) or (p["id"] == "summon_demon" and p["raw"] == 1)):
		return BattleSpellAction.execute(c,"insure")
	if id=="animate_skull" and not p.get("golden_fang",false) and RedKingMaterials.fang_count(f)>0:
		BattleSpellAction.execute(c,"golden_fang")
	return c.finish_cast(needed if needed <= mini(budget, c.cast_max_empowerment()) else 0)
