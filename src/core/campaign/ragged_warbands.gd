class_name RaggedWarbands
extends RefCounted
## Act III campaign restrictions. Ordinary campaigns never set this flag.
const STAGES := ["red_king_herded","red_king_sinkhole","red_king_hill","red_king_tethers","red_king_bridge","red_king_ringworld"]
const TABLE_II := ["thug","thug","thief","thief","war_hound","war_hound","infantryman","infantryman","man_at_arms","man_at_arms","archer","crossbowman","treasure_hunter","apothecary","knight","templar","ranger","tracker","barbarian","marksman"]
const TABLE_III := ["assassin","bard","captain","collegium_porter","crow_master","demon_hunter","demonic_servant","javelineer","monk","mystic_warrior","pack_mule","rangifer","trap_expert","tunnel_fighter","werewolf","large_construct","minor_demon","snow_troll","foulhorn","vampire"]


static func active(d: Dictionary) -> bool:
	return bool(d.get("red_king_ragged",false))


static func stage(id: String) -> bool:
	return STAGES.has(id)


static func enter(d: Dictionary) -> void:
	if active(d):
		return
	d["red_king_ragged"]=true
	for item: Dictionary in d.get("loot",[]):
		if CampaignInventory.is_item(item) and int(item.get("owner",-1))<0:
			item["ragged_sealed"]=true
	d.erase("prepared_demon")


static func ready_count(d: Dictionary) -> int:
	var count := 0
	for u: Dictionary in d.get("units",[]):
		if BaseResources.alive(u) and int(u.get("miss",0))==0 and not InjuryRules.blind(u):
			count+=1
	return count


static func roll_recruit(db: FigureDb,dice: Dice) -> String:
	# Missing supplements are rerolled, never silently substituted.
	for attempt in 256:
		var table := TABLE_II if dice.d20()<=14 else TABLE_III
		var id: String=table[dice.d20()-1]
		if db.available(id):
			return id
	return "thug" if db.available("thug") else ""


static func fill(d: Dictionary,db: FigureDb,dice: Dice) -> int:
	if not active(d) or not CampaignSuccession.living_wizard(d):
		return 0
	var count := 0
	while ready_count(d)<10:
		var id := roll_recruit(db,dice)
		if id.is_empty():
			break
		var definition := db.get_def(id)
		d["units"].append({"type":id,"id":d["units"].size(),"miss":0,"injuries":0,"dead":false,"ragged_recruit":true,"permanent_summon":definition.role=="creature"})
		d["last_report"].append("Random recruit: "+definition.name)
		count+=1
	return count


static func soldier_survival(u: Dictionary,roll: int) -> void:
	u["dead"]=false
	u["miss"]=0
	if roll<=8:
		u["ragged_absent"]=true


static func absent_owner(d: Dictionary,item: Dictionary) -> bool:
	var owner := int(item.get("owner",-1))
	return owner>=0 and owner<d.get("units",[]).size() and d["units"][owner].get("ragged_absent",false)


static func has_unassigned(d: Dictionary) -> bool:
	for item: Dictionary in d.get("loot",[]):
		if CampaignInventory.is_item(item) and not item.get("ragged_sealed",false) and int(item.get("owner",-1))<0:
			return true
	return false


static func discard(d: Dictionary,index: int) -> bool:
	if not active(d) or index<0 or index>=d["loot"].size():
		return false
	var item: Dictionary=d["loot"][index]
	if not CampaignInventory.is_item(item) or item.get("ragged_sealed",false) or absent_owner(d,item):
		return false
	d["loot"].remove_at(index)
	return true
