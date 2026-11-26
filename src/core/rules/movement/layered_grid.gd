class_name LayeredGrid
extends RefCounted
## Experimental floor-aware graph. Legacy MoveGrid remains unchanged.
var layout: FloorLayout
var mover: Figure
var others: Array[Figure] = []
var null_boundary := false
var null_board: Board
var _open_cache := {}


func _init(floors: FloorLayout,f: Figure = null,figures: Array[Figure] = []) -> void:
	layout=floors
	mover=f
	if f!=null and f.battle_ref!=null:
		var s: GameState = f.battle_ref.get_ref()
		if s!=null and s.board.floor_layout.has("null_regions"):
			null_board=s.board
			null_boundary=not ScenarioNull.field_at(null_board,f.pos) and (not f.spell_effects.is_empty() or f.elemental_shield>0 or f.controller_id>=0 or f.familiar)
	for other in figures:
		if other!=f and other.in_play():
			others.append(other)


func open(n: Vector3i) -> bool:
	if not _open_cache.has(n):
		_open_cache[n]=_compute_open(n)
	return _open_cache[n]


func _compute_open(n: Vector3i) -> bool:
	if not layout.standable(n):
		return false
	var at := layout.world(n)
	for other in others:
		if absf(other.elevation-at.y)<0.5 and other.pos.distance_to(layout.point(n))<Contact.OVERLAP:
			return false
	return true


func stops(n: Vector3i) -> bool:
	if mover==null:
		return false
	if null_boundary and ScenarioNull.field_at(null_board,layout.point(n)):
		return true
	for other in others:
		if other.side!=mover.side and absf(other.elevation-layout.height(n))<0.5 and Contact.touching(other.pos,layout.point(n)):
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
		if not layout.clearance(start.lerp(finish,0.5),Figure.BASE_RADIUS,1.6):
			continue
		var mult := layout.surfaces[n.z].rough
		if mover!=null and mover.levitates():
			mult=1.0
		out.append({"to":next,"cost":start.distance_to(finish)*mult})
	for edge: Dictionary in layout.links.get(n,[]):
		var next: Vector3i = edge["to"]
		if not open(next):
			continue
		var cost: float = edge["cost"]
		if edge["kind"]=="climb" and mover!=null and (mover.def.traits.has("expert_climber") or mover.levitates()):
			cost=layout.point(n).distance_to(layout.point(next))+ceilf(absf(layout.height(n)-layout.height(next)))
		out.append({"to":next,"cost":cost})
	return out
