extends TestCase


func test_eye_attaches_to_actual_wall_and_persists() -> void:
	var b:=make_board([],Vector2(20,16))
	b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,20,16],"level":0}],"solids":[[8,0,5,1,3,6]]}
	var f:=fig("wizard",0,Vector2(5,8))
	f.surface_id="street"
	var c:=make_game(b,[f],LoadedDice.new([20]))
	c.state.spell_catalog=JsonFile.read("res://data/spells.json")
	c.state.spellbooks[0]={"wizard_eye":10}
	c.state.active_id=f.id
	f.actions_left=2
	var options:=c._magic.counter_options("wizard_eye")
	check(not options.is_empty())
	if options.is_empty():
		return
	check(c._magic.start_counter("wizard_eye",0))
	check(c.finish_cast(0))
	var p:=WizardEye.marker(b,f)
	check(p!=null)
	if p==null:
		return
	check_eq(p.base_height,1.5)
	var restored:=BattleSnapshotParts.make_board(BattleSnapshotParts.board_data(b))
	check(WizardEye.marker(restored,f)!=null)
	check_eq(WizardEye.marker(restored,f).base_height,1.5)
