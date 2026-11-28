class_name LayeredJump
extends RefCounted
## An authored gap, with a straight run-up of at least the jump distance.
## Run-up and jump are both paid from the same movement action.


static func plans(c: GameController,generate: bool=false,continuation: bool=false,shared_grid: LayeredGrid=null,cape: bool=false) -> Dictionary:
	var out := {}
	if not LayeredMovement.eligible(c,cape) or (not generate and c.state.board.floor_layout.get("jumps",[]).is_empty()):
		return out
	var s := c.state
	var f := s.active()
	if FuryRules.target(s,f)!=null or PlaneWalk.uses_direct(f):
		return out
	var layout := s.board.floor_geometry()
	if not layout.errors.is_empty():
		return out
	var grid:=shared_grid if shared_grid!=null else LayeredGrid.new(layout,f,s.figures)
	grid.memoize_edges=continuation
	var start := layout.node(f.surface_id,f.pos)
	if not grid.open(start):
		return out
	var direct:=from_position(c,layout,grid,start,MoveRules.allowance(f),generate,cape)
	return LayeredMovement.extend_aerial(c,LayeredMovement.chain_aerial(c,direct,grid),grid) if continuation else direct


## Query from a hypothetical landing without changing the live figure.
static func from_position(c: GameController,layout: FloorLayout,grid: LayeredGrid,start: Vector3i,allowance: float,generate: bool=true,leave_contact: bool=false) -> Dictionary:
	var out: Dictionary={}
	var s:=c.state
	var f:=s.active()
	if not grid.open(start) or (grid.stops(start) and not leave_contact):
		return out
	var entries: Array=s.board.floor_layout.get("jumps",[]).duplicate()
	if generate:
		entries.append_array(_generated(c,layout,grid,start,allowance))
	for entry: Dictionary in entries:
		var from: Array = entry.get("from",[])
		var to: Array = entry.get("to",[])
		if from.size()!=3 or to.size()!=3:
			continue
		var takeoff := layout.node(str(from[0]),Vector2(from[1],from[2]))
		var target := layout.node(str(to[0]),Vector2(to[1],to[2]))
		if not grid.open(takeoff) or not grid.open(target) or start.z!=takeoff.z:
			continue
		if layout.height(target)>layout.height(takeoff)+0.001:
			continue
		var delta := layout.point(target)-layout.point(takeoff)
		var distance := delta.length()
		if distance<=0.001 or distance>allowance+0.001:
			continue
		var run := layout.point(takeoff)-layout.point(start)
		if (distance>1.001 and run.length()+0.001<distance) or (run.length()>0.001 and run.normalized().dot(delta.normalized())<0.999):
			continue
		var path := PackedVector3Array()
		var cost := distance
		var valid := true
		var steps := maxi(1,ceili(run.length()/0.1))
		for i in range(steps+1):
			var p := layout.point(start).lerp(layout.point(takeoff),float(i)/steps)
			var h := layout.surfaces[start.z].height_at(p)
			if s.board.over_void(p,Figure.BASE_RADIUS) or not grid.segment_allowed(layout.world(start),Vector3(p.x,h,p.y)) or TerrainMagic.ward_blocks(s.board,f,p,h) or not layout.surfaces[start.z].contains(p,Figure.BASE_RADIUS) or not layout.clearance(Vector3(p.x,h,p.y),Figure.BASE_RADIUS,1.6) or not is_equal_approx(h,layout.height(start)):
				valid=false
				break
			for other in grid.others:
				if absf(other.elevation-h)<0.5 and (other.pos.distance_to(p)<Contact.OVERLAP or (other.side!=f.side and Contact.touching(other.pos,p) and not (leave_contact and i==0))):
					valid=false
					break
			if not valid:
				break
			if i>0:
				var previous:=layout.point(start).lerp(layout.point(takeoff),float(i-1)/steps)
				var multiplier:=maxf(layout.surfaces[start.z].rough,TerrainMagic.floor_multiplier(s.board,(previous+p)*0.5,h,f))
				if f.levitates() or f.def.traits.has("flying") or s.board.low_gravity:
					multiplier=1.0
				cost+=previous.distance_to(p)*multiplier
		if not valid or cost>allowance+0.001:
			continue
		var a := layout.world(takeoff)
		var b := layout.world(target)
		if not LayeredFall.voluntary_allowed(s,f,a.y-b.y):
			continue
		path.append(layout.world(start))
		path.append(a)
		steps=maxi(2,ceili(distance/0.1))
		for i in range(1,steps):
			var t := float(i)/steps
			# A modest arc; descending figures remain high until reaching the edge.
			var p := a.lerp(Vector3(b.x,a.y,b.z),t)+Vector3.UP*(2.0*t*(1.0-t))
			if not layout.clearance(p,Figure.BASE_RADIUS,1.6):
				valid=false
				break
			path.append(p)
		if not valid or not grid.segment_allowed(a,b) or not LayeredFall.clear_descent(layout,b,a.y):
			continue
		path.append(Vector3(b.x,a.y,b.z))
		path.append(b)
		if not out.has(target) or cost<float(out[target]["cost"]):
			var grounded:=PackedVector3Array([layout.world(start)])
			var stride:=maxi(absi(takeoff.x-start.x),absi(takeoff.y-start.y))
			for step in range(1,stride+1):
				var p:=layout.point(start).lerp(layout.point(takeoff),float(step)/stride)
				var node:=layout.node(layout.surface_id(start),p)
				if layout.point(node).is_equal_approx(p):
					grounded.append(layout.world(node))
			var arc:=path.duplicate()
			arc.remove_at(0)
			var preview:=grounded.duplicate()
			for i in range(1,arc.size()):
				preview.append(arc[i])
			out[target]={"path":path,"arc":arc,"preview":preview,"approach_cost":cost-distance,"cost":cost,"fall":a.y-b.y,"grounded":grounded,"surface":layout.surface_id(target),"jump":true}
	return out


static func move(c: GameController,n: Vector3i) -> bool:
	var options := plans(c,true,true)
	if not options.has(n):
		return false
	var f := c.state.active()
	var layout := c.state.board.floor_geometry()
	var plan: Dictionary = options[n]
	var targets:=MovementContact.enemies_at(c.state.figures,f,layout.point(n),layout.height(n),layout.surface_id(n))
	c._magic.beauty.authorize(f,targets,_land.bind(c,f,n,plan))
	return true


static func _land(c: GameController,f: Figure,_n: Vector3i,plan: Dictionary) -> void:
	if not f.in_play() or c.state.active()!=f or not RedKingHill.before_move(c,f):
		return
	LayeredMovement.offer_aerial(c,f,plan)


## Additional primitive lattice vectors give oblique crossings without
## scanning every pair of points on the board.
const OBLIQUE: Array[Vector2i]=[
	Vector2i(2,1),Vector2i(2,-1),Vector2i(-2,1),Vector2i(-2,-1),
	Vector2i(1,2),Vector2i(1,-2),Vector2i(-1,2),Vector2i(-1,-2)
]


## Test actual support along the ray, not just its next lattice endpoint.
static func _continuous_support(c: GameController,layout: FloorLayout,from: Vector3i,to: Vector3i,height: float) -> bool:
	var support:=layout.surfaces[from.z]
	var a:=layout.point(from)
	var b:=layout.point(to)
	var steps:=maxi(1,ceili(a.distance_to(b)*10.0))
	for i in range(1,steps+1):
		var p:=a.lerp(b,float(i)/steps)
		if not support.contains(p,Figure.BASE_RADIUS) or absf(support.height_at(p)-height)>0.001 or c.state.board.over_void(p,Figure.BASE_RADIUS):
			return false
	return true


## Only interruptions in support generate jump candidates. The ray search
## remains bounded by movement allowance and never pairs all map nodes.
static func _generated(c: GameController,layout: FloorLayout,grid: LayeredGrid,start: Vector3i,allowance: float) -> Array[Dictionary]:
	var out: Array[Dictionary]=[]
	var f:=c.state.active()
	var support:=layout.surfaces[start.z]
	if support.id.begins_with("climb:"):
		return out
	if support.id=="street" and support.profiles.is_empty() and c.state.board.void_regions.is_empty():
		return out
	var max_jump:=allowance
	var height:=layout.height(start)
	var decks: Array[int]=[]
	for i in layout.surfaces.size():
		if not layout.surfaces[i].id.begins_with("climb:"):
			decks.append(i)
	var directions: Array[Vector2i]=[]
	directions.assign(MoveGrid.NEIGHBORS)
	directions.append_array(OBLIQUE)
	for direction: Vector2i in directions:
		var delta:=Vector3i(direction.x,direction.y,0)
		var step:=Vector2(direction).length()*MoveGrid.STEP
		var takeoff:=start
		for run_steps in range(floori(allowance/step)+1):
			takeoff=start+delta*run_steps
			if not grid.open(takeoff) or not is_equal_approx(layout.height(takeoff),height):
				break
			var next:=takeoff+delta
			var next_at:=layout.point(next)
			if layout.standable(next) and _continuous_support(c,layout,takeoff,next,height):
				continue
			if layout.clearance(Vector3(next_at.x,height,next_at.y),Figure.BASE_RADIUS,1.6)==false:
				continue
			var run:=step*run_steps
			var limit:=minf(max_jump,minf(maxf(1.0,run),allowance-run))
			for jump_steps in range(1,floori((limit+0.001)/step)+1):
				var xy:=takeoff+delta*jump_steps
				var at:=layout.point(xy)
				for deck in decks:
					var target:=Vector3i(xy.x,xy.y,deck)
					if not layout.contains(target) or not grid.open(target) or layout.height(target)>height+0.001 or (deck==start.z and layout.height(target)<height-0.5):
						continue
					# Prefer same-level gap crossings. Ordinary downward
					# ledge movement belongs to explicit voluntary falls.
					if layout.height(target)<height-0.5:
						continue
					out.append({"from":[support.id,layout.point(takeoff).x,layout.point(takeoff).y],"to":[layout.surface_id(target),at.x,at.y]})
			break
	return out
