class_name BattleMovementOptions
extends RefCounted
## Shared legal route interface. Flat heightfields and explicit floor graphs
## are geometry providers; the HUD, input, confirmation and cost display never
## need to know which provider produced a destination.
var cost := {}
var routes := {}
var board: Board
var layout: FloorLayout
var flat: MoveReach
var floors: LayeredReach
var jumps := {}


static func query(c: GameController,mode: String,existing: MoveReach=null) -> BattleMovementOptions:
	var o:=BattleMovementOptions.new()
	o.board=c.state.board
	if c.state.active()==null:
		return o
	if o.board.floor_layout.is_empty():
		match mode:
			"run_for_it","run_talisman": o.flat=RunForIt.reach(c,mode=="run_talisman")
			"gear_cape_move": o.flat=GearActions.cape_reach(c)
			"jump": return o
			_: o.flat=existing if existing!=null else c.reach()
		for n: Vector2i in o.flat.nodes():
			if (mode=="exit" and c.can_exit_table(n,o.flat)) or (mode!="exit" and float(o.flat.cost[n])>0.001):
				o.cost[n]=o.flat.cost[n]
	else:
		o.layout=FloorLayout.from_dict(o.board.floor_layout)
		match mode:
			"jump":
				o.jumps=LayeredJump.plans(c)
				for n: Vector3i in o.jumps:
					o.cost[n]=o.jumps[n]["cost"]
				return o
			"run_for_it","run_talisman": o.floors=LayeredMovement.reach(c,false,true,mode=="run_talisman")
			"gear_cape_move": o.floors=LayeredMovement.reach(c,true)
			_: o.floors=c.layered_reach()
		if mode=="exit":
			for n: Vector3i in c.floor_exit_nodes():
				o.cost[n]=o.floors.cost[n]
		else:
			for n: Vector3i in o.floors.cost:
				if n!=o.floors.start:
					o.cost[n]=o.floors.cost[n]
	return o


func world(node: Variant) -> Vector3:
	if node is Vector3i:
		return layout.world(node)
	var at:=MoveGrid.to_pos(node)
	return Vector3(at.x,board.height_at(at),at.y)


func path(node: Variant) -> PackedVector3Array:
	if not cost.has(node):
		return PackedVector3Array()
	if jumps.has(node):
		return jumps[node]["path"]
	if routes.has(node):
		return routes[node]
	var result:=PackedVector3Array()
	if node is Vector3i:
		for n in floors.path_to(node):
			result.append(layout.world(n))
	else:
		for at in flat.path_to(node):
			result.append(Vector3(at.x,board.height_at(at),at.y))
	return result


static func commit(c: GameController,mode: String,node: Variant) -> bool:
	if node is Vector3i and not c.state.board.floor_layout.is_empty():
		match mode:
			"exit":
				if not c.exit_on_floor(node):
					return false
				c.end_activation()
				return true
			"run_for_it","run_talisman": return LayeredMovement.move(c,node,false,true,mode=="run_talisman")
			"gear_cape_move": return LayeredMovement.move(c,node,true)
			"jump": return c.jump_on_floor(node)
			"move": return c.move_on_floor(node)
	elif node is Vector2i and c.state.board.floor_layout.is_empty():
		match mode:
			"exit": return c.exit_table(node)
			"run_for_it","run_talisman": return RunForIt.apply(c,node,mode=="run_talisman")
			"gear_cape_move": return c.move_to(node,true)
			"move": return c.move_to(node)
	return false
