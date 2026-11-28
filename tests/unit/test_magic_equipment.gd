extends TestCase


func test_equipment_compatibility_and_damage() -> void:
	var draft := WarbandDraft.new(db())
	draft.choose_defaults()
	var p := CampaignProgress.new()
	p.start(draft.as_warband())
	p.data["gold"] = 1000
	check(CampaignInventory.buy(p.data, "gear_hand_weapon_damage"))
	check(not CampaignInventory.assign_item(p.data, 0, 3, db()))
	check(CampaignInventory.assign_item(p.data, 0, 2, db()))
	var a := fig("thug", 0, Vector2(10, 10))
	a.items.assign(CampaignInventory.loadout(p.data, 2))
	check_eq(MagicEquipment.bonus(a, "damage", "hand_weapon"), 1)
	var b := fig("thug", 1, Vector2(11, 10))
	var figs: Array[Figure] = [a, b]
	check_eq(Melee.resolve(LoadedDice.new([12, 1]), figs, a, b)["b_dmg"], 5)


func test_gear_roll_and_loss() -> void:
	var d := {"loot": []}
	CampaignInventory.identify(d, {"kind": "magic arms/armour"}, LoadedDice.new([1]))
	check_eq(d["loot"][0]["gear"], "gear_hand_weapon_damage")
	d["loot"][0]["owner"] = 2
	CampaignInventory.lose_owned(d, 2)
	check(d["loot"].is_empty())


func test_magic_bow_bonus_is_not_magic_attack() -> void:
	var a:=fig("archer",0,Vector2(10,10))
	var b:=fig("genie",1,Vector2(20,10))
	var c:=make_game(make_board(),[a,b],Dice.new(4))
	a.spell_effects["enchant_weapon"]=true
	check(not WeaponActions.magic_attack(a,a.ranged))
	var normal:=Shooting.resolve_rolls(c.state.board,a,b,19,1)
	check_eq(normal["s_total"],22)
	check_eq(normal["dmg"],0)
	var magic:=Shooting.resolve_rolls(c.state.board,a,b,19,1,false,0,false,true)
	check_eq(magic["s_total"],22,"magic ammo and enchanted bow do not stack")
	check(magic["dmg"]>0)
