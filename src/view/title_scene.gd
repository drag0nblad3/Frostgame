extends Node3D
## Scenic, non-interactive city backdrop and explicit entry points.
const BATTLE := "res://scenes/main.tscn"
const LAUNCH_KEY := "frostgame_launch"
var _camera: Camera3D
var _elapsed := 0.0
var _launching := false
var _buttons := {}
var _menu: VBoxContainer


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
	panel.custom_minimum_size.x = 420
	row.add_child(panel)
	var wrap := MarginContainer.new()
	for edge: String in ["top","bottom","left","right"]:
		wrap.add_theme_constant_override("margin_"+edge,18)
	panel.add_child(wrap)
	_menu = VBoxContainer.new()
	_menu.alignment = BoxContainer.ALIGNMENT_CENTER
	_menu.add_theme_constant_override("separation",10)
	wrap.add_child(_menu)
	_label("A WIZARD'S EXPEDITION",16,Color(0.80,0.70,0.48))
	_label("FROSTGAME",49,Color(0.92,0.95,0.97))
	_label("RIVAL WARBANDS  /  FROZEN RUINS",15,Color(0.67,0.80,0.88))
	_menu.add_child(HSeparator.new())
	var checkpoint := BattleSnapshot.read()
	var meta: Dictionary = checkpoint.get("meta",{})
	var compatible := not checkpoint.is_empty()
	if meta.get("campaign",false):
		compatible = compatible and FileAccess.file_exists(CampaignProgress.PATH) and FileAccess.get_sha256(CampaignProgress.PATH) == meta.get("campaign_hash","")
	if compatible:
		_button("resume","Resume saved battle",true)
	_button("skirmish","New skirmish",not compatible)
	_button("warband","Create a warband")
	_button("campaign","Campaign headquarters")
	_button("training","Training yard")
	_button("gatehouse","Gatehouse · experimental battle")
	if not LayeredCheckpoint.read().is_empty():
		_button("resume_layered","Resume 3D battle")
	_button("guide","Field guide")
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
