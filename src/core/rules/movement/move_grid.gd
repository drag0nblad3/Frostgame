class_name MoveGrid
extends RefCounted
## Movement lattice: candidate positions every STEP inches across the table.
## Which nodes are open for one figure's move (other figures block, enemies
## stop the move on contact).

const STEP := 0.5
const NEIGHBORS := [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1),
]

var board: Board
var mover: Figure
var others: Array[Figure] = []
var cols := 0
var rows := 0
var running := false:
	set(value):
		if value != running:
			_open_memo.clear()
		running = value
## Open answers for this search. Figures and terrain don't change mid-search.
var _open_memo := {}
## Uncached open() evaluations since start-up; tests use it as a work budget.
static var evaluations := 0


func _init(b: Board, f: Figure = null, figures: Array[Figure] = []) -> void:
	board = b
	mover = f
	cols = int(b.size.x / STEP) + 1
	rows = int(b.size.y / STEP) + 1
	for o in figures:
		if o.in_play() and o != f and (f==null or o.ring_side==f.ring_side):
			others.append(o)


static func to_pos(n: Vector2i) -> Vector2:
	return Vector2(n.x * STEP, n.y * STEP)


func in_bounds(n: Vector2i) -> bool:
	return n.x >= 0 and n.y >= 0 and n.x < cols and n.y < rows


## A figure could stand here: on the table, off blocking terrain, not on another base.
func open(n: Vector2i) -> bool:
	# Distance fields ignore figures and use the same terrain/boundaries.
	# Keep their open checks across searches until the board invalidates terrain.
	var memo: Dictionary = board.static_open_cache if mover==null and others.is_empty() else _open_memo
	var known: Variant = memo.get(n)
	if known != null:
		return known
	var ok := _open(n)
	evaluations += 1
	memo[n] = ok
	return ok


func _open(n: Vector2i) -> bool:
	if not in_bounds(n):
		return false
	var p := to_pos(n)
	if not board.can_stand(p, Figure.BASE_RADIUS) or TerrainMagic.ward_blocks(board, mover, p) or BattleBoundary.blocks_position(board.boundaries,p,mover):
		return false
	var height := board.height_at(p)
	for o in others:
		if MovementContact.blocks(mover,o,others,p,height,running):
			return false
	return true


## Moving into contact with an enemy ends the move there.
func stops(n: Vector2i) -> bool:
	if mover == null:
		return false
	var p := to_pos(n)
	if mover.side >= 0 and not IllusionRules.phantom(mover) and ScenarioColumns.contact(board, p) != null:
		return true
	var height := board.height_at(p)
	for o in others:
		if o.side != mover.side and Contact.touches_position(o,p,height):
			return true
	return false


## Cost in inches of stepping a→b: rough terrain counts double.
func step_cost(a: Vector2i, b: Vector2i) -> float:
	if mover==null and others.is_empty():
		var i := _step_index(a, b)
		if i >= 0:
			var cache := board.static_step_cache
			if i < cache.size() and cache[i] >= 0.0:
				return cache[i]
			var cost := segment_cost(to_pos(a),to_pos(b))
			if i < cache.size():
				board.static_step_cache[i] = cost
			return cost
	return segment_cost(to_pos(a),to_pos(b))


## Flat cache slot for a step from `a` to a neighbour `b`, or -1.
func _step_index(a: Vector2i, b: Vector2i) -> int:
	if not in_bounds(a):
		return -1
	var d := NEIGHBORS.find(b - a)
	return -1 if d < 0 else (a.x * rows + a.y) * 8 + d


func segment_cost(pa: Vector2, pb: Vector2) -> float:
	if BattleBoundary.blocks_segment(board.boundaries,pa,pb,"movement",mover):
		return INF
	var mid := (pa + pb) * 0.5
	if not board.can_stand(mid, Figure.BASE_RADIUS) or TerrainMagic.ward_blocks(board, mover, mid):
		return INF
	if running:
		if not MovementContact.run_clear(mover,others,pa,pb,board.height_at(mid)):
			return INF
		if ScenarioColumns.contact(board,mid)!=null:
			return INF
		if board.has_ground_profiles or board.has_ramps:
			return TerrainTravel.cost(board,pa,pb,mover,true)
		return pa.distance_to(pb)+absf(board.height_at(pa)-board.height_at(pb))
	if board.low_gravity:
		return pa.distance_to(pb)
	if board.has_ground_profiles or board.has_ramps:
		return TerrainTravel.cost(board,pa,pb,mover)
	# Ramps are handled by TerrainTravel above (has_ramps), so none can be here.
	var multiplier := 1.0 if mover != null and mover.levitates() else board.move_mult_at(mid)
	return pa.distance_to(pb) * multiplier + board.climb_cost(pa, pb, mover)
