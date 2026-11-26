class_name CampaignProgress
extends RefCounted
## Versioned, JSON-safe between-game progression. No active battle save yet.
const PATH := "user://frostgame_campaign_v1.json"
var data: Dictionary = {}


func start(roster: Dictionary) -> void:
	data = {"version": 1, "name": roster["name"], "school": roster.get("school", "elementalist"), "spells": roster.get("spells", {}).duplicate(true), "gold": int(roster.get("gold", 0)), "xp": 0, "level": 0, "games": 0, "units": [], "loot": [], "last_report": [], "spell_improved": false}
	for entry: Dictionary in roster["figures"]:
		data["units"].append({"type": entry["type"], "id": data["units"].size(), "miss": 0, "injuries": 0, "dead": false})


func deployment() -> Dictionary:
	var units: Array = []
	for unit: Dictionary in data["units"]:
		if unit["dead"] or int(unit["miss"]) > 0:
			continue
		units.append({"type": unit["type"], "campaign_id": unit["id"], "at": [4.5 + 3.0 * units.size(), 3.0]})
	return {"name": data["name"], "school": data["school"], "spells": data["spells"].duplicate(true), "figures": units}


func can_deploy() -> bool:
	for unit: Dictionary in data.get("units", []):
		if unit["type"] == "wizard" and not unit["dead"]:
			return not deployment()["figures"].is_empty()
	return false


func settle(c: GameController, dice: Dice, side: int = 0) -> bool:
	if data.is_empty() or not c.state.over:
		return false
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
	report.append("Battle %d: %d treasure, +%d XP." % [data["games"], secured, xp])
	# Recover previously resting units after missing this game.
	for unit: Dictionary in data["units"]:
		unit["miss"] = maxi(0, int(unit["miss"]) - 1)
	for f in c.state.figures:
		if f.side != side or f.campaign_id < 0 or not f.out_of_action:
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
				outcome = "died"
			elif caster and roll <= 4:
				unit["injuries"] = int(unit["injuries"]) + 1
				outcome = "permanent injury (detail pending)"
			elif roll <= (6 if caster else 8):
				unit["miss"] = 1
				outcome = "misses next battle"
			elif caster and roll <= 8:
				outcome = "close call"
			report.append("%s #%d: rolled %d, %s." % [f.label(), f.campaign_id + 1, raw, outcome])
			break
	for i in secured:
		var loot := treasure(dice)
		data["gold"] = int(data["gold"]) + int(loot["gold"])
		if loot["kind"] != "":
			data["loot"].append(loot)
		report.append("Treasure %d: %d gc%s." % [i + 1, loot["gold"], ", " + str(loot["kind"]) if loot["kind"] != "" else ""])
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
