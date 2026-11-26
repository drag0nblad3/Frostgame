extends TestCase


func test_tower_null_field_blocks_casting_and_cancels_magic() -> void:
	var c := LayeredBattle.create(db(),terrain(),17,"layered_silent_tower")
	var f := c.state.figure(1)
	c.state.active_id=f.id
	f.actions_left=2
	f.pos=Vector2(18,18)
	f.surface_id="tower_second"
	f.elevation=6.0
	f.spell_effects["fleet_feet"]=true
	f.elemental_shield=3
	check(ScenarioNull.muted(f))
	ScenarioNull.enter(c,f)
	check(f.spell_effects.is_empty())
	check_eq(f.elemental_shield,0)
	check(c.state.tower_visitors.has(f.id))
	var layout := FloorLayout.from_dict(c.state.board.floor_layout)
	check(not LayeredMagic.can_teleport(c,layout.node("street",Vector2(4,4))))
	check(not LayeredBridge.eligible(c))
	check(not LayeredLeap.eligible(c,f))
	check(ScenarioNull.protected_treasure(c.state,Vector2(18,18)))
	check(not ScenarioNull.protected_treasure(c.state,Vector2(1,1)))
	check_eq(c.state.treasures.size(),5)


func test_tower_mundane_routes_are_usable() -> void:
	var c := LayeredBattle.create(db(),terrain(),17,"layered_silent_tower")
	var layout := FloorLayout.from_dict(c.state.board.floor_layout)
	check(layout.errors.is_empty(),str(layout.errors))
	var f := c.state.figure(2)
	c.state.active_id=f.id
	f.actions_left=2
	f.pos=Vector2(18,18)
	f.surface_id="tower_first"
	f.elevation=3.0
	check(c.layered_reach().can_reach(layout.node("tower_first",Vector2(19,18))))
