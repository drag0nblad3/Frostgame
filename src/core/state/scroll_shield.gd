class_name ScrollShield
extends RefCounted
const ITEM := "gear_rk_scroll_shield"


static func campaign_index(d: Dictionary,phase: String) -> int:
	for i in d.get("loot",[]).size():
		var item: Dictionary=d["loot"][i]
		var owner := int(item.get("owner",-1))
		if item.get("gear","")!=ITEM or not item.get("unlocked",false) or item.get("ragged_sealed",false) or owner<0 or owner>=d.get("units",[]).size():
			continue
		var u: Dictionary=d["units"][owner]
		if not BaseResources.alive(u) or u.get("ragged_absent",false):
			continue
		if phase=="roll" and int(item.get("shield_game",-1))!=int(d["games"]) and int(u.get("miss",0))==0 and not InjuryRules.blind(u):
			return i
		if phase=="before" and int(item.get("shield_game",-1))==int(d["games"]) and not item.get("shield_used",false) and int(u.get("miss",0))==0:
			return i
		if phase=="after" and int(item.get("shield_game",-1))==int(d["games"])-1 and item.get("shield_after",false) and not item.get("shield_used",false):
			return i
	return -1


static func roll(d: Dictionary,dice: Dice) -> bool:
	var index := campaign_index(d,"roll")
	if index<0:
		return false
	var item: Dictionary=d["loot"][index]
	d["preparation_started"]=true
	item["shield_game"]=int(d["games"])
	item["shield_spell"]=CampaignProgress.random_spell(dice)
	item["shield_used"]=false
	item["shield_after"]=false
	d["last_report"].append("Scroll Shield: "+str(item["shield_spell"]).replace("_"," ").capitalize())
	return true


static func ritual_index(d: Dictionary,id: String) -> int:
	var phase := "after" if Rituals.AFTER.has(id) else "before"
	var index := campaign_index(d,phase)
	if index<0 or d["loot"][index].get("shield_spell","")!=id:
		return -1
	return index


static func prepare(c: GameController) -> void:
	for f in c.state.figures:
		for item in f.items:
			if item.get("gear","")!=ITEM:
				continue
			if not item.has("shield_spell"):
				item["shield_spell"]=CampaignProgress.random_spell(c.dice)
			f.health=maxi(1,f.health-1)


static func source(f: Figure,id: String) -> Dictionary:
	if f==null or f.def.role not in ["wizard","apprentice"] or MagicEquipment.suppressed(f):
		return {}
	var s := RedKingVeil.of(f)
	if s==null:
		return {}
	for bearer in s.figures:
		if not bearer.in_play() or bearer.side!=f.side or bearer.ring_side!=f.ring_side or Shooting.distance(f,bearer)>2.001 or Contact.in_combat(s.figures,bearer) or MagicEquipment.suppressed(bearer) or bearer.destroyed_weapons.has("shield"):
			continue
		for item in bearer.items:
			if item.get("gear","")==ITEM and item.get("shield_spell","")==id and not item.get("shield_used",false):
				return item
	return {}


static func spells(f: Figure) -> Array[String]:
	var out: Array[String]=[]
	var s := RedKingVeil.of(f)
	if s==null:
		return out
	for bearer in s.figures:
		for item in bearer.items:
			var id := str(item.get("shield_spell",""))
			if not id.is_empty() and not out.has(id) and not source(f,id).is_empty():
				out.append(id)
	return out


static func consume(f: Figure,id: String) -> int:
	var item := source(f,id)
	if item.is_empty():
		return 0
	item["shield_used"]=true
	return 14
