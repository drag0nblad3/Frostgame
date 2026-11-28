class_name MagicBot
extends RefCounted
## Rank legal casts by tactical payoff and risk; never assume a declaration resolved.


static func plan(c: GameController, f: Figure) -> Dictionary:
	var best := {}
	var best_value := 1.5
	var threats: Dictionary={}
	for id: String in c._magic.available_spells(f):
		if id not in MagicTactics.ATTACKS + MagicTactics.HINDERS + MagicTactics.BUFFS + ["heal", "true_sight"] and not SummonActions.CONTROL.has(id):
			continue
		var probability:=MagicTactics.probability(c,f,id)
		var appeal:=BotPreference.spell_appeal(f,id)
		for t in c.state.figures:
			if not t.in_play():
				continue
			if id in MagicTactics.BUFFS and t.side==f.side and not threats.has(t.id):
				threats[t.id]=MagicTactics.near_enemy(c.state,t)
			var start:=c.ai_begin()
			var score := MagicTactics.value(c,f,t,id,float(threats.get(t.id,-1.0)),probability)*appeal
			c.ai_end("magic_score",start)
			if score<=best_value:
				continue
			start=c.ai_begin()
			var legal:=BattleAction.legal(c,"cast",t.id,id)
			c.ai_end("magic_legality",start)
			if legal:
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
		var start:=c.ai_begin()
		var leap:=leap_plan(c,f,best_value)
		c.ai_end("magic_leap",start)
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
	var exits: Array[PackedVector3Array]=[]
	if targets.any(func(entry: Dictionary) -> bool:return entry["figure"].treasure_id>=0 and entry["figure"].control_spell!="mind_control"):
		exits=_leap_exit_segments(s,layout,f.side)
	for i in mini(3,targets.size()):
		var t: Figure=targets[i]["figure"]
		if not LayeredLeap.eligible(c,t):
			continue
		var origin:=Vector3(t.pos.x,t.elevation,t.pos.y)
		var limit:=5.0 if t.treasure_id>=0 else 10.0
		var enemies: PackedVector3Array=targets[i]["enemies"]
		var threat:=_leap_threat(enemies,origin)
		var edge:=_leap_exit_distance(exits,origin)
		var candidates: Array[Dictionary]=[]
		var air_candidates: Array[Dictionary]=[]
		var caution:=BotPreference.trait_value(f,"caution")
		var greed:=BotPreference.trait_value(f,"greed")
		# Rank the eventual landing; airborne options can reach lower floors
		# beyond the direct 3D spell range. The fall itself is not spell travel.
		for n in BattlePlacement.nodes(s.board,t.pos,limit):
			if posmod(n.x,2)!=0 or posmod(n.y,2)!=0 or layout.surface_id(n).begins_with("climb:"):
				continue
			var at:=layout.world(n)
			var horizontal:=t.pos.distance_to(layout.point(n))
			if horizontal>limit+0.001 or origin.distance_to(at)<2.0:
				continue
			var score:=maxf(0.0,minf(8.0,_leap_threat(enemies,at))-minf(8.0,threat))*(0.65+0.55*caution)
			if t.treasure_id>=0 and t.control_spell!="mind_control" and is_finite(edge):
				score+=maxf(0.0,edge-_leap_exit_distance(exits,at))*(0.9+0.6*greed)
			if t!=f and not t.activated:
				score-=1.5
			var appeal:=BotPreference.appeal(s,f,hash(n),"leap_landing")
			var direct_score:=score*probability*appeal
			if direct_score<=best_value:
				continue
			if origin.distance_to(at)<=limit+0.001:
				candidates.append({"node":n,"score":direct_score})
			if at.y>=origin.y-0.5:
				continue
			# A minimal lift above the destination keeps fall damage low;
			# one higher endpoint can clear a ledge if the shallow arc cannot.
			var minimum:=maxf(0.5,ceilf((origin.y-at.y-sqrt(maxf(0.0,limit*limit-horizontal*horizontal)))*2.0)*0.5)
			for offset: float in [minimum,maxf(minimum,origin.y-at.y)]:
				var endpoint:=at+Vector3.UP*offset
				if origin.distance_to(endpoint)>limit+0.001:
					continue
				var damage:=LayeredFall.damage(s,t,offset)
				if damage>=t.health or (damage>0 and t.treasure_id>=0):
					continue
				var value: float=(score-0.35-float(damage)*(1.25+1.75*caution))*probability*appeal
				if value>best_value and (air_candidates.is_empty() or air_candidates[-1].get("endpoint")!=endpoint):
					air_candidates.append({"node":n,"endpoint":endpoint,"score":value})
		candidates.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:return a["score"]>b["score"])
		air_candidates.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:return a["score"]>b["score"])
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
		# Independently bound airborne checks. A safe direct landing wins a
		# tie, and the actual first support must match the scored destination.
		for j in mini(8,air_candidates.size()):
			var choice:=air_candidates[j]
			if float(choice["score"])<=best_value:
				break
			var n: Vector3i=choice["node"]
			if RedKingVeil.lethal(s,t.pos,layout.point(n)) or (RedKingHerded.active(s) and minf(t.pos.y,layout.point(n).y)<=float(s.scenario_data.get("herd_veil",0.0))+Figure.BASE_RADIUS):
				continue
			var air:=LayeredLeap.air_plan(c,t,choice["endpoint"],layout,grid)
			if air.is_empty() or air["node"]!=n:
				continue
			best_value=float(choice["score"])
			best={"spell":"leap","target":t.id,"node":n,"air_endpoint":choice["endpoint"],"score":best_value}
			break

	return best


## Compress contiguous legal edge nodes into short 3D segments. This uses
## the scenario's actual exit predicate and extraction floors rather than
## rewarding movement towards a sealed wall or a forbidden side.
static func _leap_exit_segments(s: GameState,layout: FloorLayout,side: int) -> Array[PackedVector3Array]:
	var out: Array[PackedVector3Array]=[]
	if RealityCracks.id(s)==12:
		var center:=s.board.size*0.5
		for n: Vector3i in layout.nodes_at(center):
			if layout.standable(n):
				var point:=layout.world(n)
				out.append(PackedVector3Array([point,point]))
		return out
	if RealityCracks.blocks_exit(s) or RedKingRingworld.active(s) or RedKingMind.active(s):
		return out
	var allowed: Array=s.board.floor_layout.get("exit_surfaces",["street"])
	var margin:=Figure.BASE_RADIUS
	var low:=ceili(margin/MoveGrid.STEP)
	var high:=Vector2i(floori((s.board.size.x-margin)/MoveGrid.STEP),floori((s.board.size.y-margin)/MoveGrid.STEP))
	for index in layout.surfaces.size():
		if not allowed.has(layout.surfaces[index].id):
			continue
		for edge in 4:
			var horizontal:=edge<2
			var fixed:=low if edge%2==0 else (high.y if horizontal else high.x)
			var run:=PackedVector3Array()
			for step in range(low,(high.x if horizontal else high.y)+1):
				var n:=Vector3i(step,fixed,index) if horizontal else Vector3i(fixed,step,index)
				if not LayeredLoot.is_exit(s,layout,n,side) or s.board.over_void(layout.point(n),Figure.BASE_RADIUS):
					if not run.is_empty():
						out.append(PackedVector3Array([run[0],run[-1]]))
						run.clear()
					continue
				var at:=layout.world(n)
				if not run.is_empty() and not is_equal_approx(at.y,run[-1].y):
					out.append(PackedVector3Array([run[0],run[-1]]))
					run.clear()
				run.append(at)
			if not run.is_empty():
				out.append(PackedVector3Array([run[0],run[-1]]))
	return out


static func _leap_exit_distance(exits: Array[PackedVector3Array],at: Vector3) -> float:
	var best:=INF
	for segment in exits:
		var delta:=segment[1]-segment[0]
		var ratio:=clampf((at-segment[0]).dot(delta)/delta.length_squared(),0.0,1.0) if not delta.is_zero_approx() else 0.0
		best=minf(best,at.distance_to(segment[0]+delta*ratio))
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
	var declared := BattleSpellAction.execute(c,"leap_air",{"spell":id,"target":chosen["target"],"at":chosen["air_endpoint"]}) if chosen.has("air_endpoint") else BattleSpellAction.execute(c,"move",{"spell":id,"target":chosen["target"],"at":chosen["node"]}) if id=="leap" else BattleSpellAction.execute(c,"place",{"spell":id,"at":chosen["node"]}) if chosen.has("node") else (BattleSpellAction.execute(c,"place",{"spell":id,"at":chosen["at"]}) if chosen.has("at") else BattleAction.execute(c,"cast",chosen["target"],id))
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
