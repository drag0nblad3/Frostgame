extends TestCase


func test_command_columns_fit_available_width() -> void:
	check_eq(BattleHud.action_columns(250.0,160.0,true),1)
	check_eq(BattleHud.action_columns(350.0,160.0,true),2)
	check_eq(BattleHud.action_columns(350.0,210.0,true),1)
	check_eq(BattleHud.action_columns(700.0,160.0,false),4)
	check_eq(BattleHud.action_columns(700.0,300.0,false),2)
	check_eq(BattleHud.action_columns(100.0,300.0,false),1)
	check_eq(BattleHud.action_columns(900.0,160.0,true),2)


func test_shared_command_glyphs() -> void:
	for key: String in ["move_confirm","attack_confirm","cast_confirm","resist_confirm","group_begin"]:
		check_eq(ActionArt.command(key,{}),MenuSymbols.ICONS["save"],key)
	for key: String in ["move_undo","items_back","mind_back"]:
		check_eq(ActionArt.command(key,{}),MenuSymbols.ICONS["back"],key)
	for key: String in ["jump","run_for_it","push_self_15"]:
		check_eq(ActionArt.command(key,{}),ActionArt.ICONS["move"],key)
	check_eq(ActionArt.command("attack_cancel",{}),ActionArt.ICONS["cancel"])
	check_eq(ActionArt.command("ammo_shot",{}),ActionArt.ICONS["shoot"])
	check_eq(ActionArt.command("fight_hand",{}),ActionArt.ICONS["fight"])
