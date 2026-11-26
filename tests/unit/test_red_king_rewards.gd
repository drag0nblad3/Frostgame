extends TestCase


func test_tables_and_central_bonus() -> void:
	var table := RedKingRewards.tables()
	check_eq(table["first"].size(),19)
	check_eq(table["second"].size(),19)
	check_eq(table["artefacts"].size(),20)
	check_eq(RedKingRewards.result(1,1),"gear_rk_lantern_of_holy_light")
	check_eq(RedKingRewards.result(20,19),"gear_rk_book_of_wisdom")
	check_eq(RedKingRewards.result(2,20),"artefact")
	var d := {"loot":[],"last_report":[],"pending_treasure":[{"token":0,"central":true,"rk_exchange":true,"first":12},{"token":1,"central":true,"rk_artefact":true,"first":10}]}
	check(RedKingRewards.exchange(d,Dice.new(14)))
	check(d["pending_treasure"][0].has("rk_roll"))
	check_eq(RedKingRewards.offer(d,d["pending_treasure"][0]),"")
	d["pending_treasure"][0]["rk_roll"]=[1,18]
	check(RedKingRewards.resolve_bonus(d,true,Dice.new(14)))
	check_eq(d["loot"].size(),1)
	check(RedKingRewards.catalog()[d["loot"][0]["gear"]]["artefact"])
	check(not d["loot"][0]["unlocked"])
	check_eq(RedKingRewards.offer(d,d["pending_treasure"][0]),"")


func test_artefact_uniqueness() -> void:
	var d := {"loot":[],"last_report":[]}
	var dice := Dice.new(84)
	for i in 20:
		check(RedKingRewards.award(d,"artefact",dice))
	check_eq(d["red_king_found_artefacts"].size(),20)
	check(not RedKingRewards.award(d,"artefact",dice))
	check_eq(d["loot"].size(),20)


func test_gear_stat_bonuses_are_not_combat_stats() -> void:
	var f := fig("wizard",0,Vector2(10,10))
	var catalog := RedKingRewards.catalog()
	var before_fight := f.effective_fight()
	var before_move := f.effective_move()
	for id in ["gear_rk_armring_of_strength","gear_rk_surefoot_boots"]:
		check(catalog[id]["live"])
		f.items.append({"gear":id,"gear_info":catalog[id]})
	check_eq(MagicEquipment.bonus(f,"fight_test"),5)
	check_eq(MagicEquipment.bonus(f,"move_test"),5)
	check_eq(f.effective_fight(),before_fight)
	check_eq(f.effective_move(),before_move)


func test_feather_blade_slot_discount() -> void:
	var unit := {"id":0,"type":"wizard","weapons":["two_handed","bow","dagger"]}
	var d := {"loot":[{"kind":"gear","gear":"gear_rk_the_feather_blade","owner":0}]}
	check_eq(CasterLoadout.carried(d,unit)["slots"],3)
	check_eq(CasterLoadout.carried(d,unit,0)["slots"],4)


func test_fixed_scenario_deployments() -> void:
	var packs := ContentProfile.registered().duplicate(true)
	packs["red_king"]["status"]="ready"
	var defs := FigureDb.load_files(FigureDb.FIGURES,FigureDb.WEAPONS,ContentProfile.new(["red_king"],packs))
	for id in ["red_king_sinkhole","red_king_hill"]:
		var s := ScenarioLoader.load_id(id,defs,terrain())
		for f in s.figures:
			check(s.board.can_stand(f.pos,Figure.BASE_RADIUS),"%s: illegal deployment at %s"%[id,f.pos])


func test_red_king_artefact_weapon_counters() -> void:
	var catalog := RedKingRewards.catalog()
	var f := fig("wizard",0,Vector2(10,10))
	var t := fig("wizard",1,Vector2(11,10))
	f.items.append({"gear":RedKingGear.FIRE,"gear_info":catalog[RedKingGear.FIRE]})
	RedKingGear.charge(f,"necromancer")
	check_eq(f.used_gear.get(RedKingGear.CHARGES,0),0)
	for i in 8:
		RedKingGear.charge(f,"elementalist")
	check_eq(f.used_gear[RedKingGear.CHARGES],5)
	f.items.clear()
	f.items.append({"gear":RedKingGear.WOE,"gear_info":catalog[RedKingGear.WOE]})
	check_eq(f.effective_will(),f.def.will+1)
	f.used_gear["rk_soulchill_will"]=2
	f.used_gear["rk_soulchill_fight"]=1
	check_eq(f.effective_will(),f.def.will-1)
	check_eq(f.effective_fight(),f.def.fight-1)
	check_eq(RedKingGear.armour(f,t),t.effective_armour())
