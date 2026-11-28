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
	s.scenario_data["reality_enabled"]=bool(d.get("reality_cracks",false))
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
	s.wounded_rules=bool(d.get("wounded_rules",false)) or (not warbands.is_empty() and bool(warbands[0].get("wounded_rules",false)))
	for side in warbands.size():
		var wb: Dictionary = warbands[side]
		s.side_names.append(wb.get("name", "Warband %d" % (side + 1)))
		var schools: Dictionary = JsonFile.read("res://data/schools.json")
		var school := str(wb.get("school", wb.get("name", ""))).to_lower()
		if schools.has(school):
			s.side_schools[side] = school
		s.spellbooks[side] = s.content_profile.filter("spells",wb.get("spells",{}))
		if wb.get("red_king_secret_hrut",false) and s.content_profile.enabled.has("red_king"):
			s.scenario_data["secret_hrut_%d"%side]=true
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
			if RedKingRingworld.active(s):
				var offsets: Array[Vector2]=[Vector2.ZERO,Vector2(1,0),Vector2(-1,0),Vector2(0,1),Vector2(0,-1),Vector2(1,1),Vector2(-1,1),Vector2(1,-1),Vector2(-1,-1),Vector2(0,2)]
				var p := Vector2(8.0 if side==0 else 22.0,18.0)+offsets[deploy_index%offsets.size()]
				at=[p.x,p.y]
			if RedKingBridge.active(s):
				var p := RedKingBridge.deployment(s,side,deploy_index)
				at=[p.x,p.y]
			if RedKingHerded.active(s):
				var x := 1.0+1.2*float(deploy_index%4)
				at=[x if side==0 else s.board.size.x-x,1.0+1.2*floori(deploy_index/4.0)]
			# Generated scenario formations must be legal movement nodes.
			# Keep the authored region and nearest half-inch position.
			if not s.board.floor_layout.is_empty() and (RedKingVeil.active(s) or RedKingHerded.active(s) or RedKingFire.active(s)):
				var snapped:=MoveGrid.to_pos(MovePlanner.node_at(Vector2(at[0],at[1])))
				at=[snapped.x,snapped.y]
			deploy_index += 1
			if wb.get("campaign_roster",false) and (s.scenario_special.begins_with("red_king_") or not s.board.floor_layout.is_empty()) and not RedKingMind.active(s):
				var repaired: Variant=CampaignDeployment.find(s,Vector2(at[0],at[1]),side,d)
				if repaired==null:
					s.scenario_data["deployment_error"]="No legal starting position for "+str(entry["type"])+". Reduce the deployed roster."
				else:
					at=[repaired.x,repaired.y]
			var def := figures.get_def(entry["type"])
			if entry.has("stat_bonus"):
				def = def.with_bonuses(entry["stat_bonus"])
			if entry.get("permanent_summon", false):
				def = def.with_bonuses({})
				def.role = "soldier"
				def.specialist = bool(entry.get("specialist",def.id in ["large_construct","foulhorn"]))
			if CasterLoadout.is_caster(def.role) and entry.has("weapons"):
				def = CasterLoadout.definition(def, entry["weapons"], figures)
			var unit := Figure.new(next_id, def, side, Vector2(at[0], at[1]), figures.unarmed())
			if entry.get("prepared_zombie", false) or entry.get("prepared_illusion", false):
				unit.summon_spell = "raise_zombie" if entry.get("prepared_zombie", false) else "illusionary_soldier"
				for caster in s.figures:
					if caster.side == side and caster.def.role in ["wizard", "apprentice"] and (int(entry.get("prepared_zombie_caster",entry.get("prepared_illusion_caster",-1)))<0 or caster.campaign_id==int(entry.get("prepared_zombie_caster",entry.get("prepared_illusion_caster",-1)))):
						unit.summoned_by = caster.id
						break
				if entry.get("prepared_zombie_strong",false):
					unit.used_gear["rk_skull_strong"]=true
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
			assign_support(s,unit,str(entry.get("surface",at[2] if at.size()>2 else "")))
			s.figures.append(unit)
			next_id += 1
	for entry: Dictionary in d.get("creatures", []):
		var at: Array = entry["at"]
		var creature := Figure.new(next_id, figures.get_def(entry["type"]), -1, Vector2(at[0], at[1]), figures.unarmed())
		assign_support(s,creature,str(entry.get("surface",at[2] if at.size()>2 else "")))
		creature.ring_side=int(entry.get("ring_side",0))
		s.figures.append(creature)
		next_id += 1
	for at: Array in d.get("treasures", []):
		var token := TreasureToken.new(s.treasures.size(), Vector2(at[0], at[1]))
		token.central = token.id == int(d.get("central_treasure", -1 if s.museum or not s.reinforcement_points.is_empty() else 0))
		token.frozen = (s.scenario_special == "underground_library" and token.central) or s.scenario_special == "complex_temple" or (RedKingFire.active(s) and token.central)
		assign_token_support(s,token,str(at[2]) if at.size()>2 else "")
		s.treasures.append(token)
	for at: Array in d.get("investigation_stands",[]):
		var stand := TreasureToken.new(s.treasures.size(),Vector2(at[0],at[1]))
		stand.central=false
		stand.investigation=true
		assign_token_support(s,stand,str(at[2]) if at.size()>2 else "")
		s.treasures.append(stand)
	if RedKingRingworld.active(s):
		RedKingRingworld.setup(s)
	if RedKingTethers.active(s):
		RedKingTethers.setup(s)
	if RedKingHerded.active(s):
		s.board.darkness=true
		RedKingHerded.setup(s)
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


static func assign_support(s: GameState,f: Figure,id: String="") -> void:
	if s.board.floor_layout.is_empty():
		f.elevation=s.board.height_at(f.pos)
		return
	var n: Variant=BattlePlacement.support(s,f.pos,id)
	if n==null:
		_report_support_error(s,f.label(),f.pos,id)
		return
	var layout:=s.board.floor_geometry()
	f.surface_id=layout.surface_id(n)
	f.elevation=layout.height(n)


static func assign_token_support(s: GameState,t: TreasureToken,id: String="") -> void:
	if s.board.floor_layout.is_empty():
		return
	var support:=BattlePlacement.authored_token_surface(s,t.pos,id)
	if support.is_empty():
		# Mausoleum corner tokens intentionally touch the masonry (core p.142).
		# Their circular footprint may overlap our conservative square proxy.
		if s.board.id=="mausoleum" and t.id<4 and (id.is_empty() or id=="street"):
			for p in s.board.pieces:
				if p.kind.id!="ruin" or not p.rect.has_point(s.board.size*0.5) or p.rect.has_point(t.pos):
					continue
				for corner: Vector2 in [p.rect.position,p.rect.end,Vector2(p.rect.position.x,p.rect.end.y),Vector2(p.rect.end.x,p.rect.position.y)]:
					if corner.distance_to(t.pos)<=TreasureRules.TOKEN_RADIUS+0.001:
						t.surface_id="street"
						return
		# Frozen temple treasures are intentionally inside their guardian column.
		if t.frozen and s.scenario_special=="complex_temple":
			for p in s.board.pieces:
				if p.kind.id=="temple_column" and p.rect.get_center().distance_to(t.pos)<0.01 and (id.is_empty() or p.surface_id==id):
					t.surface_id=p.surface_id
					return
		_report_support_error(s,"Treasure "+str(t.id),t.pos,id)
		return
	t.surface_id=support


static func _report_support_error(s: GameState,label: String,at: Vector2,id: String) -> void:
	var errors: Array=s.scenario_data.get("support_errors",[])
	errors.append("%s at %s on '%s' has no legal support."%[label,str(at),id])
	s.scenario_data["support_errors"]=errors
	s.scenario_data["deployment_error"]="; ".join(errors)
