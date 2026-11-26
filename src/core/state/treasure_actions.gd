class_name TreasureActions
extends RefCounted
## GameController helper: the only writer of live treasure state.

var _c: GameController


func _init(c: GameController) -> void:
	_c = c


func can_pick_up(id: int) -> bool:
	return _c.can_act() and TreasureRules.can_pick_up(_c.state, _c.state.active(), _c.state.treasure(id))


func pick_up(id: int) -> bool:
	if not can_pick_up(id):
		return false
	var f := _c.state.active()
	var token := _c.state.treasure(id)
	_c._spend(f)
	f.treasure_id = id
	token.carrier_id = f.id
	_c.emit("treasure_pickup", {"id": f.id, "treasure": id})
	if not token.ever_collected:
		token.ever_collected = true
		_c._encounters.on_pickup()
	return true


func can_drop(at: Vector2) -> bool:
	if _c.state.group.movement_pass():
		return false
	var f := _c.state.active()
	if f == null or not f.in_play() or f.treasure_id < 0 or f.actions_left <= 0:
		return false
	if Contact.in_combat(_c.state.figures, f):
		return false
	if f.pos.distance_to(at) < 0.85 or f.pos.distance_to(at) > 1.25:
		return false
	if not _c.state.board.can_stand(at, TreasureRules.TOKEN_RADIUS):
		return false
	for other in _c.state.figures:
		if other.in_play() and other.pos.distance_to(at) < Figure.BASE_RADIUS + TreasureRules.TOKEN_RADIUS:
			return false
	return f.moves_taken == 0 or _c.can_act()


func drop(at: Vector2) -> bool:
	if not can_drop(at):
		return false
	var f := _c.state.active()
	if f.moves_taken > 0:
		_c._spend(f)
	else:
		f.actions_left -= 1
	_drop(f, at)
	return true


func drop_on_death(f: Figure) -> void:
	if f.treasure_id >= 0:
		_drop(f, f.pos)


func _drop(f: Figure, at: Vector2) -> void:
	var token := _c.state.treasure(f.treasure_id)
	token.carrier_id = -1
	token.pos = at
	f.treasure_id = -1
	_c.emit("treasure_drop", {"id": f.id, "treasure": token.id, "at": at})


func can_exit(node: Vector2i, r: MoveReach = null) -> bool:
	if not _c.can_move():
		return false
	var f := _c.state.active()
	if r == null:
		r = _c.reach()
	var at := MoveGrid.to_pos(node)
	if not r.can_reach(node) or TreasureRules.edge_distance(_c.state.board, at) > Figure.BASE_RADIUS + 0.01:
		return false
	# The lattice keeps the base on the table; budget one more half inch to cross the edge.
	if r.cost[node] + Figure.BASE_RADIUS > MoveRules.allowance(f) + 0.001:
		return false
	for enemy in _c.state.figures:
		if enemy.in_play() and enemy.side != f.side and Contact.touching(enemy.pos, at):
			return false
	return true


func exit_table(node: Vector2i) -> bool:
	if not can_exit(node):
		return false
	var f := _c.state.active()
	if not _c.move_to(node):
		return false
	if f.pos.distance_to(MoveGrid.to_pos(node)) > 0.01 or Contact.in_combat(_c.state.figures, f):
		return true
	if f.treasure_id >= 0:
		secure(_c.state.treasure(f.treasure_id), f.side)
	f.exited = true
	f.actions_left = 0
	_c.emit("exit", {"id": f.id})
	return true


func secure(token: TreasureToken, side: int) -> void:
	_clear_carrier(token)
	token.secured_by = side
	_c.emit("treasure_secured", {"treasure": token.id, "side": side})


func lose(token: TreasureToken) -> void:
	_clear_carrier(token)
	token.lost = true
	_c.emit("treasure_lost", {"treasure": token.id})


func _clear_carrier(token: TreasureToken) -> void:
	if token.carrier_id >= 0:
		var carrier := _c.state.figure(token.carrier_id)
		carrier.treasure_id = -1
		token.carrier_id = -1
