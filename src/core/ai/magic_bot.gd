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
	if not c.state.board.floor_layout.is_empty() and c._magic.available_spell(f,"leap"):
		var leap:=leap_plan(c,f,best_value)
		if not leap.is_empty():
			best=leap
	return best


## Rescue endangered allies and advance treasure carriers. Cheap geometric
## ranking comes before expensive arc checks; only a few promising figures
## and destinations are considered, with stable individual preferences.
static func leap_plan(c: GameController,f: Figure,threshold: float=1.5) -> Dictionary:
	var s:=c.state
	var layout:=s.board.floor_geometry()
	var best: Dictionary={}
	var best_value:=threshold
	var targets: Array[Dictionary]=[]
	for t in s.figures:
		if not t.in_play() or t.side!=f.side or t.ring_side!=f.ring_side:
			continue
		var enemies:=_leap_enemies(s,t)
		var threat:=_leap_threat(enemies,Vector3(t.pos.x,t.elevation,t.pos.y))
		var carrier:=t.treasure_id>=0 and t.control_spell!="mind_control"
		if not carrier and threat>5.0:
			continue
		var urgency: float=(3.0 if carrier else 0.0)+maxf(0.0,5.0-threat)+(2.0 if t.health<=5 else 0.0)
		if t!=f and not t.activated:
			urgency-=1.5
		targets.append({"figure":t,"enemies":enemies,"urgency":urgency*BotPreference.appeal(s,f,t.id,"leap_target")})
	targets.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:return a["urgency"]>b["urgency"])
	var probability:=MagicTactics.probability(c,f,"leap")
	for i in mini(3,targets.size()):
		var t: Figure=targets[i]["figure"]
		if not LayeredLeap.eligible(c,t):
			continue
		var origin:=Vector3(t.pos.x,t.elevation,t.pos.y)
		var limit:=5.0 if t.treasure_id>=0 else 10.0
		var enemies: PackedVector3Array=targets[i]["enemies"]
		var threat:=_leap_threat(enemies,origin)
		var edge:=TreasureRules.edge_distance(s.board,t.pos)
		var candidates: Array[Dictionary]=[]
		# Sample a coarse one-inch lattice before scoring, rather than
		# solving every half-inch trajectory.
		for n in BattlePlacement.nodes(s.board,t.pos,limit):
			if posmod(n.x,2)!=0 or posmod(n.y,2)!=0 or layout.surface_id(n).begins_with("climb:"):
				continue
			var at:=layout.world(n)
			var distance:=origin.distance_to(at)
			if distance>limit+0.001 or distance<2.0:
				continue
			var score:=maxf(0.0,minf(8.0,_leap_threat(enemies,at))-minf(8.0,threat))*(0.65+0.55*BotPreference.trait_value(f,"caution"))
			if t.treasure_id>=0 and t.control_spell!="mind_control":
				score+=maxf(0.0,edge-TreasureRules.edge_distance(s.board,layout.point(n)))*(0.9+0.6*BotPreference.trait_value(f,"greed"))
			if t!=f and not t.activated:
				score-=1.5
			score*=probability*BotPreference.appeal(s,f,hash(n),"leap_landing")
			if score>best_value:
				candidates.append({"node":n,"score":score})
		candidates.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:return a["score"]>b["score"])
		var grid:=LayeredGrid.new(layout,t,s.figures)
		for j in mini(12,candidates.size()):
			var choice:=candidates[j]
			if float(choice["score"])<=best_value:
				break
			var n: Vector3i=choice["node"]
			if RedKingVeil.lethal(s,t.pos,layout.point(n)) or LayeredLeap.path(c,t,n,layout,grid).is_empty():
				continue
			best_value=float(choice["score"])
			best={"spell":"leap","target":t.id,"node":n,"score":best_value}
			break
	return best


static func _leap_enemies(s: GameState,t: Figure) -> PackedVector3Array:
	var out:=PackedVector3Array()
	for enemy in s.figures:
		if enemy.in_play() and enemy.side!=t.side and enemy.ring_side==t.ring_side and IllusionRules.visible_to(s.figures,t,enemy):
			out.append(Vector3(enemy.pos.x,enemy.elevation,enemy.pos.y))
	return out


static func _leap_threat(enemies: PackedVector3Array,at: Vector3) -> float:
	var nearest:=8.0
	for enemy in enemies:
		nearest=minf(nearest,at.distance_to(enemy))
	return nearest


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
	var declared := BattleSpellAction.execute(c,"move",{"spell":id,"target":chosen["target"],"at":chosen["node"]}) if id=="leap" else BattleSpellAction.execute(c,"place",{"spell":id,"at":chosen["node"]}) if chosen.has("node") else (BattleSpellAction.execute(c,"place",{"spell":id,"at":chosen["at"]}) if chosen.has("at") else BattleAction.execute(c,"cast",chosen["target"],id))
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
