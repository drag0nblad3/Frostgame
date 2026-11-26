class_name TerrainPiece
extends RefCounted
## A terrain piece on the table: an axis-aligned footprint in inches.

var kind: TerrainKind
var rect := Rect2()


func _init(k: TerrainKind = null, r: Rect2 = Rect2()) -> void:
	kind = k
	rect = r
