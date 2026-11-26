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
	c.state.board.pieces.append(piece)
	c.state.board.invalidate_terrain()
	c.emit("terrain_changed",{"spell":id,"created":true})
	return piece


static func _relocate_touching(c: GameController,p: TerrainPiece) -> void:
	var s := c.state
	var center := p.rect.get_center()
	var radius := p.rect.size.x*0.5
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
	_relocate_touching(c,piece)
	spawn_portal(c)


static func spawn_portal(c: GameController) -> void:
	var s := c.state
	var gate := _disc(s,"reality_portal")
	if gate==null or s.creature_db==null or not s.creature_db.available("hrut_warrior"):
		return
	var center := gate.rect.get_center()
	var desired := center+RealityCracks.direction(c)*1.5
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
			s.board.pieces.erase(piece)
			s.board.invalidate_terrain()
			c.emit("terrain_changed",{"spell":"reality_hoof","created":false})
		RealityCracks.clear(c)
		return
	if piece==null:
		piece=_make_disc(c,"reality_hoof",target,1.5)
	else:
		piece.rect.position=target-Vector2.ONE*1.5
		s.board.invalidate_terrain()
		c.emit("terrain_changed",{"spell":"reality_hoof","created":true})
	for f in s.figures.duplicate():
		if not f.in_play() or f.pos.distance_to(target)>1.5+Figure.BASE_RADIUS:
			continue
		for id in f.carried_treasures():
			c._loot.lose(s.treasure(id))
		RealityCracks.environmental_attack(c,f,10,false)
	for token in s.treasures:
		if token.on_ground() and token.pos.distance_to(target)<=1.5+TreasureRules.TOKEN_RADIUS:
			c._loot.lose(token)
	_relocate_touching(c,piece)


static func shift_ruins(c: GameController) -> void:
	var s := c.state
	var moved: Array[TerrainPiece]=[]
	var order := s.order.duplicate()
	order.reverse()
	if order.is_empty():
		for side in s.side_count():
			order.append(side)
	for round in 2:
		for side in order:
			var choices: Array[TerrainPiece]=[]
			for p in s.board.pieces:
				if not p.kind.ground_surface and not p.kind.id.begins_with("spell_") and not moved.has(p):
					choices.append(p)
			if choices.is_empty():
				return
			var start := c.dice.pick(choices.size())
			for i in choices.size():
				var p := choices[(start+i)%choices.size()]
				var offset := _legal_offset(c,p)
				if offset.is_zero_approx():
					continue
				_translate(c,p,offset)
				moved.append(p)
				break


static func _legal_offset(c: GameController,p: TerrainPiece) -> Vector2:
	var s := c.state
	for attempt in 30:
		var offset := RealityCracks.direction(c)*float(c.dice.pick(10)+1)
		var target := Rect2(p.rect.position+offset,p.rect.size)
		if not s.board.contains(target.position) or not s.board.contains(target.end):
			continue
		var clear := true
		for other in s.board.pieces:
			if other!=p and not other.kind.ground_surface and target.intersects(other.rect):
				clear=false
				break
		if not clear:
			continue
		for f in s.figures:
			if f.in_play() and not p.rect.has_point(f.pos) and target.grow(Figure.BASE_RADIUS).has_point(f.pos):
				clear=false
				break
		if clear:
			return offset
	return Vector2.ZERO


static func _translate(c: GameController,p: TerrainPiece,offset: Vector2) -> void:
	var s := c.state
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
