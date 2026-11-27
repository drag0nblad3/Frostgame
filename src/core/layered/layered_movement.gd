class_name LayeredMovement
extends RefCounted
## Floor-geometry movement adapter. Common controller owns actions and reactions.


static func eligible(c: GameController,cape: bool=false) -> bool:
	var s := c.state
	var f := s.active()
	if s.board.floor_layout.is_empty() or not (GearActions.cape_ready(c) if cape else c.can_move()) or f.surface_id.is_empty():
		return false
	# Only scenarios whose spatial objectives have been audited can opt
	# into authored stacked floors. Ordinary maps continue to use the same rules.
	if s.scenario_special not in ["","silent_tower","dreams_well","underground_library","worm_hunts","genie_in_the_bottle","haunted_houses","the_keep","complex_temple",RedKingFire.ID,RedKingInvestigations.ID,RedKingSquatter.ID,RedKingHerded.ID,RedKingVeil.ID,RedKingMind.ID,RedKingTethers.ID,RedKingRingworld.ID]:
		return false
	if cape and PlaneWalk.uses_direct(f):
		return false
	return true


static func reach(c: GameController,cape: bool=false,run: bool=false,boost: bool=false) -> LayeredReach:
	if not eligible(c,cape) or (run and not RunForIt.ready(c,boost)):
		return LayeredReach.new()
	var s := c.state
	var f := s.active()
	var layout := s.board.floor_geometry()
	if not layout.errors.is_empty():
		return LayeredReach.new()
	var start := layout.node(f.surface_id,f.pos)
	if not layout.standable(start) or not layout.point(start).is_equal_approx(f.pos) or not is_equal_approx(layout.height(start),f.elevation):
		return LayeredReach.new()
	if PlaneWalk.uses_direct(f):
		return LayeredReach.new() if run or cape else FuryRules.restrict_floor(s,f,PlaneWalk.floor_reach(s,f))
	var grid := LayeredGrid.new(layout,f,s.figures)
	grid.running=run
	var leave_site:=ScenarioColumns.contact(s.board,f.pos,f.elevation)!=null
	return FuryRules.restrict_floor(s,f,LayeredReach.search(grid,start,(6.0 if boost else 3.0) if run else MoveRules.allowance(f),cape or leave_site))


static func move(c: GameController,node: Vector3i,cape: bool=false,run: bool=false,boost: bool=false,exiting: bool=false) -> bool:
	var reachable := reach(c,cape,run,boost)
	if node==reachable.start or not reachable.can_reach(node):
		return false
	var f := c.state.active()
	var layout := c.state.board.floor_geometry()
	var path := PackedVector3Array()
	var surfaces: Array[String] = []
	for step in reachable.path_to(node):
		path.append(layout.world(step))
		surfaces.append(layout.surface_id(step))
	var cost:=float(reachable.cost[node])
	if f.spell_effects.has("plane_walk"):
		c.spend_move(f)
		for i in range(1,path.size()):
			var at:=Vector2(path[i].x,path[i].z)
			if RedKingHerded.contact(c,f,at) or RedKingVeil.touch(c,f,at):
				f.actions_left=0
				return true
			RedKingMind.collect(c,f,Vector2(path[i-1].x,path[i-1].z),at,path[i-1].y,path[i].y)
		f.pos=layout.point(node)
		f.elevation=layout.height(node)
		f.surface_id=layout.surface_id(node)
		c.emit("layered_move",{"id":f.id,"path":path,"surfaces":surfaces,"cost":cost})
		ScenarioSites.end_move(c,f)
		return true
	var targets:=MovementContact.enemies_at(c.state.figures,f,layout.point(node),layout.height(node),layout.surface_id(node))
	var ignored: Array[int]=[]
	if cape:
		for enemy in Contact.enemies_of(c.state.figures,f):
			ignored.append(enemy.id)
	c._magic.beauty.authorize(f,targets,_authorized.bind(c,f,path,surfaces,cost,ignored,cape,run,boost,exiting))
	return true


static func _authorized(c: GameController,f: Figure,path: PackedVector3Array,surfaces: Array[String],cost: float,ignored: Array[int],cape: bool,run: bool,boost: bool,exiting: bool) -> void:
	if not f.in_play() or (run and boost and not ActiveGear.spend(f,RunForIt.TALISMAN)) or (cape and not GearActions.use_cape(c,f)):
		return
	_offer_or_apply(c,f,path,surfaces,cost,ignored,run,boost,exiting)


static func _offer_or_apply(c: GameController,f: Figure,path: PackedVector3Array,surfaces: Array[String],cost: float,ignored: Array[int],run: bool,boost: bool,exiting: bool) -> void:
	var choice:=c._displacement.intercept_floor(f,path,surfaces,ignored) if c.state.forced_combat and not run else {}
	if not choice.is_empty() and choice["guard"].side==c.state.reaction_side:
		c.state.pending_intercept={"floor_route":true,"mover":f.id,"path":path,"surfaces":surfaces,"cost":cost,"ignored":ignored,"choice":choice,"exiting":exiting}
		c.emit("intercept_offer",{"id":choice["guard"].id,"target":f.id})
		return
	_apply(c,f,path,surfaces,cost,choice,run,boost,exiting)


static func answer_intercept(c: GameController,p: Dictionary,accept: bool) -> bool:
	var f:=c.state.figure(p["mover"])
	if f==null or not f.in_play():
		return false
	var surfaces: Array[String]=[]
	surfaces.assign(p["surfaces"])
	var path: PackedVector3Array=p["path"]
	var choice: Dictionary=p["choice"]
	if accept:
		_apply(c,f,path,surfaces,float(p["cost"]),choice,false,false,bool(p["exiting"]))
	else:
		var ignored: Array[int]=[]
		ignored.assign(p["ignored"])
		ignored.append(choice["guard"].id)
		_offer_or_apply(c,f,path,surfaces,float(p["cost"]),ignored,false,false,bool(p["exiting"]))
	return true


static func _apply(c: GameController,f: Figure,path: PackedVector3Array,surfaces: Array[String],cost: float,choice: Dictionary,run: bool,boost: bool,exiting: bool) -> void:
	var engaged:=Contact.in_combat(c.state.figures,f)
	if not choice.is_empty():
		path.resize(int(choice["index"])+1)
		surfaces.resize(path.size())
	c.spend_move(f)
	# Maintain authoritative floor, elevation and position at every site
	# crossing; publish the movement chunk before its consequence.
	var chunk:=PackedVector3Array([path[0]])
	var chunk_surfaces: Array[String]=[surfaces[0]]
	var portal_seen: Dictionary={}
	for i in range(1,path.size()):
		var point:=path[i]
		var at:=Vector2(point.x,point.z)
		var before:=path[i-1]
		if BoardTopology.is_transfer(c.state.board,Vector2(before.x,before.z),at):
			if chunk.size()>1:
				c.emit("layered_move",{"id":f.id,"path":chunk,"surfaces":chunk_surfaces,"cost":cost})
			f.pos=at
			f.elevation=point.y
			f.surface_id=surfaces[i]
			c.emit("layered_move",{"id":f.id,"path":PackedVector3Array([before,point]),"surfaces":[surfaces[i-1],surfaces[i]],"cost":0.0,"teleport":true})
			chunk=PackedVector3Array([point])
			chunk_surfaces=[surfaces[i]]
			c._magic.terrain.trigger_landing(f)
			if not f.in_play():
				_stop(c,f,engaged,run,boost)
				return
			continue
		if RedKingHerded.active(c.state) or RedKingVeil.active(c.state):
			if RedKingHerded.contact(c,f,at) or RedKingVeil.touch(c,f,at):
				f.actions_left=0
				_stop(c,f,engaged,run,boost)
				return
		if not RedKingSquatter.permit_step(c,f,at,point.y):
			if chunk.size()>1:
				c.emit("layered_move",{"id":f.id,"path":chunk,"surfaces":chunk_surfaces,"cost":cost})
			_stop(c,f,engaged,run,boost)
			return
		var occupied:=false
		if c.state.scenario_special=="haunted_houses" and not c.state.discovered_huts.is_empty():
			for other in c.state.figures:
				if other==f or not other.in_play() or other.ring_side!=f.ring_side or absf(other.elevation-point.y)>=0.5:
					continue
				if other.pos.distance_to(at)<Contact.OVERLAP:
					if chunk.size()>1:
						c.emit("layered_move",{"id":f.id,"path":chunk,"surfaces":chunk_surfaces,"cost":cost})
					_stop(c,f,engaged,run,boost)
					return
				if other.side!=f.side and Contact.touches_position(other,at,point.y,surfaces[i]):
					occupied=true
		f.pos=at
		f.elevation=point.y
		f.surface_id=surfaces[i]
		chunk.append(point)
		chunk_surfaces.append(surfaces[i])
		var hits:=c._magic.terrain.triggered(f,f.pos,f.elevation)
		var walls:=c._magic.terrain.touching_walls(f.pos,f.elevation)
		var previous:=path[i-1]
		var previous_at:=Vector2(previous.x,previous.z)
		RedKingMind.collect(c,f,previous_at,at,previous.y,point.y)
		var portal_hit:=not RedKingFire.portal_hits(c.state,previous_at,at,portal_seen,previous.y,point.y).is_empty()
		for wall in c._magic.terrain.touching_walls(Vector2(previous.x,previous.z),previous.y):
			walls.erase(wall)
		var hut:=ScenarioSites.site_at(c.state,"haunted_floor",f.pos,f.elevation) if c.state.scenario_special=="haunted_houses" and f.side>=0 else null
		var undiscovered:=hut!=null and not c.state.discovered_huts.has(hut.rect.position)
		var column:=f.side>=0 and not IllusionRules.phantom(f) and ScenarioColumns.contact(c.state.board,f.pos,f.elevation)!=null
		if ScenarioNull.field_at(c.state.board,f.pos) or not hits.is_empty() or not walls.is_empty() or undiscovered or occupied or column or portal_hit:
			c.emit("layered_move",{"id":f.id,"path":chunk,"surfaces":chunk_surfaces,"cost":cost})
			chunk=PackedVector3Array([point])
			chunk_surfaces=[surfaces[i]]
			if portal_hit:
				RedKingFire.portal_contact(c,f,previous_at,at,portal_seen,previous.y,point.y)
			ScenarioNull.enter(c,f)
			if f.in_play():
				for wall in walls:
					c._magic.terrain.wall_damage(f,wall)
				for p in hits:
					c._magic.terrain.explode(p)
			if not f.in_play():
				_stop(c,f,engaged,run,boost)
				return
			if column and i<path.size()-1 and ScenarioColumns.challenge(c,f):
				_stop(c,f,engaged,run,boost)
				return
			if undiscovered and ScenarioSites.enter(c,f) and Contact.in_combat(c.state.figures,f):
				_stop(c,f,engaged,run,boost)
				return
			if occupied and i<path.size()-1:
				_stop(c,f,engaged,run,boost)
				return
	if chunk.size()>1:
		c.emit("layered_move",{"id":f.id,"path":chunk,"surfaces":chunk_surfaces,"cost":cost})
	if not choice.is_empty():
		c._displacement.force_contact(choice)
	c.finish_movement(f,engaged)
	if run:
		RunForIt.finish(c,f,boost)
	elif exiting and choice.is_empty() and f.in_play() and not Contact.in_combat(c.state.figures,f):
		LayeredLoot.complete(c,f)


static func _stop(c: GameController,f: Figure,engaged: bool,run: bool,boost: bool) -> void:
	c.finish_movement(f,engaged,false)
	if run:
		RunForIt.finish(c,f,boost)
