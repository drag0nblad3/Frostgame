class_name WarbandLineup
extends SubViewportContainer
## One on-demand 3D stage for all assembled figures, not ten viewports.
signal selected(slot: int)

var _studio: SubViewport
var _camera: Camera3D
var _stage: Node3D
var _models: Dictionary={}
var _key := ""
var _draft: WarbandDraft


func _ready() -> void:
	stretch=true
	stretch_shrink=2 if GraphicsQuality.mode()<2 else 1
	mouse_filter=Control.MOUSE_FILTER_STOP
	_studio=SubViewport.new()
	_studio.own_world_3d=true
	_studio.render_target_update_mode=SubViewport.UPDATE_ONCE
	add_child(_studio)
	var room := Node3D.new()
	_studio.add_child(room)
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode=Environment.BG_COLOR
	env.background_color=Color("213b4b")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color("b8d7ed")
	env.ambient_light_energy=0.65
	world.environment=env
	room.add_child(world)
	for i in 2:
		var light := DirectionalLight3D.new()
		light.rotation_degrees=Vector3(-40,-35 if i==0 else 135,0)
		light.light_color=Color("ffe2b6") if i==0 else Color("a6d7ff")
		light.light_energy=1.35 if i==0 else 0.85
		room.add_child(light)
	_stage=Node3D.new()
	room.add_child(_stage)
	_camera=Camera3D.new()
	_camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	room.add_child(_camera)
	_camera.make_current()
	visibility_changed.connect(_request_frame)
	resized.connect(_frame)
	gui_input.connect(_pick)


func set_draft(draft: WarbandDraft) -> void:
	_draft=draft
	var key := str([draft.school,draft.apprentice,draft.soldiers,draft.wizard_weapons,draft.apprentice_weapons])
	if key!=_key:
		_key=key
		WorkshopUI.clear(_stage)
		_models.clear()
		var ids: Array[int]=[0]
		if draft.apprentice:
			ids.append(1)
		for i in draft.soldiers.size():
			ids.append(i+2)
		for slot in ids:
			var root := Node3D.new()
			_stage.add_child(root)
			var f := WorkshopUI.figure(draft,slot)
			root.add_child(MiniatureFactory.create(f,FigureView.SIDE_COLORS[0],draft.school if slot<2 else ""))
			MiniatureFactory.cylinder(root,Vector3(0,-0.11,0),0.63,0.70,0.22,Color("455d69"))
			MiniatureFactory.cylinder(root,Vector3(0,-0.21,0),0.70,0.70,0.05,Color("d1af70") if slot<2 else Color("879daa"))
			_models[slot]=root
	_frame()


func _frame() -> void:
	if _camera==null or _models.is_empty():
		return
	var aspect := maxf(0.5,size.x/maxf(1.0,size.y))
	var count := _models.size()
	var columns := mini(count,clampi(floori(aspect*3.0),2,6))
	if count>columns and count<=columns*2:
		columns=ceili(count/2.0)
	var rows := ceili(float(count)/columns)
	var spacing := 1.65
	var i := 0
	for slot: int in _models:
		var row := floori(float(i)/columns)
		var row_count := mini(columns,count-row*columns)
		var x := (float(row_count-1)*0.5-float(i%columns))*spacing
		var z := (float(row)-float(rows-1)*0.5)*2.0
		_models[slot].position=Vector3(x,0,z)
		i+=1
	var target := Vector3(0,0.83,0)
	_camera.look_at_from_position(target+Vector3(0,4.7,-9),target)
	_camera.size=maxf(2.7+float(rows-1)*1.20,(float(columns)*spacing+0.35)/aspect)
	_request_frame()


func _pick(event: InputEvent) -> void:
	var at := Vector2.ZERO
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		at=event.position
	elif event is InputEventScreenTouch and event.pressed:
		at=event.position
	else:
		return
	if _studio==null or _studio.size.x<=0 or _studio.size.y<=0:
		return
	var scale_factor := size/Vector2(_studio.size)
	var best := -1
	var distance := maxf(44.0,size.y*0.23)
	for slot: int in _models:
		var model: Node3D=_models[slot]
		var screen := _camera.unproject_position(model.global_position+Vector3(0,0.72,0))*scale_factor
		if at.distance_to(screen)<distance:
			distance=at.distance_to(screen)
			best=slot
	if best>=0:
		selected.emit(best)
		accept_event()


func _request_frame() -> void:
	if is_instance_valid(_studio) and is_visible_in_tree():
		_studio.render_target_update_mode=SubViewport.UPDATE_ONCE
