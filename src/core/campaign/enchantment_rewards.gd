class_name EnchantmentRewards
extends RefCounted


static func capture(d: Dictionary, c: GameController, side: int) -> void:
	var options: Array = []
	for t in c.state.figures:
		if t.original_side != side or t.campaign_id < 0 or t.out_of_action or d["units"][t.campaign_id]["dead"]:
			continue
		if t.spell_effects.has("enchant_weapon"):
			var w := t.ranged if t.ranged != null else t.melee
			var id := "gear_" + w.id + ("_shoot" if w.is_ranged() else "_fight")
			if CampaignInventory.catalog().has(id):
				options.append({"gear": id, "unit": t.campaign_id})
		if t.spell_effects.has("enchant_armour"):
			var heavy := t.def.id in ["knight", "templar", "marksman"]
			options.append({"gear": "gear_embedded_heavy_armour" if heavy else "gear_light_armour", "unit": t.campaign_id})
	d["enchantments"] = options


static func choices(d: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for i in d.get("enchantments", []).size():
		var option: Dictionary = d["enchantments"][i]
		var unit: Dictionary = d["units"][option["unit"]]
		if not unit["dead"] and not unit.get("dismissed", false):
			out.append(str(i))
	return out


static func label(d: Dictionary, index: int) -> String:
	var option: Dictionary = d["enchantments"][index]
	return "%s from %s #%d" % [CampaignInventory.catalog()[option["gear"]]["name"], str(d["units"][option["unit"]]["type"]).capitalize(), int(option["unit"]) + 1]


static func embed(d: Dictionary, index: int) -> void:
	var option: Dictionary = d["enchantments"][index]
	d["enchantments"].remove_at(index)
	# Enter the vault; normal item assignment applies, including compatibility and capacity.
	d["loot"].append({"kind": "gear", "gear": option["gear"], "owner": -1})
