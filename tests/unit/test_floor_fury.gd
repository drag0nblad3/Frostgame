extends TestCase


func test_fury_ignores_hidden_lower_enemy_and_compels_charge() -> void:
	var b:=make_board([],Vector2(20,16))
	b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,20,16],"level":0},{"id":"roof","rect":[2,2,16,12],"level":3}],"solids":[[2,2.8,2,16,0.2,12]]}
	var f:=fig("thug",0,Vector2(8,8))
	var below:=fig("thug",1,Vector2(8,8))
	var enemy:=fig("thug",1,Vector2(12,8))
	for unit in [f,enemy]:
		unit.surface_id="roof"
		unit.elevation=3.0
	below.surface_id="street"
	var c:=make_game(b,[f,below,enemy],LoadedDice.new([18,1]))
	c.state.active_id=f.id
	f.actions_left=2
	f.spell_effects["potion_fury"]=true
	check_eq(FuryRules.target(c.state,f),enemy)
	check(not c.can_act())
	check(not c.can_end_activation())
	var layout:=b.floor_geometry()
	check(not c.move_on_floor(layout.node("roof",Vector2(6,8))))
	check(c.move_on_floor(layout.node("roof",Vector2(11,8))))
	check(c.can_fight(enemy.id))
	check(c.fight(enemy.id))
	check(c.can_end_activation())
