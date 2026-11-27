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
var _action_row: HFlowContainer
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
var _split: BoxContainer
var _dock: VBoxContainer
var _unit_info: Label
var _action_info: Label
var _move_info: Label
var _move_bar: HBoxContainer


func _ready() -> void:
	_spell_catalog = JsonFile.read("res://data/spells.json")
	var root := PhoneSafeArea.new()
	_safe=root
	root.padding=8
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = BattleTheme.create()
	add_child(root)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(col)
	var top := HFlowContainer.new()
	top.add_theme_constant_override("h_separation",8)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(top)
	_status = _label(20)
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
	_menu.custom_minimum_size=Vector2(114,62)
	top.add_child(_menu)
	var home := _button("Home",func() -> void: title_requested.emit())
	top.add_child(home)
	home.hide() # Home remains available from the command menu.
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
	var map := _button("Maps",func() -> void:new_game_pressed.emit())
	top.add_child(map)
	map.hide() # Maps remains available from the command menu.
	var inspect := _button("Inspect", func() -> void: inspect_pressed.emit())
	ActionArt.apply(inspect,"inspect",_spell_catalog)
	top.add_child(inspect)
	_blocks.append(top)
	_objective = _label(16)
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
	var split := BoxContainer.new()
	_split=split
	split.size_flags_vertical=Control.SIZE_EXPAND_FILL
	split.mouse_filter=Control.MOUSE_FILTER_IGNORE
	col.add_child(split)
	var spacer := Control.new()
	spacer.size_flags_vertical=Control.SIZE_EXPAND_FILL
	spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	spacer.mouse_filter=Control.MOUSE_FILTER_IGNORE
	split.add_child(spacer)
	_dock=VBoxContainer.new()
	_dock.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_dock.add_theme_constant_override("separation",6)
	split.add_child(_dock)
	var panel := PanelContainer.new()
	_log_panel = panel
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	panel.custom_minimum_size = Vector2(360, 0)
	panel.visible = false
	_dock.add_child(panel)
	_log = _label(16)
	_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_log)
	_blocks.append(panel)
	_roll_panel = PanelContainer.new()
	_roll_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_roll_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_roll_panel.hide()
	_dock.add_child(_roll_panel)
	_roll_label = _label(17)
	_roll_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_roll_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_roll_label.custom_minimum_size.x = 330
	_roll_panel.add_child(_roll_label)
	_roll_timer = Timer.new()
	_roll_timer.one_shot = true
	_roll_timer.timeout.connect(func() -> void: _roll_panel.hide())
	add_child(_roll_timer)
	_unit_info=_label(22)
	_unit_info.modulate=Color("f3d49b")
	_unit_info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_dock.add_child(_unit_info)
	_blocks.append(_unit_info)
	_action_info=_label(19)
	_action_info.modulate=Color("c5e2ec")
	_action_info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_dock.add_child(_action_info)
	_blocks.append(_action_info)
	_hint = _label(20)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dock.add_child(_hint)
	_blocks.append(_hint)
	_context_tip = _label(15)
	_context_tip.modulate = Color(0.72, 0.87, 0.94)
	_context_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_context_tip.hide()
	_dock.add_child(_context_tip)
	_blocks.append(_context_tip)
	_move_info=_label(19)
	_move_info.modulate=Color("f3d49b")
	_move_info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_move_info.hide()
	_dock.add_child(_move_info)
	_blocks.append(_move_info)
	_move_bar=HBoxContainer.new()
	_move_bar.hide()
	_dock.add_child(_move_bar)
	_blocks.append(_move_bar)
	_action_scroll=ScrollContainer.new()
	_action_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	_action_scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO
	_dock.add_child(_action_scroll)
	_action_row = HFlowContainer.new()
	_action_row.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_action_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_action_row.add_theme_constant_override("h_separation",8)
	_action_row.add_theme_constant_override("v_separation",8)
	_action_scroll.add_child(_action_row)
	_blocks.append(_action_scroll)
	get_viewport().size_changed.connect(_fit_actions)
	call_deferred("_fit_actions")
	for key: String in action_labels:
		var button := _button(action_labels[key], func() -> void: action_pressed.emit(key))
		ActionArt.apply(button,key,_spell_catalog)
		button.toggle_mode = key not in ["reload", "end", "pass_phase", "group", "group_begin", "group_cancel", "items", "items_back","move_confirm","move_reset","move_camera"]
		button.tooltip_text=action_labels[key]
		button.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		button.custom_minimum_size=Vector2(126,66)
		button.add_theme_font_size_override("font_size",22)
		if key in ["move_confirm","move_reset"]:
			button.custom_minimum_size.x=0
			button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			button.size_flags_stretch_ratio=1.5 if key=="move_confirm" else 1.0
			_move_bar.add_child(button)
			if key=="move_confirm":
				button.add_theme_stylebox_override("normal",BattleTheme.panel(Color("355b60"),Color("e5c58a")))
		else:
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


func set_unit_info(unit: String,action: String) -> void:
	_unit_info.text=unit
	_unit_info.visible=not unit.is_empty()
	_action_info.text=action
	_action_info.visible=not action.is_empty()


func set_move_controls(planned: bool,dragging: bool,info: String) -> void:
	_move_info.text=info
	_buttons["move_confirm"].disabled=not planned
	_buttons["move_reset"].disabled=not planned
	_buttons["move_camera"].text="Drag: move" if dragging else "Drag: camera"
	_buttons["move_camera"].tooltip_text="Switch single-finger drag between planning movement and orbiting the camera. Two fingers still pan/zoom."


func set_actions(available: Array[String], mode: String, hint: String) -> void:
	_hint.text = hint
	_move_bar.visible=mode=="move"
	_move_info.visible=mode=="move"
	if mode.is_empty():
		set_unit_info("","")
	_context_tip.text = FieldGuide.tip(mode)
	_context_tip.visible = _tips_enabled and not _context_tip.text.is_empty()
	for key: String in _buttons:
		var b: Button = _buttons[key]
		b.disabled = not available.has(key)
		b.visible = available.has(key)
		b.set_pressed_no_signal(key == mode and b.toggle_mode)
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
	b.custom_minimum_size = Vector2(108, 60)
	b.add_theme_font_size_override("font_size", 21)
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
	# Landscape: right-hand workspace leaves the battlefield on the left.
	# Portrait: the same controls dock at the bottom, above the safe inset.
	var wide := bounds.size.x>=1000 and bounds.size.x>bounds.size.y*1.35
	_split.vertical=not wide
	_dock.custom_minimum_size.x=clampf(bounds.size.x*0.31,350.0,460.0) if wide else 0.0
	_dock.size_flags_horizontal=Control.SIZE_FILL if wide else Control.SIZE_EXPAND_FILL
	_action_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL if wide else Control.SIZE_FILL
	var visible_count := 0
	for button in _action_row.get_children():
		if button.visible:
			visible_count+=1
	var width := _dock.custom_minimum_size.x if wide else bounds.size.x
	var rows := maxi(1,ceili(float(visible_count)/maxf(1.0,floorf(width/172.0))))
	_action_scroll.custom_minimum_size.y=74.0 if wide else minf(float(rows)*74.0,bounds.size.y*0.32)
