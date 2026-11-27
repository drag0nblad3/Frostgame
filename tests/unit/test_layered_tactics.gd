extends TestCase


func test_bot_teleports_to_disconnected_visible_treasure() -> void:
	var b := make_board([],Vector2(20,12))
	b.floor_layout={"surfaces":[{"id":"west","rect":[1,3,5,5],"level":4},{"id":"east","rect":[11,3,5,5],"level":4}]}
	var f := fig("wizard",0,Vector2(4,5))
	f.surface_id="west"
	f.elevation=4.0
	var c := make_game(b,[f],LoadedDice.new([20]))
	c.state.spell_catalog=JsonFile.read("res://data/spells.json")
	c.state.spellbooks[0]={"teleport":10}
	c.state.active_id=f.id
	f.actions_left=2
	var t := TreasureToken.new(0,Vector2(13,5))
	t.surface_id="east"
	c.state.treasures.append(t)
	check(LayeredBattleBot._move(c,f))
	check_eq(f.surface_id,"east")
	check_eq(f.actions_left,0)
	check(f.magic_exhausted)


func test_bot_prefers_ordinary_move_to_nearby_loot() -> void:
	var c := LayeredBattle.create(db(),terrain(),17)
	var f := c.state.figure(1)
	c.state.active_id=f.id
	f.actions_left=2
	f.pos=Vector2(7,7)
	f.surface_id="street"
	f.elevation=0.0
	check(LayeredBattleBot._move(c,f))
	check_eq(f.surface_id,"street")
	check_eq(f.moves_taken,1)
	check_eq(f.actions_left,1)


func test_layered_bot_cape_withdrawal() -> void:
	var b := make_board([],Vector2(20,12))
	b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,20,12],"level":0}]}
	var f := fig("wizard",0,Vector2(5,5))
	var enemy := fig("thug",1,Vector2(6,5))
	f.surface_id="street"
	enemy.surface_id="street"
	var c := make_game(b,[f,enemy],Dice.new(13))
	c.state.active_id=f.id
	f.actions_left=2
	f.items.append({"gear":GearActions.CAPE})
	check(Contact.in_combat(c.state.figures,f))
	check(LayeredBattleBot._cape(c,f))
	check(not Contact.in_combat(c.state.figures,f))
	check(f.used_gear.has(GearActions.CAPE))
