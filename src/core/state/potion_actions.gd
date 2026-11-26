class_name PotionActions
extends RefCounted

var c: GameController
var catalog: Dictionary


func _init(controller: GameController) -> void:
	c = controller
	catalog = CampaignInventory.catalog()


func can_drink(id: String, target: Figure = null) -> bool:
	var f := c.state.active()
	if f == null or not f.in_play() or f.spell_effects.has("plane_walk") or f.actions_left <= 0 or c.awaiting_reaction() or not c.state.pending_cast.is_empty() or c.state.group.movement_pass() or Contact.in_combat(c.state.figures, f):
		return false
	if f.moves_taken > 0 and not c.can_act():
		return false
	if not catalog.has(id) or not catalog[id]["live"]:
		return false
	if target == null:
		target = f
	if target != f and (f.def.id != "apothecary" or not target.in_play() or target.side != f.side or Shooting.distance(f, target) > 1.0):
		return false
	if id == "healing" and target.health >= target.def.health:
		return false
	for item in f.items:
		if item.get("potion", "") == id:
			return true
	return false


func drink(id: String, target: Figure = null) -> bool:
	var f := c.state.active()
	if target == null:
		target = f
	if not can_drink(id, target):
		return false
	for i in f.items.size():
		if f.items[i].get("potion", "") == id:
			f.items.remove_at(i)
			break
	if f.moves_taken == 0 and not c.state.group.in_progress():
		f.actions_left -= 1
	else:
		c._spend(f)
	match id:
		"healing":
			c._magic._heal(target, 5)
		"restoration":
			c._magic._heal(target, target.def.health)
			target.poisoned = false
			for effect in ["slow", "curse", "furious_quill", "petrify", "blinding_light"]:
				target.spell_effects.erase(effect)
			target.petrified_skip = false
		"invisibility":
			target.spell_effects["invisibility"] = true
			c._magic.illusions.sweep()
		_:
			target.spell_effects["potion_" + id] = true
	c.emit("potion_used", {"id": f.id, "target": target.id, "potion": id})
	c.emit("spell_effect", {"id": target.id, "spell": "potion_" + id})
	return true
