class_name IllusionActions
extends RefCounted

var c: GameController


func _init(controller: GameController) -> void:
	c = controller


func reveal(f: Figure) -> void:
	if f.spell_effects.erase("invisibility"):
		c.emit("spell_expired", {"id": f.id, "spell": "invisibility"})


func sweep() -> void:
	for seer in c.state.figures:
		if not seer.in_play() or not seer.spell_effects.has("true_sight"):
			continue
		for t in c.state.figures:
			if not t.in_play() or Shooting.distance(seer, t) > 6.0:
				continue
			reveal(t)
			if IllusionRules.phantom(t):
				c._magic.summons.vanish(t)


func after_move(f: Figure) -> void:
	for t in Contact.enemies_of(c.state.figures, f):
		if (f.def.traits.has("true_sight") or f.spell_effects.has("potion_clearsight")) and IllusionRules.phantom(t):
			c._magic.summons.vanish(t)
		elif (t.def.traits.has("true_sight") or t.spell_effects.has("potion_clearsight")) and IllusionRules.phantom(f):
			c._magic.summons.vanish(f)
	if Contact.in_combat(c.state.figures, f):
		reveal(f)
	sweep()
