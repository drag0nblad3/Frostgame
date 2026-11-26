class_name TerrainDb
extends RefCounted
## All terrain kinds, keyed by id.

const DEFAULT_PATH := "res://data/terrain.json"

var kinds := {}


static func load_file(path: String = DEFAULT_PATH) -> TerrainDb:
	var db := TerrainDb.new()
	var data: Dictionary = JsonFile.read(path)
	for key: String in data:
		db.kinds[key] = TerrainKind.from_dict(key, data[key])
	return db


func get_kind(id: String) -> TerrainKind:
	if not kinds.has(id):
		push_error("TerrainDb: unknown terrain " + id)
		return null
	return kinds[id]
