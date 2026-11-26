class_name BattleHud
extends CanvasLayer
## Touch-friendly command bar and contextual battle log. Emits player intents.

signal step_pressed
signal auto_toggled(on: bool)
signal watch_toggled(on: bool)
signal new_game_pressed
signal roster_pressed
signal campaign_pressed
signal scenario_selected(id: String)
signal action_pressed(action: String)

const LOG_LINES := 4
const ACTIONS := {"move": "Move", "fight": "Fight", "shoot": "Shoot", "reload": "Reload", "collect": "Collect", "drop": "Drop", "exit": "Exit", "end": "End", "pass_phase": "Pass soldiers", "group": "Group", "group_begin": "Start group", "group_cancel": "Cancel group", "stay": "Stay", "push_self": "Move back", "push_enemy": "Push enemy", "intercept_yes": "Intercept", "intercept_no": "Let pass", "cast": "Cast", "spell_cancel": "Cancel spell", "empower_plus": "+1 HP", "empower_minus": "−1 HP", "cast_confirm": "Resolve", "spell_elemental_bolt": "Elemental Bolt", "spell_bone_dart": "Bone Dart", "spell_elemental_shield": "Elemental Shield", "spell_heal": "Heal", "spell_shield": "Shield", "spell_fleet_feet": "Fleet Feet", "spell_strength": "Strength", "spell_glow": "Glow", "spell_mind_lock": "Mind Lock", "spell_combat_awareness": "Combat Awareness", "spell_steal_health": "Steal Health", "spell_slow": "Slow", "spell_curse": "Curse", "spell_furious_quill": "Furious Quill", "spell_enchant_armour": "Enchant Armour", "spell_elemental_ball": "Elemental Ball", "spell_destroy_undead": "Destroy Undead", "spell_banish": "Banish", "spell_call_storm": "Call Storm", "spell_scatter_shot": "Scatter Shot", "spell_destructive_sphere": "Destructive Sphere", "spell_blinding_light": "Blinding Light", "spell_petrify": "Petrify", "spell_poison_dart": "Poison Dart", "spell_enchant_weapon": "Enchant Weapon", "spell_elemental_hammer": "Elemental Hammer", "cancel_control": "Release creature", "spell_animate_skull": "Animate Skull", "spell_imp": "Imp", "spell_raise_zombie": "Raise Zombie", "spell_summon_demon": "Summon Demon", "spell_control_animal": "Control Animal", "spell_control_construct": "Control Construct", "spell_control_demon": "Control Demon", "spell_control_undead": "Control Undead", "spell_mind_control": "Mind Control", "spell_fog": "Fog", "spell_mud": "Mud", "spell_wall": "Wall", "rotate_spell": "Rotate spell"}

var _status: Label
var _hint: Label
var _log: Label
var _lines: Array[String] = []
var _auto: Button
var _step: Button
var _watch: Button
var _buttons := {}
var _blocks: Array[Control] = []
var _action_row: HFlowContainer


func _ready() -> void:
	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		root.add_theme_constant_override("margin_" + side, 12)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(col)
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(top)
	_status = _label(20)
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	top.add_child(_status)
	_watch = _button("Watch", func() -> void: watch_toggled.emit(_watch.button_pressed))
	_watch.toggle_mode = true
	top.add_child(_watch)
	_step = _button("Step", func() -> void: step_pressed.emit())
	top.add_child(_step)
	_auto = _button("Auto", func() -> void: auto_toggled.emit(_auto.button_pressed))
	_auto.toggle_mode = true
	top.add_child(_auto)
	top.add_child(_button("Campaign", func() -> void: campaign_pressed.emit()))
	top.add_child(_button("Warband", func() -> void: roster_pressed.emit()))
	var scenarios := OptionButton.new()
	scenarios.add_item("Frozen Ruins")
	scenarios.set_item_metadata(0, "treasure_skirmish")
	scenarios.add_item("Mausoleum")
	scenarios.set_item_metadata(1, "mausoleum")
	scenarios.item_selected.connect(func(i: int) -> void: scenario_selected.emit(str(scenarios.get_item_metadata(i))))
	top.add_child(scenarios)
	top.add_child(_button("New game", func() -> void: new_game_pressed.emit()))
	_blocks.append(top)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(spacer)
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	panel.custom_minimum_size = Vector2(480, 0)
	col.add_child(panel)
	_log = _label(16)
	_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_log)
	_blocks.append(panel)
	_hint = _label(20)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_hint)
	_blocks.append(_hint)
	_action_row = HFlowContainer.new()
	_action_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_action_row)
	_blocks.append(_action_row)
	for key: String in ACTIONS:
		var button := _button(ACTIONS[key], func() -> void: action_pressed.emit(key))
		button.toggle_mode = key not in ["reload", "end", "pass_phase", "group", "group_begin", "group_cancel"]
		_action_row.add_child(button)
		_buttons[key] = button


func set_status(text: String) -> void:
	_status.text = text


func set_watch(on: bool, can_change: bool, idle: bool) -> void:
	_watch.set_pressed_no_signal(on)
	_watch.disabled = not can_change
	_step.visible = on
	_auto.visible = on
	_step.disabled = not idle
	_auto.disabled = not on
	_action_row.visible = not on


func set_auto(on: bool) -> void:
	_auto.set_pressed_no_signal(on)


func set_actions(available: Array[String], mode: String, hint: String) -> void:
	_hint.text = hint
	for key: String in _buttons:
		var b: Button = _buttons[key]
		b.disabled = not available.has(key)
		if key not in ["move", "fight", "shoot", "reload", "collect", "drop", "exit", "end"]:
			b.visible = available.has(key)
		b.set_pressed_no_signal(key == mode and b.toggle_mode)


func blocks_tap(at: Vector2) -> bool:
	for c in _blocks:
		if c.is_visible_in_tree() and c.get_global_rect().has_point(at):
			return true
	return false


func add_line(text: String) -> void:
	_lines.append(text)
	while _lines.size() > LOG_LINES:
		_lines.pop_front()
	_log.text = "\n".join(_lines)


func clear_log() -> void:
	_lines.clear()
	_log.text = ""


func _label(size: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _button(text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(104, 52)
	b.add_theme_font_size_override("font_size", 20)
	b.pressed.connect(on_press)
	return b
