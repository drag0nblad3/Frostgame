extends TestCase


func test_independent_consequences_can_overlap_but_barriers_do_not() -> void:
	var queue: Array[GameEvent]=[
		GameEvent.new("damage",{"id":1}),
		GameEvent.new("heal",{"id":2}),
		GameEvent.new("magic_impact",{"id":3}),
		GameEvent.new("damage",{"id":1}),
		GameEvent.new("out_of_action",{"id":1})]
	check_eq(BattlePresentation.batch_size(queue),3)
	check_eq(queue.size(),5)
	check_eq(BattlePresentation.batch_size(queue.slice(3)),1)
	check_eq(BattlePresentation.batch_size(queue.slice(4)),1)
	queue.push_front(GameEvent.new("fight",{"id":1,"target":2}))
	check_eq(BattlePresentation.batch_size(queue),1)
	queue.clear()
	check_eq(BattlePresentation.batch_size(queue),0)


func test_simultaneous_effect_batch_is_bounded() -> void:
	var queue: Array[GameEvent]=[]
	for id in range(1,9):
		queue.append(GameEvent.new("damage",{"id":id}))
	check_eq(BattlePresentation.batch_size(queue),4)


func test_timeline_navigation_does_not_modify_battle() -> void:
	var c := make_game(make_board(),[fig("wizard",0,Vector2(2,2)),fig("thug",1,Vector2(20,20))],Dice.new(15))
	var events: Array[GameEvent]=[
		GameEvent.new("turn_start",{"turn":1,"rolls":[12,8],"order":[0,1]}),
		GameEvent.new("phase",{"phase":Phase.WIZARD}),
		GameEvent.new("activate",{"id":1}),
		GameEvent.new("damage",{"id":1,"amount":2,"health":12}),
		GameEvent.new("turn_start",{"turn":2,"rolls":[4,10],"order":[1,0]}),
		GameEvent.new("phase",{"phase":Phase.WIZARD}),
		GameEvent.new("activate",{"id":2})]
	var rng := c.dice._rng.state
	var health := c.state.figure(1).health
	var timeline := BattleTimeline.build(c.state,events)
	check_eq(timeline.size(),7)
	check_eq(timeline[3]["turn"],1)
	check("12 left" in timeline[3]["line"])
	check_eq(BattleTimeline.turn_jump(timeline,2,1),4)
	check_eq(BattleTimeline.turn_jump(timeline,6,-1),0)
	check_eq(BattleTimeline.turn_jump(timeline,6,1),6)
	check_eq(c.dice._rng.state,rng)
	check_eq(c.state.figure(1).health,health)
	check_eq(events.size(),7)
	check(c.history.is_empty())
