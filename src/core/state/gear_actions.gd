class_name GearActions
extends RefCounted


static func can_use(c: GameController, id: String) -> bool:
	var f := c.state.active()
	if not c.can_act() or not ActiveGear.ready(f, id) or Contact.in_combat(c.state.figures, f) or FuryRules.target(c.state, f) != null:
		return false
	if id in ["gear_gloves_casting", "gear_wand_light"]:
		return f.def.role in ["wizard", "apprentice"]
	return true


static func arm(c: GameController, id: String) -> bool:
	if not can_use(c, id) or id not in ["gear_gloves_casting", "gear_wand_light"]:
		return false
	var f := c.state.active()
	f.next_cast_gear = "" if f.next_cast_gear == id else id
	return true


static func teleport_legal(c: GameController, at: Vector2) -> bool:
	if not can_use(c, "gear_ring_teleportation"):
		return false
	var f := c.state.active()
	return Vector2(f.pos.distance_to(at), f.elevation - c.state.board.height_at(at)).length() <= 8.0 and c._magic.movement.can_land(f, f, "teleport", at)


static func teleport_points(c: GameController) -> Array[Vector2]:
	var out: Array[Vector2] = []
	if not can_use(c, "gear_ring_teleportation"):
		return out
	var center := MovePlanner.node_at(c.state.active().pos)
	for x in range(-16, 17):
		for y in range(-16, 17):
			var at := MoveGrid.to_pos(center + Vector2i(x, y))
			if teleport_legal(c, at):
				out.append(at)
	return out


static func teleport(c: GameController, at: Vector2) -> bool:
	if not teleport_legal(c, at):
		return false
	var f := c.state.active()
	ActiveGear.spend(f, "gear_ring_teleportation")
	c._spend(f)
	c._magic.movement.move(f, at)
	c.emit("gear_used", {"id": f.id, "gear": "gear_ring_teleportation"})
	return true


static func horn(c: GameController, p: TerrainPiece) -> bool:
	if not can_use(c, "gear_horn_destruction"):
		return false
	var f := c.state.active()
	for option in c._magic.crumble.options(f):
		if option["piece"] == p:
			ActiveGear.spend(f, "gear_horn_destruction")
			c._spend(f)
			c._magic.crumble.apply(p)
			c.emit("gear_used", {"id": f.id, "gear": "gear_horn_destruction"})
			return true
	return false
