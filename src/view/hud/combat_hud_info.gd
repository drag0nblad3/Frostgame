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
