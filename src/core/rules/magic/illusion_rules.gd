class_name IllusionRules
extends RefCounted


static func visible_to(figures: Array[Figure], observer: Figure, target: Figure) -> bool:
	if target.spell_effects.has("plane_walk"):
		return false
	if observer == target:
		return true
	if target.spell_effects.has("potion_chameleon") and Shooting.distance(observer, target) > 12.0:
		return false
	if not target.spell_effects.has("invisibility") or observer.def.traits.has("true_sight") or observer.spell_effects.has("potion_clearsight"):
		return true
	for f in figures:
		if f.in_play() and f.side == observer.side and f.spell_effects.has("true_sight") and Shooting.distance(f, observer) <= 6.0:
			return true
	return false


static func phantom(f: Figure) -> bool:
	return f.summon_spell == "illusionary_soldier"
