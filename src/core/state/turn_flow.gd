class_name TurnFlow
extends RefCounted
## Turn, phase and player order for GameController: who plays next, when a
## turn ends, and when the game is over.
## TODO(rules): victory is last warband standing (or a draw at the turn limit)
## until treasure and scenarios exist.

var _c: GameController


func _init(c: GameController) -> void:
	_c = c


func start_turn() -> void:
	var s := _c.state
	if s.over:
		return
	s.turn += 1
	if s.turn > GameState.MAX_TURNS:
		_finish(-1)
		return
	for f in s.figures:
		f.activated = false
		f.actions_left = 0
	var ini := Initiative.roll(_c.dice, s.side_count())
	s.order = ini["order"]
	s.order_index = 0
	s.phase = Phase.WIZARD
	_c.emit("turn_start", {"turn": s.turn, "order": s.order, "rolls": ini["rolls"]})
	_c.emit("phase", {"phase": s.phase})
	_settle()


func after_activation() -> void:
	if not _check_victory():
		_settle()


## Moves play on until some side has a figure to activate.
func _settle() -> void:
	var s := _c.state
	while not s.over and s.waiting(s.current_side()).is_empty():
		s.order_index += 1
		if s.order_index < s.order.size():
			continue
		s.order_index = 0
		var i := Phase.ORDER.find(s.phase) + 1
		if i >= Phase.ORDER.size():
			start_turn()
			return
		s.phase = Phase.ORDER[i]
		_c.emit("phase", {"phase": s.phase})


func _check_victory() -> bool:
	var standing: Array[int] = []
	for side in _c.state.side_count():
		if not _c.state.side_figures(side).is_empty():
			standing.append(side)
	if standing.size() > 1:
		return false
	_finish(standing[0] if standing.size() == 1 else -1)
	return true


func _finish(winner: int) -> void:
	_c.state.over = true
	_c.state.winner = winner
	_c.emit("game_over", {"winner": winner, "turn": _c.state.turn})
