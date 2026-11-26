class_name TerrainPiece
extends RefCounted
## A terrain piece on the table: an axis-aligned footprint in inches.

var kind: TerrainKind
var rect := Rect2()
var circular := false
var cast_turn := -1
var caster_id := -1


func _init(k: TerrainKind = null, r: Rect2 = Rect2()) -> void:
	kind = k
	rect = r


func contains(p: Vector2) -> bool:
	return p.distance_to(rect.get_center()) <= rect.size.x * 0.5 if circular else rect.has_point(p)
