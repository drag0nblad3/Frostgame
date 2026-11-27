extends TestCase


func test_loader_retains_stacked_objectives_and_figure_support() -> void:
	var source: Dictionary=JsonFile.read(ScenarioLoader.DIR+"silent_tower.json")
	source["board"]="layered_silent_tower"
	source["treasures"]=[[18,18,"tower_roof"],[18,18,"street"]]
	var s:=ScenarioLoader.from_dict(source,db(),terrain())
	check(not s.scenario_data.has("support_errors"),str(s.scenario_data.get("support_errors",[])))
	check_eq(s.treasures[0].surface_id,"tower_roof")
	check_eq(s.treasures[1].surface_id,"street")
	for f in s.figures:
		check_eq(f.surface_id,"street")
		check_eq(f.elevation,0.0)


func test_spawn_uses_legal_lowest_support() -> void:
	var b:=make_board([],Vector2(12,12))
	b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,12,12],"level":0},{"id":"roof","rect":[0,0,12,12],"level":3}],"solids":[[0,2.8,0,12,0.2,12]]}
	var c:=make_game(b,[],Dice.new(1))
	c.state.creature_db=db()
	c._encounters._spawn("skeleton",0)
	check_eq(c.state.figures.size(),1)
	if c.state.figures.size()==1:
		var f:=c.state.figures[0]
		check_eq(f.surface_id,"street")
		check_eq(f.elevation,0.0)
		check_eq(f.pos,Vector2(0.5,6.0))
