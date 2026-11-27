class_name CompanionMantle
extends RefCounted
## Explicit compatibility option: the supplement treats these companions as specialists,
## whereas the second-edition core spell treats all animal companions as standard soldiers.
const ITEM := "gear_rk_mantle_of_the_bear_or_leopard"
const ANIMALS := ["bear","snow_leopard"]
const OPTION := "red_king_mantle_classification"

static func enabled(d: Dictionary) -> bool:
	return bool(d.get(OPTION,false)) and ContentProfile.from_campaign(d).enabled.has("red_king")

static func matching(d: Dictionary,owner: int,animal: String) -> bool:
	if owner<0 or owner>=d.get("units",[]).size() or not BaseResources.alive(d["units"][owner]):
		return false
	for item: Dictionary in d.get("loot",[]):
		if item.get("gear","")==ITEM and int(item.get("owner",-1))==owner and item.get("mantle_animal","")==animal and not item.get("ragged_sealed",false):
			return true
	return false

static func specialist(d: Dictionary,unit: Dictionary) -> bool:
	return enabled(d) and ANIMALS.has(unit.get("type","")) and unit.has("companion_of") and not matching(d,int(unit["companion_of"]),str(unit["type"]))

static func bind(d: Dictionary,index: int,animal: String) -> bool:
	if index<0 or index>=d.get("loot",[]).size() or not ANIMALS.has(animal):
		return false
	var item: Dictionary=d["loot"][index]
	if item.get("gear","")!=ITEM or not str(item.get("mantle_animal","")).is_empty() or item.get("ragged_sealed",false):
		return false
	item["mantle_animal"]=animal
	return true
