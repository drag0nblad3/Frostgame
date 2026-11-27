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


static func may_contact(observer: Figure,target: Figure) -> bool:
	return observer.def.traits.has("sense_magic") and target.def.role in ["wizard","apprentice"] and target.spell_effects.has("invisibility") and not target.spell_effects.has("plane_walk") and detects(observer,target)


static func reveal_contacts(c: GameController,f: Figure) -> void:
	if not f.in_play() or not f.def.traits.has("sense_magic"):
		return
	for target in Contact.enemies_of(c.state.figures,f):
		if may_contact(f,target):
			c._magic.illusions.reveal(target)
