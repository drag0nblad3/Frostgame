class_name TreasureToken
extends RefCounted
## A scenario objective; carrying, secured and lost are distinct states.

var id: int
var pos: Vector2
var surface_id := ""
var carrier_id := -1
var secured_by := -1
var lost := false
var ever_collected := false
var central := false
var frozen := false


func _init(token_id: int, at: Vector2) -> void:
	id = token_id
	pos = at
	central = token_id == 0


func unresolved() -> bool:
	return secured_by < 0 and not lost


func on_ground() -> bool:
	return unresolved() and carrier_id < 0
