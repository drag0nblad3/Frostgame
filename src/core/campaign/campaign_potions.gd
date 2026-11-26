class_name CampaignPotions
extends RefCounted

const VAULT_ONLY := ["construct_oil", "preservation", "dreams", "life"]
const AFTER := ["construct_oil", "preservation", "life", "restoration"]


static func preserved(d: Dictionary, u: Dictionary) -> bool:
	return u["dead"] and int(u.get("preserved_until", -1)) >= int(d["games"])


static func recently_dead(d: Dictionary, u: Dictionary) -> bool:
	return u["dead"] and (int(u.get("death_game", -1)) == int(d["games"]) or preserved(d, u))


static func choices(d: Dictionary, index: int, db: FigureDb) -> Array[int]:
	var out: Array[int] = []
	if index < 0 or index >= d["loot"].size():
		return out
	var item: Dictionary = d["loot"][index]
	var id := str(item.get("potion", ""))
	if int(item.get("owner", -1)) >= 0 or (id not in AFTER and id != "dreams"):
		return out
	if id in AFTER and (int(d["games"]) == 0 or d.get("preparation_started", false)):
		return out
	for u: Dictionary in d["units"]:
		if u.get("dismissed", false):
			continue
		var eligible := false
		match id:
			"construct_oil":
				eligible = not u["dead"] and not u.get("construct_oiled", false) and db.get_def(u["type"]).traits.has("construct")
			"preservation":
				eligible = u["type"] != "wizard" and u["dead"] and int(u.get("death_game", -1)) == int(d["games"]) and not preserved(d, u)
			"life":
				eligible = recently_dead(d, u)
				if eligible and u["type"] == "apprentice":
					for other: Dictionary in d["units"]:
						if other != u and other["type"] == "apprentice" and not other["dead"] and not other.get("dismissed", false):
							eligible = false
				if eligible and u["type"] not in ["wizard", "apprentice"]:
					var soldiers := 0
					var specialists := 0
					for other: Dictionary in d["units"]:
						if other["dead"] or other.get("dismissed", false):
							continue
						var def := db.get_def(other["type"])
						if def.role == "soldier" or other.get("permanent_summon", false):
							soldiers += 1
							if def.specialist or other["type"] == "large_construct":
								specialists += 1
					eligible = soldiers < 8 and (not db.get_def(u["type"]).specialist and u["type"] != "large_construct" or specialists < 4)
			"restoration":
				eligible = not u["dead"] and int(u["injuries"]) > 0
			"dreams":
				eligible = u["type"] == "wizard" and not u["dead"] and not d.has("dreams_xp")
		if eligible:
			out.append(int(u["id"]))
	return out


static func use(d: Dictionary, index: int, unit_id: int, db: FigureDb, dice: Dice) -> bool:
	if not choices(d, index, db).has(unit_id):
		return false
	var id: String = d["loot"][index]["potion"]
	var u: Dictionary = d["units"][unit_id]
	d["loot"].remove_at(index)
	match id:
		"construct_oil":
			u["construct_oiled"] = true
		"preservation":
			u["preserved_until"] = int(d["games"]) + 5
		"life":
			revive(u)
		"restoration":
			u["injuries"] = 0
			u["injury_types"] = {}
		"dreams":
			d["preparation_started"] = true
			var will := db.get_def("wizard").will + int(d.get("advances", {}).get("will", 0)) - int(u.get("injury_types", {}).get("psychological_scars", 0))
			d["dreams_xp"] = 50 if StatRoll.succeeds(dice.d20(), will, 12) else -30
	d["last_report"].append("%s used on %s #%d." % [CampaignInventory.catalog()[id]["name"], str(u["type"]).capitalize(), unit_id + 1])
	return true


static func revive(u: Dictionary) -> void:
	u["dead"] = false
	u["miss"] = 0
	u.erase("preserved_until")
	u.erase("death_game")
