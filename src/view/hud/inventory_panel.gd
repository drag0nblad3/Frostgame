class_name InventoryPanel
extends VBoxContainer

var campaign: CampaignProgress
var db: FigureDb
var loot: OptionButton
var owner: OptionButton
var shop: OptionButton
var summary: Label
var changed: Callable


func setup(p: CampaignProgress, figures: FigureDb, callback: Callable) -> void:
	campaign = p
	db = figures
	changed = callback
	summary = Label.new()
	summary.text = "Potion vault and loadouts"
	add_child(summary)
	loot = OptionButton.new()
	add_child(loot)
	owner = OptionButton.new()
	add_child(owner)
	_button("Assign selected potion", func() -> void:
		if loot.item_count > 0 and CampaignInventory.assign_item(campaign.data, int(loot.get_selected_metadata()), int(owner.get_selected_metadata()), db):
			changed.call())
	_button("Sell selected unassigned potion", func() -> void:
		if loot.item_count > 0 and CampaignInventory.sell(campaign.data, int(loot.get_selected_metadata())):
			changed.call())
	shop = OptionButton.new()
	add_child(shop)
	_button("Buy potion", func() -> void:
		if shop.item_count > 0 and CampaignInventory.buy(campaign.data, str(shop.get_selected_metadata())):
			changed.call())


func refresh() -> void:
	var d := campaign.data
	loot.clear()
	owner.clear()
	shop.clear()
	if d.is_empty():
		return
	var catalog := CampaignInventory.catalog()
	for i in d["loot"].size():
		var item: Dictionary = d["loot"][i]
		if item["kind"] != "potion":
			continue
		var info: Dictionary = catalog[item["potion"]]
		var assigned := int(item.get("owner", -1))
		var suffix := "Vault" if assigned < 0 else "%s #%d" % [d["units"][assigned]["type"], assigned + 1]
		loot.add_item("%s · %s%s" % [info["name"], suffix, "" if info["live"] else " · effect pending"])
		loot.set_item_metadata(loot.item_count - 1, i)
	owner.add_item("Vault")
	owner.set_item_metadata(0, -1)
	for unit: Dictionary in d["units"]:
		var capacity := CampaignInventory.slots(unit, db)
		if unit["dead"] or unit.get("dismissed", false) or capacity == 0:
			continue
		var used := CampaignInventory.loadout(d, int(unit["id"])).size() + (1 if unit["type"] in ["wizard", "apprentice"] else 0)
		owner.add_item("%s #%d · %d/%d slots" % [str(unit["type"]).capitalize(), int(unit["id"]) + 1, used, capacity])
		owner.set_item_metadata(owner.item_count - 1, int(unit["id"]))
	for id: String in catalog:
		var info: Dictionary = catalog[id]
		if not info["live"] or int(info["buy"]) <= 0:
			continue
		shop.add_item("%s · %d gc" % [info["name"], info["buy"]])
		shop.set_item_metadata(shop.item_count - 1, id)
		shop.set_item_disabled(shop.item_count - 1, int(d["gold"]) < int(info["buy"]))


func _button(label: String, action: Callable) -> void:
	var b := Button.new()
	b.text = label
	b.pressed.connect(action)
	add_child(b)
