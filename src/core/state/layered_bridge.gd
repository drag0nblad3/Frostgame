class_name LayeredBridge
extends RefCounted
## Anchored, axis-aligned six-inch bridges with explicit floor endpoints.
## The temporary surface is saved with the board, not in a legacy TerrainPiece.


static func owned(s: GameState,id: int) -> String:
	for bridge: Dictionary in s.board.floor_layout.get("bridges",[]):
		if int(bridge["owner"])==id:
			return str(bridge["surface"]["id"])
	return ""


static func eligible(c: GameController) -> bool:
	var f := c.state.active()
	return f!=null and not ScenarioNull.muted(f) and not c.state.board.floor_layout.is_empty() and c.can_act() and CasterLoadout.is_caster(f.def.role) and c._magic.available_spell(f,"bridge") and owned(c.state,f.id).is_empty() and not Contact.in_combat(c.state.figures,f) and not f.spell_effects.has("blinding_light") and not f.surface_id.begins_with("climb:")


static func proposal(c: GameController,a: Vector3i,b: Vector3i,layout: FloorLayout) -> Dictionary:
	if not eligible(c) or not layout.standable(a) or not layout.standable(b):
		return {}
	var f := c.state.active()
	var p := layout.point(a)
	var q := layout.point(b)
	var delta := q-p
	if a.z==b.z or not is_equal_approx(delta.length(),6.0) or (not is_zero_approx(delta.x) and not is_zero_approx(delta.y)):
		return {}
	if layout.surface_id(a).begins_with("climb:") or layout.surface_id(b).begins_with("climb:") or layout.surface_id(a).begins_with("bridge:") or layout.surface_id(b).begins_with("bridge:"):
		return {}
	var axis_y := is_zero_approx(delta.x)
	if (q.y<p.y if axis_y else q.x<p.x):
		return proposal(c,b,a,layout)
	var along := delta.normalized()
	var across := Vector2.RIGHT if axis_y else Vector2.DOWN
	var start := layout.height(a)
	var end := layout.height(b)
	var eye := Vector3(f.pos.x,f.elevation+1.5,f.pos.y)
	for i in range(25):
		var ratio := float(i)/24.0
		var h := lerpf(start,end,ratio)
		for offset: float in [-1.0,0.0,1.0]:
			var at := p.lerp(q,ratio)+across*offset
			var world := Vector3(at.x,h,at.y)
			if ScenarioNull.field_at(c.state.board,at,0.0) or not c.state.board.contains(at) or not LayeredSight.clear(layout,eye,world+Vector3.UP*0.03):
				return {}
			if not layout.clearance(world,0.02,0.1):
				return {}
	var id := "bridge:"+str(f.id)
	var rect := Rect2(p-across,Vector2(2,6) if axis_y else Vector2(6,2))
	var surface := {"id":id,"rect":[rect.position.x,rect.position.y,rect.size.x,rect.size.y],"level":start,"end_level":end,"axis":"y" if axis_y else "x"}
	var left := p+along*0.5
	var right := q-along*0.5
	var links := [
		{"from":[layout.surface_id(a),p.x,p.y],"to":[id,left.x,left.y],"kind":"walk"},
		{"from":[id,right.x,right.y],"to":[layout.surface_id(b),q.x,q.y],"kind":"walk"}]
	var bridge := {"owner":f.id,"surface":surface,"links":links}
	for other: Dictionary in c.state.board.floor_layout.get("bridges",[]):
		var r: Array = other["surface"]["rect"]
		if rect.intersects(Rect2(r[0],r[1],r[2],r[3])):
			return {}
	# Rebuild exactly as it would exist after the spell; reject invalid links.
	var copy := c.state.board.floor_layout.duplicate(true)
	var bridges: Array = copy.get("bridges",[])
	bridges.append(bridge)
	copy["bridges"]=bridges
	if not FloorLayout.from_dict(copy).errors.is_empty():
		return {}
	return bridge


static func start(c: GameController,a: Vector3i,b: Vector3i) -> bool:
	var bridge := proposal(c,a,b,FloorLayout.from_dict(c.state.board.floor_layout))
	return not bridge.is_empty() and c._magic._roll("bridge",c.state.active_id,null,false,-1,{"layered_bridge":bridge})


static func apply(c: GameController,bridge: Dictionary) -> void:
	var entries: Array = c.state.board.floor_layout.get("bridges",[])
	entries.append(bridge)
	c.state.board.floor_layout["bridges"]=entries
	c.emit("terrain_changed",{"spell":"bridge","created":true})


static func expire(c: GameController) -> void:
	for bridge: Dictionary in c.state.board.floor_layout.get("bridges",[]).duplicate():
		if c.dice.d20()<=2:
			remove(c,str(bridge["surface"]["id"]))


static func cancel(c: GameController) -> bool:
	var f := c.state.active()
	if f==null or c.awaiting_reaction() or not c.state.pending_cast.is_empty():
		return false
	var id := owned(c.state,f.id)
	if id.is_empty():
		return false
	remove(c,id)
	return true


static func remove(c: GameController,id: String) -> void:
	var s := c.state
	var before := FloorLayout.from_dict(s.board.floor_layout)
	var entries: Array = s.board.floor_layout.get("bridges",[])
	for i in range(entries.size()-1,-1,-1):
		if entries[i]["surface"]["id"]==id:
			entries.remove_at(i)
	s.board.floor_layout["bridges"]=entries
	var layout := FloorLayout.from_dict(s.board.floor_layout)
	c.emit("terrain_changed",{"spell":"bridge","created":false})
	for f in s.figures:
		if not f.in_play() or f.surface_id!=id:
			continue
		var n: Variant = LayeredFall.landing(layout,LayeredGrid.new(layout,f,s.figures),f.pos,f.elevation+0.001)
		if n==null:
			# No valid unoccupied lower surface: resolve as out of action, not
			# a figure stranded on a non-existent floor.
			c._hurt(f,f.health,f,false)
			continue
		var old := f.elevation
		f.surface_id=layout.surface_id(n)
		f.elevation=layout.height(n)
		c.emit("terrain_fall",{"id":f.id})
		LayeredFall.apply(c,f,old-f.elevation,f)
		ScenarioNull.enter(c,f)
	for token in s.treasures:
		if not token.on_ground() or token.surface_id!=id:
			continue
		var index := before.index_of(id)
		var above := before.surfaces[index].height_at(token.pos)
		var n: Variant = LayeredFall.landing(layout,LayeredGrid.new(layout),token.pos,above+0.001)
		if n==null:
			c._loot.lose(token)
		else:
			token.surface_id=layout.surface_id(n)
			c.emit("treasure_moved",{"treasure":token.id,"at":token.pos,"height":layout.height(n)})
