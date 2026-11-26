class_name GameEvent
extends RefCounted
## Something that happened in the game, for the view and the log.

var type := ""
var data := {}


func _init(t: String = "", d: Dictionary = {}) -> void:
	type = t
	data = d


func _to_string() -> String:
	return "%s %s" % [type, data]
