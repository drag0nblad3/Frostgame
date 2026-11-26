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
var _guide: FieldGuideDialog
var _graphics: GraphicsDialog
var _expansions: ExpansionDialog
var _atmosphere: BattleAtmosphere
var _title_board: Board


func _ready() -> void:
	GraphicsQuality.apply(get_viewport())
	var board := BoardLoader.load_id("silent_tower",TerrainDb.load_file())
	var scenery := BoardView.new()
	add_child(scenery)
	scenery.scenario_id = "silent_tower"
	scenery.cinematic = true
	scenery.build(board)
	_title_board=board
	_atmosphere=BattleAtmosphere.new()
	add_child(_atmosphere)
	_atmosphere.configure(board,"silent_tower")
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
	var margin := PhoneSafeArea.new()
	margin.padding=14
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(margin)
	var row := HBoxContainer.new()
	margin.add_child(row)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel",BattleTheme.panel(Color(0.035,0.065,0.095,0.95),Color(0.61,0.51,0.31),4))
	panel.custom_minimum_size.x = minf(430,PhoneSafeArea.safe_rect(get_viewport(),14).size.x)
	panel.size_flags_vertical=Control.SIZE_EXPAND_FILL
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
	_slots.fit_to_longest_item=false
	_slots.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	_menu.add_child(_slots)
	_slots.item_selected.connect(_select_slot)
	_button("resume","Resume saved battle",true)
	_button("skirmish","New skirmish",true)
	_button("warband","Create / edit warband")
	_button("campaign","Campaign headquarters")
	_button("training","Training yard")
	_button("guide","Field guide")
	_button("expansions","Rulebook content")
	_button("graphics","Graphics quality")
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
	if _launching or ModalInput.blocked():
		return
	if key=="expansions":
		_open_expansions()
		return
	if key in ["skirmish","warband","campaign","resume","training"]:
		var errors := WarbandSlots.content_profile().errors()
		if not errors.is_empty():
			_notice.text="; ".join(errors)
			return
	if key=="skirmish":
		_choose_scenario()
		return
	if key=="warband":
		_edit_warband()
		return
	if key=="guide":
		_open_guide()
		return
	if key=="graphics":
		_open_graphics()
		return
	_launching = true
	get_tree().root.set_meta(LAUNCH_KEY,key)
	if get_tree().change_scene_to_file(BATTLE) != OK:
		get_tree().root.remove_meta(LAUNCH_KEY)
		_launching = false


func _process(delta: float) -> void:
	if ModalInput.blocked() or GraphicsQuality.mode()==0 or (_editor!=null and _editor.visible) or (_guide!=null and _guide.visible) or (_picker!=null and _picker.visible) or (_graphics!=null and _graphics.visible):
		return
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
	var profile := WarbandSlots.content_profile()
	var compatible := not checkpoint.is_empty() and profile.same(meta.get("expansions",[])) and profile.errors().is_empty()
	var path := WarbandSlots.path_for(CampaignProgress.PATH)
	if meta.get("campaign",false):
		compatible=compatible and FileAccess.file_exists(path) and FileAccess.get_sha256(path)==meta.get("campaign_hash","")
	_buttons["resume"].visible=not checkpoint.is_empty()
	_buttons["resume"].disabled=not compatible
	_buttons["resume"].tooltip_text="Restore the saved battle's content selection or campaign state to resume." if not compatible else ""
	_buttons["expansions"].text="Rulebook content · %d enabled"%profile.enabled.size()
	_buttons["warband"].text="Create warband" if WarbandSlots.roster().is_empty() else "Edit saved warband"
	var roster := WarbandSlots.roster()
	_notice.text="Starting roster: %s. Each slot has separate saves."%roster.get("name","default expedition")
	if roster.is_empty():
		_notice.text+=" Create a warband to customize your troops."


func _select_slot(index: int) -> void:
	if ModalInput.blocked():
		_slots.select(WarbandSlots.active())
		return
	if WarbandSlots.select_slot(index):
		_refresh_slots()
	else:
		_notice.text="Could not switch save slot."
		_slots.select(WarbandSlots.active())


func _choose_scenario() -> void:
	if _picker==null:
		_picker=SkirmishPicker.new()
		add_child(_picker)
		_picker.selected.connect(func(id: String) -> void:
			_launching=true
			get_tree().root.set_meta("frostgame_scenario",id)
			get_tree().root.set_meta(LAUNCH_KEY,"selected_skirmish")
			if get_tree().change_scene_to_file(BATTLE)!=OK:
				_launching=false)
	_picker.open(true)


func _edit_warband() -> void:
	if _editor!=null:
		remove_child(_editor)
		_editor.queue_free()
	_editor=WarbandSetup.new()
	add_child(_editor)
	_editor.setup(FigureDb.load_files(FigureDb.FIGURES,FigureDb.WEAPONS,WarbandSlots.content_profile()),WarbandSlots.roster())
	_editor.get_ok_button().text="Save warband"
	_editor.drafted.connect(func(roster: Dictionary) -> void:
		if WarbandSlots.save_roster(roster):
			_refresh_slots()
			_notice.text="Warband saved to slot %d."%(WarbandSlots.active()+1)
		else:
			_notice.text="Could not save warband. Reopen the editor and try again.")
	PhoneSafeArea.popup_dialog(_editor,PhoneSafeArea.safe_rect(get_viewport(),14).size*0.96)


func _open_guide() -> void:
	if _guide==null:
		_guide=FieldGuideDialog.new()
		add_child(_guide)
	_guide.open("Back to home")


func _open_graphics() -> void:
	if _graphics==null:
		_graphics=GraphicsDialog.new()
		add_child(_graphics)
		_graphics.quality_changed.connect(func() -> void:
			GraphicsQuality.apply(get_viewport())
			_atmosphere.configure(_title_board,"silent_tower"))
	_graphics.open()


func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_GO_BACK_REQUEST and is_inside_tree():
		ModalInput.close_top(get_tree().root)


func _open_expansions() -> void:
	if _expansions==null:
		_expansions=ExpansionDialog.new()
		add_child(_expansions)
		_expansions.changed.connect(func() -> void:
			if _guide!=null:
				remove_child(_guide)
				_guide.queue_free()
				_guide=null
			_refresh_slots())
	_expansions.open(WarbandSlots.active())
