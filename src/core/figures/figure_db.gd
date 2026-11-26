class_name FigureDb
extends RefCounted
## Weapons and figure stat lines loaded from data/.

const FIGURES := "res://data/figures.json"
const WEAPONS := "res://data/weapons.json"

var weapons := {}
var figures := {}
var content_profile := ContentProfile.new()


static func load_files(fig_path: String = FIGURES, weapon_path: String = WEAPONS,profile: ContentProfile=null) -> FigureDb:
	var db := FigureDb.new()
	if profile!=null:
		db.content_profile=profile
	var wd: Dictionary = JsonFile.read(weapon_path)
	for key: String in wd:
		if not key.begins_with("_"):
			db.weapons[key] = WeaponDef.from_dict(key, wd[key])
	var fd: Dictionary = JsonFile.read(fig_path)
	if fig_path==FIGURES:
		for pack_id: String in db.content_profile.enabled:
			var pack: Dictionary=db.content_profile.packs.get(pack_id,{})
			if pack.get("status","ready")!="ready":
				continue
			var path := str(pack.get("catalogs",{}).get("figures",""))
			if not path.is_empty():
				var optional: Dictionary=JsonFile.read(path)
				for id: String in optional:
					if db.content_profile.allows("figures",id) and not fd.has(id):
						fd[id]=optional[id]
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


func available(id: String) -> bool:
	if not figures.has(id) or not content_profile.allows("figures",id):
		return false
	for weapon in get_def(id).weapons:
		if not content_profile.allows("weapons",weapon.id):
			return false
	return true
