class_name CircletDefence
extends RefCounted
const ITEM := "gear_rk_circlet_of_defence"
const SPELLS := ["blinding_light","bones_of_the_earth","curse","destructive_sphere","elemental_ball","elemental_bolt","explosive_rune","glow","mind_control","petrify","push","scatter_shot","slow","steal_health","strike_dead"]


static func binding(f: Figure) -> String:
	if f==null or MagicEquipment.suppressed(f):
		return ""
	for item in f.items:
		if item.get("gear","")==ITEM and SPELLS.has(item.get("casting_spell","")):
			return item["casting_spell"]
	return ""


static func immune(f: Figure,spell: String) -> bool:
	return not spell.is_empty() and binding(f)==spell


static func blocks(c: GameController,f: Figure,spell: String) -> bool:
	if not immune(f,spell):
		return false
	c.emit("gear_used",{"id":f.id,"gear":ITEM,"spell":spell})
	return true


static func prepare(c: GameController) -> void:
	for f in c.state.figures:
		if not binding(f).is_empty():
			f.health=maxi(1,f.health-2)
