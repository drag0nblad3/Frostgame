class_name FigureInspector
extends ExpeditionScreen
## Public read-only figure information. No actions or rolls occur in this dialog.

var _state: GameState
var _picker: OptionButton
var _body: RichTextLabel
var _portrait: MiniaturePortrait
var _content: BoxContainer
var _stats: VBoxContainer
var _visual: VBoxContainer


func _ready() -> void:
	build("FIGURE DOSSIER","Return to battle",navigate_back)
	title="Inspect figures"
	subtitle.text="Inspect any figure without spending an action"
	var col := body
	_picker = OptionButton.new()
	_picker.custom_minimum_size.y = 64
	_picker.fit_to_longest_item=false
	_picker.add_theme_font_size_override("font_size",25)
	col.add_child(_picker)
	_picker.item_selected.connect(func(index: int) -> void: _display(int(_picker.get_item_metadata(index))))
	_content = BoxContainer.new()
	_content.add_theme_constant_override("separation",12)
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_content)
	_visual = WorkshopUI.column(_content)
	_visual.size_flags_stretch_ratio=1.0
	_portrait = MiniaturePortrait.new()
	_portrait.custom_minimum_size = Vector2(0, 170)
	_portrait.tight_frame=true
	_portrait.size_flags_vertical=Control.SIZE_EXPAND_FILL
	_portrait.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_visual.add_child(_portrait)
	var instruction := Label.new()
	instruction.text = "Drag to rotate miniature"
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction.add_theme_font_size_override("font_size", 20)
	_visual.add_child(instruction)
	var details := WorkshopUI.column(_content)
	details.size_flags_stretch_ratio=1.4
	_stats=WorkshopUI.column(details)
	_stats.size_flags_vertical=Control.SIZE_FILL
	_body = RichTextLabel.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.bbcode_enabled = false
	_body.add_theme_font_size_override("normal_font_size", 25)
	_body.add_theme_constant_override("line_separation",7)
	_body.fit_content = false
	_body.scroll_active = true
	details.add_child(_body)


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
	show_screen()


func _reflow() -> void:
	if _content!=null:
		_content.vertical=size.x<size.y


func _display(id: int) -> void:
	var f := _state.figure(id)
	if f != null:
		_body.text = describe(_state, f)
		WorkshopUI.clear(_stats)
		var d := f.def.with_bonuses({})
		d.move=f.effective_move()
		d.fight=f.effective_fight()
		d.shoot=f.effective_shoot()
		d.armour=f.effective_armour()
		d.will=f.effective_will()
		d.health=f.health
		WorkshopUI.stats(_stats,d)
		WorkshopUI.label(_stats,"Health %d/%d · Effective stats before situational modifiers"%[f.health,f.def.health],20,WorkshopUI.MUTED)
		var color: Color = Color(0.65, 0.45, 0.75) if f.side < 0 else FigureView.SIDE_COLORS[f.side % FigureView.SIDE_COLORS.size()]
		_portrait.set_figure(f, color, SchoolArt.of_figure(f))


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
		if item.get("enchanted",false):
			name+=" (Enchanted)"
		if item.get("ivory_graft",false):
			name+=" (Ivory Hand graft)"
		if item.get("gear","")==RedKingMaterials.FANGS:
			name+=" (%d left)"%RedKingMaterials.amount(item)
		if f.used_gear.has(key):
			name += " (used)"
		gear.append(name)
	if not gear.is_empty():
		lines.append("\nITEMS\n" + "; ".join(gear))
	if PowerPool.available(f) > 0:
		lines.append("Power available: %d" % PowerPool.available(f))
	return "\n".join(lines)
