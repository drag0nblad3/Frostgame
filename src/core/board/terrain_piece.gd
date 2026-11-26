class_name TerrainPiece
extends RefCounted
## A terrain piece on the table: an axis-aligned footprint in inches.

var kind: TerrainKind
var rect := Rect2()
var circular := false
var eye_host: TerrainPiece
var eye_direction := Vector2.ZERO
var ramp := false
var ramp_rotated := false
var level: Variant = null
var ramp_start := 0.0
var ramp_end := 0.0
var cast_turn := -1
var caster_id := -1
var extended_bridge := false
var elemental_wall := false


func _init(k: TerrainKind = null, r: Rect2 = Rect2()) -> void:
	kind = k
	rect = r


func contains(p: Vector2) -> bool:
	return p.distance_to(rect.get_center()) <= rect.size.x * 0.5 if circular else rect.has_point(p)


func surface_height(p: Vector2) -> float:
	if not ramp:
		return float(level) if level != null else kind.height
	var fraction := (p.y - rect.position.y) / rect.size.y if ramp_rotated else (p.x - rect.position.x) / rect.size.x
	return lerpf(ramp_start, ramp_end, clampf(fraction, 0.0, 1.0))
