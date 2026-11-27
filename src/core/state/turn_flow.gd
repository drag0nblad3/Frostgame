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
	var before: Variant=RuleHooks.first("victory_before_turn",[_c])
	if before!=null and before.has("winner"):
		_finish(int(before["winner"]))
		return
	s.turn += 1
	var override: Variant=RuleHooks.first("turn_limit",[s])
	var limit:=int(s.scenario_data.get("turn_limit",GameState.MAX_TURNS if override==null else int(override)))
	if limit>0 and s.turn>limit:
		var decision: Variant=RuleHooks.first("victory_at_limit",[_c])
		if decision!=null and decision.has("winner"):
			_finish(int(decision["winner"]))
		else:
			_finish(-1 if s.treasures.is_empty() else TreasureRules.winner(s))
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
	RuleHooks.run("turn_priority",[_c,ini["rolls"]])
	resume_priority()


func resume_priority() -> void:
	var s := _c.state
	if s.scenario_data.has("rk_priority_choice") or s.scenario_data.has("rk_lightning_absorb") or s.over:
		return
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
			RuleHooks.run("turn_end",[_c])
			if s.scenario_data.has("rk_end_choice") or s.scenario_data.has("rk_direction_choice"):
				return
			resume_end_turn()
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
		RuleHooks.run("before_phase",[_c])
		s.fast_acts.clear()
		s.early.capture(s)
		if s.phase == Phase.CREATURE:
			ScenarioObjectives.spawn_worm(_c)
		if s.phase != Phase.CREATURE or not s.waiting(-1).is_empty():
			_c.emit("phase", {"phase": s.phase})


## A pending end-of-turn choice pauses before the remaining end-turn hooks.
func resume_end_turn() -> void:
	var s := _c.state
	if s.over or s.scenario_data.has("rk_end_choice") or s.scenario_data.has("rk_direction_choice"):
		return
	if RuleHooks.any("victory_after_turn",[s]) and _check_victory():
		return
	RuleHooks.run("turn_end_resume",[_c])
	_c._encounters.on_end_turn()
	start_turn()


func _check_victory() -> bool:
	var standing: Array[int] = []
	for side in _c.state.side_count():
		if not _c.state.side_figures(side).is_empty():
			standing.append(side)
	var s := _c.state
	var decision: Variant=RuleHooks.first("scenario_victory",[_c,standing])
	if decision!=null:
		if not decision.has("winner"):
			return false
		_finish(int(decision["winner"]))
		return true
	if not s.treasures.is_empty():
		if standing.size() <= 1:
			var survivor := standing[0] if standing.size() == 1 else -1
			for token in s.treasures:
				if not token.unresolved():
					continue
				var eligible := not token.frozen and not RuleHooks.any("treasure_guarded",[s,token])
				var secured := false
				if survivor >= 0:
					secured = eligible and (token.carrier_id >= 0 or _c.dice.d20()+int(RuleHooks.any("sticky_treasure",[s,survivor])) >= 15)
				if secured:
					_c._loot.secure(token, survivor)
					continue
				var claimed := false
				if eligible and token.on_ground():
					for side in s.side_count():
						if side!=survivor and RuleHooks.any("sticky_treasure",[s,side]) and _c.dice.d20()==20:
							_c._loot.secure(token,side)
							claimed=true
							break
				if not claimed:
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
