extends SceneTree
## Full seeded bot-v-bot scenario run, separate from the quick unit suite.
## godot --headless -s tests/scenario_sim.gd -- silent_tower 17

var errors: Array[String] = []


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var id := args[0] if args.size() > 0 else "treasure_skirmish"
	var seed_value := int(args[1]) if args.size() > 1 else 17
	var roster:=args[2] if args.size()>2 else "authored"
	var profile := ContentProfile.new()
	if id.begins_with("red_king_"):
		profile=ContentProfile.new(["red_king"])
	var db := FigureDb.load_files(FigureDb.FIGURES,FigureDb.WEAPONS,profile)
	if not profile.errors().is_empty():
		printerr("FAIL ", "; ".join(profile.errors()))
		quit(1)
		return
	if id.begins_with("red_king_"):
		var source: Dictionary = JsonFile.read(ScenarioLoader.DIR+id+".json")
		for entry: Dictionary in source.get("creatures",[]):
			if not db.available(entry["type"]):
				printerr("FAIL unavailable creature ",entry["type"])
				quit(1)
				return
	var terrain := TerrainDb.load_file()
	var layered := id in ["stacked_gatehouse","layered_silent_tower"]
	var c: GameController
	if layered:
		c=LayeredBattle.create(db,terrain,seed_value,id)
	else:
		var data: Dictionary=JsonFile.read(ScenarioLoader.DIR+id+".json")
		if roster!="authored":
			_apply_roster(data,roster)
		c=GameController.new(ScenarioLoader.from_dict(data,db,terrain),Dice.new(seed_value))
		if not MausoleumSetup.prepare(c.state,c.dice) or not StandardTreasurePlacement.prepare(c.state,c.dice):
			printerr("FAIL scenario treasure placement")
			quit(1)
			return
		c.start_game()
	var s := c.state
	_validate(s, "deployment")
	var activations := 0
	var start := Time.get_ticks_msec()
	c.ai_profile_enabled=true
	var profile_totals: Dictionary={}
	var count_totals: Dictionary={}
	var behavior: Dictionary={"no_action_event":0,"reversals":0,"movements":0,"casts":0,"fights":0,"shots":0,"pickups":0}
	var previous_moves: Dictionary={}
	var samples: Array[float]=[]
	var slowest: Dictionary={}
	var peak:=0.0
	var open_start:=MoveGrid.evaluations+LayeredGrid.evaluations
	var edge_start:=LayeredGrid.edge_evaluations
	while not s.over and activations < 2000:
		var turn_before:=s.turn
		var phase_before:=str(s.phase)
		var event_start:=c.history.size()
		c.ai_profile.clear()
		var open_before:=MoveGrid.evaluations+LayeredGrid.evaluations
		var edges_before:=LayeredGrid.edge_evaluations
		var started:=Time.get_ticks_usec()
		var ok:=Bot.play_activation(c)
		var ms:=float(Time.get_ticks_usec()-started)/1000.0
		samples.append(ms)
		_observe_behavior(c.history.slice(event_start),behavior,previous_moves)
		var timings: Dictionary={}
		var counts_now: Dictionary={}
		for stage: String in c.ai_profile:
			if stage.begins_with("count_"):
				var key:=stage.trim_prefix("count_")
				counts_now[key]=c.ai_profile[stage]
				count_totals[key]=int(count_totals.get(key,0))+int(c.ai_profile[stage])
			else:
				timings[stage]=c.ai_profile[stage]
				profile_totals[stage]=int(profile_totals.get(stage,0))+int(c.ai_profile[stage])
		if ms>peak:
			peak=ms
			var types: Dictionary={}
			for index in range(event_start,c.history.size()):
				var event:=c.history[index]
				types[event.type]=int(types.get(event.type,0))+1
			slowest={"turn":turn_before,"phase":phase_before,"activation":activations+1,"events":types,"stage_usec":timings,"planning_counts":counts_now,"open_checks":MoveGrid.evaluations+LayeredGrid.evaluations-open_before,"edge_checks":LayeredGrid.edge_evaluations-edges_before}
		if not ok:
			errors.append("No legal bot activation at turn %d phase %s" % [s.turn, str(s.phase)])
			break
		activations += 1
		_validate(s, "activation %d" % activations)
		if not errors.is_empty():
			break
	if not s.over:
		errors.append("Game failed to finish within activation guard")
	var counts := {}
	for e in c.history:
		counts[e.type] = int(counts.get(e.type, 0)) + 1
	var scores: Array[int] = []
	for side in s.side_count():
		scores.append(s.secured_count(side))
	var elapsed:=Time.get_ticks_msec()-start
	var total:=0.0
	for ms in samples:
		total+=ms
	samples.sort()
	var performance: Dictionary={"mean_ms":total/maxf(1.0,samples.size()),"p95_ms":samples[mini(samples.size()-1,ceili(samples.size()*0.95)-1)] if not samples.is_empty() else 0.0,"max_ms":peak,"open_checks":MoveGrid.evaluations+LayeredGrid.evaluations-open_start,"edge_checks":LayeredGrid.edge_evaluations-edge_start,"slowest":slowest,"stage_total_usec":profile_totals,"planning_counts":count_totals}
	print("SCENARIO_PERFORMANCE|",JSON.stringify({"id":id,"seed":seed_value,"activations":activations,"roster":roster,"behavior":behavior,"performance":performance}))
	print("SCENARIO_RESULT|", JSON.stringify({"id": id, "seed": seed_value, "turn": s.turn, "activations": activations, "winner": s.winner, "scores": scores, "events": counts, "elapsed_ms": elapsed, "roster":roster,"behavior":behavior,"performance":performance, "errors": errors}))
	for msg in errors:
		printerr("FAIL ", msg)
	quit(0 if errors.is_empty() else 1)


func _validate(s: GameState, where: String) -> void:
	var live: Array[Figure] = []
	var layout: FloorLayout = null
	if not s.board.floor_layout.is_empty():
		layout=s.board.floor_geometry()
		if not layout.errors.is_empty():
			errors.append(where+": "+str(layout.errors))
			return
	for f in s.figures:
		if not f.in_play():
			continue
		live.append(f)
		if layout!=null:
			var n := layout.node(f.surface_id,f.pos)
			if not layout.standable(n) or not layout.point(n).is_equal_approx(f.pos):
				errors.append("%s: illegal layered position for figure %d" % [where,f.id])
			elif not is_equal_approx(f.elevation,layout.height(n)):
				errors.append("%s: stale floor elevation for figure %d" % [where,f.id])
		else:
			if not s.board.can_stand(f.pos, Figure.BASE_RADIUS):
				errors.append("%s: figure %d stands in illegal terrain at %s" % [where, f.id, str(f.pos)])
			if not is_equal_approx(f.elevation, s.board.height_at(f.pos)):
				errors.append("%s: figure %d has stale elevation" % [where, f.id])
	for i in live.size():
		for j in range(i + 1, live.size()):
			var a := live[i]
			var b := live[j]
			if a.ring_side==b.ring_side and absf(a.elevation - b.elevation) < 0.5 and a.pos.distance_to(b.pos) < Contact.OVERLAP - 0.01:
				errors.append("%s: figures %d and %d overlap" % [where, a.id, b.id])
	for t in s.treasures:
		if layout!=null and t.on_ground():
			var index := layout.index_of(t.surface_id)
			if index<0 or not layout.surfaces[index].contains(t.pos,TreasureRules.TOKEN_RADIUS):
				errors.append("%s: treasure %d has invalid floor" % [where,t.id])
		if t.carrier_id < 0:
			continue
		var f := s.figure(t.carrier_id)
		if f == null or not f.in_play() or not f.carried_treasures().has(t.id):
			errors.append("%s: treasure %d has invalid carrier" % [where, t.id])
	for f in live:
		for id in f.carried_treasures():
			var t := s.treasure(id)
			if t == null or t.carrier_id != f.id:
				errors.append("%s: figure %d carries inconsistent treasure %d" % [where, f.id, id])


## Explicit test-only compositions. Keep scenario-required figure count,
## placement and special fixtures; change only ordinary soldier types and
## caster schools/books. School alignment penalties are applied normally.
func _apply_roster(data: Dictionary,roster: String) -> void:
	var schools: Dictionary=JsonFile.read("res://data/schools.json")
	var spells: Dictionary=JsonFile.read("res://data/spells.json")
	var names: Array=["summoner","illusionist"] if roster=="mobility" else ["chronomancer","witch"]
	var books: Array=[
		["leap","plane_walk","imp","elemental_bolt","bone_dart","poison_dart","teleport","heal"],
		["teleport","glow","invisibility","push","combat_awareness","heal","poison_dart","leap"]
	] if roster=="mobility" else [
		["petrify","slow","fleet_feet","elemental_bolt","bone_dart","combat_awareness","heal","poison_dart"],
		["curse","mud","poison_dart","strength","bone_dart","leap","heal","glow"]
	]
	var soldiers: Array=["thief","tracker","treasure_hunter","archer","thug"] if roster=="mobility" else ["man_at_arms","infantryman","crossbowman","apothecary","knight"]
	for side in data.get("warbands",[]).size():
		var wb: Dictionary=data["warbands"][side]
		var school: String=names[side%2]
		wb["school"]=school
		wb["name"]=school.capitalize()
		var book: Dictionary={}
		for id: String in books[side%2]:
			var spell: Dictionary=spells[id]
			var source: String=spell["school"]
			var penalty:=0 if source==school else (2 if schools[school]["aligned"].has(source) else (6 if schools[school]["opposed"]==source else 4))
			book[id]=int(spell["number"])+penalty
		wb["spells"]=book
		var slot:=0
		for entry: Dictionary in wb.get("figures",[]):
			if entry["type"] in ["thug","thief","archer","crossbowman","infantryman","man_at_arms","treasure_hunter","knight","barbarian","ranger","marksman","tracker","templar","apothecary"]:
				entry["type"]=soldiers[(slot+side)%soldiers.size()]
				slot+=1


## Observe behavior without modifying state or consuming randomness. These
## are review indicators, not failure conditions; retreat and waiting can
## be correct and scenario-specific actions may not use the common events.
func _observe_behavior(events: Array,metrics: Dictionary,previous: Dictionary) -> void:
	var meaningful:=false
	for e: GameEvent in events:
		match e.type:
			"move","layered_move":
				meaningful=true
				metrics["movements"]+=1
				var path: Variant=e.data.get("path")
				if path==null or path.size()<2:
					continue
				var id:=int(e.data.get("id",-1))
				var old: Dictionary=previous.get(id,{})
				if not old.is_empty() and old["from"]==path[-1] and old["to"]==path[0]:
					metrics["reversals"]+=1
				previous[id]={"from":path[0],"to":path[-1]}
			"cast_roll":
				meaningful=true
				metrics["casts"]+=1
			"fight":
				meaningful=true
				metrics["fights"]+=1
			"shoot","spell_shot":
				meaningful=true
				metrics["shots"]+=1
			"treasure_pickup":
				meaningful=true
				metrics["pickups"]+=1
			"treasure_secured","reload","well_drink","break_ice","gear_used","potion_drunk","exit","stand_investigated","column_fight","disc_transport","genie_released":
				meaningful=true
	if not meaningful:
		metrics["no_action_event"]+=1
