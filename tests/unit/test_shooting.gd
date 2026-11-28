extends TestCase


func _shot(board: Board, shooter: String, target_at: Vector2, rolls: Array) -> GameController:
	var figs: Array[Figure] = [fig(shooter, 0, Vector2(10, 10)), fig("thug", 1, target_at)]
	var c := make_game(board, figs, LoadedDice.new(rolls))
	c.state.active_id = 1
	c.state.active().actions_left = 2
	return c


func test_hit_deals_damage() -> void:
	var c := _shot(make_board(), "archer", Vector2(20, 10), [14, 5])
	check(c.shoot(2), "clear shot")
	check_eq(c.state.figure(2).health, 10 - (16 - 10), "16 - Armour 10")


func test_target_win_no_damage() -> void:
	var c := _shot(make_board(), "archer", Vector2(20, 10), [5, 14])
	check(c.shoot(2), "shot taken")
	check_eq(c.state.figure(2).health, 10, "missed")


func test_ruin_blocks_sight() -> void:
	var c := _shot(make_board([["ruin", 14, 8, 2, 4]]), "archer", Vector2(20, 10), [])
	check(not c.can_shoot(2), "wall in the way")


func test_out_of_range() -> void:
	var c := _shot(make_board(), "archer", Vector2(36, 10), [])
	check_eq(Shooting.blocked_reason(c.state.board, c.state.figures, c.state.figure(1), c.state.figure(2)), "out of range")


func test_cover_modifiers() -> void:
	var board := make_board([["wall", 18.5, 8, 0.5, 4], ["rubble", 13, 8, 2, 4]])
	var los := LineOfSight.check(board, Vector2(10, 10), Vector2(20, 10))
	check_eq(los.cover, TerrainKind.Cover.HEAVY, "wall next to target")
	check_eq(los.intervening, 1, "rubble midway")
	check_eq(Shooting.target_mod(los), 5, "+4 heavy +1 intervening")


func test_standing_in_rubble_is_light_cover() -> void:
	var board := make_board([["rubble", 19, 9, 2, 2]])
	check_eq(LineOfSight.check(board, Vector2(10, 10), Vector2(20, 10)).cover, TerrainKind.Cover.LIGHT)


func test_crossbow_reload() -> void:
	var c := _shot(make_board(), "crossbowman", Vector2(20, 10), [1, 20])
	check(c.shoot(2), "first shot")
	check(not c.state.figure(1).loaded, "unloaded")
	c.state.figure(1).acted = false
	c.state.figure(1).actions_left = 2
	check(not c.can_shoot(2), "can't shoot unloaded")
	check(c.reload(), "reload")
	check(c.state.figure(1).loaded, "loaded again")


func test_can_shoot_into_combat() -> void:
	var figs: Array[Figure] = [fig("archer", 0, Vector2(10, 10)), fig("thug", 1, Vector2(20, 10)), fig("thug", 0, Vector2(21, 10))]
	var c := make_game(make_board(), figs, Dice.new(1))
	c.state.active_id = 1
	c.state.active().actions_left = 2
	check(c.can_shoot(2), "combat is a legal target")
	check_eq(ShotTarget.participants(c.state.figures, c.state.figure(2)).size(), 2)
	check(c.shoot(2))
	var event: GameEvent = c.history[0]
	check(event.data["target"] in [2, 3], "random combat participant")
	check_eq(event.data["declared"], 2)

func test_hasty_shot() -> void:
	var c := _shot(make_board(), "archer", Vector2(20, 10), [10, 9])
	c.state.active().moves_taken = 1
	check(c.shoot(2))
	check_eq(c.state.figure(2).health, 10, "hasty modifier makes it a tie")


func test_reload_and_shoot_same_activation() -> void:
	var c := _shot(make_board(), "crossbowman", Vector2(20, 10), [14, 5])
	c.state.active().loaded = false
	check(c.reload())
	check(c.can_shoot(2))
	check(c.shoot(2))
	check_eq(c.state.active().actions_left, 0)


func test_reload_after_shooting() -> void:
	var c := _shot(make_board(), "crossbowman", Vector2(20, 10), [1, 20])
	check(c.shoot(2))
	check(c.reload())
	check(c.state.active().loaded)
	check_eq(c.state.active().actions_left, 0)


func test_glow_adds_to_shooting_damage() -> void:
	var c := _shot(make_board(), "archer", Vector2(20, 10), [10, 5])
	c.state.figure(2).spell_effects["glow"] = true
	check(c.shoot(2))
	check_eq(c.state.figure(2).health, 5)


func test_wraith_bow_shoots_through_one_ruin_and_curse() -> void:
	var c := _shot(make_board([["ruin",14,8,2,4]]),"archer",Vector2(20,10),[10,5,1])
	var f := c.state.active()
	f.items.append({"gear":Shooting.WRAITH,"gear_info":RedKingRewards.catalog()[Shooting.WRAITH]})
	check(not c.can_shoot(2))
	check(c.can_shoot(2,true))
	check(c.shoot(2,true))
	check_eq(int(f.spell_effects.get("curse",0)),14)
	check(not ActiveGear.ready(f,Shooting.WRAITH))
	var blocked := _shot(make_board([["ruin",13,8,2,4],["ruin",17,8,2,4]]),"archer",Vector2(20,10),[])
	blocked.state.active().items.append({"gear":Shooting.WRAITH,"gear_info":RedKingRewards.catalog()[Shooting.WRAITH]})
	check(not blocked.can_shoot(2,true))


func test_enchanted_ammunition_capacity_and_consumption() -> void:
	var c := _shot(make_board(),"archer",Vector2(20,10),[14,5])
	var f := c.state.active()
	check(MagicAmmo.add(f))
	check(not MagicAmmo.add(f))
	f.items.append({"gear":MagicAmmo.ITEM,"gear_info":RedKingRewards.catalog()[MagicAmmo.ITEM]})
	for i in 3:
		check(MagicAmmo.add(f))
	check_eq(MagicAmmo.count(f),4)
	check(not MagicAmmo.add(f))
	f.spell_effects["enchant_weapon"]=true
	check(c.can_shoot(2,false,true))
	check(c.shoot(2,false,true))
	check_eq(MagicAmmo.count(f),3)
	check_eq(c.state.figure(2).health,3,"+1 ammunition bonus does not stack with Enchant Weapon")


func test_hunter_quiver_replaces_caster_quiver_slot() -> void:
	var unit := {"id":0,"type":"wizard","weapons":["staff","bow","dagger"]}
	var d := {"loot":[{"kind":"gear","gear":MagicAmmo.ITEM,"owner":0}]}
	check_eq(CasterLoadout.carried(d,unit)["slots"],3)

func test_figures_contribute_intervening_or_contact_cover() -> void:
	var a:=fig("archer",0,Vector2(10,10))
	var b:=fig("thug",1,Vector2(20,10))
	var obstacle:=fig("thug",1,Vector2(15,10))
	var units: Array[Figure]=[a,b,obstacle]
	var c:=make_game(make_board(),units,Dice.new(3))
	check_eq(Shooting.resolve_rolls(c.state.board,a,b,10,10)["mod"],1)
	obstacle.pos=Vector2(19,10)
	check_eq(Shooting.resolve_rolls(c.state.board,a,b,10,10)["mod"],2)
	obstacle.pos=Vector2(11,10)
	check_eq(Shooting.resolve_rolls(c.state.board,a,b,10,10)["mod"],0)
	obstacle.pos=Vector2(15,10)
	obstacle.elevation=4.0
	check_eq(Shooting.resolve_rolls(c.state.board,a,b,10,10)["mod"],0)


func test_head_or_torso_visible_around_ruin_edge() -> void:
	var c:=_shot(make_board([["ruin",14,9.8,2,0.4]]),"archer",Vector2(20,10),[])
	check(not LineOfSight.check(c.state.board,Vector2(10,10),Vector2(20,10)).clear)
	check(c.can_shoot(2),"exposed shoulder is legal")

func test_contact_cover_is_not_one_inch_proximity() -> void:
	var c:=_shot(make_board([["wall",18.5,8,0.5,4]]),"archer",Vector2(20,10),[])
	check_eq(Shooting.defence_modifier(c.state.board,c.state.figure(1),c.state.figure(2)),1)
	c.state.figure(2).pos=Vector2(19.5,10)
	check_eq(Shooting.defence_modifier(c.state.board,c.state.figure(1),c.state.figure(2)),2)
