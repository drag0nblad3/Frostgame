class_name MoveReach
extends RefCounted
## Result of a movement search: cost to every reachable node and the way back.

var start := Vector2.ZERO
var cost := {}
var prev := {}


func can_reach(n: Vector2i) -> bool:
	return cost.has(n)


func nodes() -> Array:
	return cost.keys()


## Path from the start position to node `n` (start included).
func path_to(n: Vector2i) -> PackedVector2Array:
	var pts := PackedVector2Array()
	if not cost.has(n):
		return pts
	var cur: Variant = n
	while cur != null:
		pts.append(MoveGrid.to_pos(cur))
		cur = prev.get(cur)
	pts.append(start)
	pts.reverse()
	return pts
