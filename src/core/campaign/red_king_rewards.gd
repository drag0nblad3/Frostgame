class_name RedKingRewards
extends RefCounted
## Chapter six tables. Unimplemented item powers remain explicitly unavailable.
const PATH := "res://data/expansions/red_king/treasure.json"
static var _data: Dictionary={}


static func tables() -> Dictionary:
	if _data.is_empty():
		_data=JsonFile.read(PATH)
	return _data


static func catalog() -> Dictionary:
	return tables().get("items",{})


static func eligible(s: GameState) -> bool:
	return s.scenario_special.begins_with("red_king_") and s.content_profile.rule("red_king_treasure")


static func offer(d: Dictionary,entry: Dictionary) -> String:
	if d.get("red_king_exchange_used",false) or entry.has("rk_roll"):
		return ""
	if entry.get("rk_artefact",false):
		return "artefact"
	if entry.get("rk_exchange",false) and not d.get("red_king_exchange_used",false):
		return "treasure"
	return ""


static func result(first: int,second: int) -> String:
	if second>=20:
		return "artefact"
	var table: Array=tables()["first" if first<=10 else "second"]
	return str(table[clampi(second,1,19)-1])


static func artefact(d: Dictionary,dice: Dice) -> String:
	var seen: Array=d.get("red_king_found_artefacts",[])
	var pool: Array=[]
	for id in tables()["artefacts"]:
		if not seen.has(id):
			pool.append(id)
	if pool.is_empty():
		return ""
	var id: String=pool[dice.pick(pool.size())]
	seen.append(id)
	d["red_king_found_artefacts"]=seen
	return id


static func award(d: Dictionary,id: String,dice: Dice) -> bool:
	var chosen := artefact(d,dice) if id=="artefact" else id
	if chosen.is_empty():
		d["last_report"].append("All known artefacts have already been found.")
		return false
	if not catalog().has(chosen):
		return false
	var info: Dictionary=catalog()[chosen]
	if not d.has("loot"):
		d["loot"]=[]
	if not d.has("last_report"):
		d["last_report"]=[]
	if RedKingMaterials.is_supply(chosen):
		RedKingMaterials.add(d,chosen,6)
	else:
		d["loot"].append({"kind":"gear","gear":chosen,"owner":-1,"unlocked":not info.get("artefact",false)})
	d["last_report"].append("Red King reward: "+str(info["name"])+(" (locked)" if info.get("artefact",false) else ""))
	return true


static func exchange(d: Dictionary,dice: Dice) -> bool:
	var queue: Array=d.get("pending_treasure",[])
	if queue.is_empty():
		return false
	var entry: Dictionary=queue[0]
	var mode := offer(d,entry)
	if mode.is_empty():
		return false
	if mode=="artefact":
		queue.pop_front()
		d["red_king_exchange_used"]=true
		return award(d,"artefact",dice)
	d["red_king_exchange_used"]=true
	entry["rk_exchange"]=false
	entry["rk_roll"]=[dice.d20(),dice.d20()]
	if entry["central"]:
		# Show both results before asking whether to apply +2.
		return true
	queue.pop_front()
	return award(d,result(entry["rk_roll"][0],entry["rk_roll"][1]),dice)


static func resolve_bonus(d: Dictionary,bonus: bool,dice: Dice) -> bool:
	var queue: Array=d.get("pending_treasure",[])
	if queue.is_empty() or not queue[0].has("rk_roll"):
		return false
	var entry: Dictionary=queue.pop_front()
	var rolls: Array=entry["rk_roll"]
	return award(d,result(rolls[0],rolls[1]+(2 if bonus else 0)),dice)


static func label(first: int,second: int) -> String:
	var id := result(first,second)
	return "Artefact roll" if id=="artefact" else str(catalog()[id]["name"])


static func can_study(d: Dictionary,item: Dictionary) -> bool:
	var info: Dictionary=catalog().get(item.get("gear",""),{})
	return info.get("artefact",false) and not item.get("ragged_sealed",false) and not RaggedWarbands.absent_owner(d,item) and not item.get("unlocked",false) and int(item.get("last_study_game",-1))!=int(d.get("games",0)) and CampaignSuccession.living_wizard(d)


static func study(d: Dictionary,index: int,db: FigureDb,dice: Dice) -> bool:
	if index<0 or index>=d.get("loot",[]).size():
		return false
	var item: Dictionary=d["loot"][index]
	if not can_study(d,item):
		return false
	var info: Dictionary=catalog()[item["gear"]]
	var wizard: Dictionary={}
	for u in d["units"]:
		if u["type"]=="wizard" and BaseResources.alive(u):
			wizard=u
			break
	var bonuses := InjuryRules.bonuses(wizard,d.get("advances",{}))
	var total := dice.d20()+db.get_def("wizard").will+int(bonuses.get("will",0))
	item["last_study_game"]=int(d.get("games",0))
	item["unlocked"]=total>=int(info["unlock_tn"])
	d["last_report"].append("%s study (%d vs TN%d): %s."%[info["name"],total,info["unlock_tn"],"unlocked" if item["unlocked"] else "not understood"])
	return true
