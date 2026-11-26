class_name InjuryRules
extends RefCounted
## Roll table (pp. 77–79). The printed overlap at six is resolved in favour of Crushed Arm.
const TABLE := ["lost_toes", "lost_toes", "smashed_leg", "smashed_leg", "smashed_leg", "crushed_arm", "crushed_arm", "crushed_arm", "crushed_arm", "crushed_arm", "lost_fingers", "lost_fingers", "never_quite_as_strong", "never_quite_as_strong", "psychological_scars", "psychological_scars", "niggling_injury", "niggling_injury", "smashed_jaw", "lost_eye"]


static func roll(unit: Dictionary, dice: Dice) -> String:
	var injuries: Dictionary = unit.get("injury_types", {})
	var id := ""
	for attempt in 100:
		var candidate: String = TABLE[dice.d20() - 1]
		if int(injuries.get(candidate, 0)) < 2:
			id = candidate
			break
	if id == "":
		for candidate: String in TABLE:
			if int(injuries.get(candidate, 0)) < 2:
				id = candidate
				break
	if id == "":
		return "no further injury"
	injuries[id] = int(injuries.get(id, 0)) + 1
	unit["injury_types"] = injuries
	unit["injuries"] = int(unit.get("injuries", 0)) + 1
	return id.replace("_", " ")


static func bonuses(unit: Dictionary, base: Dictionary) -> Dictionary:
	var result := base.duplicate()
	var injuries: Dictionary = unit.get("injury_types", {})
	var penalties := {"move": 2 * int(injuries.get("smashed_leg", 0)), "fight": int(injuries.get("crushed_arm", 0)), "shoot": int(injuries.get("lost_fingers", 0)), "will": int(injuries.get("psychological_scars", 0))}
	for stat: String in penalties:
		result[stat] = int(result.get(stat, 0)) - int(penalties[stat])
	return result


static func starting_loss(unit: Dictionary) -> int:
	var injuries: Dictionary = unit.get("injury_types", {})
	var niggle := int(injuries.get("niggling_injury", 0))
	return int(injuries.get("never_quite_as_strong", 0)) + (niggle + 2 if niggle > 0 and not unit.get("niggle_paid", false) else 0)


static func blind(unit: Dictionary) -> bool:
	return int(unit.get("injury_types", {}).get("lost_eye", 0)) >= 2


static func treatment_price(d: Dictionary, unit: Dictionary) -> int:
	if RedKingCampaign.economy_locked(d):
		return -1
	var count := int(unit.get("injury_types", {}).get("niggling_injury", 0))
	if count == 0 or unit.get("niggle_paid", false) or unit["dead"] or unit.get("dismissed", false):
		return -1
	var price := 20 + count * 10
	for other: Dictionary in d["units"]:
		if other["type"] == "apothecary" and not other["dead"] and not other.get("dismissed", false):
			price -= 10
	if unit["type"] == "wizard" and BaseResources.owns(d, "sarcophagus_of_healing"):
		price -= 10
	return maxi(0, price)


static func treat(d: Dictionary, index: int) -> bool:
	if index < 0 or index >= d["units"].size():
		return false
	var unit: Dictionary = d["units"][index]
	var cost := treatment_price(d, unit)
	if cost < 0 or int(d["gold"]) < cost:
		return false
	d["gold"] = int(d["gold"]) - cost
	unit["niggle_paid"] = true
	return true
