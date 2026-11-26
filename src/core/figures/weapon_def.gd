class_name WeaponDef
extends RefCounted
## A weapon (data/weapons.json). Melee weapons have `melee`; ranged ones a `range`.

var id := ""
var name := ""
var melee := false
## Maximum range in inches; 0 for melee weapons.
var range_in := 0.0
var fight_mod := 0
var damage_mod := 0
## Damage modifier applied to blows struck against the wielder in melee.
var enemy_damage_mod := 0
var needs_reload := false


static func from_dict(weapon_id: String, d: Dictionary) -> WeaponDef:
	var w := WeaponDef.new()
	w.id = weapon_id
	w.name = d.get("name", weapon_id)
	w.melee = d.get("melee", false)
	w.range_in = float(d.get("range", 0))
	w.fight_mod = int(d.get("fight", 0))
	w.damage_mod = int(d.get("damage", 0))
	w.enemy_damage_mod = int(d.get("enemy_damage", 0))
	w.needs_reload = d.get("reload", false)
	return w


func is_ranged() -> bool:
	return range_in > 0.0
