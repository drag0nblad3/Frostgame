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
		if d.get("red_king_recruit_status",false):
			status(d,d["units"].back(),db,dice,dice.d20())
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
	if not CampaignInventory.is_item(item) or item.get("ragged_sealed",false) or absent_owner(d,item) or (item.get("gear","")=="gear_rk_construct_spikes" and int(item.get("owner",-1))>=0):
		return false
	d["loot"].remove_at(index)
	return true


## Optional status roll, permanently recorded on the recruit.
static func status(d: Dictionary,u: Dictionary,db: FigureDb,dice: Dice,roll: int) -> void:
	u["ragged_status_roll"]=roll
	var definition := db.get_def(u["type"])
	var slots := CampaignInventory.slots(u,db)
	var changes: Dictionary=u.get("ragged_bonuses",{})
	if roll<=4:
		if definition.role=="soldier" and not definition.traits.has("animal"):
			InjuryRules.roll(u,dice)
	elif roll<=6:
		changes["fight"]=-1
	elif roll<=8:
		changes["health"]=-2
	elif roll<=10 and slots>0:
		var raw := dice.d20()
		var id: String=CampaignInventory.LESSER[raw-1] if raw<=18 else CampaignInventory.GREATER[dice.pick(CampaignInventory.GREATER.size())]
		if id not in CampaignPotions.VAULT_ONLY:
			d["loot"].append({"kind":"potion","potion":id,"owner":u["id"]})
	elif roll<=14 and slots>0:
		for w in definition.weapons:
			if not w.melee or w.id in ["unarmed","natural"]:
				continue
			var id: String="gear_rk_recruit_"+w.id
			if CampaignInventory.catalog().has(id):
				d["loot"].append({"kind":"gear","gear":id,"owner":u["id"]})
				break
	elif roll<=16 and slots>0:
		var item := {"kind":"gear","gear":MagicEquipment.ITEM_TABLE[dice.pick(MagicEquipment.ITEM_TABLE.size())],"owner":-1}
		d["loot"].append(item)
		if not CampaignInventory.assign_item(d,d["loot"].size()-1,int(u["id"]),db):
			d["loot"].pop_back()
	elif roll<=18 and roll>=17:
		changes["will"]=1
	elif roll>=19:
		changes["health"]=1
	u["ragged_bonuses"]=changes
	d["last_report"].append("Recruit status: %s rolled %d."%[definition.name,roll])


static func restore(d: Dictionary,db: FigureDb) -> void:
	if not active(d):
		return
	d.erase("red_king_ragged")
	for u: Dictionary in d["units"]:
		u.erase("ragged_absent")
		if not u.get("ragged_recruit",false) or not BaseResources.alive(u):
			continue
		# Core permits permanent constructs and the normal soldier roster.
		# Other recruited bestiary creatures need a supported permission rule.
		var definition := db.get_def(u["type"])
		if definition.role=="creature" and not Rituals.CONSTRUCTS.has(u["type"]):
			u["dismissed"]=true
			d["last_report"].append(definition.name+" leaves after the campaign.")
			for item: Dictionary in d["loot"]:
				if int(item.get("owner",-1))==int(u["id"]):
					item["owner"]=-1
	for item: Dictionary in d["loot"]:
		item.erase("ragged_sealed")
	d["red_king_reconcile_pending"]=true
