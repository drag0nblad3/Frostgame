extends TestCase


func test_checkpoint_preserves_live_state_and_rng() -> void:
	var a := fig("wizard", 0, Vector2(10, 10), 1)
	var b := fig("thug", 1, Vector2(20, 20), 2)
	var c := make_game(make_board([["wall", 14, 14, 1, 3]]), [a, b], Dice.new(4242))
	c.state.creature_db = db()
	c.state.spellbooks[0] = {"heal": 8}
	c.start_game()
	a.health = 5
	a.spell_effects["strength"] = 14
	a.items.append({"gear": "gear_fate_stone"})
	a.used_gear["gear_fate_stone"] = true
	a.def = a.def.with_bonuses({"health": 2})
	var token := TreasureToken.new(0, a.pos)
	token.carrier_id = a.id
	a.treasure_id = 0
	c.state.treasures.append(token)
	c.emit("cast_result", {"id": 1, "success": true, "tn": 8})
	var kind := TerrainKind.new()
	kind.id = "spell_wizard_eye"
	var eye := TerrainPiece.new(kind, Rect2(13, 14, 0.1, 0.1))
	eye.eye_host = c.state.board.pieces[0]
	c.state.board.pieces.append(eye)
	check(BattleSnapshot.save(c, {"scenario": "test"}, "user://battle_snapshot_test.dat"))
	var data := BattleSnapshot.read("user://battle_snapshot_test.dat")
	var loaded := BattleSnapshot.rebuild(data, db())
	check(loaded != null)
	if loaded == null:
		return
	check_eq(loaded.state.figure(1).health, 5)
	check_eq(loaded.state.figure(1).def.health, 16)
	check_eq(loaded.state.figure(1).treasure_id, 0)
	check_eq(loaded.state.treasure(0).carrier_id, 1)
	check_eq(loaded.state.board.pieces[1].eye_host, loaded.state.board.pieces[0])
	check_eq(loaded.state.early.leaders, c.state.early.leaders)
	check_eq(loaded.state.order, c.state.order)
	check_eq(loaded.history.size(), c.history.size())
	check_eq(loaded.state.figure(1).spell_effects, a.spell_effects)
	check(not ActiveGear.ready(loaded.state.figure(1), "gear_fate_stone"))
	for i in 10:
		check_eq(loaded.dice.d20(), c.dice.d20())
	DirAccess.remove_absolute("user://battle_snapshot_test.dat")


func test_checkpoint_blocks_pending_roll() -> void:
	var c := make_game(make_board(), [fig("wizard", 0, Vector2(4, 4)), fig("thug", 1, Vector2(14, 14))], Dice.new(3))
	c.state.pending_cast = {"caster": 1}
	check(not BattleSnapshot.can_save(c))
	check(BattleSnapshot.capture(c).is_empty())
