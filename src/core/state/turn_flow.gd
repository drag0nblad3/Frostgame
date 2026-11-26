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
	if RedKingMind.active(s) and s.turn>=8:
		RedKingMind.finish(_c)
		_finish(0)
		return
	s.turn += 1
	if s.turn > (18 if RedKingHerded.active(s) else GameState.MAX_TURNS):
		if RedKingVeil.active(s):
			RedKingVeil.finish(_c)
			_finish(0 if RedKingVeil.xp(_c,0)>0 else 1)
			return
		if s.treasures.is_empty():
			_finish(-1)
		else:
			if RedKingInvestigations.active(s):
				RedKingInvestigations.finish_unsearched(_c)
			_finish(TreasureRules.winner(s))
		return
	for f in s.figures:
		f.activated = false
		f.magic_exhausted = false
		f.walk_phases.clear()
		f.spell_effects.erase("time_walk")
		f.actions_left = 0
	s.fast_acts.clear()
	PackRules.clear(s)
	s.order.clear()
	s.order_index = 0
	s.phase = Phase.WIZARD
	if _can_telescope(s.reaction_side):
		s.pending_initiative = true
		_c.emit("initiative_choice", {"turn": s.turn})
		return
	_roll_initiative(false)


func _can_telescope(side: int) -> bool:
	var s := _c.state
	if not s.telescope_ready.has(side):
		return false
	for f in s.figures:
		if f.in_play() and f.side == side and f.def.role == "wizard":
			return true
	return false


func answer_initiative(use: bool) -> bool:
	if not _c.state.pending_initiative:
		return false
	_c.state.pending_initiative = false
	_roll_initiative(use)
	return true


func _roll_initiative(use: bool) -> void:
	var s := _c.state
	var bonuses := {}
	for f in s.figures:
		if f.in_play() and f.side >= 0 and f.spell_effects.has("awareness"):
			bonuses[f.side] = mini(4, int(bonuses.get(f.side, 0)) + 2)
	for side: int in s.telescope_ready.keys():
		if _can_telescope(side) and (side != s.reaction_side or use):
			bonuses[side] = int(bonuses.get(side, 0)) + 5
			s.telescope_ready.erase(side)
			_c.emit("telescope_used", {"side": side})
	var ini := Initiative.roll(_c.dice, s.side_count(), bonuses)
	s.order = ini["order"]
	s.order_index = 0
	s.phase = Phase.WIZARD
	s.early.capture(s)
	_c.emit("turn_start", {"turn": s.turn, "order": s.order, "rolls": ini["rolls"]})
	RedKingHill.priority(_c,ini["rolls"])
	_c.emit("phase", {"phase": s.phase})
	_settle()


func after_activation() -> void:
	if not _check_victory():
		_settle()


## Moves play on until some side has a figure to activate.
func _settle() -> void:
	var s := _c.state
	while not s.over and s.waiting(s.current_side()).is_empty():
		if s.phase == Phase.CREATURE:
			_c._magic.on_end_turn()
			CreatureEffects.end_turn(_c)
			RedKingSquatter.end_turn(_c)
			RedKingInvestigations.end_turn(_c)
			RedKingVeil.end_turn(_c)
			RedKingFire.end_turn(_c)
			RedKingMadMan.end_turn(_c)
			RedKingMind.end_turn(_c)
			RedKingHerded.end_turn(_c)
			RedKingSinkhole.end_turn(_c)
			RedKingTethers.end_turn(_c)
			RedKingBridge.end_turn(_c)
			if (RedKingMind.active(s) or RedKingHerded.active(s)) and _check_victory():
				return
			_c._encounters.on_end_turn()
			start_turn()
			return
		s.order_index += 1
		if s.order_index < s.order.size():
			continue
		s.order_index = 0
		var i := Phase.ORDER.find(s.phase) + 1
		if i >= Phase.ORDER.size():
			start_turn()
			return
		s.phase = Phase.ORDER[i]
		RedKingVeil.before_phase(_c)
		s.fast_acts.clear()
		s.early.capture(s)
		if s.phase == Phase.CREATURE:
			ScenarioObjectives.spawn_worm(_c)
		if s.phase != Phase.CREATURE or not s.waiting(-1).is_empty():
			_c.emit("phase", {"phase": s.phase})


func _check_victory() -> bool:
	var standing: Array[int] = []
	for side in _c.state.side_count():
		if not _c.state.side_figures(side).is_empty():
			standing.append(side)
	var s := _c.state
	if RedKingBridge.active(s):
		if not standing.is_empty():
			return false
		for token in s.treasures:
			if token.unresolved():
				_c._loot.lose(token)
		_finish(TreasureRules.winner(s))
		return true
	if RedKingTethers.active(s) and RedKingTethers.remaining(s)>0:
		if not standing.is_empty():
			return false
		_finish(-1)
		return true
	if RedKingHerded.active(s):
		if not standing.is_empty() and float(s.scenario_data.get("herd_veil",0.0))<s.board.size.y:
			return false
		for token in s.treasures:
			if token.unresolved():
				_c._loot.lose(token)
		_finish(TreasureRules.winner(s))
		return true
	if RedKingMind.active(s):
		var wizard := RedKingMind.wizard(s)
		if wizard!=null and wizard.in_play():
			return false
		RedKingMind.finish(_c)
		_finish(0)
		return true
	if RedKingMadMan.active(s):
		var living_warband := false
		for f in s.figures:
			if f.side>=0 and f.in_play() and not RedKingMadMan.hunter(f):
				living_warband=true
				break
		if not living_warband:
			for token in s.treasures:
				if token.unresolved():
					_c._loot.lose(token)
			_finish(TreasureRules.winner(s))
			return true
		if RedKingMadMan.unresolved(s):
			return false
		for token in s.treasures:
			if token.unresolved():
				return false
		_finish(TreasureRules.winner(s))
		return true
	if RedKingVeil.active(s):
		if not s.side_figures(0).is_empty():
			return false
		RedKingVeil.finish(_c)
		_finish(0 if RedKingVeil.xp(_c,0)>0 else 1)
		return true
	if RedKingInvestigations.active(s):
		if not standing.is_empty():
			return false
		RedKingInvestigations.finish_unsearched(_c)
		_finish(TreasureRules.winner(s))
		return true
	if not s.treasures.is_empty():
		if standing.size() <= 1:
			var survivor := standing[0] if standing.size() == 1 else -1
			for token in s.treasures:
				if not token.unresolved():
					continue
				var secured := false
				if survivor >= 0:
					secured = not token.frozen and not RedKingHill.guarded(s,token) and (token.carrier_id >= 0 or _c.dice.d20() >= 15)
				if secured:
					_c._loot.secure(token, survivor)
				else:
					_c._loot.lose(token)
			_finish(TreasureRules.winner(s))
			return true
		for token in s.treasures:
			if token.unresolved():
				return false
		_finish(TreasureRules.winner(s))
		return true
	if standing.size() > 1:
		return false
	_finish(standing[0] if standing.size() == 1 else -1)
	return true


func _finish(winner: int) -> void:
	_c.state.over = true
	_c.state.winner = winner
	_c.emit("game_over", {"winner": winner, "turn": _c.state.turn})
