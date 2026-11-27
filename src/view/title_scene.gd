extends Node3D
## Scenic, non-interactive city backdrop and explicit entry points.
const BATTLE := "res://scenes/main.tscn"
const LAUNCH_KEY := "frostgame_launch"
var _camera: Camera3D
var _elapsed := 0.0
var _launching := false
var _buttons := {}
var _home: ExpeditionHome
var _campaign_start: CampaignStartScreen
var _return_to := ""
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
	_home=ExpeditionHome.new()
	layer.add_child(_home)
	_buttons=_home.buttons
	_slots=_home.slots
	_notice=_home.notice
	_home.requested.connect(_launch)
	_home.slot_selected.connect(_select_slot)
	_refresh_slots()


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
			_notice.show()
			return
	if key=="skirmish":
		_choose_scenario()
		return
	if key=="campaign":
		_choose_campaign()
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
	_enter_battle(key)


func _enter_battle(key: String) -> void:
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
	var progress := CampaignProgress.new()
	var has_campaign := progress.load_save()
	_home.roster_name.text=str(progress.data.get("name",roster.get("name","Unformed warband")))
	_home.roster_info.text=("%s · Level %d · %d battles"%[str(progress.data["school"]).capitalize(),progress.data["level"],progress.data["games"]]) if has_campaign else ("Choose your wizard, spells and soldiers." if roster.is_empty() else "%s · %d members · %d gc"%[str(roster.get("school","")).capitalize(),roster.get("figures",[]).size(),roster.get("gold",0)])
	_buttons["campaign"].text="Continue campaign  ›" if has_campaign else "New campaign  ›"
	_home.content.text="Save %d / %d · %s"%( [WarbandSlots.active()+1,WarbandSlots.COUNT,"Core + "+", ".join(profile.enabled) if not profile.enabled.is_empty() else "Core rules"] )
	_notice.text="Saved battle requires its original rulebook selection and campaign state." if not checkpoint.is_empty() and not compatible else ""
	_notice.visible=not _notice.text.is_empty()


func _select_slot(index: int) -> void:
	if ModalInput.blocked():
		_slots.select(WarbandSlots.active())
		return
	if WarbandSlots.select_slot(index):
		_refresh_slots()
	else:
		_notice.text="Could not switch save slot."
		_notice.show()
		_slots.select(WarbandSlots.active())


func _choose_scenario() -> void:
	if _picker==null:
		_picker=SkirmishPicker.new()
		add_child(_picker)
		_picker.selected.connect(func(id: String) -> void:
			get_tree().root.set_meta("frostgame_scenario",id)
			_enter_battle("selected_skirmish"))
		_picker.edit_requested.connect(_edit_from.bind("skirmish"))
	_picker.open(true)


func _choose_campaign() -> void:
	var progress := CampaignProgress.new()
	if progress.load_save():
		_enter_battle("campaign")
		return
	if FileAccess.file_exists(WarbandSlots.path_for(CampaignProgress.PATH)):
		_notice.text="This campaign save could not be read. Choose another save slot."
		_notice.show()
		return
	if _campaign_start==null:
		_campaign_start=CampaignStartScreen.new()
		add_child(_campaign_start)
		_campaign_start.created.connect(func() -> void: _enter_battle("campaign"))
		_campaign_start.edit_requested.connect(_edit_from.bind("campaign"))
	_campaign_start.open()


func _edit_from(page: String) -> void:
	_return_to=page
	_edit_warband()


func _after_editor() -> void:
	if _editor.visible or _return_to.is_empty():
		return
	var page := _return_to
	_return_to=""
	if page=="skirmish":
		_choose_scenario()
	elif page=="campaign":
		_choose_campaign()


func _edit_warband() -> void:
	if _editor!=null:
		remove_child(_editor)
		_editor.queue_free()
	_editor=WarbandSetup.new()
	add_child(_editor)
	_editor.setup(FigureDb.load_files(FigureDb.FIGURES,FigureDb.WEAPONS,WarbandSlots.content_profile()),WarbandSlots.roster())
	_editor.drafted.connect(func(roster: Dictionary) -> void:
		if WarbandSlots.save_roster(roster):
			_refresh_slots()
			_notice.text="Warband saved to slot %d."%(WarbandSlots.active()+1)
			_notice.show()
		else:
			_notice.text="Could not save warband. Reopen the editor and try again."
			_notice.show())
	_editor.visibility_changed.connect(func() -> void: call_deferred("_after_editor"))
	_editor.open("Save warband")


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
