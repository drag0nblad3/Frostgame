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


func test_campaign_and_spell_item_helpers() -> void:
	var f := fig("wizard",0,Vector2(5,5))
	var t := fig("thug",1,Vector2(12,5))
	var c := make_game(make_board(),[f,t],Dice.new(3))
	var catalog := RedKingRewards.catalog()
	for id in ["gear_rk_hypnotic_puppet","gear_rk_sticky_finger_gloves"]:
		f.items.append({"gear":id,"gear_info":catalog[id]})
	check_eq(RedKingGear.puppet_penalty(f,t),-2)
	t.pos=Vector2(20,5)
	check_eq(RedKingGear.puppet_penalty(f,t),0)
	check(RedKingGear.sticky(c.state,0))
	f.exited=true
	check(RedKingGear.sticky(c.state,0))
	f.out_of_action=true
	check(not RedKingGear.sticky(c.state,0))
	check_eq(RedKingGear.destiny_survival(2),2)
	check_eq(RedKingGear.destiny_survival(9),8)


func test_equipment_traits() -> void:
	var catalog := RedKingRewards.catalog()
	var f := fig("wizard",0,Vector2(10,10))
	check(not f.levitates())
	f.items.append({"gear":"gear_rk_ring_of_levitation","gear_info":catalog["gear_rk_ring_of_levitation"]})
	check(f.levitates())
	check_eq(f.effective_will(),f.def.will-3)
	var dog := fig("war_hound",0,Vector2(12,10))
	dog.items.append({"gear":"gear_rk_mind_lock_collar","gear_info":catalog["gear_rk_mind_lock_collar"]})
	check(dog.mind_locked())
	check_eq(dog.effective_will(),dog.def.will)
	var construct := fig("medium_construct",0,Vector2(14,10))
	construct.items.append({"gear":"gear_rk_construct_spikes","gear_info":catalog["gear_rk_construct_spikes"]})
	check(construct.has_horns())


func test_creature_mask_cost_is_only_paid_on_redirection() -> void:
	var catalog := RedKingRewards.catalog()
	var wizard := fig("wizard",0,Vector2(10,10))
	var other := fig("thug",0,Vector2(12,10))
	var creature := fig("wolf",-1,Vector2(11,10))
	var c := make_game(make_board(),[wizard,other,creature],Dice.new(3))
	wizard.health=3
	wizard.items.append({"gear":"gear_rk_creature_mask","gear_info":catalog["gear_rk_creature_mask"]})
	check_eq(CreatureBot.weakest(c.state,creature),other)
	check_eq(wizard.effective_will(),wizard.def.will)
	CreatureBot.apply_mask_cost(c.state,creature,other)
	check_eq(wizard.effective_will(),wizard.def.will-1)
	other.out_of_action=true
	check_eq(CreatureBot.weakest(c.state,creature),wizard)
	CreatureBot.apply_mask_cost(c.state,creature,wizard)
	check_eq(wizard.effective_will(),wizard.def.will-1)


func test_charisma_specialist_cap() -> void:
	var d := {"units":[{"type":"wizard","id":0,"dead":false}],"loot":[]}
	for i in 5:
		d["units"].append({"type":"archer","id":i+1,"dead":false})
	check(not BaseResources.fits(d,db()))
	d["loot"].append({"gear":"gear_rk_amulet_of_charisma","kind":"gear","owner":0,"unlocked":true})
	check_eq(BaseResources.specialist_limit(d),5)
	check(BaseResources.fits(d,db()))
	check(not CampaignInventory.assign_item(d,0,-1,db()))


func test_incunabula_permanent_binding() -> void:
	var d := {"loot":[{"gear":"gear_rk_golden_incunabula","kind":"gear","owner":0}],"units":[{"type":"apprentice","id":0,"dead":false}]}
	check(CampaignInventory.bind_incunabula(d,0,"heal"))
	check(not CampaignInventory.bind_incunabula(d,0,"push"))
	check_eq(CampaignInventory.incunabula_bonus(d,0,"heal"),1)
	check_eq(CampaignInventory.incunabula_bonus(d,0,"push"),0)
	var f := fig("apprentice",0,Vector2(10,10))
	f.items.assign(CampaignInventory.loadout(d,0))
	check_eq(ActiveGear.casting_bonus(f,"heal"),1)
	check_eq(ActiveGear.casting_bonus(f,"push"),0)


func test_bottle_imp_consumed_in_combat() -> void:
	var f := fig("wizard",0,Vector2(10,10))
	var enemy := fig("thug",1,Vector2(11,10))
	var c := make_game(make_board(),[f,enemy],Dice.new(7))
	c.state.creature_db=db()
	c.state.active_id=f.id
	f.actions_left=2
	f.items.append({"gear":"gear_rk_bottle_imp","gear_info":RedKingRewards.catalog()["gear_rk_bottle_imp"]})
	check(GearActions.bottle_legal(c,Vector2(9,10)))
	check(not GearActions.bottle_legal(c,Vector2(8,10)))
	check(GearActions.bottle_imp(c,Vector2(9,10)))
	check_eq(f.actions_left,1)
	check(not ActiveGear.has(f,"gear_rk_bottle_imp"))
	check_eq(c.state.figures.back().def.id,"imp")
	check_eq(c.state.figures.back().side,-1)


func test_skull_staff_limits_and_casting_cost() -> void:
	var f := fig("wizard",0,Vector2(10,10))
	var c := make_game(make_board(),[f],Dice.new(4))
	c.state.creature_db=db()
	f.items.append({"gear":"gear_rk_skull_staff","gear_info":RedKingRewards.catalog()["gear_rk_skull_staff"]})
	check_eq(ActiveGear.casting_bonus(f,"animate_skull"),1)
	c._magic.summons.spawn(f,"animate_skull",Vector2(12,10),15,8)
	check(c.state.figures.back().used_gear.get("rk_skull_strong",false))
	check(c._magic.summons.can_place(f,"animate_skull",Vector2(14,10)))
	c._magic.summons.spawn(f,"animate_skull",Vector2(14,10),15,8)
	check(not c._magic.summons.can_place(f,"animate_skull",Vector2(15,10)))
	check_eq(ActiveGear.casting_bonus(f,"animate_skull"),-1)
	check_eq(ActiveGear.casting_bonus(f,"heal"),-2)


func test_enchanted_supply_awards_and_rituals() -> void:
	var draft := WarbandDraft.new(db())
	draft.choose_defaults()
	var p := CampaignProgress.new()
	p.start(draft.as_warband())
	var d := p.data
	d["games"]=1
	d["spells"]={"write_scroll":12,"brew_potion":12,"heal":8}
	check(RedKingRewards.award(d,RedKingMaterials.WAX,Dice.new(1)))
	check(RedKingRewards.award(d,RedKingMaterials.VIAL,Dice.new(1)))
	check_eq(RedKingMaterials.available(d,RedKingMaterials.WAX),6)
	check(Rituals.attempt(d,0,"write_scroll","heal",LoadedDice.new([20]),true))
	check_eq(RedKingMaterials.available(d,RedKingMaterials.WAX),5)
	check(d["loot"].back().get("enchanted",false))
	check(Rituals.attempt(d,0,"brew_potion","healing",LoadedDice.new([1]),true))
	check_eq(RedKingMaterials.available(d,RedKingMaterials.VIAL),6)
	var before := int(d["gold"])
	check(CampaignInventory.sell(d,0))
	check_eq(int(d["gold"]),before+10)
	check_eq(RedKingMaterials.available(d,RedKingMaterials.WAX),4)


func test_golden_fangs_trade_split_and_summon() -> void:
	var d := {"loot":[],"last_report":[]}
	check(RedKingRewards.award(d,RedKingMaterials.FANGS,Dice.new(1)))
	check_eq(RedKingMaterials.available(d,RedKingMaterials.FANGS),6)
	check(RedKingMaterials.split_fang(d,0))
	check_eq(RedKingMaterials.amount(d["loot"][0]),5)
	check_eq(RedKingMaterials.amount(d["loot"][1]),1)
	var f := fig("wizard",0,Vector2(10,10))
	var c := make_game(make_board(),[f],Dice.new(1))
	c.state.creature_db=db()
	f.items.append({"gear":RedKingMaterials.FANGS,"uses":2,"gear_info":RedKingRewards.catalog()[RedKingMaterials.FANGS]})
	c._magic.summons.spawn(f,"animate_skull",Vector2(12,10),15,8,true)
	var skull: Figure=c.state.figures.back()
	check_eq(skull.effective_fight(),skull.def.fight+1)
	check_eq(RedKingMaterials.fang_count(f),1)
	c._magic.summons.spawn(f,"animate_skull",Vector2(14,10),15,8,false)
	check_eq(RedKingMaterials.fang_count(f),1)


func test_lifelong_plant_consumed_on_twenty() -> void:
	var d := {"loot":[{"kind":"gear","gear":RedKingCampaignGear.PLANT,"owner":-1}]}
	var report: Array[String]=[]
	check_eq(RedKingCampaignGear.plant_roll(d,3,report),4)
	check_eq(d["loot"].size(),1)
	check_eq(RedKingCampaignGear.plant_roll(d,20,report),21)
	check(d["loot"].is_empty())


func test_shears_injury_persistent_and_temporary() -> void:
	var d := {"units":[{"type":"knight","id":0}],"last_report":[]}
	RedKingCampaignGear.shears_injury(d,0,LoadedDice.new([19]))
	check(d["rk_shears_used"])
	check_eq(InjuryRules.starting_loss(d["units"][0]),1)
	RedKingCampaignGear.shears_injury(d,0,LoadedDice.new([20]))
	check_eq(InjuryRules.bonuses(d["units"][0],{})["health"],-1)


func test_potion_staff_and_golden_bottle_consumption() -> void:
	var f := fig("wizard",0,Vector2(10,10))
	var c := make_game(make_board(),[f],LoadedDice.new([20,1]))
	c.state.active_id=f.id
	f.actions_left=2
	f.items.append({"gear":RedKingCampaignGear.POTION_STAFF,"potion":"strength","gear_info":RedKingRewards.catalog()[RedKingCampaignGear.POTION_STAFF]})
	check(c._potions.drink("strength"))
	check_eq(f.items.size(),1)
	check(not f.items[0].has("potion"))
	f.items.append({"gear":RedKingCampaignGear.GOLDEN_BOTTLE,"potion":"toughness","bottle_doses":2,"gear_info":RedKingRewards.catalog()[RedKingCampaignGear.GOLDEN_BOTTLE]})
	check(c._potions.drink("toughness"))
	check_eq(int(f.items[1]["bottle_doses"]),1)
	f.actions_left=2
	check(c._potions.drink("toughness"))
	check(f.poisoned)
	check_eq(int(f.items[1]["bottle_doses"]),0)
	check_eq(f.items.size(),2)


func test_elemental_amulet_passive_and_overload() -> void:
	var f := fig("wizard",0,Vector2(10,10))
	var c := make_game(make_board(),[f],LoadedDice.new([17]))
	f.items.append({"gear":RedKingElemental.AMULET,"gear_info":RedKingRewards.catalog()[RedKingElemental.AMULET]})
	c.state.reaction_side=f.side
	check_eq(RedKingElemental.reduce(c,f,5),4)
	f.used_gear[RedKingElemental.ARMED]=true
	check_eq(RedKingElemental.reduce(c,f,5),8)
	check(not ActiveGear.has(f,RedKingElemental.AMULET))


func test_gutter_flail_free_attack_after_charge() -> void:
	var f := fig("infantryman",0,Vector2(10,10))
	var t := fig("thug",1,Vector2(14,10))
	var c := make_game(make_board(),[f,t],LoadedDice.new([8,1]))
	c.state.active_id=f.id
	c.state.reaction_side=f.side
	f.actions_left=2
	f.items.append({"gear":GearActions.GUTTER,"gear_info":RedKingRewards.catalog()[GearActions.GUTTER]})
	check(c.move_to(Vector2i(26,20)))
	check_eq(c.state.pending_gutter,f.id)
	check(GearActions.gutter_fight(c,t.id))
	check_eq(f.actions_left,1)
	check(not f.acted)
	check_eq(c.state.pending_gutter,-1)
