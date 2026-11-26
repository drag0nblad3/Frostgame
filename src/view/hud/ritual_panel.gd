class_name RitualPanel
extends VBoxContainer

var campaign: CampaignProgress
var choices: OptionButton
var cast_button: Button
var callback: Callable
var dice := Dice.new(0)


func setup(p: CampaignProgress, changed: Callable) -> void:
	campaign = p
	callback = changed
	var label := Label.new()
	label.text = "Out-of-game spells (after battle / preparation)"
	add_child(label)
	choices = OptionButton.new()
	add_child(choices)
	cast_button = Button.new()
	cast_button.text = "Attempt selected ritual"
	add_child(cast_button)
	cast_button.pressed.connect(func() -> void:
		if choices.item_count == 0:
			return
		var option: Dictionary = choices.get_selected_metadata()
		if Rituals.attempt(campaign.data, option["caster"], option["id"], option["option"], dice):
			callback.call())


func refresh() -> void:
	choices.clear()
	var d := campaign.data
	if d.is_empty():
		return
	for i in d["units"].size():
		var u: Dictionary = d["units"][i]
		if u["type"] not in ["wizard", "apprentice"]:
			continue
		for id: String in Rituals.AFTER + Rituals.BEFORE:
			for option: String in Rituals.choices(d, i, id):
				var text := "%s · %s: %s" % ["Before" if Rituals.BEFORE.has(id) else "After", str(u["type"]).capitalize(), id.replace("_", " ").capitalize()]
				if option != "":
					text += " — " + option.replace("_", " ").capitalize()
				choices.add_item(text)
				choices.set_item_metadata(choices.item_count - 1, {"caster": i, "id": id, "option": option})
	cast_button.disabled = choices.item_count == 0
