extends TestCase

func test_ordinary_weapon_only_elemental_damage_against_genie() -> void:
	var a:=fig("thug",0,Vector2(10,10),1)
	var b:=fig("genie",1,Vector2(11,10),2)
	var c:=make_game(make_board(),[a,b],LoadedDice.new([19,1]))
	check(WeaponEnchantment.add(a,"hand_weapon",WeaponEnchantment.HAMMER))
	var r:=Melee.resolve_rolls(c.state.figures,a,b,19,1)
	check_eq(r["b_dmg"],5)
	check_eq(r["b_hammer"],5)
	c.state.active_id=1
	a.actions_left=2
	check(c.fight(2))
	check_eq(b.health,b.def.health-5)
	check(not WeaponEnchantment.active(a,a.melee,WeaponEnchantment.HAMMER))

func test_hammer_stays_with_melee_weapon_when_shooting() -> void:
	var a:=fig("ranger",0,Vector2(10,10),1)
	var b:=fig("thug",1,Vector2(20,10),2)
	var c:=make_game(make_board(),[a,b],LoadedDice.new([1,20]))
	check(WeaponEnchantment.add(a,"hand_weapon",WeaponEnchantment.HAMMER))
	check(WeaponEnchantment.add(a,"bow",WeaponEnchantment.HAMMER))
	c.state.active_id=1
	a.actions_left=2
	check(c.shoot(2))
	check(WeaponEnchantment.active(a,a.melee,WeaponEnchantment.HAMMER))
	check(not WeaponEnchantment.active(a,a.ranged,WeaponEnchantment.HAMMER))

func test_missile_resistance_only_reduces_normal_damage() -> void:
	var a:=fig("archer",0,Vector2(10,10),1)
	var b:=fig("genie",1,Vector2(20,10),2)
	var c:=make_game(make_board(),[a,b],Dice.new(4))
	check(WeaponEnchantment.add(a,"bow",WeaponEnchantment.HAMMER))
	var r:=Shooting.resolve_rolls(c.state.board,a,b,19,1)
	check_eq(r["dmg"],5)
	check_eq(r["hammer"],5)
