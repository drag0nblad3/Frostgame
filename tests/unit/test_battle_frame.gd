extends TestCase


func test_frame_history_is_independent_and_never_uses_future_positions() -> void:
	var c := make_game(make_board(),[fig("wizard",0,Vector2(2,2)),fig("thug",1,Vector2(20,20))],Dice.new(15))
	c.state.creature_db=db()
	c.capture_frames=true
	BattleFrame.record(c)
	var rng := c.dice._rng.state
	check(BattleRecord.run(c,"fixture",{},func() -> bool:
		c.state.figure(1).pos=Vector2(5,5)
		c.emit("fixture")
		return true))
	check_eq(c.replay_frames.size(),2)
	check_eq(BattleFrame.at_or_before(c.replay_frames,0)["figures"][0]["pos"],Vector2(2,2))
	check_eq(BattleFrame.at_or_before(c.replay_frames,1)["figures"][0]["pos"],Vector2(5,5))
	check(BattleFrame.at_or_before(c.replay_frames,-1).is_empty())
	check_eq(c.dice._rng.state,rng)
	var saved := BattleSnapshot.capture(c)
	check(not saved.is_empty())
	var restored := BattleSnapshot.rebuild(saved,db())
	check(restored!=null)
	if restored!=null:
		check_eq(restored.replay_frames,c.replay_frames)
		saved.erase("replay_frames")
		var legacy := BattleSnapshot.rebuild(saved,db())
		check(legacy!=null and legacy.replay_frames.is_empty())


func test_layered_frames_preserve_elevation_and_surface_identity() -> void:
	var board := BoardLoader.load_id("stacked_gatehouse",terrain())
	var c := make_game(board,[fig("wizard",0,Vector2(8,8)),fig("thug",1,Vector2(8,8))],Dice.new(15))
	c.state.figure(1).surface_id="street"
	c.state.figure(2).surface_id="upper"
	c.state.figure(2).elevation=3
	var frame := BattleFrame.capture(c)
	check_eq(frame["figures"][0]["pos"],frame["figures"][1]["pos"])
	check_eq(frame["figures"][0]["surface"],"street")
	check_eq(frame["figures"][1]["surface"],"upper")
	check_eq(frame["figures"][1]["height"],3.0)
	check_eq(frame["floors"].size(),4)


func test_frame_storage_bound_and_opt_in() -> void:
	var c := make_game(make_board(),[fig("wizard",0,Vector2(2,2)),fig("thug",1,Vector2(20,20))],Dice.new(15))
	BattleFrame.record(c)
	check(c.replay_frames.is_empty())
	c.capture_frames=true
	for i in range(BattleFrame.LIMIT+4):
		c.history.append(GameEvent.new("fixture"))
		BattleFrame.record(c)
	check_eq(c.replay_frames.size(),BattleFrame.LIMIT)
	check(BattleFrame.at_or_before(c.replay_frames,1).is_empty())
	BattleFrame.record(c)
	check_eq(c.replay_frames.size(),BattleFrame.LIMIT)
	check_eq(c.replay_frames[-1]["event_end"],BattleFrame.LIMIT+4)
