class_name FigureInspector
extends AcceptDialog
## Public read-only figure information. No actions or rolls occur in this dialog.

var _state: GameState
var _picker: OptionButton
var _body: RichTextLabel


func _ready() -> void:
	title = "Inspect figures"
	exclusive = true
	theme = BattleTheme.create()
	get_ok_button().text = "Return to battle"
	var col := VBoxContainer.new()
	add_child(col)
	_picker = OptionButton.new()
	_picker.custom_minimum_size.y = 44
	col.add_child(_picker)
	_picker.item_selected.connect(func(index: int) -> void: _display(int(_picker.get_item_metadata(index))))
	_body = RichTextLabel.new()
	_body.bbcode_enabled = false
	_body.add_theme_font_size_override("normal_font_size", 20)
	_body.fit_content = false
	_body.scroll_active = true
	col.add_child(_body)


func open(state: GameState, preferred: int = -1) -> void:
	_state = state
	_picker.clear()
	var index := 0
	for f in state.figures:
		if not f.in_play():
			continue
		var side := "Creature" if f.side < 0 else state.side_names[f.side]
		_picker.add_item("%s · %s #%d" % [side, f.label(), f.id])
		_picker.set_item_metadata(_picker.item_count - 1, f.id)
		if f.id == preferred:
			index = _picker.item_count - 1
	if _picker.item_count > 0:
		_picker.select(index)
		_display(int(_picker.get_item_metadata(index)))
	else:
		_body.text = "No figures remain on the table."
	var viewport := get_parent().get_viewport().get_visible_rect().size
	_body.custom_minimum_size = Vector2(minf(600, viewport.x * 0.78), minf(380, viewport.y * 0.60))
	popup_centered()


func _display(id: int) -> void:
	var f := _state.figure(id)
	if f != null:
		_body.text = describe(_state, f)


static func describe(s: GameState, f: Figure) -> String:
	var lines: Array[String] = []
	var side := "Uncontrolled creature" if f.side < 0 else s.side_names[f.side]
	lines.append("%s  •  %s  •  #%d" % [f.label(), side, f.id])
	lines.append("Health  %d / %d   |   Elevation %.1f″" % [f.health, f.def.health, f.elevation])
	lines.append("Move %.1f″   Fight %+d   Shoot %+d   Armour %d   Will %+d" % [MoveRules.allowance(f) if s.active_id == f.id else float(f.effective_move()) * (0.5 if f.carries_normal_treasure() else 1.0), f.effective_fight(), f.effective_shoot(), f.effective_armour(), f.effective_will()])
	lines.append("Effective stats before opposing rolls, weapon bonuses and situational modifiers.")
	if s.active_id == f.id:
		lines.append("Active · %d action(s) left · %d move(s) used" % [f.actions_left, f.moves_taken])
	else:
		lines.append("Already activated this turn" if f.activated else "Awaiting activation")
	if f.roll_penalty() != 0:
		lines.append("Roll modifier: %+d" % f.roll_penalty())
	if f.melee != null:
		lines.append("\nMELEE: %s (Fight %+d, damage %+d, incoming damage %+d)" % [f.melee.name, f.melee.fight_mod, f.melee.damage_mod, f.melee.enemy_damage_mod])
	if f.ranged != null:
		lines.append("RANGED: %s (range %.0f″, damage %+d)%s" % [f.ranged.name, f.ranged.range_in, f.ranged.damage_mod, " · Reload required" if f.ranged.needs_reload and not f.loaded else ""])
	if f.treasure_id >= 0:
		lines.append("Carrying %d treasure(s)%s" % [f.carried_treasures().size(), " · half movement" if f.carries_normal_treasure() else " · shrunk"])
	var effects: Array[String] = []
	for key: String in f.spell_effects:
		effects.append(key.replace("_", " ").capitalize())
	if f.poisoned:
		effects.append("Poisoned · one action")
	if f.elemental_shield > 0:
		effects.append("Elemental shield: %d" % f.elemental_shield)
	if ScenarioNull.muted(f):
		effects.append("Null field · magic suppressed")
	lines.append("\nSTATUS\n" + ("; ".join(effects) if not effects.is_empty() else "No ongoing effects"))
	var traits: Array[String] = []
	for key: String in f.def.traits:
		traits.append("Immune to mundane weapons" if key == "immune_normal" else key.replace("_", " ").capitalize())
	if not traits.is_empty():
		lines.append("\nTRAITS\n" + "; ".join(traits))
	var gear: Array[String] = []
	for item in f.items:
		var key := str(item.get("gear", item.get("potion", item.get("scroll", ""))))
		if key.is_empty():
			continue
		var name := str(item.get("gear_info", {}).get("name", key.trim_prefix("gear_").replace("_", " ").capitalize()))
		if f.used_gear.has(key):
			name += " (used)"
		gear.append(name)
	if not gear.is_empty():
		lines.append("\nITEMS\n" + "; ".join(gear))
	if PowerPool.available(f) > 0:
		lines.append("Power available: %d" % PowerPool.available(f))
	return "\n".join(lines)
