class_name Bot
extends RefCounted
## Plays a warband through GameController calls only: one activation at a time.
## Fighters charge the weakest enemy they can reach; shooters find a shot.


## Activates the next figure for the side to play and plays it out.
## Returns false if there was nothing to do.
static func play_activation(c: GameController) -> bool:
	var f := _pick(c)
	if f == null or not c.activate(f.id):
		return false
	return resume_activation(c)


static func resume_activation(c: GameController) -> bool:
	return BattleRecord.run(c,"bot_resume",{},func() -> bool: return _budgeted_resume(c))


static func _budgeted_resume(c: GameController) -> bool:
	var f:=c.state.active()
	if f==null:
		return false
	# A resumed reaction starts a new deterministic decision session. Do
	# not persist transient work counters in checkpoints or replay data.
	c.ai_work={"remaining":roundi(lerpf(1400.0,2600.0,BotPreference.trait_value(f,"deliberation")))}
	var result:=_resume(c)
	c.ai_work={}
	return result


static func _resume(c: GameController) -> bool:
	var f := c.state.active()
	if f == null or c.awaiting_reaction():
		return false
	if not c.state.pending_cast.is_empty():
		MagicBot.resolve(c)
		if c.awaiting_reaction():
			return true
	if f.side>=0:
		_use_healing(c,f)
		if c.awaiting_reaction():
			return true
	if f.side >= 0:
		if RedKingBot.prepare(c,f):
			if c.awaiting_reaction() or c.state.active()!=f:
				return true
	if not c.state.board.floor_layout.is_empty():
		if RedKingRingworld.active(c.state) and f.side>=0 and RingworldBot.play(c,f):
			return _finish(c,f)
		if FuryRules.target(c.state,f)!=null:
			FuryRules.play(c,f)
		else:
			LayeredBattleBot.perform(c,f)
		return _finish(c,f)
	if RedKingRingworld.active(c.state) and f.side>=0 and RingworldBot.play(c,f):
		pass
	elif RedKingMind.is_wizard(c.state,f):
		RedKingBot.mind(c,f)
	elif FuryRules.target(c.state, f) != null:
		FuryRules.play(c, f)
	elif f.side < 0:
		CreatureBot.play(c, f)
	elif c.can_drink_well():
		c.drink_well()
		TreasureBot.play(c, f)
	elif f.treasure_id >= 0 and TreasureBot.play(c, f):
		pass
	elif MagicBot.play(c, f):
		if not c.awaiting_reaction() and c.can_move():
			TreasureBot.play(c, f)
	elif not TreasureBot.play(c, f):
		if f.ranged != null:
			_play_shooter(c, f)
		else:
			_play_fighter(c, f)
	return _finish(c,f)


## The same reaction and withdrawal policy applies after either route provider.
static func _finish(c: GameController,f: Figure) -> bool:
	if c.awaiting_reaction() or c.state.active()!=f:
		return true
	if c.state.push_winner == f.id and f.side >= 0:
		var loser := c.state.figure(c.state.push_loser)
		if loser != null and (f.treasure_id >= 0 or not BotTargets.can_harm(f, loser, f.melee)) and c.can_push(true):
			c.resolve_push(true)
		elif loser != null and loser.treasure_id >= 0 and c.can_push(false):
			c.resolve_push(false)
	c.end_activation()
	return true


## Figures already in combat go first, then shooters, then the rest.
static func _pick(c: GameController) -> Figure:
	var options := c.activatable()
	if options.is_empty():
		return null
	for f in options:
		if f.treasure_id >= 0 and not Contact.in_combat(c.state.figures, f):
			return f
	for f in options:
		if Contact.in_combat(c.state.figures, f):
			return f
	for f in options:
		if f.ranged != null:
			return f
	return options[0]


static func _fight_if_engaged(c: GameController, f: Figure) -> bool:
	var t := BotTargets.weakest_contact(c.state, f)
	if t == null:
		return false
	if c.can_act() and c.state.push_winner<0:
		BattleAction.execute(c,"fight",t.id)
	return true


static func _play_fighter(c: GameController, f: Figure) -> void:
	if _fight_if_engaged(c, f):
		return
	for i in 2:
		if not c.can_move() or not f.in_play():
			return
		var r := c.reach()
		var spot := BotTargets.charge_spot(c.state, f, r)
		if not spot.is_empty():
			c.move_to(spot["node"])
			_fight_if_engaged(c, f)
			return
		if not _advance(c, f, r):
			return
		if _fight_if_engaged(c, f):
			return


static func _play_shooter(c: GameController, f: Figure) -> void:
	if _fight_if_engaged(c, f):
		return
	if f.ranged.needs_reload and not f.loaded:
		if not BattleAction.execute(c,"reload") or not c.can_act():
			return
	var t := BotTargets.best_legal_shot(c,f)
	if RedKingBot.special_shot(c,f,t):
		return
	if t != null:
		BattleAction.execute(c,"ammo_shot" if c.can_shoot(t.id,false,true) else "shoot",t.id)
		return
	if not c.can_move():
		return
	var r := c.reach()
	var spot := BotTargets.shooting_spot(c.state, f, r)
	if not spot.is_empty():
		c.move_to(spot["node"])
		if c.can_shoot(spot["target"].id):
			BattleAction.execute(c,"ammo_shot" if c.can_shoot(spot["target"].id,false,true) else "shoot",spot["target"].id)
		return
	_advance(c, f, r)


static func _advance(c: GameController, f: Figure, r: MoveReach) -> bool:
	var target := BotTargets.nearest_enemy(c.state, f)
	if target == null:
		return false
	var n: Variant = BotTargets.advance_node(c.state, f, r, target)
	if n == null:
		return false
	return c.move_to(n)



static func _use_healing(c: GameController, f: Figure) -> void:
	var target: Figure = null
	var value := 0.0
	for t in c.state.figures:
		if t.def.health - t.health < 3 or not c._potions.can_drink("healing", t):
			continue
		var score := float(t.def.health - t.health) * MagicTactics.importance(t)
		if score > value:
			target = t
			value = score
	if target != null:
		BattleEquipmentAction.execute(c,"drink",{"id":"healing","target":target.id})
