class_name DeathMask
extends RefCounted
const ITEM := "gear_rk_mask_of_death"
const WORN := "rk_death_mask_worn"
const EVER := "rk_death_mask_ever"


static func wearing(f: Figure) -> bool:
	return f!=null and f.used_gear.get(WORN,false) and ActiveGear.has(f,ITEM) and not MagicEquipment.suppressed(f)


static func prepare(c: GameController) -> void:
	for f in c.state.figures:
		for item in f.items:
			if item.get("gear","")==ITEM and item.get("mask_start_worn",false):
				f.used_gear[WORN]=true
				f.used_gear[EVER]=true


static func can_toggle(c: GameController) -> bool:
	var f := c.state.active()
	return f!=null and f.in_play() and f.actions_left>0 and ActiveGear.has(f,ITEM) and not MagicEquipment.suppressed(f) and not c.awaiting_reaction() and c.state.pending_cast.is_empty() and c.state.push_winner<0 and not c.state.group.movement_pass() and not f.spell_effects.has("plane_walk") and FuryRules.target(c.state,f)==null and (f.moves_taken==0 and not c.state.group.in_progress() or c.can_act())


static func toggle(c: GameController) -> bool:
	if not can_toggle(c):
		return false
	var f := c.state.active()
	var wear := not f.used_gear.get(WORN,false)
	f.used_gear[WORN]=wear
	if wear:
		f.used_gear[EVER]=true
	c._potions._spend_drink(f)
	c.emit("gear_used",{"id":f.id,"gear":ITEM,"worn":wear})
	return true
