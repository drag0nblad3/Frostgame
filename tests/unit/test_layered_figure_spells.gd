extends TestCase


func _setup() -> GameController:
	var c := LayeredBattle.create(db(),terrain(),17)
	var f := c.state.figure(1)
	f.pos=Vector2(8,8)
	f.surface_id="street"
	f.elevation=0
	c.state.active_id=f.id
	f.actions_left=2
	return c


func test_solid_floor_blocks_healing_and_bolts() -> void:
	var c := _setup()
	var ally := c.state.figure(2)
	ally.pos=Vector2(8,8)
	ally.surface_id="upper"
	ally.elevation=3
	ally.health-=2
	var enemy := c.state.figure(4)
	enemy.pos=Vector2(9.5,8)
	enemy.surface_id="upper"
	enemy.elevation=3
	check(not c.can_cast("heal",ally.id))
	check(not c.can_cast("elemental_bolt",enemy.id))
	ally.pos=Vector2(8,9.5)
	ally.surface_id="street"
	ally.elevation=0
	check(c.can_cast("heal",ally.id))
	check(not c.can_cast("leap",ally.id))
	c.dice=LoadedDice.new([20])
	check(c.start_cast("heal",ally.id))
	check(c.finish_cast(0))
	check_eq(ally.health,ally.def.health)
	check_eq(c.state.active().actions_left,1)


func test_layered_save_preserves_active_floor_and_carried_treasure() -> void:
	var c := _setup()
	var f := c.state.active()
	f.surface_id="upper"
	f.elevation=3
	var token := c.state.treasure(1)
	token.carrier_id=f.id
	f.treasure_id=token.id
	var path := "user://layered_checkpoint_unit.dat"
	check(LayeredCheckpoint.save(c,path))
	var loaded := LayeredCheckpoint.load_battle(db(),path)
	check(loaded!=null)
	if loaded!=null:
		check_eq(loaded.state.active().surface_id,"upper")
		check_eq(loaded.state.active().elevation,3.0)
		check_eq(loaded.state.treasure(1).carrier_id,f.id)
		check_eq(loaded.state.active().actions_left,2)
	DirAccess.remove_absolute(path)
