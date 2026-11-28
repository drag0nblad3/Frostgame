class_name CoreScenarioChoice
extends RefCounted
## Plain decision records, shared by both geometry providers.
const KEY := "core_scenario_choice"

static func pending(c: GameController) -> Dictionary:
	return c.state.scenario_data.get(KEY,{})

static func point(s: GameState,at: Vector2,surface: String="") -> Dictionary:
	var height:=s.board.height_at(at)
	if not surface.is_empty():
		var l:=s.board.floor_geometry()
		height=l.surfaces[l.index_of(surface)].height_at(at)
	return {"at":at,"surface":surface,"world":Vector3(at.x,height,at.y)}

static func offer(c: GameController,kind: String,owner: int,actor: int,token: int,roll: int,options: Array[Dictionary]) -> bool:
	if owner<0 or owner!=c.state.reaction_side or options.is_empty() or not pending(c).is_empty():
		return false
	c.state.scenario_data[KEY]={"kind":kind,"owner":owner,"actor":actor,"token":token,"roll":roll,"options":options}
	c.emit("core_scenario_choice",{"kind":kind,"side":owner})
	return true

static func choose(c: GameController,index: int) -> bool:
	var d:=pending(c)
	if d.is_empty() or d["owner"]!=c.state.reaction_side:
		return false
	var options: Array=d["options"]
	if index<0 or index>=options.size():
		return false
	var p: Dictionary=options[index]
	var kind:=str(d["kind"])
	var f:=c.state.figure(int(d["actor"]))
	var token:=c.state.treasure(int(d["token"]))
	if kind!="column" and not _open(c,p,f if kind=="disc" else null):
		return false
	if kind=="genie" and (f==null or not f.in_play() or not ScenarioGenie.legal_spawn(c.state,f,p["world"])):
		return false
	c.state.scenario_data.erase(KEY)
	match kind:
		"genie":
			ScenarioGenie._released(c,f,token,_spawn(c,"genie",p))
		"worm":
			var worm:=_spawn(c,"giant_worm",p)
			c.state.worm_spawned=true
			c.emit("worm_emerges",{"id":worm.id,"treasure":token.id})
		"disc":
			ScenarioSites.land_disc(c,f,p,int(d["roll"]))
		"column":
			if bool(p.get("collect",false)) and f!=null and token!=null:
				c._loot.claim_free(f,token)
		_:
			return false
	c.emit("core_scenario_resolved",{"kind":kind,"choice":index})
	if c.state.phase==Phase.CREATURE and c.state.active()==null and not c.awaiting_reaction():
		c._flow._settle()
	return true

static func _open(c: GameController,p: Dictionary,mover: Figure) -> bool:
	var at: Vector2=p["at"]
	if c.state.board.floor_layout.is_empty():
		return MoveGrid.new(c.state.board,mover,c.state.figures).open(MovePlanner.node_at(at))
	return BattlePlacement.floor_open(c.state,c.state.board.floor_geometry().node(str(p["surface"]),at),mover)

static func _spawn(c: GameController,id: String,p: Dictionary) -> Figure:
	if str(p["surface"]).is_empty():
		return c._encounters._spawn_at(id,p["at"])
	return c._encounters._spawn_on_floor(id,c.state.board.floor_geometry().node(p["surface"],p["at"]))

static func tactical(c: GameController,owner: int,options: Array[Dictionary]) -> Dictionary:
	var best: Dictionary=options[0]
	var score:=-INF
	for p in options:
		var at: Vector3=p["world"]
		var ally:=20.0
		var enemy:=20.0
		for f in c.state.figures:
			if not f.in_play() or f.side<0:
				continue
			var distance:=at.distance_to(Vector3(f.pos.x,f.elevation,f.pos.y))
			if f.side==owner:
				ally=minf(ally,distance)
			else:
				enemy=minf(enemy,distance)
		var value:=ally-enemy
		if value>score:
			score=value
			best=p
	return best
