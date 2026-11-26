class_name TerrainMagic
extends RefCounted
## Dynamic terrain on the exposed-surface heightfield.
const EXTENDED := "gear_rk_extended_scroll"
const SPELLS := ["wall", "fog", "mud", "explosive_rune", "planar_tear", "grenade", "circle_of_protection", "bridge"]
var c: GameController


func _init(controller: GameController) -> void:
	c = controller


func footprint(id: String, at: Vector2, rotated: bool,extended: bool=false) -> Rect2:
	var size := Vector2(6, 6) if id == "mud" else (Vector2(1, 6) if rotated else Vector2(6, 1))
	if id == "bridge":
		var length := 9.0 if extended else 6.0
		size = Vector2(2,length) if rotated else Vector2(length,2)
	if id == "circle_of_protection":
		size = Vector2(3, 3)
	if id in ["explosive_rune", "planar_tear", "grenade"]:
		size = Vector2(0.5, 0.5)
	return Rect2(at - size * 0.5, size)


func can_place(f: Figure, id: String, at: Vector2, rotated: bool,extended: bool=false) -> bool:
	if extended and (id!="bridge" or not ActiveGear.ready(f,EXTENDED)):
		return false
	var b := c.state.board
	var rect := footprint(id, at, rotated,extended)
	if ScenarioNull.field_at(b, at, 0.0):
		return false
	if b.id == "silent_tower":
		for p in b.pieces:
			if p.kind.id.begins_with("null_") and p.rect.intersects(rect):
				return false
	if not b.contains(rect.position) or not b.contains(rect.end):
		return false
	if id == "bridge":
		return bridge_legal(f, rect, rotated)
	if id == "circle_of_protection":
		for p in b.pieces:
			if p.kind.id == "spell_circle_of_protection" and p.caster_id == f.id:
				return false
		if f.pos.distance_to(at) > 2.0 or absf(f.elevation - b.height_at(at)) > 0.1:
			return false
		for t in c.state.figures:
			if t.in_play() and (t.is_demon() or t.is_undead()) and absf(t.elevation - b.height_at(at)) < 0.5 and t.pos.distance_to(at) < 2.0:
				return false
		return true
	if id == "mud":
		return f.pos.distance_to(at) <= 24 and WizardEye.visible(b, f, at)
	if id == "grenade":
		return f.pos.distance_to(at) <= 14.0 and LineOfSight.check(b, f.pos, at).clear
	if id in ["explosive_rune", "planar_tear"]:
		if id == "explosive_rune":
			var count := 0
			for p in b.pieces:
				if p.kind.id == "spell_explosive_rune" and p.caster_id == f.id:
					count += 1
			if count >= 3:
				return false
		return f.pos.distance_to(at) <= (4.0 if id == "explosive_rune" else 24.0) and (WizardEye.visible(b, f, at, 4.0) if id == "explosive_rune" else LineOfSight.check(b, f.pos, at).clear)
	var seen := false
	for i in range(-6, 7):
		var p := at + (Vector2.DOWN if rotated else Vector2.RIGHT) * i * 0.5
		var distance := f.pos.distance_to(p)
		if id == "fog" and distance > 24.0:
			return false
		if (id == "fog" or distance <= 10.0) and WizardEye.visible(b, f, p):
			seen = true
	if not seen:
		return false
	if id == "wall":
		for t in c.state.figures:
			if t.in_play() and rect.grow(Figure.BASE_RADIUS).has_point(t.pos):
				return false
		for p in b.pieces:
			if p.kind.blocks_move and p.rect.intersects(rect):
				return false
	return true


func points(f: Figure, id: String, rotated: bool, first_only: bool,extended: bool=false) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var b := c.state.board
	for x in range(1, int(b.size.x)):
		for y in range(1, int(b.size.y)):
			var at := Vector2(x, y)
			if can_place(f,id,at,rotated,extended):
				out.append(at)
				if first_only:
					return out
	return out


func apply(f: Figure, id: String, at: Vector2, rotated: bool, roll: int = 14,extended: bool=false) -> void:
	if id == "grenade":
		var affected: Array[Figure] = []
		var s := c.state
		for t in s.figures:
			if not t.in_play() or Vector2(t.pos.distance_to(at), t.elevation - s.board.height_at(at)).length() > 1.5 + Figure.BASE_RADIUS:
				continue
			for member in ShotTarget.participants(s.figures, t):
				if not affected.has(member):
					affected.append(member)
		for t in affected:
			c._magic._shot(f, t, 3, at)
		return
	if id == "planar_tear":
		for t in c.state.figures:
			if not t.in_play() or Vector2(t.pos.distance_to(at), t.elevation - c.state.board.height_at(at)).length() > 2.0 + Figure.BASE_RADIUS:
				continue
			if not StatRoll.succeeds(c.dice.d20(), t.effective_will() + t.roll_penalty(), roll):
				c._hurt(t, roll if t.is_demon() else 2, f, false)
		return
	var kind := TerrainKind.new()
	kind.id = "spell_" + id
	kind.name = id.capitalize()
	kind.height = 0.04 if id in ["mud", "explosive_rune", "circle_of_protection"] else 3.0
	kind.blocks_los = id in ["wall", "fog"]
	kind.blocks_move = id == "wall"
	kind.walkable_top = id in ["wall", "bridge"]
	kind.move_mult = 2.0 if id == "mud" else 1.0
	var p := TerrainPiece.new(kind, footprint(id, at, rotated,extended))
	p.extended_bridge=extended
	p.elemental_wall=id=="wall" and ActiveGear.has(f,"gear_rk_ring_of_elemental_fire") and not MagicEquipment.suppressed(f)
	p.circular = id in ["mud", "explosive_rune", "circle_of_protection"]
	if id == "bridge":
		var ends := bridge_ends(p.rect, rotated)
		p.ramp = true
		p.ramp_rotated = rotated
		p.ramp_start = ends.x
		p.ramp_end = ends.y
		kind.height = maxf(ends.x, ends.y)
		kind.stairs = true
	p.cast_turn = c.state.turn
	p.caster_id = f.id
	c.state.board.pieces.append(p)
	c.state.board.invalidate_terrain()
	c.emit("terrain_changed", {"spell": id, "created": true})


func expire() -> void:
	var s := c.state
	for p in s.board.pieces.duplicate():
		if p.cast_turn < 0:
			continue
		if p.kind.id == "spell_bridge":
			if c.dice.d20() <= (1 if p.extended_bridge else 2):
				remove(p)
			continue
		if p.kind.id == "spell_circle_of_protection":
			if c.dice.d20() <= 3:
				remove(p)
			continue
		if p.kind.id == "spell_explosive_rune":
			var owner := s.figure(p.caster_id)
			if (owner == null or not owner.in_play()) and c.dice.d20() >= 11:
				remove(p)
			continue
		if p.kind.id == "spell_fog" or (p.kind.id == "spell_wall" and p.cast_turn < s.turn):
			if c.dice.d20() <= 4:
				remove(p)


func remove(p: TerrainPiece) -> void:
	var s := c.state
	WizardEye.remove_attached(s.board, p)
	s.board.pieces.erase(p)
	s.board.invalidate_terrain()
	c.emit("terrain_changed", {"spell": p.kind.id.trim_prefix("spell_"), "created": false})
	for t in s.figures:
		if not t.in_play():
			continue
		var new_height := s.board.height_at(t.pos)
		var fall := ElevationRules.fall_damage(t.elevation - new_height - (3.0 if s.board.low_gravity else 0.0))
		if not is_equal_approx(t.elevation, new_height):
			t.elevation = new_height
			c.emit("terrain_fall", {"id": t.id})
		if fall > 0 and MagicEquipment.bonus(t, "slow_fall") == 0:
			c._hurt(t, fall, t, false)


func triggered(t: Figure, at: Vector2) -> Array[TerrainPiece]:
	var result: Array[TerrainPiece] = []
	var s := c.state
	for p in s.board.pieces:
		if p.kind.id != "spell_explosive_rune":
			continue
		var owner := s.figure(p.caster_id)
		if owner == null or owner.original_side == t.original_side:
			continue
		var center := p.rect.get_center()
		if Vector2(at.distance_to(center), s.board.height_at(at) - s.board.height_at(center)).length() <= 1.0 + Figure.BASE_RADIUS:
			result.append(p)
	return result


func explode(p: TerrainPiece) -> void:
	if not c.state.board.pieces.has(p):
		return
	var s := c.state
	var owner := s.figure(p.caster_id)
	var center := p.rect.get_center()
	remove(p)
	c.emit("rune_exploded", {"at": center, "id": owner.id})
	for t in s.figures:
		if not t.in_play() or Vector2(t.pos.distance_to(center), t.elevation - s.board.height_at(center)).length() > 2.0 + Figure.BASE_RADIUS:
			continue
		c._magic._direct_attack(owner,t,5,"explosive_rune")


## Animate movement in chunks, resolving triggers at the actual path location.
func travel(f: Figure, path: PackedVector2Array, cost: float) -> bool:
	var chunk := PackedVector2Array([f.pos])
	var portal_hits := {}
	var orb_contact := false
	for i in range(1, path.size()):
		var at := path[i]
		if BoardTopology.is_transfer(c.state.board,path[i-1],at):
			if chunk.size()>1:
				c.emit("move",{"id":f.id,"path":chunk,"cost":cost})
			var old := path[i-1]
			f.pos=at
			f.elevation=c.state.board.height_at(at)
			c.emit("forced_relocation",{"id":f.id,"from":old,"at":at,"height":f.elevation})
			chunk=PackedVector2Array([at])
			trigger_landing(f)
			if not f.in_play():
				return false
			continue
		if RedKingSinkhole.active(c.state):
			var touches := RedKingSinkhole.touches(c.state,at)
			if touches and not orb_contact and not RedKingSinkhole.touches(c.state,path[i-1]):
				f.pos=at
				f.elevation=c.state.board.height_at(at)
				chunk.append(at)
				c.emit("move",{"id":f.id,"path":chunk,"cost":cost})
				chunk=PackedVector2Array([at])
				RedKingSinkhole.contact(c,f)
				if not f.in_play():
					return false
			orb_contact=touches
			RedKingSinkhole.record_xp_at(c,f,at)
		if RedKingHerded.active(c.state):
			f.pos=path[i-1]
			f.elevation=c.state.board.height_at(f.pos)
			if RedKingHerded.contact(c,f,at):
				return false
		if RedKingMind.active(c.state):
			RedKingMind.collect(c,f,path[i-1],at)
		if RedKingFire.active(c.state):
			RedKingFire.portal_contact(c,f,path[i-1],at,portal_hits)
			if not f.in_play():
				return false
		if RedKingVeil.active(c.state):
			f.pos=path[i-1]
			f.elevation=c.state.board.height_at(f.pos)
			if RedKingVeil.touch(c,f,at):
				return false
		if RedKingSquatter.active(c.state):
			# The last reached position is the door-side landing on a failed test.
			f.pos=path[i-1]
			f.elevation=c.state.board.height_at(f.pos)
			if not RedKingSquatter.permit_step(c,f,at):
				if chunk.size()>1:
					c.emit("move",{"id":f.id,"path":chunk,"cost":cost})
				return false
		var occupied := false
		if c.state.scenario_special == "haunted_houses" and not c.state.discovered_huts.is_empty():
			for other in c.state.figures:
				if other == f or not other.in_play() or absf(other.elevation - c.state.board.height_at(at)) >= 0.5:
					continue
				if other.pos.distance_to(at) < Contact.OVERLAP:
					# A creature appeared after planning; keep the last safe position.
					f.pos = path[i - 1]
					f.elevation = c.state.board.height_at(f.pos)
					if chunk.size() > 1:
						c.emit("move", {"id": f.id, "path": chunk, "cost": cost})
					return false
				if other.side != f.side and Contact.touching(other.pos, at):
					occupied = true
		chunk.append(at)
		var hits := triggered(f, at)
		var wall_hits := entering_walls(f,path[i-1],at)
		var hut := ScenarioSites.site_at(c.state, "haunted_floor", at) if c.state.scenario_special == "haunted_houses" and f.side >= 0 else null
		var undiscovered := hut != null and not c.state.discovered_huts.has(hut.rect.position)
		var null_field := ScenarioNull.field_at(c.state.board, at)
		var column := f.side >= 0 and not IllusionRules.phantom(f) and ScenarioColumns.contact(c.state.board, at) != null
		if hits.is_empty() and wall_hits.is_empty() and not undiscovered and not occupied and not null_field and not column:
			continue
		f.pos = at
		f.elevation = c.state.board.height_at(at)
		c.emit("move", {"id": f.id, "path": chunk, "cost": cost})
		chunk = PackedVector2Array([at])
		ScenarioNull.enter(c, f)
		if not f.in_play():
			return false
		for wall in wall_hits:
			wall_damage(f,wall)
		for p in hits:
			explode(p)
		if not f.in_play():
			return false
		if column and i < path.size() - 1:
			ScenarioColumns.challenge(c, f)
			return false
		if undiscovered and ScenarioSites.enter(c, f) and Contact.in_combat(c.state.figures, f):
			return false
		# A newly revealed occupant can stop an already planned path at contact.
		if occupied and i < path.size() - 1:
			return false
	f.pos = path[path.size() - 1]
	f.elevation = c.state.board.height_at(f.pos)
	if chunk.size() > 1:
		c.emit("move", {"id": f.id, "path": chunk, "cost": cost})
	return true


func trigger_landing(f: Figure) -> void:
	RedKingSinkhole.contact(c,f)
	RedKingSinkhole.record_xp(c,f)
	if not f.in_play():
		return
	for wall in touching_walls(f.pos,f.elevation):
		wall_damage(f,wall)
	for p in triggered(f, f.pos):
		explode(p)


static func ward_blocks(b: Board, f: Figure, at: Vector2) -> bool:
	if f == null or (not f.is_demon() and not f.is_undead()):
		return false
	if HolyLantern.ward(f,at,b.height_at(at)):
		return true
	for p in b.pieces:
		if p.kind.id == "spell_circle_of_protection" and p.rect.get_center().distance_to(at) < 1.5 + Figure.BASE_RADIUS and absf(b.height_at(at) - b.height_at(p.rect.get_center())) < 0.5:
			return true
	return false


func bridge_ends(rect: Rect2, rotated: bool) -> Vector2:
	var axis := Vector2.DOWN if rotated else Vector2.RIGHT
	var b := c.state.board
	var half := (rect.size.y if rotated else rect.size.x)*0.5-0.01
	return Vector2(b.height_at(rect.get_center()-axis*half),b.height_at(rect.get_center()+axis*half))


func bridge_legal(f: Figure, rect: Rect2, rotated: bool) -> bool:
	var b := c.state.board
	for p in b.pieces:
		if p.kind.id == "spell_bridge" and (p.caster_id == f.id or p.rect.intersects(rect)):
			return false
	var ends := bridge_ends(rect, rotated)
	var half := (rect.size.y if rotated else rect.size.x)*0.5-0.01
	var steps := ceili(half*4.0)
	for i in range(steps+1):
		var ratio := float(i)/steps
		var axis := Vector2.DOWN if rotated else Vector2.RIGHT
		var across := Vector2.RIGHT if rotated else Vector2.DOWN
		var at := rect.get_center() + axis * lerpf(-half,half,ratio)
		var height := lerpf(ends.x, ends.y, ratio)
		for j in [-0.9, 0.0, 0.9]:
			var sample: Vector2 = at + across * float(j)
			if b.height_at(sample) > height + 0.1 or not WizardEye.visible(b, f, sample):
				return false
			for p in b.pieces_at(sample):
				if p.kind.blocks_move and p.kind.height > height + 0.1:
					return false
	for t in c.state.figures:
		if t.in_play() and rect.has_point(t.pos):
			var ratio := (t.pos.y - rect.position.y) / rect.size.y if rotated else (t.pos.x - rect.position.x) / rect.size.x
			if absf(lerpf(ends.x, ends.y, ratio) - t.elevation) > 0.1:
				return false
	return true


func cancel_bridge(f: Figure) -> bool:
	if f == null or c.awaiting_reaction() or not c.state.pending_cast.is_empty():
		return false
	for p in c.state.board.pieces:
		if p.kind.id == "spell_bridge" and p.caster_id == f.id:
			remove(p)
			return true
	return false


func touching_walls(at: Vector2,height: float) -> Array[TerrainPiece]:
	var result: Array[TerrainPiece]=[]
	for wall in c.state.board.pieces:
		if not wall.elemental_wall or height>wall.kind.height+0.5:
			continue
		var nearest := at.clamp(wall.rect.position,wall.rect.end)
		if at.distance_to(nearest)<=Figure.BASE_RADIUS+0.001:
			result.append(wall)
	return result


func entering_walls(f: Figure,from: Vector2,at: Vector2) -> Array[TerrainPiece]:
	var result := touching_walls(at,c.state.board.height_at(at))
	for wall in touching_walls(from,c.state.board.height_at(from)):
		result.erase(wall)
	return result


func wall_damage(f: Figure,wall: TerrainPiece) -> void:
	if not f.in_play() or f.def.traits.has("antithetical_magic") or ScenarioNull.muted(f) or f.spell_effects.has("plane_walk"):
		return
	var damage := RedKingElemental.reduce(c,f,maxi(0,2-CreatureEffects.elemental_resistance(f)))
	var owner := c.state.figure(wall.caster_id)
	c._hurt(f,damage,owner if owner!=null else f)


func wall_activation(f: Figure) -> void:
	for wall in touching_walls(f.pos,f.elevation):
		wall_damage(f,wall)
