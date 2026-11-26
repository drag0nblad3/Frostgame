class_name Shatterstar
extends RefCounted

var first := {}
var next := {}
var spent := false
var resolving := false


func eligible(f: Figure, s: GameState, id: String) -> bool:
	return f.spell_effects.has("potion_shatterstar") and s.spellbooks.get(f.side, {}).has(id)


func clear() -> void:
	first.clear()
	next.clear()
	spent = false


func declare(f: Figure, id: String, target: int, at: Variant, rotated: bool, second: int, effect: Dictionary) -> Dictionary:
	var entry := {"caster": f.id, "id": id, "target": target, "at": at, "rotated": rotated, "second": second, "effect": effect}
	if first.is_empty():
		first = entry
		return {}
	if first["id"] != id or first["caster"] != f.id:
		return {}
	var initial := first
	first = {}
	next = entry
	spent = false
	f.spell_effects.erase("potion_shatterstar")
	return initial
