class_name CampaignSuccession
extends RefCounted
## Continue an eligible warband after its wizard dies (p. 103).


static func living_wizard(d: Dictionary) -> bool:
	for u: Dictionary in d.get("units", []):
		if u["type"] == "wizard" and BaseResources.alive(u):
			return true
	return false


static func candidate(d: Dictionary) -> int:
	if d.is_empty() or int(d.get("level", 0)) < 6 or living_wizard(d) or not d.get("pending_treasure", []).is_empty():
		return -1
	var fallen := false
	for u: Dictionary in d["units"]:
		if u["type"] == "wizard" and u["dead"] and not u.get("dismissed", false):
			fallen = true
	if not fallen:
		return -1
	for u: Dictionary in d["units"]:
		if u["type"] == "apprentice" and BaseResources.alive(u) and not InjuryRules.blind(u):
			return int(u["id"])
	return -1


static func promote(d: Dictionary, name: String) -> bool:
	var index := candidate(d)
	var clean_name := name.strip_edges()
	if index < 0 or clean_name.is_empty():
		return false
	for u: Dictionary in d["units"]:
		if u["type"] == "wizard" and u["dead"] and not u.get("dismissed", false):
			CampaignInventory.lose_owned(d, int(u["id"]))
			u["dismissed"] = true
	var successor: Dictionary = d["units"][index]
	successor["type"] = "wizard"
	# Apprentice's actual stats become the new wizard's base stats.
	var advances: Dictionary = d.get("advances", {})
	for stat: String in ["fight", "will", "health"]:
		advances[stat] = int(advances.get(stat, 0)) - 2
	d["advances"] = advances
	d["level"] = int(d["level"]) - 6
	d["name"] = clean_name
	d["last_report"].append("%s succeeds the fallen wizard at level %d." % [clean_name, d["level"]])
	d.erase("prepared_demon")
	d.erase("dreams_xp")
	return true
