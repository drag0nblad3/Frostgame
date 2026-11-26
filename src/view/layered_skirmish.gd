extends Node3D
## Experimental playable skirmish; all actions use GameController.
var controller: GameController
var layout: FloorLayout
var rig: CameraRig
var art: LayeredGatehouseArt
var player: EventPlayer
var floor_choice: OptionButton
var status: Label
var controls: LayeredSkirmishControls
var marks: MultiMeshInstance3D
var targets := {}
var _was_idle := false
var _layout_revision := 0


func _ready() -> void:
	var board_id := str(get_tree().root.get_meta("layered_board","stacked_gatehouse"))
	get_tree().root.remove_meta("layered_board")
	var db := FigureDb.load_files()
	var resume := bool(get_tree().root.get_meta("layered_resume",false))
	get_tree().root.remove_meta("layered_resume")
	if resume:
		controller=LayeredCheckpoint.load_battle(db)
	if controller==null:
		controller=LayeredBattle.create(db,TerrainDb.load_file(),17,board_id)
	var s := controller.state
	layout=FloorLayout.from_dict(s.board.floor_layout)
	_layout_revision=s.board.floor_layout.hash()
	art=LayeredGatehouseArt.new()
	add_child(art)
	art.build(layout)
	var atmosphere := BattleAtmosphere.new()
	add_child(atmosphere)
	atmosphere.configure(s.board,"treasure_skirmish")
	rig=CameraRig.new()
	add_child(rig)
	rig.frame_board(s.board.size)
	rig.tapped.connect(_tap)
	player=EventPlayer.new()
	player.state=s
	add_child(player)
	for f in s.figures:
		var v := FigureView.new()
		player.add_child(v)
		v.setup(f,s.side_names[f.side])
		player.views[f.id]=v
		v.set_active(s.active_id==f.id)
	controller.event_emitted.connect(player.push)
	player.build_treasures()
	marks=MultiMeshInstance3D.new()
	add_child(marks)
	_ui()
	refresh()


func _ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := MarginContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter=Control.MOUSE_FILTER_IGNORE
	root.theme=BattleTheme.create()
	for edge: String in ["left","right","top","bottom"]:
		root.add_theme_constant_override("margin_"+edge,10)
	layer.add_child(root)
	var col := VBoxContainer.new()
	col.mouse_filter=Control.MOUSE_FILTER_IGNORE
	root.add_child(col)
	var row := HFlowContainer.new()
	row.mouse_filter=Control.MOUSE_FILTER_IGNORE
	col.add_child(row)
	status=Label.new()
	row.add_child(status)
	floor_choice=OptionButton.new()
	for surface in layout.surfaces:
		floor_choice.add_item(surface.id.capitalize())
	floor_choice.add_item("All floors")
	floor_choice.select(layout.surfaces.size())
	floor_choice.item_selected.connect(func(_i: int) -> void:refresh())
	row.add_child(floor_choice)
	for entry: Array in [["Title","res://scenes/title.tscn"],["Floor lab","res://scenes/layered_demo.tscn"]]:
		var button := Button.new()
		button.text=entry[0]
		button.pressed.connect(_leave.bind(str(entry[1])))
		row.add_child(button)
	var tower_button := Button.new()
	tower_button.text="Gatehouse" if controller.state.board.id=="layered_silent_tower" else "Silent Tower"
	tower_button.pressed.connect(_switch_board)
	row.add_child(tower_button)
	var space := Control.new()
	space.mouse_filter=Control.MOUSE_FILTER_IGNORE
	space.size_flags_vertical=Control.SIZE_EXPAND_FILL
	col.add_child(space)
	controls=LayeredSkirmishControls.new()
	col.add_child(controls)
	controls.setup(self)
	var save := Button.new()
	save.text="Save 3D battle"
	save.pressed.connect(_save)
	row.add_child(save)
	if not LayeredCheckpoint.read().is_empty():
		var resume := Button.new()
		resume.text="Load 3D save"
		resume.pressed.connect(_resume)
		row.add_child(resume)


func _save() -> void:
	if not player.idle():
		return
	if LayeredCheckpoint.save(controller):
		controls.log_line.text="3D battle saved. Resume it from the title screen."
	else:
		controls.log_line.text="Finish pending actions before saving."


func _resume() -> void:
	if not player.idle():
		return
	var confirm := ConfirmationDialog.new()
	confirm.dialog_text="Load the saved 3D battle? Unsaved progress will be replaced."
	add_child(confirm)
	confirm.confirmed.connect(func() -> void:
		get_tree().root.set_meta("layered_resume",true)
		get_tree().reload_current_scene())
	confirm.canceled.connect(confirm.queue_free)
	confirm.popup_centered()


func _switch_board() -> void:
	if not player.idle():
		return
	get_tree().root.set_meta("layered_board","stacked_gatehouse" if controller.state.board.id=="layered_silent_tower" else "layered_silent_tower")
	get_tree().reload_current_scene()


func _leave(path: String) -> void:
	if player.idle():
		get_tree().change_scene_to_file(path)


func _process(_delta: float) -> void:
	if player==null or controls==null:
		return
	var idle := player.idle()
	if idle!=_was_idle:
		_was_idle=idle
		refresh()


func refresh() -> void:
	var revision := controller.state.board.floor_layout.hash()
	if revision!=_layout_revision:
		var old := floor_choice.selected
		var chosen_id := layout.surfaces[old].id if old>=0 and old<layout.surfaces.size() else ""
		layout=FloorLayout.from_dict(controller.state.board.floor_layout)
		_layout_revision=revision
		art.build(layout)
		floor_choice.clear()
		for surface in layout.surfaces:
			floor_choice.add_item(surface.id.capitalize())
		floor_choice.add_item("All floors")
		var selected := layout.index_of(chosen_id)
		floor_choice.select(selected if selected>=0 else layout.surfaces.size())
	var index := floor_choice.selected
	var all := index==layout.surfaces.size()
	var chosen := "" if all else layout.surfaces[index].id
	if controller.state.board.id=="layered_silent_tower":
		art.cut_at(INF if all else maxf(layout.surfaces[index].level,layout.surfaces[index].end_level))
	else:
		art.show_upper(all or chosen in ["upper","landing"] or chosen.begins_with("bridge:"))
	var s := controller.state
	for f in s.figures:
		var view: FigureView = player.views[f.id]
		view.visible=f.in_play() and (all or f.surface_id==chosen)
	for t in s.treasures:
		var model: MeshInstance3D = player.treasure_views[t.id]
		var carrier := s.figure(t.carrier_id)
		var surface := carrier.surface_id if carrier!=null else t.surface_id
		model.visible=t.unresolved() and (all or surface==chosen)
	status.text="%s  •  Turn %d  |  %s  |  Loot %d:%d" % ["SILENT TOWER" if s.board.id=="layered_silent_tower" else "GATEHOUSE",s.turn,Phase.name_of(s.phase),s.secured_count(0),s.secured_count(1)]
	controls.refresh()
	targets.clear()
	var active := s.active()
	if all and active!=null:
		chosen=active.surface_id
		if controls.mode=="leap_land" and s.figure(controls.leap_target)!=null:
			chosen=s.figure(controls.leap_target).surface_id
	for n: Vector3i in controls.destinations:
		if layout.surface_id(n)==chosen:
			targets[n]=true
	_draw()


func _draw() -> void:
	marks.visible=not targets.is_empty()
	if targets.is_empty():
		return
	var shape := CylinderMesh.new()
	shape.top_radius=0.15
	shape.bottom_radius=0.15
	shape.radial_segments=4
	shape.height=0.025
	var mat := StandardMaterial3D.new()
	mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color=controls.marker_color()
	shape.material=mat
	var mm := MultiMesh.new()
	mm.transform_format=MultiMesh.TRANSFORM_3D
	mm.mesh=shape
	mm.instance_count=targets.size()
	var i := 0
	for n: Vector3i in targets:
		mm.set_instance_transform(i,Transform3D(Basis.IDENTITY,layout.world(n)+Vector3.UP*0.07))
		i+=1
	marks.multimesh=mm


func _tap(at: Vector2) -> void:
	if not player.idle():
		return
	if controls.tap_figure(at):
		refresh()
		return
	var best: Variant = null
	var distance := 24.0
	for n: Vector3i in targets:
		var p := layout.world(n)+Vector3.UP*0.07
		if rig.camera.is_position_behind(p):
			continue
		var d := rig.camera.unproject_position(p).distance_to(at)
		if d<distance:
			best=n
			distance=d
	if best!=null:
		controls.choose_destination(best)
		refresh()
