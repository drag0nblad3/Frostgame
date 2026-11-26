class_name BaseUpgradePanel
extends VBoxContainer
## Purchase base upgrades and select the Inn's reserve.


var campaign: CampaignProgress
var db: FigureDb
var callback: Callable
var resources: OptionButton
var buy_button: Button
var reserve: OptionButton
var reserve_label: Label
var owned: Label


func setup(p: CampaignProgress, figures: FigureDb, changed: Callable) -> void:
	campaign = p
	db = figures
	callback = changed
	owned = Label.new()
	owned.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(owned)
	resources = OptionButton.new()
	add_child(resources)
	buy_button = Button.new()
	buy_button.text = "Purchase base resource"
	add_child(buy_button)
	buy_button.pressed.connect(func() -> void:
		if resources.item_count > 0 and BaseResources.buy(campaign.data, str(resources.get_selected_metadata())):
			callback.call())
	reserve_label = Label.new()
	reserve_label.text = "Inn: soldier staying at base"
	add_child(reserve_label)
	reserve = OptionButton.new()
	add_child(reserve)
	reserve.item_selected.connect(func(index: int) -> void:
		if BaseResources.choose_reserve(campaign.data, int(reserve.get_item_metadata(index)), db):
			callback.call())


func refresh() -> void:
	var d := campaign.data
	var catalog := BaseResources.catalog()
	var names: Array[String] = []
	resources.clear()
	var first_available := -1
	for id: String in catalog:
		var info: Dictionary = catalog[id]
		if BaseResources.owns(d, id):
			names.append(info["name"])
			continue
		resources.add_item("%s · %d gc · %s%s" % [info["name"], info["cost"], info["benefit"], "" if info["live"] else " (pending)"])
		var i := resources.item_count - 1
		resources.set_item_metadata(i, id)
		var available: bool = info["live"] and str(d.get("base", "")) != "" and int(d["gold"]) >= int(info["cost"])
		resources.set_item_disabled(i, not available)
		if available and first_available < 0:
			first_available = i
	owned.text = "Base resources: " + (", ".join(names) if not names.is_empty() else "None")
	buy_button.disabled = first_available < 0
	resources.select(first_available)
	reserve.clear()
	var selected := BaseResources.reserve_id(d, db)
	for id in BaseResources.reserve_candidates(d, db):
		var unit: Dictionary = d["units"][id]
		reserve.add_item("%s #%d" % [db.get_def(unit["type"]).name, id + 1])
		reserve.set_item_metadata(reserve.item_count - 1, id)
		if id == selected:
			reserve.select(reserve.item_count - 1)
	reserve.visible = reserve.item_count > 0
	reserve_label.visible = reserve.visible
