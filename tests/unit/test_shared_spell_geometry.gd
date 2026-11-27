extends TestCase


func _setup(stacked: bool) -> GameController:
	var b:=make_board([],Vector2(20,12))
	if stacked:
		b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,20,12],"level":0},{"id":"roof","rect":[0,0,20,12],"level":3}],"solids":[[0,2.8,0,20,0.2,12]]}
	var f:=fig("wizard",0,Vector2(5,5))
	var t:=fig("thug",0,Vector2(6,5))
	if stacked:
		f.surface_id="street"
		t.surface_id="street"
	var c:=make_game(b,[f,t],LoadedDice.new([20,20]))
	c.state.spell_catalog=JsonFile.read("res://data/spells.json")
	c.state.spellbooks[0]={"invisibility":10,"true_sight":10,"dispel":10,"time_store":10,"heal":10}
	c.state.active_id=f.id
	f.actions_left=2
	return c


func test_figure_effect_and_counter_use_shared_spellbook() -> void:
	for stacked in [false,true]:
		var c:=_setup(stacked)
		var f:=c.state.active()
		var t:=c.state.figure(2)
		check(SpellAvailability.menu_options(c._magic,f).has("invisibility"))
		check(c.start_cast("invisibility",t.id))
		check(c.finish_cast(0))
		check(t.spell_effects.has("invisibility"))
		f.acted=false
		f.non_moves=0
		f.actions_left=2
		check(not c._magic.counter_options("dispel").is_empty())
		if stacked:
			t.surface_id="roof"
			t.elevation=3.0
			check(c._magic.counter_options("dispel").is_empty())
			t.surface_id="street"
			t.elevation=0.0
		check(c._magic.start_counter("dispel",0))
		check(c.finish_cast(0))
		check(not t.spell_effects.has("invisibility"))


func test_ordinary_potion_available_on_both_geometries() -> void:
	for stacked in [false,true]:
		var c:=_setup(stacked)
		var f:=c.state.active()
		f.health-=5
		f.items.append({"potion":"healing"})
		check(c._potions.can_drink("healing",f))
		check(c._potions.drink("healing",f))
		check_eq(f.health,f.def.health)
