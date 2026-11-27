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
var discard_button: Button
var caster_equipment: OptionButton
var caster_equipment_button: Button
var mantle_animal: OptionButton
var bind_mantle: Button
var book_spell: OptionButton
var bind_book: Button
var split_fang: Button
var mask_start: Button
var ivory_staff: OptionButton
var ivory_graft: Button
var staff_potion: OptionButton
var charge_staff: Button


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
	discard_button = _button("Discard selected item",func() -> void:
		if loot.item_count>0 and RaggedWarbands.discard(campaign.data,int(loot.get_selected_metadata())):
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
	mantle_animal=OptionButton.new()
	for animal: String in CompanionMantle.ANIMALS:
		mantle_animal.add_item(animal.replace("_"," ").capitalize())
		mantle_animal.set_item_metadata(mantle_animal.item_count-1,animal)
	add_child(mantle_animal)
	bind_mantle=_button("Permanently choose mantle animal",func() -> void:
		if loot.item_count>0 and CompanionMantle.bind(campaign.data,int(loot.get_selected_metadata()),str(mantle_animal.get_selected_metadata())):
			changed.call())
	mantle_animal.hide()
	bind_mantle.hide()
	book_spell=OptionButton.new()
	add_child(book_spell)
	bind_book=_button("Permanently bind selected item to spell",func() -> void:
		if loot.item_count>0 and book_spell.item_count>0 and CampaignInventory.bind_incunabula(campaign.data,int(loot.get_selected_metadata()),str(book_spell.get_selected_metadata())):
			changed.call())
	split_fang=_button("Split off one golden fang",func() -> void:
		if loot.item_count>0 and RedKingMaterials.split_fang(campaign.data,int(loot.get_selected_metadata())):
			changed.call())
	split_fang.hide()
	mask_start=_button("Toggle starting mask state",func() -> void:
		if loot.item_count>0 and CampaignInventory.toggle_mask_start(campaign.data,int(loot.get_selected_metadata())):
			changed.call())
	mask_start.hide()
	ivory_staff=OptionButton.new()
	ivory_staff.hide()
	add_child(ivory_staff)
	ivory_graft=_button("Graft Ivory Hand onto staff (500 gc)",func() -> void:
		if loot.item_count>0 and ivory_staff.item_count>0 and CampaignInventory.graft_ivory(campaign.data,int(loot.get_selected_metadata()),int(ivory_staff.get_selected_metadata())):
			changed.call())
	ivory_graft.hide()
	staff_potion=OptionButton.new()
	staff_potion.hide()
	add_child(staff_potion)
	charge_staff=_button("Sacrifice potion to staff",func() -> void:
		if loot.item_count>0 and staff_potion.item_count>0 and RedKingCampaignGear.charge_staff(campaign.data,int(loot.get_selected_metadata()),int(staff_potion.get_selected_metadata())):
			changed.call())
	charge_staff.hide()
	loot.item_selected.connect(func(_index: int) -> void: _refresh_item_buttons())
	caster_equipment = OptionButton.new()
	add_child(caster_equipment)
	caster_equipment_button = _button("Set spellcaster weapons", func() -> void:
		if caster_equipment.item_count == 0:
			return
		var option: Dictionary = caster_equipment.get_selected_metadata()
		if CasterLoadout.set_weapons(campaign.data, option["owner"], CasterLoadout.PRESETS[option["preset"]]):
			changed.call())
	shop = OptionButton.new()
	add_child(shop)
	_button("Buy item", func() -> void:
		if shop.item_count > 0 and CampaignInventory.buy(campaign.data, str(shop.get_selected_metadata()), campaign_dice):
			changed.call())


func refresh() -> void:
	var d := campaign.data
	loot.clear()
	mantle_animal.hide()
	bind_mantle.hide()
	book_spell.clear()
	book_spell.hide()
	bind_book.hide()
	recipient_choice.clear()
	shop.clear()
	caster_equipment.clear()
	caster_equipment_button.disabled = true
	campaign_uses.clear()
	use_button.disabled = true
	if d.is_empty():
		return
	var ragged := RaggedWarbands.active(d)
	discard_button.visible=ragged
	summary.text="Carried items · Assign or discard new loot before battle" if ragged else "Equipment and potion vault"
	var catalog := CampaignInventory.catalog()
	for i in d["loot"].size():
		var item: Dictionary = d["loot"][i]
		if not CampaignInventory.is_item(item) and item["kind"] != "grimoire":
			continue
		if not catalog.has(CampaignInventory.item_id(item)):
			continue
		var info: Dictionary = catalog[CampaignInventory.item_id(item)]
		var assigned := int(item.get("owner", -1))
		var suffix := "Vault" if assigned < 0 else "%s #%d" % [d["units"][assigned]["type"], assigned + 1]
		if ragged and item.get("ragged_sealed",false):
			suffix="Inaccessible vault"
		elif ragged and RaggedWarbands.absent_owner(d,item):
			suffix+=" (separated)"
		elif ragged and assigned<0 and CampaignInventory.is_item(item):
			suffix="Assign or discard"
		if info.get("artefact",false):
			suffix+=" · "+("Unlocked" if item.get("unlocked",false) else "Locked TN%d"%info["unlock_tn"])
		if item["kind"] == "grimoire":
			suffix = "Known spell; may sell" if d["spells"].has(item["spell"]) else "Unlearned; may learn in campaign"
		if CampaignInventory.item_id(item)==CompanionMantle.ITEM:
			suffix+=" · "+str(item.get("mantle_animal","Choose animal")).replace("_"," ").capitalize()
		if CampaignInventory.item_id(item) in ["gear_rk_golden_incunabula",CircletDefence.ITEM]:
			suffix+=" · "+str(item.get("casting_spell","Choose spell")).replace("_"," ").capitalize()
		if CampaignInventory.item_id(item) == "gear_staff_casting":
			suffix += " · " + str(item.get("casting_spell", "unknown")).replace("_", " ").capitalize()
		if CampaignInventory.item_id(item) == PowerPool.ORB:
			suffix += " · %d power" % PowerPool.remaining(item)
		if RedKingMaterials.is_supply(CampaignInventory.item_id(item)):
			suffix+=" · %d uses" % RedKingMaterials.amount(item)
		if item.get("gear","")==DeathMask.ITEM:
			suffix+=" · Starts "+("worn" if item.get("mask_start_worn",false) else "unworn")
		if item.get("enchanted",false):
			suffix+=" · Enchanted"
		if item.get("ivory_graft",false):
			suffix+=" · Ivory Hand graft"
		if item.has("stored_potion"):
			suffix+=" · "+str(item["stored_potion"]).capitalize()
		if int(item.get("bottle_doses",0))>0:
			suffix+=" · %s (%d doses)"%[str(item["bottle_potion"]).capitalize(),int(item["bottle_doses"])]
		loot.add_item("%s · %s%s" % [info["name"], suffix, "" if info["live"] else " · effect pending"])
		loot.set_item_metadata(loot.item_count - 1, i)
		for unit_id in CampaignPotions.choices(d, i, db):
			var unit: Dictionary = d["units"][unit_id]
			campaign_uses.add_item("%s → %s #%d" % [info["name"], str(unit["type"]).capitalize(), unit_id + 1])
			campaign_uses.set_item_metadata(campaign_uses.item_count - 1, {"item": i, "unit": unit_id})
	use_button.disabled = campaign_uses.item_count == 0
	if not ragged:
		recipient_choice.add_item("Vault")
		recipient_choice.set_item_metadata(0, -1)
	for unit: Dictionary in d["units"]:
		var capacity := CampaignInventory.slots(unit, db)
		if unit["dead"] or unit.get("dismissed", false) or unit.get("ragged_absent",false) or (capacity == 0 and unit["type"] not in ["medium_construct", "large_construct"] and not (db.content_profile.enabled.has("red_king") and (db.get_def(unit["type"]).traits.has("animal") or db.get_def(unit["type"]).traits.has("construct")))):
			continue
		var items := CampaignInventory.loadout(d, int(unit["id"]))
		var used := items.size()
		if CasterLoadout.is_caster(unit["type"]):
			used = int(CasterLoadout.carried(d, unit)["slots"])
			for preset: String in CasterLoadout.PRESETS:
				var proposed := unit.duplicate()
				proposed["weapons"] = CasterLoadout.PRESETS[preset]
				if not CasterLoadout.fits(d, proposed):
					continue
				caster_equipment.add_item("%s #%d · %s" % [str(unit["type"]).capitalize(), int(unit["id"]) + 1, preset])
				caster_equipment.set_item_metadata(caster_equipment.item_count - 1, {"owner": int(unit["id"]), "preset": preset})
		if capacity == 0:
			var special := "Special equipment only" if db.content_profile.enabled.has("red_king") else "Hammer graft only"
			recipient_choice.add_item("%s #%d · %s" % [str(unit["type"]).capitalize(), int(unit["id"]) + 1,special])
		else:
			recipient_choice.add_item("%s #%d · %d/%d slots" % [str(unit["type"]).capitalize(), int(unit["id"]) + 1, used, capacity])
		recipient_choice.set_item_metadata(recipient_choice.item_count - 1, int(unit["id"]))
	for id: String in catalog:
		var info: Dictionary = catalog[id]
		if RedKingCampaign.economy_locked(d) or not info["live"] or int(info["buy"]) <= 0 or not ContentProfile.from_campaign(d).item_allowed(id):
			continue
		shop.add_item("%s · %d gc%s" % [info["name"],info["buy"]," per use" if info.get("material",false) else ""])
		shop.set_item_metadata(shop.item_count - 1, id)
		shop.set_item_disabled(shop.item_count - 1, int(d["gold"]) < int(info["buy"]))


	caster_equipment_button.disabled = caster_equipment.item_count == 0
	_refresh_item_buttons()


func _refresh_item_buttons() -> void:
	mantle_animal.hide()
	bind_mantle.hide()
	mask_start.hide()
	staff_potion.clear()
	staff_potion.hide()
	charge_staff.hide()
	ivory_staff.clear()
	ivory_staff.hide()
	ivory_graft.hide()
	split_fang.hide()
	book_spell.hide()
	bind_book.hide()
	book_spell.clear()
	assign_button.disabled = loot.item_count == 0 or recipient_choice.item_count==0
	sell_button.disabled = loot.item_count == 0
	discard_button.disabled=true
	if loot.item_count == 0:
		return
	var index := int(loot.get_selected_metadata())
	var item: Dictionary = campaign.data["loot"][index]
	if item.get("gear","")==CompanionMantle.ITEM and str(item.get("mantle_animal","")).is_empty() and not item.get("ragged_sealed",false):
		mantle_animal.show()
		bind_mantle.show()
	if item.get("gear","")==DeathMask.ITEM and item.get("unlocked",false) and not item.get("ragged_sealed",false):
		mask_start.text="Start with mask %s (toggle)" % ("on" if item.get("mask_start_worn",false) else "off")
		mask_start.show()
	for potion_index in RedKingCampaignGear.staff_potions(campaign.data,index):
		var potion: Dictionary=campaign.data["loot"][potion_index]
		staff_potion.add_item(str(CampaignInventory.catalog()[potion["potion"]]["name"]))
		staff_potion.set_item_metadata(staff_potion.item_count-1,potion_index)
	if staff_potion.item_count>0:
		staff_potion.show()
		charge_staff.show()
	for staff_index in CampaignInventory.ivory_staff_choices(campaign.data,index):
		var staff: Dictionary=campaign.data["loot"][staff_index]
		ivory_staff.add_item(str(CampaignInventory.catalog()[staff["gear"]]["name"]))
		ivory_staff.set_item_metadata(ivory_staff.item_count-1,staff_index)
	if ivory_staff.item_count>0:
		ivory_staff.show()
		ivory_graft.show()
	if item.get("gear","")==RedKingMaterials.FANGS and RedKingMaterials.amount(item)>1 and not RaggedWarbands.active(campaign.data) and not item.get("ragged_sealed",false):
		split_fang.show()
	if item.get("gear","") in ["gear_rk_golden_incunabula",CircletDefence.ITEM] and str(item.get("casting_spell","")).is_empty() and not item.get("ragged_sealed",false):
		var spells: Dictionary = JsonFile.read("res://data/spells.json")
		for id: String in spells:
			if db.content_profile.allows("spells",id) and (item.get("gear","")!=CircletDefence.ITEM or CircletDefence.SPELLS.has(id)):
				book_spell.add_item(str(spells[id]["name"]))
				book_spell.set_item_metadata(book_spell.item_count-1,id)
		book_spell.show()
		bind_book.show()
	assign_button.disabled = recipient_choice.item_count==0 or not CampaignInventory.is_item(item) or (RaggedWarbands.active(campaign.data) and (item.get("ragged_sealed",false) or RaggedWarbands.absent_owner(campaign.data,item)))
	discard_button.disabled=not RaggedWarbands.active(campaign.data) or not CampaignInventory.is_item(item) or item.get("ragged_sealed",false) or RaggedWarbands.absent_owner(campaign.data,item)
	sell_button.disabled = not CampaignInventory.can_sell(campaign.data, item)


func _button(label: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = label
	b.pressed.connect(action)
	add_child(b)

	return b
