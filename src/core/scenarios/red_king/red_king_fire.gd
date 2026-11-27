class_name RedKingFire
extends RefCounted
## Act II, Back Into the Fire (Red King pp.34–35).
const ID := "red_king_back_into_fire"
const PORTAL := "red_king_portal"


static func active(s: GameState) -> bool:
	return s!=null and s.scenario_special==ID


static func locked(s: GameState,token: TreasureToken) -> bool:
	return active(s) and token!=null and token.central and token.frozen


static func unlock_bonus(f: Figure) -> int:
	return 5 if f.def.id in ["thief","treasure_hunter"] or f.def.role in ["wizard","apprentice"] else 0


static func can_unlock(c: GameController,token: TreasureToken) -> bool:
	var f := c.state.active()
	return locked(c.state,token) and token.on_ground() and f!=null and f.side>=0 and c.can_act() and not Contact.in_combat(c.state.figures,f) and not IllusionRules.phantom(f) and not f.spell_effects.has("plane_walk") and TreasureRules.in_reach(c.state,f,token,Figure.BASE_RADIUS+TreasureRules.TOKEN_RADIUS+0.01)


static func unlock(c: GameController,f: Figure,token: TreasureToken) -> bool:
	if not can_unlock(c,token):
		return false
	c._spend(f)
	var raw := c.dice.d20()
	var bonus := unlock_bonus(f)
	var passed := StatRoll.succeeds(raw,f.effective_will()+f.roll_penalty()+bonus,16)
	c.emit("artefact_unlock",{"id":f.id,"roll":raw,"bonus":bonus,"success":passed})
	if passed:
		token.frozen=false
		c._loot.claim_free(f,token)
	return true


static func portals(s: GameState) -> Array[TerrainPiece]:
	var result: Array[TerrainPiece]=[]
	for p in s.board.pieces:
		if p.kind.id==PORTAL:
			result.append(p)
	return result


## The same contact rule accepts real route elevations for explicit floors.
static func portal_hits(s: GameState,from: Vector2,to: Vector2,seen: Dictionary,from_height: float=NAN,to_height: float=NAN) -> Array[TerrainPiece]:
	var hits: Array[TerrainPiece]=[]
	if not active(s):
		return hits
	for p in portals(s):
		var center:=p.rect.get_center()
		var reach:=p.rect.size.x*0.5+Figure.BASE_RADIUS
		var closest:=Geometry2D.get_closest_point_to_segment(center,from,to)
		if seen.has(p) or center.distance_to(closest)>reach+0.001:
			continue
		if not s.board.floor_layout.is_empty() and not is_nan(from_height) and not is_nan(to_height):
			var h:=lerpf(from_height,to_height,clampf(from.distance_to(closest)/maxf(from.distance_to(to),0.001),0.0,1.0))
			if h>=p.base_height+p.kind.height or h+1.6<=p.base_height:
				continue
		if from.distance_to(center)<=reach+0.001 and to.distance_to(center)>from.distance_to(center):
			continue
		hits.append(p)
	return hits


static func portal_contact(c: GameController,f: Figure,from: Vector2,to: Vector2,seen: Dictionary,from_height: float=NAN,to_height: float=NAN) -> void:
	if not f.in_play():
		return
	for p in portal_hits(c.state,from,to,seen,from_height,to_height):
		seen[p]=true
		var damage:=RedKingElemental.reduce(c,f,maxi(0,5-CreatureEffects.elemental_resistance(f)))
		c.emit("portal_contact",{"id":f.id,"amount":damage})
		c._hurt(f,damage,f,true)
		if not f.in_play():
			return


static func end_turn(c: GameController) -> void:
	var s := c.state
	if not active(s) or s.turn<2 or s.turn>8 or s.creature_db==null or not s.creature_db.available("hrut_warrior"):
		return
	var gates := portals(s)
	if gates.is_empty():
		return
	var gate := gates[c.dice.pick(gates.size())]
	var origin := gate.rect.get_center()
	var targets: Array[Figure]=[]
	for f in s.figures:
		if f.side>=0 and f.in_play() and (not f.spell_effects.has("invisibility") or f.def.role in ["wizard","apprentice"]):
			targets.append(f)
	targets.sort_custom(func(a: Figure,b: Figure) -> bool:return a.pos.distance_squared_to(origin)<b.pos.distance_squared_to(origin))
	var desired := targets[0].pos if not targets.is_empty() else origin+Vector2.UP*3.0
	if not s.board.floor_layout.is_empty():
		var layout:=s.board.floor_geometry()
		var best_floor: Variant=null
		var value:=INF
		for n in BattlePlacement.nearby_floor(s,origin,gate.base_height,3.0,gate.surface_id):
			var at:=layout.point(n)
			var radius:=at.distance_to(origin)
			var score:=radius*100.0+at.distance_to(desired)
			if radius>=1.5 and score<value:
				best_floor=n
				value=score
		if best_floor!=null:
			c._encounters._spawn_on_floor("hrut_warrior",best_floor)
			c.emit("portal_emergence",{"at":origin})
		return
	var grid := MoveGrid.new(s.board,null,s.figures)
	var best: Variant=null
	var score := INF
	var center := MovePlanner.node_at(origin)
	for x in range(-6,7):
		for y in range(-6,7):
			var n := center+Vector2i(x,y)
			var at := MoveGrid.to_pos(n)
			var radius := at.distance_to(origin)
			if radius<1.5 or radius>3.0 or not grid.open(n):
				continue
			var value := radius*100.0+at.distance_to(desired)
			if value<score:
				best=n
				score=value
	if best!=null:
		c._encounters._spawn_at("hrut_warrior",MoveGrid.to_pos(best))
		c.emit("portal_emergence",{"at":origin})


static func exit_allowed(s: GameState,at: Vector2) -> bool:
	var edge := Figure.BASE_RADIUS+0.01
	var x := minf(at.x,s.board.size.x-at.x)
	var y := minf(at.y,s.board.size.y-at.y)
	return (x<=edge and y<=3.0) or (y<=edge and x<=3.0)
