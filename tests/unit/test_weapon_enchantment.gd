extends TestCase

func test_individual_weapons_keep_their_own_enchantments() -> void:
	var f:=fig("ranger",0,Vector2(10,10))
	var enemy:=fig("thug",1,Vector2(11,10),2)
	var c:=make_game(make_board(),[f,enemy],Dice.new(3))
	check(WeaponEnchantment.add(f,"hand_weapon"))
	check(not WeaponEnchantment.add(f,"hand_weapon"))
	check(WeaponEnchantment.active(f,f.melee))
	check(not WeaponEnchantment.active(f,f.ranged))
	check_eq(Melee.fight_mod(c.state.figures,f,enemy),f.effective_fight()+1)
	check(WeaponEnchantment.add(f,"bow"))
	check(WeaponEnchantment.active(f,f.ranged))
	WeaponEnchantment.remove(f,"hand_weapon")
	check(not WeaponEnchantment.active(f,f.melee))
	check(WeaponEnchantment.active(f,f.ranged))

func test_switching_weapons_does_not_transfer_enchantment() -> void:
	var f:=fig("barbarian",0,Vector2(10,10))
	check(WeaponEnchantment.add(f,"two_handed"))
	for w in f.def.weapons:
		if w.id=="dagger":
			f.melee=w
	check(not WeaponEnchantment.active(f,f.melee))
	check_eq(WeaponEnchantment.ids(f),["two_handed"])

func test_dispel_one_weapon_not_both() -> void:
	var f:=fig("ranger",0,Vector2(10,10))
	var c:=make_game(make_board(),[f],Dice.new(3))
	WeaponEnchantment.add(f,"hand_weapon")
	WeaponEnchantment.add(f,"bow")
	c._magic.counter.apply({"kind":"weapon_enchantment","target":f.id,"spell":"enchant_weapon","weapon":"bow"})
	check_eq(WeaponEnchantment.ids(f),["hand_weapon"])


func test_cast_declares_specific_weapon_before_roll() -> void:
	var wizard:=fig("wizard",0,Vector2(10,10),1)
	var ranger:=fig("ranger",0,Vector2(14,10),2)
	var c:=make_game(make_board(),[wizard,ranger],LoadedDice.new([18]))
	c.state.spell_catalog=JsonFile.read("res://data/spells.json")
	c.state.spellbooks[0]={"enchant_weapon":8}
	c.state.active_id=1
	wizard.actions_left=2
	var options:=c._magic.counter_options("enchant_weapon")
	var index:=-1
	for i in options.size():
		if options[i]["target"]==ranger.id and options[i]["weapon"]=="hand_weapon":
			index=i
	check(index>=0)
	if index<0:
		return
	check(not c._magic.start_enchant(ranger.id,"staff"))
	check_eq((c.dice as LoadedDice).queue,[18])
	check(BattleSpellAction.execute(c,"counter",{"spell":"enchant_weapon","index":index}))
	check_eq(c.state.pending_cast.get("effect",{}).get("weapon",""),"hand_weapon")
	check(c.finish_cast(0))
	check_eq(WeaponEnchantment.ids(ranger),["hand_weapon"])
	check(not WeaponEnchantment.active(ranger,ranger.ranged))

func test_legacy_enchantment_migrates_before_weapon_switch() -> void:
	var f:=fig("barbarian",0,Vector2(10,10))
	f.spell_effects["enchant_weapon"]=true
	WeaponEnchantment.migrate(f)
	for w in f.def.weapons:
		if w.id=="dagger":
			f.melee=w
	check_eq(WeaponEnchantment.ids(f),["two_handed"])
	check(not WeaponEnchantment.active(f,f.melee))
