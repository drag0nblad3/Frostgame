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
const ACTIONS := {"wraith_shot":"Wraith Bow shot","gutter_skip":"Skip free flail attack","gear_absorb_arm":"Toggle full elemental absorption","run_for_it":"Run for it (3″)","run_talisman":"Run with talisman (6″)","extend_bridge":"Toggle 9″ bridge","cast_fang":"Toggle Golden Fang","push_self_5":"Back ½″","push_self_15":"Back 1½″","push_self_20":"Back 2″","push_self_25":"Back 2½″","push_self_30":"Back 3″","gear_rk_dazzling_cape":"Escape (Dazzling Cape)","gear_rk_bottle_imp":"Release Bottle Imp","reality_exit":"Escape through centre","ring_switch":"Switch ring side","ring_escape":"Escape via Key-Master","items": "Equipment", "items_back": "Back","break_ice": "Break treasure free", "drink_well": "Drink from well", "weapon_dagger": "Draw dagger", "weapon_staff": "Draw staff", "weapon_hand_weapon": "Draw hand weapon", "weapon_two_handed": "Draw two-handed weapon", "weapon_natural": "Use natural weapon", "fate_combat_yes": "Reroll (Fate Stone)", "fate_combat_no": "Keep roll", "telescope_use": "Use telescope (+5)", "telescope_save": "Save telescope", "gear_ring_transference": "Ring of Transference", "transfer_plus": "+1 Health", "transfer_minus": "−1 Health", "transfer_confirm": "Transfer Health", "shatter_single": "Cast only once", "potion_shatterstar": "Shatterstar Draught", "gear_ring_teleportation": "Teleport ring", "gear_horn_destruction": "Horn of Destruction", "gear_gloves_casting": "Arm casting gloves", "gear_wand_light": "Arm Wand of Light", "resist_amulet": "Use amulet (+4)", "resist_fate": "Reroll (Fate Stone)", "cast_fate": "Reroll (Fate Stone)", "move": "Move", "fight": "Fight", "shoot": "Shoot", "reload": "Reload", "collect": "Collect", "drop": "Drop", "exit": "Exit", "end": "End", "pass_phase": "Pass soldiers", "group": "Group", "group_begin": "Start group", "group_cancel": "Cancel group", "stay": "Stay", "push_self": "Move back", "push_enemy": "Push enemy", "intercept_yes": "Intercept", "intercept_no": "Let pass", "cast": "Cast", "spell_cancel": "Cancel spell", "empower_plus": "+1 empower", "empower_minus": "−1 empower", "cast_confirm": "Resolve", "cast_scroll": "Use scroll instead", "spell_decay": "Decay", "spell_beauty": "Beauty", "spell_bridge": "Bridge", "spell_plane_walk": "Plane Walk", "spell_wizard_eye": "Wizard Eye", "cancel_bridge": "Dismiss bridge", "spell_crumble": "Crumble", "spell_possess": "Possess", "spell_bones_of_the_earth": "Bones of the Earth", "spell_circle_of_protection": "Circle of Protection", "fight_hand": "Fight skeletal hand", "spell_plague_of_insects": "Plague of Insects", "spell_telekinesis": "Telekinesis", "spell_fools_gold": "Fool’s Gold", "spell_suggestion": "Suggestion", "spell_grenade": "Grenade", "spell_strike_dead": "Strike Dead", "spell_power_word": "Power Word", "spell_draining_word": "Draining Word", "spell_elemental_bolt": "Elemental Bolt", "spell_bone_dart": "Bone Dart", "spell_elemental_shield": "Elemental Shield", "spell_heal": "Heal", "spell_shield": "Shield", "spell_fleet_feet": "Fleet Feet", "spell_strength": "Strength", "spell_glow": "Glow", "spell_mind_lock": "Mind Lock", "spell_combat_awareness": "Combat Awareness", "spell_steal_health": "Steal Health", "spell_slow": "Slow", "spell_curse": "Curse", "spell_furious_quill": "Furious Quill", "spell_enchant_armour": "Enchant Armour", "spell_elemental_ball": "Elemental Ball", "spell_destroy_undead": "Destroy Undead", "spell_banish": "Banish", "spell_call_storm": "Call Storm", "spell_scatter_shot": "Scatter Shot", "spell_destructive_sphere": "Destructive Sphere", "spell_blinding_light": "Blinding Light", "spell_petrify": "Petrify", "spell_poison_dart": "Poison Dart", "spell_enchant_weapon": "Enchant Weapon", "spell_elemental_hammer": "Elemental Hammer", "cancel_control": "Release creature", "spell_animate_skull": "Animate Skull", "spell_imp": "Imp", "spell_raise_zombie": "Raise Zombie", "spell_summon_demon": "Summon Demon", "spell_control_animal": "Control Animal", "spell_control_construct": "Control Construct", "spell_control_demon": "Control Demon", "spell_control_undead": "Control Undead", "spell_mind_control": "Mind Control", "spell_fog": "Fog", "spell_mud": "Mud", "spell_wall": "Wall", "rotate_spell": "Rotate spell", "spell_leap": "Leap", "spell_teleport": "Teleport", "spell_blink": "Blink", "spell_transpose": "Transpose", "spell_push": "Push", "spell_dispel": "Dispel", "spell_spell_eater": "Spell Eater", "counter_previous": "Previous effect", "counter_next": "Next effect", "counter_confirm": "Cast on effect", "spell_explosive_rune": "Explosive Rune", "spell_planar_tear": "Planar Tear", "spell_invisibility": "Invisibility", "spell_true_sight": "True Sight", "spell_illusionary_soldier": "Illusionary Soldier", "resist_plus": "+1 empower", "resist_minus": "−1 empower", "resist_confirm": "Resolve resistance", "spell_fast_act": "Fast Act", "spell_time_store": "Time Store", "spell_time_walk": "Time Walk", "use_stored_action": "Use stored action", "potion_cancel": "Cancel potion", "potion_healing": "Potion of Healing", "potion_strength": "Potion of Strength", "potion_toughness": "Potion of Toughness", "potion_speed": "Elixir of Speed", "potion_invisibility": "Potion of Invisibility", "potion_clearsight": "Cordial of Clearsight", "potion_iron_mind": "Potion of Iron Mind", "potion_chameleon": "Elixir of the Chameleon", "potion_restoration": "Potion of Restoration", "potion_explosive_cocktail": "Explosive Cocktail", "potion_teleportation": "Potion of Teleportation", "potion_elemental_absorption": "Potion of Elemental Absorption", "potion_poison": "Poison", "potion_fairy_dust": "Philtre of Fairy Dust", "potion_fire_breath": "Potion of Fire Breath", "potion_empowerment": "Cordial of Empowerment", "potion_darkness": "Bottle of Darkness", "potion_invulnerability": "Potion of Invulnerability", "coat_melee": "Coat melee weapon", "coat_ranged": "Coat ammunition", "breathe_fire": "Breathe fire", "potion_null": "Bottle of Null", "potion_shrinking": "Shrinking Potion", "drop_shrunk": "Drop shrunk treasure", "potion_fury": "Philtre of Fury", "potion_burrowing": "Bottle of Burrowing", "potion_ethereal_vacuum": "Ethereal Vacuum"}

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
var _menu: MenuButton
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
	_menu = MenuButton.new()
	_menu.text = "Menu"
	_menu.custom_minimum_size = Vector2(90, 48)
	var popup := _menu.get_popup()
	for label_text: String in ["Campaign", "Warband", "New skirmish", "Save battle", "Resume battle", "Scenario briefing", "Combat log", "How to play", "Toggle extra tips", "Training battle", "Toggle snowfall", "Frame battlefield", "Overhead view", "Focus active figure", "Return to title", "Graphics quality"]:
		popup.add_item(label_text)
	popup.id_pressed.connect(_menu_action)
	top.add_child(_menu)
	var home := _button("Home",func() -> void: title_requested.emit())
	top.add_child(home)
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
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(spacer)
	var panel := PanelContainer.new()
	_log_panel = panel
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	panel.custom_minimum_size = Vector2(360, 0)
	panel.visible = false
	col.add_child(panel)
	_log = _label(16)
	_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_log)
	_blocks.append(panel)
	_roll_panel = PanelContainer.new()
	_roll_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_roll_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_roll_panel.hide()
	col.add_child(_roll_panel)
	_roll_label = _label(17)
	_roll_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_roll_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_roll_label.custom_minimum_size.x = 330
	_roll_panel.add_child(_roll_label)
	_roll_timer = Timer.new()
	_roll_timer.one_shot = true
	_roll_timer.timeout.connect(func() -> void: _roll_panel.hide())
	add_child(_roll_timer)
	_hint = _label(20)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_hint)
	_blocks.append(_hint)
	_context_tip = _label(15)
	_context_tip.modulate = Color(0.72, 0.87, 0.94)
	_context_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_context_tip.hide()
	col.add_child(_context_tip)
	_action_scroll=ScrollContainer.new()
	_action_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	_action_scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO
	col.add_child(_action_scroll)
	_action_row = HFlowContainer.new()
	_action_row.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_action_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_action_scroll.add_child(_action_row)
	_blocks.append(_action_scroll)
	get_viewport().size_changed.connect(_fit_actions)
	call_deferred("_fit_actions")
	for key: String in ACTIONS:
		var button := _button(ACTIONS[key], func() -> void: action_pressed.emit(key))
		ActionArt.apply(button,key,_spell_catalog)
		button.toggle_mode = key not in ["reload", "end", "pass_phase", "group", "group_begin", "group_cancel", "items", "items_back"]
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


func set_actions(available: Array[String], mode: String, hint: String) -> void:
	_hint.text = hint
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
	b.custom_minimum_size = Vector2(88, 48)
	b.add_theme_font_size_override("font_size", 18)
	b.pressed.connect(on_press)
	return b



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
	# Constrain long spell/item lists to a scrollable dock rather than letting
	# them occupy the entire battlefield. Short lists use one row.
	var visible_count := 0
	for button in _action_row.get_children():
		if button.visible:
			visible_count+=1
	var rows := maxi(1,ceili(float(visible_count)/maxf(1.0,floorf(bounds.size.x/150.0))))
	_action_scroll.custom_minimum_size.y=minf(float(rows)*54.0,bounds.size.y*0.26)
