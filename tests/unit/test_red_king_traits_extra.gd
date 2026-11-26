extends TestCase


func preview_db() -> FigureDb:
	var packs := ContentProfile.registered().duplicate(true)
	packs["red_king"]["status"]="ready"
	return FigureDb.load_files(FigureDb.FIGURES,FigureDb.WEAPONS,ContentProfile.new(["red_king"],packs))


func test_magic_senses_contact_and_item_suppression() -> void:
	var defs := preview_db()
	var wizard := fig("wizard",0,Vector2(10,10))
	var hrut := Figure.new(2,defs.get_def("hrut_warrior"),-1,Vector2(9,10),defs.unarmed())
	var nullman := Figure.new(3,defs.get_def("nullman"),-1,Vector2(12,10),defs.unarmed())
	var c := make_game(make_board(),[wizard,hrut,nullman],Dice.new(17))
	wizard.spell_effects["invisibility"]=true
	check(CreatureSenses.may_contact(hrut,wizard))
	CreatureSenses.reveal_contacts(c,hrut)
	check(not wizard.spell_effects.has("invisibility"))
	check(not MagicEquipment.suppressed(wizard))
	nullman.pos=Vector2(11,10)
	check(MagicEquipment.suppressed(wizard))
	nullman.pos=Vector2(14,10)
	check(not MagicEquipment.suppressed(wizard))


func test_control_immunity() -> void:
	var defs := preview_db()
	var wizard := fig("wizard",0,Vector2(10,10))
	var herald := Figure.new(2,defs.get_def("red_king_herald"),-1,Vector2(14,10),defs.unarmed())
	var c := make_game(make_board(),[wizard,herald],Dice.new(17))
	check(not c._magic.summons.can_control(wizard,herald,"control_demon"))
	check(not c._magic.summons.can_control(wizard,herald,"mind_control"))
