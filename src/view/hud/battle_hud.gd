class_name BattleHud
extends CanvasLayer
## Touch-friendly command bar and contextual battle log. Emits player intents.

signal step_pressed
signal auto_toggled(on: bool)
signal watch_toggled(on: bool)
signal new_game_pressed
signal roster_pressed
signal campaign_pressed
signal save_battle_pressed
signal resume_battle_pressed
signal scenario_selected(id: String)
signal briefing_pressed
signal inspect_pressed
signal guide_pressed
signal atmosphere_toggled
signal graphics_requested
signal camera_requested(mode: int)
signal title_requested
signal training_requested
signal training_next
signal training_retry
signal training_leave
signal action_pressed(action: String)

const LOG_LINES := 4
## Button labels by action key, in button order (data/action_labels.json).
static var action_labels: Dictionary = JsonFile.read("res://data/action_labels.json")

var _status: Label
var _hint: Label
var _log: Label
var _lines: Array[String] = []
var _auto: Button
var _step: Button
var _watch: Button
var _buttons := {}
var _blocks: Array[Control] = []
var _action_row: GridContainer
var _combat_body: BoxContainer
var _dock: PanelContainer
var _summary: Label
var _mode := ""
var _last_actions: Array[String]=[]
var _action_scroll: ScrollContainer
var _safe: PhoneSafeArea
var _log_panel: PanelContainer
var _menu: Button
var _command_screen: BattleCommandScreen
var _scenarios: OptionButton
var _objective: Label
var _toast: Label
var _toast_timer: Timer
var _context_tip: Label
var _tips_enabled := true
var _training_panel: VBoxContainer
var _training_text: Label
var _training_next_button: Button
var _roll_panel: PanelContainer
var _roll_label: Label
var _roll_timer: Timer
var _spell_catalog: Dictionary


func _ready() -> void:
	_spell_catalog = JsonFile.read("res://data/spells.json")
	var root := PhoneSafeArea.new()
	_safe=root
	root.padding=10
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = BattleTheme.create()
	add_child(root)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(col)
	var top := HFlowContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(top)
	_status = _label(23)
	_status.modulate = Color(1.0, 0.94, 0.80)
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.move_child(top,0)
	col.add_child(_status)
	_watch = _button("Watch", func() -> void: watch_toggled.emit(_watch.button_pressed))
	_watch.toggle_mode = true
	top.add_child(_watch)
	_step = _button("Step", func() -> void: step_pressed.emit())
	top.add_child(_step)
	_auto = _button("Auto", func() -> void: auto_toggled.emit(_auto.button_pressed))
	_auto.toggle_mode = true
	top.add_child(_auto)
	_menu=_button("Menu",_open_commands)
	_menu.custom_minimum_size=Vector2(100,48)
	top.add_child(_menu)
	# Home and Maps remain in the full command menu; keep the board header compact.
	var scenarios := OptionButton.new()
	_scenarios = scenarios
	scenarios.fit_to_longest_item=false
	scenarios.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	scenarios.custom_minimum_size=Vector2(160,48)
	for id: String in ScenarioBriefing.available_entries(WarbandSlots.content_profile()):
		scenarios.add_item(ScenarioBriefing.title(id))
		scenarios.set_item_metadata(scenarios.item_count-1,id)
	scenarios.select(1)
	scenarios.item_selected.connect(func(i: int) -> void: scenario_selected.emit(str(scenarios.get_item_metadata(i))))
	scenarios.tooltip_text = "Choose the next battle scenario; current battle stays unchanged."
	top.add_child(scenarios)
	# New skirmish uses the visible map browser; retain this selector for campaign choice.
	scenarios.hide()
	var inspect := _button("Inspect", func() -> void: inspect_pressed.emit())
	ActionArt.apply(inspect,"inspect",_spell_catalog)
	top.add_child(inspect)
	_blocks.append(top)
	_objective = _label(20)
	_objective.modulate = Color(0.85, 0.90, 0.94)
	_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_objective)
	_toast = _label(17)
	_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast.modulate = Color(1.0, 0.88, 0.55)
	_toast.visible = false
	col.add_child(_toast)
	_training_panel = VBoxContainer.new()
	_training_panel.hide()
	col.add_child(_training_panel)
	_training_text = _label(17)
	_training_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_training_text.modulate = Color(1.0, 0.86, 0.52)
	_training_panel.add_child(_training_text)
	var training_buttons := HBoxContainer.new()
	_training_panel.add_child(training_buttons)
	_training_next_button = _button("Next lesson", func() -> void: training_next.emit())
	training_buttons.add_child(_training_next_button)
	training_buttons.add_child(_button("Retry", func() -> void: training_retry.emit()))
	training_buttons.add_child(_button("Leave training", func() -> void: training_leave.emit()))
	_blocks.append(_training_panel)
	_toast_timer = Timer.new()
	_toast_timer.one_shot = true
	_toast_timer.timeout.connect(func() -> void: _toast.hide())
	add_child(_toast_timer)
	_combat_body=BoxContainer.new()
	_combat_body.vertical=true
	_combat_body.size_flags_vertical=Control.SIZE_EXPAND_FILL
	_combat_body.mouse_filter=Control.MOUSE_FILTER_IGNORE
	col.add_child(_combat_body)
	var spacer := Control.new()
	spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	spacer.size_flags_vertical=Control.SIZE_EXPAND_FILL
	spacer.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_combat_body.add_child(spacer)
	_dock=PanelContainer.new()
	_dock.mouse_filter=Control.MOUSE_FILTER_STOP
	_combat_body.add_child(_dock)
	_blocks.append(_dock)
	var dock_col := VBoxContainer.new()
	dock_col.add_theme_constant_override("separation",8)
	_dock.add_child(dock_col)
	_summary=_label(22)
	_summary.modulate=Color("e5c58a")
	_summary.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_summary.hide()
	dock_col.add_child(_summary)
	var panel := PanelContainer.new()
	_log_panel = panel
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	panel.custom_minimum_size = Vector2(0, 0)
	panel.visible = false
	dock_col.add_child(panel)
	_log = _label(16)
	_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_log)
	_blocks.append(panel)
	_roll_panel = PanelContainer.new()
	_roll_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_roll_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_roll_panel.hide()
	dock_col.add_child(_roll_panel)
	_roll_label = _label(17)
	_roll_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_roll_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_roll_label.custom_minimum_size.x = 0
	_roll_panel.add_child(_roll_label)
	_roll_timer = Timer.new()
	_roll_timer.one_shot = true
	_roll_timer.timeout.connect(func() -> void: _roll_panel.hide())
	add_child(_roll_timer)
	_hint = _label(22)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dock_col.add_child(_hint)
	_blocks.append(_hint)
	_context_tip = _label(18)
	_context_tip.modulate = Color(0.72, 0.87, 0.94)
	_context_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_context_tip.hide()
	dock_col.add_child(_context_tip)
	_action_scroll=ScrollContainer.new()
	_action_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	_action_scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO
	dock_col.add_child(_action_scroll)
	_action_row = GridContainer.new()
	_action_row.columns=2
	_action_row.add_theme_constant_override("h_separation",10)
	_action_row.add_theme_constant_override("v_separation",10)
	_action_row.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_action_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_action_scroll.add_child(_action_row)
	_blocks.append(_action_scroll)
	get_viewport().size_changed.connect(_fit_actions)
	call_deferred("_fit_actions")
	for key: String in action_labels:
		var button := _button(action_labels[key], func() -> void: action_pressed.emit(key))
		ActionArt.apply(button,key,_spell_catalog)
		button.custom_minimum_size=Vector2(0,72)
		button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		button.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		button.tooltip_text=action_labels[key]
		button.toggle_mode = key in ["move","fight","shoot","collect","drop","exit","run_for_it","run_talisman","fight_hand","ammo_shot","wraith_shot"]
		if key in ["move_confirm","attack_confirm"]:
			button.add_theme_stylebox_override("normal",BattleTheme.panel(Color("305664"),Color("e5c58a")))
		elif key in ["move_undo","attack_cancel"]:
			button.add_theme_stylebox_override("normal",BattleTheme.panel(Color("493e36"),Color("c9a17e")))
		_action_row.add_child(button)
		_buttons[key] = button


func show_roll(text: String) -> void:
	if text.is_empty():
		return
	_roll_label.text = text
	_roll_panel.show()
	_roll_timer.start(3.0)


func set_training(index: int, complete: bool, failed: bool = false) -> void:
	_training_panel.visible = index >= 0
	if index < 0:
		return
	_training_text.text = "TRAINING %d/%d · %s\n%s" % [index + 1, TrainingLesson.NAMES.size(), TrainingLesson.NAMES[index], "Lesson complete!" if complete else ("Try again with Retry." if failed else TrainingLesson.HINTS[index])]
	_training_next_button.disabled = not complete
	_training_next_button.text = "Finish training" if index == TrainingLesson.NAMES.size() - 1 else "Next lesson"


func set_objective(text: String) -> void:
	_objective.text = text


func notify(text: String) -> void:
	add_line(text)
	_toast.text = text
	_toast.show()
	_toast_timer.start(4.0)


func set_status(text: String) -> void:
	_status.text = text


func set_watch(on: bool, can_change: bool, idle: bool) -> void:
	_watch.set_pressed_no_signal(on)
	_watch.disabled = not can_change
	_step.visible = on
	_auto.visible = on
	_step.disabled = not idle
	_auto.disabled = not on
	_action_scroll.visible = not on


func set_auto(on: bool) -> void:
	_auto.set_pressed_no_signal(on)


func set_hint(hint: String) -> void:
	_hint.text=hint


func set_active_summary(f: Figure) -> void:
	_summary.visible=f!=null
	if f==null:
		return
	var text := "%s  ·  HP %d/%d\n%d ACTIONS  ·  MOVE %.1f″\nF %+d   S %+d   A %d   W %+d"%[f.label(),f.health,f.def.health,f.actions_left,MoveRules.allowance(f),f.effective_fight(),f.effective_shoot(),f.effective_armour(),f.effective_will()]
	if f.ranged!=null:
		text+="\n%s · %.0f″%s"%[f.ranged.name,f.ranged.range_in," · RELOAD" if f.ranged.needs_reload and not f.loaded else ""]
	if f.treasure_id>=0:
		text+=" · LOOT %d"%f.carried_treasures().size()
	if f.poisoned:
		text+=" · POISONED"
	_summary.text=text


func set_actions(available: Array[String], mode: String, hint: String) -> void:
	_hint.text = hint
	var changed := _mode!=mode or _last_actions!=available
	_mode=mode
	_last_actions.assign(available)
	_context_tip.text = FieldGuide.tip(mode)
	_context_tip.visible = _tips_enabled and not _context_tip.text.is_empty()
	for key: String in _buttons:
		var b: Button = _buttons[key]
		b.disabled = not available.has(key)
		b.visible = available.has(key)
		b.set_pressed_no_signal(key == mode and b.toggle_mode)
	if changed:
		for i in available.size():
			if _buttons.has(available[i]):
				_action_row.move_child(_buttons[available[i]],i)
		_action_scroll.scroll_vertical=0
		call_deferred("_fit_actions")


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
	_roll_panel.hide()
	_roll_timer.stop()


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
	b.custom_minimum_size = Vector2(108, 62)
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(on_press)
	return b



func _open_commands() -> void:
	if ModalInput.blocked():
		return
	if _command_screen==null:
		_command_screen=BattleCommandScreen.new()
		add_child(_command_screen)
		_command_screen.chosen.connect(_menu_action)
	_command_screen.open(_status.text,_objective.text,_log_panel.visible,_tips_enabled)


func _menu_action(id: int) -> void:
	match id:
		0: campaign_pressed.emit()
		1: roster_pressed.emit()
		2: new_game_pressed.emit()
		3: save_battle_pressed.emit()
		4: resume_battle_pressed.emit()
		5: briefing_pressed.emit()
		6: _log_panel.visible = not _log_panel.visible
		7: guide_pressed.emit()
		8:
			_tips_enabled = not _tips_enabled
			_context_tip.visible = _tips_enabled and not _context_tip.text.is_empty()
			notify("Extra rules tips %s." % ("on" if _tips_enabled else "off"))
		9: training_requested.emit()
		10: atmosphere_toggled.emit()
		11: camera_requested.emit(0)
		12: camera_requested.emit(1)
		13: camera_requested.emit(2)
		14: title_requested.emit()
		15: graphics_requested.emit()


func select_scenario(id: String) -> void:
	for i in _scenarios.item_count:
		if _scenarios.get_item_metadata(i) == id:
			_scenarios.select(i)
			return


func _fit_actions() -> void:
	if not is_inside_tree() or get_viewport()==null:
		return
	var bounds := PhoneSafeArea.safe_rect(get_viewport(),10)
	var wide := bounds.size.x>=bounds.size.y*1.25
	_combat_body.vertical=not wide
	_dock.custom_minimum_size.x=clampf(bounds.size.x*0.29,310.0,420.0) if wide else 0.0
	_dock.size_flags_vertical=Control.SIZE_EXPAND_FILL if wide else Control.SIZE_FILL
	_dock.size_flags_horizontal=Control.SIZE_FILL
	_action_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL if wide else Control.SIZE_FILL
	var long_list := _mode in ["spell_menu","items_menu"] or _last_actions.size()>8
	_action_row.columns=1 if wide and long_list else (2 if wide else maxi(2,mini(4,floori(bounds.size.x/190.0))))
	var rows := maxi(1,ceili(float(_last_actions.size())/float(_action_row.columns)))
	_action_scroll.custom_minimum_size.y=0.0 if wide else minf(float(rows)*82.0,bounds.size.y*0.30)
