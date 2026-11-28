class_name BattlePlacement
extends RefCounted
## Shared destination geometry. A selected node identifies both the table
## point and its support; callers never infer an upper deck from x/z alone.

static func nodes(board: Board,center: Vector2,radius: float,index: int=-1) -> Array[Vector3i]:
	var out: Array[Vector3i]=[]
	var layout:=board.floor_geometry()
	var origin:=MovePlanner.node_at(center)
	var reach:=ceili(radius/MoveGrid.STEP)
	for i in layout.surfaces.size():
		if index>=0 and i!=index:
			continue
		var surface:=layout.surfaces[i]
		if surface.id.begins_with("climb:"):
			continue
		for x in range(maxi(origin.x-reach,ceili(surface.rect.position.x/MoveGrid.STEP)),mini(origin.x+reach,floori(surface.rect.end.x/MoveGrid.STEP))+1):
			for y in range(maxi(origin.y-reach,ceili(surface.rect.position.y/MoveGrid.STEP)),mini(origin.y+reach,floori(surface.rect.end.y/MoveGrid.STEP))+1):
				out.append(Vector3i(x,y,i))
	return out


static func floor_open(s: GameState,n: Vector3i,mover: Figure=null,radius: float=Figure.BASE_RADIUS,body: float=1.6,allow_combat: bool=true,ignore: Figure=null,ring_side: int=-1,ignore_ids: Array=[] ) -> bool:
	var layout:=s.board.floor_geometry()
	if not layout.standable(n,radius,body) or layout.surface_id(n).begins_with("climb:"):
		return false
	var at:=layout.point(n)
	if s.board.over_void(at,radius) or BattleBoundary.blocks_position(s.board.boundaries,at,mover) or BattleBoundary.blocks_end(s.board.boundaries,at):
		return false
	var h:=layout.height(n)
	if TerrainMagic.ward_blocks(s.board,mover,at,h):
		return false
	for other in s.figures:
		if other==mover or other==ignore or ignore_ids.has(other.id) or not other.in_play() or (mover!=null and other.ring_side!=mover.ring_side) or (mover==null and ring_side>=0 and other.ring_side!=ring_side) or absf(other.elevation-h)>=0.5:
			continue
		var distance:=other.pos.distance_to(at)
		if distance<(Contact.OVERLAP if is_equal_approx(radius,Figure.BASE_RADIUS) else Figure.BASE_RADIUS+radius):
			return false
		if not allow_combat and mover!=null and other.side!=mover.side and Contact.touches_position(other,at,h,layout.surface_id(n)):
			return false
	return true


static func teleport_legal(s: GameState,f: Figure,n: Vector3i,limit: float=24.0) -> bool:
	var layout:=s.board.floor_geometry()
	if not floor_open(s,n,f,Figure.BASE_RADIUS,1.6,false) or ScenarioNull.muted(f) or ScenarioNull.field_at(s.board,layout.point(n)):
		return false
	var to:=layout.world(n)
	var from:=Vector3(f.pos.x,f.elevation,f.pos.y)
	return RealityCrackGeometry.world_distance(s.board,from,to)>=0.1 and LineOfSight.floor_point_visible(s.board,layout,f,to,limit)


static func teleports(s: GameState,f: Figure,limit: float=24.0,index: int=-1,first_only: bool=false) -> Array[Vector3i]:
	var out: Array[Vector3i]=[]
	for n in nodes(s.board,f.pos,limit,index):
		if teleport_legal(s,f,n,limit):
			out.append(n)
			if first_only:
				break
	return out


## Authored and edge-spawn positions default to their lowest legal support.
## Explicit surface IDs must resolve without silently selecting another deck.
static func support(s: GameState,at: Vector2,id: String="",radius: float=Figure.BASE_RADIUS,body: float=1.6,check_figures: bool=true) -> Variant:
	var layout:=s.board.floor_geometry()
	# Deployment and scenario placement most often request a known floor.
	# Resolve its index directly instead of scanning all hanging positions.
	if not id.is_empty():
		var n:=layout.node(id,at)
		if n.z<0 or id.begins_with("climb:") or not layout.point(n).is_equal_approx(at) or not layout.standable(n,radius,body) or s.board.over_void(at,radius):
			return null
		if check_figures and not floor_open(s,n,null,radius,body):
			return null
		return n
	var best: Variant=null
	var lowest:=INF
	for surface in layout.surfaces:
		if (not id.is_empty() and surface.id!=id) or surface.id.begins_with("climb:"):
			continue
		var n:=layout.node(surface.id,at)
		if not layout.point(n).is_equal_approx(at) or not layout.standable(n,radius,body) or s.board.over_void(at,radius):
			continue
		if check_figures and not floor_open(s,n,null,radius,body):
			continue
		var h:=layout.height(n)
		if h<lowest:
			best=n
			lowest=h
	return best

## Authored treasure positions are not movement nodes. Preserve their exact
## coordinates (including sub-lattice distances from scenery), while still
## demanding real support and physical clearance. Never infer a climb node.
static func authored_token_surface(s: GameState,at: Vector2,id: String="") -> String:
	var layout:=s.board.floor_geometry()
	var best:=""
	var lowest:=INF
	var radius:=TreasureRules.TOKEN_RADIUS
	if s.board.over_void(at,radius):
		return ""
	for surface in layout.surfaces:
		if (not id.is_empty() and surface.id!=id) or surface.id.begins_with("climb:") or not surface.contains(at,radius):
			continue
		var h:=surface.height_at(at)
		if h<lowest and layout.clearance(Vector3(at.x,h,at.y),radius,0.5):
			best=surface.id
			lowest=h
	return best


## Scenario spawns near a known support never select a deck above or below it.
static func nearby_floor(s: GameState,center: Vector2,height: float,radius: float,surface: String="",mover: Figure=null) -> Array[Vector3i]:
	var out: Array[Vector3i]=[]
	var layout:=s.board.floor_geometry()
	var index:=layout.index_of(surface) if not surface.is_empty() else -1
	if not surface.is_empty() and index<0:
		return out
	for n in nodes(s.board,center,radius,index):
		if layout.point(n).distance_to(center)>radius+0.001 or absf(layout.height(n)-height)>=0.5:
			continue
		if floor_open(s,n,mover):
			out.append(n)
	return out


## Authored ground entrances: prefer the lowest legal support, then the
## nearest position. Never silently spawn on a roof when the street is blocked.
static func nearest_ground(s: GameState,center: Vector2,radius: float,accept: Callable=Callable(),ring_side: int=-1) -> Variant:
	var layout:=s.board.floor_geometry()
	var allowed: Array=s.board.floor_layout.get("spawn_surfaces",s.board.floor_layout.get("exit_surfaces",["street"]))
	var best: Variant=null
	var score:=INF
	for n in nodes(s.board,center,radius):
		var at:=layout.point(n)
		var d:=at.distance_squared_to(center)
		if d>radius*radius+0.001 or d>=score or not allowed.has(layout.surface_id(n)) or (accept.is_valid() and not accept.call(at)) or not floor_open(s,n,null,Figure.BASE_RADIUS,1.6,true,null,ring_side):
			continue
		best=n
		score=d
	return best


static func ground_at(s: GameState,at: Vector2,ring_side: int=-1) -> Variant:
	var layout:=s.board.floor_geometry()
	var allowed: Array=s.board.floor_layout.get("spawn_surfaces",s.board.floor_layout.get("exit_surfaces",["street"]))
	for n in layout.nodes_at(at):
		if layout.point(n).is_equal_approx(at) and allowed.has(layout.surface_id(n)) and floor_open(s,n,null,Figure.BASE_RADIUS,1.6,true,null,ring_side):
			return n
	return null


## A horizontal scenario token displacement must not leave its supporting deck.
static func token_on_support(s: GameState,surface: String,desired: Vector2) -> Variant:
	var layout:=s.board.floor_geometry()
	var n:=layout.node(surface,desired)
	if layout.standable(n,TreasureRules.TOKEN_RADIUS,0.5) and not s.board.over_void(layout.point(n),TreasureRules.TOKEN_RADIUS):
		return n
	return null
