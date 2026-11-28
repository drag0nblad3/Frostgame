class_name CombatHudInfo
extends RefCounted
## Compact, rules-derived information. Never evaluates attacks from a draft position.


static func unit(f: Figure) -> String:
	if f==null:
		return ""
	var text := "%s · %d/%d HP · %d action%s\nM %d″  F %+d  S %+d  A %d  W %+d"%[
		f.label(),f.health,f.def.health,f.actions_left,"" if f.actions_left==1 else "s",
		f.effective_move(),f.effective_fight(),f.effective_shoot(),f.effective_armour(),f.effective_will()]
	if f.treasure_id>=0:
		text+=" · Loot %d"%f.carried_treasures().size()
	var depth:=Swimming.figure_depth(f)
	if depth==2:
		text+=" · Deep water"+(" (swim exempt)" if Swimming.immune(f) else " · Swim TN5 · Fight −2")
	elif depth==1:
		text+=" · Shallow water"+(" (exempt)" if Swimming.immune(f) else " · Rough")
	return text


static func action(bi: BattleInput,f: Figure) -> String:
	if f==null:
		return "%d eligible figures"%bi.targets.size() if bi.mode=="select" else ""
	match bi.mode:
		"move":
			return "Move · 1 action · %s"%("Second move, half distance" if f.moves_taken>0 else "First move")
		"fight","fight_hand":
			return "%s · %d target(s) · Opposed d20 + Fight; either side may take damage."%[f.melee.name if f.melee!=null else "Melee",bi.targets.size()]
		"shoot","wraith_shot","ammo_shot":
			if f.ranged!=null:
				return "%s · %g″ range · %d target(s)\nOpposed Shoot vs Fight; cover and movement affect defence."%[f.ranged.name,f.ranged.range_in,bi.targets.size()]
		"spell_menu":
			return "%d available spells · Select a spell to choose targets."%bi.cast_options.size()
		"spell_target","spell_point","treasure_spell","counter_select":
			var spell: Dictionary=bi.c.state.spell_catalog.get(bi.selected_spell,{})
			if not spell.is_empty():
				return str(spell.get("name",bi.selected_spell))+" · "+str(spell.get("kind","")).replace("_"," ").capitalize()
		"collect":
			return "Collect · 1 action · %d eligible treasure marker(s)"%bi.tokens.size()
		"exit":
			return "Retreat · Leaving the table is final."
		"items_menu":
			return "%d equipment choices"%bi.item_options.size()
	return ""


## Explain common disabled action classes using already-computed menu
## availability. Do not launch additional reach, target or spell searches.
static func restrictions(c: GameController,f: Figure,available: Array[String]) -> String:
	if f==null or c.awaiting_reaction() or not c.state.pending_cast.is_empty():
		return ""
	if f.actions_left<=0:
		return "No actions remaining."
	if f.spell_effects.has("plane_walk"):
		return "Plane Walk: movement only."
	if c.state.group.movement_pass():
		return "Group activation: movement pass."
	if f.spell_effects.has("petrify"):
		return "Petrified: restricted actions."
	if Contact.in_combat(c.state.figures,f):
		if f.spell_effects.has("blinding_light"):
			return "Engaged and blinded; normal fighting is unavailable."
		return "Engaged: normal movement, shooting and casting are restricted."
	if f.ranged!=null and f.ranged.needs_reload and not f.loaded and available.has("reload"):
		return "Ranged weapon unloaded; reload before shooting."
	if f.acted and not c.can_act() and c.can_move():
		return "Non-movement action used; only movement remains."
	if not available.has("move") and not c.can_move():
		return "Movement unavailable this activation."
	if f.ranged!=null and not available.has("shoot") and c.can_act():
		return "No legal shot (range, sight or target restrictions)."
	return ""
