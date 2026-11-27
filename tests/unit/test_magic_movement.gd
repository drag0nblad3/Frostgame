extends TestCase


func _game(rolls: Array) -> GameController:
	var c := make_game(make_board(), [fig("wizard", 0, Vector2(10, 10)), fig("thug", 0, Vector2(12, 10)), fig("thug", 1, Vector2(20, 10))], LoadedDice.new(rolls))
	c.state.spell_catalog = JsonFile.read("res://data/spells.json")
	c.state.spellbooks[0] = {"teleport": 10, "leap": 8, "transpose": 12, "push": 8}
	c.state.active_id = 1
	c.state.active().actions_left = 2
	return c


func test_leap_and_exhaustion() -> void:
	var c := _game([18])
	check(c._magic.start_move("leap", 2, Vector2(12, 18)))
	check(c.finish_cast(0))
	check_eq(c.state.figure(2).pos, Vector2(12, 18))
	check_eq(c.state.figure(2).action_limit(), 0)


func test_teleport() -> void:
	var c := _game([18])
	check(c._magic.start_at("teleport", Vector2(15, 15)))
	check(c.finish_cast(0))
	check_eq(c.state.active().pos, Vector2(15, 15))
	check_eq(c.state.active().actions_left, 0)


func test_transpose_resistance() -> void:
	var c := _game([18, 1])
	check(c._magic.start_swap(2, 3))
	check(c.finish_cast(0))
	check_eq(c.state.figure(2).pos, Vector2(20, 10))
	check_eq(c.state.figure(3).pos, Vector2(12, 10))


func test_ivory_hand_collision_and_full_push() -> void:
	var c := _game([20,1])
	var f := c.state.active()
	var target := c.state.figure(3)
	f.items.append({"gear":"gear_rk_ivory_hand","gear_info":RedKingRewards.catalog()["gear_rk_ivory_hand"]})
	target.pos=Vector2(c.state.board.size.x-1,10)
	var hp := target.health
	c._magic.movement.push(f,target)
	check_eq(target.health,hp-3)
	check(target.pos.x>c.state.board.size.x-1)
	var other := _game([1,1])
	var caster := other.state.active()
	var t := other.state.figure(3)
	caster.items.append({"gear":"gear_staff_power1","ivory_graft":true,"gear_info":CampaignInventory.catalog()["gear_staff_power1"]})
	check(MagicMovement.ivory_hand(caster))
	var before := t.health
	other._magic.movement.push(caster,t)
	check_eq(t.health,before)


func test_ivory_graft_campaign_cost() -> void:
	var d := {"gold":500,"loot":[{"kind":"gear","gear":"gear_rk_ivory_hand","owner":-1},{"kind":"gear","gear":"gear_staff_power1","owner":0}]}
	check(CampaignInventory.graft_ivory(d,0,1))
	check_eq(d["gold"],0)
	check_eq(d["loot"].size(),1)
	check(d["loot"][0]["ivory_graft"])
	check(CampaignInventory.loadout(d,0)[0]["ivory_graft"])


func test_pulsing_gem_restricted_power_and_glow() -> void:
	var c := _game([1])
	var f := c.state.active()
	f.items.append({"gear":PowerPool.GEM,"gear_info":RedKingRewards.catalog()[PowerPool.GEM]})
	check_eq(PowerPool.available(f,"push"),0)
	check_eq(PowerPool.available(f,"blink"),4)
	check_eq(PowerPool.spend(f,2,"blink"),2)
	check_eq(PowerPool.available(f,"blink"),2)
	check_eq(f.shooting_defence_penalty(),-1)
	check_eq(PowerPool.spend(f,1,"blink"),1)
	check_eq(f.shooting_defence_penalty(),-2)


func test_blink_direction_decision() -> void:
	var c := _game([1,6])
	var caster := c.state.active()
	var target := c.state.figure(2)
	c.state.reaction_side=0
	caster.items.append({"gear":PowerPool.GEM})
	var before := target.pos
	c._magic.movement.blink(caster,target,15)
	check(c.awaiting_reaction())
	check_eq(target.pos,before)
	check(c.state.scenario_data["rk_direction_choice"]["gem"])
	check(RedKingDirection.answer(c,"gem"))
	check(not c.awaiting_reaction())
	check(target.pos!=before)
	check_eq(caster.shooting_defence_penalty(),-1)
