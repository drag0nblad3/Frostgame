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
	var f := c.state.active()
	if f == null or c.awaiting_reaction():
		return false
	if f.side >= 0 and f.def.health - f.health >= 4 and c._potions.can_drink("healing"):
		c._potions.drink("healing")
	if f.side < 0:
		CreatureBot.play(c, f)
	elif not MagicBot.play(c, f) and not TreasureBot.play(c, f):
		if f.ranged != null:
			_play_shooter(c, f)
		else:
			_play_fighter(c, f)
	if c.awaiting_reaction():
		return true
	if c.state.push_winner == f.id and f.treasure_id >= 0 and c.can_push(true):
		c.resolve_push(true)
	c.end_activation()
	return true


## Figures already in combat go first, then shooters, then the rest.
static func _pick(c: GameController) -> Figure:
	var options := c.activatable()
	if options.is_empty():
		return null
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
	if c.can_act():
		c.fight(t.id)
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
		c.reload()
		return
	var t := BotTargets.best_shot(c.state, f)
	if t != null:
		c.shoot(t.id)
		return
	if not c.can_move():
		return
	var r := c.reach()
	var spot := BotTargets.shooting_spot(c.state, f, r)
	if not spot.is_empty():
		c.move_to(spot["node"])
		if c.can_shoot(spot["target"].id):
			c.shoot(spot["target"].id)
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
