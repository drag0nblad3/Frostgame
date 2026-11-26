class_name InventoryPanel
extends VBoxContainer

var campaign: CampaignProgress
var db: FigureDb
var loot: OptionButton
var recipient_choice: OptionButton
var shop: OptionButton
var summary: Label
var changed: Callable
var campaign_dice := Dice.new(0)
var campaign_uses: OptionButton
var use_button: Button
var assign_button: Button
var sell_button: Button


func setup(p: CampaignProgress, figures: FigureDb, callback: Callable) -> void:
	campaign = p
	db = figures
	changed = callback
	summary = Label.new()
	summary.text = "Equipment and potion vault"
	add_child(summary)
	loot = OptionButton.new()
	add_child(loot)
	recipient_choice = OptionButton.new()
	add_child(recipient_choice)
	assign_button = _button("Assign selected item", func() -> void:
		if loot.item_count > 0 and CampaignInventory.assign_item(campaign.data, int(loot.get_selected_metadata()), int(recipient_choice.get_selected_metadata()), db):
			changed.call())
	sell_button = _button("Sell selected unassigned item / known grimoire", func() -> void:
		if loot.item_count > 0 and CampaignInventory.sell(campaign.data, int(loot.get_selected_metadata())):
			changed.call())
	campaign_uses = OptionButton.new()
	add_child(campaign_uses)
	use_button = Button.new()
	use_button.text = "Use campaign potion"
	use_button.pressed.connect(func() -> void:
		if campaign_uses.item_count == 0:
			return
		var option: Dictionary = campaign_uses.get_selected_metadata()
		if CampaignPotions.use(campaign.data, option["item"], option["unit"], db, campaign_dice):
			changed.call())
	add_child(use_button)
	loot.item_selected.connect(func(_index: int) -> void: _refresh_item_buttons())
	shop = OptionButton.new()
	add_child(shop)
	_button("Buy item", func() -> void:
		if shop.item_count > 0 and CampaignInventory.buy(campaign.data, str(shop.get_selected_metadata()), campaign_dice):
			changed.call())


func refresh() -> void:
	var d := campaign.data
	loot.clear()
	recipient_choice.clear()
	shop.clear()
	campaign_uses.clear()
	use_button.disabled = true
	if d.is_empty():
		return
	var catalog := CampaignInventory.catalog()
	for i in d["loot"].size():
		var item: Dictionary = d["loot"][i]
		if not CampaignInventory.is_item(item) and item["kind"] != "grimoire":
			continue
		var info: Dictionary = catalog[CampaignInventory.item_id(item)]
		var assigned := int(item.get("owner", -1))
		var suffix := "Vault" if assigned < 0 else "%s #%d" % [d["units"][assigned]["type"], assigned + 1]
		if item["kind"] == "grimoire":
			suffix = "Known spell; may sell" if d["spells"].has(item["spell"]) else "Unlearned; may learn in campaign"
		if CampaignInventory.item_id(item) == "gear_staff_casting":
			suffix += " · " + str(item.get("casting_spell", "unknown")).replace("_", " ").capitalize()
		if CampaignInventory.item_id(item) == PowerPool.ORB:
			suffix += " · %d power" % PowerPool.remaining(item)
		loot.add_item("%s · %s%s" % [info["name"], suffix, "" if info["live"] else " · effect pending"])
		loot.set_item_metadata(loot.item_count - 1, i)
		for unit_id in CampaignPotions.choices(d, i, db):
			var unit: Dictionary = d["units"][unit_id]
			campaign_uses.add_item("%s → %s #%d" % [info["name"], str(unit["type"]).capitalize(), unit_id + 1])
			campaign_uses.set_item_metadata(campaign_uses.item_count - 1, {"item": i, "unit": unit_id})
	use_button.disabled = campaign_uses.item_count == 0
	recipient_choice.add_item("Vault")
	recipient_choice.set_item_metadata(0, -1)
	for unit: Dictionary in d["units"]:
		var capacity := CampaignInventory.slots(unit, db)
		if unit["dead"] or unit.get("dismissed", false) or (capacity == 0 and unit["type"] not in ["medium_construct", "large_construct"]):
			continue
		var items := CampaignInventory.loadout(d, int(unit["id"]))
		var used := items.size()
		if unit["type"] in ["wizard", "apprentice"]:
			var staff := false
			for item: Dictionary in items:
				if item.get("gear_info", {}).get("type", "") == "staff":
					staff = true
			if not staff:
				used += 1
		if capacity == 0:
			recipient_choice.add_item("%s #%d · Hammer graft only" % [str(unit["type"]).capitalize(), int(unit["id"]) + 1])
		else:
			recipient_choice.add_item("%s #%d · %d/%d slots" % [str(unit["type"]).capitalize(), int(unit["id"]) + 1, used, capacity])
		recipient_choice.set_item_metadata(recipient_choice.item_count - 1, int(unit["id"]))
	for id: String in catalog:
		var info: Dictionary = catalog[id]
		if not info["live"] or int(info["buy"]) <= 0:
			continue
		shop.add_item("%s · %d gc" % [info["name"], info["buy"]])
		shop.set_item_metadata(shop.item_count - 1, id)
		shop.set_item_disabled(shop.item_count - 1, int(d["gold"]) < int(info["buy"]))


	_refresh_item_buttons()


func _refresh_item_buttons() -> void:
	assign_button.disabled = loot.item_count == 0
	sell_button.disabled = loot.item_count == 0
	if loot.item_count == 0:
		return
	var item: Dictionary = campaign.data["loot"][int(loot.get_selected_metadata())]
	assign_button.disabled = not CampaignInventory.is_item(item)
	sell_button.disabled = not CampaignInventory.can_sell(campaign.data, item)


func _button(label: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = label
	b.pressed.connect(action)
	add_child(b)

	return b
