class_name GameController
extends RefCounted
## The only thing that changes GameState. Players and bots call its actions;
## every change is announced as a GameEvent.

signal event_emitted(e: GameEvent)

var state: GameState
var dice: Dice
var history: Array[GameEvent] = []
var _flow: TurnFlow
var _loot: TreasureActions


func _init(s: GameState, d: Dice) -> void:
	state = s
	dice = d
	_flow = TurnFlow.new(self)
	_loot = TreasureActions.new(self)


func emit(type: String, data: Dictionary = {}) -> void:
	var e := GameEvent.new(type, data)
	history.append(e)
	event_emitted.emit(e)


func start_game() -> void:
	_flow.start_turn()


## Figures the side to play may activate now.
func activatable() -> Array[Figure]:
	if state.over:
		var none: Array[Figure] = []
		return none
	return state.waiting(state.current_side())


func activate(id: int) -> bool:
	var f := state.figure(id)
	if state.active_id != -1 or f == null or not activatable().has(f):
		return false
	state.active_id = id
	f.actions_left = 2
	f.moves_taken = 0
	f.acted = false
	emit("activate", {"id": id})
	return true


func can_move() -> bool:
	var f := state.active()
	return f != null and f.in_play() and f.actions_left > 0 and MoveRules.can_move(f, state.figures)


## Where the active figure could go with its next movement action.
func reach() -> MoveReach:
	var f := state.active()
	var grid := MoveGrid.new(state.board, f, state.figures)
	return MovePlanner.reach(grid, f.pos, MoveRules.allowance(f))


func move_to(node: Vector2i) -> bool:
	if not can_move():
		return false
	var r := reach()
	if not r.can_reach(node):
		return false
	var f := state.active()
	var path := r.path_to(node)
	f.pos = path[path.size() - 1]
	f.actions_left -= 1
	f.moves_taken += 1
	emit("move", {"id": f.id, "path": path, "cost": r.cost[node]})
	return true


## One non-move action (fight, shoot, reload) per activation.
func can_act() -> bool:
	var f := state.active()
	return f != null and f.in_play() and f.actions_left > 0 and not f.acted


func can_fight(target_id: int) -> bool:
	var t := state.figure(target_id)
	return can_act() and t != null and Contact.enemies_of(state.figures, state.active()).has(t)


func fight(target_id: int) -> bool:
	if not can_fight(target_id):
		return false
	var f := state.active()
	var t := state.figure(target_id)
	var res := Melee.resolve(dice, state.figures, f, t, state.critical_hits)
	_spend(f)
	res["id"] = f.id
	res["target"] = t.id
	emit("fight", res)
	_hurt(t, res["b_dmg"], f)
	_hurt(f, res["a_dmg"], t)
	return true


func can_shoot(target_id: int) -> bool:
	var t := state.figure(target_id)
	return can_act() and t != null and Shooting.blocked_reason(state.board, state.figures, state.active(), t) == ""


func shoot(target_id: int) -> bool:
	if not can_shoot(target_id):
		return false
	var f := state.active()
	var t := state.figure(target_id)
	var res := Shooting.resolve(dice, state.board, f, t, state.critical_hits)
	_spend(f)
	if f.ranged.needs_reload:
		f.loaded = false
	res["id"] = f.id
	res["target"] = t.id
	emit("shoot", res)
	_hurt(t, res["dmg"], f)
	return true


## Reload may replace the movement action (p. 34); never while engaged.
func can_reload() -> bool:
	var f := state.active()
	return f != null and f.in_play() and f.actions_left > 0 and f.ranged != null and f.ranged.needs_reload and not f.loaded and not Contact.in_combat(state.figures, f) and (f.moves_taken == 0 or can_act())


func reload() -> bool:
	if not can_reload():
		return false
	var f := state.active()
	if f.moves_taken > 0:
		_spend(f)
	else:
		f.actions_left -= 1
	f.loaded = true
	emit("reload", {"id": f.id})
	return true


func end_activation() -> void:
	var f := state.active()
	if f == null:
		return
	f.activated = true
	state.active_id = -1
	emit("end_activation", {"id": f.id})
	_flow.after_activation()


func _spend(f: Figure) -> void:
	f.actions_left -= 1
	f.acted = true


func _hurt(f: Figure, dmg: int, by: Figure) -> void:
	if dmg <= 0 or not f.in_play():
		return
	var out := Damage.apply(f, dmg)
	emit("damage", {"id": f.id, "by": by.id, "amount": dmg, "health": f.health})
	if out:
		_loot.drop_on_death(f)
		emit("out_of_action", {"id": f.id, "by": by.id})


func can_pick_up(id: int) -> bool:
	return _loot.can_pick_up(id)


func pick_up(id: int) -> bool:
	return _loot.pick_up(id)


func drop_treasure(at: Vector2) -> bool:
	return _loot.drop(at)


func exit_table(node: Vector2i) -> bool:
	return _loot.exit_table(node)


func can_drop_treasure(at: Vector2) -> bool:
	return _loot.can_drop(at)


func can_exit_table(node: Vector2i, r: MoveReach = null) -> bool:
	return _loot.can_exit(node, r)
