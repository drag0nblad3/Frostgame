class_name LayeredLeap
extends RefCounted
## Friendly target, explicit landing floor, straight or arcing trajectory.
## The target exhausts its remaining actions; use normal spell resolution.


static func eligible(c: GameController,t: Figure) -> bool:
	var s := c.state
	var f := s.active()
	if s.board.floor_layout.is_empty() or f==null or t==null or not t.in_play() or t.side!=f.side or t.ring_side!=f.ring_side:
		return false
	if ScenarioNull.muted(f) or ScenarioNull.muted(t) or t.def.traits.has("antithetical_magic") or t.spell_effects.has("plane_walk") or RedKingMadMan.is_ryce(t) or RedKingTethers.pylon(t):
		return false
	if not c.can_act() or not CasterLoadout.is_caster(f.def.role) or not c._magic.available_spell(f,"leap"):
		return false
	if Contact.in_combat(s.figures,f) or f.spell_effects.has("blinding_light") or s.group.in_progress():
		return false
	if t.spell_effects.has("bones_of_the_earth") or t.spell_effects.has("petrify") or t.surface_id.begins_with("climb:"):
		return false
	if f==t:
		return true
	if not IllusionRules.visible_to(s.figures,f,t):
		return false
	var limit:=float(s.spell_catalog["leap"].get("range",24.0))
	return LineOfSight.spell_visible(s.board,f,t,limit) or TigerEye.floor_witness(s.board,f,Vector3(t.pos.x,t.elevation,t.pos.y),limit)!=null


static func path(c: GameController,t: Figure,n: Vector3i,layout: FloorLayout,grid: LayeredGrid) -> PackedVector3Array:
	var empty := PackedVector3Array()
	if not grid.open(n) or layout.surface_id(n).begins_with("climb:") or ScenarioNull.field_at(c.state.board,layout.point(n)) or BattleBoundary.blocks_end(c.state.board.boundaries,layout.point(n)):
		return empty
	var b:=layout.world(n)
	if not MovementContact.enemies_at(c.state.figures,t,layout.point(n),b.y,layout.surface_id(n)).is_empty():
		return empty
	return trajectory(c,t,b,layout)


## Flight budget is measured to the declared endpoint, not the eventual floor.
static func trajectory(c: GameController,t: Figure,b: Vector3,layout: FloorLayout) -> PackedVector3Array:
	var empty:=PackedVector3Array()
	var a:=BattleSpace.center(t)
	var at:=Vector2(b.x,b.z)
	var limit:=5.0 if t.treasure_id>=0 else 10.0
	if not b.is_finite() or a.distance_to(b)<0.1 or a.distance_to(b)>limit+0.001 or not c.state.board.contains(at,Figure.BASE_RADIUS):
		return empty
	if RedKingBridge.crosses_void(c.state.board,t.pos,at) or c.state.board.over_void(at,Figure.BASE_RADIUS) or BattleBoundary.blocks_segment(c.state.board.boundaries,t.pos,at,"movement",t) or BattleBoundary.blocks_end(c.state.board.boundaries,at):
		return empty
	# A straight trajectory is preferred. Test several bounded vertical arcs
	# without allowing horizontal curves around obstacles.
	for rise: float in [0.0,1.0,2.0,3.0]:
		var points := PackedVector3Array([a])
		var steps := maxi(2,ceili((a.distance_to(b)+rise*2.0)/0.1))
		var length := 0.0
		var clear := true
		for i in range(1,steps+1):
			var ratio := float(i)/steps
			var p := a.lerp(b,ratio)+Vector3.UP*(4.0*rise*ratio*(1.0-ratio))
			if ScenarioNull.field_at(c.state.board,Vector2(p.x,p.z)) or TerrainMagic.ward_blocks(c.state.board,t,Vector2(p.x,p.z),p.y) or not layout.clearance(p,Figure.BASE_RADIUS,1.6):
				clear=false
				break
			length+=points[points.size()-1].distance_to(p)
			points.append(p)
		if clear and length<=limit+0.001:
			return points
	return empty


## The fall is mandatory and costs no additional Leap distance. A blocked
## first supporting floor cannot be skipped to reach a lower one.
static func air_plan(c: GameController,t: Figure,endpoint: Vector3,layout: FloorLayout,grid: LayeredGrid) -> Dictionary:
	if not endpoint.is_finite():
		return {}
	var at:=Vector2(endpoint.x,endpoint.z)
	if not MoveGrid.to_pos(MovePlanner.node_at(at)).is_equal_approx(at):
		return {}
	var landing: Variant=LayeredFall.landing(layout,grid,at,endpoint.y)
	if landing==null:
		return {}
	var dest:=layout.world(landing)
	var fall:=endpoint.y-dest.y
	if fall<=0.001 or not BattlePlacement.floor_open(c.state,landing,t,Figure.BASE_RADIUS,1.6,false):
		return {}
	var points:=trajectory(c,t,endpoint,layout)
	if points.is_empty():
		return {}
	var steps:=maxi(1,ceili(fall*10.0))
	for i in range(1,steps+1):
		var p:=endpoint.lerp(dest,float(i)/steps)
		if ScenarioNull.field_at(c.state.board,at) or TerrainMagic.ward_blocks(c.state.board,t,at,p.y):
			return {}
	points.append(dest)
	return {"node":landing,"path":points,"fall":fall,"damage":LayeredFall.damage(c.state,t,fall)}


static func air_points(c: GameController,t: Figure,index: int,offset: float) -> Dictionary:
	var out: Dictionary={}
	if not eligible(c,t) or offset<=0.0:
		return out
	var layout:=c.state.board.floor_geometry()
	var grid:=LayeredGrid.new(layout,t,c.state.figures)
	var limit:=5.0 if t.treasure_id>=0 else 10.0
	for n in BattlePlacement.nodes(c.state.board,t.pos,limit,index):
		if not grid.open(n):
			continue
		var endpoint:=layout.world(n)+Vector3.UP*offset
		var plan:=air_plan(c,t,endpoint,layout,grid)
		if not plan.is_empty() and plan["node"]==n:
			out[n]=endpoint
	return out


static func start_air(c: GameController,t: Figure,endpoint: Vector3) -> bool:
	if not eligible(c,t):
		return false
	var layout:=c.state.board.floor_geometry()
	var plan:=air_plan(c,t,endpoint,layout,LayeredGrid.new(layout,t,c.state.figures))
	if plan.is_empty():
		return false
	var n: Vector3i=plan["node"]
	return c._magic._roll("leap",t.id,null,false,-1,{"floor_destination":n,"surface_id":layout.surface_id(n),"air_endpoint":endpoint})


## Shared bounded destination provider for menus, floor selection and bots.
static func points(c: GameController,t: Figure,first_only: bool=false,index: int=-1) -> Array[Vector3i]:
	var out: Array[Vector3i]=[]
	if not eligible(c,t):
		return out
	var layout:=c.state.board.floor_geometry()
	var grid:=LayeredGrid.new(layout,t,c.state.figures)
	var limit:=5.0 if t.treasure_id>=0 else 10.0
	for n in BattlePlacement.nodes(c.state.board,t.pos,limit,index):
		if not path(c,t,n,layout,grid).is_empty():
			out.append(n)
			if first_only:
				break
	return out


static func start(c: GameController,t: Figure,n: Vector3i) -> bool:
	if not eligible(c,t):
		return false
	var layout := c.state.board.floor_geometry()
	var points := path(c,t,n,layout,LayeredGrid.new(layout,t,c.state.figures))
	if points.is_empty():
		return false
	return c._magic._roll("leap",t.id,null,false,-1,{"floor_destination":n,"surface_id":layout.surface_id(n),"leap_path":points})


static func apply(c: GameController,t: Figure,effect: Dictionary) -> void:
	var layout := c.state.board.floor_geometry()
	var saved: Vector3i=effect["floor_destination"]
	var n:=layout.node(str(effect["surface_id"]),MoveGrid.to_pos(Vector2i(saved.x,saved.y)))
	if effect.has("air_endpoint"):
		var plan:=air_plan(c,t,effect["air_endpoint"],layout,LayeredGrid.new(layout,t,c.state.figures))
		if not plan.is_empty():
			c._magic.movement.move_floor(t,plan["node"],true,true,"leap",plan["path"],true,float(plan["fall"]))
		return
	var points:=path(c,t,n,layout,LayeredGrid.new(layout,t,c.state.figures))
	if points.is_empty():
		return
	c._magic.movement.move_floor(t,n,true,false,"leap",points)
