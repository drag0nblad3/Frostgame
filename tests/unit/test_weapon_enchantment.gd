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
