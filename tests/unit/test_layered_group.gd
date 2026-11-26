extends TestCase


func _setup() -> GameController:
	var c := LayeredBattle.create(db(),terrain(),17)
	c.state.phase=Phase.WIZARD
	c.state.order.assign([0,1])
	c.state.order_index=0
	return c


func _place(f: Figure,layout: FloorLayout,id: String,at: Vector2) -> void:
	f.surface_id=id
	f.pos=at
	f.elevation=layout.height(layout.node(id,at))


func test_group_eligibility_does_not_cross_solid_floor() -> void:
	var c := _setup()
	var s := c.state
	var layout := FloorLayout.from_dict(s.board.floor_layout)
	_place(s.figure(1),layout,"street",Vector2(8,8))
	_place(s.figure(2),layout,"upper",Vector2(8,8))
	_place(s.figure(3),layout,"street",Vector2(8,9.5))
	s.early.capture(s)
	check(Shooting.distance(s.figure(1),s.figure(2))<=EarlyPhase.RANGE)
	check(not LineOfSight.check_figures(s.board,s.figure(1),s.figure(2)).clear)
	check(not c.activatable().has(s.figure(2)))
	check(c.activatable().has(s.figure(3)))
	check(not c.begin_group([1,2]))
	check(c.begin_group([1,3]))


func test_layered_group_passes_and_checkpoint() -> void:
	var c := _setup()
	var s := c.state
	var layout := FloorLayout.from_dict(s.board.floor_layout)
	_place(s.figure(1),layout,"street",Vector2(1,5))
	_place(s.figure(2),layout,"street",Vector2(1,8))
	s.early.capture(s)
	check(c.begin_group([1,2]))
	check(c.activate(2))
	check(not c.can_act())
	var stairs := layout.node("stairs",Vector2(2,8))
	check(c.move_on_floor(stairs))
	check_eq(s.figure(2).surface_id,"stairs")
	c.end_activation()
	check(not c.activate(2))
	check(c.activate(1))
	c.end_activation()
	check_eq(s.group.stage,GroupActivation.SECOND)
	var snapshot := BattleSnapshot.capture(c)
	var restored := BattleSnapshot.rebuild(snapshot,db())
	check(restored!=null)
	if restored==null:
		return
	c=restored
	s=c.state
	check_eq(s.figure(2).surface_id,"stairs")
	check_eq(s.group.stage,GroupActivation.SECOND)
	check(c.activate(2))
	check(c.can_act())
	check_eq(s.figure(2).moves_taken,1)
	check_eq(MoveRules.allowance(s.figure(2)),3.0)
	c.end_activation()
	check(c.activate(1))
	c.end_activation()
	check(not s.group.in_progress())
	check(s.figure(2).activated)
	check(not s.figure(3).activated)
