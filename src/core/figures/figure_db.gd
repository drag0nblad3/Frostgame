class_name FigureDb
extends RefCounted
## Weapons and figure stat lines loaded from data/.

const FIGURES := "res://data/figures.json"
const WEAPONS := "res://data/weapons.json"

var weapons := {}
var figures := {}


static func load_files(fig_path: String = FIGURES, weapon_path: String = WEAPONS) -> FigureDb:
	var db := FigureDb.new()
	var wd: Dictionary = JsonFile.read(weapon_path)
	for key: String in wd:
		if not key.begins_with("_"):
			db.weapons[key] = WeaponDef.from_dict(key, wd[key])
	var fd: Dictionary = JsonFile.read(fig_path)
	for key: String in fd:
		if not key.begins_with("_"):
			db.figures[key] = FigureDef.from_dict(key, fd[key], db.weapons)
	return db


func get_def(id: String) -> FigureDef:
	if not figures.has(id):
		push_error("FigureDb: unknown figure " + id)
		return null
	return figures[id]


func unarmed() -> WeaponDef:
	return weapons["unarmed"]
