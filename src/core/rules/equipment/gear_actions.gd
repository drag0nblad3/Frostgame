class_name GearActions
extends RefCounted


static func can_use(c: GameController, id: String) -> bool:
	var f := c.state.active()
	if not c.can_act() or not ActiveGear.ready(f, id) or Contact.in_combat(c.state.figures, f) or FuryRules.target(c.state, f) != null:
		return false
	if id in ["gear_gloves_casting", "gear_wand_light", "gear_ring_transference"]:
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


static func transfer_max(c: GameController, t: Figure) -> int:
	if not can_use(c, "gear_ring_transference"):
		return 0
	var f := c.state.active()
	if t == null or t == f or not t.in_play() or ScenarioNull.muted(t) or t.side != f.side or not IllusionRules.visible_to(c.state.figures, f, t) or Shooting.distance(f, t) > 24.0 or not LineOfSight.check(c.state.board, f.pos, t.pos).clear:
		return 0
	return maxi(0, mini(5, mini(f.health, t.def.health - t.health)))


static func transfer(c: GameController, t: Figure, amount: int) -> bool:
	if amount <= 0 or amount > transfer_max(c, t):
		return false
	var f := c.state.active()
	ActiveGear.spend(f, "gear_ring_transference")
	c._spend(f)
	c._hurt(f, amount, f, false)
	# Unlike Heal, the ring transfers Health rather than casting a healing spell.
	var old := t.health
	t.health = mini(t.def.health, t.health + amount)
	if t.health > old:
		t.poisoned = false
	c.emit("heal", {"id": t.id, "amount": t.health - old, "health": t.health})
	c.emit("gear_used", {"id": f.id, "target": t.id, "gear": "gear_ring_transference", "amount": amount})
	return true


## The bottle is a consumable and can replace a movement action, even in melee.
static func bottle_ready(c: GameController,layered: bool=false) -> bool:
	var f := c.state.active()
	return f!=null and f.in_play() and f.actions_left>0 and not c.awaiting_reaction() and c.state.pending_cast.is_empty() and c.state.push_winner<0 and not c.state.group.movement_pass() and not f.spell_effects.has("plane_walk") and FuryRules.target(c.state,f)==null and ActiveGear.ready(f,"gear_rk_bottle_imp") and (f.moves_taken==0 and not c.state.group.in_progress() or c.can_act()) and c.state.creature_db!=null and (not c.state.board.floor_layout.is_empty() if layered else c.state.board.floor_layout.is_empty())


static func bottle_legal(c: GameController,at: Vector2) -> bool:
	if not bottle_ready(c):
		return false
	var f := c.state.active()
	var height := c.state.board.height_at(at)
	if Vector2(f.pos.distance_to(at),height-f.elevation).length()>1.001 or not c.state.board.can_stand(at,Figure.BASE_RADIUS) or ScenarioNull.field_at(c.state.board,at):
		return false
	for t in c.state.figures:
		if t.in_play() and t.ring_side==f.ring_side and Vector2(t.pos.distance_to(at),t.elevation-height).length()<Contact.OVERLAP:
			return false
	return true


static func bottle_points(c: GameController) -> Array[Vector2]:
	var out: Array[Vector2]=[]
	if not bottle_ready(c):
		return out
	var center := MovePlanner.node_at(c.state.active().pos)
	for x in range(-2,3):
		for y in range(-2,3):
			var at := MoveGrid.to_pos(center+Vector2i(x,y))
			if bottle_legal(c,at):
				out.append(at)
	return out


static func bottle_imp(c: GameController,at: Vector2) -> bool:
	if not bottle_legal(c,at):
		return false
	var f := c.state.active()
	for i in f.items.size():
		if f.items[i].get("gear","")=="gear_rk_bottle_imp":
			f.items.remove_at(i)
			break
	c._potions._spend_drink(f)
	c._encounters._spawn_at("imp",at,-1,f.ring_side)
	c.emit("gear_used",{"id":f.id,"gear":"gear_rk_bottle_imp"})
	return true


const CAPE := "gear_rk_dazzling_cape"


static func cape_ready(c: GameController) -> bool:
	var f := c.state.active()
	return f!=null and f.in_play() and f.actions_left>0 and not c.awaiting_reaction() and c.state.pending_cast.is_empty() and c.state.push_winner<0 and (not RedKingMind.is_wizard(c.state,f) or f.moves_taken==0) and not f.spell_effects.has("bones_of_the_earth") and not f.spell_effects.has("plane_walk") and not f.spell_effects.has("potion_burrowing") and FuryRules.target(c.state,f)==null and Contact.in_combat(c.state.figures,f) and ActiveGear.ready(f,CAPE)


static func cape_reach(c: GameController) -> MoveReach:
	return c.reach() if cape_ready(c) else MoveReach.new()


static func use_cape(c: GameController,f: Figure) -> bool:
	if not ActiveGear.spend(f,CAPE):
		return false
	c.emit("gear_used",{"id":f.id,"gear":CAPE})
	return true


const GUTTER := "gear_rk_gutter_flail"


static func gutter_bearer(f: Figure) -> bool:
	return f!=null and f.in_play() and f.melee!=null and f.melee.id=="two_handed" and not f.destroyed_weapons.has("two_handed") and not MagicEquipment.suppressed(f) and ActiveGear.has(f,GUTTER) and not f.spell_effects.has("blinding_light")


static func gutter_targets(c: GameController) -> Array[Figure]:
	var out: Array[Figure]=[]
	var f := c.state.figure(c.state.pending_gutter)
	if not gutter_bearer(f) or c.state.active()!=f:
		return out
	for t in Contact.enemies_of(c.state.figures,f):
		if not (RedKingMadMan.hunter(f) and RedKingMadMan.is_ryce(t)):
			out.append(t)
	return out


static func gutter_after_move(c: GameController,f: Figure,engaged: bool) -> void:
	if engaged or not gutter_bearer(f):
		return
	c.state.pending_gutter=f.id
	var targets := gutter_targets(c)
	if targets.is_empty():
		c.state.pending_gutter=-1
	elif f.side!=c.state.reaction_side:
		gutter_fight(c,targets[0].id)
	else:
		c.emit("gear_used",{"id":f.id,"gear":GUTTER,"offer":true})


static func gutter_fight(c: GameController,target: int) -> bool:
	var t := c.state.figure(target)
	if not gutter_targets(c).has(t) or c.awaiting_reaction() or not c.state.pending_cast.is_empty():
		return false
	var f := c.state.active()
	c.state.pending_gutter=-1
	c.emit("gear_used",{"id":f.id,"gear":GUTTER,"target":target})
	c._fate_combat.start(f,t,"fight")
	return true


static func gutter_skip(c: GameController) -> bool:
	if c.state.pending_gutter<0:
		return false
	c.state.pending_gutter=-1
	return true


static func bottle_floor_points(c: GameController) -> Dictionary:
	var out := {}
	if not bottle_ready(c,true):
		return out
	var f := c.state.active()
	var layout := FloorLayout.from_dict(c.state.board.floor_layout)
	var grid := LayeredGrid.new(layout,null,c.state.figures)
	var center := MovePlanner.node_at(f.pos)
	var origin := Vector3(f.pos.x,f.elevation,f.pos.y)
	for i in layout.surfaces.size():
		for dx in range(-2,3):
			for dy in range(-2,3):
				var n := Vector3i(center.x+dx,center.y+dy,i)
				if grid.open(n) and layout.world(n).distance_to(origin)<=1.001 and not ScenarioNull.field_at(c.state.board,layout.point(n)):
					out[n]=true
	return out


static func bottle_on_floor(c: GameController,n: Vector3i) -> bool:
	if not bottle_floor_points(c).has(n):
		return false
	var f := c.state.active()
	var layout := FloorLayout.from_dict(c.state.board.floor_layout)
	for i in f.items.size():
		if f.items[i].get("gear","")=="gear_rk_bottle_imp":
			f.items.remove_at(i)
			break
	c._potions._spend_drink(f)
	c._encounters._spawn_at("imp",layout.point(n),-1,f.ring_side,layout.surface_id(n),layout.height(n))
	c.emit("gear_used",{"id":f.id,"gear":"gear_rk_bottle_imp"})
	return true
