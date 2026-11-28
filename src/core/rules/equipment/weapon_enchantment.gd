class_name WeaponEnchantment
extends RefCounted
## Core p.121: a weapon is the target, not the figure. Keep the effect
## under the existing spell key so anti-magic and null-field cleanup work.
const KEY := "enchant_weapon"

static func ids(f: Figure) -> Array[String]:
	var out: Array[String]=[]
	var data: Variant=f.spell_effects.get(KEY,false)
	if data is Array:
		for id in data:
			if not f.destroyed_weapons.has(str(id)):
				out.append(str(id))
	elif data==true:
		# Compatibility with checkpoints from before individual enchantments.
		var w:=f.ranged if f.ranged!=null else f.melee
		if w!=null and not f.destroyed_weapons.has(w.id):
			out.append(w.id)
	return out

static func migrate(f: Figure) -> void:
	if f.spell_effects.get(KEY,false)==true:
		f.spell_effects[KEY]=ids(f)

static func active(f: Figure,w: WeaponDef) -> bool:
	return w!=null and not MagicEquipment.suppressed(f) and ids(f).has(w.id)

static func options(f: Figure) -> Array[WeaponDef]:
	var out: Array[WeaponDef]=[]
	if f==null:
		return out
	var existing:=ids(f)
	for w in f.def.weapons:
		if w.id not in ["unarmed","natural"] and not f.destroyed_weapons.has(w.id) and not existing.has(w.id) and not out.has(w):
			out.append(w)
	return out

static func add(f: Figure,id: String) -> bool:
	for w in options(f):
		if w.id==id:
			var current:=ids(f)
			current.append(id)
			f.spell_effects[KEY]=current
			return true
	return false

static func remove(f: Figure,id: String) -> void:
	var current:=ids(f)
	current.erase(id)
	if current.is_empty():
		f.spell_effects.erase(KEY)
	else:
		f.spell_effects[KEY]=current

static func preferred(f: Figure) -> String:
	var choices:=options(f)
	for w in [f.ranged,f.melee]:
		if w!=null and choices.has(w):
			return w.id
	return choices[0].id if not choices.is_empty() else ""
