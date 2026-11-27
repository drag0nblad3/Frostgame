extends TestCase


func test_shared_move_and_contact_on_each_geometry() -> void:
	for mode: String in ["flat","uneven","stacked"]:
		var b:=make_board([],Vector2(16,12))
		var height:=0.0
		if mode=="uneven":
			b=BoardLoader.from_dict({"size":[16,12],"pieces":[{"kind":"raised_ground","rect":[1,1,13,10],"level":1.0}]},terrain())
			height=1.0
		elif mode=="stacked":
			b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,16,12],"level":0},{"id":"roof","rect":[1,1,13,10],"level":3}],"solids":[[1,2.8,1,13,0.2,10]]}
			height=3.0
		var f:=fig("knight",0,Vector2(4,5))
		var enemy:=fig("thug",1,Vector2(8,5))
		f.elevation=height
		enemy.elevation=height
		if mode=="stacked":
			f.surface_id="roof"
			enemy.surface_id="roof"
		var c:=make_game(b,[f,enemy],LoadedDice.new([20,1]))
		c.state.active_id=f.id
		f.actions_left=2
		var route:=c.movement_options("move")
		var destination: Variant=MovePlanner.node_at(Vector2(7,5)) if mode!="stacked" else b.floor_geometry().node("roof",Vector2(7,5))
		check(route.cost.has(destination),mode+" contact destination")
		if not route.cost.has(destination):
			continue
		check(is_equal_approx(float(route.cost[destination]),3.0),mode+" same movement cost")
		check(BattleMovementOptions.commit(c,"move",destination),mode+" commit")
		check_eq(f.elevation,height,mode+" height retained")
		check_eq(f.actions_left,1,mode+" one movement action")
		check(c.can_fight(enemy.id),mode+" melee eligibility")


func test_projected_roof_shot_uses_actual_height_and_does_not_mutate() -> void:
	var b:=make_board([],Vector2(20,16))
	b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,20,16],"level":0},{"id":"roof","rect":[2,2,16,12],"level":3}],"solids":[[2,2.8,2,16,0.2,12]]}
	var f:=fig("archer",0,Vector2(5,5))
	var below:=fig("thug",1,Vector2(8,5))
	var above:=fig("thug",1,Vector2(10,5))
	f.surface_id="roof"
	f.elevation=3.0
	below.surface_id="street"
	above.surface_id="roof"
	above.elevation=3.0
	var c:=make_game(b,[f,below,above],LoadedDice.new([20,1]))
	c.state.active_id=f.id
	f.actions_left=2
	var projected:=Vector3(6,3,5)
	check(not Shooting.possible_from_world(b,c.state.figures,f,projected,below))
	check(Shooting.possible_from_world(b,c.state.figures,f,projected,above))
	check_eq(BotTargets.shot_value_world(c.state,f,projected,below),0.0)
	check(BotTargets.shot_value_world(c.state,f,projected,above)>0.0)
	check_eq(BotTargets.best_legal_shot(c,f),above)
	check_eq(f.pos,Vector2(5,5))
	check_eq(f.elevation,3.0)
	check_eq(f.actions_left,2)


func test_floor_contact_across_seam_does_not_bypass_illusion() -> void:
	var b:=make_board([],Vector2(12,12))
	b.floor_layout={"surfaces":[{"id":"a","rect":[0,0,6,12],"level":0},{"id":"b","rect":[6,0,6,12],"level":0}]}
	var f:=fig("knight",0,Vector2(5.5,5))
	var t:=fig("thug",1,Vector2(6.5,5))
	f.surface_id="a"
	t.surface_id="b"
	var c:=make_game(b,[f,t],LoadedDice.new([20,1]))
	check(Contact.figures_touch(f,t))
	check_eq(MovementContact.enemies_at(c.state.figures,f,f.pos,0.0,"a").size(),1)
