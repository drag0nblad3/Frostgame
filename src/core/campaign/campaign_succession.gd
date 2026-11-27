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
	if RaggedWarbands.active(d):
		d["ragged_no_apprentice"]=true
	d["last_report"].append("%s succeeds the fallen wizard at level %d." % [clean_name, d["level"]])
	d.erase("prepared_demon")
	d.erase("dreams_xp")
	return true


## A new starting wizard can continue the current invasion, with no apprentice.
static func replace_ragged(d: Dictionary,draft: Dictionary) -> bool:
	if not RaggedWarbands.active(d) or not RedKingCampaign.active(d) or living_wizard(d) or not d.get("pending_treasure",[]).is_empty():
		return false
	var wizard: Dictionary={}
	for entry: Dictionary in draft.get("figures",[]):
		if entry["type"]=="wizard":
			wizard=entry
			break
	if wizard.is_empty() or draft.get("spells",{}).is_empty():
		return false
	var replacement := CampaignProgress.new()
	var roster := draft.duplicate(true)
	roster["figures"]=[wizard]
	roster["gold"]=0
	replacement.start(roster,ContentProfile.from_campaign(d))
	for key: String in ["campaign_story","red_king_stage","red_king_history","red_king_include_veil","red_king_strict_pursuit","red_king_ragged","red_king_recruit_status","red_king_found_artefacts","red_king_artefact_recovered","red_king_secured_kalamon","red_king_mind_completed","wounded_rules","reality_cracks",CompanionMantle.OPTION,"games"]:
		if d.has(key):
			replacement.data[key]=d[key]
	replacement.data["ragged_no_apprentice"]=true
	replacement.data["last_report"]=["A new wizard joins the invasion at the current story stage. No apprentice; roll random replacements after preparation."]
	d.clear()
	d.merge(replacement.data)
	return true
