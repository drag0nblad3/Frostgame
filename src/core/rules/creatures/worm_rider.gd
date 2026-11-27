class_name WormRider
extends RefCounted
const ITEM := "gear_rk_gloves_of_the_worm_rider"


static func ignored(worm: Figure,target: Figure) -> bool:
	return worm!=null and target!=null and worm.def.id=="giant_worm" and worm.side<0 and ActiveGear.has(target,ITEM) and not MagicEquipment.suppressed(target)


static func ready(c: GameController) -> bool:
	var f := c.state.active()
	return f!=null and f.def.role in ["wizard","apprentice"] and c.can_act() and ActiveGear.ready(f,ITEM) and c.state.creature_db!=null and not Contact.in_combat(c.state.figures,f)


static func legal(c: GameController,at: Vector2,ring: int) -> bool:
	if not c.state.board.floor_layout.is_empty():
		return ground_node(c,at)!=null and not ScenarioNull.field_at(c.state.board,at)
	if not c.state.board.can_stand(at,Figure.BASE_RADIUS):
		return false
	var h := c.state.board.height_at(at)
	for f in c.state.figures:
		if f.in_play() and f.ring_side==ring and absf(f.elevation-h)<0.5 and f.pos.distance_to(at)<Contact.OVERLAP:
			return false
	return true


## A burrowing worm emerges on the table's ground, never through a roof.
static func ground_node(c: GameController,at: Vector2) -> Variant:
	for id: String in c.state.board.floor_layout.get("exit_surfaces",["street"]):
		var n: Variant=BattlePlacement.support(c.state,at,id)
		if n!=null:
			return n
	return null


static func world_point(c: GameController,at: Vector2) -> Vector3:
	var n: Variant=ground_node(c,at)
	return c.state.board.floor_geometry().world(n) if n!=null else Vector3(at.x,0,at.y)


static func points(c: GameController) -> Array[Vector2]:
	var out: Array[Vector2]=[]
	if not ready(c):
		return out
	var ring := c.state.active().ring_side
	for x in range(1,int(c.state.board.size.x)):
		for y in range(1,int(c.state.board.size.y)):
			var at := Vector2(x,y)
			if legal(c,at,ring):
				out.append(at)
	return out


static func summon(c: GameController,at: Vector2) -> bool:
	if not ready(c) or not legal(c,at,c.state.active().ring_side):
		return false
	var f := c.state.active()
	if not ActiveGear.spend(f,ITEM):
		return false
	c._spend(f)
	var roll := c.dice.d20()
	c.emit("gear_used",{"id":f.id,"gear":ITEM,"roll":roll})
	if roll!=1 and roll<17:
		return true
	if roll==1:
		if c.state.reaction_side>=0 and c.state.reaction_side!=f.side:
			c.state.scenario_data["rk_worm_relocation"]={"id":f.id,"at":at,"ring":f.ring_side}
			c.emit("worm_relocation_offer",{"id":f.id,"at":at})
			return true
		# Rival relocates the token toward the summoner's warband.
		var best := INF
		var selected := at
		for x in range(1,int(c.state.board.size.x)):
			for y in range(1,int(c.state.board.size.y)):
				var candidate := Vector2(x,y)
				if not legal(c,candidate,f.ring_side):
					continue
				for ally in c.state.figures:
					if ally.in_play() and ally.side==f.side and not ActiveGear.has(ally,ITEM) and ally.ring_side==f.ring_side:
						var distance := candidate.distance_to(ally.pos)
						if distance<best:
							best=distance
							selected=candidate
		at=selected
	_place_token(c,at,f.ring_side)
	return true


static func relocation_points(c: GameController) -> Array[Vector2]:
	var out: Array[Vector2]=[]
	var offer: Dictionary=c.state.scenario_data.get("rk_worm_relocation",{})
	if offer.is_empty():
		return out
	for x in range(1,int(c.state.board.size.x)):
		for y in range(1,int(c.state.board.size.y)):
			var at := Vector2(x,y)
			if legal(c,at,int(offer["ring"])):
				out.append(at)
	return out


static func answer_relocation(c: GameController,at: Vector2) -> bool:
	var offer: Dictionary=c.state.scenario_data.get("rk_worm_relocation",{})
	if offer.is_empty() or not relocation_points(c).has(at):
		return false
	c.state.scenario_data.erase("rk_worm_relocation")
	_place_token(c,at,int(offer["ring"]))
	return true


static func _place_token(c: GameController,at: Vector2,ring: int) -> void:
	var pending: Array=c.state.scenario_data.get("rk_worm_tokens",[])
	pending.append({"at":at,"ring":ring})
	c.state.scenario_data["rk_worm_tokens"]=pending
	var kind := TerrainKind.new()
	kind.id="rk_worm_token"
	kind.name="Worm summoning token"
	kind.height=0.02
	var marker := TerrainPiece.new(kind,Rect2(at-Vector2(0.3,0.3),Vector2(0.6,0.6)))
	marker.circular=true
	if not c.state.board.floor_layout.is_empty():
		var n: Variant=ground_node(c,at)
		if n!=null:
			marker.surface_id=c.state.board.floor_geometry().surface_id(n)
			marker.base_height=c.state.board.floor_geometry().height(n)
	c.state.board.pieces.append(marker)
	c.state.board.invalidate_terrain()
	c.emit("terrain_changed",{"spell":"worm_rider","created":true})


static func end_turn(c: GameController) -> void:
	var pending: Array=c.state.scenario_data.get("rk_worm_tokens",[])
	if pending.is_empty():
		return
	c.state.scenario_data.erase("rk_worm_tokens")
	for p in c.state.board.pieces.duplicate():
		if p.kind.id=="rk_worm_token":
			c.state.board.pieces.erase(p)
	c.state.board.invalidate_terrain()
	c.emit("terrain_changed",{"spell":"worm_rider","created":false})
	for entry: Dictionary in pending:
		var at: Vector2=entry["at"]
		var ring := int(entry["ring"])
		var best := INF
		var chosen := at
		for x in range(-6,7):
			for y in range(-6,7):
				var p := at+Vector2(x,y)*0.5
				var distance := p.distance_squared_to(at)
				if distance<best and legal(c,p,ring):
					best=distance
					chosen=p
		if is_finite(best):
			if not c.state.board.floor_layout.is_empty():
				var n: Variant=ground_node(c,chosen)
				if n!=null:
					var layout:=c.state.board.floor_geometry()
					c._encounters._spawn_at("giant_worm",chosen,-1,ring,layout.surface_id(n),layout.height(n))
			else:
				c._encounters._spawn_at("giant_worm",chosen,-1,ring)
