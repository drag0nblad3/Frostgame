class_name RedKingCampaign
extends RefCounted
## Ordered, opt-in storyline. Existing free-form campaigns remain unchanged.
const PATH := "res://data/campaigns/red_king.json"


static func active(d: Dictionary) -> bool:
	return d.get("campaign_story","")=="red_king"


static func stages() -> Array:
	return JsonFile.read(PATH).get("stages",[])


static func start(d: Dictionary,profile: ContentProfile,include_veil: bool) -> bool:
	if d.is_empty() or active(d) or int(d.get("games",0))!=0 or not profile.allows("campaigns","red_king") or not profile.enabled.has("red_king"):
		return false
	d["campaign_story"]="red_king"
	d["red_king_stage"]=0
	d["red_king_include_veil"]=include_veil
	d["red_king_history"]=[]
	return true


static func next_stage(d: Dictionary) -> Dictionary:
	if not active(d):
		return {}
	var all := stages()
	var i := int(d.get("red_king_stage",0))
	if i<0 or i>=all.size():
		return {}
	return all[i]


static func next_id(d: Dictionary) -> String:
	return str(next_stage(d).get("id",""))


static func permits(d: Dictionary,id: String) -> bool:
	return not active(d) or next_id(d)==id


static func economy_locked(d: Dictionary) -> bool:
	return RaggedWarbands.active(d) or (active(d) and next_id(d)=="red_king_veil")


static func suppress_base_after(d: Dictionary,id: String) -> bool:
	return economy_locked(d) or (active(d) and id=="red_king_investigations" and d.get("red_king_include_veil",false))


static func advance(d: Dictionary,id: String) -> bool:
	if not active(d) or not permits(d,id):
		return false
	var i := int(d["red_king_stage"])+1
	var all := stages()
	d["red_king_history"].append(id)
	while i<all.size():
		var stage: Dictionary=all[i]
		if stage.get("optional",false) and not d.get("red_king_include_veil",false):
			i+=1
			continue
		if stage.get("requires_flag","")=="secured_kalamon" and not d.get("red_king_secured_kalamon",false):
			i+=1
			continue
		break
	d["red_king_stage"]=i
	if i<all.size() and all[i].get("campaign_mode","")=="ragged_warbands":
		RaggedWarbands.enter(d)
	return true
