class_name ControllerActivation
extends RefCounted
## Starting and ending activations for GameController, and spending actions.


static func activate(c: GameController, id: int) -> bool:
	var f := c.state.figure(id)
	if c.state.active_id != -1 or f == null or not c.activatable().has(f):
		return false
	f = PackRules.select(c, f)
	id = f.id
	c.state.active_id = id
	var time_walk := f.spell_effects.has("time_walk") and f.walk_phases.has(c.state.phase)
	var fast := c.state.is_fast(f)
	if not c.state.group.in_progress() or c.state.group.movement_pass():
		RedKingInvestigations.before_activation(c,f)
	if not c.state.group.in_progress() or c.state.group.movement_pass():
		c._magic.on_activate(f)
	if c.state.group.in_progress():
		c.state.group.start_member(c.state, f)
	else:
		if not fast and not time_walk:
			c.state.early.record_activation(c.state, f)
		f.actions_left = mini(f.action_limit(), 1) if time_walk else f.action_limit()
		if time_walk:
			f.walk_phases.erase(c.state.phase)
		else:
			f.moves_taken = 0
		f.acted = false
		f.non_moves = 0
		f.used_stored_action = false
	c.emit("activate", {"id": id})
	RedKingInvestigations.activation(c,f)
	RedKingVeil.activation(c,f)
	RedKingMind.activation(c,f)
	RealityCracks.activation(c,f)
	RedKingSquatter.record_contact(c)
	if not c.state.group.in_progress() or c.state.group.movement_pass():
		CreatureEffects.activation(c,f)
		RedKingSinkhole.activation(c,f)
	HolyLantern.flee(c,f)
	Swimming.activate(c,f)
	if not f.in_play():
		f.actions_left=0
	return true


static func can_end_activation(c: GameController) -> bool:
	var f := c.state.active()
	if f == null or c.state.pending_gutter>=0 or c.awaiting_reaction() or not c.state.pending_cast.is_empty():
		return false
	if FuryRules.target(c.state, f) == null or f.actions_left <= 0:
		return true
	for t in Contact.enemies_of(c.state.figures, f):
		if c.can_fight(t.id):
			return false
	if c.can_move() and (not c.reach().nodes().is_empty() if c.state.board.floor_layout.is_empty() else not c.layered_reach().cost.is_empty()):
		return false
	return true


static func end_activation(c: GameController) -> void:
	if not c.can_end_activation():
		return
	c._displacement.clear()
	var f := c.state.active()
	if f == null:
		return
	c.state.active_id = -1
	f.actions_left = 0
	c.emit("end_activation", {"id": f.id})
	if c.state.group.in_progress():
		var before := c.state.group.stage
		if before == GroupActivation.SECOND:
			c._magic.on_end_activation(f)
		var complete := c.state.group.finish_member(c.state, f)
		if complete:
			c.emit("group_complete", {"side": f.side})
			c._flow.after_activation()
		elif before != c.state.group.stage:
			c.emit("group_second", {"side": f.side})
		return
	f.activated = true
	c._magic.on_end_activation(f)
	PackRules.finish(c.state, f)
	c._flow.after_activation()


static func _spend(c: GameController, f: Figure) -> void:
	c._displacement.clear()
	f.actions_left -= 1
	f.acted = true
	f.non_moves += 1
