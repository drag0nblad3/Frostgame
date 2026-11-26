class_name BaseResources
extends RefCounted
## Persistent upgrades attached to the current base (pp. 106–107).


static func catalog() -> Dictionary:
	return JsonFile.read("res://data/base_resources.json")


static func owns(d: Dictionary, id: String) -> bool:
	return not RedKingCampaign.economy_locked(d) and d.get("resources", []).has(id)


static func buy(d: Dictionary, id: String) -> bool:
	if RedKingCampaign.economy_locked(d) or d.is_empty() or str(d.get("base", "")) == "" or owns(d, id) or not ContentProfile.from_campaign(d).allows("base_resources",id):
		return false
	var info: Dictionary = catalog().get(id, {})
	if not info.get("live", false) or int(d["gold"]) < int(info.get("cost", 0)):
		return false
	var resources: Array = d.get("resources", [])
	resources.append(id)
	d["resources"] = resources
	d["gold"] = int(d["gold"]) - int(info["cost"])
	return true


static func casting_bonus(d: Dictionary, spell: String) -> int:
	var upgrade := ""
	match spell:
		"brew_potion":
			upgrade = "giant_cauldron"
		"animate_construct", "embed_enchantment":
			upgrade = "enchanters_workshop"
		"reveal_secret":
			upgrade = "crystal_ball"
		"write_scroll":
			upgrade = "scriptorium"
		"summon_demon":
			upgrade = "summoning_candle"
		"control_demon":
			upgrade = "arcane_candle"
	return 1 if upgrade != "" and owns(d, upgrade) else 0


static func alive(unit: Dictionary) -> bool:
	return not unit.get("dead", false) and not unit.get("dismissed", false) and not unit.get("ragged_absent",false)


static func soldier(unit: Dictionary, db: FigureDb) -> bool:
	return db.get_def(unit["type"]).role == "soldier" or unit.get("permanent_summon", false)


static func specialist(unit: Dictionary, db: FigureDb) -> bool:
	return db.get_def(unit["type"]).specialist or unit["type"] in ["large_construct","foulhorn","bear","snow_leopard"]


static func wizard_item(d: Dictionary,id: String) -> bool:
	for item: Dictionary in d.get("loot",[]):
		var owner := int(item.get("owner",-1))
		if item.get("gear","")==id and item.get("unlocked",true) and owner>=0 and owner<d.get("units",[]).size():
			var u: Dictionary=d["units"][owner]
			if u["type"]=="wizard" and alive(u):
				return true
	return false


static func specialist_limit(d: Dictionary) -> int:
	return 4+int(wizard_item(d,"gear_rk_amulet_of_charisma"))


static func wisdom_eligible(unit: Dictionary,db: FigureDb) -> bool:
	return unit["type"] in ["monk","mystic_warrior"] and specialist(unit,db)


static func counts(d: Dictionary, db: FigureDb, extra_type: String = "") -> Vector2i:
	var count := Vector2i.ZERO
	var kennel := false
	var wisdom := false
	for unit: Dictionary in d.get("units", []):
		if not alive(unit) or not soldier(unit, db):
			continue
		count.x += 1
		if specialist(unit, db):
			count.y += 1
			wisdom=wisdom or wisdom_eligible(unit,db)
		if unit["type"] in ["war_hound", "wolf"]:
			kennel = true
	if extra_type != "":
		count.x += 1
		if specialist({"type":extra_type},db):
			count.y += 1
			wisdom=wisdom or wisdom_eligible({"type":extra_type},db)
		if extra_type in ["war_hound", "wolf"]:
			kennel = true
	if kennel and owns(d, "kennel"):
		count.x -= 1
	if wisdom and wizard_item(d,"gear_rk_book_of_wisdom"):
		count.y-=1
	return count


static func fits(d: Dictionary, db: FigureDb, extra_type: String = "") -> bool:
	if RaggedWarbands.active(d):
		return RaggedWarbands.ready_count(d)+(0 if extra_type.is_empty() else 1)<=10
	var count := counts(d, db, extra_type)
	var extra := 1 if d.get("base", "") == "inn" else 0
	return count.x <= 8 + extra and count.y <= specialist_limit(d) + extra


static func reserve_candidates(d: Dictionary, db: FigureDb) -> Array[int]:
	var candidates: Array[int] = []
	if RedKingCampaign.economy_locked(d) or d.get("base", "") != "inn":
		return candidates
	var ready: Array[Dictionary] = []
	var kennel_id := -1
	var specialists := 0
	for unit: Dictionary in d.get("units", []):
		if not alive(unit) or int(unit.get("miss", 0)) > 0 or not soldier(unit, db):
			continue
		if owns(d, "kennel") and kennel_id < 0 and unit["type"] in ["war_hound", "wolf"]:
			kennel_id = int(unit["id"])
			continue
		ready.append(unit)
		if specialist(unit, db):
			specialists += 1
	var limit := specialist_limit(d)
	var wisdom_count := 0
	if wizard_item(d,"gear_rk_book_of_wisdom"):
		for unit in ready:
			if wisdom_eligible(unit,db):
				wisdom_count+=1
	var effective := specialists-int(wisdom_count>0)
	if ready.size() <= 8 and effective <= limit:
		return candidates
	for unit in ready:
		var after := effective-int(specialist(unit,db))+int(wisdom_count==1 and wisdom_eligible(unit,db))
		if after<=limit:
			candidates.append(int(unit["id"]))
	return candidates


static func reserve_id(d: Dictionary, db: FigureDb) -> int:
	var candidates := reserve_candidates(d, db)
	var selected := int(d.get("reserve_id", -1))
	if candidates.has(selected):
		return selected
	return -1 if candidates.is_empty() else candidates.back()


static func choose_reserve(d: Dictionary, id: int, db: FigureDb) -> bool:
	if not reserve_candidates(d, db).has(id):
		return false
	d["reserve_id"] = id
	return true
