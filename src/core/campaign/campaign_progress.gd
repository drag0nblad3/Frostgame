class_name CampaignProgress
extends RefCounted
## Versioned, JSON-safe between-game progression. No active battle save yet.
const PATH := "user://frostgame_campaign_v1.json"
var data: Dictionary = {}


func start(roster: Dictionary) -> void:
	data = {"version": 1, "name": roster["name"], "school": roster.get("school", "elementalist"), "spells": roster.get("spells", {}).duplicate(true), "gold": int(roster.get("gold", 0)), "xp": 0, "level": 0, "games": 0, "units": [], "loot": [], "last_report": [], "spell_improved": false, "stat_improved": false, "advances": {}, "base": ""}
	for entry: Dictionary in roster["figures"]:
		data["units"].append({"type": entry["type"], "id": data["units"].size(), "miss": 0, "injuries": 0, "dead": false})


func deployment() -> Dictionary:
	var units: Array = []
	for unit: Dictionary in data["units"]:
		if unit["dead"] or unit.get("dismissed", false) or int(unit["miss"]) > 0:
			continue
		var entry := {"type": unit["type"], "campaign_id": unit["id"], "at": [4.5 + 3.0 * units.size(), 3.0]}
		if unit["type"] in ["wizard", "apprentice"]:
			entry["stat_bonus"] = data.get("advances", {}).duplicate()
		elif data.get("base", "") == "brewery":
			entry["stat_bonus"] = {"will": 1}
		entry["items"] = CampaignInventory.loadout(data, int(unit["id"]))
		units.append(entry)
	return {"name": data["name"], "school": data["school"], "spells": data["spells"].duplicate(true), "figures": units}


func can_deploy() -> bool:
	for unit: Dictionary in data.get("units", []):
		if unit["type"] == "wizard" and not unit["dead"]:
			return not deployment()["figures"].is_empty()
	return false


func settle(c: GameController, dice: Dice, side: int = 0) -> bool:
	if data.is_empty() or not c.state.over:
		return false
	CampaignInventory.settle(data, c, side)
	var report: Array[String] = []
	var xp := 0
	var kills := 0
	for f in c.state.figures:
		if f.side == side and f.def.role == "wizard":
			xp += 40
	for event in c.history:
		var e := event.data
		if event.type == "cast_result":
			var caster := c.state.figure(e["id"])
			if caster.side == side:
				if e["success"] and int(e.get("tn", 7)) > 6:
					xp += 10
				elif not e["success"] and int(e.get("failure_damage", 0)) > 0:
					xp += 5
		elif event.type == "out_of_action":
			var victim := c.state.figure(e["id"])
			var attacker := c.state.figure(e["by"])
			if victim.side < 0 and attacker.side == side:
				kills += 1
	var secured := c.state.secured_count(side)
	xp = mini(300, xp + secured * 40 + mini(kills * 5, 50))
	data["xp"] = int(data["xp"]) + xp
	data["games"] = int(data["games"]) + 1
	data["spell_improved"] = false
	data["stat_improved"] = false
	report.append("Battle %d: %d treasure, +%d XP." % [data["games"], secured, xp])
	# Recover previously resting units after missing this game.
	for unit: Dictionary in data["units"]:
		unit["miss"] = maxi(0, int(unit["miss"]) - 1)
	for f in c.state.figures:
		if f.original_side != side or f.campaign_id < 0 or not f.out_of_action:
			continue
		for unit: Dictionary in data["units"]:
			if int(unit["id"]) != f.campaign_id:
				continue
			var raw := dice.d20()
			var caster := f.def.role in ["wizard", "apprentice"]
			var roll := raw + (1 if f.def.role == "wizard" else 0)
			var outcome := "recovered"
			if roll <= (2 if caster else 4):
				unit["dead"] = true
				CampaignInventory.lose_owned(data, f.campaign_id)
				outcome = "died"
			elif caster and roll <= 4:
				unit["injuries"] = int(unit["injuries"]) + 1
				outcome = "permanent injury (detail pending)"
			elif roll <= (6 if caster else 8):
				unit["miss"] = 1
				outcome = "misses next battle"
			elif caster and roll <= 8:
				CampaignInventory.lose_owned(data, f.campaign_id)
				outcome = "close call; carried items lost"
			report.append("%s #%d: rolled %d, %s." % [f.label(), f.campaign_id + 1, raw, outcome])
			break
	for i in secured:
		var loot := treasure(dice)
		data["gold"] = int(data["gold"]) + int(loot["gold"])
		if loot["kind"] == "grimoire":
			loot["spell"] = random_spell(dice)
		CampaignInventory.identify(data, loot, dice)
		report.append("Treasure %d: %d gc%s." % [i + 1, loot["gold"], ", " + str(loot["kind"]) if loot["kind"] != "" else ""])
	match str(data.get("base", "")):
		"laboratory":
			data["xp"] = int(data["xp"]) + 20
			report.append("Laboratory: +20 XP.")
		"brewery":
			data["gold"] = int(data["gold"]) + 20
			report.append("Brewery: +20 gc.")
		"treasury":
			var roll := dice.d20()
			if roll >= 19:
				var bonus := treasure(dice)
				data["gold"] = int(data["gold"]) + int(bonus["gold"])
				if bonus["kind"] == "grimoire":
					bonus["spell"] = random_spell(dice)
				CampaignInventory.identify(data, bonus, dice)
				report.append("Treasury: extra treasure, %d gc." % bonus["gold"])
			elif roll >= 2:
				var gold := roll + (100 if roll >= 17 else 0)
				data["gold"] = int(data["gold"]) + gold
				report.append("Treasury: +%d gc." % gold)
	data["last_report"] = report
	return true


static func treasure(dice: Dice) -> Dictionary:
	var roll := dice.d20()
	var golds := [50, 0, 0, 20, 40, 20, 40, 0, 20, 40, 0, 20, 40, 0, 20, 40, 60, 80, 100, 120]
	var kinds := ["", "", "", "3 potions", "2 potions", "1 scroll", "2 scrolls", "magic arms/armour", "magic arms/armour", "magic arms/armour", "magic item", "magic item", "magic item", "grimoire", "grimoire", "grimoire", "grimoire", "grimoire", "grimoire", "grimoire"]
	var gold: int = golds[roll - 1]
	if roll == 2 or roll == 3:
		gold = dice.d20() * (10 if roll == 2 else 20)
	return {"roll": roll, "gold": gold, "kind": kinds[roll - 1]}


func improve_spell(id: String) -> bool:
	if data.is_empty() or bool(data["spell_improved"]) or int(data["xp"]) < 100 or not data["spells"].has(id) or int(data["spells"][id]) <= 5:
		return false
	data["spells"][id] = int(data["spells"][id]) - 1
	data["xp"] = int(data["xp"]) - 100
	data["level"] = int(data["level"]) + 1
	data["spell_improved"] = true
	return true


func save(path: String = PATH) -> bool:
	if data.is_empty():
		return false
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	file.close()
	return DirAccess.rename_absolute(path + ".tmp", path) == OK


func load_save(path: String = PATH) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary or int(parsed.get("version", 0)) != 1:
		return false
	for key in ["name", "school", "spells", "gold", "xp", "level", "games", "units", "loot", "last_report", "spell_improved"]:
		if not parsed.has(key):
			return false
	data = parsed
	return true


const RANDOM_SPELLS := [["animate_skull","bones_of_the_earth","strike_dead","control_undead"],["curse","poison_dart","animal_companion","familiar"],["fleet_feet","slow","crumble","fast_act"],["leap","imp","plane_walk","control_demon"],["wall","call_storm","scatter_shot","destructive_sphere"],["push","draining_word","explosive_rune","write_scroll"],["teleport","invisibility","beauty","transpose"],["strength","telekinesis","enchant_armour","control_construct"],["awareness","true_sight","mind_lock","mind_control"],["shield","banish","blinding_light","miraculous_cure"],["bone_dart","spell_eater","steal_health","raise_zombie"],["mud","fog","control_animal","brew_potion"],["decay","time_store","petrify","time_walk"],["plague_of_insects","planar_tear","possess","summon_demon"],["elemental_bolt","elemental_ball","elemental_hammer","elemental_shield"],["furious_quill","absorb_knowledge","power_word","bridge"],["blink","fools_gold","glow","illusionary_soldier"],["enchant_weapon","grenade","embed_enchantment","animate_construct"],["combat_awareness","wizard_eye","suggestion","reveal_secret"],["circle_of_protection","heal","dispel","destroy_undead"]]
const BASES := ["brewery", "laboratory", "treasury"]
const STAT_CAPS := {"fight": 5, "shoot": 5, "will": 8, "health": 20}


static func random_spell(dice: Dice) -> String:
	var column := int(floorf((dice.d20() - 1) / 5.0))
	return RANDOM_SPELLS[dice.d20() - 1][column]


func choose_base(id: String) -> bool:
	if data.is_empty() or int(data["games"]) == 0 or not BASES.has(id):
		return false
	data["base"] = id
	return true


func can_improve_stat(id: String, db: FigureDb) -> bool:
	if data.is_empty() or not STAT_CAPS.has(id) or data.get("stat_improved", false) or int(data["xp"]) < 100:
		return false
	return int(db.get_def("wizard").get(id)) + int(data.get("advances", {}).get(id, 0)) < int(STAT_CAPS[id])


func improve_stat(id: String, db: FigureDb) -> bool:
	if not can_improve_stat(id, db):
		return false
	var advances: Dictionary = data.get("advances", {})
	advances[id] = int(advances.get(id, 0)) + 1
	data["advances"] = advances
	data["stat_improved"] = true
	data["xp"] = int(data["xp"]) - 100
	data["level"] = int(data["level"]) + 1
	return true


func learn_grimoire(index: int, db: FigureDb) -> bool:
	if data.is_empty() or int(data["xp"]) < 100 or index < 0 or index >= data["loot"].size():
		return false
	var item: Dictionary = data["loot"][index]
	var id: String = item.get("spell", "")
	if item["kind"] != "grimoire" or id == "" or data["spells"].has(id):
		return false
	var draft := WarbandDraft.new(db)
	draft.school = data["school"]
	if not draft.catalog.has(id):
		return false
	data["spells"][id] = draft.casting_number(id)
	data["xp"] = int(data["xp"]) - 100
	data["level"] = int(data["level"]) + 1
	data["loot"].remove_at(index)
	return true


func recruitment_cost(id: String, db: FigureDb) -> int:
	return 100 + 10 * int(data["level"]) if id == "apprentice" else db.get_def(id).cost


func can_hire(id: String, db: FigureDb) -> bool:
	if data.is_empty() or not db.figures.has(id) or int(data["gold"]) < recruitment_cost(id, db):
		return false
	var d := db.get_def(id)
	var soldiers := 0
	var specialists := 0
	for unit: Dictionary in data["units"]:
		if unit["dead"] or unit.get("dismissed", false):
			continue
		var other := db.get_def(unit["type"])
		if id == "apprentice" and other.role == "apprentice":
			return false
		if other.role == "soldier":
			soldiers += 1
			if other.specialist:
				specialists += 1
	return d.role == "apprentice" or (d.role == "soldier" and soldiers < 8 and (not d.specialist or specialists < 4))


func hire(id: String, db: FigureDb) -> bool:
	if not can_hire(id, db):
		return false
	data["gold"] = int(data["gold"]) - recruitment_cost(id, db)
	data["units"].append({"type": id, "id": data["units"].size(), "miss": 0, "injuries": 0, "dead": false})
	return true


func dismiss(index: int) -> bool:
	if data.is_empty() or index < 0 or index >= data["units"].size():
		return false
	var unit: Dictionary = data["units"][index]
	if unit["dead"] or unit["type"] == "wizard" or unit.get("dismissed", false):
		return false
	unit["dismissed"] = true
	for item: Dictionary in data["loot"]:
		if int(item.get("owner", -1)) == index:
			item["owner"] = -1
	return true


func treat(index: int) -> bool:
	if data.is_empty() or index < 0 or index >= data["units"].size():
		return false
	var unit: Dictionary = data["units"][index]
	if unit["dead"] or int(unit["miss"]) == 0 or unit["type"] not in ["wizard", "apprentice"] or unit.get("dismissed", false):
		return false
	var cost := 150
	for other: Dictionary in data["units"]:
		if other["type"] == "apothecary" and not other["dead"] and not other.get("dismissed", false):
			cost = 50
			break
	data["gold"] = int(data["gold"]) - cost
	unit["miss"] = 0
	return true
