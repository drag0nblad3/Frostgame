class_name GlobalConsumables
extends RefCounted


static func nullify(c: GameController) -> void:
	var s := c.state
	s.words.clear()
	s.storm_penalty = 0
	s.fast_acts.clear()
	s.board.darkness = false
	for t in s.figures:
		if not t.in_play():
			continue
		if t.shrunk_treasure_id >= 0:
			c._loot.cancel_shrinking(t)
		t.spell_effects.clear()
		t.elemental_shield = 0
		t.petrified_skip = false
		t.walk_phases.clear()
		t.stored_action_turn = -1
		if t.familiar:
			t.familiar = false
			t.def = t.def.with_bonuses({"health": -2})
			t.health = mini(t.health, t.def.health)
		if t.controller_id >= 0:
			c._magic.summons.release(t)
		c.emit("spell_expired", {"id": t.id, "spell": "all"})
	for p in s.board.pieces.duplicate():
		if p.cast_turn >= 0 and s.board.pieces.has(p):
			c._magic.terrain.remove(p)
	var casters: Array[Figure] = []
	for t in s.figures:
		if t.in_play() and t.def.role in ["wizard", "apprentice"]:
			casters.append(t)
	_null_test(c, casters, 0)


static func _null_test(c: GameController, casters: Array[Figure], index: int) -> void:
	if index >= casters.size():
		return
	var t := casters[index]
	if not t.in_play():
		_null_test(c, casters, index + 1)
		return
	c._magic.resistance.attempt(t, 14, _null_result.bind(c, casters, index))


static func _null_result(success: bool, c: GameController, casters: Array[Figure], index: int) -> void:
	var t := casters[index]
	if not success and t.in_play():
		c._hurt(t, 1, t, false)
	_null_test(c, casters, index + 1)


static func vacuum(c: GameController, f: Figure) -> void:
	for t in c.state.figures:
		if not t.in_play() or not t.def.traits.has("ethereal") or Shooting.distance(f, t) > 8.0:
			continue
		if not StatRoll.succeeds(c.dice.d20(), t.effective_will() + t.roll_penalty(), 20):
			c._hurt(t, t.health, f, false)
