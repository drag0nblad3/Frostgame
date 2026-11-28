class_name LayeredMovement
extends RefCounted
## Floor-geometry movement adapter. Common controller owns actions and reactions.


static func eligible(c: GameController,cape: bool=false) -> bool:
	var s := c.state
	var f := s.active()
	if s.board.floor_layout.is_empty() or not (GearActions.cape_ready(c) if cape else c.can_move()) or f.surface_id.is_empty():
		return false
	# Scenario rules no longer disable movement based on the map's geometry.
	if cape and PlaneWalk.uses_direct(f):
		return false
	return true


static func reach(c: GameController,cape: bool=false,run: bool=false,boost: bool=false,shared_grid: LayeredGrid=null) -> LayeredReach:
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
	var grid := shared_grid if shared_grid!=null else LayeredGrid.new(layout,f,s.figures)
	grid.running=run
	var leave_site:=ScenarioColumns.contact(s.board,f.pos,f.elevation)!=null
	var result:=LayeredReach.search(grid,start,(6.0 if boost else 3.0) if run else MoveRules.allowance(f),cape or leave_site)
	if not run and not cape and FuryRules.target(s,f)==null:
		LayeredFlight.add(s,f,grid,result,MoveRules.allowance(f))
	return FuryRules.restrict_floor(s,f,result)


static func move(c: GameController,node: Vector3i,cape: bool=false,run: bool=false,boost: bool=false,exiting: bool=false) -> bool:
	var reachable := reach(c,cape,run,boost)
	if node==reachable.start or not reachable.can_reach(node):
		return false
	var f := c.state.active()
	if not RedKingHill.before_move(c,f):
		return true
	var layout := c.state.board.floor_geometry()
	var path := PackedVector3Array()
	var surfaces: Array[String] = []
	for step in reachable.path_to(node):
		path.append(layout.world(step))
		surfaces.append(layout.surface_id(step))
	var cost:=float(reachable.cost[node])
	var air_path: PackedVector3Array=reachable.air_paths.get(node,PackedVector3Array())
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
	c._magic.beauty.authorize(f,targets,_authorized.bind(c,f,path,surfaces,cost,ignored,cape,run,boost,exiting,air_path))
	return true


static func _authorized(c: GameController,f: Figure,path: PackedVector3Array,surfaces: Array[String],cost: float,ignored: Array[int],cape: bool,run: bool,boost: bool,exiting: bool,air_path: PackedVector3Array=PackedVector3Array()) -> void:
	if not f.in_play() or (run and boost and not ActiveGear.spend(f,RunForIt.TALISMAN)) or (cape and not GearActions.use_cape(c,f)):
		return
	_offer_or_apply(c,f,path,surfaces,cost,ignored,run,boost,exiting,air_path)


static func _offer_or_apply(c: GameController,f: Figure,path: PackedVector3Array,surfaces: Array[String],cost: float,ignored: Array[int],run: bool,boost: bool,exiting: bool,air_path: PackedVector3Array=PackedVector3Array()) -> void:
	var choice:=c._displacement.intercept_floor(f,path,surfaces,ignored) if c.state.forced_combat and not run else {}
	if not choice.is_empty() and choice["guard"].side==c.state.reaction_side:
		c.state.pending_intercept={"floor_route":true,"mover":f.id,"path":path,"surfaces":surfaces,"cost":cost,"ignored":ignored,"choice":choice,"exiting":exiting,"air_path":air_path}
		c.emit("intercept_offer",{"id":choice["guard"].id,"target":f.id})
		return
	_apply(c,f,path,surfaces,cost,choice,run,boost,exiting,air_path)


static func answer_intercept(c: GameController,p: Dictionary,accept: bool) -> bool:
	var f:=c.state.figure(p["mover"])
	if f==null or not f.in_play():
		return false
	var surfaces: Array[String]=[]
	surfaces.assign(p["surfaces"])
	var path: PackedVector3Array=p["path"]
	var choice: Dictionary=p["choice"]
	if p.has("aerial_plan"):
		var plan: Dictionary=p["aerial_plan"]
		if accept:
			_apply_aerial(c,f,plan,choice)
		else:
			var rejected: Array[int]=[]
			rejected.assign(p["ignored"])
			rejected.append(choice["guard"].id)
			offer_aerial(c,f,plan,rejected)
		return true
	if accept:
		_apply(c,f,path,surfaces,float(p["cost"]),choice,false,false,bool(p["exiting"]),p.get("air_path",PackedVector3Array()))
	else:
		var ignored: Array[int]=[]
		ignored.assign(p["ignored"])
		ignored.append(choice["guard"].id)
		_offer_or_apply(c,f,path,surfaces,float(p["cost"]),ignored,false,false,bool(p["exiting"]),p.get("air_path",PackedVector3Array()))
	return true


static func _apply(c: GameController,f: Figure,path: PackedVector3Array,surfaces: Array[String],cost: float,choice: Dictionary,run: bool,boost: bool,exiting: bool,air_path: PackedVector3Array=PackedVector3Array(),finalize: bool=true,spend: bool=true) -> bool:
	if not air_path.is_empty():
		_apply_flight(c,f,air_path,surfaces,cost,choice,exiting)
		return false
	var engaged:=Contact.in_combat(c.state.figures,f)
	if not choice.is_empty():
		path.resize(int(choice["index"])+1)
		surfaces.resize(path.size())
	if spend:
		c.spend_move(f)
	# Maintain authoritative floor, elevation and position at every site
	# crossing; publish the movement chunk before its consequence.
	var chunk:=PackedVector3Array([path[0]])
	var chunk_surfaces: Array[String]=[surfaces[0]]
	var portal_seen: Dictionary={}
	var orb_contact:=RedKingSinkhole.touches(c.state,f.pos,f.elevation)
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
				return false
			continue
		if RedKingHerded.active(c.state) or RedKingVeil.active(c.state):
			if RedKingHerded.contact(c,f,at) or RedKingVeil.touch(c,f,at):
				f.actions_left=0
				_stop(c,f,engaged,run,boost)
				return false
		if not RedKingSquatter.permit_step(c,f,at,point.y):
			if chunk.size()>1:
				c.emit("layered_move",{"id":f.id,"path":chunk,"surfaces":chunk_surfaces,"cost":cost})
			_stop(c,f,engaged,run,boost)
			return false
		var occupied:=false
		if c.state.scenario_special=="haunted_houses" and not c.state.discovered_huts.is_empty():
			for other in c.state.figures:
				if other==f or not other.in_play() or other.ring_side!=f.ring_side or absf(other.elevation-point.y)>=0.5:
					continue
				if other.pos.distance_to(at)<Contact.OVERLAP:
					if chunk.size()>1:
						c.emit("layered_move",{"id":f.id,"path":chunk,"surfaces":chunk_surfaces,"cost":cost})
					_stop(c,f,engaged,run,boost)
					return false
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
		var touches_orb:=RedKingSinkhole.touches(c.state,at,point.y)
		var orb_hit:=touches_orb and not orb_contact
		orb_contact=touches_orb
		RedKingSinkhole.record_xp_at(c,f,at)
		for wall in c._magic.terrain.touching_walls(Vector2(previous.x,previous.z),previous.y):
			walls.erase(wall)
		var hut:=ScenarioSites.site_at(c.state,"haunted_floor",f.pos,f.elevation) if c.state.scenario_special=="haunted_houses" and f.side>=0 else null
		var undiscovered:=hut!=null and not c.state.discovered_huts.has(hut.rect.position)
		var column:=f.side>=0 and not IllusionRules.phantom(f) and ScenarioColumns.contact(c.state.board,f.pos,f.elevation)!=null
		if ScenarioNull.field_at(c.state.board,f.pos) or not hits.is_empty() or not walls.is_empty() or undiscovered or occupied or column or portal_hit or orb_hit:
			c.emit("layered_move",{"id":f.id,"path":chunk,"surfaces":chunk_surfaces,"cost":cost})
			chunk=PackedVector3Array([point])
			chunk_surfaces=[surfaces[i]]
			if portal_hit:
				RedKingFire.portal_contact(c,f,previous_at,at,portal_seen,previous.y,point.y)
			if orb_hit:
				RedKingSinkhole.contact(c,f)
			ScenarioNull.enter(c,f)
			if f.in_play():
				for wall in walls:
					c._magic.terrain.wall_damage(f,wall)
				for p in hits:
					c._magic.terrain.explode(p)
			if not f.in_play():
				_stop(c,f,engaged,run,boost)
				return false
			if column and (not finalize or i<path.size()-1) and ScenarioColumns.challenge(c,f):
				_stop(c,f,engaged,run,boost)
				return false
			if undiscovered and ScenarioSites.enter(c,f) and Contact.in_combat(c.state.figures,f):
				_stop(c,f,engaged,run,boost)
				return false
			if occupied and i<path.size()-1:
				_stop(c,f,engaged,run,boost)
				return false
	if chunk.size()>1:
		c.emit("layered_move",{"id":f.id,"path":chunk,"surfaces":chunk_surfaces,"cost":cost})
	if not choice.is_empty():
		c._displacement.force_contact(choice)
	if not finalize:
		if not f.in_play() or Contact.in_combat(c.state.figures,f) or ScenarioNull.field_at(c.state.board,f.pos):
			c.finish_movement(f,engaged,f.in_play())
			return false
		return true
	c.finish_movement(f,engaged)
	if run:
		RunForIt.finish(c,f,boost)
	elif exiting and choice.is_empty() and f.in_play() and not Contact.in_combat(c.state.figures,f):
		LayeredLoot.complete(c,f)
	return true


static func _stop(c: GameController,f: Figure,engaged: bool,run: bool,boost: bool) -> void:
	c.finish_movement(f,engaged,false)
	if run:
		RunForIt.finish(c,f,boost)


## Airborne route points are not standing positions. Landing interception
## uses the ordinary offer, while ground effects only trigger at landing.
static func _apply_flight(c: GameController,f: Figure,path: PackedVector3Array,surfaces: Array[String],cost: float,choice: Dictionary,exiting: bool) -> void:
	var engaged:=Contact.in_combat(c.state.figures,f)
	c.spend_move(f)
	var dest:=path[-1]
	var at:=Vector2(dest.x,dest.z)
	if RedKingHerded.contact(c,f,at) or RedKingVeil.touch(c,f,at):
		f.actions_left=0
		return
	f.pos=at
	f.elevation=dest.y
	f.surface_id=surfaces[-1]
	c.emit("layered_move",{"id":f.id,"path":path,"surfaces":surfaces,"cost":cost,"flight":true})
	RedKingFire.portal_contact(c,f,at,at,{},dest.y,dest.y)
	RedKingMind.collect(c,f,at,at,dest.y,dest.y)
	if f.in_play():
		c._magic.terrain.trigger_landing(f)
	if f.in_play() and not choice.is_empty():
		c._displacement.force_contact(choice)
	c.finish_movement(f,engaged,f.in_play())
	if exiting and choice.is_empty() and f.in_play() and not Contact.in_combat(c.state.figures,f):
		LayeredLoot.complete(c,f)


## Interception samples only the grounded run-up and actual landing; the arc
## is visual and never a standing position. Use the normal optional reaction.
static func cape_aerial(c: GameController,n: Vector3i,plan: Dictionary) -> bool:
	if not GearActions.cape_ready(c):
		return false
	var f:=c.state.active()
	var layout:=c.state.board.floor_geometry()
	var targets:=MovementContact.enemies_at(c.state.figures,f,layout.point(n),layout.height(n),layout.surface_id(n))
	c._magic.beauty.authorize(f,targets,_cape_aerial_authorized.bind(c,f,plan))
	return true


static func _cape_aerial_authorized(c: GameController,f: Figure,plan: Dictionary) -> void:
	if c.state.active()!=f or not GearActions.cape_ready(c) or not RedKingHill.before_move(c,f):
		return
	var ignored: Array[int]=[]
	for enemy in Contact.enemies_of(c.state.figures,f):
		ignored.append(enemy.id)
	if GearActions.use_cape(c,f):
		offer_aerial(c,f,plan,ignored)


static func offer_aerial(c: GameController,f: Figure,plan: Dictionary,ignored: Array[int]=[]) -> void:
	if not f.in_play() or c.state.active()!=f:
		return
	var path:=PackedVector3Array()
	var surfaces: Array[String]=[]
	_append_aerial_contacts(plan,f.surface_id,path,surfaces)
	var choice:=c._displacement.intercept_floor(f,path,surfaces,ignored) if c.state.forced_combat else {}
	if not choice.is_empty() and choice["guard"].side==c.state.reaction_side:
		c.state.pending_intercept={"floor_route":true,"mover":f.id,"path":path,"surfaces":surfaces,"cost":plan["cost"],"ignored":ignored,"choice":choice,"exiting":false,"aerial_plan":plan}
		c.emit("intercept_offer",{"id":choice["guard"].id,"target":f.id})
		return
	_apply_aerial(c,f,plan,choice)


static func _apply_aerial(c: GameController,f: Figure,plan: Dictionary,choice: Dictionary,spend: bool=true) -> void:
	if not f.in_play() or c.state.active()!=f:
		return
	var grounded: PackedVector3Array=plan["grounded"]
	var surfaces:=_grounded_surfaces(f,plan,grounded)
	var cost:=float(plan.get("segment_cost",plan.get("aerial_cost",plan["cost"])))
	var approach_cost:=float(plan.get("approach_cost",0.0))
	var engaged:=Contact.in_combat(c.state.figures,f)
	var was_wounded:=f.wounded()
	# An interception during the run-up prevents takeoff and any fall damage.
	if not choice.is_empty() and int(choice["index"])<grounded.size():
		_apply(c,f,grounded,surfaces,approach_cost if plan.has("approach_cost") else cost,choice,false,false,false,PackedVector3Array(),true,spend)
		return
	if grounded.size()>1:
		if not _apply(c,f,grounded,surfaces,approach_cost if plan.has("approach_cost") else cost,{},false,false,false,PackedVector3Array(),false,spend):
			return
	elif spend:
		c.spend_move(f)
	if not f.in_play() or c.awaiting_reaction() or (not was_wounded and f.wounded()):
		c.finish_movement(f,engaged,f.in_play())
		return
	var dest: Vector3=plan["path"][-1]
	var at:=Vector2(dest.x,dest.z)
	# A run-up can reveal a creature or alter terrain. Recheck the landing
	# before committing the airborne part of this already-spent move.
	var layout:=c.state.board.floor_geometry()
	var landing:=layout.node(str(plan["surface"]),at)
	var grid:=LayeredGrid.new(layout,f,c.state.figures)
	var arc_check: PackedVector3Array=plan.get("arc",plan["path"])
	var clear:=true
	for point in arc_check:
		if not layout.clearance(point,Figure.BASE_RADIUS,1.6):
			clear=false
			break
	if not clear or not grid.open(landing) or not is_equal_approx(layout.height(landing),dest.y):
		c.finish_movement(f,engaged,f.in_play())
		return
	if RedKingHerded.contact(c,f,at) or RedKingVeil.touch(c,f,at):
		f.actions_left=0
		return
	if not RedKingSquatter.permit_step(c,f,at,dest.y):
		c.finish_movement(f,engaged,false)
		return
	var old:=f.surface_id
	f.pos=at
	f.elevation=dest.y
	f.surface_id=str(plan["surface"])
	var arc: PackedVector3Array=plan.get("arc",plan["path"]).duplicate()
	if grounded.size()>1 and not plan.has("arc"):
		arc.remove_at(0)
	var event: Dictionary={"id":f.id,"path":arc,"surfaces":[old,f.surface_id],"cost":cost-approach_cost}
	event["jump" if plan.get("jump",false) else "fall"]=true
	c.emit("layered_move",event)
	LayeredFall.apply(c,f,float(plan["fall"]),f)
	if f.in_play():
		RedKingFire.portal_contact(c,f,at,at,{},dest.y,dest.y)
		RedKingMind.collect(c,f,at,at,dest.y,dest.y)
		ScenarioNull.enter(c,f)
	if f.in_play():
		c._magic.terrain.trigger_landing(f)
	var landing_intercept:=not choice.is_empty() and int(choice["index"])==grounded.size()
	if f.in_play() and landing_intercept:
		c._displacement.force_contact(choice)
	var can_continue:=f.in_play() and not c.awaiting_reaction() and not landing_intercept and not Contact.in_combat(c.state.figures,f) and not (not was_wounded and f.wounded()) and not bool(plan.get("end_activation",false))
	if can_continue and plan.has("next"):
		var next: Dictionary=plan["next"].duplicate()
		if plan.has("tail"):
			for key in ["tail","tail_surfaces","remaining"]:
				next[key]=plan[key]
		var later:=choice.duplicate()
		if not later.is_empty():
			later["index"]=int(later["index"])-grounded.size()
		# A landing can reveal new occupants or change the route. Recompute the
		# second leg before committing it, without modifying the live figure.
		if _valid_next_aerial(c,f,next):
			_apply_aerial(c,f,next,later,false)
			return
	elif can_continue and plan.has("tail"):
		if _continue_aerial(c,f,plan,choice,grounded.size()):
			return
	c.finish_movement(f,engaged,f.in_play())
	if bool(plan.get("end_activation",false)) and f.in_play():
		f.actions_left=0
		if c.can_end_activation():
			c.end_activation()


## A known fall that kills or newly wounds a figure ends its movement.
## Do not preview a follow-through that execution will necessarily stop.
static func fall_interrupts(c: GameController,f: Figure,plan: Dictionary) -> bool:
	var health:=f.health
	var leg:=plan
	var can_wound:=c.state.wounded_rules and not f.wounded() and not f.is_undead() and not f.def.traits.has("construct")
	var threshold:=2 if MagicEquipment.bonus(f,"vigour")>0 else 4
	while not leg.is_empty():
		health-=LayeredFall.damage(c.state,f,float(leg.get("fall",0.0)))
		if health<=0 or (can_wound and health<f.def.health and health<=threshold):
			return true
		leg=leg.get("next",{})
	return false


## Expand only explicit jump/drop choices, never the ordinary move or AI
## distance search. Each candidate keeps the full route and one action cost.
static func extend_aerial(c: GameController,base: Dictionary,shared_grid: LayeredGrid=null) -> Dictionary:
	var out:=base.duplicate()
	if base.is_empty():
		return out
	var f:=c.state.active()
	var layout:=c.state.board.floor_geometry()
	var grid:=shared_grid if shared_grid!=null else LayeredGrid.new(layout,f,c.state.figures)
	grid.memoize_edges=true
	var allowance:=MoveRules.allowance(f)
	var cost: Dictionary={}
	var prev: Dictionary={}
	var heap:=MinHeap.new()
	# All continuable landings seed one weighted flood. Overlapping landing
	# neighborhoods no longer repeat the same ground-edge searches.
	for landing: Vector3i in base:
		var plan: Dictionary=base[landing]
		var paid:=float(plan["cost"])
		if allowance-paid<MoveGrid.STEP-0.001 or bool(plan.get("end_activation",false)) or grid.stops(landing) or fall_interrupts(c,f,plan):
			continue
		cost[landing]=paid
		heap.push(paid,landing)
	RouteSearch.expand(null,grid,heap,cost,prev,allowance,true,null,true)
	var origin:=layout.node(f.surface_id,f.pos)
	for n: Vector3i in cost:
		var total:=float(cost[n])
		if n==origin or not prev.has(n) or (out.has(n) and total>=float(out[n]["cost"])-0.001):
			continue
		if BattleBoundary.blocks_end(c.state.board.boundaries,layout.point(n)):
			continue
		var nodes: Array[Vector3i]=[n]
		var root:=n
		while prev.has(root):
			root=prev[root]
			nodes.append(root)
		nodes.reverse()
		var plan: Dictionary=base[root]
		var tail:=PackedVector3Array()
		var surfaces: Array[String]=[]
		for step in nodes:
			tail.append(layout.world(step))
			surfaces.append(layout.surface_id(step))
		var extended:=plan.duplicate()
		extended["cost"]=total
		extended["aerial_cost"]=plan["cost"]
		extended["remaining"]=allowance-float(plan["cost"])
		extended["tail"]=tail
		extended["tail_surfaces"]=surfaces
		var preview: PackedVector3Array=plan.get("preview",plan["path"]).duplicate()
		for i in range(1,tail.size()):
			preview.append(tail[i])
		extended["preview"]=preview
		out[n]=extended
	return out


## Recheck the declared suffix against the actual geometry and budget after
## landing. Never spend a second action or silently substitute a new route.
static func _continue_aerial(c: GameController,f: Figure,plan: Dictionary,choice: Dictionary,landing_index: int) -> bool:
	var declared: PackedVector3Array=plan["tail"]
	var declared_surfaces: Array=plan["tail_surfaces"]
	var layout:=c.state.board.floor_geometry()
	var grid:=LayeredGrid.new(layout,f,c.state.figures)
	var start:=layout.node(f.surface_id,f.pos)
	if not grid.open(start) or grid.stops(start) or ScenarioNull.field_at(c.state.board,f.pos):
		return false
	var path:=PackedVector3Array([layout.world(start)])
	var surfaces: Array[String]=[f.surface_id]
	var budget:=float(plan["remaining"])
	var spent:=0.0
	var previous:=start
	var intercept: Dictionary={}
	for i in range(1,declared.size()):
		var point:=declared[i]
		var n:=layout.node(str(declared_surfaces[i]),Vector2(point.x,point.z))
		if not grid.open(n) or not layout.world(n).is_equal_approx(point):
			break
		var step_cost:=INF
		for edge in grid.neighbors(previous):
			if edge["to"]==n:
				step_cost=minf(step_cost,float(edge["cost"]))
		if spent+step_cost>budget+0.001:
			break
		spent+=step_cost
		path.append(point)
		surfaces.append(str(declared_surfaces[i]))
		previous=n
		if not choice.is_empty() and int(choice["index"])==landing_index+i:
			intercept=choice.duplicate()
			intercept["index"]=i
			break
		if grid.stops(n):
			break
	if path.size()<2:
		return false
	_apply(c,f,path,surfaces,spent,intercept,false,false,false,PackedVector3Array(),true,false)
	return true


## A drop approach may cross stairs and change support before reaching the ledge.
## Straight jump run-ups retain the original single-support representation.
static func _grounded_surfaces(f: Figure,plan: Dictionary,grounded: PackedVector3Array) -> Array[String]:
	var surfaces: Array[String]=[]
	if plan.has("grounded_surfaces"):
		surfaces.assign(plan["grounded_surfaces"])
	else:
		for i in grounded.size():
			surfaces.append(f.surface_id)
	return surfaces


## Bounded second aerial leg. The live figure is not relocated to preview
## hypothetical routes. Prefer the direct route on a tie.
static func chain_aerial(c: GameController,base: Dictionary,shared_grid: LayeredGrid=null,rank: Callable=Callable(),budget: int=0) -> Dictionary:
	var out:=base.duplicate()
	if base.is_empty():
		return out
	var f:=c.state.active()
	var layout:=c.state.board.floor_geometry()
	var grid:=shared_grid if shared_grid!=null else LayeredGrid.new(layout,f,c.state.figures)
	grid.memoize_edges=true
	var origin:=layout.node(f.surface_id,f.pos)
	var allowance:=MoveRules.allowance(f)
	var seeds: Array=base.keys()
	if rank.is_valid() and budget>0 and seeds.size()>budget:
		seeds.sort_custom(func(a: Vector3i,b: Vector3i) -> bool:return float(rank.call(layout.world(a)))+float(base[a]["cost"])*0.2<float(rank.call(layout.world(b)))+float(base[b]["cost"])*0.2)
		seeds=seeds.slice(0,budget)
	for landing: Vector3i in seeds:
		var first: Dictionary=base[landing]
		var paid:=float(first["cost"])
		var remaining:=allowance-paid
		if remaining<0.501 or bool(first.get("end_activation",false)) or grid.stops(landing) or fall_interrupts(c,f,first):
			continue
		var second:=LayeredJump.from_position(c,layout,grid,landing,remaining)
		var drops:=LayeredDrop.from_position(c,layout,grid,landing,remaining,true,false,null,false,rank,budget)
		for target: Vector3i in drops:
			if not second.has(target) or float(drops[target]["cost"])<float(second[target]["cost"]):
				second[target]=drops[target]
		for target: Vector3i in second:
			if target==origin or target==landing:
				continue
			var leg: Dictionary=second[target]
			var total:=paid+float(leg["cost"])
			if total>allowance+0.001 or (out.has(target) and total>=float(out[target]["cost"])-0.001):
				continue
			var combined:=first.duplicate()
			combined["segment_cost"]=paid
			combined["cost"]=total
			combined["next"]=leg
			var preview: PackedVector3Array=first.get("preview",first["path"]).duplicate()
			var suffix: PackedVector3Array=leg.get("preview",leg["path"])
			for i in range(1,suffix.size()):
				preview.append(suffix[i])
			combined["preview"]=preview
			out[target]=combined
	return out


## Flatten only grounded contact points, preserving the landing index used
## to split an accepted reaction between the two aerial legs.
static func _append_aerial_contacts(plan: Dictionary,support: String,path: PackedVector3Array,surfaces: Array[String]) -> void:
	var grounded: PackedVector3Array=plan["grounded"]
	var explicit: Array=plan.get("grounded_surfaces",[])
	for i in range(0 if path.is_empty() else 1,grounded.size()):
		path.append(grounded[i])
		surfaces.append(str(explicit[i]) if not explicit.is_empty() else support)
	path.append(plan["path"][-1])
	surfaces.append(str(plan["surface"]))
	if plan.has("next"):
		_append_aerial_contacts(plan["next"],str(plan["surface"]),path,surfaces)
	var tail: PackedVector3Array=plan.get("tail",PackedVector3Array())
	var tail_surfaces: Array=plan.get("tail_surfaces",[])
	for i in range(1,tail.size()):
		path.append(tail[i])
		surfaces.append(str(tail_surfaces[i]))


static func _valid_next_aerial(c: GameController,f: Figure,plan: Dictionary) -> bool:
	var layout:=c.state.board.floor_geometry()
	var grid:=LayeredGrid.new(layout,f,c.state.figures)
	var start:=layout.node(f.surface_id,f.pos)
	var target: Vector3=plan["path"][-1]
	var n:=layout.node(str(plan["surface"]),Vector2(target.x,target.z))
	var budget:=float(plan["cost"])
	var candidates:=LayeredJump.from_position(c,layout,grid,start,budget) if plan.get("jump",false) else LayeredDrop.from_position(c,layout,grid,start,budget,true)
	if not candidates.has(n):
		return false
	var actual: Dictionary=candidates[n]
	return actual["grounded"]==plan["grounded"] and actual["path"]==plan["path"]
