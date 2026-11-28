class_name ScenarioObjectives
extends RefCounted
## Scenario-specific actions and creature emergence.


static func well(s: GameState) -> TerrainPiece:
	if s.scenario_special == "dreams_well":
		for p in s.board.pieces:
			if p.kind.id == "dreams_well":
				return p
	return null


static func inside_well(s: GameState, at: Vector2,height: float=NAN) -> bool:
	var p := well(s)
	return p!=null and p.contains(at) and (is_nan(height) or absf(height-p.base_height)<0.5)


static func can_drink(c: GameController) -> bool:
	var f := c.state.active()
	var p := well(c.state)
	if f == null or p == null or not c.can_act() or f.def.role not in ["wizard", "apprentice"] or c.state.well_drinkers.has(f.id) or Contact.in_combat(c.state.figures, f):
		return false
	return absf(f.elevation-p.base_height)<0.5 and f.pos.distance_to(p.rect.get_center()) <= p.rect.size.x * 0.5 + Figure.BASE_RADIUS + 0.1


static func drink(c: GameController) -> bool:
	if not can_drink(c):
		return false
	var f := c.state.active()
	c._spend(f)
	c.state.well_drinkers[f.id] = true
	c.emit("well_drink", {"id": f.id, "side": f.side, "xp": 50 if f.def.role == "wizard" else 30})
	return true


static func spawn_worm(c: GameController) -> void:
	var s := c.state
	if s.scenario_special != "worm_hunts" or s.worm_spawned or s.creature_db == null:
		return
	var collected := 0
	var candidates: Array[TreasureToken] = []
	for token in s.treasures:
		if token.ever_collected:
			collected += 1
		if token.unresolved():
			candidates.append(token)
	if candidates.is_empty() or c.dice.d20() + collected < 16:
		return
	var token := candidates[c.dice.pick(candidates.size())]
	var carrier := s.figure(token.carrier_id)
	var origin := carrier.pos if carrier != null else token.pos
	var options: Array[Dictionary]=[]
	var height:=carrier.elevation if carrier!=null else TreasureRules.token_height(s,token)
	if is_nan(height):
		return
	var limit:=2.0*Figure.BASE_RADIUS if carrier!=null else Figure.BASE_RADIUS+TreasureRules.TOKEN_RADIUS
	var closest:=INF
	if not s.board.floor_layout.is_empty():
		var support:=carrier.surface_id if carrier!=null else token.surface_id
		var layout:=s.board.floor_geometry()
		for n in BattlePlacement.nearby_floor(s,origin,height,1.5,support):
			var distance:=layout.point(n).distance_to(origin)
			if distance<limit-0.001:
				continue
			closest=minf(closest,distance)
			options.append(CoreScenarioChoice.point(s,layout.point(n),layout.surface_id(n)))
	else:
		var grid:=MoveGrid.new(s.board,null,s.figures)
		var center:=MovePlanner.node_at(origin)
		for x in range(-3,4):
			for y in range(-3,4):
				var n:=center+Vector2i(x,y)
				var at:=MoveGrid.to_pos(n)
				var distance:=at.distance_to(origin)
				if distance<limit-0.001 or distance>1.5 or not grid.open(n) or absf(s.board.height_at(at)-height)>=0.5:
					continue
				closest=minf(closest,distance)
				options.append(CoreScenarioChoice.point(s,at))
	if options.is_empty():
		return
	var near: Array[Dictionary]=[]
	for p in options:
		var at: Vector2=p["at"]
		if at.distance_to(origin)<=closest+0.25:
			near.append(p)
	var owner:=s.order[0] if not s.order.is_empty() else -1
	if CoreScenarioChoice.offer(c,"worm",owner,-1,token.id,0,near):
		return
	var p:=CoreScenarioChoice.tactical(c,owner,near)
	var worm:=CoreScenarioChoice._spawn(c,"giant_worm",p)
	s.worm_spawned=true
	c.emit("worm_emerges",{"id":worm.id,"treasure":token.id})



static func can_break_ice(c: GameController) -> bool:
	var f := c.state.active()
	var token := c.state.treasure(0)
	return c.state.scenario_special == "underground_library" and f != null and token != null and token.frozen and token.on_ground() and c.can_act() and not Contact.in_combat(c.state.figures, f) and not IllusionRules.phantom(f) and TreasureRules.in_reach(c.state,f,token,Figure.BASE_RADIUS+TreasureRules.TOKEN_RADIUS+0.01)


static func break_ice(c: GameController) -> bool:
	if not can_break_ice(c):
		return false
	var f := c.state.active()
	var raw := c.dice.d20()
	var success := StatRoll.succeeds(raw, f.effective_fight() + f.roll_penalty(), 14)
	c._spend(f)
	if success:
		c.state.treasure(0).frozen = false
	c.emit("break_ice", {"id": f.id, "roll": raw, "success": success})
	return true


static func exit_distance(s: GameState, at: Vector2) -> float:
	if s.scenario_special != "underground_library":
		return TreasureRules.edge_distance(s.board, at)
	var size := s.board.size
	var distance := INF
	for door: Vector2 in [Vector2(size.x * 0.5, 0), Vector2(size.x * 0.5, size.y), Vector2(0, size.y * 0.5), Vector2(size.x, size.y * 0.5)]:
		distance = minf(distance, at.distance_to(door))
	return distance


static func exit_allowed(s: GameState, at: Vector2,side: int=-1) -> bool:
	if RealityCracks.blocks_exit(s):
		return false
	if RedKingRingworld.active(s):
		return false
	if RedKingBridge.active(s):
		return RedKingBridge.exit_allowed(s,at)
	if RedKingTethers.active(s) and RedKingTethers.remaining(s)>0:
		return false
	if RedKingHerded.active(s):
		return at.y>=s.board.size.y-Figure.BASE_RADIUS-0.01
	if RedKingFire.active(s):
		return RedKingFire.exit_allowed(s,at)
	if RedKingVeil.active(s):
		return RedKingVeil.exit_allowed(s,at,side)
	if RedKingInvestigations.active(s):
		return RedKingInvestigations.exit_allowed(s,at,side)
	if s.scenario_special != "underground_library":
		return true
	var size := s.board.size
	var margin := Figure.BASE_RADIUS + 0.01
	return ((at.y <= margin or at.y >= size.y - margin) and absf(at.x - size.x * 0.5) <= 3.0) or ((at.x <= margin or at.x >= size.x - margin) and absf(at.y - size.y * 0.5) <= 3.0)


static func library_roll(raw: int, dice: Dice) -> int:
	return dice.d20() if raw in [1, 2, 3, 4, 5, 8, 9, 10, 11, 12, 13] else raw
