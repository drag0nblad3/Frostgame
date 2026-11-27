class_name RedKingCampaign
extends RefCounted
## Ordered, opt-in storyline. Existing free-form campaigns remain unchanged.
const PATH := "res://data/campaigns/red_king.json"


static func active(d: Dictionary) -> bool:
	return d.get("campaign_story","")=="red_king"


static func stages() -> Array:
	return JsonFile.read(PATH).get("stages",[])


static func start(d: Dictionary,profile: ContentProfile,include_veil: bool,strict_pursuit: bool=false) -> bool:
	if d.is_empty() or active(d) or int(d.get("games",0))!=0 or not profile.allows("campaigns","red_king") or not profile.enabled.has("red_king"):
		return false
	d["campaign_story"]="red_king"
	d["red_king_stage"]=0
	d["red_king_include_veil"]=include_veil
	d["red_king_strict_pursuit"]=strict_pursuit
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
	return next_id(d)==id if active(d) else freeform_permits(id)


## Mindscape is a rescue-linked bonus encounter, not a free-form campaign mission.
static func freeform_permits(id: String) -> bool:
	return id!="red_king_mind"


static func skip_mind(d: Dictionary) -> bool:
	if next_id(d)!="red_king_mind" or not d.get("pending_treasure",[]).is_empty():
		return false
	d["red_king_secured_kalamon"]=false
	d["red_king_mind_skipped"]=true
	d["last_report"].append("Skipped the optional Mindscape encounter.")
	return advance(d,"red_king_mind",false)


## The two short pursuit intermissions block commerce and base effects,
## but do not invalidate a roster that was legal before the pursuit.
static func temporary_lock(d: Dictionary) -> bool:
	if not active(d):
		return false
	return next_id(d)=="red_king_veil" or (next_id(d)=="red_king_demons_and_mad_man" and bool(d.get("red_king_strict_pursuit",false)))


static func economy_locked(d: Dictionary) -> bool:
	return RaggedWarbands.active(d) or temporary_lock(d)


static func suppress_base_after(d: Dictionary,id: String) -> bool:
	if RaggedWarbands.active(d):
		return true
	if not active(d):
		return false
	return (id=="red_king_investigations" and bool(d.get("red_king_include_veil",false))) or (id=="red_king_back_into_fire" and bool(d.get("red_king_strict_pursuit",false)))


static func capacity_context(d: Dictionary) -> Dictionary:
	if not temporary_lock(d):
		return d
	var prior := d.duplicate(true)
	prior.erase("campaign_story")
	return prior


static func advance(d: Dictionary,id: String,completed: bool=true) -> bool:
	if not active(d) or not permits(d,id):
		return false
	var i := int(d["red_king_stage"])+1
	var all := stages()
	if completed:
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


static func reconcile(d: Dictionary,db: FigureDb) -> bool:
	if not active(d) or not next_id(d).is_empty() or not d.get("pending_treasure",[]).is_empty() or not RaggedWarbands.active(d):
		return false
	RaggedWarbands.restore(d,db)
	d["last_report"].append("Restore the warband: dismiss surplus members until normal roster limits are met.")
	return true


static func return_to_skirmishes(d: Dictionary,db: FigureDb) -> bool:
	if not active(d) or not d.get("red_king_reconcile_pending",false) or not BaseResources.fits(d,db):
		return false
	d.erase("red_king_reconcile_pending")
	d.erase("campaign_story")
	return true
