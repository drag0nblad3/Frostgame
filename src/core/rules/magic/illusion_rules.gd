class_name IllusionRules
extends RefCounted


static func visible_to(figures: Array[Figure], observer: Figure, target: Figure) -> bool:
	if observer == target or not target.spell_effects.has("invisibility") or observer.def.traits.has("true_sight"):
		return true
	for f in figures:
		if f.in_play() and f.side == observer.side and f.spell_effects.has("true_sight") and Shooting.distance(f, observer) <= 6.0:
			return true
	return false


static func phantom(f: Figure) -> bool:
	return f.summon_spell == "illusionary_soldier"
