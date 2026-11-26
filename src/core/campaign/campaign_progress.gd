class_name CampaignProgress
extends RefCounted
## Versioned, JSON-safe between-game progression. No active battle save yet.
const PATH := "user://frostgame_campaign_v1.json"
var data: Dictionary = {}


func start(roster: Dictionary,profile: ContentProfile=null) -> void:
	data = {"version": 1, "name": roster["name"], "school": roster.get("school", "elementalist"), "spells": roster.get("spells", {}).duplicate(true), "gold": int(roster.get("gold", 0)), "xp": 0, "level": 0, "games": 0, "units": [], "loot": [], "last_report": [], "spell_improved": false, "stat_improved": false, "advances": {}, "base": ""}
	if profile!=null:
		data["expansions"]=profile.enabled.duplicate()
	for entry: Dictionary in roster["figures"]:
		var unit := {"type": entry["type"], "id": data["units"].size(), "miss": 0, "injuries": 0, "dead": false}
		if entry.has("weapons"):
			unit["weapons"] = entry["weapons"].duplicate()
		data["units"].append(unit)


func deployment() -> Dictionary:
	var units: Array = []
	var ragged := RaggedWarbands.active(data)
	var reserve := -1 if ragged else BaseResources.reserve_id(data, FigureDb.load_files())
	for unit: Dictionary in data["units"]:
		if unit["dead"] or unit.get("dismissed", false) or (ragged and unit.get("ragged_absent",false)) or int(unit["miss"]) > 0 or InjuryRules.blind(unit) or int(unit["id"]) == reserve:
			continue
		var entry := {"type": unit["type"], "campaign_id": unit["id"], "at": [4.5 + 3.0 * units.size(), 3.0]}
		if unit["type"] in ["wizard", "apprentice"]:
			entry["stat_bonus"] = data.get("advances", {}).duplicate()
		elif not ragged and data.get("base", "") == "brewery":
			entry["stat_bonus"] = {"will": 1}
		var bonuses := InjuryRules.bonuses(unit, entry.get("stat_bonus", {}))
		entry["injury_types"] = unit.get("injury_types", {}).duplicate(true)
		entry["starting_loss"] = InjuryRules.starting_loss(unit)
		entry["campaign_base"] = "" if ragged else data.get("base", "")
		entry["familiar"] = unit.get("familiar", false)
		entry["awareness"] = unit.get("awareness", false)
		if unit.get("familiar", false):
			bonuses["health"] = int(bonuses.get("health", 0)) + 2
		if unit.has("companion_of"):
			bonuses["will"] = int(bonuses.get("will", 0)) + 3
		if unit.get("construct_oiled", false):
			bonuses["move"] = int(bonuses.get("move", 0)) + 1
		for stat: String in unit.get("ragged_bonuses",{}):
			bonuses[stat]=int(bonuses.get(stat,0))+int(unit["ragged_bonuses"][stat])
		entry["stat_bonus"] = bonuses
		entry["permanent_summon"] = unit.get("permanent_summon", false)
		entry["items"] = CampaignInventory.loadout(data, int(unit["id"]))
		if CasterLoadout.is_caster(unit["type"]):
			entry["weapons"] = CasterLoadout.carried(data, unit)["weapons"]
		units.append(entry)
	if data.get("prepared_zombie", false):
		units.append({"type": "zombie", "at": [4.5 + 3.0 * units.size(), 3.0], "prepared_zombie": true})
	if str(data.get("prepared_illusion", "")) != "":
		units.append({"type": data["prepared_illusion"], "at": [4.5 + 3.0 * units.size(), 3.0], "prepared_illusion": true})
	var demon: Dictionary = data.get("prepared_demon", {})
	if not demon.is_empty():
		for entry: Dictionary in units:
			if int(entry.get("campaign_id", -1)) == int(demon["caster"]):
				units.append({"type": demon["type"], "at": [0, 0], "prepared_demon": demon.duplicate(true)})
				break
	# Two deployment ranks prevent extra prepared figures from exceeding the table.
	for i in units.size():
		units[i]["at"] = [4.5 + 3.0 * (i % 10), 3.0 + 1.5 * floori(i / 10.0)]
	return {"name": data["name"], "school": data["school"], "spells": data["spells"].duplicate(true), "figures": units, "telescope": BaseResources.owns(data, "celestial_telescope")}


func can_deploy() -> bool:
	if not data.get("pending_treasure", []).is_empty():
		return false
	if RaggedWarbands.active(data) and RaggedWarbands.has_unassigned(data):
		return false
	for unit: Dictionary in data.get("units", []):
		if unit["type"] == "wizard" and not unit["dead"] and not InjuryRules.blind(unit):
			return not deployment()["figures"].is_empty()
	return false


func settle(c: GameController, dice: Dice, side: int = 0) -> bool:
	if data.is_empty() or not c.state.over or not data.get("pending_treasure", []).is_empty():
		return false
	if RedKingMind.active(c.state):
		return RedKingMindRewards.settle(data,c,side)
	CampaignInventory.settle(data, c, side)
	var report: Array[String] = []
	var xp := 0
	var kills := 0
	var hrut_xp := 0
	var scenario_xp := 0
	var worm_hurt := false
	for f in c.state.figures:
		if f.side == side and f.def.role == "wizard":
			xp += 40
	for event in c.history:
		var e := event.data
		if event.type == "cast_result":
			var caster := c.state.figure(e["id"])
			if caster.side == side and not e.get("scroll", false):
				if e["success"] and int(e.get("tn", 7)) > 6:
					xp += 10
				elif not e["success"] and int(e.get("failure_damage", 0)) > 0:
					xp += 5
		elif event.type in ["well_drink", "hut_discovered", "disc_transport", "genie_released", "tower_entered", "column_fight", "squatter_xp", "investigation_xp", "mad_man_xp"] and int(e["side"]) == side:
			scenario_xp += int(e["xp"])
		elif event.type == "damage" and c.state.scenario_special == "worm_hunts":
			var victim := c.state.figure(e["id"])
			var attacker := c.state.figure(e["by"])
			if victim != null and attacker != null and victim.def.id == "giant_worm" and attacker.original_side == side and not worm_hurt:
				worm_hurt = true
				scenario_xp += 20
		elif event.type == "out_of_action":
			var victim := c.state.figure(e["id"])
			var attacker := c.state.figure(e["by"])
			if RedKingMadMan.active(c.state) and victim!=null and attacker!=null and victim.original_side!=side and attacker.side==side and victim.def.id.begins_with("hrut_"):
				hrut_xp=mini(50,hrut_xp+10)
				continue
			if victim != null and attacker != null and victim.side < 0 and attacker.side == side and not RedKingMadMan.is_ryce(victim):
				var bounty := 20 if victim.def.traits.has("bounty_20") else (10 if victim.def.traits.has("bounty_10") else 0)
				if bounty > 0:
					data["gold"] = int(data["gold"]) + bounty
					report.append("%s bounty: %d gc." % [victim.label(), bounty])
				if c.state.scenario_special == "worm_hunts" and victim.def.id == "giant_worm":
					scenario_xp += 50
				elif c.state.scenario_special == "genie_in_the_bottle" and victim.def.id == "genie":
					scenario_xp += 50
				elif c.state.museum and victim.def.id == "medium_construct":
					scenario_xp += 10
				elif RedKingFire.active(c.state) and victim.def.id=="hrut_warrior":
					scenario_xp+=10
				elif RedKingFire.active(c.state) and victim.def.id=="blood_marked_berserker":
					scenario_xp+=5
				elif not (RedKingInvestigations.active(c.state) and victim.def.id=="blood_marked_berserker"):
					kills += 1
	scenario_xp+=hrut_xp
	var secured := c.state.secured_count(side)
	if RedKingMadMan.active(c.state):
		var rescue := c.state.treasure(int(c.state.scenario_data.get("ryce_token",-1)))
		data["red_king_secured_kalamon"]=rescue!=null and rescue.secured_by==side
		if data["red_king_secured_kalamon"]:
			secured-=1
	var treasure_xp := secured*40
	if RedKingFire.active(c.state):
		treasure_xp=0
		for token in c.state.treasures:
			if token.secured_by==side:
				treasure_xp+=60 if token.central else 20
		for f in c.state.figures:
			if f.original_side==side and not f.out_of_action:
				scenario_xp+=5
	xp = maxi(0, mini(300, xp + treasure_xp + mini(kills * 5, 50) + scenario_xp) + int(data.get("dreams_xp", 0)))
	if RedKingVeil.active(c.state):
		xp=RedKingVeil.xp(c,side)
	if RedKingHerded.active(c.state):
		xp+=RedKingHerded.exit_xp(c.state,side)
	data.erase("dreams_xp")
	data["xp"] = int(data["xp"]) + xp
	data["games"] = int(data["games"]) + 1
	data["spell_improved"] = false
	data["stat_improved"] = false
	data["ritual_attempts"] = {}
	data["preparation_started"] = false
	data["prepared_zombie"] = false
	data["prepared_illusion"] = ""
	data.erase("prepared_demon")
	for unit: Dictionary in data["units"]:
		unit["familiar"] = false
		unit["awareness"] = false
		unit["niggle_paid"] = false
		unit["last_knocked_out"] = false
	for f in c.state.figures:
		if f.original_side == side and f.campaign_id >= 0:
			data["units"][f.campaign_id]["last_knocked_out"] = f.out_of_action
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
			if RaggedWarbands.active(data) and not caster:
				RaggedWarbands.soldier_survival(unit,raw)
				report.append("%s #%d: %s."%[f.label(),f.campaign_id+1,"separated from the warband" if unit.get("ragged_absent",false) else "recovered"])
				break
			var roll := raw + (1 if f.def.role == "wizard" else 0)
			var outcome := "recovered"
			if roll <= (2 if caster else 4):
				unit["dead"] = true
				unit["death_game"] = data["games"]
				CampaignInventory.lose_owned(data, f.campaign_id)
				outcome = "died"
			elif caster and roll <= 4:
				outcome = "permanent injury: " + InjuryRules.roll(unit, dice)
			elif roll <= (6 if caster else 8):
				if f.def.role == "wizard" and BaseResources.owns(data, "sarcophagus_of_healing"):
					outcome = "recovered using the sarcophagus"
				else:
					unit["miss"] = 1
					outcome = "misses next battle"
			elif caster and roll <= 8:
				CampaignInventory.lose_owned(data, f.campaign_id)
				outcome = "close call; carried items lost"
			report.append("%s #%d: rolled %d, %s." % [f.label(), f.campaign_id + 1, raw, outcome])
			break
	EnchantmentRewards.capture(data, c, side)
	var secrets := int(data.get("revealed_secrets", 0))
	data["revealed_secrets"] = 0
	data["pending_treasure"] = []
	# Central treasure gets its own optional reroll, not a Reveal Secret choice.
	var recovered: Array[TreasureToken] = []
	for token in c.state.treasures:
		if token.secured_by == side and token.central:
			recovered.append(token)
	for token in c.state.treasures:
		if token.secured_by == side and not token.central:
			recovered.append(token)
	for token in recovered:
		if RedKingMadMan.rescue(c.state,token):
			report.append("Kalamon Ryce rescued: eligible for the optional solo encounter.")
			continue
		if RedKingFire.active(c.state) and token.central:
			data["red_king_artefact_recovered"]=true
		if token.bonus_gold>0:
			data["gold"]=int(data["gold"])+token.bonus_gold
			report.append("Recovered offering: +%d gc."%token.bonus_gold)
		if c.state.scenario_special == "genie_in_the_bottle" and token.id == c.state.lamp_token:
			data["gold"] = int(data["gold"]) + 250
			report.append("Recovered the genie lamp: 250 gc.")
			continue
		var raw := dice.d20()
		if c.state.scenario_special == "underground_library":
			if token.central:
				data["loot"].append({"kind": "scroll", "scroll": random_spell(dice), "owner": -1})
				report.append("Library central treasure: extra scroll.")
			else:
				raw = ScenarioObjectives.library_roll(raw, dice)
		if token.central:
			data["pending_treasure"].append({"token": token.id, "first": raw, "second": 0, "central": true})
		elif secrets > 0:
			var second := dice.d20()
			if c.state.scenario_special == "underground_library":
				second = ScenarioObjectives.library_roll(second, dice)
			data["pending_treasure"].append({"token": token.id, "first": raw, "second": second, "central": false})
			secrets -= 1
		else:
			_award_treasure(raw, dice, report, token.id)
	match ("" if RaggedWarbands.active(data) else str(data.get("base", ""))):
		"temple":
			if dice.d20() >= 16:
				data["loot"].append({"kind": "potion", "potion": "healing", "owner": -1})
				report.append("Temple: free Potion of Healing.")
		"library":
			var roll := dice.d20()
			if roll >= 15:
				var spell := random_spell(dice)
				if roll >= 19:
					data["loot"].append({"kind": "grimoire", "spell": spell})
					report.append("Library: discovered a grimoire of " + spell.replace("_", " ").capitalize() + ".")
				else:
					data["loot"].append({"kind": "scroll", "scroll": spell, "owner": -1})
					report.append("Library: discovered a scroll of " + spell.replace("_", " ").capitalize() + ".")
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
	return treasure_result(dice.d20(), dice)


static func treasure_result(roll: int, dice: Dice) -> Dictionary:
	var golds := [50, 0, 0, 20, 40, 20, 40, 0, 20, 40, 0, 20, 40, 0, 20, 40, 60, 80, 100, 120]
	var kinds := ["", "", "", "3 potions", "2 potions", "1 scroll", "2 scrolls", "magic arms/armour", "magic arms/armour", "magic arms/armour", "magic item", "magic item", "magic item", "grimoire", "grimoire", "grimoire", "grimoire", "grimoire", "grimoire", "grimoire"]
	var gold: int = golds[roll - 1]
	if roll == 2 or roll == 3:
		gold = dice.d20() * (10 if roll == 2 else 20)
	return {"roll": roll, "gold": gold, "kind": kinds[roll - 1]}


func improve_spell(id: String) -> bool:
	if not CampaignSuccession.living_wizard(data) or bool(data["spell_improved"]) or int(data["xp"]) < 100 or not data["spells"].has(id) or int(data["spells"][id]) <= 5:
		return false
	data["spells"][id] = int(data["spells"][id]) - 1
	data["xp"] = int(data["xp"]) - 100
	data["level"] = int(data["level"]) + 1
	data["spell_improved"] = true
	return true


func save(path: String = "") -> bool:
	if path.is_empty():
		path=WarbandSlots.path_for(PATH)
	if data.is_empty():
		return false
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	file.close()
	return DirAccess.rename_absolute(path + ".tmp", path) == OK


func load_save(path: String = "") -> bool:
	if path.is_empty():
		path=WarbandSlots.path_for(PATH)
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
const BASES := ["brewery", "laboratory", "treasury", "temple", "crypt", "tower", "library", "inn"]
const STAT_CAPS := {"fight": 5, "shoot": 5, "will": 8, "health": 20}


static func random_spell(dice: Dice) -> String:
	var column := int(floorf((dice.d20() - 1) / 5.0))
	return RANDOM_SPELLS[dice.d20() - 1][column]


func choose_base(id: String) -> bool:
	if RaggedWarbands.active(data) or data.is_empty() or int(data["games"]) == 0 or not BASES.has(id) or not ContentProfile.from_campaign(data).allows("bases",id):
		return false
	if id == data.get("base", ""):
		return true
	var proposed := data.duplicate(true)
	proposed["base"] = id
	proposed["resources"] = []
	if not BaseResources.fits(proposed, FigureDb.load_files()):
		return false
	data["base"] = id
	data["resources"] = []
	data.erase("reserve_id")
	data.erase("prepared_demon")
	return true


func can_improve_stat(id: String, db: FigureDb) -> bool:
	if not CampaignSuccession.living_wizard(data) or not STAT_CAPS.has(id) or data.get("stat_improved", false) or int(data["xp"]) < 100:
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
	if not CampaignSuccession.living_wizard(data) or int(data["xp"]) < 100 or index < 0 or index >= data["loot"].size():
		return false
	var item: Dictionary = data["loot"][index]
	var id: String = item.get("spell", "")
	if item["kind"] != "grimoire" or id == "" or data["spells"].has(id) or not ContentProfile.from_campaign(data).allows("spells",id):
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
	if id == "apprentice":
		return 100 + 10 * int(data["level"])
	var discount := 10 if BaseResources.owns(data, "carrier_pigeons") else 0
	return maxi(0, db.get_def(id).cost - discount)


func can_hire(id: String, db: FigureDb) -> bool:
	if RaggedWarbands.active(data):
		return false
	if not CampaignSuccession.living_wizard(data) or not db.available(id) or not ContentProfile.from_campaign(data).allows("figures",id) or int(data["gold"]) < recruitment_cost(id, db):
		return false
	var d := db.get_def(id)
	for unit: Dictionary in data["units"]:
		if id == "apprentice" and unit["type"] == "apprentice" and CampaignPotions.preserved(data, unit):
			return false
		if unit["dead"] or unit.get("dismissed", false):
			continue
		var other := db.get_def(unit["type"])
		if id == "apprentice" and other.role == "apprentice":
			return false
	return d.role == "apprentice" or (d.role == "soldier" and BaseResources.fits(data, db, id))


func hire(id: String, db: FigureDb) -> bool:
	if not can_hire(id, db):
		return false
	data["gold"] = int(data["gold"]) - recruitment_cost(id, db)
	data["units"].append({"type": id, "id": data["units"].size(), "miss": 0, "injuries": 0, "dead": false})
	return true


func dismiss(index: int) -> bool:
	if RaggedWarbands.active(data) or data.is_empty() or index < 0 or index >= data["units"].size():
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
	if RaggedWarbands.active(data) or data.is_empty() or index < 0 or index >= data["units"].size():
		return false
	var unit: Dictionary = data["units"][index]
	if unit["dead"] or int(unit["miss"]) == 0 or unit["type"] not in ["wizard", "apprentice"] or unit.get("dismissed", false):
		return false
	var cost := 150
	for other: Dictionary in data["units"]:
		if other["type"] == "apothecary" and not other["dead"] and not other.get("dismissed", false):
			cost = 50
			break
	if unit["type"] == "wizard" and BaseResources.owns(data, "sarcophagus_of_healing"):
		cost = 0
	data["gold"] = int(data["gold"]) - cost
	unit["miss"] = 0
	return true


func _award_treasure(raw: int, dice: Dice, report: Array, token: int) -> void:
	var loot := treasure_result(raw, dice)
	data["gold"] = int(data["gold"]) + int(loot["gold"])
	if loot["kind"] == "grimoire":
		loot["spell"] = random_spell(dice)
	CampaignInventory.identify(data, loot, dice)
	report.append("Treasure %d: %d gc%s." % [token + 1, loot["gold"], ", " + str(loot["kind"]) if loot["kind"] != "" else ""])


func resolve_treasure(second: bool, dice: Dice) -> bool:
	var pending: Array = data.get("pending_treasure", [])
	if pending.is_empty():
		return false
	var entry: Dictionary = pending.pop_front()
	var roll := int(entry["first"])
	if second:
		roll = dice.d20() if entry["central"] else int(entry["second"])
	_award_treasure(roll, dice, data["last_report"], int(entry["token"]))
	return true


static func treasure_label(roll: int) -> String:
	var labels := ["50 gc", "d20 × 10 gc", "d20 × 20 gc", "20 gc + 3 potions", "40 gc + 2 potions", "20 gc + scroll", "40 gc + 2 scrolls", "Magic weapon/armour", "20 gc + magic weapon/armour", "40 gc + magic weapon/armour", "Magic item", "20 gc + magic item", "40 gc + magic item", "Grimoire", "20 gc + grimoire", "40 gc + grimoire", "60 gc + grimoire", "80 gc + grimoire", "100 gc + grimoire", "120 gc + grimoire"]
	return labels[roll - 1]
