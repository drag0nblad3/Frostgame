class_name FigureDef
extends RefCounted
## A figure type's stat line (data/figures.json).

var id := ""
var name := ""
## "wizard", "apprentice" or "soldier": decides the activation phase.
var role := "soldier"
var move := 6
var fight := 0
var shoot := 0
var armour := 10
var will := 0
var health := 10
var cost := 0
var specialist := false
var shield := false
var traits: Array[String] = []
var weapons: Array[WeaponDef] = []
## True while the stat line is unchecked against the book.
var verify := false


static func from_dict(fig_id: String, d: Dictionary, weapon_db: Dictionary) -> FigureDef:
	var f := FigureDef.new()
	f.id = fig_id
	f.name = d.get("name", fig_id)
	f.role = d.get("role", "soldier")
	f.move = int(d.get("move", 6))
	f.fight = int(d.get("fight", 0))
	f.shoot = int(d.get("shoot", 0))
	f.armour = int(d.get("armour", 10))
	f.will = int(d.get("will", 0))
	f.health = int(d.get("health", 10))
	f.cost = int(d.get("cost", 0))
	f.specialist = d.get("specialist", false)
	f.shield = d.get("shield", false)
	for trait_id: String in d.get("traits", []):
		f.traits.append(trait_id)
	f.verify = d.get("verify", false)
	for w: String in d.get("weapons", []):
		if weapon_db.has(w):
			f.weapons.append(weapon_db[w])
		else:
			push_error("FigureDef %s: unknown weapon %s" % [fig_id, w])
	return f


## First melee weapon listed, or bare hands.
func melee_weapon(weapon_db: Dictionary) -> WeaponDef:
	for w in weapons:
		if w.melee:
			return w
	return weapon_db.get("unarmed")


## First ranged weapon listed, or null.
func ranged_weapon() -> WeaponDef:
	for w in weapons:
		if w.is_ranged():
			return w
	return null


## Equipment that interferes with carrying loot (p. 68).
func treasure_encumbered() -> bool:
	if shield:
		return true
	for w in weapons:
		if w.is_ranged() or w.id in ["staff", "two_handed"]:
			return true
	return false


## Copy a type before applying per-campaign modifiers; database definitions stay immutable.
func with_bonuses(bonuses: Dictionary) -> FigureDef:
	var copy := FigureDef.new()
	for key in ["id", "name", "role", "move", "fight", "shoot", "armour", "will", "health", "cost", "specialist", "shield", "verify"]:
		copy.set(key, get(key))
	copy.traits.assign(traits)
	copy.weapons.assign(weapons)
	for key in ["move", "fight", "shoot", "armour", "will", "health"]:
		copy.set(key, int(copy.get(key)) + int(bonuses.get(key, 0)))
	return copy
