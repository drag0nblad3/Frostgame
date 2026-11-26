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
		if o.in_play() and o != f:
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
	if not board.can_stand(p, Figure.BASE_RADIUS):
		return false
	for o in others:
		if o.pos.distance_to(p) < Contact.OVERLAP:
			return false
	return true


## Moving into contact with an enemy ends the move there.
func stops(n: Vector2i) -> bool:
	if mover == null:
		return false
	var p := to_pos(n)
	for o in others:
		if o.side != mover.side and Contact.touching(o.pos, p):
			return true
	return false


## Cost in inches of stepping a→b: rough terrain counts double.
func step_cost(a: Vector2i, b: Vector2i) -> float:
	var pa := to_pos(a)
	var pb := to_pos(b)
	var mid := (pa + pb) * 0.5
	if not board.can_stand(mid, Figure.BASE_RADIUS):
		return INF
	return pa.distance_to(pb) * board.move_mult_at(mid)
