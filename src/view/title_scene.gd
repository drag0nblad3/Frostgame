extends Node3D
## Scenic, non-interactive city backdrop and explicit entry points.
const BATTLE := "res://scenes/main.tscn"
const LAUNCH_KEY := "frostgame_launch"
var _camera: Camera3D
var _elapsed := 0.0
var _launching := false
var _buttons := {}
var _menu: VBoxContainer
var _slots: OptionButton
var _picker: SkirmishPicker
var _editor: WarbandSetup
var _notice: Label


func _ready() -> void:
	var board := BoardLoader.load_id("silent_tower",TerrainDb.load_file())
	var scenery := BoardView.new()
	add_child(scenery)
	scenery.scenario_id = "silent_tower"
	scenery.cinematic = true
	scenery.build(board)
	var atmosphere := BattleAtmosphere.new()
	add_child(atmosphere)
	atmosphere.configure(board,"silent_tower")
	_camera = Camera3D.new()
	_camera.fov = 56.0
	add_child(_camera)
	_camera.make_current()
	_frame()
	var layer := CanvasLayer.new()
	add_child(layer)
	var screen := Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.theme = BattleTheme.create()
	layer.add_child(screen)
	var shade := ColorRect.new()
	shade.color = Color(0.025,0.045,0.075,0.36)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(shade)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge: String in ["top","bottom","left","right"]:
		margin.add_theme_constant_override("margin_"+edge,28)
	screen.add_child(margin)
	var row := HBoxContainer.new()
	margin.add_child(row)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel",BattleTheme.panel(Color(0.035,0.065,0.095,0.95),Color(0.61,0.51,0.31),4))
	panel.custom_minimum_size.x = minf(420,get_viewport().get_visible_rect().size.x-56)
	row.add_child(panel)
	var wrap := MarginContainer.new()
	for edge: String in ["top","bottom","left","right"]:
		wrap.add_theme_constant_override("margin_"+edge,18)
	panel.add_child(wrap)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	wrap.add_child(scroll)
	_menu = VBoxContainer.new()
	_menu.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_menu.alignment = BoxContainer.ALIGNMENT_CENTER
	_menu.add_theme_constant_override("separation",10)
	scroll.add_child(_menu)
	_label("A WIZARD'S EXPEDITION",16,Color(0.80,0.70,0.48))
	_label("FROSTGAME",49,Color(0.92,0.95,0.97))
	_label("RIVAL WARBANDS  /  FROZEN RUINS",15,Color(0.67,0.80,0.88))
	_menu.add_child(HSeparator.new())
	_label("ACTIVE WARBAND",14,Color("c6b17d"))
	_slots=OptionButton.new()
	_menu.add_child(_slots)
	_slots.item_selected.connect(_select_slot)
	_button("resume","Resume saved battle",true)
	_button("skirmish","New skirmish",true)
	_button("warband","Create / edit warband")
	_button("campaign","Campaign headquarters")
	_button("training","Training yard")
	_button("gatehouse","Experimental 3D skirmish")
	_button("resume_layered","Resume 3D battle")
	_button("guide","Field guide")
	_notice=Label.new()
	_notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_menu.add_child(_notice)
	_refresh_slots()
	_label("A fan-made tactical tabletop simulator",13,Color(0.65,0.73,0.79))
	var space := Control.new()
	space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(space)


func _label(value: String, font_size: int, tint: Color) -> void:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size",font_size)
	label.modulate = tint
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_menu.add_child(label)


func _button(key: String, value: String, primary: bool = false) -> void:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 48
	if primary:
		button.add_theme_stylebox_override("normal",BattleTheme.panel(Color(0.18,0.32,0.38),Color(0.88,0.72,0.39)))
	_menu.add_child(button)
	_buttons[key] = button
	button.pressed.connect(_launch.bind(key))


func _launch(key: String) -> void:
	if _launching:
		return
	if key=="skirmish" or key=="gatehouse":
		_choose_scenario(key=="gatehouse")
		return
	if key=="warband":
		_edit_warband()
		return
	_launching = true
	get_tree().root.set_meta(LAUNCH_KEY,key)
	if key in ["gatehouse","resume_layered"]:
		get_tree().root.remove_meta(LAUNCH_KEY)
		if key=="resume_layered":
			get_tree().root.set_meta("layered_resume",true)
		if get_tree().change_scene_to_file("res://scenes/layered_skirmish.tscn")!=OK:
			_launching=false
		return
	if get_tree().change_scene_to_file(BATTLE) != OK:
		get_tree().root.remove_meta(LAUNCH_KEY)
		_launching = false


func _process(delta: float) -> void:
	_elapsed += delta
	_frame()


func _frame() -> void:
	# Slow scenic pan, only on this presentation scene.
	_camera.position = Vector3(8.8+sin(_elapsed*0.095)*1.5,7.1,1.0+cos(_elapsed*0.095)*0.7)
	_camera.look_at(Vector3(14.6,4.6,19.0))


func _refresh_slots() -> void:
	_slots.clear()
	for i in WarbandSlots.COUNT:
		_slots.add_item("%d · %s"%[i+1,WarbandSlots.summary(i)])
	_slots.select(WarbandSlots.active())
	var checkpoint := BattleSnapshot.read()
	var meta: Dictionary=checkpoint.get("meta",{})
	var compatible := not checkpoint.is_empty()
	var path := WarbandSlots.path_for(CampaignProgress.PATH)
	if meta.get("campaign",false):
		compatible=compatible and FileAccess.file_exists(path) and FileAccess.get_sha256(path)==meta.get("campaign_hash","")
	_buttons["resume"].visible=compatible
	_buttons["resume_layered"].visible=not LayeredCheckpoint.read().is_empty()
	_buttons["warband"].text="Create warband" if WarbandSlots.roster().is_empty() else "Edit saved warband"
	_notice.text="Your selected slot keeps its own roster, campaign and saved battles."


func _select_slot(index: int) -> void:
	if WarbandSlots.select_slot(index):
		_refresh_slots()
	else:
		_notice.text="Could not switch save slot."
		_slots.select(WarbandSlots.active())


func _choose_scenario(experimental: bool) -> void:
	if _picker==null:
		_picker=SkirmishPicker.new()
		add_child(_picker)
		_picker.selected.connect(func(id: String,layered: bool) -> void:
			_launching=true
			if layered:
				get_tree().root.set_meta("layered_board",id)
				get_tree().change_scene_to_file("res://scenes/layered_skirmish.tscn")
			else:
				get_tree().root.set_meta("frostgame_scenario",id)
				get_tree().root.set_meta(LAUNCH_KEY,"selected_skirmish")
				get_tree().change_scene_to_file(BATTLE))
	_picker.open(experimental)


func _edit_warband() -> void:
	if _editor!=null:
		remove_child(_editor)
		_editor.queue_free()
	_editor=WarbandSetup.new()
	add_child(_editor)
	_editor.setup(FigureDb.load_files(),WarbandSlots.roster())
	_editor.get_ok_button().text="Save warband"
	_editor.drafted.connect(func(roster: Dictionary) -> void:
		if WarbandSlots.save_roster(roster):
			_refresh_slots()
			_notice.text="Warband saved to slot %d."%(WarbandSlots.active()+1)
		else:
			_notice.text="Could not save warband. Reopen the editor and try again.")
	_editor.popup_centered_ratio(0.94)
