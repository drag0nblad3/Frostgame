class_name CrumbleActions
extends RefCounted

## The controller owns this helper; avoid a RefCounted ownership cycle.
var _controller_ref: WeakRef
var c: GameController:
	get:
		return _controller_ref.get_ref() as GameController


func _init(controller: GameController) -> void:
	_controller_ref=weakref(controller)


func options(f: Figure) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var board := c.state.board
	for p in board.pieces:
		if p.kind.id==ConvexCrumble.KIND:
			if ConvexCrumble.visible(board,f,p):
				out.append({"kind":"terrain","target":f.id,"piece":p,"label":"%s at %.1f, %.1f"%[p.kind.name,p.rect.get_center().x,p.rect.get_center().y]})
			continue
		if p.kind.id.begins_with("null_") or p.kind.id == "temple_column":
			continue
		if p.kind.id != "spell_wall" and (p.cast_turn >= 0 or not p.kind.blocks_move or p.kind.height < 1.0):
			continue
		var near := Vector2(clampf(f.pos.x, p.rect.position.x, p.rect.end.x), clampf(f.pos.y, p.rect.position.y, p.rect.end.y)).lerp(f.pos, 0.02)
		if not board.floor_layout.is_empty():
			# Freestanding authored architecture and conjured walls share a destruction contract.
			if p.dynamic_surface.is_empty() or not LineOfSight.floor_point_visible(board,board.floor_geometry(),f,Vector3(near.x,p.base_height+0.5,near.y)):
				continue
		elif not LineOfSight.check(board,f.pos,near).clear:
			continue
		out.append({"kind": "terrain", "target": f.id, "piece": p, "label": "%s at %.1f, %.1f" % [p.kind.name, p.rect.get_center().x, p.rect.get_center().y]})
	return out


func apply(p: TerrainPiece) -> void:
	var s := c.state
	if not s.board.pieces.has(p):
		return
	if p.kind.id==ConvexCrumble.KIND:
		ConvexCrumble.apply(c,p)
		return
	if p.kind.id == "spell_wall":
		c._magic.terrain.remove(p)
		return
	if not s.board.floor_layout.is_empty():
		_floor_crumble(p)
		return
	# Remove a doorway-width strip through the simplified solid ruin footprint.
	var r := p.rect
	var along_x := r.size.x >= r.size.y
	var length := r.size.x if along_x else r.size.y
	var remaining := maxf(0.0, (length - 1.5) * 0.5)
	WizardEye.remove_attached(s.board, p)
	s.board.pieces.erase(p)
	if remaining > 0.01:
		var a := Rect2(r.position, Vector2(remaining, r.size.y) if along_x else Vector2(r.size.x, remaining))
		var b := Rect2(r.end - a.size, a.size)
		s.board.pieces.append(TerrainPiece.new(p.kind, a))
		s.board.pieces.append(TerrainPiece.new(p.kind, b))
	s.board.invalidate_terrain()
	c.emit("terrain_changed", {"spell": "crumble", "created": false})
	for t in s.figures:
		if not t.in_play() or t.elevation <= s.board.height_at(t.pos):
			continue
		var mod := t.effective_move() + t.roll_penalty() - int(t.injury_types.get("lost_toes", 0))
		var saved := StatRoll.succeeds(c.dice.d20(), mod, 22)
		if saved:
			var moved := false
			for i in 16:
				var at := t.pos + Vector2.RIGHT.rotated(TAU * i / 16.0)
				if s.board.height_at(at) >= t.elevation and c._magic.movement.landing(t, at, true):
					c._magic.movement.move(t, at)
					moved = true
					break
			if moved:
				continue
		var h := s.board.height_at(t.pos)
		var damage := ElevationRules.fall_damage(t.elevation - h)
		t.elevation = h
		c.emit("terrain_fall", {"id": t.id})
		if damage > 0 and MagicEquipment.bonus(t, "slow_fall") == 0:
			c._hurt(t, damage, t, false)


func _floor_crumble(p: TerrainPiece) -> void:
	if p.dynamic_surface.is_empty():
		return
	var s:=c.state
	var before:=s.board.floor_geometry()
	var id:=p.dynamic_surface
	var entries: Array=s.board.floor_layout.get("walls",[])
	var template: Dictionary={}
	for i in range(entries.size()-1,-1,-1):
		if entries[i]["id"]==id:
			template=entries[i].duplicate(true)
			entries.remove_at(i)
	if template.is_empty() or not template.get("architectural",false):
		return
	var r:=p.rect
	var along_x:=r.size.x>=r.size.y
	var length:=r.size.x if along_x else r.size.y
	var remaining:=maxf(0.0,(length-1.5)*0.5)
	WizardEye.remove_attached(s.board,p)
	s.board.pieces.erase(p)
	var replacements: Array[String]=[]
	if remaining>0.01:
		var size:=Vector2(remaining,r.size.y) if along_x else Vector2(r.size.x,remaining)
		for start: Vector2 in [r.position,r.end-size]:
			var part:=TerrainPiece.new(p.kind,Rect2(start,size))
			part.surface_id=p.surface_id
			part.base_height=p.base_height
			part.dynamic_surface=id+":part:"+str(replacements.size())
			var row:=template.duplicate(true)
			row["id"]=part.dynamic_surface
			row["rect"]=[start.x,start.y,size.x,size.y]
			entries.append(row)
			replacements.append(part.dynamic_surface)
			s.board.pieces.append(part)
	s.board.floor_layout["walls"]=entries
	s.board.invalidate_terrain()
	var layout:=s.board.floor_geometry()
	# Bases on surviving masonry do not fall merely because the support was
	# split into two identifiers. Those over the gap get the normal fall.
	for f in s.figures:
		if not f.in_play() or f.surface_id!=id:
			continue
		for next in replacements:
			var n:=layout.node(next,f.pos)
			if layout.standable(n) and is_equal_approx(layout.height(n),f.elevation):
				f.surface_id=next
				break
	for token in s.treasures:
		if not token.on_ground() or token.surface_id!=id:
			continue
		for next in replacements:
			var n:=layout.node(next,token.pos)
			if layout.standable(n,TreasureRules.TOKEN_RADIUS,0.5):
				token.surface_id=next
				break
	c.emit("terrain_changed",{"spell":"crumble","created":false})
	FloorSupportRemoval.resolve(c,before,id)
