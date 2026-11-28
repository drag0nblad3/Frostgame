class_name LayeredDrop
extends RefCounted
## Explicit voluntary fall (core p.50), from a current ledge or hanging
## position. Never add damaging descents to normal safe movement previews.

static func plans(c: GameController,continuation: bool=false) -> Dictionary:
	var out: Dictionary={}
	if not LayeredMovement.eligible(c):
		return out
	var s:=c.state
	var f:=s.active()
	if FuryRules.target(s,f)!=null or PlaneWalk.uses_direct(f):
		return out
	var layout:=s.board.floor_geometry()
	var start:=layout.node(f.surface_id,f.pos)
	if not layout.standable(start):
		return out
	var grid:=LayeredGrid.new(layout,f,s.figures)
	grid.memoize_edges=continuation
	var allowance:=MoveRules.allowance(f)
	var direct:=from_position(c,layout,grid,start,allowance,continuation,true)
	return LayeredMovement.extend_aerial(c,LayeredMovement.chain_aerial(c,direct,grid),grid) if continuation else direct


static func from_position(c: GameController,layout: FloorLayout,grid: LayeredGrid,start: Vector3i,allowance: float,approach: bool,allow_long: bool=false) -> Dictionary:
	var out: Dictionary={}
	var s:=c.state
	var f:=s.active()
	if not grid.open(start) or grid.stops(start):
		return out
	var initial: Array[String]=[layout.surface_id(start)]
	_from_ledge(s,f,layout,grid,start,0.0,allowance,PackedVector3Array([layout.world(start)]),initial,out,allow_long)
	if approach:
		var reach:=LayeredReach.search(grid,start,allowance)
		for ledge: Vector3i in reach.cost:
			var approach_cost:=float(reach.cost[ledge])
			if ledge==start or allowance-approach_cost<0.501 or grid.stops(ledge):
				continue
			var support:=layout.surfaces[ledge.z]
			if support.id=="street" and support.profiles.is_empty() and is_equal_approx(support.level,support.end_level):
				continue
			# Most interior points cannot fall; avoid building paths for them.
			if not _near_edge(layout,ledge):
				continue
			var grounded:=PackedVector3Array()
			var surfaces: Array[String]=[]
			for step in reach.path_to(ledge):
				grounded.append(layout.world(step))
				surfaces.append(layout.surface_id(step))
			_from_ledge(s,f,layout,grid,ledge,approach_cost,allowance,grounded,surfaces,out,false)
		return out
	return out


static func _near_edge(layout: FloorLayout,n: Vector3i) -> bool:
	var h:=layout.height(n)
	for d in MoveGrid.NEIGHBORS:
		var other:=n+Vector3i(d.x,d.y,0)
		if not layout.contains(other) or layout.height(other)<h-0.5:
			return true
		if d.x==0 or d.y==0:
			other=n+Vector3i(d.x*2,d.y*2,0)
			if not layout.contains(other) or layout.height(other)<h-0.5:
				return true
	return false


static func _from_ledge(s: GameState,f: Figure,layout: FloorLayout,grid: LayeredGrid,start: Vector3i,approach_cost: float,allowance: float,grounded: PackedVector3Array,surfaces: Array[String],out: Dictionary,allow_long: bool=false) -> void:
	var support:=layout.surfaces[start.z]
	# Ordinary flat ground cannot drop; a profiled street may border a ditch.
	if support.id=="street" and support.profiles.is_empty() and is_equal_approx(support.level,support.end_level):
		return
	var a:=layout.world(start)
	var offsets: Array[Vector2i]=[Vector2i.ZERO]
	offsets.append_array(MoveGrid.NEIGHBORS)
	for d in MoveGrid.NEIGHBORS:
		if d.x==0 or d.y==0:
			offsets.append(d*2)
	for d in offsets:
		var at:=layout.point(start+Vector3i(d.x,d.y,0))
		var same:=layout.node(support.id,at)
		if not support.id.begins_with("climb:") and layout.standable(same) and layout.height(same)>=a.y-0.5:
			continue
		if s.board.over_void(at,Figure.BASE_RADIUS):
			continue
		var n: Variant=LayeredFall.landing(layout,grid,at,a.y)
		if n==null:
			continue
		var b:=layout.world(n)
		var drop:=a.y-b.y
		if drop<=0.5:
			continue
		# A continuous ramp is movement, not a voluntary fall.
		if n.z==start.z:
			var profile:=support.profile_at(layout.point(start))
			if profile!=null and profile.ramp and profile==support.profile_at(at):
				continue
			if support.profiles.is_empty() and not is_equal_approx(support.level,support.end_level):
				continue
		var edge:=Vector3(b.x,a.y,b.z)
		if not grid.segment_allowed(a,edge):
			continue
		var clear:=true
		for i in range(1,5):
			if not layout.clearance(a.lerp(edge,float(i)/4.0),Figure.BASE_RADIUS,1.6):
				clear=false
				break
		if not clear:
			continue
		var cost:=approach_cost+a.distance_to(edge)+drop+(3.0 if s.board.low_gravity else 0.0)
		var long_fall:=drop+(3.0 if s.board.low_gravity else 0.0)>float(f.effective_move())
		if cost>allowance+0.001 and not (allow_long and long_fall and f.moves_taken==0 and approach_cost<=0.001):
			continue
		if out.has(n) and float(out[n]["cost"])<=cost+0.001:
			continue
		var preview:=grounded.duplicate()
		preview.append(edge)
		preview.append(b)
		out[n]={"path":PackedVector3Array([a,edge,b]),"preview":preview,"arc":PackedVector3Array([a,edge,b]),"cost":cost,"approach_cost":approach_cost,"fall":drop,"end_activation":long_fall,"grounded":grounded,"grounded_surfaces":surfaces,"surface":layout.surface_id(n)}


static func move(c: GameController,n: Vector3i) -> bool:
	var options:=plans(c,true)
	if not options.has(n):
		return false
	var f:=c.state.active()
	var layout:=c.state.board.floor_geometry()
	var plan: Dictionary=options[n]
	var targets:=MovementContact.enemies_at(c.state.figures,f,layout.point(n),layout.height(n),layout.surface_id(n))
	c._magic.beauty.authorize(f,targets,_land.bind(c,f,n,plan))
	return true


static func _land(c: GameController,f: Figure,_n: Vector3i,plan: Dictionary) -> void:
	if not f.in_play() or c.state.active()!=f or not RedKingHill.before_move(c,f):
		return
	LayeredMovement.offer_aerial(c,f,plan)


