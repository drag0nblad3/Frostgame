extends TestCase


func _fixture() -> GameController:
	var b := make_board()
	b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,20,12],"level":0},{"id":"west","rect":[1,3,5,5],"level":4},{"id":"east","rect":[11,3,5,5],"level":4}],"solids":[[1,3.7,3,5,0.3,5],[11,3.7,3,5,0.3,5]]}
	var f := fig("wizard",0,Vector2(4,5))
	f.surface_id="west"
	f.elevation=4.0
	var c := make_game(b,[f],LoadedDice.new([20]))
	c.state.spell_catalog=JsonFile.read("res://data/spells.json")
	c.state.spellbooks[0]={"bridge":10}
	c.state.active_id=f.id
	f.actions_left=2
	return c


func test_cast_bridge_and_cross_preserves_lower_floor() -> void:
	var c := _fixture()
	var layout := FloorLayout.from_dict(c.state.board.floor_layout)
	var a := layout.node("west",Vector2(5.5,5))
	var b := layout.node("east",Vector2(11.5,5))
	check(not LayeredBridge.proposal(c,a,b,layout).is_empty())
	check(c.bridge_on_floors(a,b))
	check(c.finish_cast(0))
	layout=FloorLayout.from_dict(c.state.board.floor_layout)
	check(layout.errors.is_empty(),str(layout.errors))
	var f := c.state.active()
	var bridge := layout.node("bridge:1",Vector2(8,5))
	check(layout.standable(bridge))
	check(layout.standable(layout.node("street",Vector2(8,5))))
	check(c.move_on_floor(bridge))
	check_eq(f.surface_id,"bridge:1")
	check_eq(f.elevation,4.0)
	var restored := BattleSnapshot.rebuild(BattleSnapshot.capture(c),db())
	check(restored!=null)
	if restored!=null:
		check_eq(restored.state.active().surface_id,"bridge:1")
		check_eq(FloorLayout.from_dict(restored.state.board.floor_layout).height(bridge),4.0)


func test_bot_builds_bridge_to_disconnected_treasure() -> void:
	var c := _fixture()
	var f := c.state.active()
	var token := TreasureToken.new(0,Vector2(13,5))
	token.surface_id="east"
	c.state.treasures.append(token)
	var layout := FloorLayout.from_dict(c.state.board.floor_layout)
	var grid := LayeredGrid.new(layout,f,c.state.figures)
	var reach := LayeredReach.search(grid,layout.node(f.surface_id,f.pos),100.0)
	check(LayeredBridgeTactics.try_cast(c,f,layout,reach,grid))
	check_eq(LayeredBridge.owned(c.state,f.id),"bridge:1")


func test_bridge_collapse_moves_figures_and_treasure_to_ground() -> void:
	var c := _fixture()
	var layout := FloorLayout.from_dict(c.state.board.floor_layout)
	check(c.bridge_on_floors(layout.node("west",Vector2(5.5,5)),layout.node("east",Vector2(11.5,5))))
	check(c.finish_cast(0))
	var f := c.state.active()
	f.pos=Vector2(8,5)
	f.surface_id="bridge:1"
	f.elevation=4.0
	var hp := f.health
	var token := TreasureToken.new(0,Vector2(9,5))
	token.surface_id="bridge:1"
	c.state.treasures.append(token)
	c.dice=LoadedDice.new([1])
	LayeredBridge.expire(c)
	check_eq(f.surface_id,"street")
	check_eq(f.elevation,0.0)
	check_eq(f.health,hp-6)
	check_eq(token.surface_id,"street")
	check_eq(FloorLayout.from_dict(c.state.board.floor_layout).index_of("bridge:1"),-1)


func test_extended_bridge_span_and_expiry() -> void:
	var c := _fixture()
	var f := c.state.active()
	f.items.append({"gear":TerrainMagic.EXTENDED,"gear_info":RedKingRewards.catalog()[TerrainMagic.EXTENDED]})
	var layout := FloorLayout.from_dict(c.state.board.floor_layout)
	var a := layout.node("west",Vector2(3,5))
	var b := layout.node("east",Vector2(12,5))
	check(LayeredBridge.proposal(c,a,b,layout).get("extended",false))
	check(c.bridge_on_floors(a,b))
	check(c.finish_cast(0))
	check(not ActiveGear.ready(f,TerrainMagic.EXTENDED))
	c.dice=LoadedDice.new([2,1])
	LayeredBridge.expire(c)
	check(not LayeredBridge.owned(c.state,f.id).is_empty())
	LayeredBridge.expire(c)
	check(LayeredBridge.owned(c.state,f.id).is_empty())
