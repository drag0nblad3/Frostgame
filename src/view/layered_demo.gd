extends Node3D
## Isolated mechanics laboratory, not campaign or regular skirmish.
var controller: GameController
var layout: FloorLayout
var rig: CameraRig
var art: LayeredGatehouseArt
var player: EventPlayer
var marker_root: Node3D
var floor_choice: OptionButton
var status: Label
var move_button: Button
var collect_button: Button
var bot_button: Button
var selected := -1
var targets := {}
var _last_idle := false


func _ready() -> void:
	var db := FigureDb.load_files()
	var state := GameState.new()
	state.board=BoardLoader.load_id("stacked_gatehouse",TerrainDb.load_file())
	layout=FloorLayout.from_dict(state.board.floor_layout)
	state.side_names.assign(["Expedition","Rival"])
	state.creature_db=db
	var a := Figure.new(1,db.get_def("thug"),0,Vector2(2,8),db.unarmed())
	a.surface_id="stairs"
	a.elevation=layout.height(layout.node(a.surface_id,a.pos))
	var b := Figure.new(2,db.get_def("archer"),1,Vector2(8,8),db.unarmed())
	b.surface_id="street"
	state.figures.assign([a,b])
	for id: String in ["street","upper"]:
		var token := TreasureToken.new(state.treasures.size(),Vector2(9.5,8))
		token.surface_id=id
		state.treasures.append(token)
	controller=GameController.new(state,Dice.new(17))
	state.active_id=1
	a.actions_left=2
	art=LayeredGatehouseArt.new()
	add_child(art)
	art.build(layout)
	var atmosphere := BattleAtmosphere.new()
	add_child(atmosphere)
	atmosphere.configure(state.board,"treasure_skirmish")
	rig=CameraRig.new()
	add_child(rig)
	rig.frame_board(state.board.size)
	rig.tapped.connect(_tap)
	player=EventPlayer.new()
	player.state=state
	add_child(player)
	for f in state.figures:
		var view := FigureView.new()
		player.add_child(view)
		view.setup(f,state.side_names[f.side])
		view.face_toward(Vector3(9,0,8))
		player.views[f.id]=view
	controller.event_emitted.connect(player.push)
	# EventPlayer handles collection and 3D move paths; its treasure creation
	# reads legacy ground heights, so reposition tokens on named surfaces here.
	player.build_treasures()
	for token in state.treasures:
		var model: MeshInstance3D = player.treasure_views[token.id]
		model.position=TableSpace.to_world(token.pos,layout.height(layout.node(token.surface_id,token.pos))+0.25)
	marker_root=Node3D.new()
	add_child(marker_root)
	_build_ui()
	_refresh()


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter=Control.MOUSE_FILTER_IGNORE
	margin.theme=BattleTheme.create()
	for edge: String in ["left","right","top","bottom"]:
		margin.add_theme_constant_override("margin_"+edge,12)
	layer.add_child(margin)
	var col := VBoxContainer.new()
	col.mouse_filter=Control.MOUSE_FILTER_IGNORE
	margin.add_child(col)
	var row := HFlowContainer.new()
	row.mouse_filter=Control.MOUSE_FILTER_IGNORE
	col.add_child(row)
	status=Label.new()
	status.add_theme_font_size_override("font_size",19)
	row.add_child(status)
	floor_choice=OptionButton.new()
	for s in layout.surfaces:
		floor_choice.add_item(s.id.capitalize())
	floor_choice.add_item("All floors")
	floor_choice.select(layout.surfaces.size())
	floor_choice.item_selected.connect(func(_index: int) -> void:_refresh())
	row.add_child(floor_choice)
	_button(row,"Title",func() -> void:get_tree().change_scene_to_file("res://scenes/title.tscn"))
	var space := Control.new()
	space.size_flags_vertical=Control.SIZE_EXPAND_FILL
	space.mouse_filter=Control.MOUSE_FILTER_IGNORE
	col.add_child(space)
	var commands := HFlowContainer.new()
	col.add_child(commands)
	move_button=_button(commands,"New movement turn",_reset_turn)
	collect_button=_button(commands,"Collect treasure",_collect)
	bot_button=_button(commands,"Auto-route to upper treasure",_auto_route)


func _button(row: Control,label: String,callback: Callable) -> Button:
	var button := Button.new()
	button.text=label
	button.custom_minimum_size.y=48
	button.pressed.connect(callback)
	row.add_child(button)
	return button


func _reset_turn() -> void:
	if not player.idle():
		return
	var f := controller.state.active()
	f.actions_left=2
	f.moves_taken=0
	f.acted=false
	f.non_moves=0
	_refresh()


func _collect() -> void:
	if not player.idle():
		return
	for token in controller.state.treasures:
		if controller.can_pick_up(token.id):
			controller.pick_up(token.id)
			break
	_refresh()


func _auto_route() -> void:
	if not player.idle():
		return
	var f := controller.state.active()
	var target := layout.node("upper",Vector2(9.5,8))
	var reachable := controller.layered_reach()
	var next: Variant = LayeredBot.best_step(layout,reachable,target,LayeredGrid.new(layout,f,controller.state.figures))
	if next!=null:
		controller.move_on_floor(next)
	_refresh()


func _tap(at: Vector2) -> void:
	if not player.idle():
		return
	var best: Variant = null
	var distance := 24.0
	for node: Vector3i in targets:
		var point := layout.world(node)+Vector3.UP*0.07
		if rig.camera.is_position_behind(point):
			continue
		var d := rig.camera.unproject_position(point).distance_to(at)
		if d<distance:
			best=node
			distance=d
	if best!=null:
		controller.move_on_floor(best)
		_refresh()


func _process(_delta: float) -> void:
	if player==null:
		return
	var idle := player.idle()
	if idle!=_last_idle:
		_last_idle=idle
		_refresh()


func _refresh() -> void:
	var f := controller.state.active()
	var index := floor_choice.selected
	var all := index==layout.surfaces.size()
	var chosen := "" if all else layout.surfaces[index].id
	art.show_upper(all or chosen=="upper" or chosen=="landing")
	for unit in controller.state.figures:
		var view: FigureView = player.views[unit.id]
		view.visible=all or unit.surface_id==chosen
	for token in controller.state.treasures:
		var model: MeshInstance3D = player.treasure_views[token.id]
		model.visible=token.unresolved() and (all or token.surface_id==chosen or token.carrier_id>=0)
	for child in marker_root.get_children():
		marker_root.remove_child(child)
		child.queue_free()
	targets.clear()
	status.text="GATEHOUSE LAB  |  %s %.1f″  |  %d actions" % [f.surface_id.capitalize(),f.elevation,f.actions_left]
	collect_button.disabled=true
	bot_button.disabled=not player.idle() or f.actions_left<=0
	move_button.disabled=not player.idle()
	if not player.idle():
		return
	for token in controller.state.treasures:
		if controller.can_pick_up(token.id):
			collect_button.disabled=false
	var reach := controller.layered_reach()
	for node: Vector3i in reach.cost:
		if node==reach.start or layout.surface_id(node)!=(f.surface_id if all else chosen):
			continue
		targets[node]=true
	var mesh := CylinderMesh.new()
	mesh.top_radius=0.13
	mesh.bottom_radius=0.13
	mesh.radial_segments=4
	mesh.height=0.035
	var material := StandardMaterial3D.new()
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color=Color(0.30,0.96,0.77)
	mesh.material=material
	var mm := MultiMesh.new()
	mm.transform_format=MultiMesh.TRANSFORM_3D
	mm.mesh=mesh
	mm.instance_count=targets.size()
	var i := 0
	for node: Vector3i in targets:
		mm.set_instance_transform(i,Transform3D(Basis.IDENTITY,layout.world(node)+Vector3.UP*0.065))
		i+=1
	var markers := MultiMeshInstance3D.new()
	markers.multimesh=mm
	marker_root.add_child(markers)
