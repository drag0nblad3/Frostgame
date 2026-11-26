class_name ScenarioLoader
extends RefCounted
## Builds a GameState from data/scenarios/<id>.json: a board id plus
## warbands, each a name and figures {"type", "at": [x, y]} in inches.

const DIR := "res://data/scenarios/"


static func load_id(scenario_id: String, figures: FigureDb, terrain: TerrainDb) -> GameState:
	return from_dict(JsonFile.read(DIR + scenario_id + ".json"), figures, terrain)


static func from_dict(d: Dictionary, figures: FigureDb, terrain: TerrainDb) -> GameState:
	var s := GameState.new()
	s.board = BoardLoader.load_id(d["board"], terrain)
	s.random_encounters = d.get("random_encounters", false)
	s.museum = d.get("museum", false)
	s.scenario_special = str(d.get("special", ""))
	if s.scenario_special == "dreams_well":
		for piece in s.board.pieces:
			if piece.kind.id == "dreams_well":
				piece.circular = true
	for at: Array in d.get("reinforcements", []):
		s.reinforcement_points.append(Vector2(at[0], at[1]))
	s.forced_combat = d.get("forced_combat", false)
	s.creature_db = figures
	s.content_profile=figures.content_profile
	s.spell_catalog = s.content_profile.filter("spells",JsonFile.read("res://data/spells.json"))
	var next_id := 1
	var warbands: Array = d.get("warbands", [])
	for side in warbands.size():
		var wb: Dictionary = warbands[side]
		s.side_names.append(wb.get("name", "Warband %d" % (side + 1)))
		var schools: Dictionary = JsonFile.read("res://data/schools.json")
		var school := str(wb.get("school", wb.get("name", ""))).to_lower()
		if schools.has(school):
			s.side_schools[side] = school
		s.spellbooks[side] = s.content_profile.filter("spells",wb.get("spells",{}))
		if wb.get("telescope", false):
			s.telescope_ready[side] = true
		var deploy_index := 0
		for entry: Dictionary in wb.get("figures", []):
			if RedKingMind.active(s) and (side!=0 or entry["type"]!="wizard"):
				continue
			var at: Array = [0.5,0.5] if RedKingMind.active(s) else entry["at"]
			if s.scenario_special == "underground_library":
				var position := Vector2(15.0 + float(deploy_index % 5) * 1.5, 1.5 + floori(deploy_index / 5.0) * 1.5)
				if side == 1:
					position.y = s.board.size.y - position.y
				at = [position.x, position.y]
			if RedKingVeil.active(s) and side==0:
				at=[2.0+float(deploy_index%8)*2.7,1.0+1.5*floori(deploy_index/8.0)]
			if RedKingFire.active(s):
				var x := 1.0+1.1*float(deploy_index%4)
				at=[x if side==0 else s.board.size.x-x,1.0+1.1*floori(deploy_index/4.0)]
			deploy_index += 1
			var def := figures.get_def(entry["type"])
			if entry.has("stat_bonus"):
				def = def.with_bonuses(entry["stat_bonus"])
			if entry.get("permanent_summon", false):
				def = def.with_bonuses({})
				def.role = "soldier"
				def.specialist = def.id == "large_construct"
			if CasterLoadout.is_caster(def.role) and entry.has("weapons"):
				def = CasterLoadout.definition(def, entry["weapons"], figures)
			var unit := Figure.new(next_id, def, side, Vector2(at[0], at[1]), figures.unarmed())
			if entry.get("prepared_zombie", false) or entry.get("prepared_illusion", false):
				unit.summon_spell = "raise_zombie" if entry.get("prepared_zombie", false) else "illusionary_soldier"
				for caster in s.figures:
					if caster.side == side and caster.def.role in ["wizard", "apprentice"]:
						unit.summoned_by = caster.id
						break
			if entry.has("prepared_demon"):
				var demon: Dictionary = entry["prepared_demon"]
				for caster in s.figures:
					if caster.side == side and caster.campaign_id == int(demon["caster"]):
						unit.prepared_demon_caster = caster.id
						unit.original_side = -1
						unit.controller_id = caster.id
						unit.summoned_by = caster.id
						unit.control_spell = "control_demon"
						unit.summon_spell = "summon_demon"
						unit.control_roll = int(demon["control_roll"])
						break
			if RedKingFire.active(s):
				unit.spell_effects["invisibility"]=true
			unit.campaign_base = str(entry.get("campaign_base", ""))
			unit.familiar = entry.get("familiar", false)
			if entry.get("awareness", false):
				unit.spell_effects["awareness"] = true
			unit.injury_types = entry.get("injury_types", {}).duplicate(true)
			unit.health = maxi(1, unit.health - int(entry.get("starting_loss", 0)))
			for item: Dictionary in entry.get("items", []):
				unit.items.append(item.duplicate(true))
			unit.campaign_id = int(entry.get("campaign_id", -1))
			unit.elevation = s.board.height_at(unit.pos)
			s.figures.append(unit)
			next_id += 1
	for entry: Dictionary in d.get("creatures", []):
		var at: Array = entry["at"]
		var creature := Figure.new(next_id, figures.get_def(entry["type"]), -1, Vector2(at[0], at[1]), figures.unarmed())
		creature.elevation = s.board.height_at(creature.pos)
		s.figures.append(creature)
		next_id += 1
	for at: Array in d.get("treasures", []):
		var token := TreasureToken.new(s.treasures.size(), Vector2(at[0], at[1]))
		token.central = token.id == int(d.get("central_treasure", -1 if s.museum or not s.reinforcement_points.is_empty() else 0))
		token.frozen = (s.scenario_special == "underground_library" and token.central) or s.scenario_special == "complex_temple" or (RedKingFire.active(s) and token.central)
		s.treasures.append(token)
	for at: Array in d.get("investigation_stands",[]):
		var stand := TreasureToken.new(s.treasures.size(),Vector2(at[0],at[1]))
		stand.central=false
		stand.investigation=true
		s.treasures.append(stand)
	if RedKingMadMan.active(s):
		# Keep a reserved hidden objective ID so UI and checkpoint token maps
		# remain stable when Ryce becomes unconscious.
		var rescue := TreasureToken.new(s.treasures.size(),s.board.size*0.5)
		rescue.central=false
		rescue.lost=true
		s.treasures.append(rescue)
		s.scenario_data["ryce_token"]=rescue.id
		s.scenario_data["crack_clock"]=1
		s.scenario_data["hunters_deployed"]=false
		for npc in s.figures:
			if RedKingMadMan.is_ryce(npc):
				s.scenario_data["ryce_id"]=npc.id
				break
		for side in warbands.size():
			if warbands[side].get("red_king_artefact_recovered",false):
				s.scenario_data["reduced_hunters_%d"%side]=true
	return s
