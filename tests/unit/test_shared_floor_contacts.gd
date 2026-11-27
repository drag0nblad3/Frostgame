extends TestCase


func _game(stacked: bool,dice: Dice) -> GameController:
	var b:=make_board([],Vector2(20,12))
	if stacked:
		b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,20,12],"level":0},{"id":"roof","rect":[0,0,20,12],"level":3}]}
	var f:=fig("thug",0,Vector2(3,5))
	var t:=fig("wizard",1,Vector2(7,5))
	if stacked:
		f.surface_id="street"
		t.surface_id="street"
	var c:=make_game(b,[f,t],dice)
	c.state.active_id=f.id
	f.actions_left=2
	return c


func test_beauty_and_invisibility_follow_same_contact_policy() -> void:
	for stacked in [false,true]:
		var c:=_game(stacked,LoadedDice.new([1]))
		var f:=c.state.active()
		var t:=c.state.figure(2)
		var n: Variant=Vector3i(12,10,0) if stacked else Vector2i(12,10)
		t.spell_effects["invisibility"]=true
		check(not c.movement_options().cost.has(n),"unseen enemy cannot be contacted")
		t.spell_effects.erase("invisibility")
		t.spell_effects["beauty"]=18
		check(c.movement_options().cost.has(n))
		check(c.commit_movement("move",n))
		check_eq(f.pos,Vector2(3,5))
		check_eq(f.actions_left,2)
		check(not c.movement_options().cost.has(n),"failed Beauty prevents repeat approach")


func test_floor_guard_reaction_respects_floor_and_commit() -> void:
	var c:=_game(true,Dice.new(1))
	var f:=c.state.active()
	var guard:=c.state.figure(2)
	guard.pos=Vector2(5,6.5)
	c.state.forced_combat=true
	c.state.reaction_side=1
	var layout:=FloorLayout.from_dict(c.state.board.floor_layout)
	var n:=layout.node("street",Vector2(7,5))
	guard.surface_id="roof"
	guard.elevation=3.0
	var route:=c.layered_reach()
	var path:=PackedVector3Array()
	var surfaces: Array[String]=[]
	for step in route.path_to(n):
		path.append(layout.world(step))
		surfaces.append(layout.surface_id(step))
	check(c._displacement.intercept_floor(f,path,surfaces,[]).is_empty())
	guard.surface_id="street"
	guard.elevation=0.0
	# Direct authored route avoids a tie between multiple equal shortest paths.
	path=PackedVector3Array([Vector3(3,0,5),Vector3(4,0,5),Vector3(5,0,5),Vector3(6,0,5),Vector3(7,0,5)])
	surfaces.assign(["street","street","street","street","street"])
	var choice:=c._displacement.intercept_floor(f,path,surfaces,[])
	check(not choice.is_empty())
	LayeredMovement._offer_or_apply(c,f,path,surfaces,4.0,[],false,false,false)
	check(not c.state.pending_intercept.is_empty())
	check_eq(f.actions_left,2)
	check_eq(f.pos,Vector2(3,5))
	if not c.state.pending_intercept.is_empty():
		check(c.answer_intercept(true))
		check_eq(f.actions_left,1)
		check_eq(f.moves_taken,1)
		check(Contact.in_combat(c.state.figures,f))
