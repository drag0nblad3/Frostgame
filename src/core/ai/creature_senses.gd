class_name CreatureSenses
extends RefCounted
## Movement-only perception; never bypasses line of sight for attacks.
static func detects(observer: Figure,target: Figure) -> bool:
	if not observer.in_play() or not target.in_play():
		return false
	var distance := Shooting.distance(observer,target)
	if observer.def.traits.has("sense_magic") and target.def.role in ["wizard","apprentice"] and distance<=12.0:
		return true
	return observer.def.traits.has("keen_senses") and distance<=6.0
