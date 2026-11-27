class_name RitualPanel
extends VBoxContainer

var campaign: CampaignProgress
var choices: OptionButton
var cast_button: Button
var enchant_supply: CheckButton
var shears: OptionButton
var bottle: CheckButton
var shield_roll: Button
var callback: Callable
var dice := Dice.new(0)


func setup(p: CampaignProgress, changed: Callable) -> void:
	campaign = p
	callback = changed
	var label := Label.new()
	label.text = "Out-of-game spells (after battle / preparation)"
	add_child(label)
	shield_roll=Button.new()
	shield_roll.custom_minimum_size.y=44
	shield_roll.text="Roll Scroll Shield spell before battle"
	add_child(shield_roll)
	shield_roll.pressed.connect(func() -> void:
		if ScrollShield.roll(campaign.data,dice):
			callback.call())
	choices = OptionButton.new()
	add_child(choices)
	enchant_supply=CheckButton.new()
	enchant_supply.custom_minimum_size.y=44
	enchant_supply.hide()
	add_child(enchant_supply)
	shears=OptionButton.new()
	shears.custom_minimum_size.y=44
	shears.hide()
	add_child(shears)
	bottle=CheckButton.new()
	bottle.text="Fill Golden Bottle (two doses)"
	bottle.custom_minimum_size.y=44
	bottle.hide()
	add_child(bottle)
	bottle.toggled.connect(func(on: bool) -> void:
		if on:
			enchant_supply.set_pressed_no_signal(false))
	enchant_supply.toggled.connect(func(on: bool) -> void:
		if on:
			bottle.set_pressed_no_signal(false))
	choices.item_selected.connect(func(_index: int) -> void: _refresh_supply())
	cast_button = Button.new()
	cast_button.text = "Attempt selected ritual"
	add_child(cast_button)
	cast_button.pressed.connect(func() -> void:
		if choices.item_count == 0:
			return
		var option: Dictionary = choices.get_selected_metadata()
		if Rituals.attempt(campaign.data, option["caster"], option["id"], option["option"], dice,enchant_supply.visible and enchant_supply.button_pressed,int(shears.get_selected_metadata()) if shears.visible else -1,bottle.visible and bottle.button_pressed,bool(option.get("shield",false))):
			callback.call())


func refresh() -> void:
	choices.clear()
	enchant_supply.hide()
	var d := campaign.data
	shield_roll.visible=not d.is_empty() and ScrollShield.campaign_index(d,"roll")>=0
	if d.is_empty():
		return
	for i in d["units"].size():
		var u: Dictionary = d["units"][i]
		if u["type"] not in ["wizard", "apprentice"]:
			continue
		for id: String in Rituals.AFTER + Rituals.BEFORE:
			for option: String in Rituals.choices(d, i, id):
				var text := "%s · %s: %s" % ["Before" if Rituals.BEFORE.has(id) else "After", str(u["type"]).capitalize(), id.replace("_", " ").capitalize()]
				if id == "embed_enchantment":
					text += " — " + EnchantmentRewards.label(d, int(option))
				elif option != "":
					text += " — " + option.replace("_", " ").capitalize()
				choices.add_item(text)
				choices.set_item_metadata(choices.item_count - 1, {"caster": i, "id": id, "option": option})
		if u["type"]=="wizard":
			for id: String in Rituals.AFTER+Rituals.BEFORE:
				for option in Rituals.choices(d,i,id,true):
					choices.add_item("Scroll Shield · "+id.replace("_"," ").capitalize()+(" — "+option if not option.is_empty() else ""))
					choices.set_item_metadata(choices.item_count-1,{"caster":i,"id":id,"option":option,"shield":true})
	cast_button.disabled = choices.item_count == 0

	_refresh_supply()


func _refresh_supply() -> void:
	bottle.hide()
	bottle.set_pressed_no_signal(false)
	shears.hide()
	shears.clear()
	enchant_supply.hide()
	enchant_supply.set_pressed_no_signal(false)
	if choices.item_count==0:
		return
	var option: Dictionary=choices.get_selected_metadata()
	if option.get("shield",false):
		return
	var db := FigureDb.load_files(FigureDb.FIGURES,FigureDb.WEAPONS,ContentProfile.from_campaign(campaign.data))
	var targets := RedKingCampaignGear.shears_choices(campaign.data,int(option["caster"]),str(option["id"]),db)
	if not targets.is_empty():
		shears.add_item("Mystic Shears: do not use")
		shears.set_item_metadata(0,-1)
		for target in targets:
			var unit: Dictionary=campaign.data["units"][target]
			shears.add_item("Shears +2: %s #%d"%[str(unit["type"]).capitalize(),target+1])
			shears.set_item_metadata(shears.item_count-1,target)
		shears.show()
	if option["id"]=="brew_potion" and RedKingCampaignGear.empty_bottle(campaign.data,int(option["caster"]),str(option["option"]))>=0:
		bottle.show()
	var id := RedKingMaterials.for_ritual(str(option["id"]))
	var amount := RedKingMaterials.available(campaign.data,id)
	if amount>0:
		enchant_supply.text="Use %s (%d left)" % ["scroll wax" if id==RedKingMaterials.WAX else "enchanted vial",amount]
		enchant_supply.show()
