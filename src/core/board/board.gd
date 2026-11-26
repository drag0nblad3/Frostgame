class_name Board
extends RefCounted
## The table: size in inches plus terrain pieces. Origin is the bottom-left corner.

var id := ""
var name := ""
var size := Vector2(36, 36)
var pieces: Array[TerrainPiece] = []


func contains(p: Vector2, margin: float = 0.0) -> bool:
	return p.x >= margin and p.y >= margin and p.x <= size.x - margin and p.y <= size.y - margin


## Pieces whose footprint contains `p`.
func pieces_at(p: Vector2) -> Array[TerrainPiece]:
	var out: Array[TerrainPiece] = []
	for piece in pieces:
		if piece.rect.has_point(p):
			out.append(piece)
	return out


## Movement cost multiplier at a point (the worst piece there).
func move_mult_at(p: Vector2) -> float:
	var key: Variant = _key(p)
	if key != null and _mult_cache.has(key):
		return _mult_cache[key]
	var m := 1.0
	for piece in pieces_at(p):
		m = maxf(m, piece.kind.move_mult)
	if key != null:
		_mult_cache[key] = m
	return m


## True if a figure with this base radius can stand at `p`.
func can_stand(p: Vector2, radius: float) -> bool:
	var key: Variant = _key(p) if is_equal_approx(radius, Figure.BASE_RADIUS) else null
	if key != null and _stand_cache.has(key):
		return _stand_cache[key]
	var ok := _can_stand(p, radius)
	if key != null:
		_stand_cache[key] = ok
	return ok


## Terrain never moves, so answers on the quarter-inch lattice (where move
## searches look) are cached. Off-lattice points are computed each time.
var _stand_cache := {}
var _mult_cache := {}
## Bot distance fields by target node (see MovePlanner.distance_field).
var field_cache := {}


func _key(p: Vector2) -> Variant:
	var q := p * 4.0
	if is_equal_approx(q.x, roundf(q.x)) and is_equal_approx(q.y, roundf(q.y)):
		return Vector2i(roundi(q.x), roundi(q.y))
	return null


func _can_stand(p: Vector2, radius: float) -> bool:
	if not contains(p, radius):
		return false
	for piece in pieces:
		if piece.kind.blocks_move and piece.rect.grow(radius).has_point(p):
			return false
	return true
