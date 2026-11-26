class_name CampaignInventory
extends RefCounted
## Item ownership is stored on each individual loot record, not duplicated in the roster.
const LESSER := ["healing","strength","toughness","speed","invisibility","explosive_cocktail","teleportation","elemental_absorption","clearsight","poison","fury","iron_mind","burrowing","fairy_dust","construct_oil","fire_breath","preservation","chameleon"]
const GREATER := ["empowerment","shrinking","restoration","dreams","shatterstar","darkness","ethereal_vacuum","invulnerability","null","life"]


static func catalog() -> Dictionary:
	var result: Dictionary = JsonFile.read("res://data/potions.json")
	result.merge(JsonFile.read("res://data/magic_equipment.json"))
	result.merge(RedKingRewards.catalog())
	var spells: Dictionary = JsonFile.read("res://data/spells.json")
	for id: String in spells:
		result["scroll_" + id] = {"name": "Scroll: " + str(spells[id]["name"]), "buy": 250, "sell": 30, "live": spells[id]["kind"] not in ["unimplemented", "ritual"]}
		result["grimoire_" + id] = {"name": "Grimoire: " + str(spells[id]["name"]), "buy": 500, "sell": 200, "live": true}
	return result


static func item_id(item: Dictionary) -> String:
	if item.get("kind", "") == "grimoire":
		return "grimoire_" + str(item.get("spell", ""))
	if item.has("scroll"):
		return "scroll_" + str(item["scroll"])
	return str(item.get("gear", item.get("potion", "")))


static func is_item(item: Dictionary) -> bool:
	return item["kind"] in ["potion", "gear", "scroll"]


static func identify(d: Dictionary, reward: Dictionary, dice: Dice) -> void:
	var kind: String = reward["kind"]
	if kind.ends_with("potions"):
		for i in int(kind.split(" ")[0]):
			var roll := dice.d20()
			var id: String = LESSER[roll - 1] if roll <= 18 else GREATER[floori((dice.d20() - 1) / 2.0)]
			d["loot"].append({"kind": "potion", "potion": id, "owner": -1})
	elif kind.ends_with("scroll") or kind.ends_with("scrolls"):
		for i in int(kind.split(" ")[0]):
			d["loot"].append({"kind": "scroll", "scroll": CampaignProgress.random_spell(dice), "owner": -1})
	elif kind in ["magic arms/armour", "magic item"]:
		var table := MagicEquipment.ARM_TABLE if kind == "magic arms/armour" else MagicEquipment.ITEM_TABLE
		var item := {"kind": "gear", "gear": table[dice.d20() - 1], "owner": -1}
		if item["gear"] == "gear_staff_casting":
			item["casting_spell"] = CampaignProgress.random_spell(dice)
		d["loot"].append(item)
	elif kind != "":
		d["loot"].append(reward)


static func slots(unit: Dictionary, db: FigureDb) -> int:
	var def := db.get_def(unit["type"])
	if def.traits.has("animal") or def.role == "creature":
		return 0
	return 5 if def.role == "wizard" else (4 if def.role == "apprentice" else 1)


static func assign_item(d: Dictionary, index: int, owner: int, db: FigureDb) -> bool:
	if d.is_empty() or index < 0 or index >= d["loot"].size():
		return false
	var item: Dictionary = d["loot"][index]
	if RaggedWarbands.active(d):
		if item.get("ragged_sealed",false) or RaggedWarbands.absent_owner(d,item):
			return false
		if owner<0:
			return false
	if not is_item(item):
		return false
	if item.get("gear","") in ["gear_rk_mind_lock_collar","gear_rk_construct_spikes"]:
		if not ContentProfile.from_campaign(d).item_allowed(item_id(item)):
			return false
		var collar: bool=item["gear"]=="gear_rk_mind_lock_collar"
		if collar and owner==-1:
			item["owner"]=-1
			return true
		if (not collar and int(item.get("owner",-1))>=0) or owner<0 or owner>=d["units"].size():
			return false
		var recipient: Dictionary=d["units"][owner]
		if recipient["dead"] or recipient.get("dismissed",false) or recipient.get("ragged_absent",false):
			return false
		var definition := db.get_def(recipient["type"])
		if not definition.traits.has("animal" if collar else "construct"):
			return false
		for other: Dictionary in d["loot"]:
			if other!=item and int(other.get("owner",-1))==owner and (collar or other.get("gear","")==item["gear"]):
				return false
		item["owner"]=owner
		return true
	if item.get("gear", "") == "gear_construct_hammer":
		if int(item.get("owner", -1)) >= 0 or owner < 0 or owner >= d["units"].size():
			return false
		var construct: Dictionary = d["units"][owner]
		if construct["dead"] or construct.get("dismissed", false) or construct["type"] not in ["medium_construct", "large_construct"]:
			return false
		for other: Dictionary in d["loot"]:
			if other.get("gear", "") == "gear_construct_hammer" and int(other.get("owner", -1)) == owner:
				return false
		item["owner"] = owner
		return true
	if owner == -1:
		var previous := int(item.get("owner",-1))
		item["owner"] = -1
		if item.get("gear","") in ["gear_rk_amulet_of_charisma","gear_rk_book_of_wisdom"] and not BaseResources.fits(d,db):
			item["owner"]=previous
			return false
		return true
	if item.get("potion", "") in CampaignPotions.VAULT_ONLY:
		return false
	if owner < 0 or owner >= d["units"].size():
		return false
	var unit: Dictionary = d["units"][owner]
	if unit["dead"] or unit.get("dismissed", false) or unit.get("ragged_absent",false):
		return false
	if item["kind"] == "scroll" and unit["type"] not in ["wizard", "apprentice"]:
		return false
	var used := 0
	var info: Dictionary = catalog()[item_id(item)]
	if info.get("expansion","")=="red_king" and (not info["live"] or not item.get("unlocked",true)):
		return false
	if info.get("apprentice_only",false) and (unit["type"]!="apprentice" or str(item.get("casting_spell","")).is_empty()):
		return false
	if info.get("vault_only",false):
		return false
	if info.get("wizard_only",false) and unit["type"]!="wizard":
		return false
	if item.get("gear","")=="gear_rk_lightning_brooch":
		var definition := db.get_def(unit["type"])
		if unit["type"] in ["knight","templar","marksman"]:
			return false
		for trait_id: String in definition.traits:
			if trait_id.begins_with("elemental_resistance_"):
				return false
	if (info.get("caster_only",false) or info.get("bonus",{}).has("cast_failure_cap")) and unit["type"] not in ["wizard","apprentice"]:
		return false
	if item.get("gear", "") == "gear_ring_transference" and unit["type"] not in ["wizard", "apprentice"]:
		return false
	var caster := CasterLoadout.is_caster(unit["type"])
	if item["kind"] == "gear" and not (caster and info["type"] in MagicEquipment.WEAPONS) and not MagicEquipment.compatible(db.get_def(unit["type"]), info):
		return false
	for i in d["loot"].size():
		if i != index and int(d["loot"][i].get("owner", -1)) == owner:
			var other: Dictionary = d["loot"][i]
			var other_info: Dictionary = catalog()[item_id(other)]
			if (item.get("gear","")=="gear_rk_lightning_brooch" and (other_info.get("bonus",{}).has("elemental_resistance") or other_info.get("type","")=="heavy_armour")) or (other.get("gear","")=="gear_rk_lightning_brooch" and (info.get("bonus",{}).has("elemental_resistance") or info.get("type","")=="heavy_armour")):
				return false
			if item_id(item)==RedKingMaterials.FANGS and item_id(other)==RedKingMaterials.FANGS:
				var total := RedKingMaterials.amount(item)+RedKingMaterials.amount(other)
				if total>6:
					return false
				other["uses"]=total
				d["loot"].remove_at(index)
				return true
			if item["kind"] == "gear" and other["kind"] == "gear":
				if item_id(item)==item_id(other) or (info["type"]!="item" and other_info["type"]==info["type"]):
					return false
			used += 1
	if caster:
		if not CasterLoadout.fits(d, unit, index, item):
			return false
	elif used >= slots(unit, db):
		return false
	item["owner"] = owner
	return true


static func buy(d: Dictionary, id: String, dice: Dice = null) -> bool:
	var potions := catalog()
	if RedKingCampaign.economy_locked(d) or d.is_empty() or not potions.has(id) or not ContentProfile.from_campaign(d).item_allowed(id):
		return false
	if potions[id].get("expansion","")=="red_king" and not potions[id]["live"]:
		return false
	var price := int(potions[id]["buy"])
	if price <= 0 or int(d["gold"]) < price:
		return false
	d["gold"] = int(d["gold"]) - price
	if id.begins_with("grimoire_"):
		d["loot"].append({"kind": "grimoire", "spell": id.trim_prefix("grimoire_")})
	elif id.begins_with("scroll_"):
		d["loot"].append({"kind": "scroll", "scroll": id.trim_prefix("scroll_"), "owner": -1})
	elif RedKingMaterials.is_supply(id):
		RedKingMaterials.add(d,id,1)
	elif id.begins_with("gear_"):
		var item := {"kind": "gear", "gear": id, "owner": -1}
		if id == "gear_staff_casting":
			item["casting_spell"] = CampaignProgress.random_spell(dice if dice != null else Dice.new(0))
		d["loot"].append(item)
	else:
		d["loot"].append({"kind": "potion", "potion": id, "owner": -1})
	return true


static func can_sell(d: Dictionary, item: Dictionary) -> bool:
	if RedKingCampaign.economy_locked(d):
		return false
	if item["kind"] == "grimoire":
		return d.get("spells", {}).has(item.get("spell", ""))
	return is_item(item) and int(item.get("owner", -1)) < 0


static func sell(d: Dictionary, index: int) -> bool:
	if d.is_empty() or index < 0 or index >= d["loot"].size():
		return false
	var item: Dictionary = d["loot"][index]
	if not can_sell(d, item):
		return false
	var info: Dictionary=catalog()[item_id(item)]
	var price := int(info["sell"])
	if RedKingMaterials.is_supply(item_id(item)):
		if not RedKingMaterials.consume_at(d,index):
			return false
		d["gold"]=int(d["gold"])+price
		return true
	if info.get("artefact",false) and not item.get("unlocked",false):
		price=floori(float(price)/2.0)
	d["gold"] = int(d["gold"]) + price
	d["loot"].remove_at(index)
	return true


static func loadout(d: Dictionary, owner: int) -> Array:
	var items: Array = []
	for item: Dictionary in d["loot"]:
		if int(item.get("owner", -1)) != owner:
			continue
		if item["kind"] == "potion":
			items.append({"potion": item["potion"], "campaign_item": true,"enchanted":bool(item.get("enchanted",false))})
		elif item["kind"] == "scroll":
			items.append({"scroll": item["scroll"], "campaign_item": true,"enchanted":bool(item.get("enchanted",false))})
		elif item["kind"] == "gear":
			var gear := {"gear": item["gear"], "gear_info": catalog()[item["gear"]].duplicate(true), "campaign_item": true}
			if item["gear"] in ["gear_staff_casting","gear_rk_golden_incunabula"]:
				gear["casting_spell"] = item.get("casting_spell", "")
			if item["gear"] == PowerPool.ORB:
				gear["power_left"] = PowerPool.remaining(item)
			if item["gear"]==RedKingMaterials.FANGS:
				gear["uses"]=RedKingMaterials.amount(item)
			if item.get("ivory_graft",false):
				gear["ivory_graft"]=true
			if item["gear"]==RedKingCampaignGear.POTION_STAFF and not str(item.get("stored_potion","")).is_empty():
				gear["potion"]=item["stored_potion"]
			if item["gear"]==RedKingCampaignGear.GOLDEN_BOTTLE and int(item.get("bottle_doses",0))>0:
				gear["potion"]=item["bottle_potion"]
				gear["bottle_doses"]=int(item["bottle_doses"])
			items.append(gear)
	return items


static func settle(d: Dictionary, c: GameController, side: int) -> void:
	for f in c.state.figures:
		if f.original_side != side or f.campaign_id < 0:
			continue
		var remaining := {}
		var enchanted := {}
		var orb_left := -1
		var fangs_left := 0
		var bottle_left := 0
		for item: Dictionary in f.items:
			if item.get("campaign_item", false):
				var id := item_id(item)
				if id == PowerPool.ORB:
					orb_left = PowerPool.remaining(item)
				if id==RedKingMaterials.FANGS:
					fangs_left=RedKingMaterials.amount(item)
				if id==RedKingCampaignGear.GOLDEN_BOTTLE:
					bottle_left=int(item.get("bottle_doses",0))
				remaining[id] = int(remaining.get(id, 0)) + 1
				if item.get("enchanted",false):
					enchanted[id]=int(enchanted.get(id,0))+1
		for i in range(d["loot"].size() - 1, -1, -1):
			var item: Dictionary = d["loot"][i]
			if not is_item(item) or int(item.get("owner", -1)) != f.campaign_id:
				continue
			var id := item_id(item)
			if int(remaining.get(id, 0)) <= 0 or (id == PowerPool.ORB and orb_left == 0):
				d["loot"].remove_at(i)
			else:
				remaining[id] = int(remaining[id]) - 1
				if item.has("potion") or item.has("scroll"):
					item.erase("enchanted")
					if int(enchanted.get(id,0))>0:
						item["enchanted"]=true
						enchanted[id]=int(enchanted[id])-1
				if id == PowerPool.ORB:
					item["power_left"] = orb_left
				if id==RedKingMaterials.FANGS:
					item["uses"]=fangs_left
				if id==RedKingCampaignGear.GOLDEN_BOTTLE:
					item["bottle_doses"]=bottle_left
					if bottle_left<=0:
						item.erase("bottle_potion")


static func lose_owned(d: Dictionary, owner: int) -> void:
	for i in range(d["loot"].size() - 1, -1, -1):
		if int(d["loot"][i].get("owner", -1)) == owner:
			d["loot"].remove_at(i)


static func bind_incunabula(d: Dictionary,index: int,spell: String) -> bool:
	if index<0 or index>=d.get("loot",[]).size():
		return false
	var item: Dictionary=d["loot"][index]
	if item.get("gear","")!="gear_rk_golden_incunabula" or not str(item.get("casting_spell","")).is_empty() or item.get("ragged_sealed",false):
		return false
	if not JsonFile.read("res://data/spells.json").has(spell) or not ContentProfile.from_campaign(d).allows("spells",spell):
		return false
	item["casting_spell"]=spell
	return true


static func incunabula_bonus(d: Dictionary,owner: int,spell: String) -> int:
	if owner<0 or owner>=d.get("units",[]).size() or d["units"][owner]["type"]!="apprentice":
		return 0
	for item: Dictionary in d.get("loot",[]):
		if item.get("gear","")=="gear_rk_golden_incunabula" and int(item.get("owner",-1))==owner and item.get("casting_spell","")==spell:
			return 1
	return 0


static func ivory_staff_choices(d: Dictionary,index: int) -> Array[int]:
	var out: Array[int]=[]
	if index<0 or index>=d.get("loot",[]).size() or RedKingCampaign.economy_locked(d) or int(d.get("gold",0))<500:
		return out
	var hand: Dictionary=d["loot"][index]
	if hand.get("gear","")!="gear_rk_ivory_hand" or hand.get("ragged_sealed",false):
		return out
	var items := catalog()
	for i in d["loot"].size():
		var staff: Dictionary=d["loot"][i]
		var info: Dictionary=items.get(staff.get("gear",""),{})
		if info.get("type","")=="staff" and staff.get("unlocked",true) and not staff.get("ivory_graft",false) and not staff.get("ragged_sealed",false):
			out.append(i)
	return out


static func graft_ivory(d: Dictionary,index: int,staff_index: int) -> bool:
	if not ivory_staff_choices(d,index).has(staff_index):
		return false
	d["loot"][staff_index]["ivory_graft"]=true
	d["gold"]=int(d["gold"])-500
	d["loot"].remove_at(index)
	return true
