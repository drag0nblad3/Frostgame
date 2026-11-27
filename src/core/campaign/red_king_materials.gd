class_name RedKingMaterials
extends RefCounted
const WAX := "gear_rk_enchanted_scroll_wax_6"
const VIAL := "gear_rk_enchanted_vials_6"
const FANGS := "gear_rk_golden_fangs_6"


static func is_supply(id: String) -> bool:
	return id in [WAX,VIAL,FANGS]


static func for_ritual(id: String) -> String:
	return WAX if id=="write_scroll" else (VIAL if id=="brew_potion" else "")


static func amount(item: Dictionary) -> int:
	return maxi(0,int(item.get("uses",6)))


static func available(d: Dictionary,id: String) -> int:
	if not is_supply(id):
		return 0
	var total := 0
	for item: Dictionary in d.get("loot",[]):
		if item.get("gear","")==id and int(item.get("owner",-1))<0 and not item.get("ragged_sealed",false):
			total+=amount(item)
	return total


static func add(d: Dictionary,id: String,count: int) -> void:
	for item: Dictionary in d["loot"]:
		if item.get("gear","")==id and int(item.get("owner",-1))<0 and not item.get("ragged_sealed",false):
			var take := mini(count,maxi(0,6-amount(item))) if id==FANGS else count
			item["uses"]=amount(item)+take
			count-=take
			if count==0:
				return
	while count>0:
		var take := mini(6,count) if id==FANGS else count
		d["loot"].append({"kind":"gear","gear":id,"owner":-1,"uses":take,"unlocked":true})
		count-=take


static func consume_at(d: Dictionary,index: int) -> bool:
	var item: Dictionary=d["loot"][index]
	if not is_supply(str(item.get("gear",""))) or amount(item)<=0 or item.get("ragged_sealed",false):
		return false
	item["uses"]=amount(item)-1
	if int(item["uses"])==0:
		d["loot"].remove_at(index)
	return true


static func consume(d: Dictionary,id: String) -> bool:
	if not is_supply(id):
		return false
	for i in d["loot"].size():
		var item: Dictionary=d["loot"][i]
		if item.get("gear","")==id and int(item.get("owner",-1))<0 and consume_at(d,i):
			return true
	return false


static func item_index(items: Array,key: String,id: String) -> int:
	var ordinary := -1
	for i in items.size():
		if items[i].get(key,"")!=id:
			continue
		if items[i].get("enchanted",false):
			return i
		if ordinary<0:
			ordinary=i
	return ordinary


static func use_potion(items: Array,index: int,dice: Dice) -> int:
	var item: Dictionary=items[index]
	var roll := dice.d20() if item.get("enchanted",false) else 0
	item.erase("enchanted")
	if roll<19:
		items.remove_at(index)
	return roll


static func split_fang(d: Dictionary,index: int) -> bool:
	if index<0 or index>=d.get("loot",[]).size() or RaggedWarbands.active(d):
		return false
	var item: Dictionary=d["loot"][index]
	if item.get("gear","")!=FANGS or item.get("ragged_sealed",false) or amount(item)<2:
		return false
	item["uses"]=amount(item)-1
	d["loot"].append({"kind":"gear","gear":FANGS,"owner":-1,"uses":1,"unlocked":true})
	return true


static func fang_count(f: Figure) -> int:
	if f==null or MagicEquipment.suppressed(f):
		return 0
	for item in f.items:
		if item.get("gear","")==FANGS:
			return amount(item)
	return 0


static func spend_fang(f: Figure) -> bool:
	if fang_count(f)<=0:
		return false
	for i in f.items.size():
		if f.items[i].get("gear","")==FANGS:
			f.items[i]["uses"]=amount(f.items[i])-1
			if int(f.items[i]["uses"])==0:
				f.items.remove_at(i)
			return true
	return false
