class_name CasterLoadout
extends RefCounted
## Spellcaster weapons, free dagger, two-slot heavy weapons and quiver.
const PRESETS := {"Staff": ["staff", "dagger"], "Hand weapon": ["hand_weapon", "dagger"], "Two-handed": ["two_handed", "dagger"], "Dagger only": ["dagger"], "Bow": ["bow", "dagger"], "Crossbow": ["crossbow", "dagger"], "Staff + bow": ["staff", "bow", "dagger"], "Staff + crossbow": ["staff", "crossbow", "dagger"], "Hand weapon + bow": ["hand_weapon", "bow", "dagger"], "Hand weapon + crossbow": ["hand_weapon", "crossbow", "dagger"], "Two-handed + bow": ["two_handed", "bow", "dagger"], "Two-handed + crossbow": ["two_handed", "crossbow", "dagger"], "Staff + hand weapon": ["staff", "hand_weapon", "dagger"]}


static func is_caster(type: String) -> bool:
	return type in ["wizard", "apprentice"]


static func standard(unit: Dictionary) -> Array:
	return unit.get("weapons", PRESETS["Staff"]).duplicate()


static func valid(weapons: Array) -> bool:
	var seen := {}
	for id: String in weapons:
		if id not in MagicEquipment.WEAPONS or seen.has(id):
			return false
		seen[id] = true
	return not (seen.has("bow") and seen.has("crossbow"))


static func weapon_slots(weapons: Array) -> int:
	var used := 0
	for id: String in weapons:
		if id == "dagger":
			continue
		used += 2 if id in ["two_handed", "bow", "crossbow"] else 1
	return used


static func carried(d: Dictionary, unit: Dictionary, omit: int = -1, extra: Dictionary = {}) -> Dictionary:
	var weapons := standard(unit)
	var other := 0
	var discounted := {}
	var catalog := CampaignInventory.catalog()
	var items: Array = []
	for i in d.get("loot", []).size():
		var item: Dictionary = d["loot"][i]
		if i != omit and int(item.get("owner", -1)) == int(unit["id"]):
			items.append(item)
	if not extra.is_empty():
		items.append(extra)
	for item: Dictionary in items:
		var info: Dictionary = catalog.get(CampaignInventory.item_id(item), {})
		var type := str(info.get("type", ""))
		if type in MagicEquipment.WEAPONS:
			if not weapons.has(type):
				weapons.append(type)
			if int(info.get("slot_discount", 0)) > 0:
				discounted[type] = int(info["slot_discount"])
		else:
			other += 1
	var used := weapon_slots(weapons) + other
	if weapons.has("bow") or weapons.has("crossbow"):
		for item: Dictionary in items:
			if item.get("gear","")==MagicAmmo.ITEM:
				used-=1
				break
	for discount in discounted.values():
		used -= int(discount)
	return {"weapons": weapons, "slots": used}


static func fits(d: Dictionary, unit: Dictionary, omit: int = -1, extra: Dictionary = {}) -> bool:
	var load := carried(d, unit, omit, extra)
	return valid(load["weapons"]) and int(load["slots"]) <= (5 if unit["type"] == "wizard" else 4)


static func set_weapons(d: Dictionary, owner: int, weapons: Array) -> bool:
	if owner < 0 or owner >= d.get("units", []).size() or not valid(weapons):
		return false
	var unit: Dictionary = d["units"][owner]
	if not is_caster(unit["type"]) or not BaseResources.alive(unit):
		return false
	var proposed := unit.duplicate()
	proposed["weapons"] = weapons.duplicate()
	if not fits(d, proposed):
		return false
	unit["weapons"] = proposed["weapons"]
	return true


static func definition(def: FigureDef, weapons: Array, db: FigureDb) -> FigureDef:
	var copy := def.with_bonuses({})
	copy.weapons.clear()
	for id: String in weapons:
		if id in MagicEquipment.WEAPONS and db.weapons.has(id):
			copy.weapons.append(db.weapons[id])
	return copy
