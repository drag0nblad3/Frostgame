class_name GameController
extends RefCounted
## The only thing that changes GameState. Players and bots call its actions;
## every change is announced as a GameEvent.

signal event_emitted(e: GameEvent)

var state: GameState
var dice: Dice
var history: Array[GameEvent] = []
var _flow: TurnFlow


func _init(s: GameState, d: Dice) -> void:
	state = s
	dice = d
	_flow = TurnFlow.new(self)


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
	return f != null and f.actions_left > 0 and MoveRules.can_move(f, state.figures)


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
	return f != null and f.actions_left > 0 and not f.acted


func fight(target_id: int) -> bool:
	var f := state.active()
	var t := state.figure(target_id)
	if not can_act() or t == null or not Contact.enemies_of(state.figures, f).has(t):
		return false
	var res := Melee.resolve(dice, state.figures, f, t)
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
	var res := Shooting.resolve(dice, state.board, f, t)
	_spend(f)
	if f.ranged.needs_reload:
		f.loaded = false
	res["id"] = f.id
	res["target"] = t.id
	emit("shoot", res)
	_hurt(t, res["dmg"], f)
	return true


## TODO(rules): check that reloading a crossbow uses the activation's one non-move action.
func reload() -> bool:
	var f := state.active()
	if not can_act() or f.ranged == null or not f.ranged.needs_reload or f.loaded:
		return false
	_spend(f)
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
		emit("out_of_action", {"id": f.id, "by": by.id})
