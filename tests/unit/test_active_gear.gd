extends TestCase


func test_staff_and_gloves() -> void:
	var c := make_game(make_board(), [fig("wizard", 0, Vector2(10, 10)), fig("thug", 1, Vector2(25, 25))], LoadedDice.new([5]))
	c.state.spell_catalog = JsonFile.read("res://data/spells.json")
	c.state.spellbooks[0] = {"fleet_feet": 10}
	c.state.active_id = 1
	var f := c.state.active()
	f.actions_left = 2
	f.items.append({"gear": "gear_staff_casting", "casting_spell": "fleet_feet"})
	f.items.append({"gear": "gear_gloves_casting"})
	check(GearActions.arm(c, "gear_gloves_casting"))
	check(c.start_cast("fleet_feet", 1))
	check_eq(c.state.pending_cast["total"], 11)
	check(c.finish_cast(0))
	check(f.spell_effects.has("fleet_feet"))
	check(not ActiveGear.ready(f, "gear_gloves_casting"))


func test_teleport_ring_once() -> void:
	var c := make_game(make_board(), [fig("thug", 0, Vector2(10, 10)), fig("thug", 1, Vector2(25, 25))], Dice.new(1))
	c.state.active_id = 1
	var f := c.state.active()
	f.actions_left = 2
	f.items.append({"gear": "gear_ring_teleportation"})
	check(not GearActions.teleport(c, Vector2(19, 10)))
	check(GearActions.teleport(c, Vector2(18, 10)))
	check_eq(f.pos, Vector2(18, 10))
	check_eq(f.actions_left, 1)
	check(not ActiveGear.ready(f, "gear_ring_teleportation"))


func test_opposing_worm_token_relocation() -> void:
	var packs := ContentProfile.registered().duplicate(true)
	packs["red_king"]["status"]="ready"
	var defs := FigureDb.load_files(FigureDb.FIGURES,FigureDb.WEAPONS,ContentProfile.new(["red_king"],packs))
	var f := fig("wizard",1,Vector2(10,10),1)
	var t := fig("thug",0,Vector2(20,20),2)
	var c := make_game(make_board(),[f,t],LoadedDice.new([1]))
	c.state.creature_db=defs
	f.items.append({"gear":WormRider.ITEM})
	c.state.reaction_side=0
	c.state.active_id=f.id
	f.actions_left=2
	check(WormRider.summon(c,Vector2(15,15)))
	check(c.awaiting_reaction())
	check(not WormRider.answer_relocation(c,Vector2(-1,-1)))
	check(WormRider.answer_relocation(c,Vector2(18,18)))
	check_eq(c.state.scenario_data["rk_worm_tokens"][0]["at"],Vector2(18,18))
	check(not c.awaiting_reaction())
