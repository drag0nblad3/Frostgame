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
	if not in_bounds(n):
		return false
	var p := to_pos(n)
	if not board.can_stand(p, Figure.BASE_RADIUS) or TerrainMagic.ward_blocks(board, mover, p) or BattleBoundary.blocks_position(board.boundaries,p,mover):
		return false
	var height := board.height_at(p)
	for o in others:
		if absf(o.elevation - height) < 0.5:
			var distance := o.pos.distance_to(p)
			if distance < Contact.OVERLAP:
				return false
			if mover != null and o.side != mover.side and distance <= Contact.CONTACT and ((not IllusionRules.visible_to(others, mover, o) and not CreatureSenses.may_contact(mover,o)) or (mover.battle_ref != null and mover.battle_ref.get_ref() != null and BeautyActions.blocked(mover.battle_ref.get_ref(), mover, o))):
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
		if o.side != mover.side and absf(o.elevation - height) < 0.5 and Contact.touching(o.pos, p):
			return true
	return false


## Cost in inches of stepping a→b: rough terrain counts double.
func step_cost(a: Vector2i, b: Vector2i) -> float:
	if mover==null and others.is_empty():
		var key := Vector4i(a.x,a.y,b.x,b.y)
		if board.static_step_cache.has(key):
			return board.static_step_cache[key]
		var cost := segment_cost(to_pos(a),to_pos(b))
		board.static_step_cache[key]=cost
		return cost
	return segment_cost(to_pos(a),to_pos(b))


func segment_cost(pa: Vector2, pb: Vector2) -> float:
	if BattleBoundary.blocks_segment(board.boundaries,pa,pb,"movement",mover):
		return INF
	var mid := (pa + pb) * 0.5
	if not board.can_stand(mid, Figure.BASE_RADIUS) or TerrainMagic.ward_blocks(board, mover, mid):
		return INF
	if board.low_gravity:
		return pa.distance_to(pb)
	if board.has_ground_profiles or board.has_ramps:
		return TerrainTravel.cost(board,pa,pb,mover)
	for p in board.pieces_at(mid):
		if p.ramp and p.contains(pa) and p.contains(pb):
			var delta := board.height_at(pa) - board.height_at(pb)
			return Vector2(pa.distance_to(pb), delta).length()
	var multiplier := 1.0 if mover != null and mover.levitates() else board.move_mult_at(mid)
	return pa.distance_to(pb) * multiplier + board.climb_cost(pa, pb, mover)
