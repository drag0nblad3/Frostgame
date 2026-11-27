class_name RealityCrackTerrain
extends RefCounted
## Dynamic obstacle and terrain relocation effects (13, 15, 16).


static func _disc(s: GameState,id: String) -> TerrainPiece:
	for p in s.board.pieces:
		if p.kind.id==id:
			return p
	return null


static func _make_disc(c: GameController,id: String,center: Vector2,radius: float) -> TerrainPiece:
	var kind := TerrainKind.new()
	kind.id=id
	kind.name="Dimensional portal" if id=="reality_portal" else "Cloven hoof"
	kind.blocks_move=true
	kind.blocks_los=true
	kind.height=3.0
	kind.walkable_top=false
	var piece := TerrainPiece.new(kind,Rect2(center-Vector2.ONE*radius,Vector2.ONE*radius*2.0))
	piece.circular=true
	if not c.state.board.floor_layout.is_empty() and not RealityFloorTerrain.place_disc(c,piece):
		return null
	c.state.board.pieces.append(piece)
	c.state.board.invalidate_terrain()
	c.emit("terrain_changed",{"spell":id,"created":true})
	return piece


static func _relocate_touching(c: GameController,p: TerrainPiece) -> void:
	var s := c.state
	var center := p.rect.get_center()
	var radius := p.rect.size.x*0.5
	if not s.board.floor_layout.is_empty():
		RealityFloorTerrain.relocate_touching(c,p)
		return
	for f in s.figures.duplicate():
		if not f.in_play() or f.pos.distance_to(center)>radius+Figure.BASE_RADIUS:
			continue
		var delta: Vector2=f.pos-center
		if delta.is_zero_approx():
			delta=RealityCracks.direction(c)
		ForcedRelocation.relocate(c,f,center+delta.normalized()*(radius+Figure.BASE_RADIUS+0.1))
	for t in s.treasures:
		if not t.on_ground() or t.pos.distance_to(center)>radius+TreasureRules.TOKEN_RADIUS:
			continue
		var delta := t.pos-center
		if delta.is_zero_approx():
			delta=RealityCracks.direction(c)
		var target := center+delta.normalized()*(radius+TreasureRules.TOKEN_RADIUS+0.05)
		if not s.board.can_stand(target,TreasureRules.TOKEN_RADIUS):
			for i in 20:
				var candidate := center+Vector2.RIGHT.rotated(TAU*float(i)/20.0)*(radius+TreasureRules.TOKEN_RADIUS+0.1)
				if s.board.can_stand(candidate,TreasureRules.TOKEN_RADIUS):
					target=candidate
					break
		if s.board.can_stand(target,TreasureRules.TOKEN_RADIUS):
			t.pos=target
			c.emit("treasure_moved",{"treasure":t.id,"at":target})


static func portal(c: GameController) -> void:
	var s := c.state
	var at := s.board.size*0.5+RealityCracks.direction(c)*(float(c.dice.d20())*0.5)
	at=at.clamp(Vector2.ONE,s.board.size-Vector2.ONE)
	var piece := _make_disc(c,"reality_portal",at,1.0)
	if piece==null:
		RealityCracks.clear(c)
		return
	_relocate_touching(c,piece)
	spawn_portal(c)


static func spawn_portal(c: GameController) -> void:
	var s := c.state
	var gate := _disc(s,"reality_portal")
	if gate==null or s.creature_db==null or not s.creature_db.available("hrut_warrior"):
		return
	var center := gate.rect.get_center()
	var desired := center+RealityCracks.direction(c)*1.5
	if not s.board.floor_layout.is_empty():
		var layout:=s.board.floor_geometry()
		var best_floor: Variant=null
		var value:=INF
		for n in BattlePlacement.nearby_floor(s,center,gate.base_height,2.5,gate.surface_id):
			var at:=layout.point(n)
			var d:=at.distance_squared_to(desired)
			if at.distance_to(center)>=1.5-0.001 and d<value:
				best_floor=n
				value=d
		if best_floor!=null:
			c._encounters._spawn_on_floor("hrut_warrior",best_floor)
		return
	var grid := MoveGrid.new(s.board,null,s.figures)
	var base := MovePlanner.node_at(center)
	var best: Variant=null
	var score := INF
	for x in range(-6,7):
		for y in range(-6,7):
			var n := base+Vector2i(x,y)
			var at := MoveGrid.to_pos(n)
			var radius := at.distance_to(center)
			var d := at.distance_squared_to(desired)
			if radius>=1.5-0.001 and radius<=2.5 and d<score and grid.open(n):
				best=n
				score=d
	if best!=null:
		c._encounters._spawn_at("hrut_warrior",MoveGrid.to_pos(best))


static func hoof(c: GameController,initial: bool) -> void:
	var s := c.state
	var piece := _disc(s,"reality_hoof")
	if not initial and piece==null:
		return
	var origin := s.board.size*0.5 if piece==null else piece.rect.get_center()
	var target := origin+RealityCracks.direction(c)*floorf(float(c.dice.d20())/3.0)
	if not s.board.contains(target,1.5):
		if piece!=null:
			RealityFloorTerrain.remove_disc(s,piece)
			s.board.pieces.erase(piece)
			s.board.invalidate_terrain()
			c.emit("terrain_changed",{"spell":"reality_hoof","created":false})
		RealityCracks.clear(c)
		return
	if piece==null:
		piece=_make_disc(c,"reality_hoof",target,1.5)
		if piece==null:
			RealityCracks.clear(c)
			return
	elif not s.board.floor_layout.is_empty():
		if not RealityFloorTerrain.move_disc(c,piece,target):
			return
	else:
		piece.rect.position=target-Vector2.ONE*1.5
		s.board.invalidate_terrain()
		c.emit("terrain_changed",{"spell":"reality_hoof","created":true})
	target=piece.rect.get_center()
	for f in s.figures.duplicate():
		if not f.in_play() or f.pos.distance_to(target)>1.5+Figure.BASE_RADIUS or (not s.board.floor_layout.is_empty() and not RealityFloorTerrain.touches_height(piece,f.elevation,1.6)):
			continue
		for id in f.carried_treasures():
			c._loot.lose(s.treasure(id))
		RealityCracks.environmental_attack(c,f,10,false)
	for token in s.treasures:
		if token.on_ground() and token.pos.distance_to(target)<=1.5+TreasureRules.TOKEN_RADIUS and (s.board.floor_layout.is_empty() or RealityFloorTerrain.touches_height(piece,TreasureRules.token_height(s,token),0.5)):
			c._loot.lose(token)
	_relocate_touching(c,piece)


static func shift_ruins(c: GameController) -> void:
	var s := c.state
	var order := s.order.duplicate()
	order.reverse()
	if order.is_empty():
		for side in s.side_count():
			order.append(side)
	order.append_array(order.duplicate())
	s.scenario_data["rk_ruins_queue"]={"sides":order,"moved":[]}
	_continue_shift(c)


static func _continue_shift(c: GameController) -> void:
	var s := c.state
	var queue: Dictionary=s.scenario_data["rk_ruins_queue"]
	while not queue["sides"].is_empty():
		var side: int=queue["sides"].pop_front()
		var choices: Array[int]=[]
		for i in s.board.pieces.size():
			var p := s.board.pieces[i]
			if p.kind.ground_surface or p.kind.id.begins_with("spell_") or queue["moved"].has(i):
				continue
			if not _offsets(c,p,true).is_empty():
				choices.append(i)
		if choices.is_empty():
			break
		if side==s.reaction_side:
			s.scenario_data["rk_priority_choice"]={"kind":"ruins","options":choices}
			c.emit("reality_ruins_choice",{})
			return
		var start := c.dice.pick(choices.size())
		var index := choices[start]
		var p := s.board.pieces[index]
		var offsets := _offsets(c,p)
		var offset: Vector2=offsets[c.dice.pick(offsets.size())]
		_translate(c,p,offset)
		queue["moved"].append(index)
	s.scenario_data.erase("rk_ruins_queue")
	RealityCracks.clear(c)


static func shift_points(c: GameController,index: int) -> Array[Vector2]:
	var out: Array[Vector2]=[]
	if not c.state.scenario_data.get("rk_priority_choice",{}).get("options",[]).has(index):
		return out
	var piece := c.state.board.pieces[index]
	for offset in _offsets(c,piece):
		out.append(piece.rect.get_center()+offset)
	return out


static func answer_shift(c: GameController,index: int,at: Vector2) -> bool:
	var s := c.state
	if not shift_points(c,index).has(at):
		return false
	var p := s.board.pieces[index]
	var queue: Dictionary=s.scenario_data["rk_ruins_queue"]
	queue["moved"].append(index)
	s.scenario_data.erase("rk_priority_choice")
	_translate(c,p,at-p.rect.get_center())
	_continue_shift(c)
	if not s.scenario_data.has("rk_priority_choice"):
		c._flow.resume_priority()
	return true


## Whole-inch destinations keep the mobile marker layer small. Fractional
## original positions are preserved instead of snapping the terrain itself.
static func _offsets(c: GameController,p: TerrainPiece,first: bool=false) -> Array[Vector2]:
	var out: Array[Vector2]=[]
	for x in range(-10,11):
		for y in range(-10,11):
			var offset := Vector2(x,y)
			if offset.is_zero_approx() or offset.length_squared()>100.001 or not _valid_offset(c,p,offset):
				continue
			out.append(offset)
			if first:
				return out
	return out


static func _valid_offset(c: GameController,p: TerrainPiece,offset: Vector2) -> bool:
	var s := c.state
	if not s.board.floor_layout.is_empty():
		return RealityFloorRuins.valid(s,p,offset)
	var target := Rect2(p.rect.position+offset,p.rect.size)
	if not s.board.contains(target.position) or not s.board.contains(target.end):
		return false
	for other in s.board.pieces:
		if other!=p and other.eye_host!=p and not other.kind.ground_surface and target.intersects(other.rect):
			return false
	for f in s.figures:
		if f.in_play() and not (p.contains(f.pos) and f.elevation>=p.kind.height-0.01) and target.grow(Figure.BASE_RADIUS).has_point(f.pos):
			return false
	return true


static func _translate(c: GameController,p: TerrainPiece,offset: Vector2) -> void:
	var s := c.state
	if not s.board.floor_layout.is_empty():
		RealityFloorRuins.shift(c,p,offset)
		return
	var riders: Array[Figure]=[]
	var tokens: Array[TreasureToken]=[]
	for f in s.figures:
		if f.in_play() and p.contains(f.pos) and f.elevation>=p.kind.height-0.01:
			riders.append(f)
	for token in s.treasures:
		if token.on_ground() and p.contains(token.pos):
			tokens.append(token)
	p.rect.position+=offset
	for attached in s.board.pieces:
		if attached.eye_host==p:
			attached.rect.position+=offset
	s.board.invalidate_terrain()
	for f in riders:
		var old := f.pos
		f.pos+=offset
		f.elevation=s.board.height_at(f.pos)
		f.disengaged.clear()
		c.emit("forced_relocation",{"id":f.id,"from":old,"at":f.pos,"height":f.elevation})
	for token in tokens:
		token.pos+=offset
		c.emit("treasure_moved",{"treasure":token.id,"at":token.pos})
	c.emit("terrain_changed",{"spell":"reality_ruins","created":true})
