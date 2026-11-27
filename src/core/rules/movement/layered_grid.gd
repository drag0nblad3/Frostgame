class_name LayeredGrid
extends RefCounted
## Explicit floor graph, with shared contact and movement restrictions.
var layout: FloorLayout
var mover: Figure
var others: Array[Figure] = []
var null_boundary := false
var null_board: Board
var _open_cache := {}
var running := false:
	set(value):
		if running!=value:
			_open_cache.clear()
		running=value
var board: Board


func _init(floors: FloorLayout,f: Figure = null,figures: Array[Figure] = []) -> void:
	layout=floors
	mover=f
	if f!=null and f.battle_ref!=null:
		var s: GameState = f.battle_ref.get_ref()
		if s!=null:
			board=s.board
		if s!=null and s.board.floor_layout.has("null_regions"):
			null_board=s.board
			null_boundary=not ScenarioNull.field_at(null_board,f.pos) and (not f.spell_effects.is_empty() or f.elemental_shield>0 or f.controller_id>=0 or f.familiar)
	for other in figures:
		if other!=f and other.in_play() and (f==null or f.ring_side==other.ring_side):
			others.append(other)


func open(n: Vector3i) -> bool:
	if not _open_cache.has(n):
		_open_cache[n]=_compute_open(n)
	return _open_cache[n]


func _compute_open(n: Vector3i) -> bool:
	if not layout.standable(n):
		return false
	var at := layout.world(n)
	var point:=layout.point(n)
	if board!=null and (board.over_void(point,Figure.BASE_RADIUS) or BattleBoundary.blocks_position(board.boundaries,point,mover) or TerrainMagic.ward_blocks(board,mover,point,at.y)):
		return false
	for other in others:
		if MovementContact.blocks(mover,other,others,point,at.y,running,layout.surface_id(n)):
			return false
	return true


func stops(n: Vector3i) -> bool:
	if mover==null:
		return false
	if null_boundary and ScenarioNull.field_at(null_board,layout.point(n)):
		return true
	for other in others:
		if other.side!=mover.side and Contact.touches_position(other,layout.point(n),layout.height(n),layout.surface_id(n)):
			return true
	return false


func neighbors(n: Vector3i) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not open(n):
		return out
	var start := layout.world(n)
	for d: Vector2i in MoveGrid.NEIGHBORS:
		var next := n+Vector3i(d.x,d.y,0)
		if not open(next):
			continue
		var finish := layout.world(next)
		if not segment_allowed(start,finish) or (running and not run_segment_clear(start,finish)):
			continue
		if not layout.clearance(start.lerp(finish,0.5),Figure.BASE_RADIUS,1.6):
			continue
		var mult := layout.surfaces[n.z].rough
		if board!=null:
			var middle:=start.lerp(finish,0.5)
			mult=maxf(mult,TerrainMagic.floor_multiplier(board,Vector2(middle.x,middle.z),middle.y))
		if running or (mover!=null and mover.levitates()):
			mult=1.0
		out.append({"to":next,"cost":start.distance_to(finish)*mult})
	for edge: Dictionary in layout.links.get(n,[]):
		var next: Vector3i = edge["to"]
		if not open(next) or not segment_allowed(start,layout.world(next)) or (running and not run_segment_clear(start,layout.world(next))):
			continue
		if not layout.magic_solids.is_empty():
			var finish:=layout.world(next)
			var clear:=true
			var steps:=maxi(1,ceili(start.distance_to(finish)*10.0))
			for i in range(1,steps):
				if not layout.clearance(start.lerp(finish,float(i)/steps),Figure.BASE_RADIUS,1.6):
					clear=false
					break
			if not clear:
				continue
		var cost: float = edge["cost"]
		if edge["kind"]=="climb" and mover!=null and (running or mover.def.traits.has("expert_climber") or mover.levitates()):
			cost=layout.point(n).distance_to(layout.point(next))+ceilf(absf(layout.height(n)-layout.height(next)))
		out.append({"to":next,"cost":cost})
	return out


func segment_allowed(a: Vector3,b: Vector3) -> bool:
	return board==null or not BattleBoundary.blocks_segment(board.boundaries,Vector2(a.x,a.z),Vector2(b.x,b.z),"movement",mover)


func run_segment_clear(a: Vector3,b: Vector3) -> bool:
	return MovementContact.run_clear(mover,others,Vector2(a.x,a.z),Vector2(b.x,b.z),(a.y+b.y)*0.5)
